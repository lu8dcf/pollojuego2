extends Node3D
@export_group("Spawn")
@export var altura_spawn: float = 5.0

# Referencias a las escenas que vamos a instanciar
var bloque_terreno: PackedScene = preload("res://scenes/environment/BloqueTerreno.tscn")
var bloque_borde: PackedScene = preload("res://scenes/environment/BloqueBorde.tscn")

@export_group("Modo de Escena")
@export var es_escena_menu: bool = false # Activar si se usa en el menú principal

@export_group("Efecto Ola (Barrido)")
@export var tiempo_barrido_linea: float = 0.04 # Tiempo entre el inicio de cada fila (Z)
@export var duracion_animacion_bloque: float = 0.5 # Duración del salto/elevación de cada bloque
@export var desfase_x: float = 0.005 # Pequeño desfasaje en X para dar curvatura a la ola

@export_group("Semilla (Determinismo)")
@export var semilla_menu_fija: int = 123456 # Semilla estética para el menú
@export var semilla_mapa: int = 123456	# Semilla de la partida

@export_group("Dimensiones")
@export var ancho: int = 60
@export var largo: int = 60
@export var tamano_bloque: float = 1.0
@export var radio_spawn_centro: int = 4 # Zona segura alrededor del centro

@export_group("Forma de la Isla")
@export var frecuencia_ruido: float = 0.015 # Menor frecuencia = continente más amplio
@export var porcentaje_relleno: float = 0.60 # Target del 60% de suelo en la grilla

@export_group("Efecto Iceberg (Eje Y)")
@export var escala_y_centro: float = 6.0	# Profundidad en el centro
@export var escala_y_borde: float = 1.5	# Profundidad en los bordes
@export var variacion_bloque: float = 1.2   # Desnivel aleatorio entre bloques vecinos

# Instancias de ruido y RNG
var ruido = FastNoiseLite.new()
var ruido_altura = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	if es_escena_menu:
		semilla_mapa = semilla_menu_fija
	else:
		actualizar_semilla_desde_global()
		
	generar_mapa()

func actualizar_semilla_desde_global() -> void:
	var global = get_node_or_null("/root/GlobalJuego")
	if global and "semilla_mapa" in global:
		semilla_mapa = global.semilla_mapa

func _decidir_carga_simple() -> bool:
	#if es_escena_menu:
		#return true  # el menú siempre simple para entrar rápido
	var global = get_node_or_null("/root/GlobalJuego")
	if global and "carga_mapa_simple" in global:
		return global.carga_mapa_simple
	return true

func arrancar_partida_con_global() -> void:
	es_escena_menu = false
	actualizar_semilla_desde_global()
	generar_mapa()

# -----------------------------------------------------------------------------
# PUNTO DE ENTRADA
# -----------------------------------------------------------------------------
func generar_mapa() -> void:
	# Limpiar instancias previas
	for child in get_children():
		child.queue_free()

	# 1) Calcular el mapa completo (sin instanciar nada aún)
	var datos := _calcular_datos_mapa()
	var visitados: Dictionary = datos["visitados"]
	var distancias: Dictionary = datos["distancias"]

	# 2) Instanciar según el modo
	if _decidir_carga_simple():
		mapa_carga_simple(visitados, distancias)
	else:
		mapa_carga_compleja(visitados, distancias)

func mapa_carga_simple(visitados: Dictionary, distancias: Dictionary) -> void:
	for z in range(largo):
		for x in range(ancho):
			var pos: Vector2i = Vector2i(x, z)
			var pos_final := Vector3(x * tamano_bloque, 0, z * tamano_bloque)

			if visitados.has(pos):
				var bloque = bloque_terreno.instantiate()
				add_child(bloque)

				# Escala Y (iceberg) calculada igual que antes
				var dist_borde: int = distancias.get(pos, 0)
				var factor_profundidad: float = clamp(float(dist_borde) / 8.0, 0.0, 1.0)
				var ruido_var: float = (ruido_altura.get_noise_2d(x, z) + 1.0) * 0.5
				var escala_y_final: float = lerp(escala_y_borde, escala_y_centro, factor_profundidad) + (ruido_var * variacion_bloque)

				bloque.position = pos_final
				bloque.scale = Vector3(1.0, escala_y_final, 1.0)
			else:
				var muro = bloque_borde.instantiate()
				add_child(muro)
				muro.position = pos_final
				muro.visible = false

func mapa_carga_compleja(visitados: Dictionary, distancias: Dictionary) -> void:
	for z in range(largo):
		for x in range(ancho):
			var pos: Vector2i = Vector2i(x, z)
			if visitados.has(pos):
				var bloque = bloque_terreno.instantiate()
				add_child(bloque)

				var dist_borde: int = distancias.get(pos, 0)
				var factor_profundidad: float = clamp(float(dist_borde) / 8.0, 0.0, 1.0)
				var ruido_var: float = (ruido_altura.get_noise_2d(x, z) + 1.0) * 0.5
				var escala_y_final: float = lerp(escala_y_borde, escala_y_centro, factor_profundidad) + (ruido_var * variacion_bloque)

				var pos_final: Vector3 = Vector3(x * tamano_bloque, 0, z * tamano_bloque)

				bloque.position = pos_final + Vector3(0, -escala_y_final - 2.0, 0)
				bloque.scale = Vector3(1.0, 0.01, 1.0)

				var retraso_bloque: float = float(x) * desfase_x
				var tween = create_tween().set_parallel(true)
				tween.tween_property(bloque, "position", pos_final, duracion_animacion_bloque)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(retraso_bloque)
				tween.tween_property(bloque, "scale", Vector3(1.0, escala_y_final, 1.0), duracion_animacion_bloque)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(retraso_bloque)
			else:
				var muro = bloque_borde.instantiate()
				add_child(muro)
				muro.position = Vector3(x * tamano_bloque, 0, z * tamano_bloque)
				muro.visible = false

		if tiempo_barrido_linea > 0.0 and is_inside_tree():
			await get_tree().create_timer(tiempo_barrido_linea).timeout

func _calcular_datos_mapa() -> Dictionary:
	rng.seed = semilla_mapa
	ruido.seed = semilla_mapa
	ruido.frequency = frecuencia_ruido
	ruido.fractal_octaves = 2

	ruido_altura.seed = semilla_mapa + 9999
	ruido_altura.frequency = 0.1

	var mapa: Dictionary = {}
	var total_casillas: int = ancho * largo
	var minimo_requerido: int = int(total_casillas * porcentaje_relleno)
	var ancho_entero = int(ancho / 2.0)
	var largo_entero = int(largo / 2.0)
	var centro: Vector2i = Vector2i(ancho_entero, largo_entero)

	var umbral: float = 0.05
	var intento_seed: int = semilla_mapa

	# --- Generación por ruido
	while true:
		mapa.clear()
		var casillas_suelo: int = 0
		for x in range(ancho):
			for z in range(largo):
				var pos: Vector2i = Vector2i(x, z)
				if x == 0 or x == ancho - 1 or z == 0 or z == largo - 1:
					mapa[pos] = false
					continue
				if pos.distance_to(centro) <= radio_spawn_centro:
					mapa[pos] = true
					casillas_suelo += 1
					continue
				var nx: float = (float(x) / float(ancho - 1)) * 2.0 - 1.0
				var nz: float = (float(z) / float(largo - 1)) * 2.0 - 1.0
				var dist_centro: float = sqrt(nx * nx + nz * nz)
				var valor_final: float = ruido.get_noise_2d(x, z) - pow(dist_centro, 2.0) * 0.45
				if valor_final > umbral:
					mapa[pos] = true
					casillas_suelo += 1
				else:
					mapa[pos] = false
		if casillas_suelo >= minimo_requerido:
			break
		umbral -= 0.02
		if umbral < -0.8:
			intento_seed += 1
			ruido.seed = intento_seed
			umbral = 0.05

	# --- Suavizado
	mapa = aplicar_suavizado(mapa)

	# --- Flood fill
	var visitados: Dictionary = {}
	var cola: Array = [centro]
	visitados[centro] = true
	var direcciones_4: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while cola.size() > 0:
		var actual: Vector2i = cola.pop_front()
		for dir in direcciones_4:
			var vecino: Vector2i = actual + dir
			if mapa.get(vecino, false) and not visitados.has(vecino):
				visitados[vecino] = true
				cola.append(vecino)

	# --- Distancias al borde
	var distancias := calcular_distancias_al_borde(visitados, direcciones_4)

	return { "visitados": visitados, "distancias": distancias }



# ------------------------------------------------------------------------------
# FUNCIONES AUXILIARES
# ------------------------------------------------------------------------------

func aplicar_suavizado(mapa_original: Dictionary) -> Dictionary:
	var mapa_nuevo: Dictionary = mapa_original.duplicate()
	var direcciones_8: Array = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	
	for x in range(1, ancho - 1):
		for z in range(1, largo - 1):
			var pos: Vector2i = Vector2i(x, z)
			var vecinos_tierra: int = 0
			
			for dir in direcciones_8:
				if mapa_original.get(pos + dir, false):
					vecinos_tierra += 1
			
			if vecinos_tierra < 3:
				mapa_nuevo[pos] = false
			elif vecinos_tierra > 5:
				mapa_nuevo[pos] = true
				
	return mapa_nuevo

func calcular_distancias_al_borde(suelo_dict: Dictionary, dirs: Array) -> Dictionary:
	var distancias: Dictionary = {}
	var cola: Array = []
	
	for pos in suelo_dict:
		var es_borde: bool = false
		for d in dirs:
			if not suelo_dict.has(pos + d):
				es_borde = true
				break
		if es_borde:
			distancias[pos] = 0
			cola.append(pos)
			
	while cola.size() > 0:
		var actual: Vector2i = cola.pop_front()
		var d_actual: int = distancias[actual]
		for d in dirs:
			var vecino: Vector2i = actual + d
			if suelo_dict.has(vecino) and not distancias.has(vecino):
				distancias[vecino] = d_actual + 1
				cola.append(vecino)
				
	return distancias


func obtener_posicion_spawn(indice: int = 0, total: int = 1) -> Vector3:
	"""Devuelve una posición de spawn alrededor del centro del mapa."""
	var centro_x = (float(ancho) / 2.0) * tamano_bloque
	var centro_z = (float(largo) / 2.0) * tamano_bloque
	
	# Si hay varios jugadores, los distribuimos en círculo alrededor del centro
	if total <= 1:
		return Vector3(centro_x, altura_spawn, centro_z)
	
	# Radio del círculo de spawn
	var radio = 3.0
	var angulo = (float(indice) / float(total)) * TAU
	var offset_x = cos(angulo) * radio
	var offset_z = sin(angulo) * radio
	
	return Vector3(centro_x + offset_x, altura_spawn, centro_z + offset_z)
