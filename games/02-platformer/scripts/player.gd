extends CharacterBody2D

const SPEED: float = 280.0
const JUMP_VELOCITY: float = -520.0
const GRAVITY: float = 1400.0
const ATTACK_DURATION: float = 0.15
const HITBOX_OFFSET: float = 30.0

var facing: int = 1
var is_attacking: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_visual: ColorRect = $Hitbox/Visual

func _ready() -> void:
	_set_hitbox_active(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction > 0.0:
		facing = 1
	elif direction < 0.0:
		facing = -1

	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()

	move_and_slide()

func _perform_attack() -> void:
	is_attacking = true
	hitbox.position.x = facing * HITBOX_OFFSET
	_set_hitbox_active(true)
	await get_tree().create_timer(ATTACK_DURATION).timeout
	_set_hitbox_active(false)
	is_attacking = false

func _set_hitbox_active(active: bool) -> void:
	hitbox.monitoring = active
	hitbox_visual.visible = active
