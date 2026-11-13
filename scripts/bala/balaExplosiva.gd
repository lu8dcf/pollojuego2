extends Node3D

var tipoComportamiento = comportamientoArma

var posicionInicio

#explosiva
var avanza = false
var velocidadBala = 15
var direccion

var inicio = false
var es_fantasma: bool = false 
var danioBala 
#solo explosiva
@onready var areaExplosiva = $area_explosion
@onready var tiempo = $captarExplosion


#TEST
@onready var textureBullet =$explosiva


func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3, danio: int,visual_local: bool = false) -> void:

	if comp == null: #si por alguna razon no tiene comportamiento, vuelve
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	danioBala = danio
	direccion = direccion_inicial.normalized()
	inicio = true
	tiempo.wait_time =comp.get_tiempoEspoleta()
	es_fantasma = visual_local
	
func _ready() -> void:
	top_level = true
	Sonidos.sonidoCohete()
	textureBullet.visible=true
	#balaExplosiva()

func _process(_delta: float) -> void:
	if(inicio):
		balaExplosiva()

func _physics_process(delta: float) -> void:
	if(avanza): #bala comun y explosiva
		global_position += direccion * velocidadBala * delta

#-------------------------------------------------------------------explosiva
func balaExplosiva():
	inicio = false
	avanza = true

	textureBullet.visible = true
	#fin Test
	
	var tiempoEspoleta = tipoComportamiento.tiempo_espoleta #pongo el tiempo definido en el arma
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
			if(cuerpo.is_in_group("enemy") and cuerpo.has_method("recibir_dano")):
				if is_instance_valid(cuerpo) and cuerpo.is_inside_tree():
					cuerpo.recibir_dano(danioBala)
	tiempo.start()

#-----------------------------------------------------------------------------cexplosiva
func _on_tiempo_vida_timeout() -> void:
	eliminarBala()
	
func eliminarBala():
	queue_free()


func _on_area_explosion_area_entered(area: Area3D) -> void:
	if(area.get_collision_layer_value(4)):
		eliminarBala()
	if(area.is_in_group("enemy")):
		explosion()
	pass # Replace with function body.

func _on_area_explosion_body_entered(_body: Node3D) -> void:
	explosion()
	pass # Replace with function body.


func _on_body_entered(body: Node3D) -> void:
	if es_fantasma:
		eliminarBala()
		return
	if body.is_in_group("enemy"):
		# Aplicar daño al enemigo
		if body.has_method("recibir_dano"):
			body.recibir_dano(danioBala)
			queue_free()


func _on_captar_explosion_timeout() -> void:
	eliminarBala()
	pass # Replace with function body.
