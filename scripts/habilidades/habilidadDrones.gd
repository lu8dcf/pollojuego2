class_name HabilidadDrones
extends Habilidad

@export var cantidad_drones: int = 2
var droneScene = preload("res://scenes/habilidad/dron_1.tscn")
var puedoUsar = true

func usar() -> void:
	if jugador == null:
		print("jug null")
		return
	if(puedoUsar):
		puedoUsar = false
		var dronHijo = droneScene.instantiate()
		add_child(dronHijo)
		dronHijo.position = $Marker3D.global_position
		await  get_tree().create_timer(4).timeout
		dronHijo.queue_free()
	#
#func usar() -> void:
	#solicitar_usar.rpc_id(1)
#
#
#@rpc("any_peer", "reliable")
#func solicitar_usar() -> void:
	#if not multiplayer.is_server():
		#return
#
	#ejecutar()
#
#
#func ejecutar() -> void:
	#if jugador == null:
		#return
#
	#if not puedoUsar:
		#return
#
	#puedoUsar = false
#
	#var dronHijo = droneScene.instantiate()
	#add_child(dronHijo)
#
	#dronHijo.global_position = $Marker3D.global_position
#
	#await get_tree().create_timer(4.0).timeout
#
	#if is_instance_valid(dronHijo):
		#dronHijo.queue_free()

	#jugador.crear_drones(cantidad_drones)


func _on_tiempo_recarga_timeout() -> void:
	puedoUsar=true
	$tiempoRecarga.start()
	pass # Replace with function body.
