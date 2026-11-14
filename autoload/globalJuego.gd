# global_juego.gd - Datos y lógica del juego (SIN señales)
extends Node


# ===== VARIABLES GLOBALES =====
var semilla_mapa: int = 123456
var carga_mapa_simple:bool=true

# ===== INVENTARIO GLOBAL =====
var inventario_jugador = [1, 7, 12, 9, null, null] # inventario de maximo 6 slots

# ===== SELECCIÓN DE PERSONAJE =====
var polloBasico = "res://scenes/pollos/pollo_modelo_1.tscn"

# ===== DATOS DEL JUGADOR =====
var salud_jugador: int = 100
var salud_maxima: int = 100
var nombre_jugador: String = ""
var experiencia_maxima:int = 100 # se le debe agregar un 0.25 de otra para cada nivel
var experiencia:int = 0

# ===== SISTEMA DE PUNTAJE =====
# peer_id : { score: 0, username: str, salud: 100 }
var session_info: Dictionary = {}

# ===== CONSTANTES =====
const SALUD_DEFAULT: int = 100
const DAÑO_MINIMO: int = 1
const DAÑO_MAXIMO: int = 100

# ===== TIPO DE JUEGO =====
var mundo:Node3D# mapa actual, esto es forest
var spawn_container: Node3D # donde spawnean los jugadores
var un_jugador:bool = true # si es true es singleplayer
var cant_jugadores:int = 0 # minimo de jugadores (ni bien se conecte uno se suma)
var max_cant_jugadores:int = 4 # maximo de jugadores en una partida
var en_pantalla_perder = true

var oleada:int = 1
var menu_abierto: bool = false

# ===== TIPO DE JUEGO =====
var duracion_oleada:float=90.0
var duracion_tienda:float=15.0
# estados del ciclo
enum FaseJuego{
	OLEADA,
	TIENDA,
	CARGANDO,
	LOBBY,
	MENU,
	PAUSA
}
var fase_actual:FaseJuego = FaseJuego.MENU
var fase_antes_de_pausa:FaseJuego = FaseJuego.OLEADA
var esta_pausado:bool = false


#Tamaño del Mapa
var mapa_x_min = 8
var mapa_x_max = 72
var mapa_z_min = 8
var mapa_z_max = 72


#enemigos
var cant_tipo_enemigos = 4 # maxima cantidad de tipos de eenmigos
var cant_enemigos = 30  # Cantidad de enemigos en la oleada siempr activos por jugador

func _ready():
	# estas son señales de red 
	if Network:
		Network.tube_client.session_created.connect(_configurar_sesion)
		multiplayer.peer_connected.connect(_agregar_jugador)
		multiplayer.peer_disconnected.connect(_eliminar_jugador)

func _configurar_sesion():
	var nombre_temp = "Jugador"
	if GlobalJuego.nombre_jugador != "":
		nombre_temp = GlobalJuego.nombre_jugador
	# PRIMERA CONFIGURACION DE SESSION INFO
	session_info[1] = {
		"score": 0,
		"username": nombre_temp,
		"salud": SALUD_DEFAULT,
		"salud_maxima": SALUD_DEFAULT,
		"velocidad": 5.0,
		"resistencia": 0.0,
		"personaje": 0,
		"estado": Jugador.Estado.OLEADA,
		"ping": 0,
		"inventario": [],
		"armas_actuales": []
	}
	#  veerificar que el peer esté listo antes de hacer RPC
	if multiplayer.multiplayer_peer == null:
		await get_tree().create_timer(0.5).timeout
		if multiplayer.multiplayer_peer == null:
			print("ERROR: peer sigue null, no se puede replicar session_info")
			return
	_replicar_session_info.rpc(session_info)

func reiniciar_vida_jugador(peer_id:int) ->void:
	if not session_info.has(peer_id):
		return
	var info:Dictionary = session_info[peer_id]
	var salud_max :int = info.get("salud_maxima",SALUD_DEFAULT)
	info["salud"] = salud_max
	session_info[peer_id] = info
	_replicar_session_info.rpc(session_info)
	
	

func _agregar_jugador(peer_id: int):
	await get_tree().create_timer(1.0).timeout
	
	var jugador = _obtener_jugador(peer_id)
	if jugador:
		session_info[peer_id] = {
			"score": 0,
			"username": jugador.nameplate.text ,
			"salud": SALUD_DEFAULT,
			"salud_maxima": SALUD_DEFAULT,
			"velocidad": 5.0,
			"resistencia": 0.0,
			"personaje": 0,
			"estado": Jugador.Estado.OLEADA,
			"ping": 0,
			"inventario": [],
			"armas_actuales": []
		}
		_replicar_session_info.rpc(session_info)
		
		# SE EMITE LA señal global de jugador conectado
		GlobalSignal.jugador_conectado.emit(peer_id)

func _eliminar_jugador(peer_id: int):
	if session_info.has(peer_id):
		session_info.erase(peer_id)
		_replicar_session_info.rpc(session_info)
		
		# Emitir señal global de jugador desconectado
		GlobalSignal.jugador_desconectado.emit(peer_id)

func _obtener_jugador(peer_id: int) -> Node:
	"""Busca un jugador por su ID"""
	for jugador in get_tree().get_nodes_in_group("Jugadores"):
		if jugador.name == str(peer_id):
			return jugador
	return null

# ===== FUNCIONES DE SALUD =====

#reiniciar la vida de todos y replicar el resultado
func reiniciar_vida_todos()->void:
	for peer_id in session_info.keys():
		var info : Dictionary = session_info[peer_id]
		var salud_max:int = info.get("salud_maxima",SALUD_DEFAULT)
		info["salud"] = salud_max
		session_info[peer_id] = info
	
	_replicar_session_info(session_info)
	#for i in GlobalJuego.session_info.keys():
		#print("DESPUES DE REINICIAR i: ",i, "Global: ", GlobalJuego.session_info[i])

func curar_jugador(peer_id: int, cantidad: int):
	"""Cura a un jugador específico"""
	if not session_info.has(peer_id):
		return
	
	var salud_actual = session_info[peer_id]["salud"]
	var nueva_salud = min(SALUD_DEFAULT, salud_actual + abs(cantidad))
	
	session_info[peer_id]["salud"] = nueva_salud
	_replicar_session_info.rpc(session_info)
	
	# Emitir señal de salud actualizada
	GlobalSignal.salud_jugador_cambiada.emit(nueva_salud)


# ===== FUNCIONES DE FIN PARTIDA =====
func _contruir_puntajes_ordenados() -> Array:
	var lista:Array = []
	for peer_id in session_info.keys():
		var info:Dictionary = session_info[peer_id]
		lista.append({
			"peer_id":peer_id,
			"username":info.get("username"),
			"score":info.get("score",0),
			"personaje":int(info.get("personaje",0)),
		})
	lista.sort_custom(func(a,b):return["score"]>b["score"])
	return lista # se devuelve la lsita ordenadade mayor a menor

func terminar_partida_un_jugador():
	if not un_jugador:
		return
	var puntajes:=_contruir_puntajes_ordenados()
	Network._mostrar_pantalla_perder_rpc.rpc(puntajes) # dado que es single player el peer id es 1

func chequear_fin_multijugador():
	if un_jugador or not multiplayer.is_server():
		return
	#se recorre a todos los jugadores del mundo y se verifica que esten muertos
	var jugadores :=get_tree().get_nodes_in_group("Jugadores") # al obtener solo el grupo evitamos usar el session_info
	if jugadores.is_empty():
		return
	for jugador in jugadores:
		if not is_instance_valid(jugador):
			continue 
		if jugador.estadoActual != Jugador.Estado.MUERTE:
			return # revisa si queda alguno vivo
		
		#si estan todos muertos entonces se crean los puntajes y se reedirije a la pantalla
		var puntajes:= _contruir_puntajes_ordenados()
		Network._mostrar_pantalla_perder_rpc.rpc(puntajes)
	
# ===== REPLICACIÓN DE RED =====
@rpc("authority", "call_local")
func _replicar_session_info(info: Dictionary):
	"""Replica la información de sesión a todos los clientes"""
	session_info = info
	
	# Emitir señal global de sesión actualizada
	GlobalSignal.sesion_actualizada.emit(session_info)

# ===== FUNCIONES PARA SINGLEPLAYER =====
func configurar_singleplayer():
	session_info.clear()
	session_info[1] = {
		"score": 0,
		"username": nombre_jugador,
		"salud": SALUD_DEFAULT,
		"salud_maxima": SALUD_DEFAULT,
		"velocidad": 5.0,
		"resistencia": 0.0,
		"personaje": 0,
		"estado": Jugador.Estado.OLEADA,
		"ping": 0,
		"inventario": [],
		"armas_actuales": []
	}
	
	GlobalSignal.sesion_actualizada.emit(session_info)
	
	
	
	
	
	
	
	
