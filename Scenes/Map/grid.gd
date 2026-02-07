extends Control

class_name MapGrid

@export var Col : Color
@export var AxisColor : Color
@export var ZoomLevel = 1.0
@export var EventHandler : UIEventHandler
var Offset : Vector2

var FreeLabels : Array[RichTextLabel]
var UsedLabels : Array[RichTextLabel]

var M : Mutex
var S : Semaphore

var Dissabled : bool = false
#func _physics_process(delta: float) -> void:
	#queue_redraw()

func _ready() -> void:
	M = Mutex.new()
	EventHandler.GridPressed.connect(ToggleGrid)



func CreateRichText() -> RichTextLabel:
	var L = RichTextLabel.new()
	L.fit_content = true
	L.bbcode_enabled = true
	L.use_parent_material = true
	L.autowrap_mode = TextServer.AUTOWRAP_OFF
	L.modulate = Color(1,1,1, 0.2)
	L.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	FreeLabels.append(L)
	call_deferred("add_child", L)
	#add_child(L)
	return L

func ResetLabels() -> void:
	for g in range(UsedLabels.size() - 1, -1, -1):
		ToggleLabelUsed(UsedLabels[g], false)

func HideUnused() -> void:
	for g in FreeLabels:
		g.call_deferred("hide")

func ToggleLabelUsed(L : RichTextLabel, t : bool) -> void:
	if (t):
		UsedLabels.append(L)
		FreeLabels.erase(L)
	else:
		FreeLabels.append(L)
		UsedLabels.erase(L)

func GetFreeLabel() -> RichTextLabel:
	var L = FreeLabels.pop_back()
	if (L == null):
		L = CreateRichText()
	L.call_deferred("show")
	return L

func ToggleGrid(t : bool) -> void:
	Dissabled = !t
	visible = t
	if (t):
		ReprocessLines()

func UpdateOffset(NewOffset : Vector2) -> void:
	Offset = NewOffset
	if (visible):
		ReprocessLines()

func UpdateCameraZoom(NewZoom : float) -> void:
	ZoomLevel = NewZoom
	#ReprocessLines()


func ReprocessLines() -> void:
	var T = Thread.new()
	T.start(UpdateLines.bind(global_position, size, get_viewport_rect().size, ShipCamera.GetInstance().global_position, T))
	

var Threads : int = 0

var TLines : PackedVector2Array
var TLines2 : PackedVector2Array
var TLines3 : PackedVector2Array
var TStrings : Dictionary[String, Vector2]
var TStrings2 : Dictionary[String, Vector2]
var TStrings3 : Dictionary[String, Vector2]

func UpdateLines(ContainerPos : Vector2, ContainerSize : Vector2, VPSize : Vector2, campos : Vector2, T : Thread) -> void:
	M.lock()
	Threads += 1
	M.unlock()
	var Lines : PackedVector2Array
	var Lines2 : PackedVector2Array
	var Lines3 : PackedVector2Array
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
			Lines.append(Vector2(XPos, 0))
			Lines.append(Vector2(XPos, ContainerSize.y))
			Lines.append(Vector2(0, YPos))
			Lines.append(Vector2(ContainerSize.x, YPos))
			var text_pos = Vector2(XPos + 30, YPos - 50)  # Slight offset for visibility relative to the grid square
			var globpos = ContainerPos + Vector2(XPos, YPos)
			var coordinate_text = "[color=#ffc315]X[/color]{0}[color=#ffc315]Y[/color]{1}".format([roundi(globpos.x/ 100.0) + 50, roundi(globpos.y / 100.0) + 50])
			Strings[coordinate_text] = text_pos

			
		for Ten in 10:
			var XPosT = XPos + (ContainerSize.x / (Siz * 10)) * Ten
			
			var globalXPos = ContainerPos.x + XPosT
			var drawx = globalXPos > vpmin.x and globalXPos < vpmax.x
			
			var YPosT = YPos + (ContainerSize.y / (Siz * 10)) * Ten
			
			var globalyPos = ContainerPos.y + YPosT
			var drawy = globalyPos > vpmin.y and globalyPos < vpmax.y
			
			var DrawTenLine = ZoomLevel < 0.8

			if (DrawTenLine):
				if (drawx):
					Lines2.append(Vector2(XPosT, 0))
					Lines2.append(Vector2(XPosT, ContainerSize.y))
				if (drawy):
					Lines2.append(Vector2(0, YPosT))
					Lines2.append(Vector2(ContainerSize.x, YPosT))
			if (ZoomLevel < 0.1):
				continue
				
			if (DrawTenLine):
				for g in range(-10,20):
					if (DrawHundreadLine and g == 0 and Ten == 0):
						continue
					var ything = YPos + ((ContainerSize.y / (Siz * 10.0)) * g)
					var text_pos = Vector2(XPosT + 10, ything - 20)  # Slight offset for visibility relative to the grid square
					var globpos = ContainerPos + Vector2(XPosT, ything)
					var coordinate_text = "[color=#ffc315]X[/color]{0}[color=#ffc315]Y[/color]{1}".format([roundi(globpos.x/ 100.0) + 50, roundi(globpos.y / 100.0) + 50])
					
					var globaltextpos = ContainerPos + text_pos
					
					var DrawXTex = globaltextpos.x > vpmin.x and globaltextpos.x < vpmax.x 
					var DrawTTen = globaltextpos.y > vpmin.y and globaltextpos.y < vpmax.y
					
					if (!DrawXTex and !DrawTTen):
						continue

					Strings2[coordinate_text] = text_pos
					
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
						Lines3.append(Vector2(XPosO, 0))
						Lines3.append(Vector2(XPosO, ContainerSize.y))
					if (drawyO):
						Lines3.append(Vector2(0, YPosO))
						Lines3.append(Vector2(ContainerSize.x, YPosO))
				if (ZoomLevel < 0.8):
					continue
				for g in range(-100,100):
					if (DrawTenLine and g == 0 and One == 0):
						continue
					
					var ything = YPosT + ((ContainerSize.y / (Siz * 100.0)) * g)
					var text_pos = Vector2(XPosO + 3, ything - 5)  # Slight offset for visibility relative to the grid square
					var globpos = ContainerPos + Vector2(XPosO, ything)
					var coordinate_text = "[color=#ffc315]X[/color]{0}[color=#ffc315]Y[/color]{1}".format([roundi(globpos.x/ 100.0) + 50, roundi(globpos.y / 100.0) + 50])
					
					var globaltextpos = ContainerPos + text_pos
					if (globaltextpos.x < vpmin.x or globaltextpos.x > vpmax.x or globaltextpos.y < vpmin.y or globaltextpos.y > vpmax.y):
						continue

					Strings3[coordinate_text] = text_pos

	M.lock()
	if (Threads > 1):
		#a thread recalculating everything has already started so we cancel this
		Threads -= 1
		M.unlock()
		call_deferred("LinesUpdateAborted", T)
		return
	#print("Thread amm : {0}".format([Threads]))
	TLines = Lines
	TLines2 = Lines2
	TLines3 = Lines3
	TStrings = Strings
	TStrings2 = Strings2
	TStrings3 = Strings3
	ResetLabels()
	UpdateStrings()
	HideUnused()
	Threads -= 1
	M.unlock()
	call_deferred("LinesUpdateFinished", T)
	

func UpdateStrings() -> void:
	for g in TStrings:
		var L = GetFreeLabel()
		L.call_deferred("set_position", TStrings[g] - Vector2(0,300))
		L.call_deferred("set", "text","[font_size=300]" + g)
		ToggleLabelUsed(L, true)
		#draw_string(get_theme_default_font(), TStrings[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 300, Color(1,1,1, 0.2))
	for g in TStrings2:
		var L = GetFreeLabel()
		L.call_deferred("set_position", TStrings2[g] - Vector2(0,100))
		L.call_deferred("set", "text","[font_size=100]" + g)
		ToggleLabelUsed(L, true)
		#draw_string(get_theme_default_font(), TStrings2[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 100, Color(1,1,1, 0.2))
	for g in TStrings3:
		var L = GetFreeLabel()
		L.call_deferred("set_position", TStrings3[g] - Vector2(0,10))
		L.call_deferred("set", "text","[font_size=10]" + g)
		ToggleLabelUsed(L, true)
		#draw_string(get_theme_default_font(), TStrings3[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1, 0.2))


#func _physics_process(_delta: float) -> void:
	#
	#for g in 10:
		#var stringtorender : String
		#var pos : Vector2
		#var fontsize : String
		#M.lock()
		#if (TStrings.size() > 0):
			#stringtorender = TStrings.keys()[TStrings.keys().size() - 1]
			#pos = TStrings[stringtorender] - Vector2(0,300)
			#fontsize = "[font_size=300]"
			#TStrings.erase(stringtorender)
		#else: if (TStrings2.size() > 0):
			#stringtorender = TStrings2.keys()[TStrings2.keys().size() - 1]
			#pos = TStrings2[stringtorender] - Vector2(0,100)
			#fontsize = "[font_size=100]"
			#TStrings2.erase(stringtorender)
		#else: if (TStrings3.size() > 0):
			#stringtorender = TStrings3.keys()[TStrings3.keys().size() - 1]
			#pos = TStrings3[stringtorender] - Vector2(0,10)
			#fontsize = "[font_size=10]"
			#TStrings3.erase(stringtorender)
		#else:
			#M.unlock()
			#return
		#
		#var L = GetFreeLabel()
		#L.position = pos
		#L.text = fontsize + stringtorender
		#ToggleLabelUsed(L, true)
		#M.unlock()

func LinesUpdateAborted(T : Thread) -> void:
	T.wait_to_finish()

func LinesUpdateFinished(T : Thread) -> void:
	T.wait_to_finish()
	queue_redraw()

func _draw() -> void:
	M.lock()
	#for g in TLines:
	if (TLines.size() > 0):
		draw_multiline(TLines, Col, max(16, 80 - (ZoomLevel * 160)), true)
	#for g in TLines2:
	if (TLines2.size() > 0):
		draw_multiline(TLines2, Col, max(8, 40 - (ZoomLevel * 80)), true)
		#draw_line(g[0], g[1], Col, max(8, 40 - (ZoomLevel * 80)), true)
	#for g in TLines3:
	if (TLines3.size() > 0):
		draw_multiline(TLines3, Col, max(2, 10 - (ZoomLevel * 20)), true)
		#draw_line(g[0], g[1], Col, max(2, 10 - (ZoomLevel * 20)), true)
	M.unlock()
	
	#for g in TStrings:
		#var L = GetFreeLabel()
		#L.position = TStrings[g] - Vector2(0,300)
		#L.text = "[font_size=300]" + g
		#ToggleLabelUsed(L, true)
		##draw_string(get_theme_default_font(), TStrings[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 300, Color(1,1,1, 0.2))
	#for g in TStrings2:
		#var L = GetFreeLabel()
		#L.position = TStrings2[g] - Vector2(0,100)
		#L.text = "[font_size=100]" + g
		#ToggleLabelUsed(L, true)
		##draw_string(get_theme_default_font(), TStrings2[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 100, Color(1,1,1, 0.2))
	#for g in TStrings3:
		#var L = GetFreeLabel()
		#L.position = TStrings3[g] - Vector2(0,10)
		#L.text = "[font_size=10]" + g
		#ToggleLabelUsed(L, true)
		#draw_string(get_theme_default_font(), TStrings3[g], g, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1, 0.2))
	
	
