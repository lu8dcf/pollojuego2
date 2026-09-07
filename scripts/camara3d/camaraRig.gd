class_name CameraRig
extends Node3D

@onready var camara: Camera3D = $OffsetRig/Camera3D

@export var jugador: Node3D #nodo al que seguir

@export var seguimiento_activo: bool = true #activa o desactica el seguimiento

@export var lookahead_activo: bool = true #lookahead (movimiento suave)

#Movimientos y limites del rig
#Porcentaje en que la camara auno no se mueve
#Sintaxis: 10 = 10% del ancho de la pantalla.
@export_range(0.0, 50.0, 0.5)
var radio_cercano: float = 10.0
#desplazamiento maximo (que no se mueve)
@export_range(1.0, 100.0, 0.5)
var radio_lejano: float = 40.0
# maximo desplazamiento moviendo, + suave = valores chicos: 0.5 - 1.0
@export_range(0.0, 5.0, 0.05)
var desplazamiento_maximo: float = 1.25
# Tiempo que tarda el lookahead en alcanzar el mouse/objetivo
@export_range(0.01, 2.0, 0.01)
var suavizado: float = 0.25

#poscision del rig
var _offset_base: Vector3

#desplazamiento que va a hacer el rig segun la pos del mouse
var _lookahead_actual: Vector3 = Vector3.ZERO

# suavizar el lookahead
var _tween: Tween


func _ready():
	if not jugador:
		printerr("CameraRig: No se ha asignado un jugador.")
		return
	# posciion relativa del jugador al rig
	_offset_base = global_position - jugador.global_position

func _physics_process(_delta):
	if not jugador:
		return

	if seguimiento_activo: #primero hago el movimiento
		var posicion_base = jugador.global_position + _offset_base
		global_position = posicion_base + _lookahead_actual

	if lookahead_activo: #despues calculo el desplazamiento suave
		var objetivo = _calcular_lookahead()
		_actualizar_lookahead(objetivo)
	else:
		_actualizar_lookahead(Vector3.ZERO)

func _calcular_lookahead() -> Vector3:
	var viewport = get_viewport()
	var tamanio = viewport.get_visible_rect().size #proporcional al tamanio de pantalla

	var mouse = viewport.get_mouse_position() #pos del mouse

	var centro = tamanio / 2.0 #centro de la pantalla

	var vector_mouse = mouse - centro #vector del centro al mouse


	var distancia_porcentaje = ( #paso ña distancia a porcentaje de la pantalla (comportamiento consistente)
		vector_mouse.length() / tamanio.x
	) * 100.0

	if distancia_porcentaje <= radio_cercano: #zona muerta
		return Vector3.ZERO #punto en que el mouse no esta tan lejos como para generar el desplazamiento

	var fuerza = remap( #esto devuelve un valor que esta entre 0 y desplazamiento maximo
		distancia_porcentaje,
		radio_cercano,
		radio_lejano, 
		0.0,
		desplazamiento_maximo 
	) #esta es la fuerza que hace que mientras mas lejos el mouse mas se "estira" pero de manera controlada

	fuerza = clamp( #restringo que no se pase de desplazamiento_maximo
		fuerza,
		0.0,
		desplazamiento_maximo
	)

	var direccion = vector_mouse.normalized() #normalizo la direccion del mouse

	return Vector3( #retorno
		direccion.x * fuerza,
		0.0,
		direccion.y * fuerza
	)


func _actualizar_lookahead(objetivo: Vector3): #el verdadero suavizado, siempre la magia del tween

	if _lookahead_actual.is_equal_approx(objetivo):
		return

	if _tween and _tween.is_running(): #rompo si hay otro tween
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)

	_tween.tween_property(
		self,
		"_lookahead_actual",
		objetivo,
		suavizado
	)
