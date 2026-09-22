extends Node3D

@onready var spawn_container: Node3D = %SpawnContainer
@onready var timer_enemy: Timer = %TimerEnemy
@onready var menu_camera: MenuCameraController = $Camera3D
#@onready var contenedor_mapa: Node3D = $Conteendor_mapa


const enemigo_base = preload("uid://b8go34qeye00a") # Escena enemy0


var is_menu_mode: bool = false
var ya_hizo=false
var variedad_enemigos=0

func _ready() -> void:
	GlobalJuego.mundo = self
	GlobalJuego.spawn_container = spawn_container
		
	timer_enemy.timeout.connect(spawn_enemy)
	
	# Configurar la cámara
	if menu_camera:
		menu_camera.look_at_target = self

func enable_menu_mode() -> void:
	"""Activar modo menú - NO pausa el juego"""
	is_menu_mode = true
	
	if menu_camera:
		
		# Activar la cámara
		menu_camera.make_current()
		menu_camera.set_process(true)
	
	# Detener el timer de spawn
	if timer_enemy:
		timer_enemy.stop()

func disable_menu_mode() -> void:
	"""Desactivar modo menú"""
	is_menu_mode = false
	
	if menu_camera:
		menu_camera.set_process(false)
	
	# Reactivar el timer si es necesario
	if timer_enemy and not timer_enemy.is_stopped():
		pass  # El timer ya está corriendo

func agregar_mapa():
	var mapa = load("res://scenes/environment/mapa1.tscn")
	var mapa_actual = mapa.instanciate()
	add_child(mapa_actual)
	
func spawn_enemy():
	
	if not multiplayer.has_multiplayer_peer():
		return
	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	
	# Verificar que tengamos un ID válido
	var mi_id = multiplayer.get_unique_id()
	if mi_id == 0 or mi_id == 1 and not multiplayer.is_server():
		# Si somos cliente y nos devuelve 1, hay un problema
		if not multiplayer.is_server():
			return
	var cantidad_enemigos = get_tree().get_nodes_in_group("enemy").size()
	if cantidad_enemigos > GlobalJuego.cant_enemigos:
		return
	
	if is_menu_mode:
		return
	if not is_multiplayer_authority():
		return
	# SOLO el servidor puede spawnear enemigos
	if not multiplayer.is_server():
		return  # Los clientes NO spawnean, solo reciben sincronización
	
	#GlobalSignal.agrega_enemigo.emit(1)
	instanciar_enemigo()

func instanciar_enemigo():
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('enemy') < 20:
		for player in get_tree().get_node_count_in_group("Jugadores"):
			var new_target = fabrica_enemigos(0)
			
			var rand_x = randf_range(GlobalJuego.mapa_x_min, GlobalJuego.mapa_x_max)
			var rand_z = randf_range(GlobalJuego.mapa_z_min, GlobalJuego.mapa_z_max)
			#print (rand_x," ",rand_z)
			new_target.position = Vector3(rand_x, 2.0, rand_z)
			spawn_container.add_child(new_target, true)

func fabrica_enemigos(tipo):

		
	
	if tipo < 0 or tipo > GlobalJuego.cant_tipo_enemigos: # hasta aca solo 4 enemigos
		push_error("Valor X fuera de rango: " + str(tipo))
		return
		
	if tipo==0:
		variedad_enemigos+=1
		tipo=variedad_enemigos
		if variedad_enemigos==3:
			variedad_enemigos=0
			 
	var nuevo_enemigo = enemigo_base.instantiate()
	nuevo_enemigo.tipo = tipo
	
	return nuevo_enemigo


func partida_unsolojugador():
	is_menu_mode = false
	
	# Desactivar cámara del menú
	if menu_camera:
		menu_camera.deactivate_menu_camera()
	
	set_process(true)
	
