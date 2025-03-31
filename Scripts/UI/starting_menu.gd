extends CanvasLayer

class_name StartingMenu

@export var CreditsScene : PackedScene

var SpawnedCredits : Control

signal GameStart(Load : bool)

func _ready() -> void:
	$w/PointLight2D.energy = 0
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property($w/PointLight2D, "energy", 1, 2)
	LoopAmp()

func _on_play_pressed() -> void:
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	GameStart.emit(true)


func On_Credits_Pressed() -> void:
	SpawnedCredits = CreditsScene.instantiate()
	$w.add_child(SpawnedCredits)


func LoopAmp() -> void:
	var Tw = create_tween()
	Tw.set_trans(Tween.TRANS_BOUNCE)
	Tw.tween_property($w/LineDrawer, "amplitude", randf_range(-80, 80), 0.2)
	await Tw.finished
	call_deferred("LoopAmp")
