extends PopupPanel

var close_button: Button
var switch_user_button: Button
var music_slider: HSlider
var sound_slider: HSlider

func _ready():
	close_button = $VBoxContainer/CloseButton
	switch_user_button = $VBoxContainer/SwitchUserButton
	music_slider = $VBoxContainer/MusicSlider
	sound_slider = $VBoxContainer/SoundSlider
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if switch_user_button:
		switch_user_button.pressed.connect(_on_switch_user_pressed)
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	
	if sound_slider:
		sound_slider.value_changed.connect(_on_sound_changed)
	
	_load_settings()
	visible = false

func _on_close_pressed():
	hide()

func _on_switch_user_pressed():
	hide()
	
	# Показываем уведомление о переходе к выбору профиля
	PopupHelper.show_notification(
		"Смена пользователя",
		"Выберите профиль из списка",
		true,
		1.5,
		func(): 
			GameManager.change_scene("res://core/profile_selector.tscn")
	)

func _on_music_changed(value: float):
	_save_settings()

func _on_sound_changed(value: float):
	_save_settings()

func _load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		if music_slider:
			music_slider.value = config.get_value("audio", "music_volume", 0.5)
		if sound_slider:
			sound_slider.value = config.get_value("audio", "sound_volume", 0.5)

func _save_settings():
	var config = ConfigFile.new()
	if music_slider:
		config.set_value("audio", "music_volume", music_slider.value)
	if sound_slider:
		config.set_value("audio", "sound_volume", sound_slider.value)
	config.save("user://settings.cfg")
