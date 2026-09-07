extends Area2D

@onready var sprite_rango: Sprite2D = %SpriteRango
@onready var sprite_palanca: Sprite2D = %SpritePalanca
@onready var radio_colision = %RadioColision.shape.radius # se necesita obteener el radio para el movimiento de la palanca


var distancia: float
var direccion: Vector2 # para que el jugador sepa hacia donde se mueve

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch: # si se acaba de presionar 
		if event.is_pressed():
			distancia = global_position.distance_to(event.position) 
			if distancia < radio_colision:
				sprite_palanca.global_position = event.position
				direccion  = global_position.direction_to(sprite_palanca.global_position) * distancia/ radio_colision
		else:  # si se suelta
			sprite_palanca.position=Vector2.ZERO # detenemos su movimiento
			direccion = Vector2.ZERO
	if event is InputEventScreenDrag: # si se arrastra el dedo
		distancia = global_position.distance_to(event.position) 
		if distancia <= radio_colision:
			sprite_palanca.global_position = event.position
			direccion  = global_position.direction_to(sprite_palanca.global_position) * distancia/ radio_colision
		else:
			direccion = global_position.direction_to(event.position)
			sprite_palanca.global_position = global_position + (direccion * radio_colision)
				
