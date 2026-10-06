extends CharacterBody3D

class_name Jugador

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@export var sensitivity: float = 0.002

const SPEED := 5.0
const JUMP_VELOCITY := 4.5

var velocidad
var resistencia


var joystick: Joystick = null

@onready var camera_3d: Camera3D = $camaraRig/OffsetRig/Camera3D
@onready var nameplate: Label3D = %Nameplate
@onready var player_ui: PlayerUI = %Player_UI
#@onready var nodoJugador: Node3D = $jugador

@onready var timer_caido: Timer = $timer_caido
@onready var timer_salvar: Timer = $timer_salvar

var pollo

enum Estado {
OLEADA,
CAIDO,
MUERTE,
TIENDA,
DASH,
AYUDANDO
}

@export var estadoActual: Estado = Estado.OLEADA

var ultimoEstado : Estado = Estado.OLEADA
var salud := 100
var salud_maxima = 100
var objetivo_actual: Node = null

#DASH
const DASH_SPEED := 80.0
const DASH_DURATION := 0.25
var direccion_dash := Vector3.ZERO
var tiempo_dash := 0.0

#------------------------------------------------------------METODOS

func _enter_tree() -> void:
	if GlobalJuego.un_jugador:
		set_multiplayer_authority(1)
		return
	else:
		var id = int(name)
		if id <= 0:
			id = 1
		set_multiplayer_authority(id)


#@rpc("authority", "call_local", "reliable")
#func crear_pollo_en_red(tipo_elegido: int) -> void:
	#var tipo_pollo_enum = tipo_elegido as PolloFactory.TipoPollo
	#
	##como es funcion static, puedo acceder a los datos que necesito
	#var datos_pollo = PolloFactory.obtener_datos(tipo_pollo_enum) 
	#
	##me copio los datos que me interesa
	#if not datos_pollo.is_empty():
		#self.salud_maxima = datos_pollo.get("salud_maxima")
		#self.salud = self.salud_maxima
		#self.velocidad = datos_pollo.get("velocidad")
		#self.resistencia = datos_pollo.get("resistencia")
	#
	##saco nodos viejos
	#for child in get_children():
		#if child is Pollo:
			#child.queue_free()
#
	##instancio el nodo pollo (visual y habilidad)
	#pollo = PolloFactory.crear(tipo_pollo_enum, self)
	#
	## le asigno la autoridad
	#add_child(pollo)
	#pollo.set_multiplayer_authority(get_multiplayer_authority(), true)
	#add_to_group("Jugadores")

func _ready() -> void:
	pollo = $FabricaPollos.crear($FabricaPollos.TipoPollo.BLANCO, self) #si queres poner otras habilidades: LENTES = dron, MARRON = escudo, BLANCO = dash
	add_child(pollo) #eSTO debe recibir ya un nodo pollo elegido
	pollo.set_multiplayer_authority(get_multiplayer_authority(), true) #para que el pollo tenga el mismo nivel de auoridad que el padre
	add_to_group("Jugadores")
	nameplate.text = name
	player_ui.hide()
	GlobalSignal.enviar_joystick.connect(recibir_joystick) # para obtener el joystick
	if GlobalJuego.un_jugador:
		# MODO UN JUGADOR
		await get_tree().process_frame
		if camera_3d:
			camera_3d.current = true
		ready_client_visuals()
		return
	
	# MODO MULTIJUGADOR
	if !GlobalJuego.un_jugador:
		if not is_multiplayer_authority():
			if camera_3d:
				camera_3d.current = false
			player_ui.hide()
			set_process(false)
			set_physics_process(false)
			return
		await get_tree().process_frame
		if camera_3d:
			camera_3d.current = true
		ready_client_visuals()

	#GlobalSignal.enviar_joystick.connect(recibir_joystick) #comprobar esto
	#if not is_multiplayer_authority():
	#	if camera_3d:
	#		camera_3d.current = false
	#	player_ui.hide()
	#	set_process(false)
	#	return

	#await get_tree().process_frame
	#if camera_3d:
	#	camera_3d.current = true
	#ready_client_visuals() #hasta aca



func recibir_joystick(j: Joystick) -> void:
	joystick = j
	
func ready_client_visuals() -> void:
	player_ui.show()
	if GlobalJuego.nombre_jugador:
		nameplate.text = GlobalJuego.nombre_jugador

	camera_3d.current = true

#-------------------------------------------------------------------------INPUT
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if not puede_interactuar():
		return

	if event.is_action_pressed("attack2"): #click derecho (o izq?)
		if estadoActual == Estado.CAIDO:
			return
		if objetivo_actual == null:
			return
		empezar_salvar()


func _process(_delta: float) -> void:
	
	if not is_multiplayer_authority():
		return
		
	if Input.is_action_just_pressed("habilidad"): # K
		if puede_usar_habilidad():
			pollo.usar_habilidad()

	if Input.is_action_just_pressed("menu"):
		estadoActual = Estado.TIENDA
		open_menu(player_ui.menu.visible)
		
	if Input.is_action_just_pressed("test_caido"): # M
		cambiar_estado(Estado.CAIDO) #aca
		pedir_ayuda()

	if Input.is_action_just_pressed("crearArma"): # L
		GlobalSignal.emit_signal("equiparArma", 3)
#-------------------------------------------------------------------------MENU
func open_menu(current_visibility: bool) -> void:
	player_ui.menu.visible = !current_visibility
	player_ui.controls_root.visible = current_visibility
	if player_ui.menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


#------------------------------------------------------------------ESTADOS - CONSULTAS

func puede_moverse() -> bool:
	return estadoActual == Estado.OLEADA

func puede_disparar() -> bool:
	return estadoActual in [Estado.OLEADA,Estado.CAIDO]

func puede_usar_habilidad() -> bool:
	return estadoActual in [Estado.OLEADA,Estado.DASH]

func puede_interactuar() -> bool:
	return estadoActual == Estado.OLEADA
	
func puede_recibir_danio():
	return estadoActual == Estado.OLEADA

func puede_cambiar_arma():
	return estadoActual == Estado.OLEADA
func esta_vivo() -> bool:
	return estadoActual != Estado.MUERTE

#---------------------------------------------------------------ENTRAR ESTADOS

func entrar_caido() -> void:
	estado_caido_rpc.rpc() #al servidor!


func entrar_muerte() -> void:
	timer_caido.stop()
	print("personaje muerto")
	salud = 0
	velocity = Vector3.ZERO


func entrar_oleada() -> void:
	timer_caido.stop()

func entrar_tienda() -> void:
	velocity = Vector3.ZERO

func entrar_dash() -> void:
	pass
func entrar_ayudando():
	pass


#------------------------------------------------------------------------CAMBIAR ESTADO
func cambiar_estado(nuevo_estado: Estado) -> void:
	#if(not is_multiplayer_authority()):
		#return
	if estadoActual == nuevo_estado:
		return
	ultimoEstado = estadoActual
	estadoActual = nuevo_estado
	match nuevo_estado:
		Estado.CAIDO:
			entrar_caido()
		Estado.MUERTE:
			entrar_muerte()
		Estado.OLEADA:
			entrar_oleada()
		Estado.TIENDA:
			entrar_tienda()
		Estado.DASH:
			entrar_dash()
		Estado.AYUDANDO:
			entrar_ayudando()



#-----------------------------------------------------------------------------DASH

func iniciar_dash() -> void:
	direccion_dash = pollo.global_transform.basis.z
	direccion_dash = direccion_dash.normalized()
	tiempo_dash = DASH_DURATION
	cambiar_estado(Estado.DASH)

func procesar_dash(delta: float) -> void:
	tiempo_dash -= delta
	velocity = direccion_dash * DASH_SPEED
	move_and_slide()
	if tiempo_dash <= 0.0:
		terminar_dash()


func terminar_dash() -> void:
	velocity = Vector3.ZERO
	direccion_dash = Vector3.ZERO
	cambiar_estado(Estado.OLEADA)

#--------------------------------------------------------------------PHYSICS PROCESSS
#func _physics_process(delta: float) -> void:
func _physics_process(delta: float) -> void:

	#if is_multiplayer_authority() or multiplayer.is_server():
	#if not is_multiplayer_authority() and not multiplayer.is_server(): 
		#return 
	
	if not is_multiplayer_authority():
		return
	match estadoActual:
		Estado.OLEADA:
			#if(not multiplayer.is_server()):
				#print(">>> ENTRA OLEADA")
			procesar_movimiento(delta)

		Estado.DASH:
			#if(not multiplayer.is_server()):
				#print(">>> ENTRA DASH")
			procesar_dash(delta)

		Estado.CAIDO:
			#if(not multiplayer.is_server()):
				#print(">>> ENTRA CAIDO")
			procesar_caido()

		Estado.MUERTE:
			#if(not multiplayer.is_server()):
				#print(">>> ENTRA MUERTE")
			procesar_muerte()

		Estado.TIENDA:
			#if(not multiplayer.is_server()):
				#print(">>> ENTRA TIENDA")
			procesar_tienda()
			
		Estado.AYUDANDO:
			procesar_ayudando()
			procesar_salvar()

#----------------------------------------------------------------------MOVIMIENTO NORMAL

func procesar_movimiento(delta: float) -> void:
	# GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta
	# INPUT
	var direction := Vector3.ZERO
	# Joystick
	if (joystick != null and is_instance_valid(joystick) and joystick.direccion != Vector2.ZERO):
		direction = (transform.basis *Vector3(joystick.direccion.x,0,joystick.direccion.y)).normalized()

	# Teclado
	else:
		var input_dir := Input.get_vector("left","right","forward","backward")
		direction = (transform.basis *Vector3(input_dir.x,0,input_dir.y)).normalized()

	# VELOCIDAD
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if is_multiplayer_authority():
			pollo.mirar_hacia(direction, delta) #ROTACION POLLO
	else:
		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)

	move_and_slide()

#------------------------------------------------------------------------PROCESAR

func procesar_caido() -> void:
	velocity = Vector3.ZERO
	
func procesar_muerte() -> void:
	velocity = Vector3.ZERO

func procesar_tienda() -> void:
	velocity = Vector3.ZERO
	
func procesar_ayudando() -> void:
	velocity = Vector3.ZERO
#---------------------------------------------------------------#SISTEMA DE SALVAR

func procesar_salvar() -> void:
	if timer_salvar.is_stopped(): #si no se hizo durante el tiempo definidp
		cancelar_salvar()
		return
	if not Input.is_action_pressed("attack2"): #mouse derecho
		cancelar_salvar()
		return
	if objetivo_actual == null: #
		cancelar_salvar()
		return
	if estadoActual != Estado.AYUDANDO:#
		cancelar_salvar()


func empezar_salvar() -> void:
	if estadoActual == Estado.OLEADA:
		cambiar_estado(Estado.AYUDANDO)
	else:
		return
	if objetivo_actual == null:
		return
	if not timer_salvar.is_stopped():
		return
	timer_salvar.start()


func cancelar_salvar() -> void:
	if timer_salvar.is_stopped():
		return
	timer_salvar.stop()
	cambiar_estado(Estado.OLEADA)

func _on_timer_salvar_timeout() -> void:
	if objetivo_actual == null:
		return
	if estadoActual != Estado.AYUDANDO:
		return
	if not Input.is_action_pressed("attack2"):
		return
	var objetivo_id := int(objetivo_actual.name)
	pedir_salvar(objetivo_id)
	cambiar_estado(Estado.OLEADA)
#--------------------------------------------------------------------------DANIO

func recibir_dano(dano: int):
	if not multiplayer.is_server():
		return
	if( puede_recibir_danio()):
		var vida_actual = salud - dano
		#flash_rojo.rpc(get_multiplayer_authority())  # aviso a todos que brille
		if vida_actual <= 0:
				cambiar_estado(Estado.CAIDO)
		salud = vida_actual
		sincronizar_salud_y_efecto.rpc(salud)

@rpc("any_peer", "call_local", "reliable")		
func sincronizar_salud_y_efecto(nueva_salud: int):
	#actualizo vida salud
	salud = nueva_salud
	
	#flash rojo
	if has_node("pollo"): 
		pollo.flash_rojo()
		
	#paso el porcentaje a l abarra para que baje
	var porcentaje = float(nueva_salud) / salud_maxima
	$barraVida.bajarVida(porcentaje)
	
	# Esto es para que se vea SOLO la barra propia
	if is_multiplayer_authority():
		$barraVida.visible = true
	else:
		$barraVida.visible = false

#------------------------------------------------------------------------SERVIDOR

@rpc("any_peer")
func pedir_ayuda() -> void:
	print("Ayuda!")


func pedir_salvar(objetivo_id: int) -> void:
	if multiplayer.is_server():
		Network.procesar_salvar(multiplayer.get_unique_id(), objetivo_id) #si es el server esto
	else:
		Network.pedir_salvar_rpc.rpc_id(1, objetivo_id) #si es cliente, esto
	objetivo_actual = null

#------------------------------------------------------------DETECCION DE AYUDA

func _on_deteccion_ayuda_area_entered(area: Area3D) -> void:
	if estadoActual != Estado.CAIDO:
		objetivo_actual = area.get_parent()


func _on_deteccion_ayuda_area_exited(area: Area3D) -> void:
	if objetivo_actual == area.get_parent():
		objetivo_actual = null
		
		
#------------------------------------------------------------------------TIMER CAIDO y morir
func _on_timer_caido_timeout() -> void:
	if not is_multiplayer_authority():
		return
	if estadoActual != Estado.CAIDO:
		return
	morir_rpc.rpc(int(name))

@rpc("any_peer", "call_local", "reliable")
func morir_rpc(jugador_id: int) -> void:
	var jugador := GlobalJuego._obtener_jugador(jugador_id)
	if jugador == null:
		return
	cambiar_estado(Estado.MUERTE)
	jugador.morir()

@rpc("any_peer", "call_local", "reliable")
func estado_caido_rpc() -> void:
	timer_caido.start()

func morir():
	print("jugador ha muerto!")
	#flash_claro.rpc()
	
	#muerto = true
	#animation_player.play("Death01")
	#await animation_player.animation_finished
	#animacion_muerte()
	# queue_free()
#-------------------------------------------------------------------SALVADOO
func polloSalvado():
	if( timer_caido):
		timer_caido.stop()
	if multiplayer.is_server() or is_multiplayer_authority():
		cambiar_estado(Estado.OLEADA)
	salud = salud_maxima
	$barraVida.reiniciar_barra()
