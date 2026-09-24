extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

#comun y explosiva
var avanza = false
var velocidadBala = 15
var direccion

var inicio = false

#solo comun
@onready var areaComun = $area_comun

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

func _process(_delta: float) -> void:
	if(inicio):
		balaComun()


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if(avanza): #bala comun y explosiva
		global_position += direccion * velocidadBala * delta


#------------------------------------------------------------------comun

func balaComun():
	inicio = false
	#TEST------------------------------------
	textureBullet.visible = true
	#fin Test
	
	areaComun.visible = true
	avanza=true
	tiempoDeVida.start()

#-----------------------------------------------------------------------------comun y explosiva
func _on_tiempo_vida_timeout() -> void: #tiempo de vida de la bala comun
	eliminarBala()
	
func eliminarBala():
	if !is_multiplayer_authority():
		return
	queue_free()
