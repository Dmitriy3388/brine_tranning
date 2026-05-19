extends Node2D

@onready var board = $Board
@onready var grid_container = $Board/GridContainer
@onready var pieces_container = $Pieces
@onready var score_label = $UI/ScoreLabel
@onready var next_button = $UI/NextButton

var current_image: Texture2D
var grid_size = Vector2(4, 5)
var piece_width = 0.0
var piece_height = 0.0
var total_pieces = 0
var placed_pieces = 0
var current_level = 1
var level_completed = false
var total_levels = 0

func _ready():
	setup_board()
	button_setup()
	detect_total_levels()
	load_level(current_level)

func detect_total_levels():
	total_levels = 0
	var level = 1
	
	while true:
		var image_path_png = "res://assets/game_4/level" + str(level) + "/full.png"
		var image_path_jpg = "res://assets/game_4/level" + str(level) + "/full.jpg"
		
		if ResourceLoader.exists(image_path_png) or ResourceLoader.exists(image_path_jpg):
			total_levels += 1
			level += 1
		else:
			break
	
	print("Detected total levels: ", total_levels)
	
	if total_levels == 0:
		print("ERROR: No levels found!")
		total_levels = 1

func button_setup():
	next_button.visible = false
	next_button.position = Vector2(550, 400)  # Смещён вниз с 320 на 400
	next_button.custom_minimum_size = Vector2(150, 40)
	next_button.text = "Следующий уровень"
	next_button.pressed.connect(_on_next_button_pressed)

func setup_board():
	board.position = Vector2(80, 120)  # Было 40, стало 120 (смещение на 80)
	var invisible_style = StyleBoxFlat.new()
	invisible_style.bg_color = Color.TRANSPARENT
	invisible_style.border_width_bottom = 0
	invisible_style.border_width_top = 0
	invisible_style.border_width_left = 0
	invisible_style.border_width_right = 0
	board.add_theme_stylebox_override("panel", invisible_style)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE

func resize_texture(texture: Texture2D, max_size: int) -> Texture2D:
	var image = texture.get_image()
	var width = image.get_width()
	var height = image.get_height()
	
	if width <= max_size and height <= max_size:
		return texture
	
	var scale = float(max_size) / float(max(width, height))
	var new_width = max(1, int(width * scale))
	var new_height = max(1, int(height * scale))
	
	image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	var new_texture = ImageTexture.create_from_image(image)
	
	return new_texture

func load_level(level_num):
	level_completed = false
	clear_children(grid_container)
	clear_children(pieces_container)
	
	if level_num <= 2:
		grid_size.x = 2
	elif level_num <= 4:
		grid_size.x = 4
	else:
		grid_size.x = 6
	
	var image_path_png = "res://assets/game_4/level" + str(level_num) + "/full.png"
	var image_path_jpg = "res://assets/game_4/level" + str(level_num) + "/full.jpg"
	current_image = null
	
	if ResourceLoader.exists(image_path_png):
		current_image = load(image_path_png)
	elif ResourceLoader.exists(image_path_jpg):
		current_image = load(image_path_jpg)
	else:
		print("ERROR: Cannot load image for level ", level_num)
		return
	
	current_image = resize_texture(current_image, 450)
	
	var cols = grid_size.x
	var piece_width_tmp = float(current_image.get_width()) / cols
	grid_size.y = current_image.get_height() / piece_width_tmp
	grid_size.y = round(grid_size.y)
	
	piece_width = float(current_image.get_width()) / float(grid_size.x)
	piece_height = float(current_image.get_height()) / float(grid_size.y)
	total_pieces = int(grid_size.x * grid_size.y)
	placed_pieces = 0
	
	var h_separation = 2
	var v_separation = 2
	
	grid_container.add_theme_constant_override("h_separation", h_separation)
	grid_container.add_theme_constant_override("v_separation", v_separation)
	
	var grid_width = (piece_width * grid_size.x) + (h_separation * (grid_size.x - 1))
	var grid_height = (piece_height * grid_size.y) + (v_separation * (grid_size.y - 1))
	
	board.size = Vector2(grid_width, grid_height)
	board.position = Vector2(80, 120)  # Было 40, стало 120
	grid_container.columns = grid_size.x
	
	for i in range(total_pieces):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(piece_width, piece_height)
		slot.modulate = Color(0.8, 0.8, 0.8, 1)
		grid_container.add_child(slot)
	
	await get_tree().process_frame
	
	var slot_positions = []
	for child in grid_container.get_children():
		slot_positions.append(child.global_position)
	
	var image = current_image.get_image()
	var pieces_list = []
	
	for y in range(int(grid_size.y)):
		for x in range(int(grid_size.x)):
			var idx = y * int(grid_size.x) + x
			var rect = Rect2(x * piece_width, y * piece_height, piece_width, piece_height)
			var piece_image = image.get_region(rect)
			var piece_texture = ImageTexture.create_from_image(piece_image)
			var piece = preload("res://scenes/game_4/piece.tscn").instantiate()
			piece.texture_normal = piece_texture
			piece.custom_minimum_size = Vector2(piece_width, piece_height)
			piece.target_position = slot_positions[idx]
			pieces_list.append(piece)
	
	pieces_list.shuffle()
	clear_children(pieces_container)
	
	for piece in pieces_list:
		var random_pos = get_random_position_outside_board(piece)
		piece.position = random_pos
		pieces_container.add_child(piece)
	
	update_top_bar()

func update_top_bar():
	var level_info = "🧩 Уровень " + str(current_level) + "/" + str(total_levels)
	var progress = str(placed_pieces) + "/" + str(total_pieces)
	GameManager.update_top_bar(-1, -1, 0, level_info + "  |  🧩 " + progress)

func get_random_position_outside_board(current_piece):
	var viewport_rect = get_viewport().get_visible_rect()
	var board_rect = Rect2(board.global_position, board.size)
	var margin = 20
	var fragment_size = piece_width
	var max_attempts = 300
	
	for attempt in range(max_attempts):
		var random_x = randf_range(board_rect.end.x + margin, viewport_rect.size.x - fragment_size - margin)
		var random_y = randf_range(margin, viewport_rect.size.y - fragment_size - margin)
		var candidate_pos = Vector2(random_x, random_y)
		
		if board_rect.has_point(candidate_pos):
			continue
		
		var overlap = false
		for piece in pieces_container.get_children():
			if piece != current_piece and piece.global_position.distance_to(candidate_pos) < fragment_size:
				overlap = true
				break
		
		if not overlap:
			return candidate_pos
	
	return Vector2(board_rect.end.x + 80, 100 + (pieces_container.get_child_count() * 10))

func on_piece_placed():
	if level_completed:
		return
	
	placed_pieces += 1
	score_label.text = str(placed_pieces) + "/" + str(total_pieces)
	update_top_bar()
	
	if placed_pieces >= total_pieces:
		on_level_complete()

func on_level_complete():
	if level_completed:
		return
	
	level_completed = true
	print("Level ", current_level, " complete!")
	
	GameManager.add_stars(1)
	
	if current_level >= total_levels:
		next_button.text = "В меню"
		
		PopupHelper.show_notification(
			"ПОЗДРАВЛЯЮ!",
			"Ты собрал все " + str(total_levels) + " пазлов!\n+" + str(total_levels) + " звёзд!",
			true,
			2.0,
			func(): 
				GameManager.open_game_selector()
		)
	else:
		next_button.text = "Следующий уровень"
		
		PopupHelper.show_notification(
			"Уровень " + str(current_level) + " пройден!",
			"+1 звезда!",
			true,
			1.0,
			Callable()
		)
	
	grid_container.add_theme_constant_override("h_separation", 0)
	grid_container.add_theme_constant_override("v_separation", 0)
	
	await get_tree().process_frame
	next_button.visible = true

func _on_next_button_pressed():
	if current_level >= total_levels:
		GameManager.open_game_selector()
		return
	
	current_level += 1
	next_button.visible = false
	load_level(current_level)

func clear_children(node):
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()
