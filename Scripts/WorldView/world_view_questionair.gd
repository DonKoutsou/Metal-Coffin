extends PanelContainer

class_name WorldViewQuestionair

@export var IntroDialogue : Array[String]
@export var PossibleQuestions : Array[WorldviewQuestion]
var PickedQuestions : Array[WorldviewQuestion]

var CurrentIntroDialogue : int = 0
var CurrentQuestion : int = 0

signal Ended

func _ready() -> void:
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
	$VBoxContainer/Label.text = IntroDialogue[CurrentIntroDialogue]
	$VBoxContainer/Label.visible_ratio = 0

var Tw : Tween
func _physics_process(delta: float) -> void:
	$VBoxContainer/Label.visible_ratio += delta
	if ($VBoxContainer/Label.visible_ratio < 1):
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
		$VBoxContainer/Label.text = IntroDialogue[CurrentIntroDialogue]
		$VBoxContainer/Label.visible_ratio = 0

func SkipButton() -> void:
	UpdateQuestion()
	$VBoxContainer/HBoxContainer2.hide()
	$VBoxContainer/HBoxContainer.show()

func UpdateQuestion() -> void:
	if (PickedQuestions.size() <= CurrentQuestion):
		Ended.emit()
		queue_free()
		return
	$VBoxContainer/Label.text = PickedQuestions[CurrentQuestion].QuestionText
	$VBoxContainer/Label.visible_ratio = 0
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
