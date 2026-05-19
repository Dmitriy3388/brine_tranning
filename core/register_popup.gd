extends Panel

func _ready():
	# Откладываем центрирование на следующий кадр
	call_deferred("center_popup")
	
	$VBoxContainer/CreateButton.pressed.connect(_on_create)
	$VBoxContainer/CancelButton.pressed.connect(_on_cancel)

func center_popup():
	# Ждем один кадр, чтобы размеры точно определились
	await get_tree().process_frame
	
	# Получаем размер экрана
	var screen_size = get_viewport().get_visible_rect().size
	
	# Получаем реальный размер попапа
	var popup_size = size
	
	print("Screen size: ", screen_size)
	print("Popup size: ", popup_size)
	
	# Вычисляем позицию для центра окна
	var center_x = (screen_size.x - popup_size.x) / 2
	var center_y = (screen_size.y - popup_size.y) / 2
	
	# Устанавливаем позицию
	position = Vector2(center_x, center_y)
	
	print("New position: ", position)

func _on_create():
	var name = $VBoxContainer/NameInput.text.strip_edges()
	
	if name.is_empty():
		PopupHelper.show_notification(
			"Ошибка",
			"Введите имя!",
			false,
			1.5,
			Callable()
		)
		return
	
	if name.length() < 2:
		PopupHelper.show_notification(
			"Ошибка",
			"Имя должно содержать хотя бы 2 буквы",
			false,
			1.5,
			Callable()
		)
		return
	
	var gender = "male" if $VBoxContainer/GenderOptions/MaleRadio.button_pressed else "female"
	var profile = ProfileManager.create_profile(name, gender)
	
	GameManager.set_profile(profile)
	GameManager.save_last_profile(profile["name"])
	
	PopupHelper.show_notification(
		"Профиль создан!",
		"Добро пожаловать, " + name + "!",
		true,
		1.5,
		func():
			GameManager.open_game_selector()
	)

func _on_cancel():
	GameManager.open_main_menu()
