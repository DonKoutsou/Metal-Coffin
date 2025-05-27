extends PanelContainer

class_name ActionDeclarationUI

@export var UIInSound : AudioStream
@export var UIOutSound : AudioStream

signal ActionDeclarationFinished

func _ready() -> void:
	visible = false

func DoActionDeclaration(ActionName : String, CustomTime : float = 3) -> void:
	visible = true
	get_child(0).text = ActionName
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_BACK)
	Tw.tween_property(self, "custom_minimum_size", Vector2(650, 80), CustomTime/6)
	
	var InSound = DeletableSoundGlobal.new()
	InSound.stream = UIInSound
	InSound.autoplay = true
	InSound.bus = "MapSounds"
	InSound.pitch_scale = randf_range(0.9, 1.1)
	add_child(InSound)
	
	Tw.finished.connect(ActionDeclarationStage1.bind(CustomTime))

func ActionDeclarationStage1(CustomTime : float) -> void:
	get_child(0).visible = true
	
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property(get_child(0), "modulate", Color(1,1,1,1), CustomTime/6)
	Tw2.finished.connect(ActionDeclarationStage2.bind(CustomTime))

func ActionDeclarationStage2(CustomTime : float) -> void:
	Helper.GetInstance().wait((CustomTime/6) *2).connect(ActionDeclarationStage3.bind(CustomTime))
	
func ActionDeclarationStage3(CustomTime : float) -> void:
	var Tw3 = create_tween()
	Tw3.set_ease(Tween.EASE_OUT)
	Tw3.set_trans(Tween.TRANS_QUAD)
	Tw3.tween_property(get_child(0), "modulate", Color(1,1,1,0), CustomTime/6)
	Tw3.finished.connect(ActionDeclarationStage4.bind(CustomTime))
	
func ActionDeclarationStage4(CustomTime : float) -> void:
	get_child(0).visible = false
	
	var Tw4 = create_tween()
	Tw4.set_ease(Tween.EASE_IN)
	Tw4.set_trans(Tween.TRANS_BACK)
	Tw4.tween_property(self, "custom_minimum_size", Vector2(0, 80), CustomTime/6)
	
	var OutSound = DeletableSoundGlobal.new()
	OutSound.stream = UIOutSound
	OutSound.autoplay = true
	OutSound.bus = "MapSounds"
	OutSound.pitch_scale = randf_range(0.9, 1.1)
	add_child(OutSound)
	
	Tw4.finished.connect(FinishActionDeclaration)

func FinishActionDeclaration() -> void:
	ActionDeclarationFinished.emit()
	visible = false
