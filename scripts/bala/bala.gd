extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

#comun y explosiva
var avanza = false
var velocidadBala = 15
var direccion

#solo comun
@onready var areaComun = $area_comun

#solo explosiva
@onready var areaExplosiva = $area_explosion

#solo melee
@onready var areaMelee = $area_melee

#TEST
@onready var textureBullet = $pollo_1


func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3) -> void:

	if comp == null: #si por alguna razon no tiene comportamiento, vuelve
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	direccion = direccion_inicial.normalized()

	if tipoComportamiento is comportamientoComun:
		balaComun()
	elif tipoComportamiento is comportamientoExplosiva:
		balaExplosiva()
	elif tipoComportamiento is ComportamientoMelee:
		balaMelee()


	
func _ready() -> void:

	textureBullet.visible=true


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if(avanza): #bala comun y explosiva
		global_position += direccion * velocidadBala * delta
#--------------------------------------------------------------------melee

func balaMelee():
	avanza = false
	areaMelee.visible = true
	await get_tree().create_timer(0.2).timeout
	eliminarBala()
	#TEST------------------------------------
	textureBullet.visible = true
	#fin Test
	
	var cuerpos_en_area = areaMelee.get_overlapping_bodies()
	#for cuerpo in cuerpos_en_area:
		#if cuerpo.is_in_group("enemies") and cuerpo.has_method("take_damage"):
			#cuerpo.take_damage(damage * GlobalItem.potenciando_danio_arma)
	await get_tree().create_timer(0.5).timeout
	eliminarBala()

#------------------------------------------------------------------comun

func balaComun():
	
	#TEST------------------------------------
	textureBullet.visible = true
	#fin Test
	
	areaComun.visible = true
	avanza=true
	tiempoDeVida.start()

#-------------------------------------------------------------------explosiva
func balaExplosiva():
	avanza = true

	#TEST------------------------------------
	textureBullet.visible = true
	#fin Test
	
	var tiempoEspoleta = tipoComportamiento.tiempo_espoleta
	await get_tree().create_timer(tiempoEspoleta).timeout
	explosion()
	
func explosion():
	velocidadBala = 0
	await get_tree().process_frame
	
	# Obtener cuerpos dentro del Area
	areaExplosiva.visible = true
	var cuerpos_en_area = areaExplosiva.get_overlapping_bodies()
	if(cuerpos_en_area != null):
		print("en la explosion me llevo a :")
	else:
		print("vacio")
	#for cuerpo in cuerpos_en_area:
		#if cuerpo.is_in_group("enemies") and cuerpo.has_method("take_damage"):
			#cuerpo.take_damage(damage * GlobalItem.potenciando_danio_arma)
	await get_tree().create_timer(0.5).timeout
	eliminarBala()

#-----------------------------------------------------------------------------comun y explosiva
func _on_tiempo_vida_timeout() -> void: #tiempo de vida de la bala comun
	eliminarBala()
	
func eliminarBala():
	if !is_multiplayer_authority():
		return
	queue_free()
