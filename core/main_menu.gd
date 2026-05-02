extends Control

func _ready():
	$MenuButtons/PlayButton.pressed.connect(_on_play)
	$MenuButtons/ContinueButton.pressed.connect(_on_continue)
	$MenuButtons/QuitButton.pressed.connect(_on_quit)

	var has_profiles = ProfileManager.get_all_profiles().size() > 0
	$MenuButtons/ContinueButton.visible = has_profiles


func _on_play():
	GameManager.change_scene("res://core/register_popup.tscn")


func _on_continue():
	var profiles = ProfileManager.get_all_profiles()
	if profiles.is_empty():
		return

	GameManager.change_scene("res://core/profile_selector.tscn")


func _on_quit():
	get_tree().quit()
