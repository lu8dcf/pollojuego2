extends CharacterBody3D
class_name EnemigoBase

# Caracteristicas del bicho
@export var vida := 30  # vida del bicho
var dano = 10 # daño que hace al jugador

# IA
var puede_moverse = false

# Cruz
var ver_cruz = true
@onready var cruz: MeshInstance3D = $cruz
#Componentes
#var movimiento_especifico = preload("res://scenes/enemy/movimiento/movimiento.tscn")

# Modelo
var ver_modelo = false
@onready var modelo= $modelo
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
var animation_player : AnimationPlayer

@export var tipo: int = 1 # tipo d enemigo
@export var animacion_ataque=false

var is_dying := false
var jugador: Node3D = null

# datos de movimiento
@export var velocidad_base: float = 2.0
@export var velocidad_giro: float = 8.0
var velocidad: float = velocidad_base # velocidad actual
var direccion_actual: Vector3 = Vector3.FORWARD

# tipos de comportamientos
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
	INACTIVO,  # congelado
	WANDER,    # camina aleatoriamente
	PERSIGUE,  # persigue a un jugador
	FLEE       # escapa del jugador
	
}

# colisiiones
@onready var bigote: Area3D = $bigote

var posicionado = false  # cuando se encuentre correctamente en el piso sin tocar la pared
# seek persigue
@export var distancia_frenado: float =5.0     # A qué distancia empieza a frenar
@export var distancia_llegada: float = 1.5   # A qué distancia se detiene
@export var rot_byte = 0 # valor del angulo menos presiso para pasarlo por lan
@onready var marcapaso: Timer = $Marcapaso




# cambios de los colores
@export var geometry: MeshInstance3D
var shader_muerte: ShaderMaterial = null  #  ShaderMaterial
var material_original: Material
var material_rojo: StandardMaterial3D

# funciones para hacer daño
var hace_dano= false
var jugador_dano: Node3D = null

func _ready():
	
	# Areas de colision
	cargar_materiales()
	cargar_modelo()
	add_to_group('enemy')
	tipo_enemigo()
	cargar_pullups()
	#jugador = get_tree().get_first_node_in_group("Jugadores")
	# Esperar un frame para que el NavigationServer se inicialice
	await get_tree().physics_frame
	marcapaso.timeout.connect(cambios)
		
func cargar_materiales():
	material_rojo = StandardMaterial3D.new()
	material_rojo.albedo_color = Color.RED
	# Si querés que se “ilumine”, podés subir emissive:
	material_rojo.emission_enabled = true
	material_rojo.emission = Color.RED
	material_rojo.emission_energy_multiplier = 2.0 	

func cargar_pullups():
	pass

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

func tipo_enemigo():
	animation_player.play("caminar_bicho")
	match tipo:
		1:
			#Chaser (ninja) debe hacer Seek para perseguir al jugador cuando éste se acerca, o cuando Chaser se acerca al jugador mientras hace Wander. Si el jugador se aleja una cierta distancia, Chaser debe volver a hacer Wander. Además Chaser debe hacer Arrive cuando llega a la posición del jugador.
			estado_actual=estado.WANDER
			geometry = $modelo/enemigo_1/Babosa/Skeleton3D/Cubo_106
		2:
			#Coward (payaso) debe hacer Flee para huir del jugador cuando éste se acerca, o cuando Coward se acerca al jugador mientras hace Wander. Si el jugador (o Coward) se aleja una cierta distancia, Coward debe volver a hacer Wander
			estado_actual=estado.WANDER
			geometry = $modelo/enemigo_2/caracol/Skeleton3D/Cubo_105
		3:
			#Wanderer (mago) simplemente hace Wander sin verse afectado ni por el jugador, ni por los otros NPCs
			estado_actual=estado.WANDER
			geometry = $modelo/enemigo_3/acaro/Skeleton3D/Cubo_086
		4:
			#langosta (mago) simplemente hace Wander sin verse afectado ni por el jugador, ni por los otros NPCs
			estado_actual=estado.WANDER
			geometry = $modelo/enemigo_4/saltamontes/Skeleton3D/Cubo_104
	material_original = geometry.get_surface_override_material(0)
	# Acceder a los datos por número
	var datos = Enemigos.datos[tipo]

	# Asignar parámetros
	vida = datos["vida"]
	velocidad_base = datos["velocidad"]
	dano = datos["dano"]
	
	
	
func recibir_dano(danio):
	if not multiplayer.is_server():
		return
	var vida_actual = vida - danio
	flash_rojo.rpc()  # aviso a todos que brille
	if vida_actual <= 0:
			morir.rpc()
	else:
		vida = vida_actual
		
		
		
@rpc("authority", "call_local")		
func flash_rojo():
	geometry.material_override = material_rojo
	await get_tree().create_timer(0.2).timeout
	geometry.material_override = material_original

	

@rpc("authority", "call_local", "reliable")		
func morir():
	$CollisionShape3D.disabled = true  # elimino la collision
	var shader = preload("res://assets/modelos/shader/muerte.gdshader")
	shader_muerte = ShaderMaterial.new()
	shader_muerte.shader = shader
	geometry.set_surface_override_material(0, shader_muerte)
	geometry.material_override = shader_muerte
				
	var tween = create_tween()
	#tween.set_parallel(true)
	
	# Subir y rotar lentamente
	#tween.tween_property(self, "global_position:y", global_position.y + 10 ,3)
	#tween.tween_property(self, "rotation:y", rotation.y + 10, 2)  # Girar mientras sube
	tween.tween_property(self, "scale", Vector3(0.01,0.01,0.01), 1.5)
		
	await tween.finished
		
	queue_free()
	


func cambios():
	if animacion_ataque:
		animation_player.play("ataque_bicho")
	else:
		animation_player.play("caminar_bicho")
	
	if hace_dano:
		jugador_dano.recibir_dano(dano)
	

func _physics_process(delta: float) -> void:
	var rotacion_actual = modelo.rotation.y		
	# Cuando SE RECIBE el valor  el valor:
	
	var angulo_recibido = byte_a_angulo(rot_byte)

		#  interpolando localmente:
	modelo.rotation.y = lerp_angle(rotacion_actual, angulo_recibido, velocidad_giro * delta)
	
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	

	if is_dying: # si esta atacando no cambia el movimiento
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
			if not _jugador_valido():
				estado_actual = estado.WANDER
				jugador = null
				return
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
			if not _jugador_valido():
				estado_actual = estado.WANDER
				jugador = null
				return
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
	

func _jugador_valido() -> bool:
	return jugador != null and is_instance_valid(jugador)

# angulo_objetivo está en radianes, entre -PI y PI (o 0..2TAU, da igual)
func angulo_a_byte(angulo: float) -> int:
	# Normalizamos a [0, TAU)
	var tau = TAU
	var norm = fposmod(angulo, tau)
	# Mapa a [0, 255]
	return int(norm / tau * 255.0 + 0.5)
	
func byte_a_angulo(rot_byte2) -> float:
	if rot_byte2 == null:
		return 0.0  # o el valor por defecto que quieras
	
	var tau = TAU
	return (rot_byte2 / 255.0) * tau
	

func mostrar_cruz(): # titila la cruz 
	$CollisionShape3D.disabled = true  # no recibe daño
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
	$CollisionShape3D.disabled = false  # aca puede recibir daño
	
# player entra al area de vision
func _on_vision_body_entered(body: Node3D) -> void: 
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	jugador = body
	if body.is_in_group("Jugadores"):
		# Aplicar daño al enemigo
		if body.has_method("esta_vivo"):
			#body.recibir_dano(dano)
			if !body.esta_vivo():  # asugan el nodo que recibira daño
				return
	if tipo==1 and estado_actual==estado.WANDER:
		estado_actual=estado.PERSIGUE
	
	if tipo==2 and estado_actual==estado.WANDER:
		estado_actual=estado.FLEE	
	
	if tipo==3 and estado_actual==estado.WANDER:
		estado_actual=estado.PERSIGUE
	
	if tipo==4 and estado_actual==estado.WANDER:
		estado_actual=estado.PERSIGUE	


func _on_vision_body_exited(_body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	
	if _body == jugador:
		jugador = null
		
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

func _on_bigote_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	if !posicionado:
		queue_free()
	if body.is_in_group("Jugadores"):
		# Aplicar daño al enemigo
		if body.has_method("recibir_dano"):
			#body.recibir_dano(dano)
			jugador_dano = body  # asugan el nodo que recibira daño
			hace_dano = true
	else:		
		evadir_obstaculo=true
		evasion._activar_evasion()
	

func _on_bigote_body_exited(body: Node3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	
	if body.is_in_group("Jugadores"):
		# Aplicar daño al enemigo
		if body.has_method("recibir_dano"):
			hace_dano = false
	else:		
		evadir_obstaculo=false
		evasion._verificar_salida()



func _on_danio_area_entered(_area: Area3D) -> void:
	if not multiplayer.is_server(): # solo el servidor puede mover los enemigos
		return
	estado_actual = estado.INACTIVO
	puede_moverse = false
	jugador = null
	queue_free()
