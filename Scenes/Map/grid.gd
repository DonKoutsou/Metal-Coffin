extends Control

class_name MapGrid

@export var Col : Color
@export var ZoomLevel = 1.0
@export var EventHandler : UIEventHandler
var Offset : Vector2

var M : Mutex
#func _physics_process(delta: float) -> void:
	#queue_redraw()

func _ready() -> void:
	M = Mutex.new()
	EventHandler.GridPressed.connect(ToggleGrid)

func ToggleGrid(t : bool) -> void:
	visible = t

func UpdateOffset(NewOffset : Vector2) -> void:
	Offset = NewOffset
	ReprocessLines()

func UpdateCameraZoom(NewZoom : float) -> void:
	ZoomLevel = NewZoom
	ReprocessLines()


func ReprocessLines() -> void:
	var T = Thread.new()
	T.start(UpdateLines.bind(global_position, size, get_viewport_rect().size, ShipCamera.GetInstance().global_position, T))
	

var TLines : Array[Array]
var TLines2 : Array[Array]
var TStrings : Dictionary[String, Vector2]
var TStrings2 : Dictionary[String, Vector2]
var TStrings3 : Dictionary[String, Vector2]

func UpdateLines(ContainerPos : Vector2, ContainerSize : Vector2, VPSize : Vector2, campos : Vector2, T : Thread) -> void:
	var Lines : Array[Array]
	var Lines2 : Array[Array]
	var Strings : Dictionary[String, Vector2]
	var Strings2 : Dictionary[String, Vector2]
	var Strings3 : Dictionary[String, Vector2]
	
	var Siz = roundi(ContainerSize.x / 10000)
	
	#var xmulti = 0
	#var ymulti = 0

	var vpmin = (campos - (VPSize / 2 / ZoomLevel))
	var vpmax = (campos + (VPSize / 2 / ZoomLevel))

	Offset.x = wrap(Offset.x, -(ContainerSize.x / Siz), ContainerSize.x / Siz)
	Offset.y = wrap(Offset.y, -(ContainerSize.y / Siz), ContainerSize.y / Siz)
	
	#var stringsdrew = 0
	
	for Hundread in range(0, Siz):
		
		var XPos = ((ContainerSize.x / Siz) * Hundread) - Offset.x
		var YPos = ((ContainerSize.y / Siz) * Hundread) - Offset.y
		
		var DrawHundreadLine = ZoomLevel < 0.15 and Hundread > 0
		
		if (DrawHundreadLine):
			Lines.append([Vector2(XPos, 0), Vector2(XPos, ContainerSize.y)])
			Lines.append([Vector2(0, YPos), Vector2(ContainerSize.x, YPos)])
			#draw_line(Vector2(XPos, 0), Vector2(XPos, size.y), Color(0,0,0,0.3), max(8, 40 - (ZoomLevel * 80)), true)
			#draw_line(Vector2(0, YPos), Vector2(size.x, YPos), Color(0,0,0,0.3), max(8, 40 - (ZoomLevel * 80)), true)
			
			#var text_pos = Vector2(XPos + 30, YPos - 50)  # Slight offset for visibility relative to the grid square
			#var globpos = global_position + Vector2(XPos, YPos)
			#var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x) / 1000, roundi(globpos.y)/ 1000])
#
			#draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 300, Color(1,1,1, 0.1))
			#stringsdrew += 1
			
		for Ten in 10:
			var XPosT = XPos + (ContainerSize.x / (Siz * 10)) * Ten
			
			var globalXPos = ContainerPos.x + XPosT
			var drawx = globalXPos > vpmin.x and globalXPos < vpmax.x
			
			var YPosT = YPos + (ContainerSize.y / (Siz * 10)) * Ten
			
			var globalyPos = ContainerPos.y + YPosT
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
					
					var ything = YPos + ((ContainerSize.y / (Siz * 10)) * g)
					var text_pos = Vector2(XPosT + 10, ything - 20)  # Slight offset for visibility relative to the grid square
					var globpos = ContainerPos + Vector2(XPosT, ything)
					var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x)/ 1000, roundi(globpos.y) / 1000])
					
					var globaltextpos = ContainerPos + text_pos
					if (globaltextpos.x < vpmin.x or globaltextpos.x > vpmax.x or globaltextpos.y < vpmin.y or globaltextpos.y > vpmax.y):
						continue
					
				# Adjust drawing to consider the color and font setup
					Strings2[coordinate_text] = text_pos
					#draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 100, Color(1,1,1, 0.2))
					#stringsdrew += 1
			
			if (DrawHundreadLine and Ten == 0):
				DrawTenLine = !DrawHundreadLine

			if (DrawTenLine):
				if (drawx):
					Lines.append([Vector2(XPosT, 0), Vector2(XPosT, ContainerSize.y)])
					#draw_line(Vector2(XPosT, 0), Vector2(XPosT, size.y), Col, max(8, 40 - (ZoomLevel * 80)), true)
				if (drawy):
					Lines.append([Vector2(0, YPosT), Vector2(ContainerSize.x, YPosT)])
					#draw_line(Vector2(0, YPosT), Vector2(size.x, YPosT), Col, max(8, 40 - (ZoomLevel * 80)), true)
					
			if (ZoomLevel < 0.15):
				continue
			for One in range(0, 10):
				
				var XPosO = XPosT + (ContainerSize.x / (Siz * 100)) * One
				var globalXPosO = ContainerPos.x + XPosO
				
				var YPosO = YPosT + (ContainerSize.y / (Siz * 100)) * One
				var globalYPosO = ContainerPos.y + YPosO
				
				var drawxO = globalXPosO > vpmin.x and globalXPosO < vpmax.x
				var drawyO = globalYPosO > vpmin.y and globalYPosO < vpmax.y
				
				if (!drawxO and !drawyO):
					continue
				
				var DrawOneLine = true
				
				if (DrawOneLine and One == 0):
					DrawOneLine = !DrawTenLine
				
				if (DrawOneLine):
					if (drawxO):
						Lines2.append([Vector2(XPosO, 0), Vector2(XPosO, ContainerSize.y)])
						#draw_line(Vector2(XPosO, 0), Vector2(XPosO, size.y), Col, max(2, 10 - (ZoomLevel * 20)), true)
					if (drawyO):
						Lines2.append([Vector2(0, YPosO), Vector2(ContainerSize.x, YPosO)])
						#draw_line(Vector2(0, YPosO), Vector2(size.x, YPosO), Col, max(2, 10 - (ZoomLevel * 20)), true)
				
				if (ZoomLevel < 0.8):
					continue
				for g in range(-100,100):
					if (DrawTenLine and g == 0 and One == 0):
						continue
					
					var ything = YPosT + ((ContainerSize.y / (Siz * 100)) * g)
					var text_pos = Vector2(XPosO + 3, ything - 5)  # Slight offset for visibility relative to the grid square
					var globpos = ContainerPos + Vector2(XPosO, ything)
					var coordinate_text = "X{0}Y{1}".format([roundi(globpos.x)/ 100, roundi(globpos.y) / 100])
					
					var globaltextpos = ContainerPos + text_pos
					if (globaltextpos.x < vpmin.x or globaltextpos.x > vpmax.x or globaltextpos.y < vpmin.y or globaltextpos.y > vpmax.y):
						continue
					
				# Adjust drawing to consider the color and font setup
					Strings3[coordinate_text] = text_pos
					#draw_string(get_theme_default_font(), text_pos, coordinate_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1, 0.2))
					#stringsdrew += 1
	#print("draw {0} strings".format([stringsdrew]))
	M.lock()
	TLines.clear()
	TLines.append_array(Lines)
	TLines2.clear()
	TLines2.append_array(Lines2)
	TStrings.clear()
	TStrings.assign(Strings)
	TStrings2.clear()
	TStrings2.assign(Strings2)
	TStrings3.clear()
	TStrings3.assign(Strings3)
	M.unlock()
	call_deferred("LinesUpdateFinished", T)
	
func LinesUpdateFinished(T : Thread) -> void:
	T.wait_to_finish()
	queue_redraw()

func _draw() -> void:
	for g in TLines:
		draw_line(g[0], g[1], Col, max(8, 40 - (ZoomLevel * 80)), true)
	for g in TLines2:
		draw_line(g[0], g[1], Col, max(2, 10 - (ZoomLevel * 20)), true)
	for g in TStrings:
		draw_string(get_theme_default_font(), TStrings[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 300, Color(1,1,1, 0.2))
	for g in TStrings2:
		draw_string(get_theme_default_font(), TStrings2[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 100, Color(1,1,1, 0.2))
	for g in TStrings3:
		draw_string(get_theme_default_font(), TStrings3[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1, 0.2))
