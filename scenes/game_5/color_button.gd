extends TextureButton

signal color_selected(color)

@export var button_color: Color = Color.WHITE

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	color_selected.emit(button_color)
