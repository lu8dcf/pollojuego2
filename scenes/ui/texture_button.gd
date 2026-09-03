# texture_button_animado.gd
extends TextureButton
class_name TextureButtonAnimado

# Referencia al label hijo
@onready var label: Label = $Label

# Parámetros de animación
@export var saturacion_normal: float = 1.0          # Saturación normal
@export var saturacion_hover: float = 1.5           # Saturación al hover
@export var brillo_hover: float = 1.2               # Brillo adicional
@export var velocidad_transicion: float = 10.0      # Velocidad de transición

# Parámetros de elevación
@export var elevacion_hover: float = -5.0           # Cuánto se eleva (negativo = arriba)
@export var velocidad_elevacion: float = 12.0       # Velocidad de elevación

# Parámetros de línea decorativa
@export var color_linea: Color = Color(1, 1, 0)     # Color de la línea (amarillo)
@export var grosor_linea: float = 3.0               # Grosor de la línea
@export var ancho_linea: float = 0.6                # Ancho relativo de la línea (0-1)
@export var velocidad_linea: float = 8.0            # Velocidad de aparición

# Parámetros de temblor
@export var intensidad_temblor: float = 2.0         # Intensidad del temblor
@export var duracion_temblor: float = 0.2           # Duración del temblor

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

func _ready() -> void:
	# Guardar posición original
	posicion_original = position
	
	# Conectar señales del mouse
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Configurar el proceso
	set_process(true)
	
	# Aplicar valores iniciales
	_aplicar_saturacion(saturacion_normal)
	cambiar_label(tamanio, color, texto)
	
	# Asegurarse de que el botón se redibuje
	queue_redraw()

func _process(delta: float) -> void:
	# Actualizar saturación suavemente
	_actualizar_saturacion(delta)
	
	# Actualizar línea decorativa
	_actualizar_linea(delta)
	
	# Actualizar elevación
	_actualizar_elevacion(delta)
	
	# Actualizar temblor si está activo
	if temblando:
		_actualizar_temblor(delta)

func _draw() -> void:
	"""Dibuja la línea decorativa debajo del botón"""
	if progreso_linea > 0.01:  # Solo dibujar si es visible
		var ancho_boton = size.x
		var ancho_linea_px = ancho_boton * ancho_linea * progreso_linea
		var centro_x = size.x / 2
		var y_linea = size.y + grosor_linea + 5  # 5 píxeles debajo del botón
		
		# Dibujar línea con alpha según progreso
		var color_final = color_linea
		color_final.a = progreso_linea
		
		draw_line(
			Vector2(centro_x - ancho_linea_px / 2, y_linea),
			Vector2(centro_x + ancho_linea_px / 2, y_linea),
			color_final,
			grosor_linea
		)

func _on_mouse_entered() -> void:
	"""Cuando el mouse entra al botón"""
	mouse_encima = true
	_iniciar_temblor()

func _on_mouse_exited() -> void:
	"""Cuando el mouse sale del botón"""
	mouse_encima = false

func _iniciar_temblor() -> void:
	"""Inicia el efecto de temblor"""
	temblando = true
	tiempo_temblor = 0.0

func _actualizar_temblor(delta: float) -> void:
	"""Actualiza el efecto de temblor"""
	tiempo_temblor += delta
	
	if tiempo_temblor >= duracion_temblor:
		# Terminar temblor
		temblando = false
		_actualizar_posicion_elevacion()
		return
	
	# Calcular intensidad decreciente
	var progreso = tiempo_temblor / duracion_temblor
	var intensidad_actual = intensidad_temblor * (1.0 - progreso)
	
	# Aplicar temblor aleatorio
	var offset_x = randf_range(-intensidad_actual, intensidad_actual)
	var offset_y = randf_range(-intensidad_actual, intensidad_actual)
	
	position = posicion_original + Vector2(offset_x, offset_y) + Vector2(0, elevacion_actual)

func _actualizar_elevacion(delta: float) -> void:
	"""Actualiza la elevación del botón"""
	var elevacion_objetivo = elevacion_hover if mouse_encima else 0.0
	elevacion_actual = lerp(elevacion_actual, elevacion_objetivo, velocidad_elevacion * delta)
	
	if not temblando:
		_actualizar_posicion_elevacion()

func _actualizar_posicion_elevacion() -> void:
	"""Aplica la elevación a la posición"""
	position = posicion_original + Vector2(0, elevacion_actual)

func _actualizar_linea(delta: float) -> void:
	"""Actualiza la aparición/desaparición de la línea"""
	var linea_objetivo = 1.0 if mouse_encima else 0.0
	progreso_linea = lerp(progreso_linea, linea_objetivo, velocidad_linea * delta)
	queue_redraw()  # Redibujar para actualizar la línea

func _actualizar_saturacion(delta: float) -> void:
	"""Actualiza la saturación suavemente"""
	var saturacion_objetivo = saturacion_hover if mouse_encima else saturacion_normal
	saturacion_actual = lerp(saturacion_actual, saturacion_objetivo, velocidad_transicion * delta)
	_aplicar_saturacion(saturacion_actual)

func _aplicar_saturacion(valor_saturacion: float) -> void:
	"""Aplica saturación al botón usando modulate"""
	if valor_saturacion > 1.0:
		# Aumentar brillo y saturación
		var factor = valor_saturacion * brillo_hover
		modulate = Color(factor, factor, factor, 1.0)
	else:
		# Color normal
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func cambiar_label(tamanio_nuevo: int = 20, color_nuevo: String = "#ffffff", texto_nuevo: String = ""):
	"""Cambia las propiedades del label"""
	# Convertir color correctamente
	var color_final: Color
	if color_nuevo.length() == 7:  # Formato #RRGGBB
		color_final = Color(color_nuevo + "ff")
	else:
		color_final = Color(color_nuevo)
	

	
	# Modificar solo tamaño y color
	label.label_settings.font_size = tamanio_nuevo
	label.add_theme_font_size_override("font_size", tamanio_nuevo)
	label.label_settings.font_color = color_final
	
	# Establecer texto
	if texto_nuevo != "":
		label.text = texto_nuevo
	
	label.queue_redraw()

# Funciones públicas para control manual
func activar_hover():
	"""Activa el efecto hover manualmente"""
	_on_mouse_entered()

func desactivar_hover():
	"""Desactiva el efecto hover manualmente"""
	_on_mouse_exited()
