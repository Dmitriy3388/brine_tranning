extends Node2D

# --- Ссылки на узлы в сцене ---
@onready var tile_map: TileMapLayer = $Labirint
@onready var player: CharacterBody2D = $Player
@onready var mushrooms_container = $Mushrooms
@onready var mushroom_counter: Label = $UI/MushroomCounter

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
	
	generate_maze()
	visualize_maze()
	setup_player()
	spawn_mushrooms()
	update_mushroom_counter()
	
	print("=== GAME READY ===")

func generate_maze():
	grid = []
	for y in range(height):
		grid.append([])
		for x in range(width):
			grid[y].append(false)
	
	var start_x = 1
	var start_y = 1
	grid[start_y][start_x] = true
	
	carve_maze(start_x, start_y)
	create_exit()

func create_exit():
	exit_cell = Vector2i(width - 1, height - 2)
	
	if grid[exit_cell.y][exit_cell.x - 1]:
		grid[exit_cell.y][exit_cell.x] = true
	else:
		grid[exit_cell.y][exit_cell.x - 1] = true
		grid[exit_cell.y][exit_cell.x] = true

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
	if tile_map == null:
		return
	
	tile_map.clear()
	
	if tile_map.tile_set == null:
		return
	
	for y in range(height):
		for x in range(width):
			var cell_pos = Vector2i(x, y)
			
			if not grid[y][x]:
				var random_wall = wall_variants[randi() % wall_variants.size()]
				tile_map.set_cell(cell_pos, source_id, random_wall)
	
	tile_map.position = maze_offset

func setup_player():
	if tile_map == null:
		return
	
	var player_start_pos = Vector2i(1, 1)
	for x in range(1, width - 1):
		if grid[1][x]:
			player_start_pos = Vector2i(x, 1)
			break
	
	var player_local_pos = tile_map.map_to_local(player_start_pos) + maze_offset
	player.position = player_local_pos
	
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		camera.enabled = true

func update_mushroom_counter():
	if mushroom_counter:
		mushroom_counter.text = "🍄 " + str(collected_mushrooms) + "/" + str(TOTAL_MUSHROOMS)
		if collected_mushrooms >= TOTAL_MUSHROOMS:
			mushroom_counter.add_theme_color_override("font_color", Color.GREEN)
		else:
			mushroom_counter.add_theme_color_override("font_color", Color.WHITE)

func _on_mushroom_collected():
	collected_mushrooms += 1
	update_mushroom_counter()
	
	if collected_mushrooms >= TOTAL_MUSHROOMS:
		print("All mushrooms collected! Find the exit!")

func spawn_mushrooms():
	var free_cells = []
	
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if grid[y][x]:
				free_cells.append(Vector2i(x, y))
	
	free_cells.shuffle()
	var selected_cells = free_cells.slice(0, TOTAL_MUSHROOMS)
	
	for pos in selected_cells:
		var mushroom = mushroom_scene.instantiate()
		var world_pos = tile_map.map_to_local(pos) + maze_offset
		mushroom.position = world_pos
		mushroom.add_to_group("mushrooms")
		mushroom.collected.connect(_on_mushroom_collected)
		mushrooms_container.add_child(mushroom)

func show_cannot_exit_message():
	if game_ended:
		return
	
	PopupHelper.show_notification(
		"🚪 Выход закрыт",
		"Нужно собрать все грибы!\n🍄 " + str(collected_mushrooms) + "/" + str(TOTAL_MUSHROOMS),
		false,
		2.0,
		Callable()
	)

func show_win_message():
	if game_ended:
		return
	
	game_ended = true
	GameManager.complete_game("game_3")
	
	PopupHelper.show_notification(
		"🏆 ПОБЕДА!",
		"Ты собрал все грибы и нашёл выход!\n✨ +" + str(GameManager.STARS_REWARD) + " звезды!",
		true,
		2.0,
		func():
			get_tree().paused = false
			GameManager.open_game_selector()
	)
	
	get_tree().paused = true
