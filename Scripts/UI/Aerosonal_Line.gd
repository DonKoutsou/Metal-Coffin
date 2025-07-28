extends Control

class_name  AeroSonarLine
@export var OffsetAmmount : float

var Offset = 0.0

#var Controller : PlayerDrivenShip

@export var Contacts : Dictionary[int, float]

var CurrentA : float

signal Found(Str : float)

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
	
	var MidPoint = size.y / 2
	#var HighPoint = (MidPoint) + OffsetAmmount
	#var LowPoint = (MidPoint) - OffsetAmmount
	
	var LastPoint = Vector2(0, MidPoint)
	
	var CurrentOffset = roundi(Offset)
	#var ascending : bool = true
	
	var BiggestFind : float = 0
	
	for g in range(1, PointAmm + 1):
		
		var mapped_value = 1 + ((g - 1) / (PointAmm - 1)) * 44
		var roundedmapped = roundi(mapped_value)
		
		var amm = 0
		if (Contacts.has(roundedmapped)):
			amm = Contacts[roundedmapped]
			
			#if (amm * 20 < OffsetAmmount):
				#amm = 0
		var magnitude = amm - (mapped_value - roundedmapped)
		#var l = Helper.UpDownLerp(PointAmm, g)
		#magnitude *= l
		#print(mapped_value)
		var Dif : float = 0
		var Height = MidPoint
		if (CurrentOffset == 0):
			Dif = clamp(OffsetAmmount * (magnitude + 1), 0, 20)
			Height += Dif
		else : if (CurrentOffset == 2):
			Dif = clamp(OffsetAmmount * (magnitude + 1), 0, 20)
			Height -= Dif
		if (Dif > BiggestFind and amm > 0):
			BiggestFind = Dif
		
		#Height += Contacts.count(g)
		#Height += (CurrentOffset2 - 5) * Offset2Ammount
		
		
		var NewPoint = Vector2(Step * g, Height)
		draw_line(LastPoint, NewPoint, Color(1,0,0))
		LastPoint = NewPoint
		CurrentOffset = wrap(CurrentOffset + 1, 0, 3)
		
		
		if (!g % 25):
			var v = wrap(roundi(rad_to_deg(CurrentA) - roundedmapped) + 25, 0, 360)
			draw_string(get_theme_default_font(), Vector2(Step * g, 10), var_to_str(v), HORIZONTAL_ALIGNMENT_FILL, -1, 5, Color(1,0,0))
	
	if (BiggestFind > 3 and BiggestFind > OffsetAmmount):
		Found.emit(BiggestFind)
