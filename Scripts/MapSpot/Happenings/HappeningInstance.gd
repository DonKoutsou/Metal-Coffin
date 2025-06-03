extends Control

class_name HappeningInstance

#@export var TestHappening : Happening
@export var OptionParent : Control
@export var HappeningText : RichTextLabel
@export var HappeningBackgroundTexture : TextureRect
@export var ProgBar : ProgressBar
@export var DiagButtons : Control
@export var NextDialogueButton : Button
@export var SkipDialogueButton : Button
@export var TextFloater : PackedScene
@export var Line : Control
@export var Amp : Control

var EventSpot : MapSpot
var SelectedOption : int
var Hapen : Happening
var CurrentBranch : Array[HappeningStage]
var CurrentStage : int = 0

signal HappeningFinished(Recruited : bool, End : bool)

signal ResponseReceived

signal NextDiag

var RecruitedShips : bool = false

var FinishedCampaign : bool = false

var Events : Array[OverworldEventData]

var HappeningInstigator : MapShip

var CurrentText : int

func _ready() -> void:
	UISoundMan.GetInstance().Refresh()
	#set_physics_process(false)
	var TownBG = EventSpot.SpotType.BackgroundScene.instantiate() as TownBackground
	$SubViewportContainer/SubViewport.add_child(TownBG)
	TownBG.set_physics_process(false)
	
	Tw = create_tween()
	Tw.set_trans(Tween.TRANS_BOUNCE)
	Tw.tween_property(Line, "amplitude", randf_range(3, 20), 1)
	
	DiagButtons.visible = false
	ProgBar.visible = false
	#PresentHappening(load("res://Resources/Happenings/CardiPrince.tres"))

func PresentHappening(Hap : Happening):
	SimulationManager.GetInstance().TogglePause(true)

	Hapen = Hap
	CurrentBranch = Hap.Stages
	
	call_deferred("NextStage")
	
	#set_physics_process(false)

func NextStage() -> void:
	var Stage = CurrentBranch[CurrentStage]
	HappeningBackgroundTexture.texture = Stage.StagePic
	
	if (Stage.StagePic != null):
		var bTw = create_tween()
		bTw.set_ease(Tween.EASE_OUT)
		bTw.set_trans(Tween.TRANS_QUAD)
		
		bTw.tween_property($VBoxContainer/HBoxContainer2/Control, "custom_minimum_size", Vector2(320,0), 1)

	else:

		var bTw = create_tween()
		bTw.set_ease(Tween.EASE_OUT)
		bTw.set_trans(Tween.TRANS_QUAD)
		
		bTw.tween_property($VBoxContainer/HBoxContainer2/Control, "custom_minimum_size", Vector2(0,0), 1)
	
	CurrentText = 0
	for z in Stage.HappeningTexts.size():
		var Last = Stage.HappeningTexts.size() ==  z + 1
		
		var text = Stage.HappeningTexts[z]
		
		HappeningText.text = text
		HappeningText.visible_ratio = 0
		if (Last and Stage.HappeningTexts.size() > 1):
			break
		if (Last and Stage.Options.size() > 0):
			break
			
		DiagButtons.visible = true
		OptionParent.visible = false
		
		await NextDiag
		
		CurrentText += 1
		
		DiagButtons.visible = false
		OptionParent.visible = true
	
	CurrentStage += 1
	
	if (Stage.Options.size() > 0):
		var OptionAmm = Stage.Options.size()
		for f in OptionParent.get_child_count():
			var but = OptionParent.get_child(f) as Button
			if (f >= OptionAmm):
				but.visible = false
				continue
			var Opt = Stage.Options[f] as Happening_Option
			but.text = Opt.OptionName
			if (Opt.WorldviewCheck != WorldView.WorldViews.NONE):
				var Checks = WorldView.WorldViews.keys()[Opt.WorldviewCheck].split("_")
				var CurrentCheck
				if (Opt.CheckPossetive):
					CurrentCheck = Checks[1]
				else:
					CurrentCheck = Checks[0]
				but.text += "\nWorldView check : {0}".format([CurrentCheck])
				
				if (!ActionTracker.IsActionCompleted(ActionTracker.Action.WORLDVIEW_CHECK)):
					ActionTracker.OnActionCompleted(ActionTracker.Action.WORLDVIEW_CHECK)
					var text = "Certain dialogue options require a stat check to happen. This check will determine if the option will have the outcome you want."
					ActionTracker.GetInstance().ShowTutorial("Worldview Checks", text, [but], true)

		
		await ResponseReceived
		
		var Option = Stage.Options[SelectedOption] as Happening_Option
		
		var Check = Option.Check()

		if (Option.WorldviewCheck != WorldView.WorldViews.NONE):
			var CheckResault = TextFloater.instantiate() as Floater
			if (Check):
				CheckResault.SetColor(true)
				CheckResault.text = "WorldView Check Successfull"
			else:
				CheckResault.SetColor(false)
				CheckResault.text = "WorldView Check Failed"
			add_child(CheckResault)
		
		var res = Option.OptionOutCome(HappeningInstigator)
		
		if (Option is Drone_Happening_Option and res == true):
			RecruitedShips = true
		
		if (Option is EndGame_Happening_Option and res == true):
			FinishedCampaign = true
		
		if (Option.Event != null):
			Events.append(Option.Event)
		
		if (Check):
			HappeningText.text = Option.OptionResault(EventSpot)
			HappeningText.visible_ratio = 0
			DiagButtons.visible = true
			SkipDialogueButton.visible = false
			OptionParent.visible = false
			
			await NextDiag
			
			DiagButtons.visible = false
			SkipDialogueButton.visible = true
			OptionParent.visible = true
		if (Stage.Options[SelectedOption].FinishDiag):
		
			HappeningFinished.emit(RecruitedShips, FinishedCampaign, Events)
			$VBoxContainer/HBoxContainer2/VBoxContainer2.visible = false
		else:
			var Possiblebranch : Array[HappeningStage] = []
			if (!Check):
				Possiblebranch.append_array(Option.WorldViewCheckFailBranch)
			else:
				Possiblebranch.append_array(Option.BranchContinuation)
			
			if (Possiblebranch.size() > 0):
				CurrentBranch = Possiblebranch
				CurrentStage = 0
			
			
	if (CurrentBranch.size() == CurrentStage):
		HappeningFinished.emit(RecruitedShips, FinishedCampaign, Events)
		$VBoxContainer/HBoxContainer2/VBoxContainer2.visible = false
	else:
		call_deferred("NextStage")
		
	
func _on_option_1_pressed() -> void:
	SelectedOption = 0
	ResponseReceived.emit()
func _on_option_2_pressed() -> void:
	
	SelectedOption = 1
	ResponseReceived.emit()
func _on_option_3_pressed() -> void:
	
	SelectedOption = 2
	ResponseReceived.emit()
func _on_option_4_pressed() -> void:
	
	SelectedOption = 3
	ResponseReceived.emit()
	
var d = 0.06
var Tw : Tween
func _physics_process(delta: float) -> void:
	
	HappeningText.visible_ratio += delta
	
	d -= delta
	if (d > 0):
		return
	d = 0.06

	if (HappeningText.visible_ratio < 1):
		#if (!$AudioStreamPlayer.playing):
		$AudioStreamPlayer.pitch_scale = randf_range(0.85, 1.15)
		$AudioStreamPlayer.play()
		if (Tw.finished):
			Tw = create_tween()
			Tw.set_trans(Tween.TRANS_BOUNCE)
			Tw.tween_property(Line, "amplitude", randf_range(-30, 30), 0.2)
		Amp.toggle(true)
	else:
		Tw = create_tween()
		#Tw.set_trans(Tween.TRANS_BOUNCE)
		Tw.tween_property(Line, "amplitude", 0, 0.1)
		Amp.toggle(false)
		#$VBoxContainer/LineDrawer.amplitude = 0

func _on_next_diag_pressed() -> void:
	NextDiag.emit()


func _on_skip_diag_pressed() -> void:
	var Size = CurrentBranch[CurrentStage].HappeningTexts.size()
	NextDiag.emit()
	while(Size - 1 > CurrentText):
		NextDiag.emit()
