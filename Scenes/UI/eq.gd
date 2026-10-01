extends VBoxContainer

class_name EQ

var prev : float = 0

var Work : bool = false

func _ready() -> void:
	#for g : Control in get_children():
		#g.custom_minimum_size.y = size.y
	DoThing()

func DoThing() -> void:
	var newval = randf_range(0, get_child_count())
	var tw = create_tween()
	tw.tween_method(SetVar, prev, newval, 0.1)
	await  tw.finished
	prev = newval
	if (Work):
		call_deferred("DoThing")

func Toggle(t : bool) -> void:
	if (Work == t):
		return
	Work = t
	if (t):
		DoThing()
	else:
		var tw = create_tween()
		tw.tween_method(SetVar, prev, 0, 0.1)
	
func SetVar(v : float) -> void:
	var i = roundi(v)
	
	for g in get_children().size():
		var ch = get_child(g)
		ch.visible = g < i
