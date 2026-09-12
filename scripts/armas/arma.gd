extends Resource
class_name Arma


enum TipoArma {
	MELEE,
	COMUN,
	EXPLOSIVA
}
@export var id: int #o usar un StringName (nombre unico, genial!)
@export var nombre: String

@export var danio: float

@export var sprite: PackedScene #el tipo que sea esto

@export var tiempoDeAtaque: int

@export var tipo : TipoArma
@export var comportamiento: comportamientoArma

#Mas adelante, si quisiera agregar modificadores:
#@export var comportamientos: Array[ComportamientoArma] = []
