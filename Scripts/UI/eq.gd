extends VBoxContainer

class_name EQ

var prev : float = 0

func _ready() -> void:
	DoThing()

func DoThing() -> void:
	var newval = randf_range(0, get_child_count())
	var tw = create_tween()
	tw.tween_method(SetVar, prev, newval, 0.1)
	await  tw.finished
	prev = newval
	call_deferred("DoThing")

func SetVar(v : float) -> void:
	var i = roundi(v)
	
	for g in get_children().size():
		var ch = get_child(g)
		ch.visible = g < i
