extends Node3D

#Pruebo la fabrica de armas
@onready
var crear_armas_derecho = $derecho

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var arma = crear_armas_derecho.crear_arma(1)
	#await get_tree().create_timer(2).timeout
	#arma.atacar()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
