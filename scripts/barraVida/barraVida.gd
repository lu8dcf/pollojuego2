extends Node3D

@onready var barraVerde = $barraVerde
var esVisible: bool = false
var vidaCompleta

func _ready() -> void:
	vidaCompleta = barraVerde.scale.y

func bajarVida(porcentaje: float) -> void:
	if (!esVisible):
		esVisible = true
		visible = true
		
	if porcentaje <= 15: #antes de llegar a 0, el pollo va a entrar en caido
		esVisible = false
		visible = false
	
	if(barraVerde.scale.y > 0):
		barraVerde.scale.y = porcentaje


func reiniciar_barra():
	barraVerde.scale.y = 1
