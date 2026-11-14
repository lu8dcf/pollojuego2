extends Node3D

var danioBala: float = 0.0
var es_fantasma: bool = false
@onready var areaMelee: Area3D = $area_melee
var ya_golpeo: bool = false

func _ready() -> void:
	top_level = true
	add_to_group("bala")

# Ahora recibe 3 parámetros: posición, daño y si es solo visual local
func iniciar(posicion_inicial: Vector3, danio: float, visual_local: bool = false) -> void:
	global_position = posicion_inicial
	danioBala = danio
	es_fantasma = visual_local

	ejecutar_golpe()

func ejecutar_golpe() -> void:
	if ya_golpeo:
		return
	ya_golpeo = true

	areaMelee.visible = true
	areaMelee.monitoring = true

	await get_tree().physics_frame
	await get_tree().physics_frame

	# LA REGLA DE ORO: Solo el servidor (o si juegas solo offline) aplica daño real. 
	# Si es un fantasma visual del cliente, NO hace daño para evitar duplicarlo.
	var es_servidor = not multiplayer.has_multiplayer_peer() or multiplayer.is_server()

	if es_servidor and not es_fantasma:
		var cuerpos = areaMelee.get_overlapping_bodies()
		for cuerpo in cuerpos:
			if cuerpo.is_in_group("enemy") and cuerpo.has_method("recibir_dano"):
				if is_instance_valid(cuerpo) and cuerpo.is_inside_tree():
					cuerpo.recibir_dano(danioBala)

	await get_tree().create_timer(0.15).timeout
	queue_free()
