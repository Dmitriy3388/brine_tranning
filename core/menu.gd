extends CanvasLayer

@onready var selector = $PopupPanel/PlayMenu/Selector
@onready var main_menu = $PopupPanel/PlayMenu/MainMenu
@onready var line_menu = $LineMenu/LineMenuButton
@onready var back = $PopupPanel/PlayMenu/Back
@onready var popup_panel = $PopupPanel


func _ready():
	popup_panel.visible = false
	selector.pressed.connect(_on_selector)
	main_menu.pressed.connect(_on_main_menu)
	line_menu.pressed.connect(_on_line_menu)
	back.pressed.connect(_on_back)


func _on_line_menu():
	popup_panel.visible = true


func _on_back():
	popup_panel.visible = false


func _on_main_menu():
	GameManager.open_main_menu()


func _on_selector():
	GameManager.open_game_selector()
