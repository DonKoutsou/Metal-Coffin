extends PanelContainer

class_name CardFightEndScene

@export var DateLabel : Label
@export var LocationLabel : Label
@export var DataLabel : RichTextLabel
@export var FriendlyCombatantsLabel : RichTextLabel
@export var EnemyCombatantsLabel : RichTextLabel
@export var FriendlyCasualtiesLabel : RichTextLabel
@export var EnemyCasualtiesLabal : RichTextLabel

signal ContinuePressed

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($MarginContainer/VBoxContainer/ContinueButton)

func _on_continue_button_pressed() -> void:
	ContinuePressed.emit()

func SetData(Data : BattleReportData) -> void:
	var col = ColorManager.GetCurrentColor().to_html()
	var text = ""
	if (Data.Won):
		text += "[center][color={1}]Funds Earned[/color] : {0}\n".format([Data.FundWon, col])
	else:
		text += "[center][color={1}]Funds Earned[/color] : {0}\n".format([0, col])
	text += "[color={1}]Damage Dealt[/color] : {0}\n".format([roundi(Data.DamageDone), col])
	text += "[color={1}]Damage Received [/color]: {0}\n".format([roundi(Data.DamageGot), col])
	text += "[color={1}]Damage Negated[/color] : {0}\n".format([roundi(Data.DamageNegated), col])
	DataLabel.text = text
	
	for g in Data.FriendlyCasualties:
		FriendlyCasualtiesLabel.text += "[p][center]{0}".format([g])
	for g in Data.EnemyCasualties:
		EnemyCasualtiesLabal.text += "[p][center]{0}".format([g])
	
	for g in Data.FriendlyCombatants:
		FriendlyCombatantsLabel.text += "[p][center]{0}".format([g])
	for g in Data.EnemyCombatants:
		EnemyCombatantsLabel.text += "[p][center]{0}".format([g])
	
	DateLabel.text = Data.Date
	
	LocationLabel.text = Data.Location
