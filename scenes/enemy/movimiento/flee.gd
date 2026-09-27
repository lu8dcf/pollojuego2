# flee.gd
extends Node
class_name Flee

# ==================== CONFIGURACIÓN ====================
@export var velocidad_maxima: float = 4.0     # Velocidad de huida
@export var distancia_seguridad: float = 8.0  # Distancia mínima a mantener
@export var distancia_maxima: float = 12.0    # Distancia a la que deja de huir
@export var suavizado: float = 6.0            # Suavizado del movimiento
@export var fuerza_extra: float = 1.2         # Multiplicador de urgencia

# ==================== ESTADO INTERNO ====================
var direccion_huida: Vector3 = Vector3.ZERO

# ==================== LÓGICA PRINCIPAL ====================
# Calcula la velocidad de huida del jugador
# Devuelve Vector3.ZERO si está lo suficientemente lejos
func calcular_velocidad(posicion_actual: Vector3, posicion_jugador: Vector3, direccion_actual: Vector3, delta: float) -> Vector3:
	# 1. Calcular distancia al jugador
	var distancia := posicion_actual.distance_to(posicion_jugador)
	
	# 2. Si está muy lejos, no huir (volver a Wander)
	if distancia > distancia_maxima:
		direccion_huida = direccion_actual
		return Vector3.ZERO
	
	# 3. Calcular dirección opuesta al jugador (solo en XZ)
	var direccion_opuesta := posicion_actual - posicion_jugador
	direccion_opuesta.y = 0
	direccion_opuesta = direccion_opuesta.normalized()
	
	# 4. Si están muy cerca, aplicar urgencia extra
	var urgencia := 1.0
	if distancia < distancia_seguridad:
		urgencia = fuerza_extra
	
	# 5. Calcular la dirección deseada (alejarse)
	var direccion_deseada := direccion_opuesta * urgencia
	
	# 6. Aplicar suavizado para evitar giros bruscos
	direccion_huida = direccion_actual.lerp(direccion_deseada, suavizado * delta).normalized()
	
	# 7. Devolver la velocidad final
	return direccion_huida * velocidad_maxima

# ==================== CONSULTAS ====================
func deber_huir(posicion_actual: Vector3, posicion_jugador: Vector3) -> bool:
	var distancia := posicion_actual.distance_to(posicion_jugador)
	return distancia <= distancia_maxima

func esta_a_salvo(posicion_actual: Vector3, posicion_jugador: Vector3) -> bool:
	var distancia := posicion_actual.distance_to(posicion_jugador)
	return distancia > distancia_maxima

# ==================== UTILIDADES ====================
func set_velocidad(nueva_velocidad: float) -> void:
	velocidad_maxima = max(0.0, nueva_velocidad)

func set_distancia_seguridad(nueva_distancia: float) -> void:
	distancia_seguridad = max(0.1, nueva_distancia)

func set_distancia_maxima(nueva_distancia: float) -> void:
	distancia_maxima = max(distancia_seguridad + 1.0, nueva_distancia)
