extends Node2D

@onready var profession_sprite = $ProfessionSprite
@onready var grid = $GridContainer
@onready var score_label = $UI/ScoreLabel
@onready var round_label = $UI/RoundLabel
@onready var profession_label = $UI/ProfessionLabel
@onready var message_label = $UI/MessageLabel
@onready var next_button = $UI/NextButton

var professions_db = []
var items_db = []
var current_profession = null
var current_items = []
var correct_ids = []
var selected_ids = []
var score = 0
var round = 0
var mistakes = 0
const TOTAL_ROUNDS = 5
const MAX_MISTAKES = 3

func _ready():
	load_all_from_filesystem()
	next_round()

func load_all_from_filesystem():
	load_professions_from_folder()
	load_items_from_folder()

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
	round += 1
	
	if round > TOTAL_ROUNDS:
		_on_game_complete()
		return
	
	selected_ids.clear()
	current_items.clear()
	current_profession = professions_db[randi() % professions_db.size()]
	var prof_id = current_profession["id"]
	
	profession_sprite.texture = load(current_profession["texture_path"])
	
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

func display_items():
	clear_grid()
	for item in current_items:
		var button = TextureButton.new()
		button.texture_normal = load(item["texture_path"])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(120, 120)  # Увеличено с 80x80
		
		if item["id"] in selected_ids:
			button.modulate = Color(0.5, 0.5, 0.5)
		
		button.pressed.connect(_on_item_pressed.bind(button, item["id"]))
		grid.add_child(button)

func clear_grid():
	for child in grid.get_children():
		child.queue_free()

func _on_item_pressed(button, id):
	if id in selected_ids:
		message_label.text = "⚠️ Этот предмет уже выбран!"
		message_label.modulate = Color.YELLOW
		return
	
	if id not in correct_ids:
		mistakes += 1
		message_label.text = "✗ Ошибка! Осталось ошибок: " + str(MAX_MISTAKES - mistakes)
		message_label.modulate = Color.RED
		update_ui()
		
		if mistakes >= MAX_MISTAKES:
			set_process(false)
			_on_game_over()
		return
	
	selected_ids.append(id)
	button.modulate = Color(0.5, 0.5, 0.5)
	message_label.text = "✓ Правильно!"
	message_label.modulate = Color.GREEN
	update_ui()
	
	if selected_ids.size() >= 3:
		score += 1
		message_label.text = "✓ Раунд пройден! +1 очко"
		message_label.modulate = Color.GREEN
		update_ui()
		await get_tree().create_timer(1.5).timeout
		next_round()

func update_ui():
	score_label.text = "🏆 " + str(score) + "/" + str(TOTAL_ROUNDS)
	round_label.text = "📊 Раунд: " + str(round) + "/" + str(TOTAL_ROUNDS)
	profession_label.text = "💼 " + current_profession["name"]

func _on_game_complete():
	GameManager.complete_game("game_2")
	
	PopupHelper.show_notification(
		"🏆 ПОБЕДА!",
		"Счёт: " + str(score) + "/" + str(TOTAL_ROUNDS) + "\n✨ +" + str(GameManager.STARS_REWARD) + " звезды!",
		true,
		2.0,
		func(): 
			GameManager.open_game_selector()
	)
	
	set_process(false)

func _on_game_over():
	PopupHelper.show_notification(
		"💀 ИГРА ОКОНЧЕНА",
		"Слишком много ошибок!\nПопробуй ещё раз!",
		false,
		2.0,
		func(): 
			GameManager.open_game_selector()
	)
