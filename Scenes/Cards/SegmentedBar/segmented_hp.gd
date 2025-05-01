extends PanelContainer

class_name SegmentedBar

@export var SegmentScene : PackedScene

var Segments : int

func Init(SegmentAmm : int) -> void:
	Segments = SegmentAmm
	
	for g in $HBoxContainer.get_children():
		g.free()
		
	for g in Segments:
		var p = SegmentScene.instantiate()

		$HBoxContainer.add_child(p)

func ChangeSegmentAmm(NewAmm : int ) -> void:
	Segments = NewAmm
	for g in $HBoxContainer.get_children():
		g.free()
		
	for g in Segments:
		var p = SegmentScene.instantiate()

		$HBoxContainer.add_child(p)

var LabelTween : Tween

var SegmentTween : Tween

func UpdateSegments(NewAmm : int) -> void:
	for g in $HBoxContainer.get_children().size():
		var p = $HBoxContainer.get_child(g)
		p.Toggle(g < NewAmm)

func NotifyNotEnough() -> void:
	if (LabelTween and LabelTween.is_running()):
		LabelTween.kill()
	
	LabelTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	LabelTween.tween_property($Control/Label,"scale", Vector2(1.5, 1.5), 0.55)
	
	await LabelTween.finished
	
	#if (LabelTween and LabelTween.is_running()):
	LabelTween.kill()
	LabelTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	LabelTween.tween_property($Control/Label,"scale", Vector2.ONE, 0.55)

func UpdateAmmount(OldAmmd : int, NewAmm : int) -> void:
	if (SegmentTween and SegmentTween.is_running()):
		SegmentTween.kill()
	SegmentTween = create_tween()
	SegmentTween.set_ease(Tween.EASE_OUT)
	SegmentTween.set_trans(Tween.TRANS_QUAD)
	SegmentTween.tween_method(UpdateSegments, OldAmmd, NewAmm, 0.5)
	
	$Control/Label.text = var_to_str(NewAmm)
	
	$Control/Label.pivot_offset = $Control/Label.size / 2
	
	if (LabelTween and LabelTween.is_running()):
		LabelTween.kill()
	
	LabelTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	LabelTween.tween_property($Control/Label,"scale", Vector2(1.5, 1.5), 0.55)
	
	await LabelTween.finished
	
	#if (LabelTween and LabelTween.is_running()):
	LabelTween.kill()
	LabelTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	LabelTween.tween_property($Control/Label,"scale", Vector2.ONE, 0.55)
