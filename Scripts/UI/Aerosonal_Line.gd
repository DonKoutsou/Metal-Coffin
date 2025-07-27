@tool
extends Control

class_name  AeroSonarLine
@export var OffsetAmmount : float

var Offset = 0.0

var Controller : PlayerDrivenShip

@export var Contacts : Dictionary[int, float]

var CurrentA : float

func _physics_process(delta: float) -> void:
	Offset = wrap(Offset + (delta * 10), 0, 2)
	queue_redraw()

func Update(NewContacts : Dictionary[int, float], CurrentAngle : float) -> void:
	Contacts.clear()
	Contacts.assign(NewContacts)
	CurrentA = CurrentAngle

func _draw() -> void:
	
	var PointAmm = size.x
	var Step = size.x / PointAmm
	
	var MidPoint = size.y / 2 + 5
	var HighPoint = (MidPoint) + OffsetAmmount
	var LowPoint = (MidPoint) - OffsetAmmount
	
	var LastPoint = Vector2(0, MidPoint)
	
	var CurrentOffset = roundi(Offset)
	var ascending : bool = true
	
	
	
	for g in range(1, PointAmm + 1):
		
		var mapped_value = 1 + ((g - 1) / (PointAmm - 1)) * (45 - 1)
		var roundedmapped = roundi(mapped_value)
		
		var amm = 0
		if (Contacts.has(roundedmapped)):
			amm = Contacts[roundedmapped]
		var magnitude = min(amm - (mapped_value - roundedmapped), 3)
		#print(mapped_value)
		
		var Height = MidPoint
		if (CurrentOffset == 0):
			Height += OffsetAmmount * magnitude + 1
		else : if (CurrentOffset == 2):
			Height -= OffsetAmmount * magnitude + 1
		
		#Height += Contacts.count(g)
		#Height += (CurrentOffset2 - 5) * Offset2Ammount
		
		
		var NewPoint = Vector2(Step * g, Height)
		draw_line(LastPoint, NewPoint, Color(1,0,0))
		LastPoint = NewPoint
		CurrentOffset = wrap(CurrentOffset + 1, 0, 3)
		
		if (!g % 25):
			var v = wrap(roundi(rad_to_deg(CurrentA) - roundedmapped) + 25, 0, 360)
			draw_string(get_theme_default_font(), Vector2(Step * g, 15), var_to_str(v), HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(1,0,0))
