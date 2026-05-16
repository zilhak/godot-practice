extends CharacterBody2D

const SPEED: float = 80.0
const GRAVITY: float = 1400.0
const RAY_OFFSET_X: float = 18.0

@export var initial_direction: int = -1

var direction: int = -1

@onready var floor_ray: RayCast2D = $FloorRay

func _ready() -> void:
	direction = initial_direction
	_align_floor_ray()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = float(direction) * SPEED
	move_and_slide()

	if is_on_floor():
		if is_on_wall():
			_turn_around()
		elif not floor_ray.is_colliding():
			_turn_around()

func _turn_around() -> void:
	direction = -direction
	_align_floor_ray()

func _align_floor_ray() -> void:
	floor_ray.position.x = float(direction) * RAY_OFFSET_X

func die() -> void:
	queue_free()
