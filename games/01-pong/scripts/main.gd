extends Node2D

var score_left: int = 0
var score_right: int = 0

@onready var score_label: Label = $ScoreLabel
@onready var ball: Node2D = $Ball

func _ready() -> void:
	ball.left_scored.connect(_on_left_scored)
	ball.right_scored.connect(_on_right_scored)
	_update_label()

func _on_left_scored() -> void:
	score_left += 1
	_update_label()

func _on_right_scored() -> void:
	score_right += 1
	_update_label()

func _update_label() -> void:
	score_label.text = "%d : %d" % [score_left, score_right]
