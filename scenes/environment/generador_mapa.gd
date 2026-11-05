extends Node3D

@export_group("Configuración General")
@export var altura_spawn: float = 5.0
@export var ancho: int = 60
@export var largo: int = 60
@export var tamano_bloque: float = 1.0

@export_group("Modo de Escena")
@export var es_escena_menu: bool = false
@export var semilla_menu_fija: int = 123456

@export_group("Centro Seguro (20x20)")
@export var radio_centro: int = 10

@export_group("Forma de los Bordes")
@export var frecuencia_ruido: float = 0.02
@export var umbral_ruido_inicial: float = 0.35

@export_group("Sistema de Plantas")
@export var generar_plantas: bool = true
@export var probabilidad_spawn_planta: float = 0.12
@export var radio_exclusion_centro_plantas: float = 6.0

@export_group("Semilla")
@export var semilla_mapa: int = 123456

var bloque_terreno: PackedScene = preload("res://scenes/environment/BloqueTerreno.tscn")
var bloque_borde: PackedScene = preload("res://scenes/environment/BloqueBorde.tscn")

var escenas_plantas: Array[PackedScene] = [
	preload("res://scenes/environment/planta_1.tscn"),
	preload("res://scenes/environment/planta_2.tscn"),
	preload("res://scenes/environment/planta_3.tscn"),
	preload("res://scenes/environment/planta_4.tscn")
]

var ruido = FastNoiseLite.new()
var ruido_borde = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	if es_escena_menu:
		semilla_mapa = semilla_menu_fija
	else:
		actualizar_semilla_desde_global()
	await generar_mapa()


func actualizar_semilla_desde_global() -> void:
	var global = get_node_or_null("/root/GlobalJuego")
	if global and "semilla_mapa" in global:
		semilla_mapa = global.semilla_mapa


func _decidir_carga_simple() -> bool:
	var global = get_node_or_null("/root/GlobalJuego")
	if global and "carga_mapa_simple" in global:
		return global.carga_mapa_simple
	return true


func arrancar_partida_con_global() -> void:
	es_escena_menu = false
	actualizar_semilla_desde_global()
	await generar_mapa()


func generar_nueva_semilla_y_enviar() -> void:
	randomize()
	var multiplicador_azar = randi_range(10, 99)
	semilla_mapa = randi() * multiplicador_azar
	var global = get_node_or_null("/root/GlobalJuego")
	if global and "semilla_mapa" in global:
		global.semilla_mapa = semilla_mapa


func regenerar_con_semilla(nueva_semilla: int) -> void:
	semilla_mapa = nueva_semilla
	await generar_mapa()


# -----------------------------------------------------------------------------
# PUNTO DE ENTRADA
# -----------------------------------------------------------------------------
func generar_mapa() -> void:
	# limpiar instancias previas
	for child in get_children():
		child.queue_free()
	
	# esperar un frame para que se liberen del todo
	if is_inside_tree():
		await get_tree().process_frame
	
	# 1) configurar el ruido con la semilla actual (DETERMINISTA)
	rng.seed = semilla_mapa
	ruido.seed = semilla_mapa
	ruido.frequency = frecuencia_ruido
	ruido.fractal_octaves = 3
	
	ruido_borde.seed = semilla_mapa + 5000
	ruido_borde.fractal_octaves = 2
	
	# 2) calcular el mapa (visitados = celdas caminables conectadas al centro)
	var datos := _calcular_datos_mapa()
	var visitados: Dictionary = datos["visitados"]
	var distancias: Dictionary = datos["distancias"]
	
	# 3) instanciar según el modo
	if _decidir_carga_simple():
		mapa_carga_simple(visitados, distancias)
	else:
		mapa_carga_compleja(visitados, distancias)


# -----------------------------------------------------------------------------
# CALCULO DEL MAPA
# -----------------------------------------------------------------------------
func _calcular_datos_mapa() -> Dictionary:
	var centro_x = int(ancho / 2)
	var centro_z = int(largo / 2)
	var centro_vector = Vector2i(centro_x, centro_z)
	
	var total_casillas_utiles = (ancho - 2) * (largo - 2)
	var objetivo_caminables = int(total_casillas_utiles * 0.70)
	
	var mapa_bruto: Dictionary = {}
	var visitados: Dictionary = {}
	var umbral_actual = umbral_ruido_inicial
	var direcciones: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	while true:
		mapa_bruto.clear()
		
		for x in range(ancho):
			for z in range(largo):
				var pos = Vector2i(x, z)
				
				# bordes del mundo: siempre muro
				if x == 0 or x == ancho - 1 or z == 0 or z == largo - 1:
					mapa_bruto[pos] = false
					continue
				
				var distancia_al_centro = pos.distance_to(centro_vector)
				var radio_maximo = (ancho / 2.0) - 2.0
				var factor_costa = ruido_borde.get_noise_2d(x * 1.5, z * 1.5) * 7.0
				
				# fuera de la isla (costa irregular)
				if distancia_al_centro > (radio_maximo + factor_costa):
					mapa_bruto[pos] = false
					continue
				
				# centro seguro (siempre caminable)
				if distancia_al_centro <= radio_centro:
					mapa_bruto[pos] = true
					continue
				
				# forma general con ruido + factor distancia + modificador semilla
				var valor_ruido = ruido.get_noise_2d(x, z)
				var factor_distancia = 1.0 - (distancia_al_centro / (ancho * 0.5))
				var modificador_semilla = sin(float(semilla_mapa % 1000) + float(x) * 0.1) * 0.05
				
				if valor_ruido + (factor_distancia * 0.2) + modificador_semilla > umbral_actual:
					mapa_bruto[pos] = true
				else:
					mapa_bruto[pos] = false
		
		# flood fill desde el centro para descartar islas desconectadas
		visitados.clear()
		var cola: Array = [centro_vector]
		visitados[centro_vector] = true
		
		while cola.size() > 0:
			var actual = cola.pop_front()
			for dir in direcciones:
				var vecino = actual + dir
				if mapa_bruto.get(vecino, false) and not visitados.has(vecino):
					visitados[vecino] = true
					cola.append(vecino)
		
		if visitados.size() >= objetivo_caminables or umbral_actual <= -0.8:
			break
		
		umbral_actual -= 0.05
	
	# distancias al borde (para el efecto iceberg si lo usas)
	var distancias := calcular_distancias_al_borde(visitados, direcciones)
	
	return { "visitados": visitados, "distancias": distancias }


# -----------------------------------------------------------------------------
# INSTANCIACION DE BLOQUES
# -----------------------------------------------------------------------------
func mapa_carga_simple(visitados: Dictionary, _distancias: Dictionary) -> void:
	var centro_x = int(ancho / 2)
	var centro_z = int(largo / 2)
	
	for z in range(largo):
		for x in range(ancho):
			var pos = Vector2i(x, z)
			var pos_final = Vector3(x * tamano_bloque, 0, z * tamano_bloque)
			
			if visitados.has(pos):
				var bloque = bloque_terreno.instantiate()
				add_child(bloque)
				bloque.position = pos_final
				
				# plantas (solo fuera del centro seguro)
				if generar_plantas:
					var dist_centro_planta = Vector2(pos_final.x, pos_final.z).distance_to(
						Vector2(centro_x * tamano_bloque, centro_z * tamano_bloque)
					)
					if dist_centro_planta > radio_exclusion_centro_plantas:
						if rng.randf() < probabilidad_spawn_planta:
							var indice_planta = rng.randi() % escenas_plantas.size()
							var planta = escenas_plantas[indice_planta].instantiate()
							add_child(planta)
							var offset_x = rng.randf_range(-0.35, 0.35)
							var offset_z = rng.randf_range(-0.35, 0.35)
							planta.position = pos_final + Vector3(offset_x, 0.0, offset_z)
							planta.rotation = Vector3.ZERO
							var escala_azar = rng.randf_range(0.85, 1.15)
							planta.scale = Vector3(escala_azar, escala_azar, escala_azar)
			else:
				var muro = bloque_borde.instantiate()
				add_child(muro)
				muro.position = pos_final
				muro.visible = false


func mapa_carga_compleja(visitados: Dictionary, _distancias: Dictionary) -> void:
	var centro_x = int(ancho / 2)
	var centro_z = int(largo / 2)
	
	for z in range(largo):
		for x in range(ancho):
			var pos = Vector2i(x, z)
			var pos_final = Vector3(x * tamano_bloque, 0, z * tamano_bloque)
			
			if visitados.has(pos):
				var bloque = bloque_terreno.instantiate()
				add_child(bloque)
				
				var retraso = float(x) * 0.005
				bloque.position = pos_final + Vector3(0, -8.0, 0)
				bloque.scale = Vector3(1.0, 0.01, 1.0)
				
				var tween = create_tween().set_parallel(true)
				tween.tween_property(bloque, "position", pos_final, 0.5)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(retraso)
				tween.tween_property(bloque, "scale", Vector3(1.0, 1.0, 1.0), 0.5)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(retraso)
			else:
				var muro = bloque_borde.instantiate()
				add_child(muro)
				muro.position = pos_final
				muro.visible = false
		
		if is_inside_tree():
			await get_tree().create_timer(0.04).timeout


# -----------------------------------------------------------------------------
# FUNCIONES AUXILIARES
# -----------------------------------------------------------------------------
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
	var centro_x = (float(ancho) / 2.0) * tamano_bloque
	var centro_z = (float(largo) / 2.0) * tamano_bloque
	
	if total <= 1:
		return Vector3(centro_x, altura_spawn, centro_z)
	
	var radio_spawn = 2.0
	var angulo = (float(indice) / float(total)) * TAU
	return Vector3(centro_x + cos(angulo) * radio_spawn, altura_spawn, centro_z + sin(angulo) * radio_spawn)
