extends Node3D

@onready var spawn_container: Node3D = %SpawnContainer
#@onready var spawn_proyectiles: Node3D = %ContenedorProyectiles
@onready var timer_enemy: Timer = %TimerEnemy
@onready var menu_camera: MenuCameraController = $Camera3D
#@onready var contenedor_mapa: Node3D = $Conteendor_mapa

@onready var mapa: Node3D = %mapa

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
	var mapa = load("res://scenes/environment/generador_mapa.tscn")
	var mapa_actual = mapa.instantiate()
	add_child(mapa_actual)
	
func spawn_enemy():
	
	if not multiplayer.is_server():
		return

	if is_menu_mode:
		return
		
	if GlobalJuego.esta_pausado or GlobalJuego.fase_actual == GlobalJuego.FaseJuego.TIENDA:
		return
	if get_tree().get_nodes_in_group("enemy").size() >= GlobalJuego.cant_enemigos:
		return

	instanciar_enemigo()

func instanciar_enemigo():
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('enemy') < GlobalJuego.cant_enemigos * GlobalJuego.cant_jugadores:
		for player in get_tree().get_node_count_in_group("Jugadores"):
			var new_target = fabrica_enemigos(0)
			
			var rand_x = randf_range(GlobalJuego.mapa_x_min, GlobalJuego.mapa_x_max)
			var rand_z = randf_range(GlobalJuego.mapa_z_min, GlobalJuego.mapa_z_max)
			#print (rand_x," ",rand_z)
			new_target.position = Vector3(rand_x, 10.0, rand_z)
			spawn_container.add_child(new_target, true)

func fabrica_enemigos(tipo):

	if tipo < 0 or tipo >= GlobalJuego.cant_tipo_enemigos: # hasta aca solo 4 enemigos
		push_error("Valor X fuera de rango: " + str(tipo))
		return
		
	if tipo==0:
		variedad_enemigos+=1
		tipo=variedad_enemigos
		if variedad_enemigos==GlobalJuego.cant_tipo_enemigos:
			variedad_enemigos=0
			 
	var nuevo_enemigo = enemigo_base.instantiate()
	nuevo_enemigo.tipo = tipo
	
	return nuevo_enemigo

# ============================================================
# PAUSA DE GAMEPLAY (para la tienda)
# ============================================================
func pausar_gameplay()->void:
	if timer_enemy:
		timer_enemy.stop() # detener el timer de enemigos
	#desactivar a los enemigos
	for enemigo in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemigo):
			enemigo.set_physics_process(false)
			enemigo.set_process(false)
	# desactivar a los jugadores
	for jugador in get_tree().get_nodes_in_group("Jugadores"):
		if is_instance_valid(jugador):
			jugador.set_physics_process(false)
			jugador.set_process(false)

func reanudar_gameplay()->void:
	
	#activar a los enemigos
	for enemigo in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemigo):
			
			enemigo.set_physics_process(true)
			enemigo.set_process(true)
	# activar a los jugadores
	for jugador in get_tree().get_nodes_in_group("Jugadores"):
		if is_instance_valid(jugador):
			jugador.set_physics_process(true)
			jugador.set_process(true)
	if timer_enemy:
		timer_enemy.start() # reactivar el spawn de enemigo


# eliminar enemigos del spawn
func limpiar_enemigos()->void:
	if not multiplayer.is_server():
		return # solo host puede eliminar enemigos
	_borrar_enemigos_locales()
	# avisarle a los clientes que elmiinen a los enemigos
	limpiar_enemigos_rpc.rpc()

@rpc("authority","call_local","reliable")
func limpiar_enemigos_rpc() ->void:
	_borrar_enemigos_locales()
	
func _borrar_enemigos_locales()->void:
	for enemigo in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemigo):
			enemigo.queue_free()
	
	if spawn_container: # cada enemigo que haya quedado se elminda de forma local
		for child in spawn_container.get_children():
			if child.is_in_group("enemy"):
				child.queue_free()
	
# REGENERAR MAPA ENTRE OLEADAS

func regenerar_mapa_nueva_oleada(nueva_semilla:int)->void:
	if not multiplayer.is_server():
		return
	
	limpiar_enemigos()
	#avisar a los cleintes que reactualicen la semilla
	_regenerar_mapa_rpc.rpc(nueva_semilla) 
	
	await get_tree().create_timer(0.3).timeout
	
@rpc("authority","call_local","reliable")
func _regenerar_mapa_rpc(nueva_semilla:int)->void:
	var generador = mapa
	if not generador:
		return
	
	await generador.regenerar_con_semilla(nueva_semilla)

func obtener_posicion_spawn(indice:int,total:int)->Vector3:
	var generador = mapa
	if generador and generador.has_method("obtener_posicion_spawn"):
		return generador.obtener_posicion_spawn(indice, total)
	# fallback: posicion por defecto si no hay generador
	return Vector3(30, 5, 30)
		
	
	
	
	
	
	
	
	
	
