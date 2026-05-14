extends CanvasLayer

@onready var selector = $PopupPanel/PlayMenu/Selector
@onready var main_menu = $PopupPanel/PlayMenu/MainMenu
@onready var line_menu = $LineMenu/LineMenuButton
@onready var back = $PopupPanel/PlayMenu/Back
@onready var popup_panel = $PopupPanel

var confirmation_popup: ConfirmationDialog = null
var pending_action: String = ""

func _ready():
	popup_panel.visible = false
	
	selector.pressed.connect(_on_selector)
	main_menu.pressed.connect(_on_main_menu)
	line_menu.pressed.connect(_on_line_menu)
	back.pressed.connect(_on_back)
	
	_setup_confirmation_dialog()

func _setup_confirmation_dialog():
	confirmation_popup = ConfirmationDialog.new()
	confirmation_popup.title = "Подтверждение"
	confirmation_popup.dialog_text = "Весь прогресс в текущей игре будет потерян. Продолжить?"
	confirmation_popup.ok_button_text = "Да"
	confirmation_popup.cancel_button_text = "Нет"
	
	confirmation_popup.confirmed.connect(_on_confirmed)
	confirmation_popup.canceled.connect(_on_canceled)
	
	add_child(confirmation_popup)

func _on_line_menu():
	popup_panel.visible = true

func _on_back():
	popup_panel.visible = false

func _on_main_menu():
	pending_action = "main_menu"
	confirmation_popup.popup_centered()

func _on_selector():
	pending_action = "selector"
	confirmation_popup.popup_centered()

func _on_confirmed():
	match pending_action:
		"main_menu":
			GameManager.open_main_menu()
		"selector":
			GameManager.open_game_selector()
	
	pending_action = ""
	popup_panel.visible = false

func _on_canceled():
	pending_action = ""
