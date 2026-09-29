class_name Escudo
extends StaticBody3D

var jugador: Node3D
@onready var areaDeteccion: Area3D = $Area3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var tiempo_de_vida : float = 5.0
var tiempo_transcurrido: float = 0.0


func _enter_tree() -> void:
	add_to_group("Escudo")
	top_level = true
	
	var partes = name.split("_") #corta el nombre en la barraBaja
	#escudo e ID
	if partes.size() >= 2:
		var id_jugador = partes[1].to_int()
		
		set_multiplayer_authority(id_jugador)
		jugador = GlobalJuego._obtener_jugador(id_jugador)
		
		if jugador != null:
			global_position = Vector3(jugador.global_position.x, 0.0, jugador.global_position.z)

func _ready() -> void:
	#colisiones
	collision.disabled = false 
	visible = true

	if multiplayer.is_server():
		areaDeteccion.monitoring = true
		# Conectamos la senial 
		if not areaDeteccion.body_entered.is_connected(_on_body_entered_continuo):
			areaDeteccion.body_entered.connect(_on_body_entered_continuo)
		
		#enemigos que estan cerca cuando se habilita escudo
		_chequeo_inicial_rapido()
	else:
		areaDeteccion.monitoring = false

func inicializar(p_jugador: Node3D) -> void:
	jugador = p_jugador
	if jugador != null:
		global_position = Vector3(jugador.global_position.x, 0.0, jugador.global_position.z)

func _physics_process(delta):
	if not is_instance_valid(jugador):
		return
		
	tiempo_transcurrido += delta
	if tiempo_transcurrido >= tiempo_de_vida:
		#servidor lo borra y el MultiplayerSpawner lo limpia en los clientes
		if multiplayer.is_server():
			destruir()
		return
	# Seguir al jugador continuamente
	global_position.x = jugador.global_position.x
	global_position.z = jugador.global_position.z
	global_position.y = 0.0

#Para los enemigos que entran MIENTRAS el escudo ya existe
func _on_body_entered_continuo(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		_eliminar_enemigo(body)

#para los enemigos que ya estaban adentro justo cuando se genera el escudo
func _chequeo_inicial_rapido() -> void:
	#dos frames de físicas
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var enemigos = areaDeteccion.get_overlapping_bodies()
	for enemigo in enemigos:
		if enemigo.is_in_group("enemy"):
			_eliminar_enemigo(enemigo)

func _eliminar_enemigo(enemigo: Node3D) -> void:
	print("enemigo que no pasa el escudo: ", enemigo.name)
	#if enemigo.has_method("morir"):
		#enemigo.morir()
	#else:
		#enemigo.queue_free()
		#enemigo.queue_free()

func destruir():
	queue_free()
