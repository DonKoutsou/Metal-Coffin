extends PanelContainer

class_name PlanetAnalyzer

@export var DropContainerScene : PackedScene
var Drops : Array[DropContainer] = []

func _ready() -> void:
	UISoundMan.GetInstance().Refresh()

func SetVisuals(Spot : MapSpot) -> void:
	$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer2/HBoxContainer/PlanetName.text = Spot.GetSpotName()
	#$VBoxContainer/HBoxContainer/VBoxContainer/PlanetDesc.text = Spot.GetSpotDescriptio()
	var boo = Spot.Analyzed or Spot.Visited
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer4/HBoxContainer/CanLandCheck.button_pressed = Spot.CanLand()
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer4/HBoxContainer/CanLandCheck.visible = boo
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer4/HBoxContainer/CanLandUnKnown.visible = !boo
	
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer5/HBoxContainer2/AtmoCheck.button_pressed = Spot.HasAtmosphere()
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer5/HBoxContainer2/AtmoCheck.visible = boo
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer5/HBoxContainer2/HasAtmoUnKnown.visible = !boo
	
	$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer6/HBoxContainer3/Label2.text = "Analyzed" if Spot.Analyzed else "Not Analyzed"
	
	AddItems(Spot.GetPossibleDrops())
	
	#$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label2.visible = false
	
	
	$VBoxContainer/HBoxContainer/Control/ColorRect.visible = !boo
	if (boo):
		var viz = Spot.SpotType.Scene.instantiate() as MeshInstance3D
		var abb = viz.get_aabb().get_longest_axis_size() * viz.scale.x
		$VBoxContainer/HBoxContainer/Control/SubViewportContainer/SubViewport.add_child(viz)
		$VBoxContainer/HBoxContainer/Control/SubViewportContainer/SubViewport/Camera3D.position.z = abb * 2
	
	$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer2/HBoxContainer/TextureRect.texture = Spot.SpotType.MapIcon
	#$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/HBoxContainer2/Label2.text = Spot.SpotType.GetEnumString()
func _on_button_pressed() -> void:
	queue_free()
func AddItems(It : Array) -> void:
	for z in It.size():
		var newbox = DropContainerScene.instantiate() as DropContainer
		$VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer3/VBoxContainer/GridContainer.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
		newbox.AddIcon(newcont.ItemType.ItemIcon)
		if (newcont.ItemType is UsableItem):
			newbox.UpdateIcontColor(newcont.ItemType.ItecColor)
		Drops.append(newbox)
