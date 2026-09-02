# world_forest.gd - CORREGIDO
extends Node3D

@onready var spawn_container: Node3D = %SpawnContainer
@onready var timer_target: Timer = %TimerTarget
@onready var menu_camera: MenuCameraController = $Camera3D

const TARGET = preload("uid://w08mo482g7si")

var is_menu_mode: bool = false

func _ready() -> void:
	Global.forest = self
	Global.spawn_container = spawn_container
	
	timer_target.timeout.connect(spawn_target)
	
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
	if timer_target:
		timer_target.stop()

func disable_menu_mode() -> void:
	"""Desactivar modo menú"""
	is_menu_mode = false
	
	if menu_camera:
		menu_camera.set_process(false)
	
	# Reactivar el timer si es necesario
	if timer_target and not timer_target.is_stopped():
		pass  # El timer ya está corriendo

func spawn_target():
	# No spawnear targets si estamos en modo menú
	if is_menu_mode:
		return
		
	if is_multiplayer_authority() and get_tree().get_node_count_in_group('Targets') < 20:
		for player in get_tree().get_node_count_in_group("Players"):
			var new_target = TARGET.instantiate()
			var rand_x = randf_range(-25.0, 25.0)
			var rand_z = randf_range(-25.0, 25.0)
			new_target.position = Vector3(rand_x, 1.0, rand_z)
			spawn_container.add_child(new_target, true)
