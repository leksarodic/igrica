# Save and Cross-Device Sync

**Implementation:** `game/scripts/core/save_manager.gd`, `game/scripts/core/sync_service.gd`, `game/scripts/core/game.gd`
**Verified by:** `game/tests/run_tests.gd` (save, corruption, backup, two-device conflict), `game/tests/integration.gd` (explicit transfer), and macOS export boot.

---

## 1. Principles

1. The local save is always available and always authoritative for the running session.
2. Nothing newer is ever overwritten by something older without an explicit player choice.
3. Every write is atomic and checksummed.
4. A damaged save is preserved for recovery, never silently deleted.
5. Sync is a copy of immutable snapshots, not a live database mutation.
6. The player is told the truth about status: local only, shared, pending, or conflicting.
7. No account is required. No server is required. No network is required.

---

## 2. Local file format

Path: `user://saves/<slot>.json` (Godot's per-application user directory; `LongNote` on macOS/iOS).

```json
{
  "header": {
    "magic": "longnote.save",
    "schema": 1,
    "game_version": "0.1.0",
    "slot": "autosave",
    "save_id": "uuid",
    "created_utc": "2026-11-23T12:00:00",
    "modified_utc": "2026-11-23T13:42:11",
    "device": { "id": "uuid", "name": "aleksa's Mac", "platform": "macOS" },
    "revision": 42,
    "playtime_seconds": 1234.5,
    "automatic": false,
    "checksum": "sha256 hex"
  },
  "state": { "...": "GameState.to_dict()" }
}
```

`state` contains player identity and stats, inventory/equipment, quests and choices, flags, world state (puzzles, doors, builds, lanterns, region state), companion trust/active state, journal/lore/echoes, and statistics.

### Checksum

The checksum is SHA-256 over a **canonicalized** payload: the header without `checksum`, plus `state`.

Canonicalization sorts dictionary keys, converts dictionary keys to strings, turns integral floats into integers, and renders non-integral floats as `f:%.6f`. This is necessary because Godot's JSON parser promotes numbers to floats; without normalization an integral `1` would become `1.0` and the checksum would fail after a read/write cycle. The fixed textual form also survives cross-platform float formatting.

### Atomic write

```
write <slot>.json.tmp
flush + close
read back and verify magic + checksum
if <slot>.json exists: copy it to <slot>.json.bak
remove <slot>.json
rename <slot>.json.tmp -> <slot>.json
```

If the process dies between steps:

- `.tmp` with no `.json` → the previous `.json` or `.bak` is used.
- `.json` missing and `.bak` present → `load_slot` reads the backup and reports `recovered_from_backup`.
- verification fails → the file is copied to `<slot>.json.corrupt-<timestamp>` and the backup is offered.

No step deletes the only copy.

### Slots and autosave

- `autosave` is written at region thresholds, lantern rests, quest changes, and app pause/background.
- Manual saves use `save_current(current_slot)` or “Save as new journey” with a sanitized name.
- Autosave never overwrites a manual slot.
- All slots are listed by `SaveManager.list_slots()` with player name, region, playtime, modified time, device, revision, and checksum.
- Corrupt slots appear in the list as preserved/damaged, not hidden.

---

## 3. Sync folder layout

```
<syncRoot>/
  index.json
  <slot>.<device_id>.json      # full header + state snapshot
```

`index.json`:

```json
{
  "schema": 1,
  "updated_utc": "...",
  "devices": {
    "<device_id>": { "name": "aleksa's Mac", "platform": "macOS", "last_seen": "..." }
  },
  "slots": {
    "autosave": {
      "<device_id>": {
        "device_name": "...",
        "checksum": "...",
        "revision": 42,
        "modified_utc": "...",
        "playtime_seconds": 1234.5,
        "file": "autosave.<device_id>.json"
      }
    }
  }
}
```

The local “last synced” digest lives in `user://sync_state.json`, per device, not in the shared index. This prevents one device from claiming another's sync state.

### Adapters / roots

`SyncService.discover_root()` picks:

1. **iOS ubiquity container** (`~/Library/Mobile Documents/iCloud~com~leksarodic~longnote/Documents`) if it exists. This requires the app to be signed with the iCloud capability and the container entitlement. If it does not exist, fallback.
2. **macOS iCloud Drive** (`~/Library/Mobile Documents/com~apple~CloudDocs/LongNote`) if iCloud Drive is mounted; created only if the parent exists.
3. **Local** `user://sync` otherwise.

The player can set another folder programmatically (`set_root`). The Save & Sync screen also supports explicit `.longnote` package export/import through the native file picker, which works even when no shared folder exists.

This is deliberately **iCloud Drive / file-level**, not CloudKit/account sync. The game has a handful of files; the conflict semantics are explicit; and the player can inspect and recover their data in Finder or the Files app.

---

## 4. Conflict model

Definitions:

- `local` = the save in `user://saves/<slot>.json` on this device.
- `remote` = the newest snapshot for the same slot from a different device in the sync folder.
- `last` = the checksum this device recorded at its last successful sync for that slot.

| local | remote | last | State | Behavior |
|---|---|---|---|---|
| missing | missing | — | `no_data` | Nothing to do |
| present | missing | — | `local_only` | Offer push |
| missing | present | — | `remote_only` | Offer pull |
| same checksum as remote | same | — | `synced` | Nothing to do |
| clean (== last) | changed | present | `remote_newer` | Offer “Use other device” |
| changed | clean (== last) | present | `local_newer` | Offer push |
| changed | changed | present | `conflict` | Preserve both; explicit choice |
| no last | different checksums | missing | `conflict` | Preserve both; explicit choice |

Timestamps are displayed but **not used for ordering**, because clocks are unreliable. Ordering is revision + checksum + recorded last-sync digest.

### Resolutions

- **Keep this device**: writes this device's snapshot and updates the last-sync digest. The other device's snapshot remains in the folder.
- **Use the other device**: archives the local file as `<slot>.pre-sync-<timestamp>.json`, then writes the remote state locally. Nothing is deleted.
- **Keep both**: imports the remote state as `<slot>_<device>` and leaves the local slot untouched. Both appear in the journey list.

A conflict warning is emitted (`Events.conflict_detected`) and shown on the Save & Sync screen. There is no default destructive action.

### Duplicate rewards / co-op

Co-op is not shipped. The architecture reserves host-authoritative reward IDs and idempotency keys so a future network session cannot grant the same quest reward twice. This is documented as design, not implemented.

---

## 5. Lifecycle behavior

- On `NOTIFICATION_APPLICATION_PAUSED` and window focus loss: save current, then push to the shared folder.
- On close request: save current, then push.
- On iOS background: the same path is used; audio is stopped by the platform.
- Autosave does **not** push to iCloud on every checkpoint, to avoid network churn and transition stalls. Explicit saves, pause-screen actions, app background, and “Save and continue on another device” push.
- The local file is written before any sync attempt, so an offline player never blocks on the cloud.

---

## 6. Verification

Automated:

- 100+ save/load assertions across runs.
- Tampered JSON → rejected, quarantined.
- Corrupt main → backup recovered and marked.
- Two simulated devices (`device_mac`, `device_phone`) with divergent progress → `conflict` state, remote device identified, *Keep both* produces a new slot and leaves the local slot intact.
- A clean third device sees `remote_only`, pulls, and loads the remote player name and progress.
- Explicit “Save and continue on another device” writes a snapshot that exists on disk.
- Checksum stability after a write/read cycle (including playtime floats).

Not verified:

- Signed iOS iCloud container access.
- A real two-Mac session through iCloud Drive.
- A physical iPhone background/foreground save.
- CloudKit (intentionally not used).

These are listed in `docs/PLAYTESTING.md` as D3/D11.
