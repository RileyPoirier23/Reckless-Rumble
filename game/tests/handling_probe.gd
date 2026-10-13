## How each car handles under each set of aids, with keyboard-style inputs (ramped like the real
## keyboard): godot --headless --path game -s tests/handling_probe.gd
## A "SPIN" is the car more than 45 degrees off the way it's going at speed.
extends SceneTree

const H := preload("res://tests/handling.gd")

func _init() -> void:
	for id in ["silvio", "supreem", "charjer"]:
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cars/%s.json" % id))
		for a in [CarSim.Assist.ARCADE, CarSim.Assist.STREET, CarSim.Assist.SIM]:
			var row := []
			for m in H.MOVES:
				var w: float = H.worst_slide(spec, a, m)
				row.append("%s=%s" % [m, ("SPIN(%d)" % int(w)) if w > 45.0 else str(int(w))])
			print("%-8s %-6s %s" % [id, ["SIM", "STREET", "ARCADE"][a], "  ".join(row)])
	quit()
