extends Control

@onready var stars_label = $StarsLabel


func _ready():
	$SelectorButtons/Game1.pressed.connect(_on_game1)
	$SelectorButtons/Game2.pressed.connect(_on_game2)
	$SelectorButtons/Game3.pressed.connect(_on_game3)
	$SelectorButtons/Game4.pressed.connect(_on_game4)
	$SelectorButtons/Game5.pressed.connect(_on_game5)
	$SelectorButtons/Back.pressed.connect(_on_back)

	_update_stars_display()


func _update_stars_display():
	if stars_label:
		stars_label.text = "Звёзды: " + str(GameManager.get_stars())


func _on_game1():
	GameManager.start_game("game_1")

func _on_game2():
	GameManager.start_game("game_2")


func _on_game3():
	GameManager.start_game("game_3")

func _on_game4():
	GameManager.start_game("game_4")

func _on_game5():
	GameManager.start_game("game_5")


func _on_back():
	GameManager.open_main_menu()
