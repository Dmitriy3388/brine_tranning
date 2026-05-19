extends Panel

func _ready():
	load_profiles()
	$VBoxContainer/SelectButton.pressed.connect(_on_select)
	$VBoxContainer/BackButton.pressed.connect(_on_back)

func load_profiles():
	# Быстро получаем только имена
	var profile_names = ProfileManager.get_all_profile_names()
	var list = $ProfilesList
	
	list.clear()
	list.add_theme_color_override("font_color", Color(0, 0, 0))
	list.add_theme_color_override("bg_color", Color(1, 1, 1))
	list.add_theme_color_override("selection_color", Color(0.5, 0.5, 0.5))
	list.add_theme_constant_override("item_separation", 40)
	list.add_theme_font_size_override("font_size", 24)
	
	# Добавляем ТОЛЬКО имена (без загрузки полных данных)
	for name in profile_names:
		list.add_item(name)  # Показываем только имя
	
	if list.get_item_count() > 0:
		list.select(0)

func _on_select():
	var list = $ProfilesList
	var selected = list.get_selected_items()
	
	if selected.is_empty():
		PopupHelper.show_notification(
			"Внимание",
			"Выберите профиль из списка",
			false,
			1.5,
			Callable()
		)
		return
	
	# Загружаем ТОЛЬКО выбранный профиль
	var profile_name = list.get_item_text(selected[0])
	var profile = ProfileManager.load_profile(profile_name)  # Полная загрузка только сейчас
	
	if profile.is_empty():
		PopupHelper.show_notification(
			"Ошибка",
			"Не удалось загрузить профиль",
			false,
			1.5,
			Callable()
		)
		return
	
	GameManager.set_profile(profile)
	GameManager.save_last_profile(profile["name"])
	
	PopupHelper.show_notification(
		"Профиль загружен",
		"Добро пожаловать, " + profile["name"] + "!",
		true,
		1.5,
		func():
			GameManager.open_game_selector()
	)

func _on_back():
	GameManager.open_main_menu()
