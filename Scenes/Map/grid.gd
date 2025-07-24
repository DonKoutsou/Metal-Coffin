extends Control

class_name MapGrid

@export var Col : Color
@export var ZoomLevel = 1.0
@export var EventHandler : UIEventHandler
var Offset : Vector2

#func _physics_process(delta: float) -> void:
	#queue_redraw()

func _ready() -> void:
	EventHandler.GridPressed.connect(ToggleGrid)

func ToggleGrid() -> void:
	visible = !visible

func UpdateOffset(NewOffset : Vector2) -> void:
	Offset = NewOffset
	queue_redraw()

func UpdateCameraZoom(NewZoom : float) -> void:
	ZoomLevel = NewZoom
	queue_redraw()

func _draw() -> void:
	var Lines : Dictionary[Vector2, float]
	
	var Siz = roundi(size.x / 10000)
	
	var xmulti = 0
	var ymulti = 0
	
	var campos = ShipCamera.GetInstance().global_position
	var vpmin = (campos - (get_viewport_rect().size / 2 / ZoomLevel))
	var vpmax = (campos + (get_viewport_rect().size / 2 / ZoomLevel))

	Offset.x = wrap(Offset.x, -(size.x / Siz), size.x / Siz)
	Offset.y = wrap(Offset.y, -(size.y / Siz), size.y / Siz)
	
	var stringsdrew = 0
	
	for Hundread in range(0, Siz):
		
		var XPos = ((size.x / Siz) * Hundread) - Offset.x
		var YPos = ((size.y / Siz) * Hundread) - Offset.y
		
		var DrawHundreadLine = ZoomLevel < 0.15 and Hundread > 0
		
		if (DrawHundreadLine):
			draw_line(Vector2(XPos, 0), Vector2(XPos, size.y), Color(0,0,0,0.3), max(8, 40 - (ZoomLevel * 80)), true)
			draw_line(Vector2(0, YPos), Vector2(size.x, YPos), Color(0,0,0,0.3), max(8, 40 - (ZoomLevel * 80)), true)
			
			
			#var text_pos = Vector2(XPos + 30, YPos - 50)  # Slight offset for visibility relative to the grid square
			#var globpos = global_position + Vector2(XPos, YPos)
			#var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x) / 1000, roundi(globpos.y)/ 1000])
#
			#draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 300, Color(1,1,1, 0.1))
			#stringsdrew += 1
			
		for Ten in 10:
			var XPosT = XPos + (size.x / (Siz * 10)) * Ten
			
			var globalXPos = global_position.x + XPosT
			var drawx = globalXPos > vpmin.x and globalXPos < vpmax.x
			
			var YPosT = YPos + (size.y / (Siz * 10)) * Ten
			
			var globalyPos = global_position.y + YPosT
			var drawy = globalyPos > vpmin.y and globalyPos < vpmax.y
			#
			#if (globalyPos < vpmin.y or globalyPos > vpmax.y):
				#continue
			#if (!drawx and !drawy):
				#continue
			
			var DrawTenLine = ZoomLevel < 0.8
			
			
			if (DrawTenLine and ZoomLevel > 0.08):
				for g in range(-10,20):
					#if (g == 0 and Ten == 0):
						#continue
					
					var ything = YPos + ((size.y / (Siz * 10)) * g)
					var text_pos = Vector2(XPosT + 10, ything - 20)  # Slight offset for visibility relative to the grid square
					var globpos = global_position + Vector2(XPosT, ything)
					var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x)/ 1000, roundi(globpos.y) / 1000])
					
					var globaltextpos = global_position + text_pos
					if (globaltextpos.x < vpmin.x or globaltextpos.x > vpmax.x or globaltextpos.y < vpmin.y or globaltextpos.y > vpmax.y):
						continue
					
				# Adjust drawing to consider the color and font setup
					draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 100, Color(1,1,1, 0.2))
					stringsdrew += 1
			
			if (DrawHundreadLine and Ten == 0):
				DrawTenLine = !DrawHundreadLine

			if (DrawTenLine):
				if (drawx):
					draw_line(Vector2(XPosT, 0), Vector2(XPosT, size.y), Col, max(8, 40 - (ZoomLevel * 80)), true)
				if (drawy):
					draw_line(Vector2(0, YPosT), Vector2(size.x, YPosT), Col, max(8, 40 - (ZoomLevel * 80)), true)
					
			if (ZoomLevel < 0.15):
				continue
			for One in range(0, 10):
				
				var XPosO = XPosT + (size.x / (Siz * 100)) * One
				var globalXPosO = global_position.x + XPosO
				
				var YPosO = YPosT + (size.y / (Siz * 100)) * One
				var globalYPosO = global_position.y + YPosO
				
				var drawxO = globalXPosO > vpmin.x and globalXPosO < vpmax.x
				var drawyO = globalYPosO > vpmin.y and globalYPosO < vpmax.y
				
				if (!drawxO and !drawyO):
					continue
				
				var DrawOneLine = true
				
				if (DrawOneLine and One == 0):
					DrawOneLine = !DrawTenLine
				
				if (DrawOneLine):
					if (drawxO):
						draw_line(Vector2(XPosO, 0), Vector2(XPosO, size.y), Col, max(2, 10 - (ZoomLevel * 20)), true)
					if (drawyO):
						draw_line(Vector2(0, YPosO), Vector2(size.x, YPosO), Col, max(2, 10 - (ZoomLevel * 20)), true)
				
				if (ZoomLevel < 0.8):
					continue
				for g in range(-100,100):
					if (DrawTenLine and g == 0 and One == 0):
						continue
					
					var ything = YPosT + ((size.y / (Siz * 100)) * g)
					var text_pos = Vector2(XPosO + 3, ything - 5)  # Slight offset for visibility relative to the grid square
					var globpos = global_position + Vector2(XPosO, ything)
					var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x)/ 100, roundi(globpos.y) / 100])
					
					var globaltextpos = global_position + text_pos
					if (globaltextpos.x < vpmin.x or globaltextpos.x > vpmax.x or globaltextpos.y < vpmin.y or globaltextpos.y > vpmax.y):
						continue
					
				# Adjust drawing to consider the color and font setup
					draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1, 0.2))
					stringsdrew += 1
	print("draw {0} strings".format([stringsdrew]))
