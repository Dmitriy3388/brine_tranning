extends CharacterBody2D

@export var speed: float = 200.0

@onready var animated_sprite = $AnimatedSprite2D

var is_busy: bool = false
var last_valid_position: Vector2 = Vector2.ZERO

func _ready():
	last_valid_position = position
	print("Player ready at position: ", position)

func _physics_process(_delta):
	# Если занят (анимация do) — не двигаемся
	if is_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Ввод для движения
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * speed
	move_and_slide()
	
	# Проверка границ и выхода
	check_boundaries()
	
	# Атака
	if Input.is_action_just_pressed("ui_accept"):
		attack()
		return
	
	# Анимация движения
	update_move_animation()

func check_boundaries():
	var game = get_parent()
	var cell = game.tile_map.local_to_map(global_position)
	
	# Запоминаем валидную позицию (на проходе внутри лабиринта)
	if cell.x >= 0 and cell.x < game.width and cell.y >= 0 and cell.y < game.height:
		if game.grid[cell.y][cell.x]:  # на проходе
			last_valid_position = position
	
	# Если вне границ лабиринта — возвращаемся
	if cell.x < 0 or cell.x >= game.width or cell.y < 0 or cell.y >= game.height:
		if game.collected_mushrooms < game.TOTAL_MUSHROOMS:
			game.show_cannot_exit_message()
			position = last_valid_position
		elif game.collected_mushrooms >= game.TOTAL_MUSHROOMS:
			game.show_win_message()
		return


func attack():
	is_busy = true
	velocity = Vector2.ZERO
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("do"):
		animated_sprite.play("do")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout
	
	try_collect_mushroom()
	is_busy = false

func try_collect_mushroom():
	var mushrooms = get_tree().get_nodes_in_group("mushrooms")
	for mushroom in mushrooms:
		if mushroom.has_method("try_collect"):
			mushroom.try_collect()

func update_move_animation():
	if is_busy:
		return
	
	if not animated_sprite:
		return
	
	if velocity.length() == 0:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		return
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x < 0
