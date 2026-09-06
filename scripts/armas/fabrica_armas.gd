class_name FabricaArmas
extends Node

var datos_armas: Dictionary = {}

var escenas_armas = {
	Arma.TipoArma.MELEE:
		preload("res://scenes/armas/arma_melee.tscn"),

	Arma.TipoArma.COMUN:
		preload("res://scenes/armas/arma_comun.tscn"),

	Arma.TipoArma.EXPLOSIVA:
		preload("res://scenes/armas/arma_explosiva.tscn")
}


func _ready() -> void:
	_cargar_armas("res://resources/arma/")
	
func _cargar_armas(ruta: String):

	var directorio = DirAccess.open(ruta)

	if not directorio:
		push_error("No se pudo abrir: " + ruta)
		return

	directorio.list_dir_begin()

	var archivo = directorio.get_next()

	while archivo != "":

		if archivo == "." or archivo == "..":
			archivo = directorio.get_next()
			continue

		var ruta_completa = ruta + "/" + archivo

		if directorio.current_is_dir():
			_cargar_armas(ruta_completa)

		elif archivo.ends_with(".tres"):
			var datos: Arma = load(ruta_completa)

			if datos:
				datos_armas[datos.id] = datos

		archivo = directorio.get_next()

	directorio.list_dir_end()


func crear_arma(id: int) -> Node3D:

	if not datos_armas.has(id):
		print("ID de arma no existe: ", id)
		return null

	var datos: Arma = datos_armas[id]

	if not escenas_armas.has(datos.tipo):
		push_error("Tipo de arma desconocido: ", datos.tipo)
		return null

	var escena: PackedScene = escenas_armas[datos.tipo]

	var arma: Node3D = escena.instantiate()

	arma.datos = datos

	return arma
