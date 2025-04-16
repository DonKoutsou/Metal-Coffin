extends PanelContainer

class_name WorldViewQuestionair

@export_group("Nodes")
@export var Text : Label

@export_group("Texts")
@export var IntroDialogue : Array[String]
@export var PossibleQuestions : Array[WorldviewQuestion]
var PickedQuestions : Array[WorldviewQuestion]

var CurrentIntroDialogue : int = 0
var CurrentQuestion : int = 0

signal Ended

func Init() -> void:
	UISoundMan.GetInstance().Refresh()
	Tw = create_tween()
	Tw.set_trans(Tween.TRANS_BOUNCE)
	Tw.tween_property($VBoxContainer/LineDrawer, "amplitude", randf_range(3, 20), 1)
	for g in 4:
		var Stat = WorldView.WorldViews.values()[g + 1]
		var Picked : Array[WorldviewQuestion]
		
		while Picked.size() < 4:
			var Question = PossibleQuestions.pick_random()
			if (Question.WorldviewSkill != Stat):
				continue
			if (Picked.has(Question)):
				continue
			Picked.append(Question)
			
		PickedQuestions.append_array(Picked)
		
	PickedQuestions.shuffle()
	$VBoxContainer/HBoxContainer2.visible = true
	Text.visible = true
	Text.text = IntroDialogue[CurrentIntroDialogue]
	Text.visible_ratio = 0

var d = 0.06
var Tw : Tween
func _physics_process(delta: float) -> void:
	
	Text.visible_ratio += delta
	
	d -= delta
	if (d > 0):
		return
	d = 0.06
	
	
	
	if (Text.visible_ratio < 1):
		#if (!$AudioStreamPlayer.playing):
		$AudioStreamPlayer.pitch_scale = randf_range(0.85, 1.15)
		$AudioStreamPlayer.play()
		if (Tw.finished):
			Tw = create_tween()
			Tw.set_trans(Tween.TRANS_BOUNCE)
			Tw.tween_property($VBoxContainer/LineDrawer, "amplitude", randf_range(-60, 60), 0.2)
			
	else:
		Tw = create_tween()
		#Tw.set_trans(Tween.TRANS_BOUNCE)
		Tw.tween_property($VBoxContainer/LineDrawer, "amplitude", 0, 0.1)
		#$VBoxContainer/LineDrawer.amplitude = 0

func NextButtonPressed() -> void:
	CurrentIntroDialogue += 1
	if (IntroDialogue.size() <= CurrentIntroDialogue):
		UpdateQuestion()
		$VBoxContainer/HBoxContainer2.hide()
		$VBoxContainer/HBoxContainer.show()
	else:
		Text.text = IntroDialogue[CurrentIntroDialogue]
		Text.visible_ratio = 0

func SkipButton() -> void:
	UpdateQuestion()
	$VBoxContainer/HBoxContainer2.hide()
	$VBoxContainer/HBoxContainer.show()

func UpdateQuestion() -> void:
	if (PickedQuestions.size() <= CurrentQuestion):
		Ended.emit()
		$VBoxContainer.visible = false
		#queue_free()
		return
	Text.text = PickedQuestions[CurrentQuestion].QuestionText
	Text.visible_ratio = 0
	$VBoxContainer/HBoxContainer/Button.text = PickedQuestions[CurrentQuestion].NegativeAnswer
	$VBoxContainer/HBoxContainer/Button2.text = PickedQuestions[CurrentQuestion].PossetiveAnswer

func Option1Pressed() -> void:
	WorldView.GetInstance().AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, - 10, false)
	CurrentQuestion += 1
	UpdateQuestion()
func Option2Pressed() -> void:
	WorldView.GetInstance().AdjustStat(PickedQuestions[CurrentQuestion].WorldviewSkill, 10, false)
	CurrentQuestion += 1
	UpdateQuestion()
