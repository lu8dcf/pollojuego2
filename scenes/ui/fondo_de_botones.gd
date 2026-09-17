# barra_animada.gd
extends TextureRect
class_name BarraAnimada

# Señal para avisarle a los botones cuando todas las barras terminen
signal barras_completadas

# Parámetros de animación
@export var duracion_animacion: float = 0.5        # Duración de la traslación de cada barra
@export var retraso_maximo_x: float = 0.6          # Tiempo total entre la primera y última barra
@export var tiempo_espera_inicial: float = 0.1     # Pausa antes de arrancar la secuencia

var posicion_original: Vector2

func _ready() -> void:
	posicion_original = position
	modulate.a = 0.0
	
	# Esperar un frame para leer posiciones globales
	await get_tree().process_frame
	_animar_entrada_por_x()

func _animar_entrada_por_x() -> void:
	var ancho_pantalla = get_viewport_rect().size.x
	
	# Calcular la posición X normalizada (0.0 a la izquierda, 1.0 a la derecha)
	var factor_x = clamp(global_position.x / ancho_pantalla, 0.0, 1.0)
	
	# Iniciar fuera de la pantalla (derecha)
	position.x = ancho_pantalla + size.x + 20.0
	
	# A menor X (más a la izquierda), menor retraso -> Aparece PRIMERO
	var retraso = tiempo_espera_inicial + (factor_x * retraso_maximo_x)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Traslación desde la derecha hacia su posición original
	tween.tween_property(self, "position:x", posicion_original.x, duracion_animacion)\
		.set_delay(retraso)
		
	# Aparición suave (Fade-in)
	tween.tween_property(self, "modulate:a", 1.0, duracion_animacion * 0.5)\
		.set_delay(retraso)
	
	# Emitir señal solo cuando termine la última barra
	tween.finished.connect(func():
		_verificar_ultima_barra()
	)

func _verificar_ultima_barra() -> void:
	# Busca si hay otras barras aún animándose en el grupo
	var barras = get_tree().get_nodes_in_group("barras_animadas")
	# Si es el último en terminar, emite la señal global
	barras_completadas.emit()
