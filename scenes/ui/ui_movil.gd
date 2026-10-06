extends CanvasLayer

@onready var joystick: Joystick = %Joystick

func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		layer = 100
		visible = true
		await get_tree().process_frame
		GlobalSignal.enviar_joystick.emit(joystick)
	else:
		layer = 1
		visible = false
		
