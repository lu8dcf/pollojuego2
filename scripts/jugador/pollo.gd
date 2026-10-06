class_name Pollo
extends Node3D

var jugador: Jugador

var habilidad: Habilidad
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var modelo : Node3D
@onready var geometry
#var meshes: Array[MeshInstance3D] = []

var material_original: Material
var material_rojo: StandardMaterial3D

func inicializar(p_jugador: Jugador,p_modelo: Node3D,p_habilidad: Habilidad) -> void:

	jugador = p_jugador
	modelo = p_modelo
	habilidad = p_habilidad

	add_child(modelo)
	add_child(habilidad)

	habilidad.iniciar(jugador)


func _ready():
	for nodo in find_children("*", "MeshInstance3D", true, false):
		var mesh := nodo as MeshInstance3D
		
		var material := mesh.get_active_material(0)
		
		if material is ShaderMaterial:
			mesh.material_override = material.duplicate()



func usar_habilidad() -> void:
	if habilidad == null:
		return
		
	if multiplayer.is_server():
		#host: ejecuto directamente
		habilidad.usar()
	else:
		# cliente: solicito al servidor
		solicitar_habilidad.rpc_id(1)

@rpc("any_peer", "reliable")
func solicitar_habilidad() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id() #obtengo a quien llamo la habilidad

	if habilidad == null:
		return

	# Ordeno al cliente que la ejecute
	ejecutar_habilidad.rpc_id(peer_id)


@rpc("any_peer", "reliable")
func ejecutar_habilidad() -> void:
	habilidad.usar()
var haciendo_flash: bool = false

func flash_rojo():
	# Si ya estaba parpadeando, evitamos sobreescribir los materiales originales
	if haciendo_flash:
		return
		
	var meshes = modelo.find_children("*", "MeshInstance3D", true, false)
	var materiales_originales = []
	haciendo_flash = true
	
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color.RED
	
	# 1. Guardamos el estado y aplicamos el rojo
	for mesh in meshes:
		materiales_originales.append(mesh.get_surface_override_material(0))
		mesh.set_surface_override_material(0, rojo)
	
	# 2. Esperamos los 0.2 segundos una sola vez
	await get_tree().create_timer(0.2).timeout
	
	# 3. Restauramos limpiando el override correctamente
	for i in range(meshes.size()):
		if is_instance_valid(meshes[i]):
			if materiales_originales[i] == null:
				# Forzamos a Godot a remover por completo el override material
				meshes[i].set_surface_override_material(0, null)
			else:
				meshes[i].set_surface_override_material(0, materiales_originales[i])
				
	haciendo_flash = false

	
func mirar_hacia(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var angulo := atan2(direction.x,direction.z) #este pi es para invertir la vuelta
	self.rotation.y = lerp_angle(self.rotation.y,angulo,delta * 10.0)

func reproducir_animacion(nombre: StringName) -> void:
	animation_player.play(nombre)
