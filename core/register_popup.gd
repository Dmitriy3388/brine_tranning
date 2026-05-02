extends Panel

func _ready():
	$VBoxContainer/CreateButton.pressed.connect(_on_create)
	$VBoxContainer/CancelButton.pressed.connect(_on_cancel)


func _on_create():
	var name = $VBoxContainer/NameInput.text.strip_edges()
	if name.is_empty():
		return

	var gender = "male" if $VBoxContainer/GenderOptions/MaleRadio.button_pressed else "female"
	var profile = ProfileManager.create_profile(name, gender)
	GameManager.set_profile(profile)
	GameManager.open_game_selector()


func _on_cancel():
	GameManager.open_main_menu()
