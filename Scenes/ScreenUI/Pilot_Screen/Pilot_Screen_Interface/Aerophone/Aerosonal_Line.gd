extends Control

class_name  AeroSonarLine
@export var OffsetAmmount : float
@export var Radius : float = 1.0
@export var ContactGr : Image
@export var CircleDivisions : int = 3
@export var N : NoiseTexture2D

var NoiseImage : Image
var NoiseOffset : float = 0.0
var Offset = 0.0

signal Found(Str : float)

func _ready() -> void:
	NoiseImage = N.get_image()
	N.changed.connect(NoiseChanged)

func NoiseChanged() -> void:
	NoiseImage = N.get_image()

func _physics_process(delta: float) -> void:
	Offset = wrap(Offset + (delta * 10), 0, 2)
	

func Update(Gr : Image) -> void:
	ContactGr = Gr
	queue_redraw()

func GetPointInCircle(Point : int, num_points : int = 20) -> Vector2:
	var angle = float(Point) / float(num_points) * PI * 2.0
	return Vector2(cos(angle), sin(angle))


func _draw() -> void:
	var PointAmm = size.x
	var MidPoint = size / 2
	
	var LastPoint : Vector2
	
	var CurrentOffset = roundi(Offset)
	
	var BiggestFind : float = 0
	
	#stored lines that will be drawn all together in the end
	var lines : PackedVector2Array

	for g in range(0, PointAmm):
		#we normalise the current point
		var m = Helper.normalize_value(g, 0, PointAmm)
		var NoiseUvX = wrap((m * NoiseImage.get_width()) + NoiseOffset, 0 , NoiseImage.get_width())
		var NoiseValue = NoiseImage.get_pixelv(Vector2i(NoiseUvX, 0)).r
		
		#add 0.5 to it to reverse it, for some reason angles are opposite
		var samplepos = wrap(m + 0.5, 0, 1)
		#Map is  within the gradient range, gradient is from 0.3, to 0.7
		var MappedSamplePos = Helper.mapvalue(samplepos, 0.3, 0.7)
		#Sample texture, multiply normalised value with texture width to get pixel
		
		var amm : float = ContactGr.get_pixelv(Vector2i(MappedSamplePos * ContactGr.get_width(), 0)).r * 2
		#amm = floor(amm)
		var mapped_value = 1 + ((g - 1) / (PointAmm)) / PointAmm
		var roundedmapped = roundi(mapped_value)
		
		var magnitude = amm - (mapped_value - roundedmapped + NoiseValue)

		var Dif : float = 0
		var Height = Radius + amm
		if (CurrentOffset == 0):
			Dif = clamp(OffsetAmmount * (magnitude + 1), 0, AeroSonar.MAX_GAIN)
			Height += Dif
		else : if (CurrentOffset == 2):
			Dif = clamp(OffsetAmmount * (magnitude + 1), 0, AeroSonar.MAX_GAIN)
			Height -= Dif
			
		if (Dif > BiggestFind and amm > 0):
			BiggestFind = Dif

		var NewPoint = GetPointInCircle(g, PointAmm - 1) + (size / 2)
		var offset = MidPoint.direction_to(NewPoint) * Height
		#NewPoint += offset
		if (g > 0):
			lines.append(LastPoint)
			lines.append(NewPoint + offset)
		LastPoint = NewPoint + offset
		CurrentOffset = wrap(CurrentOffset + 1, 0, 3)
		
		var v = roundi(wrap(samplepos - 0.25, 0, 1) * 100)
		var sampledin = roundi(samplepos * 100)
		if (!v % 10):
			var t = "{0}".format([snapped(v * 3.6, 10)])
			var stringsize = get_theme_default_font().get_string_size(t,HORIZONTAL_ALIGNMENT_FILL, -1, 7)
			var PointP = NewPoint - (NewPoint.direction_to(MidPoint) * (Radius / 2 + 9)) - Vector2(stringsize.x / 2, -3)
			draw_string(get_theme_default_font(), PointP, t, HORIZONTAL_ALIGNMENT_FILL, -1, 7, Color(1,0,0))

	for g in range(1, CircleDivisions + 1):
		var r = Radius / CircleDivisions
		r *= g
		draw_circle(MidPoint, r + 10, Color(1,0,0), false)
	
	NoiseOffset = randf_range(-1, 1)
	
	draw_multiline(lines, Color(1,0,0))
	
	if (BiggestFind > 3 and BiggestFind > OffsetAmmount):
		Found.emit(BiggestFind)
