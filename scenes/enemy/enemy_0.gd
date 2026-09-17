extends CharacterBody3D
class_name EnemigoBase

@export var health := 100
# @export var animation_player: AnimationPlayer

@onready var crystal_timer: Timer = $Timer

# IA
var puede_moverse = false

# Cruz
var ver_cruz = true
@onready var cruz: MeshInstance3D = $cruz

# Modelo
var ver_modelo = false
@onready var modelo= $modelo
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
var animation_player : AnimationPlayer
#@export var enemigos: Array[PackedScene] = [
#preload("uid://cqy6sq80q31lu"),
#preload("uid://cgn8qa26kgyil"),
#preload("uid://lpniycrdwhlo"),
#preload("uid://drhx2vi2udeec"),
#]
@export var tipo: int # tipo d enemigo

var is_hurt := false
var is_dying := false

func _ready():
	#animation_player.playback_default_blend_time = 0.2
	cargar_modelo()
	add_to_group('enemy')
	look_at(goal_position)

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

func take_damage(damage: int, source: int):
	var next_health = health - damage
	
	var player_to_notify: Jugador
	for current_player in get_tree().get_nodes_in_group('Players'):
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
	Global.update_score_for(source)
	set_collision_layer_value(1, false)
	is_dying = true
	#animation_player.play("Death01")
	#await animation_player.animation_finished
	queue_free()


var SPEED := 0.5
var direction := Vector3.ZERO
var goal_position := Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	if is_dying or is_hurt:
		return

	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta 
		#print (position)
		if position.y < -2:
			#print ("cayo")
			queue_free()
		move_and_slide()	
		return
	elif is_on_floor() and ver_cruz: #Mostrar cruz
		mostrar_cruz()
		
	if not puede_moverse:
		return
	
	if position.distance_to(goal_position) > 3.0: 
		direction = position.direction_to(goal_position)
		#animation_player.play("andar")
	else:
		direction = Vector3.ZERO
		#animation_player.play("Spell_Simple_Shoot")
		if crystal_timer.is_stopped():
			crystal_timer.start()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


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
