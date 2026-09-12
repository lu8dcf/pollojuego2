extends Node3D
class_name armaBase

@export var bala = preload("res://scenes/bala/bala.tscn")

@onready var puntero = $Marker3D
@onready var sprite = $Sprite3D
@onready var tiempo = $tiempoEntreDisparo
var datos: Arma

func _ready() -> void:
	tiempo.wait_time = datos.tiempoDeAtaque
	#aplico la textura del arma
	#sprite=datos.sprite
	
	#ahora como es una packescene solo lo añado de hijo
	if(datos.sprite != null):
		add_child(datos.sprite.instantiate())


func obtengoEnemigoMasCercano():
	print("ayuda")



func _on_tiempo_disparo_timeout() -> void:
	disparo()
	tiempo.start()
	pass # Replace with function body.


func disparo():
	#Mas animacion
	var nueva_bala = bala.instantiate()
	nueva_bala.top_level = true
	nueva_bala.iniciar(datos.comportamiento,
		puntero.global_position,
		-puntero.global_transform.basis.z
	)

	add_child(nueva_bala)
