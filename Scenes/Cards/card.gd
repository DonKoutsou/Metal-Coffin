extends PanelContainer

class_name Card

@export var CardIcon : TextureRect
@export var CardName : Label
@export var CardDesc : RichTextLabel
@export var CardCost : Label

signal OnCardPressed(C : Card, Options : CardOption)

var CStats : CardStats

var Cost : int

var TargetLoc : Vector2

func _physics_process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if (TargetLoc != Vector2.ZERO):
		draw_set_transform(- global_position)
		draw_line(global_position + size / 2, TargetLoc, Color(0.482,0.69,0.705), 2)

func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($Button)
	$PanelContainer.visible = false
	set_physics_process(TargetLoc != Vector2.ZERO)

func SetCardStats(Stats : CardStats, Options : Array[CardOption]) -> void:
	CStats = Stats
	Cost = Stats.Energy
	if Stats.SelectedOption !=  null:
		CardName.text = Stats.SelectedOption.OptionName + " " + Stats.CardName
		Cost += Stats.SelectedOption.EnergyAdd
	else:
		CardName.text = Stats.CardName
	CardIcon.texture = Stats.Icon
	
	var DescText =  "[center]{0}".format([Stats.CardDescription])
	#CardDesc.visible_ratio = 0
	#var tw = create_tween()
	#tw.tween_property(CardDesc, "visible_ratio", 1, 1)
	
	CardDesc.text = DescText
	
	CardCost.text = var_to_str(Cost)
	for g in Stats.Options:
		var OptionBut = Button.new()
		OptionBut.text = g.OptionName
		$PanelContainer/HBoxContainer.add_child(OptionBut)
		OptionBut.connect("pressed", OnOptionSelected.bind(g))
	for g in Options:
		var OptionBut = Button.new()
		OptionBut.text = g.OptionName
		$PanelContainer/HBoxContainer.add_child(OptionBut)
		OptionBut.connect("pressed", OnOptionSelected.bind(g))

func OnButtonPressed() -> void:
	if ($PanelContainer/HBoxContainer.get_child_count() > 0 and CStats.SelectedOption == null):
		if ($PanelContainer/HBoxContainer.get_child_count() == 1):
			OnCardPressed.emit(self, CStats.Options[0])
			return
		$PanelContainer.visible = true
	else:
		OnCardPressed.emit(self, null)

func Dissable() -> void:
	$Button.disabled = true

func OnOptionSelected(Option : CardOption) -> void:
	#var but = get_viewport().gui_get_focus_owner() as Button
	#Option = but.text
	$PanelContainer.visible = false
	OnCardPressed.emit(self, Option)

func GetCost() -> int:
	#if (CStats.SelectedOption != null):
		#return Cost + CStats.SelectedOption.EnergyAdd
	return Cost
