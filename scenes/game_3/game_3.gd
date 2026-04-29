extends Node2D

# --- Ссылки на узлы в сцене ---
@onready var tile_map: TileMapLayer = $Labirint
@onready var player: CharacterBody2D = $Player # CharacterBody2D (физика)
@onready var mushrooms_container = $Mushrooms

# --- Параметры лабиринта ---
@export var width: int = 17
@export var height: int = 9
var maze_offset: Vector2 = Vector2(20, 70) 
var mushroom_scene = preload("res://scenes/game_3/mushroom.tscn")
var collected_mushrooms: int = 0
const TOTAL_MUSHROOMS: int = 4
var can_exit: bool = false
var exit_cell: Vector2i
var grid: Array[Array] = []
var is_message_showing: bool = false
var game_ended: bool = false

# --- ID атласа ---
var source_id: int = 1

# --- Координаты тайлов стен (деревья) в атласе ---
var wall_variants: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(4, 0)
]

func _ready():
	print("=== GAME START ===")
	print("tile_map node: ", tile_map)
	print("player node: ", player)
	
	generate_maze()
	visualize_maze()
	setup_player()
	spawn_mushrooms()
	
	print("=== GAME READY ===")

func generate_maze():
	print("--- generate_maze START ---")
	
	grid = []
	for y in range(height):
		grid.append([])
		for x in range(width):
			grid[y].append(false)
	
	print("Grid created: ", grid.size(), " x ", grid[0].size())
	
	var start_x = 1
	var start_y = 1
	grid[start_y][start_x] = true
	print("Start cell: (", start_x, ", ", start_y, ")")
	
	carve_maze(start_x, start_y)
	print("--- generate_maze END ---")
	create_exit()

func create_exit():
	exit_cell = Vector2i(width - 1, height - 2)
	
	if grid[exit_cell.y][exit_cell.x - 1]:
		grid[exit_cell.y][exit_cell.x] = true
		print("Exit created at (", exit_cell.x, ", ", exit_cell.y, ")")
	else:
		grid[exit_cell.y][exit_cell.x - 1] = true
		grid[exit_cell.y][exit_cell.x] = true
		print("Exit created with forced path at (", exit_cell.x, ", ", exit_cell.y, ")")

func carve_maze(x: int, y: int):
	var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]
	directions.shuffle()
	
	for dir in directions:
		var new_x = x + dir.x
		var new_y = y + dir.y
		
		if new_x > 0 and new_x < width - 1 and new_y > 0 and new_y < height - 1 and not grid[new_y][new_x]:
			grid[new_y][new_x] = true
			grid[y + dir.y / 2][x + dir.x / 2] = true
			carve_maze(new_x, new_y)

func visualize_maze():
	print("--- visualize_maze START ---")
	
	if tile_map == null:
		print("ERROR: tile_map is null! Check node name 'Labirint'")
		return
	
	tile_map.clear()
	
	if tile_map.tile_set == null:
		print("ERROR: No TileSet assigned to TileMapLayer 'Labirint'!")
		return
	
	var wall_count = 0
	
	for y in range(height):
		for x in range(width):
			var cell_pos = Vector2i(x, y)
			
			if grid[y][x]:
				# Пол — пустота
				pass
			else:
				var random_wall = wall_variants[randi() % wall_variants.size()]
				tile_map.set_cell(cell_pos, source_id, random_wall)
				wall_count += 1
	
	# Сдвигаем весь TileMapLayer
	tile_map.position = maze_offset
	
	print("Walls placed: ", wall_count)
	print("Floors (empty): ", (width * height) - wall_count)
	print("Total cells: ", width * height)
	print("TileMap position offset: ", tile_map.position)
	print("--- visualize_maze END ---")

func setup_player():
	print("--- setup_player START ---")
	
	if tile_map == null:
		print("ERROR: tile_map is null, cannot set player position")
		return
	
	# Ищем первую свободную клетку во втором ряду
	var player_start_pos = Vector2i(1, 1)
	for x in range(1, width - 1):
		if grid[1][x]:
			player_start_pos = Vector2i(x, 1)
			break
	
	print("Player start cell: ", player_start_pos)
	
	# Применяем смещение
	var player_local_pos = tile_map.map_to_local(player_start_pos) + maze_offset
	player.position = player_local_pos
	print("Player position set to: ", player.position)
	
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		camera.enabled = true
		print("Camera enabled")
	
	print("--- setup_player END ---")
	
func _on_mushroom_collected():
	collected_mushrooms += 1
	print("Mushrooms collected: ", collected_mushrooms, "/", TOTAL_MUSHROOMS)
	
	if collected_mushrooms >= TOTAL_MUSHROOMS:
		print("All mushrooms collected! Find the exit!")
	
func spawn_mushrooms():
	var free_cells = []
	
	# Собираем все свободные клетки (проходы)
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if grid[y][x]:  # это проход
				free_cells.append(Vector2i(x, y))
	
	# Перемешиваем и берём первые 4
	free_cells.shuffle()
	var selected_cells = free_cells.slice(0, TOTAL_MUSHROOMS)
	
	for pos in selected_cells:
		var mushroom = mushroom_scene.instantiate()
		var world_pos = tile_map.map_to_local(pos) + maze_offset
		mushroom.position = world_pos
		mushroom.add_to_group("mushrooms")
		mushroom.collected.connect(_on_mushroom_collected)
		mushrooms_container.add_child(mushroom)
		print("Mushroom spawned at cell: ", pos)
	
	print("Spawned ", selected_cells.size(), "/", TOTAL_MUSHROOMS, " mushrooms")



func show_popup(title: String, message: String, is_win: bool):
	# Создаём временное окно сообщения
	var popup = CanvasLayer.new()
	var panel = Panel.new()
	var label_title = Label.new()
	var label_message = Label.new()
	var button = Button.new()
	
	# Настройка размеров
	panel.size = Vector2(400, 200)
	panel.position = Vector2(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 100)
	panel.color = Color(0.2, 0.2, 0.2, 0.95)
	
	label_title.text = title
	label_title.position = Vector2(200, 40)
	label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_title.add_theme_font_size_override("font_size", 28)
	label_title.add_theme_color_override("font_color", Color.YELLOW if is_win else Color.RED)
	
	label_message.text = message
	label_message.position = Vector2(200, 90)
	label_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_message.add_theme_font_size_override("font_size", 16)
	
	button.text = "OK"
	button.position = Vector2(150, 140)
	button.size = Vector2(100, 40)
	button.pressed.connect(func(): popup.queue_free())
	
	panel.add_child(label_title)
	panel.add_child(label_message)
	panel.add_child(button)
	popup.add_child(panel)
	add_child(popup)
	
	if is_win:
		get_tree().paused = true
		button.pressed.connect(func(): get_tree().paused = false)
		
func show_cannot_exit_message():
	if is_message_showing:
		return  # Не показываем второе окно
	
	is_message_showing = true
	print("Cannot exit! Need ", TOTAL_MUSHROOMS - collected_mushrooms, " more mushrooms.")
	
	var popup = CanvasLayer.new()
	var panel = Panel.new()
	var label = Label.new()
	var button = Button.new()
	
	panel.size = Vector2(300, 150)
	panel.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y / 2 - 75)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	panel.add_theme_stylebox_override("panel", stylebox)
	
	label.text = "Нужно собрать все грибы!\n" + str(collected_mushrooms) + "/" + str(TOTAL_MUSHROOMS)
	label.position = Vector2(10, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	
	button.text = "OK"
	button.position = Vector2(100, 90)
	button.size = Vector2(100, 40)
	button.pressed.connect(func(): 
		popup.queue_free()
		is_message_showing = false  # Сбрасываем флаг
	)
	
	panel.add_child(label)
	panel.add_child(button)
	popup.add_child(panel)
	add_child(popup)

func show_win_message():
	if game_ended:
		return
	
	game_ended = true
	print("YOU WIN! All mushrooms collected!")
	
	var popup = CanvasLayer.new()
	popup.process_mode = Node.PROCESS_MODE_ALWAYS  # ← КЛЮЧЕВОЕ: окно работает даже на паузе
	
	var panel = Panel.new()
	var label = Label.new()
	var button = Button.new()
	
	panel.size = Vector2(400, 200)
	panel.position = Vector2(get_viewport().size.x / 2 - 200, get_viewport().size.y / 2 - 100)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.3, 0.1, 0.95)
	panel.add_theme_stylebox_override("panel", stylebox)
	
	label.text = "ПОБЕДА!\nТы собрал все грибы и нашёл выход!"
	label.size = Vector2(380, 80)
	label.position = Vector2(10, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.YELLOW)
	
	button.text = "OK"
	button.size = Vector2(100, 40)
	button.position = Vector2(150, 130)
	button.pressed.connect(func(): 
		popup.queue_free()
		get_tree().paused = false
		get_tree().quit()  # Закрывает игру
	)
	
	panel.add_child(label)
	panel.add_child(button)
	popup.add_child(panel)
	add_child(popup)
	
	get_tree().paused = true
