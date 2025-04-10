extends Control

class_name Card

@export var CardName : Label
@export var CardDesc : RichTextLabel
@export var CardCost : Label
@export var CardTex : TextureRect

signal OnCardPressed(C : Card, Options : CardOption)

var CStats : CardStats

var Cost : int

var TargetLoc : Vector2

var InterpolationValue : float

func _physics_process(delta: float) -> void:
	InterpolationValue = min(InterpolationValue + delta * 2, 1)
	UpdateLine()

func UpdateLine() -> void:
	$Line2D.set_point_position(1, lerp(Vector2.ZERO ,$Line2D.to_local(TargetLoc),InterpolationValue))
		#draw_line(global_position + size / 2, lerp(global_position + size / 2 ,TargetLoc,InterpolationValue), Color(0.482,0.69,0.705), 5)

func CompactCard() -> void:
	$VBoxContainer/CardDesc.visible = false
	$Line2D.position.y -= size.y - 85
	custom_minimum_size.y = 85
	size.y = 85
	
	#position.y += size.y - 85
	set_anchors_preset(Control.PRESET_CENTER)

func KillCard() -> void:
	var KillTw = create_tween()
	KillTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	KillTw.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
	await KillTw.finished
	free()

func _ready() -> void:
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf($Button)
	$PanelContainer.visible = false
	set_physics_process(TargetLoc != Vector2.ZERO)
	$Line2D.visible = TargetLoc != Vector2.ZERO

func SetCardStats(Stats : CardStats, Options : Array[CardOption]) -> void:
	CStats = Stats
	Cost = Stats.Energy
	var DescText =  "[center] {0}".format([Stats.CardDescription])
	
	if Stats.SelectedOption !=  null:
		CardName.text = Stats.SelectedOption.OptionName + " " + Stats.CardName
		DescText =  "[center] {0}".format([ Stats.SelectedOption.OptionDescription])
		Cost += Stats.SelectedOption.EnergyAdd
		CardTex.texture = Stats.SelectedOption.NewPic
	else:
		CardName.text = Stats.CardName
		CardTex.texture = Stats.Icon
	
	#var DescText =  "[center]{0}".format([Stats.CardDescription])
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
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.RemoveSelf($Button)
	
func OnOptionSelected(Option : CardOption) -> void:
	#var but = get_viewport().gui_get_focus_owner() as Button
	#Option = but.text
	$PanelContainer.visible = false
	OnCardPressed.emit(self, Option)

func GetCost() -> int:
	#if (CStats.SelectedOption != null):
		#return Cost + CStats.SelectedOption.EnergyAdd
	return Cost
