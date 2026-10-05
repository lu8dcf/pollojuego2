class_name Dron
extends Node3D

#refereencias
var jugador: Jugador
var ancla: Node3D
var objetivo
@export var id_jugador: int
@export var lado: int

#
var tiempo_de_vida : float = 5.0
var tiempo_transcurrido: float = 0.0


#elementos escoltas:
@export var distancia_al_jugador: float = 2
@export var velocidad_seguimiento: float = 15.0
@export var suavizado: float = 15.0
@export var distancia_minima: float = 0.1
@export var distancia_maxima_objetivo: float = 600.0

func _enter_tree() -> void:
	add_to_group("Dron")
	var partes = name.split("_")
	if partes.size() >= 3:
		var id_dueno = partes[1].to_int()
		var lado_asignado = partes[2].to_int()
		
		set_multiplayer_authority(id_dueno)
		jugador = GlobalJuego._obtener_jugador(id_dueno)
		lado = lado_asignado # <--- El cliente ya sabe perfectamente su lado de escolta
		
		if jugador != null:
			top_level = true
			# Ahora sí calculamos la posición exacta de spawn en el cliente
			global_position = calcular_posicion_objetivo()

func inicializar(p_jugador: Jugador, p_posicion_inicial: Vector3, p_lado: int) -> void:
	jugador = p_jugador
	lado = p_lado

	top_level = true
	global_position = p_posicion_inicial
	#add_to_group("Dron")

	if jugador != null:
		objetivo = buscarObjetivoMasCercano()

func _ready():
	if jugador != null:
		objetivo = buscarObjetivoMasCercano()


func calcular_posicion_objetivo() -> Vector3:
	var derecha := jugador.global_transform.basis.x
	derecha.y = 0
	derecha = derecha.normalized()

	var offset = derecha * distancia_al_jugador * lado

	return jugador.global_position + offset


func _physics_process(delta):
	tiempo_transcurrido += delta
	if tiempo_transcurrido >= tiempo_de_vida:
		#el servidor lo borra
		if multiplayer.is_server():
			destruir()
		return
	#escolta
	if not is_instance_valid(jugador):
		return
	var objetivo_pos := calcular_posicion_objetivo()
	var direccion := objetivo_pos - global_position
	direccion.y = 0

	if direccion.length_squared() > 0.01:
		direccion = direccion.normalized()

		var velocidad_objetivo := direccion * velocidad_seguimiento

		global_position.x = lerp(
			global_position.x,
			global_position.x + velocidad_objetivo.x * delta,
			suavizado * delta
		)

		global_position.z = lerp(
			global_position.z,
			global_position.z + velocidad_objetivo.z * delta,
			suavizado * delta
		)

	
	#objetivo y hacaia donde mira
	if objetivo != null and is_instance_valid(objetivo):
		mirarObjetivo(delta)


func actualizar_objetivo():
	objetivo = buscarObjetivoMasCercano()

func mirarObjetivo(delta):
	actualizar_objetivo()
	if objetivo == null or not is_instance_valid(objetivo):
		return
	if not is_instance_valid(jugador):
		return
	#if(ojeti)
	var direccion = -(objetivo.global_position - global_position) #MUCHO MUY IMPORTANTE ESE MENOOOS
# sin contar la altura
	direccion.y = 0
	
	if direccion.length_squared() == 0:
		return
	
	direccion = direccion.normalized()
	var angulo_objetivo = atan2( #calculo angulo al objetivo
			direccion.x,
			direccion.z
		)
		
	var direccion_actual = global_transform.basis.z #forward de un node 3d
	direccion_actual.y = 0

	if direccion_actual.length_squared() == 0:
		return

	direccion_actual = direccion_actual.normalized()

	var angulo_actual = atan2(
		direccion_actual.x,
		direccion_actual.z
	)

	var diferencia = angle_difference( #cuanto debo girar hacia el objetivo
		angulo_actual,
		angulo_objetivo
	)

	rotation.y += diferencia * delta * 10.0 #aplico diferencia



func buscarObjetivoMasCercano():
	var listaEnemigos = GlobalJuego.spawn_container.get_children()
	var mas_cercano: Node3D = null
	var distancia_minima2: float = INF
	
	for obj in listaEnemigos:
		var distancia = global_position.distance_to(obj.global_position)
		if distancia < distancia_minima2:
			distancia_minima2 = distancia
			mas_cercano = obj
	if mas_cercano == null:
		return null
	var distancia = global_position.distance_to(mas_cercano.global_position)
	if(distancia > distancia_maxima_objetivo):
		var direccion = jugador.global_transform.basis.z
		direccion.y = 0

		if direccion.length_squared() == 0:
			return Vector3.ZERO

		return direccion.normalized()
	return mas_cercano


func destruir():
	queue_free()
