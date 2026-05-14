extends Node2D

var items_db = []
var current_items = []
var current_trait = ""
var correct_answer_index = -1
var score = 0
var mistakes = 0
const MAX_MISTAKES = 5
const ROUNDS_TO_WIN = 20
var completed_rounds = 0

@onready var grid = $GridContainer
@onready var score_label = $UI/ScoreLabel
@onready var message_label = $UI/MessageLabel
@onready var trait_label = $UI/TraitLabel

var trait_map = {
	"a": "живое",
	"b": "водоплавающее",
	"c": "летает",
	"d": "хищник",
	"e": "домашнее",
	"f": "имеет ноги",
	"g": "пушистое"
}

var reliable_traits = ["живое", "домашнее", "летает", "пушистое", "имеет ноги"]
var requires_alive_filter = ["летает", "водоплавающее", "хищник", "домашнее"]

func _ready():
	load_items_from_folder()
	new_round()

func load_items_from_folder():
	items_db.clear()
	var dir = DirAccess.open("res://assets/game_1/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				var full_name = file_name.replace(".png", "")
				var parts = full_name.split("_")
				var trait_letters = parts[0] if parts.size() > 0 else ""
				var item_name = parts[1] if parts.size() > 1 else full_name
				var traits = {}
				for letter in trait_letters:
					if trait_map.has(letter):
						traits[trait_map[letter]] = true
				items_db.append({
					"id": full_name,
					"name": item_name,
					"texture_path": "res://assets/game_1/items/" + file_name,
					"traits": traits
				})
			file_name = dir.get_next()
		dir.list_dir_end()

func get_working_pool():
	if current_trait in requires_alive_filter:
		var alive_items = []
		for item in items_db:
			if item["traits"].get("живое", false) == true:
				alive_items.append(item)
		return alive_items
	return items_db

func select_random_trait():
	var true_traits = []
	for traits in reliable_traits:
		var working_pool = items_db
		if traits in requires_alive_filter:
			working_pool = []
			for item in items_db:
				if item["traits"].get("живое", false) == true:
					working_pool.append(item)
		var with_trait = 0
		var without_trait = 0
		for item in working_pool:
			if item["traits"].get(traits, false) == true:
				with_trait += 1
			else:
				without_trait += 1
		if with_trait >= 3 and without_trait >= 1:
			true_traits.append(traits)
	if true_traits.size() == 0:
		current_trait = reliable_traits[0]
	else:
		current_trait = true_traits[randi() % true_traits.size()]

func new_round():
	clear_grid()
	select_random_trait()
	generate_round()
	display_items()
	update_ui()
	update_trait_label()

func clear_grid():
	for child in grid.get_children():
		child.queue_free()

func generate_round():
	current_items.clear()
	var working_pool = get_working_pool()
	var items_with_trait = []
	var items_without_trait = []
	
	for item in working_pool:
		if item["traits"].get(current_trait, false) == true:
			items_with_trait.append(item)
		else:
			items_without_trait.append(item)
	
	if items_with_trait.size() < 3:
		select_random_trait()
		generate_round()
		return
	
	if items_without_trait.size() < 1:
		select_random_trait()
		generate_round()
		return
	
	items_with_trait.shuffle()
	for i in range(3):
		current_items.append(items_with_trait[i])
	
	items_without_trait.shuffle()
	current_items.append(items_without_trait[0])
	current_items.shuffle()
	
	for i in range(current_items.size()):
		if current_items[i]["traits"].get(current_trait, false) == false:
			correct_answer_index = i
			break

func display_items():
	for item in current_items:
		var button = TextureButton.new()
		button.texture_normal = load(item["texture_path"])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(100, 100)
		button.pressed.connect(_on_item_pressed.bind(button))
		grid.add_child(button)

func _on_item_pressed(button):
	var index = button.get_index()
	
	if index == correct_answer_index:
		score += 1
		completed_rounds += 1
		
		# Моментальная обратная связь через message_label
		message_label.text = "✓ Правильно!"
		message_label.modulate = Color.GREEN
		
		if completed_rounds >= ROUNDS_TO_WIN:
			_on_game_complete()
		else:
			new_round()
	else:
		mistakes += 1
		var correct_item = current_items[correct_answer_index]
		
		# Моментальная обратная связь через message_label
		message_label.text = "✗ Неверно! Лишний: " + correct_item["name"]
		message_label.modulate = Color.RED
		update_ui()
		
		if mistakes >= MAX_MISTAKES:
			_on_game_over()

func _on_game_complete():
	GameManager.complete_game("game_1")
	
	PopupHelper.show_notification(
		"🏆 ПОБЕДА!",
		"Ты набрал " + str(score) + " очков!\n✨ +" + str(GameManager.STARS_REWARD) + " звезды!",
		true,
		2.0,
		func(): 
			GameManager.open_game_selector()
	)
	
	set_process(false)

func _on_game_over():
	PopupHelper.show_notification(
		"💀 ИГРА ОКОНЧЕНА",
		"Счёт: " + str(score) + "\nПопробуй ещё раз!",
		false,
		2.0,
		func(): 
			GameManager.open_game_selector()
	)
	
	set_process(false)

func update_ui():
	var rounds_text = str(completed_rounds) + "/" + str(ROUNDS_TO_WIN)
	score_label.text = "⭐ " + str(score) + "  |  ❌ " + str(mistakes) + "/" + str(MAX_MISTAKES) + "  |  🔄 " + rounds_text

func update_trait_label():
	var trait_display = {
		"живое": "ЖИВОЕ",
		"водоплавающее": "ВОДОПЛАВАЮЩЕЕ",
		"летает": "ЛЕТАЕТ",
		"хищник": "ХИЩНИК",
		"домашнее": "ДОМАШНЕЕ",
		"имеет ноги": "ИМЕЕТ НОГИ",
		"пушистое": "ПУШИСТОЕ"
	}
	trait_label.text = "❓ Найди лишнее: " + trait_display.get(current_trait, current_trait)
