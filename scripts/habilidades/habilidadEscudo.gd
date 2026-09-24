class_name HabilidadEscudo
extends Habilidad

@export var duracion: float = 5.0
@onready var escudo = $escudo
var puedoUsar = false


func usar() -> void:
	if jugador == null:
		return
	if(puedoUsar):
		habilitarEscudo()
	#jugador.activar_escudo(duracion)

func habilitarEscudo():
	escudo.visible = true
	escudo.monitoring = true
	await get_tree().create_timer(3).timeout
	escudo.visible = false
	escudo.monitoring = false



func _on_tiempo_recarga_timeout() -> void:
	puedoUsar=true
	$tiempoRecarga.start()
	pass # Replace with function body.
