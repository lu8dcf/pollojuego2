extends comportamientoArma
class_name comportamientoExplosiva

@export var rango_explosivo : int

@export var danio_explosion : float

@export var tiempo_espoleta : float

@export var bala : PackedScene = preload("res://scenes/bala/balaExplosiva.tscn")


func get_tiempoEspoleta() -> float:
	return tiempo_espoleta
