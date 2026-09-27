extends Control

@onready var un_jugador: TextureButtonAnimado = $un_jugador
@onready var multijugador: TextureButtonAnimado = $multijugador

func _ready() -> void:
	pass


func _on_salir_pressed() -> void:
	get_tree().quit()
