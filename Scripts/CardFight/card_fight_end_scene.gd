extends PanelContainer

class_name CardFightEndScene

@export var DateLabel : Label
@export var LocationLabel : Label
@export var DataLabel : RichTextLabel
@export var FriendlyCasualtiesLabel : Label
@export var EnemyCasualtiesLabal : Label

signal ContinuePressed

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($VBoxContainer/ContinueButton)

func _on_continue_button_pressed() -> void:
	ContinuePressed.emit()

func SetData(Won : bool, Funds : int, DoneDmg : float, GotDmg : float, NegDmg : float, FRCasualties : Array[BattleShipStats], ENCasualties : Array[BattleShipStats], Loc : Vector2) -> void:

	var text = ""
	if (Won):
		text += "[center][color=#ffc315]Funds Earned[/color] : {0}\n".format([Funds])
	else:
		text += "[center][color=#ffc315]Funds Earned[/color] : {0}\n".format([0])
	text += "[color=#ffc315]Damage Dealt[/color] : {0}\n".format([roundi(DoneDmg)])
	text += "[color=#ffc315]Damage Received [/color]: {0}\n".format([roundi(GotDmg)])
	text += "[color=#ffc315]Damage Negated[/color] : {0}\n".format([roundi(NegDmg)])
	DataLabel.text = text
	
	for g in FRCasualties:
		FriendlyCasualtiesLabel.text += "\n{0}".format([g.Name])
	for g in ENCasualties:
		EnemyCasualtiesLabal.text += "\n{0}".format([g.Name])
	
	DateLabel.text = Clock.GetDateTimeString()
	var closest = Helper.GetInstance().GetClosestSpot(Loc)
	if (closest.global_position.distance_to(Loc) < 1000):
		LocationLabel.text = "Location : {0}".format([closest.GetSpotName()])
	else:
		LocationLabel.text = "Location : {0} of {1}".format([Helper.AngleToDirection(closest.global_position.angle_to_point(Loc)) ,closest.GetSpotName()])
