extends Panel

func _ready():
	load_profiles()
	$VBoxContainer/SelectButton.pressed.connect(_on_select)
	$VBoxContainer/BackButton.pressed.connect(_on_back)

func load_profiles():
	var profiles = ProfileManager.get_all_profiles()
	var list = $ProfilesList
	
	list.clear()
	list.add_theme_color_override("font_color", Color(0, 0, 0))
	list.add_theme_color_override("bg_color", Color(1, 1, 1))
	list.add_theme_color_override("selection_color", Color(0.5, 0.5, 0.5))
	list.add_theme_constant_override("item_separation", 40)
	list.add_theme_font_size_override("font_size", 24)
	
	for p in profiles:
		var text = p.name + " (" + p.gender + ")"
		list.add_item(text)
	
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
	
	var profiles = ProfileManager.get_all_profiles()
	var profile = profiles[selected[0]]
	
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
