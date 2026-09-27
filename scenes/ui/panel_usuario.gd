extends PanelContainer

@onready var contenedor_personaje: Control = %ContenedorPersonaje
@onready var sprite_personaje: AnimatedSprite2D = %SpritePersonaje
@onready var aro: NinePatchRect = %Aro

var peer_id: int = 0
var salud_actual: int = GlobalJuego.SALUD_DEFAULT
var salud_maxima: int = GlobalJuego.SALUD_DEFAULT
var id_personaje: int = 1

const COLOR_BIEN := Color(0.2, 0.9, 0.2)      # verde
const COLOR_MEDIO := Color(0.95, 0.85, 0.1)   # amarillo
const COLOR_BAJO := Color(0.9, 0.15, 0.15)    # rojo

func _ready() -> void:
	pass # Replace with function body.


func configurar(id: int, salud: int, salud_max: int, personaje: int):
	peer_id = id
	salud_actual = salud
	salud_maxima = salud_max
	id_personaje = personaje
	
	_reproducir_personaje(id_personaje)
	_actualizar_vida(salud_actual)
	

func _reproducir_personaje(id: int) -> void:
	if sprite_personaje:
		sprite_personaje.play("idle" + str(id))
	# Si usas TextureRect en lugar de AnimatedSprite2D:
	# sprite_personaje.texture = load("res://personajes/sapo_" + str(id) + ".png")

func actualizar_salud(nueva_salud: int) -> void:
	salud_actual = nueva_salud
	_actualizar_vida(nueva_salud)

func actualizar_personaje(id: int) -> void:
	id_personaje = id
	_reproducir_personaje(id)

func _actualizar_vida(salud: int) -> void:
	if salud_maxima <= 0:
		return
	
	# Color del aro según el porcentaje
	var porcentaje = float(salud) / float(salud_maxima)
	var color_aro := COLOR_BIEN
	
	if porcentaje <= 0.25:
		color_aro = COLOR_BAJO
	elif porcentaje <= 0.5:
		color_aro = COLOR_MEDIO
	
	if aro:
		aro.modulate = color_aro
