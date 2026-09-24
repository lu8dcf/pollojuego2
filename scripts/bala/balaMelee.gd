extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

#comun y explosiva
var avanza = false
var direccion
var inicio = false

#solo melee
@onready var areaMelee = $area_melee

#TEST
#@onready var textureBullet = $pollo_1


func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3) -> void:

	if comp == null: #si por alguna razon no tiene comportamiento, vuelve
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	direccion = direccion_inicial.normalized()
	inicio = true
	
func _ready() -> void:
	top_level = true
	#textureBullet.visible=true
	balaMelee()

func _process(_delta: float) -> void:
	if(inicio):
		tiempoDeVida.start
		balaMelee()


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
#--------------------------------------------------------------------melee

func balaMelee():
	inicio = false
	areaMelee.visible = true
	await get_tree().create_timer(0.2).timeout
	#eliminarBala()
	#TEST------------------------------------
	#textureBullet.visible = true
	#fin Test
	
	var cuerpos_en_area = areaMelee.get_overlapping_bodies()
	#for cuerpo in cuerpos_en_area:
		#if cuerpo.is_in_group("enemies") and cuerpo.has_method("take_damage"):
			#cuerpo.take_damage(damage * GlobalItem.potenciando_danio_arma)

	eliminarBala()

#-----------------------------------------------------------------------------comun y explosiva
	
func eliminarBala():
	if !is_multiplayer_authority():
		return
	queue_free()


func _on_tiempo_vida_timeout() -> void:
	eliminarBala()
	pass # Replace with function body.
