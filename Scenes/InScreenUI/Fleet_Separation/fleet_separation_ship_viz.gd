extends PanelContainer

class_name CaptainButton

@export var CapPortrait : TextureRect

@export var CapName : Label


signal OnShipSelected
signal OnShipDeselected

var ContainedShip : MapShip
var ContainedCaptain : Captain

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($Button)

func SetShip(Ship : MapShip) -> void:
	ContainedShip = Ship
	SetVisuals2(Ship.Cpt)

func SetCpt(Cpt : Captain) -> void:
	ContainedCaptain = Cpt
	SetVisuals2(Cpt)

func SetVisuals(Cap : Captain) -> void:
	CapPortrait.texture = Cap.CaptainPortrait

	CapName.text = Cap.GetCaptainName()

func SetVisuals2(Cap : Captain) -> void:
	CapPortrait.texture = Cap.ShipIcon

	CapName.text = Cap.GetCaptainName()

func _on_button_pressed() -> void:
	OnShipSelected.emit()


func _on_button_button_up() -> void:
	OnShipDeselected.emit()

func Dissable() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
