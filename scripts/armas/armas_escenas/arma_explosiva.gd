extends Node3D
class_name ArmaExplosiva

var datos: Arma


func atacar():
	await get_tree().create_timer(datos.comportamiento.tiempo_espoleta).timeout
	print("boom!")
