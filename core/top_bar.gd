extends CanvasLayer

@onready var menu_button = $Panel/HBoxContainer/MenuButton
@onready var avatar_rect = $Panel/HBoxContainer/Avatar
@onready var name_label = $Panel/HBoxContainer/Name
@onready var stars_label = $Panel/HBoxContainer/Stars
@onready var game_stats_label = $Panel/HBoxContainer/GameStats
@onready var popup_panel = $Panel/PopupPanel
@onready var selector_button = $Panel/PopupPanel/PlayMenu/Selector
@onready var main_menu_button = $Panel/PopupPanel/PlayMenu/MainMenu
@onready var back_button = $Panel/PopupPanel/PlayMenu/Back

var is_in_game_selector: bool = false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_display()
	
	# Скрываем панель при старте
	popup_panel.visible = false
	
	# Подключаем кнопки
	menu_button.pressed.connect(_on_menu_button_pressed)
	selector_button.pressed.connect(_on_selector_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	if not GameManager.stars_updated.is_connected(_on_stars_updated):
		GameManager.stars_updated.connect(_on_stars_updated)
		
	if not GameManager.game_exited.is_connected(_on_game_exited):
		GameManager.game_exited.connect(_on_game_exited)

func _on_game_exited():
	clear_game_stats()

func _on_menu_button_pressed():
	# ОПРЕДЕЛЯЕМ КОНТЕКСТ ПРАВИЛЬНО
	is_in_game_selector = false
	
	# Проверяем через GameManager._current_scene
	if GameManager._current_scene:
		var scene_path = GameManager._current_scene.scene_file_path
		print("Текущая сцена: ", scene_path)
		
		if scene_path == "res://core/game_selector.tscn":
			is_in_game_selector = true
			print("Мы в Game Selector'е - скрываем кнопку 'Выбор Игры'")
		else:
			print("Мы в игре - показываем кнопку 'Выбор Игры'")
	
	# Управляем видимостью кнопки "Выбор Игры"
	selector_button.visible = not is_in_game_selector
	
	# Открываем или закрываем панель
	popup_panel.visible = not popup_panel.visible
	
	# Подгоняем размер панели
	if popup_panel.visible:
		await get_tree().process_frame
		_adjust_popup_size()

func _adjust_popup_size():
	var min_size = $Panel/PopupPanel/PlayMenu.get_combined_minimum_size()
	popup_panel.size = Vector2i(min_size.x + 20, min_size.y + 20)
	# Центрируем панель
	popup_panel.popup_centered()

func _on_selector_pressed():
	# Закрываем панель и переходим к выбору игр
	popup_panel.visible = false
	GameManager.open_game_selector()

func _on_main_menu_pressed():
	popup_panel.visible = false
	
	# Если мы в игре - показываем предупреждение
	if not is_in_game_selector:
		PopupHelper.show_confirmation(
			"Подтверждение",
			"Весь прогресс в текущей игре будет потерян. Продолжить?",
			func():
				GameManager.open_main_menu(),
			func():
				popup_panel.visible = true
		)
	else:
		GameManager.open_main_menu()

func _on_back_pressed():
	popup_panel.visible = false

func update_game_stats(score: int, mistakes: int = -1, max_mistakes: int = 0, round_info: String = ""):
	var stats_parts = []
	
	if score >= 0:
		stats_parts.append("🏆 " + str(score))
	
	if mistakes >= 0 and max_mistakes > 0:
		stats_parts.append("❌ " + str(mistakes) + "/" + str(max_mistakes))
	
	if not round_info.is_empty():
		stats_parts.append(round_info)
	
	if stats_parts.is_empty():
		game_stats_label.text = ""
	else:
		game_stats_label.text = "  |  " + "  |  ".join(stats_parts)

func _update_display():
	var profile = GameManager.current_profile
	
	if profile.is_empty() or not profile.has("name") or profile["name"] == "":
		name_label.text = "Гость"
		_set_default_avatar()
	else:
		name_label.text = profile.get("name", "Игрок")
		
		var gender = profile.get("gender", "male")
		var avatar_path = "res://assets/ui/avatar_" + gender + ".png"
		
		if ResourceLoader.exists(avatar_path):
			avatar_rect.texture = load(avatar_path)
		else:
			_set_default_avatar()
	
	var stars = GameManager.get_stars()
	stars_label.text = "⭐ " + str(stars)

func _on_stars_updated(new_stars):
	_update_display()

func clear_game_stats():
	game_stats_label.text = ""

func _set_default_avatar():
	var image = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.6, 0.3, 1))
	var texture = ImageTexture.create_from_image(image)
	avatar_rect.texture = texture
