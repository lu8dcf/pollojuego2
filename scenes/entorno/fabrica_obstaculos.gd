extends Node3D
class_name MapaObstaculos

# --- Límites del área (coordenadas en X y Z) ---
var x_min = GlobalJuego.mapa_x_min
var x_max = GlobalJuego.mapa_x_max
var z_min = GlobalJuego.mapa_z_min
var z_max = GlobalJuego.mapa_z_max

# --- Configuración ---
@export var cantidad_obstaculos: int = 20
@export var altura_y: float = 0.5          # altura del centro del cubo (si el piso está en y=0)
@export var tamaño_cubo: Vector3 = Vector3(1, 1, 1)
@export var separacion_minima: float = 4 # evita que se superpongan

# --- Referencias ---
@export var escena_cubo = preload("res://scenes/entorno/obstaculo.tscn")        # arrastra tu CuboObstaculo.tscn aquí
@onready var contenedor: Node3D = $Obstaculos

var posiciones_usadas: Array[Vector3] = []


func _ready():
	if escena_cubo == null:
		push_error("Falta asignar escena_cubo en el inspector.")
		return
	generar_obstaculos()

func generar_obstaculos():
	
	
	posiciones_usadas.clear()
	
	var intentos_max = cantidad_obstaculos * 30  # para evitar loop infinito si el área es chica
	var colocados = 0
	var intentos = 0
	
	while colocados < cantidad_obstaculos and intentos < intentos_max:
		intentos += 1
		
		var pos = Vector3(
			randf_range(x_min, x_max),
			altura_y,
			randf_range(z_min, z_max)
		)
		
		if _posicion_valida(pos):
			_instanciar_cubo(pos)
			posiciones_usadas.append(pos)
			colocados += 1
	
	if colocados < cantidad_obstaculos:
		push_warning("Solo se colocaron %d de %d obstáculos (área muy pequeña o mucha separación)." 
			% [colocados, cantidad_obstaculos])

func _posicion_valida(pos: Vector3) -> bool:
	for p in posiciones_usadas:
		if p.distance_to(pos) < separacion_minima:
			return false
	return true

func _instanciar_cubo(pos: Vector3):
	var cubo = escena_cubo.instantiate()
	
	cubo.position = pos
	# Tamaño aleatorio opcional:
	# cubo.scale = tamaño_cubo * randf_range(0.7, 1.5)
	add_child(cubo)
	
