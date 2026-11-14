extends TextureRect

@onready var label_posicion: Label = %LabelPosicion
@onready var sprite_personaje: AnimatedSprite2D = %SpritePersonaje
@onready var label_score: Label = %LabelScore
@onready var label_usuario: Label = %LabelUsuario

func configurar(posicion:int,datos:Dictionary,es_local:bool)->void:
	label_posicion.text = "%d"% posicion
	label_score.text = "%d" % int(datos.get("score",0))
	label_usuario.text = datos.get("username","jugador") 
	if es_local:
		pass  # es su propio panel, habria que hacerlo tipo si es el tuyo cambiar el fondo o algo asi
