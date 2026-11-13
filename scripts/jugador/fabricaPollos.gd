class_name PolloFactory
extends Node


enum TipoPollo {
	BLANCO,
	LENTES,
	MARRON,
	ROSA,
	AZUL,
	DORADO
}


const POLLO_SCENE: PackedScene = preload("res://scenes/pollos/pollo.tscn")


const POLLOS := {
	TipoPollo.BLANCO: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_1.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDash.tscn"),
		"salud_maxima": 100, 
		"velocidad": 5.0,
		"resistencia": 0.2 #porcentaje del 0 al 1
	},

	TipoPollo.LENTES: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_2.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDrones.tscn"),
		"salud_maxima": 80,
		"velocidad": 8.0,
		"resistencia": 0.4
	},

	TipoPollo.MARRON: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_3.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadEscudo.tscn"),
		"salud_maxima": 120,
		"velocidad": 4.0,
		"resistencia": 0.6
	},
	TipoPollo.ROSA: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_4.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDash.tscn"),
		"salud_maxima": 100, 
		"velocidad": 5.0,
		"resistencia": 0.2 #porcentaje del 0 al 1
	},
	TipoPollo.AZUL: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_5.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDash.tscn"),
		"salud_maxima": 100, 
		"velocidad": 5.0,
		"resistencia": 0.2 #porcentaje del 0 al 1
	},
	TipoPollo.DORADO: {
		"modelo": preload("res://scenes/pollos/pollo_modelo_6.tscn"),
		"habilidad": preload("res://scenes/habilidad/habilidadDash.tscn"),
		"salud_maxima": 100, 
		"velocidad": 5.0,
		"resistencia": 0.2 #porcentaje del 0 al 1
	},
}

# obtener datos numericos
static func obtener_datos(tipo: TipoPollo) -> Dictionary:
	if POLLOS.has(tipo): #si tengo ese pollo
		return POLLOS[tipo] #retorno los datos de ese pollo
	return {}

#
static func crear(tipo: TipoPollo, jugador: Jugador) -> Pollo:
	if not POLLOS.has(tipo): return null #si no hay ese pollo, null
	var datos: Dictionary = POLLOS[tipo]

	var pollo: Pollo = POLLO_SCENE.instantiate() #escena lista
	var modelo: Node3D = datos["modelo"].instantiate() #modelo del pollo especifico
	var habilidad: Habilidad = datos["habilidad"].instantiate() #habilidad del pollo especifico

	pollo.inicializar(jugador, modelo, habilidad)
	return pollo
