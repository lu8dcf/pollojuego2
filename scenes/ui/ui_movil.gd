extends CanvasLayer

@onready var joystick: Joystick = %Joystick
@onready var touch_button_revivir: TouchScreenButton = %TouchButtonRevivir
@onready var touch_button_habilidad: TouchScreenButton = %TouchButtonHabilidad
@onready var touch_button_arma_1: TouchScreenButton = %TouchButtonArma1
@onready var touch_button_arma_2: TouchScreenButton = %TouchButtonArma2
@onready var touch_button_arma_3: TouchScreenButton = %TouchButtonArma3
@onready var touch_button_arma_4: TouchScreenButton = %TouchButtonArma4
@onready var touch_button_arma_5: TouchScreenButton = %TouchButtonArma5
@onready var touch_button_arma_6: TouchScreenButton = %TouchButtonArma6

func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		layer = 100
		visible = true
		await get_tree().process_frame
		GlobalSignal.enviar_joystick.emit(joystick)
		
	else:
		layer = 1
		visible = false
		
