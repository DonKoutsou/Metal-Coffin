extends PanelContainer

class_name FleetSeparationShipViz

@export var CapPortrait : TextureRect

@export var CapName : Label


signal OnShipSelected

var ContainedShip : MapShip

func SetShip(Ship : MapShip) -> void:
	ContainedShip = Ship
	SetVisuals(Ship.Cpt)

func SetVisuals(Cap : Captain) -> void:
	CapPortrait.texture = Cap.CaptainPortrait

	CapName.text = Cap.CaptainName

func _on_button_pressed() -> void:
	OnShipSelected.emit()
