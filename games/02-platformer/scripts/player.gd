extends CharacterBody2D

const SPEED: float = 280.0
const JUMP_VELOCITY: float = -700.0
const GRAVITY: float = 1400.0
const ATTACK_DURATION: float = 0.15
const HITBOX_OFFSET: float = 30.0

var facing: int = 1
var is_attacking: bool = false
var spawn_position: Vector2

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_visual: ColorRect = $Hitbox/Visual
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	spawn_position = position
	_set_hitbox_active(false)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)

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
	hitbox.position.x = float(facing) * HITBOX_OFFSET
	_set_hitbox_active(true)
	await get_tree().create_timer(ATTACK_DURATION).timeout
	_set_hitbox_active(false)
	is_attacking = false

func _set_hitbox_active(active: bool) -> void:
	hitbox.monitoring = active
	hitbox_visual.visible = active

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("die"):
		body.die()

func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		_die_and_respawn()

func _die_and_respawn() -> void:
	velocity = Vector2.ZERO
	position = spawn_position
	is_attacking = false
	_set_hitbox_active(false)
