extends Control
class_name CaptainNotification
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("Fadeout")

func SetCaptain(Cpt : Captain):
	$PanelContainer/TextureRect.texture = Cpt.CaptainPortrait
	$PanelContainer2/Label.text = "New Captain Recruited \n" + Cpt.CaptainName

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
