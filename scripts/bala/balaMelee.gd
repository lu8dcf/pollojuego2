extends Node3D

var tipoComportamiento = comportamientoArma
@onready var tiempoDeVida = $tiempoVida
var posicionInicio

# común y explosiva
var avanza = false
var direccion
var inicio = false

# solo melee
@onready var areaMelee = $area_melee

var ya_eliminada: bool = false

func iniciar(comp: comportamientoArma, posicion_inicial: Vector3, direccion_inicial: Vector3) -> void:
	if comp == null:
		return

	global_position = posicion_inicial
	posicionInicio = posicion_inicial
	tipoComportamiento = comp
	direccion = direccion_inicial.normalized()
	inicio = true


func _ready() -> void:
	add_to_group("bala")
	top_level = true
	# Iniciar lógica melee una sola vez
   # if tipoComportamiento == comportamientoArma.MELEE: # ajustá según tu enum/const
	activar_melee()


func _process(_delta: float) -> void:
	if inicio:
		inicio = false
		tiempoDeVida.start()
		# Si querés que melee se active una sola vez, no lo llames acá


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
	# lógica de movimiento si la hubiera


func activar_melee() -> void:
	if ya_eliminada:
		return

	areaMelee.visible = true
	await get_tree().create_timer(0.2).timeout

	if ya_eliminada or not is_inside_tree():
		return

	var cuerpos_en_area = areaMelee.get_overlapping_bodies()
	for cuerpo in cuerpos_en_area:
		if cuerpo.is_in_group("enemy"):
			# Acá podés aplicar daño, etc.
			pass

	eliminarBala()


func eliminarBala() -> void:
	if ya_eliminada:
		return
	ya_eliminada = true

	if not multiplayer.is_server():
		return

	queue_free()


func _on_tiempo_vida_timeout() -> void:
	eliminarBala()


func _on_area_melee_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return

	# Si ya la estás eliminando, no hagas nada
	if ya_eliminada:
		return

	# Opcional: si querés que el primer contacto mate la bala inmediatamente
	eliminarBala()
