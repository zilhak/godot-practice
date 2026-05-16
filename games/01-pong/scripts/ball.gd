extends Node2D

@export var speed: float = 420.0

const BALL_SIZE: float = 20.0
const VIEWPORT_WIDTH: float = 1152.0
const VIEWPORT_HEIGHT: float = 648.0
const START_POSITION := Vector2(
	VIEWPORT_WIDTH / 2.0 - BALL_SIZE / 2.0,
	VIEWPORT_HEIGHT / 2.0 - BALL_SIZE / 2.0
)

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	reset_and_launch()

func reset_and_launch() -> void:
	position = START_POSITION
	var dir_x := 1.0 if randf() < 0.5 else -1.0
	var dir_y := randf_range(-0.5, 0.5)
	velocity = Vector2(dir_x, dir_y).normalized() * speed

func _process(delta: float) -> void:
	position += velocity * delta
	_bounce_off_walls()

func _bounce_off_walls() -> void:
	if position.y <= 0.0 and velocity.y < 0.0:
		position.y = 0.0
		velocity.y = -velocity.y
	elif position.y + BALL_SIZE >= VIEWPORT_HEIGHT and velocity.y > 0.0:
		position.y = VIEWPORT_HEIGHT - BALL_SIZE
		velocity.y = -velocity.y
