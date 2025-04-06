extends Control

class_name FightMinigame

@export var Float : PackedScene
@export var Accuracy : float = 50
@export var Bar : ProgressBar

signal Ended(Resault : bool)

func _ready() -> void:
	SetAccuracy()

func SetAccuracy() -> void:
	var percentSize = Bar.size.x / 100 * Accuracy
	$Panel.size.x = percentSize
	#center panel
	$Panel.position.x = (size.x / 2) - percentSize / 2


func _physics_process(delta: float) -> void:
	Bar.value += 1
	if (Bar.value == 100):
		set_physics_process(false)
		var t = Float.instantiate() as Floater
		t.text = "Fail"
		add_child(t)
		await t.Ended
		Ended.emit(false)
		#Restart()

func _on_stop_button_pressed() -> void:
	set_physics_process(false)
	
	var Distance = abs(Bar.value - 50)
	if (Distance > Accuracy / 2):
		var t = Float.instantiate() as Floater
		t.text = "Fail"
		add_child(t)
		await t.Ended
		Ended.emit(false)
	else:
		var t = Float.instantiate() as Floater
		t.text = "Good"
		add_child(t)
		await t.Ended
		Ended.emit(true)
		
	#Restart()
	#if (value - 50 + Accuracy)

func Restart() -> void:
	Accuracy = randf_range(1, 50)
	SetAccuracy()
	Bar.value = 0
	set_physics_process(true)
