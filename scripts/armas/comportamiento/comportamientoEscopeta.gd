extends comportamientoArma
class_name comportamientoEscopeta

@export var vida_bala : float

@export var bala : PackedScene = preload("res://scenes/bala/balaEscopeta.tscn")

@export var cant_perdigones : int
@export var dispersion: float = 15.0

func get_cant_perdigones() ->int:
	return cant_perdigones

func get_vida_bala() -> float:
	return vida_bala
