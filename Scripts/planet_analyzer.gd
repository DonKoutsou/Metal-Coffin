extends PanelContainer

class_name PlanetAnalyzer

@export var DropContainerScene : PackedScene
var Drops : Array[DropContainer] = []

func SetVisuals(Spot : MapSpotType) -> void:
	var viz = Spot.Scene.instantiate() as MeshInstance3D
	var abb = viz.get_aabb().get_longest_axis_size() * viz.scale.x
	$VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport.add_child(viz)
	$VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/Camera3D.position.z = abb * 2
	$VBoxContainer/HBoxContainer/VBoxContainer/PlanetName.text = Spot.FullName
	$VBoxContainer/HBoxContainer/VBoxContainer/PlanetDesc.text = Spot.Description
	AddItems(Spot.PossibleDrops)
func _on_button_pressed() -> void:
	queue_free()
func AddItems(It : Array[Item]) -> void:
	for z in It.size():
		var newbox = DropContainerScene.instantiate() as DropContainer
		$VBoxContainer/HBoxContainer/VBoxContainer/GridContainer.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
		newbox.AddIcon(newcont.ItemType.ItemIcon)
		Drops.append(newbox)
