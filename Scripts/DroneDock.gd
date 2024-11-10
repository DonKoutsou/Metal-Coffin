extends Area2D
class_name DroneDock
@export var DroneScene : PackedScene

@export var DroneDockEventH : DroneDockEventHandler

@export var LandedVoiceLines : Array[AudioStream]
@export var ReturnVoiceLines : Array[AudioStream]
@export var TakeoffVoiceLines : Array[AudioStream]

var DockedDrones : Array[Drone]
var FlyingDrones : Array[Drone]

func _ready() -> void:
	$Line2D.visible = false
	DroneDockEventH.connect("OnDroneDirectionChanged", DroneAimDirChanged)
	DroneDockEventH.connect("OnDroneArmed", DroneArmed)
	DroneDockEventH.connect("OnDroneDissarmed", DroneDissarmed)
	DroneDockEventH.connect("DroneLaunched", LaunchDrone)
	DroneDockEventH.connect("DroneRangeChanged", DroneRangeChanged)
	for g in 2:
		var drone = DroneScene.instantiate()
		call_deferred("AddDroneToHierarchy",drone)
		
func PlayLandingSound()-> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = LandedVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()
func PlayReturnSound() -> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = ReturnVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()	

func PlayTakeoffSound() -> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = TakeoffVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()	
	
func SoundEnded() -> void:
	for g in $Sounds.get_child_count():
		if (!($Sounds.get_child(g) as AudioStreamPlayer).playing):
			$Sounds.get_child(g).queue_free()
			return
		
func DroneArmed() -> void:
	$Line2D.visible = true

func DroneDissarmed() -> void:
	$Line2D.visible = false

func DroneAimDirChanged(NewDir : float) -> void:
	$Line2D.rotation = NewDir / 10
	
func DroneRangeChanged(NewRange : float) -> void:
	$Line2D.set_point_position(1, Vector2(NewRange * 80, 0))
	print(NewRange)
	
func LaunchDrone() -> void:
	if (DockedDrones.size() == 0):
		return
	var fueltoconsume = $Line2D.get_point_position(1).x / 160
	if (ShipData.GetInstance().GetStat("FUEL").CurrentVelue < fueltoconsume):
		return
	ShipData.GetInstance().ConsumeResource("FUEL", fueltoconsume)
	PlayTakeoffSound()
	var drone = DockedDrones[0]
	UndockDrone(drone)
	drone.global_rotation = $Line2D.global_rotation
	drone.global_position = global_position
	drone.Fuel = $Line2D.get_point_position(1).x
	
	drone.EnableDrone()
func AddDroneToHierarchy(drone : Drone):
	get_parent().get_parent().add_child(drone)
	DockDrone(drone)
	DroneDockEventH.OnDroneAdded(drone)


func DockDrone(drone : Drone, playsound : bool = false):
	if (playsound):
		PlayLandingSound()
	FlyingDrones.erase(drone)
	DockedDrones.append(drone)
	
	if (drone.Fuel > 0):
		ShipData.GetInstance().RefilResource("FUEL", drone.Fuel / 160)
		drone.Fuel = 0
	
	DroneDockEventH.OnDroneDocked(drone)
	
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			continue
		var dock = docks[g]
		var trans = RemoteTransform2D.new()
		dock.add_child(trans)
		trans.remote_path = drone.get_path()
		return

func UndockDrone(drone : Drone):
	DockedDrones.erase(drone)
	FlyingDrones.append(drone)
	DroneDockEventH.OnDroneUnDocked(drone)
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			var trans = docks[g].get_child(0) as RemoteTransform2D
			if (trans.remote_path == drone.get_path()):
				trans.free()
				return

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ShootDrone")):
		if (DockedDrones.size() == 0):
			return
		var drone = DockedDrones[0]
		UndockDrone(drone)
		drone.look_at(get_global_mouse_position())
		drone.EnableDrone()
