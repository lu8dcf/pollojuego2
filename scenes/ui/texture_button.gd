# texture_button_animado.gd
extends TextureButton
class_name TextureButtonAnimado

# Referencia al label hijo
@onready var label: Label = $Label

# Parámetros de animación visual (Hover)
@export var saturacion_normal: float = 1.0          # Saturación normal
@export var saturacion_hover: float = 1.5           # Saturación al hover
@export var brillo_hover: float = 1.2               # Brillo adicional
@export var velocidad_transicion: float = 10.0      # Velocidad de transición

# Parámetros de elevación (Hover)
@export var elevacion_hover: float = -5.0           # Cuánto se eleva (negativo = arriba)
@export var velocidad_elevacion: float = 12.0       # Velocidad de elevación

# Parámetros de línea decorativa
@export var color_linea: Color = Color(0.957, 0.959, 0.953, 1.0)     # Color de la línea (amarillo)
@export var grosor_linea: float = 3.0               # Grosor de la línea
@export var ancho_linea: float = 0.6                # Ancho relativo de la línea (0-1)
@export var velocidad_linea: float = 8.0            # Velocidad de aparición

# Parámetros de temblor
@export var intensidad_temblor: float = 2.0         # Intensidad del temblor
@export var duracion_temblor: float = 0.2           # Duración del temblor

# Parámetros de animación de entrada
@export var tiempo_espera_barras: float = 0.3      # Tiempo que espera a que las barras terminen de entrar
@export var tiempo_espera_base: float = 0.1         # Retraso base propio de los botones
@export var retraso_por_pantalla_y: float = 0.6     # Intervalo de tiempo entre el primer y último botón según Y
@export var duracion_animacion_entrada: float = 0.5 # Duración del movimiento de entrada

# Parámetros del label
@export var tamanio: int = 20
@export var color: String = "#ffffff"
@export var texto: String = ""

# Variables internas
var posicion_original: Vector2
var temblando: bool = false
var tiempo_temblor: float = 0.0
var mouse_encima: bool = false
var saturacion_actual: float = 1.0
var progreso_linea: float = 0.0                    # 0 = oculta, 1 = visible
var elevacion_actual: float = 0.0                  # Elevación actual del botón
var animando_entrada: bool = true                   # Deshabilita hover/procesos mientras entra

func _ready() -> void:
	posicion_original = position
	disabled = true
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Al presionar, ejecuta la aberración/impacto directo sobre el shader
	pressed.connect(_on_pressed_impacto)
	
	set_process(true)
	_aplicar_saturacion(saturacion_normal)
	cambiar_label(tamanio, color, texto)
	queue_redraw()
	
	await get_tree().process_frame
	animar_entrada_cascada()

func _on_pressed_impacto() -> void:
	"""Busca el ColorRect en el CanvasLayer/Escena y modifica su shader directamente"""
	var color_rect = _buscar_color_rect(get_tree().current_scene)
	
	if color_rect and color_rect.material is ShaderMaterial:
		var mat = color_rect.material as ShaderMaterial
		
		# Forzar el parámetro 'intensidad' en el shader (0.08 para que sea bien visible)
		mat.set_shader_parameter("intensidad", 0.08)
		
		# Reducir la intensidad a 0.0 progresivamente en 0.25 segundos
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/intensidad", 0.0, 0.25)

func _buscar_color_rect(nodo: Node) -> ColorRect:
	"""Recorre la escena buscando el ColorRect que tiene el ShaderMaterial"""
	if nodo is ColorRect and nodo.material is ShaderMaterial:
		return nodo
		
	for hijo in nodo.get_children():
		var resultado = _buscar_color_rect(hijo)
		if resultado:
			return resultado
			
	return null

func animar_entrada_cascada() -> void:
	animando_entrada = true
	disabled = true
	
	var viewport_rect = get_viewport_rect()
	var ancho_pantalla = viewport_rect.size.x
	var alto_pantalla = viewport_rect.size.y
	
	var y_global = global_position.y
	var factor_y = clamp(y_global / alto_pantalla, 0.0, 1.0)
	
	position.x = ancho_pantalla + size.x + 20.0
	modulate.a = 0.0
	
	var retraso_total = tiempo_espera_barras + tiempo_espera_base + (factor_y * retraso_por_pantalla_y)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", posicion_original.x, duracion_animacion_entrada).set_delay(retraso_total)
	tween.tween_property(self, "modulate:a", 1.0, duracion_animacion_entrada * 0.5).set_delay(retraso_total)
	
	tween.finished.connect(func():
		animando_entrada = false
		disabled = false
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
		var ancho_boton = size.x
		var ancho_linea_px = ancho_boton * ancho_linea * progreso_linea
		var centro_x = size.x / 2.0
		var y_linea = size.y + grosor_linea + 5.0
		
		var color_final = color_linea
		color_final.a = progreso_linea
		
		draw_line(
			Vector2(centro_x - ancho_linea_px / 2.0, y_linea),
			Vector2(centro_x + ancho_linea_px / 2.0, y_linea),
			color_final,
			grosor_linea
		)

func _on_mouse_entered() -> void:
	if animando_entrada:
		return
	mouse_encima = true
	_iniciar_temblor()

func _on_mouse_exited() -> void:
	if animando_entrada:
		return
	mouse_encima = false

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
	var elevacion_objetivo = elevacion_hover if mouse_encima else 0.0
	elevacion_actual = lerp(elevacion_actual, elevacion_objetivo, velocidad_elevacion * delta)
	
	if not temblando:
		_actualizar_posicion_elevacion()

func _actualizar_posicion_elevacion() -> void:
	position = posicion_original + Vector2(0, elevacion_actual)

func _actualizar_linea(delta: float) -> void:
	var linea_objetivo = 1.0 if mouse_encima else 0.0
	progreso_linea = lerp(progreso_linea, linea_objetivo, velocidad_linea * delta)
	queue_redraw()

func _actualizar_saturacion(delta: float) -> void:
	var saturacion_objetivo = saturacion_hover if mouse_encima else saturacion_normal
	saturacion_actual = lerp(saturacion_actual, saturacion_objetivo, velocidad_transicion * delta)
	_aplicar_saturacion(saturacion_actual)

func _aplicar_saturacion(valor_saturacion: float) -> void:
	if valor_saturacion > 1.0:
		var factor = valor_saturacion * brillo_hover
		modulate = Color(factor, factor, factor, modulate.a)
	else:
		modulate = Color(1.0, 1.0, 1.0, modulate.a)

func cambiar_texto(texto_nuevo: String):
	label.text = texto_nuevo

func cambiar_label(tamanio_nuevo: int = 20, color_nuevo: String = "#ffffff", texto_nuevo: String = ""):
	var color_final: Color
	if color_nuevo.length() == 7:
		color_final = Color(color_nuevo + "ff")
	else:
		color_final = Color(color_nuevo)
	
	label.label_settings.font_size = tamanio_nuevo
	label.add_theme_font_size_override("font_size", tamanio_nuevo)
	label.label_settings.font_color = color_final
	
	if texto_nuevo != "":
		label.text = texto_nuevo
	
	label.queue_redraw()

func activar_hover():
	_on_mouse_entered()

func desactivar_hover():
	_on_mouse_exited()
