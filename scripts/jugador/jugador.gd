extends CharacterBody3D

class_name Jugador
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var sensitivity: float = 0.002

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var camera_3d: Camera3D = $camaraRig/OffsetRig/Camera3D
#@onready var head: Node3D = %Head
@onready var nameplate: Label3D = %Nameplate

#@onready var sound_hit: AudioStreamPlayer = %SoundHit
#@onready var sound_ping: AudioStreamPlayer = %SoundPing
@onready var player_ui: PlayerUI = %Player_UI


#SELECCION DE POLLO
#var personajePollo = preload("res://scenes/pollos/pollo_modelo_1.tscn")
@onready
var nodoJugador = $jugador

#obtengo mouse para seguirlo
var mousePosicion : Vector2

#maquina de estados
enum Estado {
	OLEADA, #estado generico, dutante la oleada
	CAIDO, #incapacitado, solo peude disparar pero no moverse
	MUERTE, #paso el tiempo de caido y muere
	TIENDA, #no puede moverse ni atacar.
	DASH
}
@export var estadoActual : Estado

#salud jugador
var salud = 100

#temporizador de vida en estado CAIDO
@onready var timer_caido: Timer = $timer_caido
#tiempo que se debe presionar la tecla para salvar
@onready var timer_salvar: Timer = $timer_salvar


# Jugador que actualmente esta dentro de nuestra zona de ayuda.
var objetivo_actual: Node = null



#-----------------------------------------------------------------HABILIDADES

#habilidad especial
#@onready var habilidad: Habilidad = $habilidad
#-----------------------------------------------DASH
const DASH_SPEED := 20.0
const DASH_DURATION := 0.25
const DASH_COLDOWN :=3

var direccion_dash := Vector3.ZERO
var tiempo_dash := 0.0





#@onready var animation_library_godot_standard: Node3D = %AnimationLibrary_Godot_Standard
#@export var animation_player: AnimationPlayer 
#@export var player_mesh: MeshInstance3D

#@onready var arms_root: Node3D = %ArmsRoot
#@export var weapon_animation_player: AnimationPlayer 
#@export var hurt_box: HurtBox
#@export var arm_mesh_right: MeshInstance3D
#@export var arm_mesh_left: MeshInstance3D



func _enter_tree() -> void:
	set_multiplayer_authority(int(name)) #lo mete en el arbol

func _ready():
	#add_child(personajePollo.instantiate())
	add_to_group("Jugadores")
	nameplate.text = name
#	animation_player.playback_default_blend_time = 0.2
#	arms_root.hide()
	#replicate_color_changed(player_ui.COLORS[0])
	player_ui.hide()

	if not is_multiplayer_authority(): #
		set_process(false)
		set_physics_process(false)
		return
	
	ready_client_visuals() 

func ready_client_visuals():
	player_ui.show()
	#arms_root.show()
	#weapon_animation_player.playback_default_blend_time = 0.2
	#weapon_animation_player.speed_scale = 0.7
	
	#player_ui.option_button_color.item_selected.connect(on_color_changed)
	#animation_library_godot_standard.hide()
	if GlobalJuego.nombre_jugador: 
		nameplate.text =  GlobalJuego.nombre_jugador
	camera_3d.current = true
	
	#------------------------------------------------------------------------------INPUTS

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	#si estoy en un estado que no peude interactuar
	if not puede_interactuar():
		return
		
# Cuando se PRESIONA E.
	if event.is_action_pressed("attack2"):
		if estadoActual == Estado.CAIDO:
			return
		if objetivo_actual == null:
			return
		empezar_salvar()
	#if event is InputEventMouseMotion: #esto hace que no puedo mover mas o menos de los 90 grados
		#$nodo_jugador.rotate_y(-event.relative.x * sensitivity)	
		#camera_3d.rotate_x(-event.relative.y * sensitivity)
		#camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('menu'):
		estadoActual = Estado.TIENDA
		open_menu(player_ui.menu.visible)
		
	if Input.is_action_just_pressed("test_caido"):
		estadoActual = Estado.CAIDO
		pedir_ayuda()

	if puede_disparar():
		shoot()	

	if Input.is_action_just_pressed("attack1"): # Mouse Izq
		attack(1) 
		
	#if Input.is_key_pressed(KEY_SHIFT):# ESTO DEBE SER ACCION PARA EL JOYSTICK VIRTUAL
		#if habilidad:
			#habilidad.usar()
	

func open_menu(current_visibility: bool):
	player_ui.menu.visible = !current_visibility
	player_ui.controls_root.visible = current_visibility
	

	if player_ui.menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#else:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		
		
#--------------------------------------------------------------------------------ESTADOS
		
func puede_moverse() -> bool:
	return estadoActual == Estado.OLEADA

func puede_atacar() -> bool:
	return estadoActual == Estado.OLEADA

func puede_disparar() -> bool:
	return estadoActual in [Estado.OLEADA, Estado.CAIDO]

func puede_usar_habilidad() -> bool:
	return estadoActual == Estado.OLEADA

func puede_interactuar() -> bool:
	return estadoActual == Estado.OLEADA

func esta_vivo() -> bool:
	return estadoActual != Estado.MUERTE


func entrar_caido():
	estadoActual = Estado.CAIDO
	timer_caido.start()
	
func entrar_muerte():
	estadoActual = Estado.MUERTE
	timer_caido.stop()
	salud = 0
	velocity = Vector3.ZERO

func entrar_oleada() -> void:
	estadoActual = Estado.OLEADA
	timer_caido.stop()

func entrar_tienda():
	estadoActual = Estado.TIENDA
	velocity = Vector3.ZERO
	
func cambiar_estado(nuevo_estado: Estado) -> void:
	if estadoActual == nuevo_estado:
		return
	match nuevo_estado:
		Estado.CAIDO:
			entrar_caido()
		Estado.MUERTE:
			entrar_muerte()
		Estado.OLEADA:
			entrar_oleada()
		Estado.TIENDA:
			entrar_tienda()

	estadoActual = nuevo_estado
	
func _on_timer_caido_timeout() -> void:
	cambiar_estado(Estado.MUERTE)
	pass # Replace with function body.
#----------------------------------------------------------------HABILIDADES

#-------------------------------------------------DASH

#func empezar_dash(direccion: Vector3) -> void:
	#if estadoActual != Estado.OLEADA:
		#return
	#if direccion.length_squared() < 0.001:
		#return
	#direccion_dash = direccion.normalized()
	#tiempo_dash = DASH_DURATION
	#cambiar_estado(Estado.DASH)
#
#func procesar_dash(delta: float) -> void:
	#tiempo_dash -= delta
	#velocity = direccion_dash * DASH_SPEED
	#move_and_slide()
	#if tiempo_dash <= 0.0:
		#terminar_dash()
#
#func terminar_dash() -> void:
	#velocity = Vector3.ZERO
	#direccion_dash = Vector3.ZERO
	#cambiar_estado(Estado.OLEADA)

# --------------------------------------------------------------SISTEMA DE SALVAR
func procesar_salvar() -> void:
	# Si no estamos intentando salvar,
	# no hacemos nada.
	if timer_salvar.is_stopped():
		return
	# comprobar que se sigue presionando E
	if not Input.is_action_pressed("attack2"):
		cancelar_salvar()
		return
	# Comprobar que el objetivo sigue existiendo
	if objetivo_actual == null:
		cancelar_salvar()
		return
	# Comprobar que seguimos en condiciones de salvar
	if estadoActual != Estado.OLEADA:
		cancelar_salvar()
		return


# EMPEZAR A SALVAR
func empezar_salvar() -> void:
	if estadoActual != Estado.OLEADA:
		return
	if objetivo_actual == null:
		return
	# Evitamos reiniciar el timer si ya estaba contando.
	if not timer_salvar.is_stopped():
		return
	timer_salvar.start()

# CANCELAR SALVAR
func cancelar_salvar() -> void:
	if timer_salvar.is_stopped():
		return
	timer_salvar.stop()


# COMPLETAR SALVAR
func _on_timer_salvar_timeout() -> void:
	if objetivo_actual == null:
		return
	if estadoActual != Estado.OLEADA:
		return
	# Seguridad adicional:
	# verificamos que EL BOTON DERECHP siga presionada.
	if not Input.is_action_pressed("attack2"):
		return
	var objetivo_id := int(objetivo_actual.name)
	pedir_salvar(objetivo_id)
#
#
#func procesar_habilidad() -> void:
	#if not puede_usar_habilidad():
		#return
	#if Input.is_action_just_pressed("habilidad"):
		#print("usoHabilidad")
		##habilidad.usar()

func _physics_process(delta: float) -> void:
	match estadoActual:
		#Estado.OLEADA:
			#procesar_movimiento(delta)
		#Estado.DASH:
			#procesar_dash(delta)
		Estado.CAIDO:
			velocity = Vector3.ZERO
		Estado.MUERTE:
			velocity = Vector3.ZERO
		Estado.TIENDA:
			velocity = Vector3.ZERO

	# Si llegamos aca estamos en OLEADA
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


	#sigo con la mirada al mouse
	mirar_al_mouse(delta)
	
	move_and_slide()
	#handle_animations(direction)

#var one_shots: Array[String] = ["Sword_Attack"]

func mirar_al_mouse(delta: float) -> void:

	var camara = get_viewport().get_camera_3d()
	if not camara:
		return

	var mouse_pos = get_viewport().get_mouse_position() #pos del mouse ne la pantalla

	#hago un raycast para obtener la pos en el mundo 3d
	var origen = camara.project_ray_origin(mouse_pos)
	var direccion_rayo = camara.project_ray_normal(mouse_pos)

	# Plano horizontal del jugador
	var plano = Plane(Vector3.UP, global_position.y)

	# interseccion del rayo con el plano
	var punto_mouse = plano.intersects_ray(
		origen,
		direccion_rayo
	)

	if punto_mouse == null:
		return

	# direccion desde el jugador hacia el mouse
	var direccion = -(punto_mouse - global_position) #MUCHO MUY IMPORTANTE ESE MENOOOS

	# sin contar la altura
	direccion.y = 0

	if direccion.length_squared() < 0.001:
		return

	# rotacion
	var rotacion_objetivo = atan2(
		direccion.x,
		direccion.z
	)

	# roto el nodo pollo, no todo
	nodoJugador.rotation.y = lerp_angle(
		nodoJugador.rotation.y,
		rotacion_objetivo,
		delta * 10.0
	)


#func handle_animations(direction: Vector3):
#	if animation_player.current_animation in one_shots:
#		return

	#if velocity.y == 0.0:
		#if direction.x != 0.0 or direction.y != 0.0:
			#animation_player.play("Jog_Fwd")
		#else: 
			#animation_player.play("Idle")
	#else:
		#animation_player.play("Jump")

	
func shoot():
	var force = 100
	var pos = global_position
	#var shoot_dir = get_shoot_direction()
	#Global.shoot_ball.rpc_id(1, pos, shoot_dir, force)
	#
#func get_shoot_direction():
	#var viewport_rect = get_viewport().get_visible_rect().size
	#var raycast_start = camera_3d.project_ray_origin(viewport_rect / 2)
	#var raycast_end = raycast_start + camera_3d.project_ray_normal(viewport_rect / 2) * 200
	#return -(raycast_start - raycast_end).normalized()

@rpc("any_peer", 'call_local')
func register_hit(is_dead = false):
	#if is_dead:
		#sound_hit.play()
		#sound_ping.play()
	#else:
		#sound_hit.play()
	
	player_ui.hit_marker.show()
	await get_tree().create_timer(0.2).timeout
	player_ui.hit_marker.hide()
	
#func on_color_changed(new_item: int):
	#replicate_color_changed.rpc(player_ui.COLORS[new_item])	

#@rpc("authority", "call_local")
#func replicate_color_changed(new_color: Color):
	#var material: StandardMaterial3D = player_mesh.get_active_material(0)
	#var new_material = material.duplicate()
	#new_material.albedo_color = new_color
	#player_mesh.set_surface_override_material(0, new_material)
	#arm_mesh_left.set_surface_override_material(0, new_material)
	#arm_mesh_right.set_surface_override_material(0, new_material)

func attack(version: int):
	#print ("Ataque")
	Sonidos.sonidoPollo()
	#if weapon_animation_player.current_animation.begins_with("arm_model_animations/swing"):
		#return
	
	#if version == 1:
		#hurt_box.current_damage = 25
	#elif version == 2:
		#hurt_box.current_damage = 50
	#hurt_box.bodies_hit.clear()
	#
	#animation_player.stop()
	#animation_player.play("Sword_Attack")
	#weapon_animation_player.play("arm_model_animations/swing_0" + str(version))
	#await weapon_animation_player.animation_finished
	#weapon_animation_player.play("arm_model_animations/idle")
	
#cuando un jugador esta cerca, si se aprieta la E, manda la peticion de salvarlo
#func _on_deteccion_ayuda_area_entered(area: Area3D) -> void: 
	#if(estadoActual != estados.CAIDO) and (Input.is_action_just_pressed("attack2")):
		#var jugador_objetivo = area.get_parent()
		#var objetivo_id = int(jugador_objetivo.name)
		#print("id es: ",objetivo_id)
		#pedir_salvar(objetivo_id)

	
	#-----------------------------------------SERVIDOR
	
	
		

#-------------------------SERVIDOR----------------------

@rpc("any_peer")
func pedir_ayuda():
	print("Ayuda!")


func pedir_salvar(objetivo_id: int) -> void:
	Network.pedir_salvar_rpc.rpc_id(1, objetivo_id)
	
	objetivo_actual = null

func _on_deteccion_ayuda_area_entered(area: Area3D) -> void: 
	# Guardamos al jugador afectado solo si no estamos caídos
	if estadoActual != Estado.CAIDO: 
		objetivo_actual = area.get_parent()

func _on_deteccion_ayuda_area_exited(area: Area3D) -> void:
	# Si el jugador se aleja del área, limpiamos la referencia
	if objetivo_actual == area.get_parent():
		objetivo_actual = null
