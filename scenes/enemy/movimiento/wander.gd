# wander.gd
extends Node
class_name Wander

# ==================== CONFIGURACIÓN ====================
@export var radio_circulo: float = 10.0       # Radio del círculo imaginario
@export var distancia_circulo: float = 10.0   # Distancia del círculo al frente
@export var velocidad_cambio: float = 0.1    # Qué tan rápido cambia el ángulo
@export var velocidad_maxima: float = 1.0    # Velocidad máxima del enemigo
@export var suavizado: float = 0.5           # Suavizado del movimiento

# ==================== ESTADO INTERNO ====================
var angulo_objetivo: float = 0.0    # Ángulo actual del punto en el círculo
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ==================== INICIALIZACIÓN ====================
func _ready() -> void:
	rng.randomize()
	angulo_objetivo = rng.randf_range(-PI, PI)  # Ángulo inicial aleatorio

# ==================== LÓGICA PRINCIPAL ====================
# Devuelve la velocidad deseada (Vector3) para el enemigo
func calcular_velocidad(posicion_actual: Vector3, direccion_actual: Vector3, delta: float) -> Vector3:
	# 1. Desplazar el ángulo aleatoriamente
	angulo_objetivo += rng.randf_range(-1.0, 1.0) * velocidad_cambio * delta
	
	# Mantener el ángulo en el rango [-PI, PI]
	angulo_objetivo = wrapf(angulo_objetivo, -PI, PI)
	
	# 2. Calcular la dirección "hacia adelante" del enemigo
	var adelante := direccion_actual.normalized()
	if adelante.length() < 0.01:
		adelante = Vector3.FORWARD
	
	# 3. Calcular el centro del círculo imaginario
	var centro_circulo := posicion_actual + adelante * distancia_circulo
	
	# 4. Calcular el punto objetivo sobre el perímetro del círculo
	# Usamos dos vectores perpendiculares para ubicar el punto en el plano XZ
	var derecha := adelante.cross(Vector3.UP).normalized()
	var arriba := derecha.cross(adelante).normalized()
	
	var punto_objetivo := centro_circulo \
		+ derecha * cos(angulo_objetivo) * radio_circulo \
		+ arriba * sin(angulo_objetivo) * radio_circulo
	
	# 5. Calcular la dirección deseada (Seek hacia el punto objetivo)
	var direccion_deseada := (punto_objetivo - posicion_actual).normalized()
	
	# 6. Aplicar suavizado para evitar giros bruscos
	direccion_deseada = direccion_actual.lerp(direccion_deseada, suavizado * delta).normalized()
	
	# 7. Devolver la velocidad final
	return direccion_deseada * velocidad_maxima

# ==================== UTILIDADES ====================
func reiniciar() -> void:
	angulo_objetivo = rng.randf_range(-PI, PI)

func set_radio(nuevo_radio: float) -> void:
	radio_circulo = max(0.1, nuevo_radio)

func set_distancia(nueva_distancia: float) -> void:
	distancia_circulo = max(0.1, nueva_distancia)

func set_velocidad(nueva_velocidad: float) -> void:
	velocidad_maxima = max(0.0, nueva_velocidad)

func set_velocidad_cambio(nueva_velocidad: float) -> void:
	velocidad_cambio = max(0.0, nueva_velocidad)
