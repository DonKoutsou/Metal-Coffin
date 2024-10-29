extends PanelContainer

class_name PlanetAnalyzer

@export var DropContainerScene : PackedScene
var Drops : Array[DropContainer] = []

func _ready() -> void:
	UISoundMan.GetInstance().Refresh()

func SetVisuals(Spot : MapSpot) -> void:
	if (Spot.Analyzed):
		var viz = Spot.SpotType.Scene.instantiate() as MeshInstance3D
		var abb = viz.get_aabb().get_longest_axis_size() * viz.scale.x
		$VBoxContainer/HBoxContainer/Control/SubViewportContainer/SubViewport.add_child(viz)
		$VBoxContainer/HBoxContainer/Control/SubViewportContainer/SubViewport/Camera3D.position.z = abb * 2
		$VBoxContainer/HBoxContainer/VBoxContainer/PlanetName.text = Spot.SpotType.FullName
		$VBoxContainer/HBoxContainer/VBoxContainer/PlanetDesc.text = Spot.SpotType.Description
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CheckBox.button_pressed = Spot.SpotType.CanLand
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CheckBox2.button_pressed = Spot.SpotType.HasAtmoshere
		$VBoxContainer/HBoxContainer/Control/ColorRect.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label2.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label4.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer3/Label2.text = "Analyzed"
		AddItems(Spot.SpotType.PossibleDrops)
	else :
		$VBoxContainer/HBoxContainer/VBoxContainer/PlanetName.text = "?"
		$VBoxContainer/HBoxContainer/VBoxContainer/PlanetDesc.text = "?"
		$VBoxContainer/HBoxContainer/Control/ColorRect.visible = true
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CheckBox.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CheckBox2.visible = false
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TextureRect.texture = Spot.SpotType.MapIcon
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Label2.text = Spot.SpotType.GetEnumString()
func _on_button_pressed() -> void:
	queue_free()
func AddItems(It : Array[Item]) -> void:
	for z in It.size():
		var newbox = DropContainerScene.instantiate() as DropContainer
		$VBoxContainer/HBoxContainer/VBoxContainer/GridContainer.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
		newbox.AddIcon(newcont.ItemType.ItemIcon)
		if (newcont.ItemType is UsableItem):
			newbox.UpdateIcontColor(newcont.ItemType.ItecColor)
		Drops.append(newbox)
