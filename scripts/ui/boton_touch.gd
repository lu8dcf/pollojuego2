extends TouchScreenButton
class_name TouchScreenButtonAnimado

# Referencia al label hijo (opcional)
@onready var label: Label = get_node_or_null("Label")

# Parámetros de animación visual (Al mantener presionado / Hover táctil)
@export var saturacion_normal: float = 1.0         # Saturación normal
@export var saturacion_hover: float = 1.5           # Saturación al presionar
@export var brillo_hover: float = 1.2               # Brillo adicional
@export var velocidad_transicion: float = 10.0      # Velocidad de transición

# Parámetros de elevación
@export var elevacion_hover: float = -5.0           # Cuánto se eleva (negativo = arriba)
@export var velocidad_elevacion: float = 12.0       # Velocidad de elevación

# Parámetros de línea decorativa
@export var color_linea: Color = Color(0.957, 0.959, 0.953, 1.0)
@export var grosor_linea: float = 3.0
@export var ancho_linea: float = 0.6                # Ancho relativo (0-1)
@export var velocidad_linea: float = 8.0

# Parámetros de temblor
@export var intensidad_temblor: float = 2.0
@export var duracion_temblor: float = 0.2

# Parámetros de animación de entrada
@export var animar_al_iniciar: bool = true          # Desactívalo si es un botón de HUD en juego
@export var tiempo_espera_barras: float = 0.3
@export var tiempo_espera_base: float = 0.1
@export var retraso_por_pantalla_y: float = 0.6
@export var duracion_animacion_entrada: float = 0.5

# Parámetros del label
@export var tamanio: int = 20
@export var color: String = "#ffffff"
@export var texto: String = ""

var disabled: bool = false:
	set(valor):
		disabled = valor
		# Atenúa el botón visualmente cuando está deshabilitado
		modulate.a = 0.5 if disabled else 1.0
		if disabled:
			presionado = false

# Variables internas
var posicion_original: Vector2
var temblando: bool = false
var tiempo_temblor: float = 0.0
var presionado: bool = false
var saturacion_actual: float = 1.0
var progreso_linea: float = 0.0
var elevacion_actual: float = 0.0
var animando_entrada: bool = false

func _ready() -> void:
	posicion_original = position
	
	# En TouchScreenButton, el "hover" ocurre mientras el dedo mantiene presionado el botón
	pressed.connect(_on_touch_pressed)
	released.connect(_on_touch_released)
	
	set_process(true)
	_aplicar_saturacion(saturacion_normal)
	
	if label:
		cambiar_label(tamanio, color, texto)
		
	queue_redraw()
	
	if animar_al_iniciar:
		await get_tree().process_frame
		animar_entrada_cascada()

func _obtener_tamano_textura() -> Vector2:
	if texture_normal:
		return texture_normal.get_size()
	return Vector2(100, 40)

func _on_touch_pressed() -> void:
	if animando_entrada or disabled:
		return
	presionado = true
	_iniciar_temblor()
	_ejecutar_impacto()
	
	if Sonidos.has_method("sonidoHover"):
		Sonidos.sonidoHover()
	if Sonidos.has_method("sonidoSelect"):
		Sonidos.sonidoSelect()

func _on_touch_released() -> void:
	presionado = false

func _ejecutar_impacto() -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var color_rect = _buscar_color_rect(tree.current_scene)
	if color_rect and color_rect.material is ShaderMaterial:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("intensidad", 0.08)
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/intensidad", 0.0, 0.25)

func _buscar_color_rect(nodo: Node) -> ColorRect:
	if nodo is ColorRect and nodo.material is ShaderMaterial:
		return nodo
	for hijo in nodo.get_children():
		var resultado = _buscar_color_rect(hijo)
		if resultado:
			return resultado
	return null

func animar_entrada_cascada() -> void:
	animando_entrada = true
	var tam = _obtener_tamano_textura()
	var viewport_rect = get_viewport_rect()
	var ancho_pantalla = viewport_rect.size.x
	var alto_pantalla = viewport_rect.size.y
	
	var factor_y = clamp(global_position.y / alto_pantalla, 0.0, 1.0)
	
	position.x = ancho_pantalla + tam.x + 20.0
	modulate.a = 0.0
	
	var retraso_total = tiempo_espera_barras + tiempo_espera_base + (factor_y * retraso_por_pantalla_y)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", posicion_original.x, duracion_animacion_entrada).set_delay(retraso_total)
	tween.tween_property(self, "modulate:a", 1.0, duracion_animacion_entrada * 0.5).set_delay(retraso_total)
	
	tween.finished.connect(func():
		animando_entrada = false
	)

func _process(delta: float) -> void:
	if animando_entrada:
		return
		
	_actualizar_saturacion(delta)
	_actualizar_linea(delta)
	_actualizar_elevacion(delta)
	
	if temblando:
		_actualizar_temblor(delta)

func _draw() -> void:
	if progreso_linea > 0.01 and not animando_entrada:
		var tam = _obtener_tamano_textura()
		var ancho_linea_px = tam.x * ancho_linea * progreso_linea
		
		# Ajuste según si el TouchScreenButton tiene "Centered" activado o no
		var centro_x = 0.0 if shape_centered else (tam.x / 2.0)
		var y_linea = (tam.y / 2.0 if shape_centered else tam.y) + grosor_linea + 5.0
		
		var color_final = color_linea
		color_final.a = progreso_linea
		
		draw_line(
			Vector2(centro_x - ancho_linea_px / 2.0, y_linea),
			Vector2(centro_x + ancho_linea_px / 2.0, y_linea),
			color_final,
			grosor_linea
		)

func _iniciar_temblor() -> void:
	temblando = true
	tiempo_temblor = 0.0

func _actualizar_temblor(delta: float) -> void:
	tiempo_temblor += delta
	if tiempo_temblor >= duracion_temblor:
		temblando = false
		_actualizar_posicion_elevacion()
		return
	
	var progreso = tiempo_temblor / duracion_temblor
	var intensidad_actual = intensidad_temblor * (1.0 - progreso)
	var offset_x = randf_range(-intensidad_actual, intensidad_actual)
	var offset_y = randf_range(-intensidad_actual, intensidad_actual)
	
	position = posicion_original + Vector2(offset_x, offset_y) + Vector2(0, elevacion_actual)

func _actualizar_elevacion(delta: float) -> void:
	var elevacion_objetivo = elevacion_hover if presionado else 0.0
	elevacion_actual = lerp(elevacion_actual, elevacion_objetivo, velocidad_elevacion * delta)
	if not temblando:
		_actualizar_posicion_elevacion()

func _actualizar_posicion_elevacion() -> void:
	position = posicion_original + Vector2(0, elevacion_actual)

func _actualizar_linea(delta: float) -> void:
	var linea_objetivo = 1.0 if presionado else 0.0
	progreso_linea = lerp(progreso_linea, linea_objetivo, velocidad_linea * delta)
	queue_redraw()

func _actualizar_saturacion(delta: float) -> void:
	var saturacion_objetivo = saturacion_hover if presionado else saturacion_normal
	saturacion_actual = lerp(saturacion_actual, saturacion_objetivo, velocidad_transicion * delta)
	_aplicar_saturacion(saturacion_actual)

func _aplicar_saturacion(valor_saturacion: float) -> void:
	if valor_saturacion > 1.0:
		var factor = valor_saturacion * brillo_hover
		modulate = Color(factor, factor, factor, modulate.a)
	else:
		modulate = Color(1.0, 1.0, 1.0, modulate.a)

func cambiar_texto(texto_nuevo: String) -> void:
	if label:
		label.text = texto_nuevo

func cambiar_label(tamanio_nuevo: int = 20, color_nuevo: String = "#ffffff", texto_nuevo: String = "") -> void:
	if not label:
		return
	var color_final: Color = Color(color_nuevo + "ff") if color_nuevo.length() == 7 else Color(color_nuevo)
	
	if label.label_settings:
		label.label_settings.font_size = tamanio_nuevo
		label.label_settings.font_color = color_final
	else:
		label.add_theme_font_size_override("font_size", tamanio_nuevo)
		label.add_theme_color_override("font_color", color_final)
	
	if texto_nuevo != "":
		label.text = texto_nuevo
	label.queue_redraw()
