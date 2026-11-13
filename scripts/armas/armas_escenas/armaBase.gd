extends Node3D
class_name armaBase


@onready var synchronizer = $MultiplayerSynchronizer


@onready var containerBalas: Node3D = get_tree().get_first_node_in_group("contenedor_balas")
@onready var puntero
@onready var sprite = $Sprite3D
@onready var tiempo = $tiempoEntreDisparo

var objetivo: Node3D = null
var objetivo_actual: Node3D

#var objetivoMasCercano
var balaArma 

var datos: Arma
var jugadorPadre

func _ready() -> void:
	#top_level = true #esto es para que cuando el padre rote, este nodo no
	if(datos.tiempoDeAtaque > 0):
		tiempo.wait_time = datos.tiempoDeAtaque
	else:
		tiempo.wait_time = 1
		
	if(datos.comportamiento.bala != null):
		balaArma = datos.comportamiento.bala
	
	#ahora como es una packescene solo lo añado de hijo
	if(datos.sprite != null):
		var spriteArma = datos.sprite.instantiate()
		add_child(spriteArma)
		if (spriteArma.has_node("Marker3D")):
			puntero = spriteArma.get_child(-1)
		
	
	jugadorPadre = GlobalJuego._obtener_jugador(multiplayer.get_unique_id())
	
		


func _physics_process(delta):
	global_position = get_parent().global_position
	if objetivo != null and is_instance_valid(objetivo) and (balaArma != ComportamientoMelee): #melee estatica
		mirarObjetivo(delta)


func actualizar_objetivo():
	objetivo = buscarObjetivoMasCercano()




func mirarObjetivo(delta):
	#objetivoMasCercano = buscarObjetivoMasCercano()
	if objetivo == null or not is_instance_valid(objetivo):
		return
	
	var direccion = -(objetivo.global_position - global_position) #MUCHO MUY IMPORTANTE ESE MENOOOS
# sin contar la altura
	direccion.y = 0
	
	if direccion.length_squared() == 0:
		return
	
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
	return mas_cercano



func _on_tiempo_disparo_timeout() -> void:
	disparo()
	tiempo.start()
	pass # Replace with function body.

func _on_buscar_objetivo_timeout() -> void:
	actualizar_objetivo()


func disparo():
	if objetivo == null or not is_instance_valid(objetivo):
		return

	if jugadorPadre == null or not jugadorPadre.puede_disparar():
		return

	var direccion = objetivo.global_position - puntero.global_position
	direccion.y = 0
	direccion = direccion.normalized()

	var cantidad = 1
	var dispersion = 15.0

	if datos and datos.comportamiento:
		if datos.comportamiento.has_method("get_cant_perdigones"):
			cantidad = datos.comportamiento.get_cant_perdigones()
		if "dispersion" in datos.comportamiento:
			dispersion = datos.comportamiento.dispersion

	var posicion = puntero.global_position

	if multiplayer.is_server():
		# Si dispara el servidor, creamos la bala REAL (autoritativa para hacer danio)
		procesar_disparo_servidor(posicion, direccion, datos.danio, cantidad, dispersion, 1)
	else:
		#Cada cliente crea su bala VISUAL (con 'true' para indicar que no haga danioo)
		crear_balas_visualmente(posicion, direccion, datos.danio, cantidad, dispersion, true)
		# Pido al seervidor que procese el disparo real
		solicitar_disparo.rpc_id(1, direccion)


@rpc("any_peer", "reliable")
func solicitar_disparo(direccion: Vector3) -> void:
	if not multiplayer.is_server():
		return

	var emisor = multiplayer.get_remote_sender_id()
	var posicion = puntero.global_position
	var cantidad = 1
	var dispersion = 15.0

	if datos and datos.comportamiento:
		if datos.comportamiento.has_method("get_cant_perdigones"):
			cantidad = datos.comportamiento.get_cant_perdigones()
		if "dispersion" in datos.comportamiento:
			dispersion = datos.comportamiento.dispersion

	# El servidor crea la bala REAL (con 'false', lo que significa que SI se aplica danio)
	procesar_disparo_servidor(posicion, direccion, datos.danio, cantidad, dispersion, emisor)


func procesar_disparo_servidor(posicion: Vector3, direccion: Vector3, danio: float, cantidad: int, dispersion: float, id_emisor: int) -> void:
	# El servidor crea la bala autoritativa
	crear_balas_visualmente(posicion, direccion, danio, cantidad, dispersion, false)

	# Replico para los demas clientes para que las dibujen (marcadas como visuales 'true')
	replicar_disparo_a_otros.rpc(posicion, direccion, danio, cantidad, dispersion, id_emisor)


@rpc("any_peer", "reliable")
func replicar_disparo_a_otros(posicion: Vector3, direccion: Vector3, danio: float, cantidad: int, dispersion: float, id_emisor: int) -> void:
	if multiplayer.get_unique_id() == id_emisor:
		return

		# Los demas clientes crean su bala visual
	crear_balas_visualmente(posicion, direccion, danio, cantidad, dispersion, true)


# parametro es_visual_local a la funcin
func crear_balas_visualmente(posicion: Vector3, direccion: Vector3, danio: float, cantidad: int, dispersion: float, es_visual_local: bool) -> void:
	if balaArma == null:
		return

	var abanico = [0.0, dispersion, -dispersion, dispersion * 2.0, -dispersion * 2.0]
	var angulos = abanico.slice(0, clampi(cantidad, 1, abanico.size()))

	for grados in angulos:
		var dir_final = direccion.rotated(Vector3.UP, deg_to_rad(grados))
		var nueva_bala = balaArma.instantiate()

		nueva_bala.top_level = true
		containerBalas.add_child(nueva_bala, true)

		# Indicador si es visual/fantasma o real
		nueva_bala.iniciar(
			datos.comportamiento,
			posicion,
			dir_final,
			danio / angulos.size(),
			es_visual_local
		)
