class_name SaveMigrations
extends RefCounted
## Ordered, explicit migrations for the save schema. Schema 1 is current, so
## there are no transforms yet; this hook exists so a future schema change has
## one obvious place to live and a place for fixtures in tests.

const CURRENT := 1


static func migrate(state: Dictionary, from_schema: int) -> Dictionary:
	var out := state.duplicate(true)
	if from_schema < 1:
		# Pre-1 files never shipped. Be conservative: keep the data, fill basics.
		out["player"] = out.get("player", {})
		out["quests"] = out.get("quests", {})
		out["world"] = out.get("world", {})
	if from_schema < CURRENT:
		# Future ordered migrations go here, each guarded by its source schema.
		pass
	return out
