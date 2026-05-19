extends CanvasLayer

@onready var selector = $PopupPanel/PlayMenu/Selector
@onready var main_menu_btn = $PopupPanel/PlayMenu/MainMenu
@onready var line_menu = $LineMenu/LineMenuButton
@onready var back = $PopupPanel/PlayMenu/Back
@onready var popup_panel = $PopupPanel
@onready var line_menu_container = $LineMenu
@onready var play_menu_container = $PopupPanel/PlayMenu

var close_callback: Callable = Callable()
var pending_action: String = ""
var is_in_game_selector: bool = false

func set_context(in_selector: bool):
	print("set_context called, is_in_game_selector = ", in_selector)
	is_in_game_selector = in_selector
	
	# Управляем видимостью кнопки "Выбор Игры"
	if is_in_game_selector:
		selector.visible = false  # В Game Selector'е скрываем
		print("Кнопка 'Выбор Игры' СКРЫТА")
	else:
		selector.visible = true   # В играх показываем
		print("Кнопка 'Выбор Игры' ВИДНА")
	
	_adjust_popup_size()

func _ready():
	# Скрываем панель при старте
	popup_panel.visible = false
	
	# Скрываем LineMenu (кнопка с тремя полосками) - она нам не нужна
	line_menu_container.visible = false
	
	# Кнопка "Выбор Игры" по умолчанию видна (для игр)
	# Потом set_context() изменит если нужно
	selector.visible = true
	
	selector.pressed.connect(_on_selector)
	main_menu_btn.pressed.connect(_on_main_menu)
	back.pressed.connect(_on_back)
	
	_adjust_popup_size()

func _adjust_popup_size():
	await get_tree().process_frame
	
	if not is_instance_valid(popup_panel) or not is_instance_valid(play_menu_container):
		return
	
	var min_size = play_menu_container.get_combined_minimum_size()
	
	var panel_style = popup_panel.get_theme_stylebox("panel")
	if panel_style:
		min_size.x += panel_style.content_margin_left + panel_style.content_margin_right
		min_size.y += panel_style.content_margin_top + panel_style.content_margin_bottom
	else:
		min_size.x += 20
		min_size.y += 20
	
	popup_panel.size = Vector2i(int(min_size.x), int(min_size.y))

func connect_close_callback(callback: Callable):
	close_callback = callback

# Этот метод вызывается из TopBar для открытия/закрытия панели
func toggle_panel():
	if popup_panel.visible:
		popup_panel.visible = false
		if close_callback.is_valid():
			close_callback.call()
	else:
		popup_panel.visible = true
		_adjust_popup_size()

func _on_back():
	popup_panel.visible = false
	if close_callback.is_valid():
		close_callback.call()

func _on_main_menu():
	pending_action = "main_menu"
	
	if is_in_game_selector:
		_on_confirmed()
	else:
		_show_confirmation()

func _on_selector():
	pending_action = "selector"
	
	if is_in_game_selector:
		_on_confirmed()
	else:
		_show_confirmation()

func _show_confirmation():
	popup_panel.visible = false
	PopupHelper.show_confirmation(
		"Подтверждение",
		"Весь прогресс в текущей игре будет потерян. Продолжить?",
		_on_confirmed,
		_on_canceled
	)

func _on_confirmed():
	match pending_action:
		"main_menu":
			GameManager.open_main_menu()
		"selector":
			GameManager.open_game_selector()
	pending_action = ""
	if close_callback.is_valid():
		close_callback.call()

func _on_canceled():
	pending_action = ""
	popup_panel.visible = true
	_adjust_popup_size()
