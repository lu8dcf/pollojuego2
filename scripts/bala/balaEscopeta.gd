extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $vidaBala
var posicionInicio
var velocidadBala = 15
var direccion
var inicio = false
var avanza = false
var danioBala

var nro_perdigones
var es_fantasma: bool = false # Si es true, solo dibuja y no hace danio
#solo comun
#@onready var areaComun = $area_comun

#TEST
@onready var textureBullet = $pollo_1
@onready var dano = 10 # daño de la balad

func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3, danio,visual_local: bool = false) -> void:

	if comp == null: #si por alguna razon no tiene comportamiento, vuelve
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	danioBala = danio
	direccion = direccion_inicial.normalized()
	tiempoDeVida.wait_time = comp.get_vida_bala()
	
	inicio = true
	avanza = true
	es_fantasma = visual_local

	
func _ready() -> void:
	add_to_group("bala")
	top_level = true
	#textureBullet.visible=true

func _process(_delta: float) -> void:
	if(inicio):
		perdigones()


func _physics_process(delta: float) -> void:
	if not avanza:
		return
	global_position += direccion * velocidadBala * delta


#------------------------------------------------------------------comun

func perdigones():
	inicio = false
	tiempoDeVida.start()


#-----------------------------------------------------------------------------comun y explosiva
func _on_tiempo_vida_timeout() -> void: #tiempo de vida de la bala comun
	eliminarBala()
	
func eliminarBala():
	#if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		#return
	avanza = false
	queue_free()


#func _on_area_comun_body_entered(_body: Node3D) -> void:
	#if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		#return
		#
				##--------------------------Aca cuando choca con el enemigo
	#eliminarBala()
	#
#
#
#func _on_area_comun_area_entered(_area: Area3D) -> void:
	#if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		#return
	#eliminarBala()


func _on_body_entered(body: Node3D) -> void:
# Si es una bala puramente visual de un cliente, ignoramos las colisiones de daño)
	if es_fantasma:
		eliminarBala()
		return

	# Si estamos en el servidor, aplicamos el daño de verdad
	if multiplayer.is_server():
		if body.is_in_group("enemy"):
			if body.has_method("recibir_dano"):
				body.recibir_dano(danioBala)
				
	eliminarBala()


func _on_area_entered(_area: Area3D) -> void:
	#if not multiplayer.is_server(): # solo el servidor puede eliminar balas
		#return
	eliminarBala()
