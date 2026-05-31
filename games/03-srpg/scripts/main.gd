extends Node

const BATTLE_SCENE: String = "res://battle.tscn"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") \
			or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		get_tree().change_scene_to_file(BATTLE_SCENE)
