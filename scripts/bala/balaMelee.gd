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
	add_to_group("bala")
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
	for cuerpo in cuerpos_en_area:
		if(cuerpo.is_in_group("enemy")):
			#print("golpeo enemigo") --------------------------Aca cuando choca con el enemigo
			pass

	eliminarBala()

#-----------------------------------------------------------------------------comun y explosiva
	
func eliminarBala():
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	queue_free()


func _on_tiempo_vida_timeout() -> void:
	eliminarBala()
	


func _on_area_melee_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	print("elimina melle")		#--------------------------Aca cuando choca con el enemigo
	eliminarBala()
	
