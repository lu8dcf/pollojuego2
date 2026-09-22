extends CanvasLayer

@onready var joystick: Joystick = %Joystick

func _ready() -> void:
	if OS.has_feature("mobile"):
		await get_tree().process_frame 
		GlobalSignal.enviar_joystick.emit(joystick)
	else:
		pass
		
