extends CanvasLayer

class_name StartingMenu

@export var CreditsScene : PackedScene

var SpawnedCredits : Control

signal GameStart(Load : bool)

func _ready() -> void:
	$w.modulate = Color(0,0,0)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property($w, "modulate", Color(1,1,1), 2)

func _on_play_pressed() -> void:
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	GameStart.emit(true)


func On_Credits_Pressed() -> void:
	SpawnedCredits = CreditsScene.instantiate()
	$w.add_child(SpawnedCredits)
