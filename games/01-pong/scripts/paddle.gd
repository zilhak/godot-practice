extends Node2D

@export var up_action: String = "paddle_left_up"
@export var down_action: String = "paddle_left_down"
@export var speed: float = 480.0

const PADDLE_HEIGHT: float = 100.0
const VIEWPORT_HEIGHT: float = 648.0

func _process(delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed(up_action):
		direction -= 1.0
	if Input.is_action_pressed(down_action):
		direction += 1.0

	position.y += direction * speed * delta
	position.y = clamp(position.y, 0.0, VIEWPORT_HEIGHT - PADDLE_HEIGHT)
