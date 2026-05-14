extends Panel

func _ready():
	$VBoxContainer/CreateButton.pressed.connect(_on_create)
	$VBoxContainer/CancelButton.pressed.connect(_on_cancel)

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
