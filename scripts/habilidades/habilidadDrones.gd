class_name HabilidadDrones
extends Habilidad

@export var cantidad_drones: int = 2
var droneScene = preload("res://scenes/habilidad/dron_1.tscn")
var puedoUsar = false

func usar() -> void:
	if jugador == null:
		return
	if(puedoUsar):
		var dronHijo = droneScene.instantiate()
		add_child(dronHijo)
		dronHijo.position = $Marker3D.global_position
		await  get_tree().create_timer(4).timeout
		dronHijo.queue_free()
		
	#jugador.crear_drones(cantidad_drones)


func _on_tiempo_recarga_timeout() -> void:
	puedoUsar=true
	$tiempoRecarga.start()
	pass # Replace with function body.
