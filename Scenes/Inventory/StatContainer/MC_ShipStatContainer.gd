@tool
extends ShipStatContainer

class_name MC_ShipStatContainer

@export_file("*.tscn") var Tooltipscene : String

var Tooltip : Control
func _process(_delta: float) -> void:
	PositionTooltip()

func PositionTooltip() -> void:
	var Mpos = get_global_mouse_position() 
	var VPRect =  get_viewport().get_visible_rect()
	Mpos -= Vector2(0, Tooltip.size.y)
	var DistanceFromTop = Mpos.y
	var DistFromRight = VPRect.size.x - Mpos.x
	var Diff = DistanceFromTop
	var Diff2 = Tooltip.size.x - DistFromRight
	
	var FinalPos = Mpos
	if (Diff < 0):
		FinalPos -= Vector2(0,Diff)
	if (Diff2 > 0):
		FinalPos -= Vector2(Diff2,0)
	
	Tooltip.global_position = FinalPos
	#Tooltip.global_position = get_global_mouse_position()

func _on_mouse_entered() -> void:
	if (Engine.is_editor_hint()):
		return
	var tipscene : PackedScene = ResourceLoader.load(Tooltipscene)
	Tooltip = tipscene.instantiate()
	
	Tooltip.global_position = get_global_mouse_position() - Vector2(0, Tooltip.size.y)
	Ingame_UIManager.GetInstance().add_child(Tooltip)
	Tooltip.set_deferred("size", Vector2(Tooltip.size.x,0))
	
	var col = ColorManager.GetCurrentColor().to_html()
	var tooptipText = STAT_CONST.GetTooltip(STName).replace("#ffc315", "{0}".format([col]))
	
	Tooltip.get_child(0).text = "[color={2}][font_size=22]{0}[/font_size][/color]\n{1}".format([STAT_CONST.STATS.keys()[STName].replace("_", " ") ,tooptipText, col])
	
	PositionTooltip()
	set_process(true)

func _on_mouse_exited() -> void:
	if (Engine.is_editor_hint()):
		return
	Tooltip.queue_free()
	set_process(false)
