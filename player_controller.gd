extends Node2D

@export var speed: float = 200.0

@onready var player = $Player
@onready var animated_sprite = $Player/AnimatedSprite2D

var is_busy: bool = false

func _physics_process(delta):
	# Если занят (анимация do) — не двигаемся
	if is_busy:
		player.velocity = Vector2.ZERO
		return
	
	# Ввод для движения
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Передаём скорость игроку (НО НЕ ВЫЗЫВАЕМ move_and_slide)
	player.velocity = input_dir * speed
	
	# Атака
	if Input.is_action_just_pressed("ui_accept"):
		attack()
		return
	
	# Анимация движения
	update_move_animation()

func attack():
	is_busy = true
	player.velocity = Vector2.ZERO
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("do"):
		animated_sprite.play("do")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout
	
	is_busy = false

func update_move_animation():
	if is_busy:
		return
	
	if not animated_sprite:
		return
	
	if player.velocity.length() == 0:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		return
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
		animated_sprite.flip_h = player.velocity.x < 0
