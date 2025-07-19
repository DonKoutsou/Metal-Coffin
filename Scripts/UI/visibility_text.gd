extends Label

class_name VisibilityText

@export var ShipControllerEventH : ShipControllerEventHandler

var CurrentShip : PlayerDrivenShip

func _ready() -> void:
	ShipControllerEventH.connect("OnControlledShipChanged", ControlledShipChanged)
	CurrentShip = ShipControllerEventH.CurrentControlled

func ControlledShipChanged(NewShip : PlayerDrivenShip) -> void:
	CurrentShip = NewShip

func _physics_process(_delta: float) -> void:
	if (CurrentShip == null):
		return
		
	var vis = WeatherManage.GetInstance().GetVisibilityInPosition(CurrentShip.global_position)
	text = "Visibility : {0} = {1}".format([GetTextForVis(vis), snapped(vis, 0.01)])
	
func GetTextForVis(Vis : float) -> String:
	if (Vis > 0.9):
		return "Clear"
	if (Vis > 0.7):
		return "Dim"
	return "Hazy"
