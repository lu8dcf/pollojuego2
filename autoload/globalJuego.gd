extends Node

#inventario global
var inventario_jugador = [null, null, null, null, null, null] # inventario de maximo 6 slots

#Seleccion de personaje
var polloBasico = "res://scenes/pollos/pollo_modelo_1.tscn"


#Tamaño del Mapa
var mapa_x_min = -20
var mapa_x_max = 20
var mapa_z_min = -20
var mapa_z_max = 20


#enemigos
var cant_enemigos = 50 # Cantidad de enemigos en la oleada siempr activos
