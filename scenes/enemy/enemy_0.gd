extends CharacterBody3D
class_name EnemigoBase

@export var health := 100
# @export var animation_player: AnimationPlayer

#@onready var crystal_timer: Timer = $Timer

# IA
var puede_moverse = false

# Cruz
var ver_cruz = true
@onready var cruz: MeshInstance3D = $cruz
#Componentes
var movimiento_especifico = preload("res://scenes/enemy/movimiento/movimiento.tscn")

# Modelo
var ver_modelo = false
@onready var modelo= $modelo
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
var animation_player : AnimationPlayer

@export var tipo: int = 1 # tipo d enemigo
@export var animacion_ataque=false
var is_hurt := false
var is_dying := false
var jugador: Node3D = null

# datos de movimiento
@export var velocidad_base: float = 1
@export var velocidad_giro: float = 8.0
var velocidad: float = velocidad_base # velocidad actual
var direccion_actual: Vector3 = Vector3.FORWARD
@onready var wander: Wander = $Wander
@onready var flee: Flee = $Flee
@onready var evasion= $Evasion
var evadir_obstaculo= false
var velocidad_deseada := Vector3.ZERO # velocidad de evasion


var velocidad_actual: Vector3 = Vector3.ZERO
var direccion: Vector3  = Vector3.ZERO

#  una variable para almacenar el estado actual
var estado_actual: estado = estado.INACTIVO
var estado_anterior: estado = estado.INACTIVO
# posibles estados
enum estado {
	INACTIVO,
	WANDER,
	PERSIGUE,
	FLEE
	
}

# colisiiones
@onready var bigote: Area3D = $bigote

var posicionado = false  # cuando se encuentre correctamente en el piso sin tocar la pared
# seek persigue
@export var distancia_frenado: float =5.0     # A qué distancia empieza a frenar
@export var distancia_llegada: float = 1.5   # A qué distancia se detiene
@export var rot_byte = 0
@onready var marcapaso: Timer = $Marcapaso

func _ready():
	# Areas de colision

	cargar_modelo()
	cargar_movimiento()
	add_to_group('enemy')
	tipo_enemigo()
	marcapaso.timeout.connect(cambios)
	#jugador = get_tree().get_first_node_in_group("Jugadores")
	# Esperar un frame para que el NavigationServer se inicialice
	await get_tree().physics_frame
	
	

	# CONFIGURAR MultiplayerSynchronizer correctamente
	
func cargar_modelo(): # tipo de enemigo
	
	var escena_glb = load("res://scenes/enemy/enemigo_"+ str(tipo)+".tscn")
	var instancia_glb = escena_glb.instantiate()
	
	#asignarle un pullups
	#instancia_objeto_pieza.id=id
		
	
	modelo.add_child(instancia_glb)
	# Buscar el AnimationPlayer dentro de esta instancia
	animation_player = _find_animation_player(instancia_glb)	
	
func _find_animation_player(node: Node) -> AnimationPlayer: # agrega las animaciones del mnodelo a la pieza
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found = _find_animation_player(child)
		if found:
			return found
	return null	

func cargar_movimiento():
	var movimiento = movimiento_especifico.instantiate()
	var movimiento_script = "res://scenes/enemy/movimiento/mov_"+str(tipo)+".gd"
	var script = load(movimiento_script)
	movimiento.set_script(script)
	add_child(movimiento)
	movimiento.owner = self  #  Establece el owner manualmente

func tipo_enemigo():
	animation_player.play("caminar_bicho")
	match tipo:
		1:
			#Chaser (ninja) debe hacer Seek para perseguir al jugador cuando éste se acerca, o cuando Chaser se acerca al jugador mientras hace Wander. Si el jugador se aleja una cierta distancia, Chaser debe volver a hacer Wander. Además Chaser debe hacer Arrive cuando llega a la posición del jugador.
			estado_actual=estado.WANDER
		2:
			#Coward (payaso) debe hacer Flee para huir del jugador cuando éste se acerca, o cuando Coward se acerca al jugador mientras hace Wander. Si el jugador (o Coward) se aleja una cierta distancia, Coward debe volver a hacer Wander
			estado_actual=estado.WANDER
		3:
			#Wanderer (mago) simplemente hace Wander sin verse afectado ni por el jugador, ni por los otros NPCs
			estado_actual=estado.WANDER
		4:
			pass

func take_damage(damage: int, source: int):
	var next_health = health - damage
	
	var player_to_notify: Jugador
	for current_player in get_tree().get_nodes_in_group('Jugadores'):
		if current_player.name == str(source):
			player_to_notify = current_player
			break
	
	if not player_to_notify:
		return
	
	if next_health <= 0:
		player_to_notify.register_hit.rpc_id(source, true)
		death(source)
	else:
		health = next_health
		player_to_notify.register_hit.rpc_id(source)
		is_hurt = true
		#animation_player.play("Hit_Chest")
		#await animation_player.animation_finished
		is_hurt = false

func death(source):
	#Global.update_score_for(source)
	set_collision_layer_value(1, false)
	is_dying = true
	#animation_player.play("Death01")
	#await animation_player.animation_finished
	queue_free()

func cambios():
	if animacion_ataque:
		animation_player.play("ataque_bicho")
	else:
		animation_player.play("caminar_bicho")
	
	

func _physics_process(delta: float) -> void:
	
	var rotacion_actual = modelo.rotation.y		
	# Cuando SE RECIBE el valor  el valor:
	var angulo_recibido = byte_a_angulo(rot_byte)

		#  interpolando localmente:
	modelo.rotation.y = lerp_angle(rotacion_actual, angulo_recibido, velocidad_giro * delta)
	
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	

	if is_dying or is_hurt: # si esta atacando no cambia el movimiento
		return

	# Add the gravity.
	
	if !posicionado:
		if not is_on_floor(): # detecta la llegada al piso
			velocity += get_gravity() * delta 
			if position.y < -2:
				queue_free()
			move_and_slide() # caer
			return
		elif is_on_floor() and ver_cruz: #Mostrar cruz
			mostrar_cruz()
			posicionado=true
		
		
	if not puede_moverse: # si esta vedado a moverse por cualquie cosa
		return
	
# ---------------  Estados del enemigo
	
	match estado_actual:
		estado.INACTIVO:
			direccion_actual= Vector3.ZERO
		
		estado.WANDER: # Mago
			if velocidad_actual.length() > 0.1:
				direccion_actual = Vector3(velocity.x, 0, velocity.z).normalized()
			velocidad = velocidad_base /2
			# Calcular la velocidad deseada con Wander
			velocidad_actual = wander.calcular_velocidad(
			global_position,
			direccion_actual,
			delta)
			
		
		estado.PERSIGUE: #seek
			var distancia = Vector2(
				jugador.global_position.x - global_position.x,
				jugador.global_position.z - global_position.z
			).length()
			

			# Si ya llegó, detenerse
			if distancia <= distancia_llegada:
				velocidad_actual.x = 0
				velocidad_actual.z = 0
				animacion_ataque= true
				
				
			else:
				# Calcular dirección al jugador (solo XZ)
				direccion = (jugador.global_position - global_position)
				direccion.y = 0
				direccion = direccion.normalized()
				animacion_ataque= false
				
			
				# Aplicar Arrive: velocidad proporcional a la distancia
				var factor_velocidad = 1.0
				if distancia < distancia_frenado:
					factor_velocidad = distancia / distancia_frenado
					factor_velocidad = clamp(factor_velocidad, 0.0, 1.0)
				
				var velocidad_final = velocidad_base * 2.0 * factor_velocidad
				
				velocidad_actual.x = direccion.x * velocidad_final
				velocidad_actual.z = direccion.z * velocidad_final

			
	
		estado.FLEE:
			# Si se aleja lo suficiente, volver a WANDER
			if flee.esta_a_salvo(global_position, jugador.global_position):
				estado_actual = estado.WANDER
				
				velocidad_actual = wander.calcular_velocidad(
					global_position, direccion_actual, delta
				)
			else:
				velocidad_actual = flee.calcular_velocidad(
					global_position, jugador.global_position, direccion_actual, delta
				)
			
		#estado.EVASION:
	if evadir_obstaculo:
		velocidad_actual = evasion.calcular_evasion(direccion_actual, delta)
	
	
	if velocidad_actual.length() > 0.1:
		# Dirección hacia donde se mueve
		direccion_actual = velocidad_actual.normalized()
		
		# Ángulo Y (en radianes) mirando hacia esa dirección
		var angulo_objetivo = atan2(direccion_actual.x, direccion_actual.z)
				
		# Interpolación angular suave (evita giros bruscos)
		angulo_objetivo = lerp_angle(rotacion_actual, angulo_objetivo, velocidad_giro * delta)
		# Ejemplo de uso antes de enviar por RPC / sincronizador:
		rot_byte = angulo_a_byte(angulo_objetivo)
			# envías rot_byte (un solo byte o un int pequeño)	
		
		
		
		
	# Aplicar velocidad al CharacterBody3D
	velocity.x = velocidad_actual.x
	velocity.z = velocidad_actual.z
	
	
	
	# Gravedad
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	

# angulo_objetivo está en radianes, entre -PI y PI (o 0..2TAU, da igual)
func angulo_a_byte(angulo: float) -> int:
	# Normalizamos a [0, TAU)
	var tau = TAU
	var norm = fposmod(angulo, tau)
	# Mapa a [0, 255]
	return int(norm / tau * 255.0 + 0.5)
	
func byte_a_angulo(rot_byte: int) -> float:
	var tau = TAU
	return (rot_byte / 255.0) * tau
	


func mostrar_cruz(): # titila la cruz 
	var tween = create_tween()
	ver_cruz = false # solo parpadela la primera vez
		#  ciclo de parpadeo 3 veces
	for i in range(3):
		tween.tween_property($cruz, "visible", true, 0.0)
		tween.tween_interval(0.3)
		tween.tween_property($cruz, "visible", false, 0.0)
		tween.tween_interval(0.3)
	
	#  inicial del nodo Modelo antes de aparecer
	tween.tween_callback(func():
		$modelo.visible = true
		$modelo.scale = Vector3.ZERO # Inicia invisible/pequeño
	)
	
	#  Aparición suave (Fade-in por escala en 0.5 segundos)
	tween.tween_property($modelo, "scale", Vector3.ONE, 0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	# finalizar la aparicion de puede mover
	tween.tween_callback(func():
			puede_moverse = true # permino que se empiece a movere
			set_collision_mask_value(4, true))  # Agrego las pareces de colision

# player entra al area de vision
func _on_vision_body_entered(body: Node3D) -> void: 
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	jugador = body
	if tipo==1 and estado_actual==estado.WANDER:
		estado_actual=estado.PERSIGUE
	
	if tipo==2 and estado_actual==estado.WANDER:
		estado_actual=estado.FLEE	
	


func _on_vision_body_exited(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	if tipo==1 and estado_actual==estado.PERSIGUE:
		estado_actual=estado.WANDER
		
		


func _on_bigote_area_entered(_area: Area3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	if !posicionado:
		queue_free()
	
	evadir_obstaculo=true
	evasion._activar_evasion()
		

func _on_bigote_area_exited(_area: Area3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	evadir_obstaculo=false
	evasion._verificar_salida()

func _on_bigote_body_entered(_body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	if !posicionado:
		queue_free()
	evadir_obstaculo=true
	evasion._activar_evasion()
	

func _on_bigote_body_exited(_body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	evadir_obstaculo=false
	evasion._verificar_salida()


func _on_danio_body_entered(_body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	
	queue_free()
