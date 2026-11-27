#!/usr/bin/env python3
"""Content, documentation, and product-constraint validation.

Runs without Godot or third-party packages. It checks the things a compiler
cannot: that every referenced id exists, that the novella is a novella, that the
required documents are present, and that the shipped scripts do not contain
retention or notification machinery.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
DATA = GAME / "data"

errors: list[str] = []
notes: list[str] = []


def load(name: str) -> dict:
    path = DATA / name
    if not path.exists():
        errors.append(f"missing data file: {path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{path}: {exc}")
        return {}


items = load("items.json")
recipes = load("recipes.json")
quests = load("quests.json")
enemies = load("enemies.json")
regions = load("regions.json")
skills = load("skills.json")
dialogue = load("dialogue.json")
builds = load("builds.json")
lore = load("lore.json")

# --- content integrity ----------------------------------------------------
for rid, recipe in recipes.items():
    out = recipe.get("output")
    if out not in ("upgrade_weapon", "upgrade_cloak") and out not in items:
        errors.append(f"recipe {rid} outputs unknown item {out}")
    for mat in recipe.get("cost", {}):
        if mat not in items:
            errors.append(f"recipe {rid} costs unknown item {mat}")

for bid, build in builds.items():
    if build.get("kit") not in items:
        errors.append(f"build {bid} uses unknown kit {build.get('kit')}")

for eid, enemy in enemies.items():
    for mat in enemy.get("materials", {}):
        if mat not in items:
            errors.append(f"enemy {eid} drops unknown item {mat}")

for qid, quest in quests.items():
    stages = quest.get("stages")
    if not isinstance(stages, list) or not stages:
        errors.append(f"quest {qid} has no stages")
    for i, stage in enumerate(stages):
        if "text" not in stage:
            errors.append(f"quest {qid} stage {i} has no text")

for did, dlg in dialogue.items():
    nodes = dlg.get("nodes", {})
    if dlg.get("start") not in nodes:
        errors.append(f"dialogue {did} has no valid start node")
    for nid, node in nodes.items():
        if "next" in node and node["next"] not in nodes:
            errors.append(f"dialogue {did}/{nid} next target missing")
        for choice in node.get("choices", []):
            if choice.get("next") not in nodes:
                errors.append(f"dialogue {did}/{nid} choice target missing")
        if "text" not in node:
            errors.append(f"dialogue {did}/{nid} has no text")

for lid, entry in lore.items():
    for key in ("title", "text"):
        if key not in entry:
            errors.append(f"lore {lid} missing {key}")

for did, dlg in dialogue.items():
    for node in dlg.get("nodes", {}).values():
        for effect in node.get("effects", []):
            if effect.get("type") == "lore" and effect.get("id") not in lore:
                errors.append(f"dialogue {did} references unknown lore {effect.get('id')}")

for sid, skill in skills.items():
    for key in ("name", "description", "arc"):
        if key not in skill:
            errors.append(f"skill {sid} missing {key}")

for rid, region in regions.items():
    if "name" not in region:
        errors.append(f"region {rid} missing name")

# Every region known to the factory should have data.
factory = (GAME / "scripts/world/region_factory.gd").read_text(encoding="utf-8")
for rid in re.findall(r'"([a-z_]+)":\n\t\t\treturn', factory):
    if rid not in regions:
        errors.append(f"region factory references unknown region {rid}")

# --- novella and required documents --------------------------------------
required_docs = [
    "README.md",
    "docs/GAME_DESIGN_DOCUMENT.md",
    "docs/PROJECT_PLAN.md",
    "docs/TECHNICAL_ARCHITECTURE.md",
    "docs/ART_DIRECTION.md",
    "docs/PLAYTESTING.md",
    "docs/architecture/save_sync.md",
    "docs/architecture/ios_build.md",
    "docs/story/novella.md",
    "docs/story/world_lore.md",
    "docs/story/characters.md",
    "docs/story/factions.md",
    "docs/story/locations.md",
    "docs/story/timeline.md",
    "docs/story/story_structure.md",
]
for rel in required_docs:
    if not (ROOT / rel).exists():
        errors.append(f"required document missing: {rel}")

novella = ROOT / "docs/story/novella.md"
if novella.exists():
    text = novella.read_text(encoding="utf-8")
    words = len(text.split())
    notes.append(f"novella words: {words}")
    if not (7500 <= words <= 9000):
        errors.append(f"novella word count {words} outside 7500-9000")
    chapters = re.findall(r"^## \d+\.", text, re.MULTILINE)
    if len(chapters) < 8:
        errors.append(f"novella has only {len(chapters)} chapters")
    if "TODO" in text or "lorem ipsum" in text.lower():
        errors.append("novella contains placeholder text")

# --- product constraints --------------------------------------------------
banned_apis = [
    r"NotificationServer",
    r"OS\.shell_open",
    r"push_notification",
    r"HTTPRequest",
    r"Firebase",
    r"AdMob",
]
banned_words = [
    r"\bdaily\s+reward\b",
    r"\blogin\s+streak\b",
    r"\bloot\s*box\b",
    r"\bbattle\s*pass\b",
    r"\benergy\s+system\b",
    r"\blimited[-\s]time\s+event\b",
    r"\bgacha\b",
]
for path in (GAME / "scripts").rglob("*.gd"):
    text = path.read_text(encoding="utf-8")
    for pattern in banned_apis + banned_words:
        if re.search(pattern, text, re.IGNORECASE):
            errors.append(f"banned pattern {pattern!r} in {path.relative_to(ROOT)}")
    for match in re.finditer(r"(?i)(api[_-]?key|secret|password)\s*=\s*['\"][^'\"]+['\"]", text):
        errors.append(f"possible secret in {path.relative_to(ROOT)}: {match.group(0)}")

# --- project sanity -------------------------------------------------------
project = (GAME / "project.godot").read_text(encoding="utf-8")
if 'config/features=PackedStringArray("4.7", "Mobile")' not in project:
    errors.append("project.godot does not pin Godot 4.7 Mobile")
if "window/handheld/orientation=0" not in project:
    errors.append("iPhone orientation is not pinned to landscape")
if "config/use_custom_user_dir=true" not in project:
    errors.append("project does not isolate its user data directory")

notes.append(f"items: {len(items)}  recipes: {len(recipes)}  quests: {len(quests)}  dialogue: {len(dialogue)}  builds: {len(builds)}")
notes.append(f"scripts: {len(list((GAME / 'scripts').rglob('*.gd')))}")

print("== The Long Note — content validation ==")
for note in notes:
    print("  " + note)
if errors:
    print(f"\nFAILED ({len(errors)})")
    for err in errors:
        print("  ✗ " + err)
    sys.exit(1)
print("\nOK — content, documents, and product constraints are consistent.")
