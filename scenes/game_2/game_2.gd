extends Node2D

@onready var profession_sprite = $ProfessionSprite
@onready var grid = $GridContainer
@onready var score_label = $UI/ScoreLabel
@onready var round_label = $UI/RoundLabel
@onready var profession_label = $UI/ProfessionLabel
@onready var message_label = $UI/MessageLabel
@onready var next_button = $UI/NextButton

var professions_db = []
var items_db = []           # [{id, texture_path, profession}]
var current_profession = null
var current_items = []
var correct_ids = []
var selected_ids = []
var score = 0
var round = 0
const TOTAL_ROUNDS = 5

func _ready():
	load_all_from_filesystem()
	setup_ui_positions()
	next_round()

func load_all_from_filesystem():
	load_professions_from_folder()
	load_items_from_folder()
	print("Loaded professions: ", professions_db.size())
	print("Loaded items: ", items_db.size())

func load_professions_from_folder():
	professions_db.clear()
	var dir = DirAccess.open("res://assets/game_2/professions/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				var id = file_name.replace(".png", "")
				professions_db.append({
					"id": id,
					"name": id.capitalize(),
					"texture_path": "res://assets/game_2/professions/" + file_name
				})
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Error: Cannot open professions folder")

func load_items_from_folder():
	items_db.clear()
	var dir = DirAccess.open("res://assets/game_2/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				var id = file_name.replace(".png", "")
				var parts = id.split("_")
				var profession = parts[0] if parts.size() > 0 else "unknown"
				items_db.append({
					"id": id,
					"profession": profession,
					"texture_path": "res://assets/game_2/items/" + file_name
				})
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Error: Cannot open items folder")

func get_items_for_profession(profession_id):
	var result = []
	for item in items_db:
		if item["profession"] == profession_id:
			result.append(item)
	return result

func get_other_items(profession_id):
	var result = []
	for item in items_db:
		if item["profession"] != profession_id:
			result.append(item)
	return result

func next_round():
	if round >= TOTAL_ROUNDS:
		game_over()
		return
	
	selected_ids.clear()
	current_items.clear()
	
	# Выбираем случайную профессию
	current_profession = professions_db[randi() % professions_db.size()]
	var prof_id = current_profession["id"]
	
	# Загружаем спрайт профессии
	profession_sprite.texture = load(current_profession["texture_path"])
	
	# Получаем правильные предметы
	var profession_items = get_items_for_profession(prof_id)
	profession_items.shuffle()
	correct_ids = []
	for i in range(min(3, profession_items.size())):
		var item = profession_items[i]
		correct_ids.append(item["id"])
		current_items.append({
			"id": item["id"],
			"texture_path": item["texture_path"]
		})
	
	# Получаем неправильные предметы
	var other_items = get_other_items(prof_id)
	other_items.shuffle()
	for i in range(3):
		var item = other_items[i]
		current_items.append({
			"id": item["id"],
			"texture_path": item["texture_path"]
		})
	
	current_items.shuffle()
	
	update_ui()
	display_items()
	round += 1

func display_items():
	clear_grid()
	for item in current_items:
		var button = TextureButton.new()
		button.texture_normal = load(item["texture_path"])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(80, 80)
		
		if item["id"] in selected_ids:
			button.modulate = Color(0.5, 0.5, 0.5)
		
		button.pressed.connect(_on_item_pressed.bind(button, item["id"]))
		grid.add_child(button)

func clear_grid():
	for child in grid.get_children():
		child.queue_free()

func _on_item_pressed(button, id):
	if id in selected_ids:
		message_label.text = "You already selected this!"
		message_label.modulate = Color.YELLOW
		return
	
	if selected_ids.size() >= 3:
		message_label.text = "Select only 3 items!"
		message_label.modulate = Color.YELLOW
		return
	
	selected_ids.append(id)
	button.modulate = Color(0.5, 0.5, 0.5)
	
	if selected_ids.size() == 3:
		check_answer()

func check_answer():
	var correct_count = 0
	for id in selected_ids:
		if id in correct_ids:
			correct_count += 1
	
	if correct_count == 3:
		score += 1
		message_label.text = "✓ Correct! +1"
		message_label.modulate = Color.GREEN
	else:
		var wrong_count = 3 - correct_count
		message_label.text = "✗ Wrong! " + str(wrong_count) + " incorrect"
		message_label.modulate = Color.RED
	
	update_ui()
	await get_tree().create_timer(1.5).timeout
	next_round()

func update_ui():
	score_label.text = "Score: " + str(score)
	round_label.text = "Round: " + str(round) + "/" + str(TOTAL_ROUNDS)
	profession_label.text = current_profession["name"]

func game_over():
	message_label.text = "GAME OVER! Score: " + str(score) + "/" + str(TOTAL_ROUNDS)
	message_label.modulate = Color.RED
	next_button.visible = true
	get_tree().paused = true

func _on_next_button_pressed():
	get_tree().paused = false
	next_button.visible = false
	score = 0
	round = 0
	next_round()

func setup_ui_positions():
	score_label.position = Vector2(20, 20)
	round_label.position = Vector2(900, 20)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profession_label.position = Vector2(540, 550)
	profession_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(540, 1700)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_button.position = Vector2(440, 1600)
	next_button.visible = false
	next_button.pressed.connect(_on_next_button_pressed)
