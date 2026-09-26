extends Node2D

@export var ShipControllerEvent : ShipControllerEventHandler
@export var Col : Color
@export var size : float = 10

var CamZoom = 1

func _draw() -> void:
	DrawRuller()

func DrawRuller() -> void:

	var LineW = 2 / CamZoom

	
	var vizrange = size

	for g in 3:
		draw_circle(Vector2.ZERO, vizrange / 3 * (g + 1), Color(100, 100, 100, 0.3), false, LineW, true)
	
	draw_circle(Vector2.ZERO, vizrange, Color(1.0, 0.616, 0.078, 1.0), false, LineW, true)

	var Next = rotation_degrees
	var Num = 90

	var Lines : PackedVector2Array

	for g in 12: 
		var LineStartPos = Vector2(vizrange / 3,0).rotated(deg_to_rad(Next))
		Lines.append(LineStartPos)
		var LineEndPos = Vector2(vizrange,0).rotated(deg_to_rad(Next))
		Lines.append(LineEndPos)
		
		Next -= 30
		var Text = "{0}".format([Num])
		Num = wrap(Num - 30, 0, 360)
		if (10/CamZoom > vizrange / 5):
			continue 
		#if (vizrange > 110):

		
		if (Text.length() == 0):
			continue
		var TextSize = roundi(min(10/CamZoom, vizrange / 10))
		if (TextSize <= 0):
			continue
		var StringSize = ThemeDB.fallback_font.get_string_size(Text, HORIZONTAL_ALIGNMENT_CENTER, -1, TextSize) / 2
		StringSize.y *= -0.5
		var StringOffset = LineStartPos.direction_to(LineEndPos) * TextSize
		#draw_string(ThemeDB.fallback_font, LineEndPos - StringSize + StringOffset + Vector2(5,5), Text, HORIZONTAL_ALIGNMENT_CENTER, -1, TextSize, Color(0,0,0))
		#draw_string(ThemeDB.fallback_font, LineEndPos - StringSize + StringOffset, Text, HORIZONTAL_ALIGNMENT_CENTER, -1, TextSize)
		
		
		#if Num == 0:
			#Num = 360

	draw_multiline(Lines, Color(100, 100, 100, 0.3), LineW, true)
