extends Control

class_name WorldviewUI

@export var WorldviewStatScene : PackedScene

func _ready() -> void:
	UiSoundManager.GetInstance().AddSelf($HBoxContainer/Button)
	for g in WorldView.WorldviewStats:
		var Stat = WorldviewStatScene.instantiate() as WorldviewStatUI
		$HBoxContainer/PanelContainer/VBoxContainer.add_child(Stat)
		Stat.Set(g)

var Open : bool = false

func _on_button_pressed() -> void:
	if (Open):
		Open = false
		$HBoxContainer/Button.text = "<<"
		var tw = create_tween()
		tw.tween_property(self, "position", Vector2(position.x + $HBoxContainer/PanelContainer.size.x, position.y), 0.5)
	else:
		Open = true
		$HBoxContainer/Button.text = ">>"
		var tw = create_tween()
		tw.tween_property(self, "position", Vector2(position.x - $HBoxContainer/PanelContainer.size.x, position.y), 0.5)
		
