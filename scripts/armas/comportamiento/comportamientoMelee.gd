extends comportamientoArma
class_name ComportamientoMelee

var datos : Arma


func atacar():
	datos.comportamiento.ataque()
