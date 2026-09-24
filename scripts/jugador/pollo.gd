class_name Pollo
extends Node3D

var jugador: Jugador

@onready var habilidad: Habilidad = $Habilidad
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var modelo : Node3D

func inicializar(p_jugador: Jugador,p_modelo: Node3D,p_habilidad: Habilidad) -> void:
	jugador = p_jugador
	modelo = p_modelo
	habilidad = p_habilidad

	add_child(modelo)
	add_child(habilidad)

	habilidad.iniciar(jugador)


func usar_habilidad() -> void:
	if habilidad:
		habilidad.usar()

func reproducir_animacion(nombre: StringName) -> void:
	animation_player.play(nombre)
