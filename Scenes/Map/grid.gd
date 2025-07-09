extends ColorRect

@export var Col : Color
@export var ZoomLevel = 1.0
var Offset : Vector2

#func _physics_process(delta: float) -> void:
	#queue_redraw()

func UpdateOffset(NewOffset : Vector2) -> void:
	Offset = NewOffset
	queue_redraw()

func UpdateZoom(NewZoom : float) -> void:
	ZoomLevel = NewZoom
	queue_redraw()

func _draw() -> void:
	var Lines : Dictionary[Vector2, float]
	
	var Siz = roundi(size.x / 10000)
	
	while Offset.x > size.x / Siz:
		Offset.x -= size.x / Siz
	while Offset.y > size.y / Siz:
		Offset.y -= size.y / Siz
		
	while Offset.x < 0:
		Offset.x += size.x / Siz
	while Offset.y < 0:
		Offset.y += size.y / Siz
	
	#while Offset < Vector2.ZERO:
		#Offset += size
	
	for Hundread in range(0, Siz):
		var XPos = ((size.x / Siz) * Hundread) - Offset.x
		var YPos = ((size.y / Siz) * Hundread) - Offset.y
		
		var DrawHundreadLine = ZoomLevel < 0.15 and Hundread > 0
		
		if (DrawHundreadLine):
			draw_line(Vector2(XPos, 0), Vector2(XPos, size.y), Col, 100 - (ZoomLevel * 200), true)
			
			draw_line(Vector2(0, YPos), Vector2(size.x, YPos), Col, 100 - (ZoomLevel * 200), true)

		for Ten in range(0, 10):
			var XPosT = XPos + (size.x / (Siz * 10)) * Ten
			var YPosT = YPos + (size.y / (Siz * 10)) * Ten
			
			var DrawTenLine = true
			
			if (DrawTenLine and Ten == 0):
				DrawTenLine = !DrawHundreadLine

			if (DrawTenLine):
				draw_line(Vector2(XPosT, 0), Vector2(XPosT, size.y), Col, max(8, 40 - (ZoomLevel * 80)), true)
				
				draw_line(Vector2(0, YPosT), Vector2(size.x, YPosT), Col, max(8, 40 - (ZoomLevel * 80)), true)
		
			
			for One in range(0, 10):
				
				var XPosO = XPosT + (size.x / (Siz * 100)) * One
				var YPosO = YPosT + (size.y / (Siz * 100)) * One
				
				
				var DrawOneLine = ZoomLevel > 0.15
				
				if (DrawOneLine and One == 0):
					DrawOneLine = !DrawTenLine
				
				if (DrawOneLine):
				
					draw_line(Vector2(XPosO, 0), Vector2(XPosO, size.y), Col, max(2, 10 - (ZoomLevel * 20)), true)
					
					draw_line(Vector2(0, YPosO), Vector2(size.x, YPosO), Col, max(2, 10 - (ZoomLevel * 20)), true)
		
