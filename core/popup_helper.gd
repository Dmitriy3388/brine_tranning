extends CanvasLayer

var popup_style: StyleBoxFlat
var theme_resource: Theme = null
var active_popup: PopupPanel = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_style()
	_load_theme()
	hide()

func _load_style():
	if ResourceLoader.exists("res://core/resourses/popup_style.tres"):
		popup_style = load("res://core/resourses/popup_style.tres")
		print("Popup style loaded successfully")
	else:
		print("Warning: popup_style.tres not found, creating default style")
		_create_default_style()

func _load_theme():
	if ResourceLoader.exists("res://core/resourses/theme.tres"):
		theme_resource = load("res://core/resourses/theme.tres")
		print("Theme loaded successfully")
	else:
		print("Warning: theme.tres not found")

func _create_default_style():
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	popup_style.border_width_left = 2
	popup_style.border_width_right = 2
	popup_style.border_width_top = 2
	popup_style.border_width_bottom = 2
	popup_style.border_color = Color(0.3, 0.7, 0.3, 1)
	popup_style.corner_radius_top_left = 10
	popup_style.corner_radius_top_right = 10
	popup_style.corner_radius_bottom_left = 10
	popup_style.corner_radius_bottom_right = 10

func _apply_theme_to_button(button: Button):
	if theme_resource:
		button.theme = theme_resource
		button.add_theme_font_size_override("font_size", 22)
		button.custom_minimum_size = Vector2(110, 45)
	else:
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2, 1))
		button.custom_minimum_size = Vector2(110, 45)

func show_notification(title: String, message: String, is_success: bool = true, duration: float = 2.0, on_closed: Callable = Callable()):
	if active_popup:
		active_popup.queue_free()
		active_popup = null
	
	var popup = PopupPanel.new()
	popup.title = title
	popup.exclusive = true
	popup.popup_window = false
	
	if popup_style:
		popup.add_theme_stylebox_override("panel", popup_style)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_top", 25)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_bottom", 25)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size = Vector2(280, 0)
	
	if is_success:
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.add_theme_color_override("font_color", Color.RED)
	
	vbox.add_child(label)
	margin_container.add_child(vbox)
	popup.add_child(margin_container)
	
	add_child(popup)
	active_popup = popup
	
	await get_tree().process_frame
	
	var min_width = max(350, margin_container.get_combined_minimum_size().x + 40)
	var current_size = popup.size
	popup.size = Vector2i(min_width, current_size.y)
	
	popup.popup_centered()
	
	await get_tree().create_timer(duration).timeout
	
	if active_popup == popup and popup and is_instance_valid(popup):
		popup.queue_free()
		active_popup = null
		if on_closed.is_valid():
			on_closed.call()

func show_confirmation(title: String, message: String, on_confirm: Callable = Callable(), on_cancel: Callable = Callable()):
	if active_popup:
		active_popup.queue_free()
		active_popup = null
	
	var popup = PopupPanel.new()
	popup.title = title
	popup.exclusive = true
	popup.popup_window = false
	
	if popup_style:
		popup.add_theme_stylebox_override("panel", popup_style)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 35)
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_right", 35)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size = Vector2(300, 0)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = HBoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 25)
	
	var confirm_button = Button.new()
	confirm_button.text = "Да"
	_apply_theme_to_button(confirm_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Нет"
	_apply_theme_to_button(cancel_button)
	
	confirm_button.pressed.connect(func():
		popup.queue_free()
		active_popup = null
		if on_confirm.is_valid():
			on_confirm.call()
	)
	
	cancel_button.pressed.connect(func():
		popup.queue_free()
		active_popup = null
		if on_cancel.is_valid():
			on_cancel.call()
	)
	
	buttons_container.add_child(confirm_button)
	buttons_container.add_child(cancel_button)
	vbox.add_child(label)
	vbox.add_child(buttons_container)
	margin_container.add_child(vbox)
	popup.add_child(margin_container)
	
	add_child(popup)
	active_popup = popup
	
	await get_tree().process_frame
	
	var min_width = max(380, margin_container.get_combined_minimum_size().x + 40)
	var current_size = popup.size
	popup.size = Vector2i(min_width, current_size.y)
	
	popup.popup_centered()

func close_notification():
	if active_popup:
		active_popup.queue_free()
		active_popup = null
