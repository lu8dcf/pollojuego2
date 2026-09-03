# camera3d.gd - Movimiento oscilatorio lateral
extends Camera3D
class_name MenuCameraController

# Parámetros de movimiento oscilatorio
@export_group("Movimiento Oscilatorio")
@export var oscillation_amplitude: float = 2.0    # Amplitud del movimiento lateral (qué tan lejos se mueve)
@export var oscillation_speed: float = 0.3        # Velocidad de oscilación (qué tan rápido)
@export var oscillation_axis: Vector3 = Vector3(1, 0, 0)  # Eje de movimiento (X = lateral, Z = profundidad)

@export_group("Movimiento Vertical")
@export var vertical_amplitude: float = 0.5       # Amplitud del movimiento vertical
@export var vertical_speed: float = 0.2           # Velocidad del movimiento vertical
@export var vertical_offset: float = 0.0          # Desfase inicial vertical

@export_group("Movimiento de Balanceo")
@export var sway_amplitude: float = 1.0           # Amplitud del balanceo
@export var sway_frequency: float = 0.3           # Frecuencia del balanceo
@export var sway_offset: float = 0.0              # Desfase inicial del balanceo

@export_group("Enfoque")
@export var look_at_target: Node3D                # Objetivo a mirar (centro del mundo)
@export var focus_height: float = 2.0             # Altura del punto de enfoque
@export var smooth_follow_speed: float = 3.0      # Velocidad de suavizado

# Variables internas
var time_accumulator: float = 0.0
var initial_position: Vector3
var target_position: Vector3
var is_menu_active: bool = false

func _ready() -> void:
	# Guardar posición inicial
	initial_position = position
	
	# Si no hay objetivo definido, usar el padre
	if not look_at_target:
		look_at_target = get_parent()
	
	# Añadir desfases aleatorios para movimiento más natural
	sway_offset = randf_range(0, TAU)
	vertical_offset = randf_range(0, TAU)
	
	# Normalizar el eje de oscilación
	if oscillation_axis.length() > 0:
		oscillation_axis = oscillation_axis.normalized()
	
	set_process(false)

func _process(delta: float) -> void:
	if not is_menu_active:
		return
		
	# Acumular tiempo para animaciones
	time_accumulator += delta
	
	# Calcular nueva posición
	_calculate_camera_position(delta)
	
	# Actualizar orientación de la cámara
	_update_camera_look_at(delta)

func _calculate_camera_position(delta: float) -> void:
	# Posición base = posición inicial
	var new_position = initial_position
	
	# Movimiento oscilatorio lateral (va y viene)
	var lateral_movement = sin(time_accumulator * oscillation_speed) * oscillation_amplitude
	new_position += oscillation_axis * lateral_movement
	
	# Movimiento vertical suave
	var vertical_movement = sin(time_accumulator * vertical_speed + vertical_offset) * vertical_amplitude
	new_position.y += vertical_movement
	
	# Balanceo sutil adicional (movimiento circular pequeño)
	var sway_x = cos(time_accumulator * sway_frequency + sway_offset) * sway_amplitude * 0.5
	var sway_z = sin(time_accumulator * sway_frequency + sway_offset) * sway_amplitude * 0.3
	new_position.x += sway_x
	new_position.z += sway_z
	
	# Suavizar el movimiento
	target_position = new_position
	position = position.lerp(target_position, smooth_follow_speed * delta)

func _update_camera_look_at(delta: float) -> void:
	if look_at_target:
		# Punto de enfoque con altura ajustada
		var look_point = look_at_target.global_position + Vector3(0, focus_height, 0)
		
		# Suavizar la rotación hacia el objetivo
		var target_rotation = (look_point - global_position).normalized()
		var current_rotation = -global_transform.basis.z
		
		# Interpolar suavemente la dirección de la cámara
		var new_rotation = current_rotation.lerp(target_rotation, smooth_follow_speed * delta)
		look_at(global_position + new_rotation)

func activate_menu_camera() -> void:
	"""Activar cámara de menú manteniendo su posición exacta"""
	# Guardar la posición actual como base
	initial_position = position
	
	# Activar la cámara
	is_menu_active = true
	make_current()
	set_process(true)
	
	# Reiniciar animación
	time_accumulator = 0
	sway_offset = randf_range(0, TAU)
	vertical_offset = randf_range(0, TAU)
	

func deactivate_menu_camera() -> void:
	"""Desactivar cámara de menú"""
	is_menu_active = false
	set_process(false)

func _on_menu_entered() -> void:
	activate_menu_camera()

func _on_menu_exited() -> void:
	deactivate_menu_camera()
