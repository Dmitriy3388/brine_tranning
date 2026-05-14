extends Control

@onready var settings_popup = $SettingsPopup

func _ready():
	$MenuButtons/PlayButton.pressed.connect(_on_play)
	$MenuButtons/ContinueButton.pressed.connect(_on_continue)
	$MenuButtons/SettingsButton.pressed.connect(_on_settings)
	$MenuButtons/QuitButton.pressed.connect(_on_quit)
	
	var has_profiles = ProfileManager.get_all_profiles().size() > 0
	$MenuButtons/ContinueButton.visible = has_profiles
	
	if settings_popup:
		settings_popup.visible = false

func _on_play():
	GameManager.change_scene("res://core/register_popup.tscn")

func _on_continue():
	var profiles = ProfileManager.get_all_profiles()
	if profiles.is_empty():
		PopupHelper.show_notification(
			"Нет профилей",
			"Создайте новый профиль через кнопку 'Играть!'",
			false,
			2.0,
			Callable()
		)
		return
	
	var last_profile_name = GameManager.load_last_profile()
	var selected_profile = null
	
	if not last_profile_name.is_empty():
		for p in profiles:
			if p.get("name", "") == last_profile_name:
				selected_profile = p
				break
	
	if selected_profile == null:
		selected_profile = profiles[0]
		for p in profiles:
			var p_time = p.get("created", "0")
			var selected_time = selected_profile.get("created", "0")
			if p_time > selected_time:
				selected_profile = p
	
	GameManager.set_profile(selected_profile)
	
	PopupHelper.show_notification(
		"Загрузка",
		"Добро пожаловать, " + selected_profile["name"] + "!",
		true,
		1.5,
		func(): 
			GameManager.open_game_selector()
	)

func _on_settings():
	if settings_popup:
		var button = $MenuButtons/SettingsButton
		var button_global_pos = button.global_position
		settings_popup.position = Vector2i(button_global_pos.x, button_global_pos.y + 50)
		settings_popup.popup()

func _on_quit():
	get_tree().quit()
