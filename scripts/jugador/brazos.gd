extends Node3D

#Pruebo la fabrica de armas
@onready
var crear_armas_derecho = $derecho

@onready var mano_izquierda: Marker3D = $izquierdo/Marker3D
@onready var mano_derecha: Marker3D = $derecho/Marker3D

enum Manos {
	IZQUIERDA,
	DERECHA
}
var ultima_mano: Manos = Manos.IZQUIERDA

func _ready() -> void:
	var arma = crear_armas_derecho.crear_arma(1)

func obtener_arma(mano: Manos) -> Node:
	if mano == Manos.IZQUIERDA:
		if mano_izquierda.get_child_count() > 0:
			return mano_izquierda.get_child(0)
	else:
		if mano_derecha.get_child_count() > 0:
			return mano_derecha.get_child(0)
	return null


func equipar_arma(id_arma: int) -> void:
	var mano: Marker3D
	if ultima_mano == Manos.IZQUIERDA:
		mano = mano_izquierda
	else:
		mano = mano_derecha
	# si esa mano tiene un arma...
	if mano.get_child_count() > 0:
		var arma_actual = mano.get_child(0)
		# si se intenta la misma arma que retorne
		if arma_actual.id_arma == id_arma:
			return
		# si es otra, que la saque
		arma_actual.queue_free()
	# creo una nueva arma
	var nueva_arma = crear_armas_derecho.crear_arma(id_arma)
	mano.add_child(nueva_arma)
	nueva_arma.transform = Transform3D.IDENTITY
	# cambia de mano para la siguiente arma
	if ultima_mano == Manos.IZQUIERDA:
		ultima_mano = Manos.DERECHA
	else:
		ultima_mano = Manos.IZQUIERDA
