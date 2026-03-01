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
	UISoundMan.GetInstance().AddSelf($VBoxContainer/ContinueButton)

func _on_continue_button_pressed() -> void:
	ContinuePressed.emit()

func SetData(Data : BattleReportData) -> void:

	var text = ""
	if (Data.Won):
		text += "[center][color=#ffc315]Funds Earned[/color] : {0}\n".format([Data.FundWon])
	else:
		text += "[center][color=#ffc315]Funds Earned[/color] : {0}\n".format([0])
	text += "[color=#ffc315]Damage Dealt[/color] : {0}\n".format([roundi(Data.DamageDone)])
	text += "[color=#ffc315]Damage Received [/color]: {0}\n".format([roundi(Data.DamageGot)])
	text += "[color=#ffc315]Damage Negated[/color] : {0}\n".format([roundi(Data.DamageNegated)])
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
