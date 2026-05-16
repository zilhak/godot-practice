extends Node2D

@export var speed: float = 420.0

const BALL_SIZE: float = 20.0
const PADDLE_WIDTH: float = 20.0
const PADDLE_HEIGHT: float = 100.0
const MAX_BOUNCE_ANGLE: float = 0.75
const VIEWPORT_WIDTH: float = 1152.0
const VIEWPORT_HEIGHT: float = 648.0
const START_POSITION := Vector2(
	VIEWPORT_WIDTH / 2.0 - BALL_SIZE / 2.0,
	VIEWPORT_HEIGHT / 2.0 - BALL_SIZE / 2.0
)

var velocity: Vector2 = Vector2.ZERO

@onready var left_paddle: Node2D = get_node("../LeftPaddle")
@onready var right_paddle: Node2D = get_node("../RightPaddle")

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
	_bounce_off_paddles()

func _bounce_off_paddles() -> void:
	var ball_rect := Rect2(position, Vector2(BALL_SIZE, BALL_SIZE))
	var left_rect := Rect2(left_paddle.position, Vector2(PADDLE_WIDTH, PADDLE_HEIGHT))
	var right_rect := Rect2(right_paddle.position, Vector2(PADDLE_WIDTH, PADDLE_HEIGHT))

	if velocity.x < 0.0 and ball_rect.intersects(left_rect):
		position.x = left_paddle.position.x + PADDLE_WIDTH
		_apply_paddle_bounce(left_paddle.position.y, 1.0)
	elif velocity.x > 0.0 and ball_rect.intersects(right_rect):
		position.x = right_paddle.position.x - BALL_SIZE
		_apply_paddle_bounce(right_paddle.position.y, -1.0)

func _apply_paddle_bounce(paddle_y: float, dir_x: float) -> void:
	var ball_center_y: float = position.y + BALL_SIZE / 2.0
	var paddle_center_y: float = paddle_y + PADDLE_HEIGHT / 2.0
	var offset: float = clampf((ball_center_y - paddle_center_y) / (PADDLE_HEIGHT / 2.0), -1.0, 1.0)
	var angle: float = offset * MAX_BOUNCE_ANGLE
	velocity = Vector2(cos(angle) * dir_x, sin(angle)) * speed

func _bounce_off_walls() -> void:
	if position.y <= 0.0 and velocity.y < 0.0:
		position.y = 0.0
		velocity.y = -velocity.y
	elif position.y + BALL_SIZE >= VIEWPORT_HEIGHT and velocity.y > 0.0:
		position.y = VIEWPORT_HEIGHT - BALL_SIZE
		velocity.y = -velocity.y
