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
	add_to_group("bala")
	top_level = true
	textureBullet.visible=true
	#balaExplosiva()

func _process(_delta: float) -> void:
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
		for cuerpo in cuerpos_en_area:
			if(cuerpo.is_in_group("enemy")):
				#print("danio enemigo ") --------------------------Aca cuando choca con el enemigo
				pass
	await get_tree().create_timer(0.5).timeout
	eliminarBala()

#-----------------------------------------------------------------------------comun y explosiva
func _on_tiempo_vida_timeout() -> void: #tiempo de vida de la bala comun
	eliminarBala()
	
func eliminarBala():
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	queue_free()


func _on_impacto_previo_body_entered(body: Node3D) -> void:
	explosion()
