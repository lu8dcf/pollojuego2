extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

#comun y explosiva
var avanza = false
var velocidadBala = 15
var direccion

var inicio = false

var danioBala

#solo comun
#@onready var areaComun = $area_comun

#TEST
@onready var textureBullet = $pollo_1
@onready var dano = 10 # daño de la balad

func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3, danio) -> void:

	if comp == null: #si por alguna razon no tiene comportamiento, vuelve
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	danioBala = danio
	direccion = direccion_inicial.normalized()
	inicio = true

	
func _ready() -> void:
	add_to_group("bala")
	top_level = true
	#textureBullet.visible=true

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
	#textureBullet.visible = true
	#fin Test
	
	#areaComun.visible = true
	avanza=true
	tiempoDeVida.start()

#-----------------------------------------------------------------------------comun y explosiva
func _on_tiempo_vida_timeout() -> void: #tiempo de vida de la bala comun
	eliminarBala()
	
func eliminarBala():
	if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		return
	
	queue_free()


func _on_area_comun_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		return
		
				#--------------------------Aca cuando choca con el enemigo
	eliminarBala()
	


func _on_area_comun_area_entered(_area: Area3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		return
	eliminarBala()


func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		return
	if body.is_in_group("enemy"):
		# Aplicar daño al enemigo
		if body.has_method("recibir_dano"):
			body.recibir_dano(danioBala)
			queue_free()
	


func _on_area_entered(_area: Area3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		return
	eliminarBala()
