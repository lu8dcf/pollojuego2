# menu_background.gd
extends Node3D
class_name MenuBackground

# Referencias a nodos de la escena
@onready var camera_3d: Camera3D = %CameraMenu
@onready var spawn_container: Node3D = %SpawnContainer
@onready var timer_target: Timer = %TimerTarget

# Configuración de movimiento de cámara
@export var camera_orbit_radius: float = 30.0
@export var camera_orbit_speed: float = 0.1  # Velocidad de rotación (radianes/seg)
@export var camera_height: float = 8.0
@export var camera_look_height: float = 2.0
@export var camera_bob_amplitude: float = 0.5
@export var camera_bob_speed: float = 0.3

# Variables internas
var camera_angle: float = 0.0
var time_accumulator: float = 0.0
var target_point: Vector3 = Vector3.ZERO

# Precarga del target (igual que en tu mundo original)
const TARGET = preload("uid://w08mo482g7si")

func _ready() -> void:
	# Configurar referencias globales para el fondo
	Global.forest = self
	Global.spawn_container = spawn_container
	
	# Conectar timer para spawn de targets decorativos
	timer_target.timeout.connect(spawn_target)
	
	# Iniciar con algunos targets para que no esté vacío
	_spawn_initial_targets()
	
	# Configurar la cámara inicial
	_setup_camera()
	
	# Iniciar movimiento de cámara
	set_process(true)

func _process(delta: float) -> void:
	# Actualizar posición de cámara con movimiento orbital suave
	_update_camera_orbit(delta)
	
	# Añadir efecto de "respiración" a la cámara
	_update_camera_bob(delta)

func _setup_camera() -> void:
	# Posicionar cámara inicial
	camera_angle = randf_range(0, TAU)  # Ángulo inicial aleatorio
	_update_camera_position()
	
	# Configurar FOV para efecto cinematográfico
	camera_3d.fov = 60.0
	
	# Añadir efecto de profundidad
	if camera_3d is Camera3D:
		camera_3d.far = 200.0

func _update_camera_orbit(delta: float) -> void:
	# Incrementar ángulo de órbita
	camera_angle += camera_orbit_speed * delta
	
	# Calcular posición orbital
	var orbit_x = cos(camera_angle) * camera_orbit_radius
	var orbit_z = sin(camera_angle) * camera_orbit_radius
	
	# Posición base de la cámara
	var base_position = Vector3(orbit_x, camera_height, orbit_z)
	
	# Aplicar posición suavizada
	camera_3d.position = camera_3d.position.lerp(base_position, delta * 2.0)
	
	# Hacer que la cámara mire al centro del mapa
	var look_target = Vector3.ZERO + Vector3(0, camera_look_height, 0)
	camera_3d.look_at(look_target)

func _update_camera_bob(delta: float) -> void:
	# Acumular tiempo para el efecto de balanceo
	time_accumulator += delta
	
	# Calcular offset de balanceo
	var bob_offset = Vector3(
		sin(time_accumulator * camera_bob_speed) * camera_bob_amplitude,
		cos(time_accumulator * camera_bob_speed * 0.7) * camera_bob_amplitude * 0.5,
		0
	)
	
	# Aplicar balanceo suavemente
	camera_3d.position += bob_offset * delta

func _spawn_initial_targets() -> void:
	# Spawnear targets decorativos iniciales
	for i in range(5):
		spawn_target()

func spawn_target() -> void:
	# Solo spawnear si no excede el límite
	if get_tree().get_node_count_in_group('Targets') < 15:
		var new_target = TARGET.instantiate()
		
		# Posición aleatoria en círculo para mejor vista
		var angle = randf_range(0, TAU)
		var distance = randf_range(5.0, 25.0)
		var rand_x = cos(angle) * distance
		var rand_z = sin(angle) * distance
		
		new_target.position = Vector3(rand_x, 1.0, rand_z)
		spawn_container.add_child(new_target, true)

# Función para pausar/reanudar animación cuando sea necesario
func pause_camera_movement() -> void:
	set_process(false)

func resume_camera_movement() -> void:
	set_process(true)

# Efecto especial: zoom suave al entrar al menú
func play_entrance_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Zoom desde lejos
	camera_3d.position = Vector3(0, camera_height + 15, camera_orbit_radius + 20)
	camera_3d.look_at(Vector3.ZERO)
	
	tween.tween_property(camera_3d, "position", 
		Vector3(cos(camera_angle) * camera_orbit_radius, 
				camera_height, 
				sin(camera_angle) * camera_orbit_radius), 
		3.0)
