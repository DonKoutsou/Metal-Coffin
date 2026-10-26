extends Control

class_name Paintshop

@export var repaintPrice : int = 3000
@export_group("Nodes")
@export var priceLabel : Label

var palette : Texture2D
var currentCol : int = 0

signal colorChanged(newCol : int)


func SetData(cap : Captain) -> void:
	var data : HullData = cap.GetHullData()
	palette = ResourceLoader.load(data.hull_Pallete)

	currentCol = cap.col


func _on_next_pressed() -> void:
	currentCol = wrap(currentCol + 1, 0, palette.get_size().y)
	colorChanged.emit(currentCol)

func _on_prev_pressed() -> void:
	currentCol = wrap(currentCol - 1, 0, palette.get_size().y)
	colorChanged.emit(currentCol)
