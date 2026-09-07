# world_forest.gd - CORREGIDO
extends Node3D

@onready var spawn_container: Node3D = %SpawnContainer
@onready var timer_enemy: Timer = %TimerEnemy
@onready var menu_camera: MenuCameraController = $Camera3D

const TARGET = preload("uid://b8go34qeye00a") # Escena enemy0

var is_menu_mode: bool = false
var ya_hizo=false

func _ready() -> void:
	Global.forest = self
	Global.spawn_container = spawn_container
	
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

func spawn_enemy():
	var cantidad_enemigos = get_tree().get_nodes_in_group("enemy").size()
	if cantidad_enemigos > GlobalJuego.cant_enemigos:
		return
	# No spawnear targets si estamos en modo menú
	if is_menu_mode:
		return
	
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('Targets') < 20:
		for player in get_tree().get_node_count_in_group("Jugadores"):
			var new_target = TARGET.instantiate()
			var rand_x = randf_range(GlobalJuego.mapa_x_min, GlobalJuego.mapa_x_max)
			var rand_z = randf_range(GlobalJuego.mapa_z_min, GlobalJuego.mapa_z_max)
			#print (rand_x," ",rand_z)
			new_target.position = Vector3(rand_x, 2.0, rand_z)
			spawn_container.add_child(new_target, true)
	ya_hizo=true
