extends Node3D
class_name armaBase

@export var bala = preload("res://scenes/bala/bala.tscn")

@onready var synchronizer = $MultiplayerSynchronizer


@onready var contenedor = $SpawnContainerBalas
@onready var puntero = $Marker3D
@onready var sprite = $Sprite3D
@onready var tiempo = $tiempoEntreDisparo

var objetivoMasCercano


@onready var objetivo = null
var datos: Arma

func _ready() -> void:
	top_level = true #esto es para que cuando el padre rote, este nodo no
	#if(datos.tiempoDeAtaque > 0):
		#tiempo.wait_time = datos.tiempoDeAtaque
	#else:
		#tiempo.wait_time = 1
		
	#aplico la textura del arma
	#sprite=datos.sprite
	
	#ahora como es una packescene solo lo añado de hijo
	if(datos.sprite != null):
		add_child(datos.sprite.instantiate())

func _physics_process(delta: float) -> void:
	global_position = get_parent().global_position
	mirarObjetivo(delta)
	
	
func mirarObjetivo(delta):
	# direccion desde el jugador hacia el mouse
	objetivoMasCercano = buscarObjetivoMasCercano()
	if(objetivoMasCercano == null):
		return
	
	var direccion = -(objetivoMasCercano - global_position) #MUCHO MUY IMPORTANTE ESE MENOOOS
# sin contar la altura
	direccion.y = 0

	# direccion actual del puntero
	var direccion_marker = -(puntero.global_position - global_position)
	direccion_marker.y = 0

	# angulo actual del puntero
	var angulo_marker = atan2(
		direccion_marker.x,
		direccion_marker.z
	)

	# angulo que debe tener el puntero
	var angulo_objetivo = atan2(
		direccion.x,
		direccion.z
	)

	# dir necesaria
	var diferencia = angle_difference(
		angulo_marker,
		angulo_objetivo
	)

	rotation.y += diferencia * delta * 10.0



func buscarObjetivoMasCercano():
	var listaEnemigos = GlobalJuego.spawn_container.get_children()
	var mas_cercano: Node3D = null
	var distancia_minima: float = INF
	
	for obj in listaEnemigos:
		var distancia = global_position.distance_to(obj.global_position)
		if distancia < distancia_minima:
			distancia_minima = distancia
			mas_cercano = obj
	if mas_cercano == null:
		return null
	return mas_cercano.global_position



func _on_tiempo_disparo_timeout() -> void:
	disparo()
	tiempo.start()
	pass # Replace with function body.


#func disparo():
	##Mas animacion
	#var nueva_bala = bala.instantiate()
	#nueva_bala.top_level = true #autonomo del padre
	#nueva_bala.set_multiplayer_authority(get_multiplayer_authority())
	#
	#var objetivo = buscarObjetivoMasCercano()
	#if objetivo == null:
		#return
		#
	#var direccion = objetivo - puntero.global_position
	#direccion.y = 0 #que no vaya ni arriba ni abajo
	#direccion = direccion.normalized()
	#
	#nueva_bala.iniciar(datos.comportamiento, puntero.global_position, direccion)
	#contenedor.add_child(nueva_bala, true) #lo agrego al contenedor de spawn

func disparo():
	var objetivo = buscarObjetivoMasCercano()

	if objetivo == null:
		return

	var direccion = objetivo - puntero.global_position
	direccion.y = 0
	direccion = direccion.normalized()

	#var tipo_bala = datos.comportamiento.tipo_bala

	if multiplayer.is_server():
		## Si este ArmaBase está en el servidor,
		## no necesitamos hacer un RPC.
		#crear_bala(
			#puntero.global_position,
			#direccion,
			##tipo_bala
		#)
	#else:
		## Si este ArmaBase pertenece a un cliente,
		# le pedimos al servidor que cree la bala.
		solicitar_disparo.rpc_id(
			1,
			puntero.global_position,
			direccion,
			#tipo_bala
		)

func crear_bala(posicion: Vector3, direccion: Vector3) -> void:
	var nueva_bala = bala.instantiate()
	nueva_bala.set_multiplayer_authority(1)
	contenedor.add_child(nueva_bala, true)
	nueva_bala.iniciar(
		datos.comportamiento,
		posicion,
		direccion
	)

#--------------------------------------------------------------------------------SERVIDOR

@rpc("any_peer", "reliable")
func solicitar_disparo(posicion: Vector3, direccion: Vector3) -> void:
	if !multiplayer.is_server():
		return

	crear_bala(posicion, direccion)
