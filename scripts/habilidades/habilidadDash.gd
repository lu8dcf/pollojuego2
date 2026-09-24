class_name HabilidadDash
extends Habilidad

@export var velocidad_dash: float = 20.0
@export var duracion: float = 0.15


func usar() -> void:
	if jugador == null:
		return

	var direccion := -jugador.global_transform.basis.z

	jugador.iniciar_dash(direccion, velocidad_dash, duracion)
