class_name PolloFactory
extends Node


enum TipoPollo {
	BLANCO,
	LENTES,
	MARRON,
}


const POLLO_SCENE: PackedScene = preload("res://scenes/pollos/pollo.tscn")


const POLLOS := {
	TipoPollo.BLANCO: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_1.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDash.tscn"),
		#salud, velocidad
	},

	TipoPollo.LENTES: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_2.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDrones.tscn"),
	},

	TipoPollo.MARRON: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_3.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadEscudo.tscn"),
	},

}


static func crear(tipo: TipoPollo, jugador: Jugador) -> Pollo:
	
	if not POLLOS.has(tipo):
		push_error("Tipo de pollo inválido: %s" % tipo)
		return null

	var datos: Dictionary = POLLOS[tipo]

	var pollo: Pollo = POLLO_SCENE.instantiate()

	var modelo: Node3D = datos["modelo"].instantiate()
	var habilidad: Habilidad = datos["habilidad"].instantiate()

	pollo.inicializar(jugador, modelo, habilidad)

	return pollo
