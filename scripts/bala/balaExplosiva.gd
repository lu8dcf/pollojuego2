extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

#explosiva
var avanza = false
var velocidadBala = 15
var direccion

var inicio = false

#solo explosiva
@onready var areaExplosiva = $area_explosion

#TEST
@onready var textureBullet = $pollo_1


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
	textureBullet.visible=true
	#balaExplosiva()

func _process(delta: float) -> void:
	if(inicio):
		balaExplosiva()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if(avanza): #bala comun y explosiva
		global_position += direccion * velocidadBala * delta

#-------------------------------------------------------------------explosiva
func balaExplosiva():
	inicio = false
	avanza = true

	#TEST------------------------------------
	textureBullet.visible = true
	#fin Test
	
	var tiempoEspoleta = tipoComportamiento.tiempo_espoleta
	await get_tree().create_timer(tiempoEspoleta).timeout
	explosion()
	
func explosion():
	avanza = false
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


func _on_area_explosion_area_entered(area: Area3D) -> void:
	if(area.get_collision_layer_value(4)):
		eliminarBala()
	pass # Replace with function body.


func _on_impacto_previo_area_entered(area: Area3D) -> void:
	explosion()
	pass # Replace with function body.
