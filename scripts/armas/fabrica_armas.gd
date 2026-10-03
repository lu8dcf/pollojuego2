class_name FabricaArmas
extends Node

var datos_armas: Dictionary = {}


func _ready() -> void:
	#Metodo automativo = diacces
	_cargar_armas("res://resources/arma/")

	# Respaldo
	#print("Intentando cargar armas mediante preload...")
	if(datos_armas.is_empty()):
		_cargar_arma_manual(preload("res://resources/arma/comun/comun1.tres"))
		_cargar_arma_manual(preload("res://resources/arma/explosiva/explosiva1.tres"))
		_cargar_arma_manual(preload("res://resources/arma/melee/melee1.tres"))




func _cargar_arma_manual(datos: Arma) -> void:
	if datos == null:
		#print("ERROR: preload devolvio null")
		return
	if datos_armas.has(datos.id):
		#print("Arma ID ", datos.id, " ya estaba cargada por DirAccess.")
		return
	datos_armas[datos.id] = datos
	#print("Arma ID ", datos.id, " cargada mediante PRELOAD.")


func _cargar_armas(ruta: String) -> void:
	var directorio = DirAccess.open(ruta)

	if not directorio:
		push_error("No se pudo abrir: " + ruta)
		print("ERROR: DirAccess no pudo abrir ", ruta)
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
			#print("Encontrado archivo: ", ruta_completa)

			var datos: Arma = load(ruta_completa)

			if datos:
				datos_armas[datos.id] = datos
				#print("Arma ID ", datos.id, " cargada mediante DIRACCESS.")
			#else:
				#print("ERROR: no se pudo cargar ", ruta_completa)

		archivo = directorio.get_next()

	directorio.list_dir_end()


#func _ready() -> void:
	#_cargar_armas("res://resources/arma/")
	#
#func _cargar_armas(ruta: String):
	#var directorio = DirAccess.open(ruta)
	#if not directorio:
		#push_error("No se pudo abrir: " + ruta)
		#return
	#directorio.list_dir_begin()
	#var archivo = directorio.get_next()
	#while archivo != "":
		#if archivo == "." or archivo == "..":
			#archivo = directorio.get_next()
			#continue
		#var ruta_completa = ruta + "/" + archivo
		#if directorio.current_is_dir():
			#_cargar_armas(ruta_completa)
		#elif archivo.ends_with(".tres"):
			#var datos: Arma = load(ruta_completa)
			#if datos:
				#datos_armas[datos.id] = datos
		#archivo = directorio.get_next()
	#directorio.list_dir_end()


func crear_arma(id: int) -> Node3D:
	if not datos_armas.has(id):
		print("ID de arma no existe: ", id)
		return null
	var datos: Arma = datos_armas[id]
	var escena: PackedScene = preload("res://scenes/armas/armaBase.tscn")
	var arma: Node3D = escena.instantiate()
	arma.datos = datos
	return arma
