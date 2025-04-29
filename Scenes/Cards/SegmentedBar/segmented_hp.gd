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

func Update(NewAmm : int) -> void:
	for g in $HBoxContainer.get_children().size():
		var p = $HBoxContainer.get_child(g)
		p.Toggle(g < NewAmm)

func ChangeSegmentAmm(NewAmm : int ) -> void:
	Segments = NewAmm
	for g in $HBoxContainer.get_children():
		g.free()
		
	for g in Segments:
		var p = SegmentScene.instantiate()

		$HBoxContainer.add_child(p)
