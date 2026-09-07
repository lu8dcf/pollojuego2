extends comportamientoArma
class_name comportamientoExplosiva

var datos : Arma

var rango_explosivo

var danio_explosion

var tiempo_espoleta


func atacar():
	var tree = Engine.get_main_loop() as SceneTree
	await tree.create_timer(tiempo_espoleta).timeout
	print("booom!")
