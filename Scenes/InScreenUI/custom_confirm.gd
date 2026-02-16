extends ColorRect

class_name CustomConfirm

@export var ChoiceButton1 : Button
@export var ChoiceButton2 : Button
@export var OptionTextLabel : Label

var AnswerSignal : SignalObject

func DoChoice(Choice1 : String, Choice2 : String, Text : String) -> SignalObject:
	ChoiceButton1.text = Choice1
	ChoiceButton2.text = Choice2
	OptionTextLabel.text = Text
	AnswerSignal = SignalObject.new()
	return AnswerSignal

func _on_choice_1_pressed() -> void:
	AnswerSignal.Sign.emit(true)
	queue_free()

func _on_choice_2_pressed() -> void:
	AnswerSignal.Sign.emit(false)
	queue_free()
