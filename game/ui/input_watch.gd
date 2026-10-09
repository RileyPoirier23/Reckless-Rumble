## Autoload: notices whether you last touched the keyboard or a controller, so prompts follow.
extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.setup()
	Hints.pad = not Input.get_connected_joypads().is_empty()

func _input(e: InputEvent) -> void:
	Hints.saw(e)
