extends Control

class_name ElingUI

@export var ShipControllerEvenH : ShipControllerEventHandler
@export_file var DirectionMaskFiles : Array[String]
@export_file("*.png") var DistanceMasks : Array[String]
@export_file("*.png") var OnOffTextures : Array[String]

@export_group("Nodes")
@export var RangeIndicator : PointLight2D
@export var AlertLight : PointLight2D
@export var DangerCloseLight : PointLight2D
@export var DirectionLight : PointLight2D
@export var ElintText : TextureRect
@export var BeepSound : AudioStreamPlayer2D

@export var Alarm : AudioStream
@export var Beep : AudioStream

var Lights : Array[Light2D] = []

var ConnectedShip : MapShip

var FoundContact : bool = false

var CurrentState : ELINTSTATE

enum ELINTSTATE{
	NONE,
	CLOSE,
	MEDIUM,
	FAR,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for g in get_children():
		if g is Light2D:
			Lights.append(g)
			g.visible = false
	
	UpdateConnectedShip(ShipControllerEvenH.CurrentControlled)
	ShipControllerEvenH.OnControlledShipChanged.connect(UpdateConnectedShip)
	#SetDirection(67)
	#SetDistance(800)

func ToggleElint(t : bool) -> void:
	if (t):
		var tex = ResourceLoader.load(OnOffTextures[0])
		ElintText.texture = tex
		set_physics_process(true)
		
	else:
		var tex = ResourceLoader.load(OnOffTextures[1])
		ElintText.texture = tex
		set_physics_process(false)
		
func UpdateConnectedShip(Sh : MapShip) -> void:
	ConnectedShip = Sh
	ToggleElint(Sh.Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0)
	#if Sh is Drone:
		#ToggleElint(Sh.Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT) > 0)
	#else :
		#ToggleElint(true)
		
var d = 0.4
func _physics_process(delta: float) -> void:
	#UpdateBasedOnMouse()
	
	d -= delta
	if (d > 0):
		return
	d = 0.6
	
	var Elint = ConnectedShip.GetClosestElintLevel()
	if (Elint < 0):
		#RangeIndicator.visible = false
		CurrentState = ELINTSTATE.NONE
		FoundContact = false
		for g in Lights:
			g.visible = false
		return
	else :
		if (!FoundContact):
			RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.ELINT_DETECTED)
		FoundContact = true
		#RangeIndicator.show()
		SetDirection(rad_to_deg(ConnectedShip.global_position.angle_to_point(ConnectedShip.GetClosestElint())) + 180)
		SetDistance(Elint)
	
	for g in Lights:
		g.visible = !g.visible
	
	if (CurrentState != ELINTSTATE.NONE):
		BeepSound.play()

func UpdateBasedOnMouse() -> void:
	var mpos = get_global_mouse_position()
	var pos = global_position + (size / 2)
	var ang = (rad_to_deg(pos.angle_to_point(mpos))) + 180
	SetDirection(ang)
	SetDistance(pos.distance_squared_to(mpos))

func SetDirection(dir : float) -> void:
	#print(dir)
	for g in DirectionMaskFiles.size():
		if (abs((g * 30) - dir) > 15):
			continue
		var tex : Texture2D = ResourceLoader.load(DirectionMaskFiles[roundi(g)])
		DirectionLight.set_texture(tex)
		break

static func DegreesToElintAngle(Deg : float) -> int:
	var dirs = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
	for g in dirs.size():
		if (abs(dirs[g] - Deg) > 15):
			continue
		return dirs[g]
	return 0
	
func SetDistance(dist : int) -> void:
	#var maxdist = ConnectedShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT)
	if (dist == 3):
		if (CurrentState != ELINTSTATE.CLOSE):
			CurrentState = ELINTSTATE.CLOSE
			var text = ResourceLoader.load(DistanceMasks[2])
			RangeIndicator.texture = text
			if (!Lights.has(DangerCloseLight)):
				Lights.append(DangerCloseLight)
			DangerCloseLight.visible = DirectionLight.visible
			BeepSound.stream = Alarm
			BeepSound.pitch_scale = 4
			
	else : if (dist == 2):
		if (CurrentState != ELINTSTATE.MEDIUM):
			CurrentState = ELINTSTATE.MEDIUM
			var text = ResourceLoader.load(DistanceMasks[1])
			RangeIndicator.texture = text
			Lights.erase(DangerCloseLight)
			DangerCloseLight.visible = false
			#$AudioStreamPlayer.playing = false
			BeepSound.stream = Beep
			BeepSound.pitch_scale = 1
			
	else :
		if (CurrentState != ELINTSTATE.FAR):
			CurrentState = ELINTSTATE.FAR
			var text = load(DistanceMasks[0])
			RangeIndicator.texture = text
			Lights.erase(DangerCloseLight)
			DangerCloseLight.visible = false
			BeepSound.stream = Beep
			BeepSound.pitch_scale = 1
			#$AudioStreamPlayer.playing = false
	
