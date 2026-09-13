# global_juego.gd - Datos y lógica del juego (SIN señales)
extends Node

# ===== INVENTARIO GLOBAL =====
var inventario_jugador = [null, null, null, null, null, null] # inventario de maximo 6 slots

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
var cant_jugadres:int = 0

#Tamaño del Mapa
var mapa_x_min = -20
var mapa_x_max = 20
var mapa_z_min = -20
var mapa_z_max = 20


#enemigos
var cant_enemigos = 50 # Cantidad de enemigos en la oleada siempr activos

func _ready():
	# estas son señales de red 
	if Network:
		Network.tube_client.session_created.connect(_configurar_sesion)
		multiplayer.peer_connected.connect(_agregar_jugador)
		multiplayer.peer_disconnected.connect(_eliminar_jugador)

func _configurar_sesion():
	"""Configura la sesión inicial con el jugador local"""
	var nombre_temp = "Anónimo"
	if GlobalJuego.nombre_jugador != "":
		nombre_temp = GlobalJuego.nombre_jugador
	
	session_info[1] = {
		"score": 0,
		"username": nombre_temp,
		"salud": SALUD_DEFAULT
	}
	
	_replicar_session_info.rpc(session_info)
	print("Sesión configurada: ", session_info)

func _agregar_jugador(peer_id: int):
	"""Agrega un nuevo jugador a la sesión"""
	await get_tree().create_timer(1.0).timeout
	
	var jugador = _obtener_jugador(peer_id)
	if jugador:
		session_info[peer_id] = {
			"score": 0,
			"username": jugador.nameplate.text if jugador.nameplate else "Jugador " + str(peer_id),
			"salud": SALUD_DEFAULT
		}
		_replicar_session_info.rpc(session_info)
		
		# Emitir señal global de jugador conectado
		GlobalSignal.jugador_conectado.emit(peer_id)

func _eliminar_jugador(peer_id: int):
	"""Elimina un jugador de la sesión"""
	if session_info.has(peer_id):
		session_info.erase(peer_id)
		_replicar_session_info.rpc(session_info)
		
		# Emitir señal global de jugador desconectado
		GlobalSignal.jugador_desconectado.emit(peer_id)

func _obtener_jugador(peer_id: int) -> Node:
	"""Busca un jugador por su ID"""
	for jugador in get_tree().get_nodes_in_group("Players"):
		if jugador.name == str(peer_id):
			return jugador
	return null

# ===== FUNCIONES DE SALUD =====
func dañar_jugador(peer_id: int, cantidad_daño: int):
	"""Aplica daño a un jugador específico"""
	if not session_info.has(peer_id):
		return
	
	var salud_actual = session_info[peer_id]["salud"]
	var nueva_salud = max(0, salud_actual - abs(cantidad_daño))
	
	session_info[peer_id]["salud"] = nueva_salud
	_replicar_session_info.rpc(session_info)
	
	# Emitir señales globales
	GlobalSignal.jugador_recibio_daño.emit(peer_id, cantidad_daño)
	GlobalSignal.salud_jugador_cambiada.emit(nueva_salud)
	
	# Verificar si murió
	if nueva_salud <= 0:
		_jugador_murio(peer_id)

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

func _jugador_murio(peer_id: int):
	"""Maneja la muerte de un jugador"""
	print("Jugador ", peer_id, " ha muerto")
	
	# Emitir señal global de muerte
	GlobalSignal.jugador_muerto.emit(peer_id)
	
	# Respawn con salud completa
	if session_info.has(peer_id):
		session_info[peer_id]["salud"] = SALUD_DEFAULT

# ===== FUNCIONES DE PUNTAJE =====
func agregar_punto(peer_id: int):
	"""Agrega un punto al jugador"""
	if not session_info.has(peer_id):
		return
	
	session_info[peer_id]["score"] = session_info[peer_id]["score"] + 1
	_replicar_session_info.rpc(session_info)
	
	# Emitir señal de puntaje actualizado
	GlobalSignal.puntaje_actualizado.emit(peer_id, session_info[peer_id]["score"])

# ===== REPLICACIÓN DE RED =====
@rpc("authority", "call_local")
func _replicar_session_info(info: Dictionary):
	"""Replica la información de sesión a todos los clientes"""
	session_info = info
	
	# Emitir señal global de sesión actualizada
	GlobalSignal.sesion_actualizada.emit(session_info)

# ===== FUNCIONES PARA SINGLEPLAYER =====
func configurar_singleplayer():
	"""Configura el juego para un solo jugador"""
	var nombre_temp = "Jugador Solo"
	if Global.username != "":
		nombre_temp = Global.username
	
	session_info.clear()
	session_info[1] = {
		"score": 0,
		"username": nombre_temp,
		"salud": SALUD_DEFAULT
	}
	
	# Emitir señal global
	GlobalSignal.sesion_actualizada.emit(session_info)
	print("Singleplayer configurado: ", session_info)
