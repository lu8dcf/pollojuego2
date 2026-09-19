# obstacle_avoidance.gd
extends Node
class_name ObstacleAvoidance

# ==================== CONFIGURACIÓN ====================
@export var distancia_rayos: float = 3.0          # Longitud de los rayos de detección
@export var cantidad_rayos: int = 5               # Cantidad de rayos (más = más preciso)
@export var angulo_abanico: float = 90.0          # Ángulo total del abanico en grados
@export var fuerza_evasion: float = 2.0           # Qué tan fuerte evade
@export var capa_colision: int = 1                # Capa de colisión de los obstáculos (bitmask)
@export var distancia_pared: float = 1.5          # Distancia a la que detecta paredes

# ==================== ESTADO INTERNO ====================
var direccion_evasion: Vector3 = Vector3.ZERO
var rayos: Array[RayCast3D] = []
var debug_activo: bool = false

# ==================== INICIALIZACIÓN ====================
func _ready() -> void:
	_crear_rayos()

func _crear_rayos() -> void:
	# Limpiar rayos previos
	for r in rayos:
		if is_instance_valid(r):
			r.queue_free()
	rayos.clear()
	
	var padre := get_parent() as Node3D
	if not padre:
		push_error("ObstacleAvoidance debe ser hijo de un Node3D")
		return
	
	# Calcular el ángulo entre rayos
	var angulo_entre := 0.0
	if cantidad_rayos > 1:
		angulo_entre = deg_to_rad(angulo_abanico) / float(cantidad_rayos - 1)
	
	var angulo_inicial := -deg_to_rad(angulo_abanico) / 2.0
	
	for i in range(cantidad_rayos):
		var rayo := RayCast3D.new()
		rayo.enabled = true
		rayo.collision_mask = capa_colision
		rayo.target_position = Vector3(0, 0, -distancia_rayos)  # Hacia adelante (-Z)
		
		# Rotar el rayo según su posición en el abanico
		var angulo := angulo_inicial + angulo_entre * i
		rayo.rotation.y = angulo
		
		padre.add_child(rayo)
		rayos.append(rayo)

# ==================== LÓGICA PRINCIPAL ====================
# Recibe la velocidad deseada y devuelve una velocidad corregida que evita obstáculos
func calcular_evasion(velocidad_deseada: Vector3, delta: float) -> Vector3:
	if velocidad_deseada.length() < 0.01:
		return velocidad_deseada
	
	# Actualizar la dirección de los rayos según la velocidad deseada
	_orientar_rayos(velocidad_deseada)
	
	# Detectar obstáculos
	var obstaculos := _detectar_obstaculos()
	
	if obstaculos.is_empty():
		return velocidad_deseada
	
	# Calcular dirección de evasión
	var direccion_evasion := _calcular_direccion_evasion(obstaculos)
	
	# Combinar velocidad deseada con evasión
	var velocidad_final := (velocidad_deseada.normalized() + direccion_evasion * fuerza_evasion).normalized()
	velocidad_final *= velocidad_deseada.length()
	
	return velocidad_final

func _orientar_rayos(velocidad_deseada: Vector3) -> void:
	var padre := get_parent() as Node3D
	if not padre:
		return
	
	# Orientar el abanico de rayos hacia la dirección deseada
	var direccion_plana := Vector3(velocidad_deseada.x, 0, velocidad_deseada.z).normalized()
	if direccion_plana.length() < 0.01:
		return
	
	var angulo := atan2(direccion_plana.x, direccion_plana.z)
	padre.rotation.y = lerp_angle(padre.rotation.y, angulo, 10.0 -)

func _detectar_obstaculos() -> Array:
	var obstaculos := []
	for rayo in rayos:
		if not is_instance_valid(rayo):
			continue
		rayo.force_raycast_update()
		if rayo.is_colliding():
			obstaculos.append({
				"rayo": rayo,
				"colision": rayo.get_collider(),
				"punto": rayo.get_collision_point(),
				"normal": rayo.get_collision_normal(),
				"distancia": rayo.global_position.distance_to(rayo.get_collision_point())
			})
	return obstaculos

func _calcular_direccion_evasion(obstaculos: Array) -> Vector3:
	var direccion := Vector3.ZERO
	
	for obs in obstaculos:
		var normal: Vector3 = obs["normal"]
		var distancia: float = obs["distancia"]
		
		# Cuanto más cerca, más fuerte la evasión
		var peso := 1.0 - (distancia / distancia_rayos)
		peso = clamp(peso, 0.0, 1.0)
		
		# Sumar la normal del obstáculo (dirección de escape)
		direccion += normal * peso
	
	if direccion.length() > 0.01:
		direccion = direccion.normalized()
	
	return direccion

# ==================== DETECCIÓN DE PAREDES ====================
# Devuelve true si hay una pared muy cerca en la dirección actual
func detectar_pared_cercana(posicion_actual: Vector3, direccion_actual: Vector3) -> bool:
	var espacio := get_parent().get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		posicion_actual,
		posicion_actual + direccion_actual * distancia_pared
	)
	query.collision_mask = capa_colision
	
	var resultado := espacio.intersect_ray(query)
	return not resultado.is_empty()

# ==================== CONSULTAS ====================
func hay_obstaculo_adelante() -> bool:
	for rayo in rayos:
		if is_instance_valid(rayo) and rayo.is_colliding():
			return true
	return false

# ==================== UTILIDADES ====================
func set_distancia_rayos(nueva_distancia: float) -> void:
	distancia_rayos = max(0.5, nueva_distancia)
	for rayo in rayos:
		if is_instance_valid(rayo):
			rayo.target_position = Vector3(0, 0, -distancia_rayos)

func set_capa_colision(nueva_capa: int) -> void:
	capa_colision = nueva_capa
	for rayo in rayos:
		if is_instance_valid(rayo):
			rayo.collision_mask = capa_colision

func activar_debug(activo: bool) -> void:
	debug_activo = activo
	for rayo in rayos:
		if is_instance_valid(rayo):
			rayo.visible = activo

func _process(_delta: float) -> void:
	if debug_activo:
		for rayo in rayos:
			if is_instance_valid(rayo) and rayo.is_colliding():
				DebugDraw3D.draw_line(
					rayo.global_position,
					rayo.get_collision_point(),
					Color.RED
				)
