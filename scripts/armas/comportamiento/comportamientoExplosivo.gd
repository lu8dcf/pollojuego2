extends comportamientoArma
class_name comportamientoExplosiva

@export var rango_explosivo : int

@export var danio_explosion : float

@export var tiempo_espoleta : float

@export var bala : PackedScene = preload("uid://b635l88o7cpj4")


func get_tiempoEspoleta() -> float:
	return tiempo_espoleta
