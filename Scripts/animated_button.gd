extends TextureButton

@export var OffTexture : Texture
@export var OnTexture : Texture

func _ready() -> void:
	var anim = $AnimationPlayer.get_animation("Tick") as Animation
	anim = anim.duplicate()
	var resanim = $AnimationPlayer.get_animation("RESET") as Animation
	resanim = resanim.duplicate()
	($AnimationPlayer.get_animation_library("") as AnimationLibrary).add_animation("Tick",anim)
	($AnimationPlayer.get_animation_library("") as AnimationLibrary).add_animation("RESET",resanim)
	resanim.track_set_key_value(0, 0 , OffTexture)
	anim.track_set_key_value(0, 0 , OffTexture)
	anim.track_set_key_value(0, 1 , OnTexture)
	$AnimationPlayer.play("RESET")
	
	#$AnimationPlayer.play("Tick")
func _on_pressed() -> void:
	pass # Replace with function body.
	
func _on_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		$AnimationPlayer.play("Tick")
	else :
		$AnimationPlayer.stop()
	
func ToggleDissable(t : bool):
	disabled = t
	if (t):
		modulate = Color(0.6,0.6,0.6,1)
	else : 
		modulate = Color(1,1,1,1)
