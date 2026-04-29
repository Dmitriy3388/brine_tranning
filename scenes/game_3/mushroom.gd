extends Area2D

signal collected

var player_in_range = false
var is_collected = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" and not is_collected:
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func try_collect():
	if player_in_range and not is_collected:
		is_collected = true
		collected.emit()
		queue_free()
