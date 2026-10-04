extends Node3D

@onready var barraVerde = $barraVerde
var esVisible: bool = false

func bajarVida(porcentaje: float) -> void:
	if (!esVisible):
		esVisible = true
		visible = true
		
	if porcentaje <= 0:
		esVisible = false
		visible = false
	
	if(barraVerde.scale.y > 0):
		barraVerde.scale.y = porcentaje
