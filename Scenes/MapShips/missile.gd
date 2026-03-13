extends Node2D

class_name Missile
#Missile class. Used in Map when spawning an enemy, has a radar infront, 
#once an enemy enters it the missile will hone at them and kill once struc
var MissileName : String
var Distance : int = 1500
@export var Speed : float = 1
var Damage : float = 20
var Amm : int
@export var MissileLaunchSound : AudioStream
@export var C : CardStats
@export var MissileVisual : Node2D
@export var CollisionDetector : Node2D
@export var AltitudeChangeSpeed : float = 1.0

var FoundShips : Array[Node2D] = []
var Friendly = false
var Altitude : float
var TargetAltitude : float
var DistanceTraveled : float
var WindVector : Vector2
var Killed : bool = false
var FiredBy : MapShip
var VisibleBy : Array[MapShip]

var CurrentLandAltitude : float

signal ShipMet(FriendlyShips : Array[MapShip] , EnemyShips : Array[MapShip], Missiles : Array[BattleShipStats])
signal OnShipDestroyed(Mis : Missile)
signal AltitudeChanged()

var activationdistance : float = 0

func SetData(Dat :Array[MissileItem]) -> void:
	Speed = Dat[0].Speed
	MissileName = Dat[0].ItemName
	Damage = Dat[0].Damage
	Distance = Dat[0].Distance
	Amm = Dat.size()

func GetSpeed() -> float:
	return Speed

func GetShipName() -> String:
	return MissileName

func _ready() -> void:
	TargetAltitude = Altitude
	if (FiredBy is not HostileShip):
		var s = DeletableSound.new()
		s.stream = MissileLaunchSound
		s.volume_db = -15
		s.bus = "MapSounds"
		s.autoplay = true
		s.max_distance = 20000
		get_parent().add_child(s)
	$AccelPosition.position.x = Speed / 360
	
	#$Radar_Range.visible = Friendly
	
func UpdateAltitude(NewAltitude) -> void:
	Altitude = NewAltitude
	AltitudeChanged.emit(NewAltitude)

func UpdateShipWindManipulationModifier() -> void:
	#var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * (WeatherManage.WindSpeed / WeatherManage.MAX_WIND_SPEED) * 0.2
	var StormValue = WeatherManage.Instance.StormValueInPosition(global_position)
	var StormAffectedWind = WeatherManage.WindDirection + (WeatherManage.WindDirection * StormValue)
	var Height = 0.3 + 0.7 * (Altitude / 10000)
	var WindProt = TopographyMap.GetWindProtection(global_position ,Altitude)
	WindVector = (StormAffectedWind * Height) * WindProt

func _physics_process(delta: float) -> void:
	if (SimulationManager.Paused):
		return
	
	var SimulatedDelta = delta * SimulationManager.SimSpeed()
	
	var CurrentTarget : Node2D
	for g in FoundShips:
		if (g != null):
			CurrentTarget = g
			break
	
	CurrentLandAltitude = TopographyMap.GetAltitudeAtGlobalPosition(global_position)
	
	var IncommingCollision : Vector3
	var Collided : bool = false
	if (CurrentTarget != null):
		IncommingCollision = TopographyMap.GetCollisionPoint3(global_position, Altitude, CurrentTarget.global_position, CurrentTarget.Altitude)
		Collided = Vector2(IncommingCollision.x, IncommingCollision.y) != CurrentTarget.global_position
	else:
		IncommingCollision = TopographyMap.GetCollisionPoint3(global_position, Altitude, CollisionDetector.global_position, Altitude)
		Collided = Vector2(IncommingCollision.x, IncommingCollision.y) != CollisionDetector.global_position
	
	if (Vector2(IncommingCollision.x, IncommingCollision.y) == global_position):
		Kill()
	else: if (Collided):
		var NewAlt = max(IncommingCollision.z + 100, CurrentLandAltitude + 100)
		if (NewAlt > TargetAltitude):
			TargetAltitude = NewAlt
	else:
		if (CurrentLandAltitude + 100 > TargetAltitude):
			TargetAltitude = CurrentLandAltitude + 100
	
	if (Altitude != TargetAltitude):
		UpdateAltitude(move_toward(Altitude, TargetAltitude, AltitudeChangeSpeed * SimulatedDelta))
	UpdateShipWindManipulationModifier()
	var offset = GetShipSpeedVec()
	
	DistanceTraveled += offset.length() * SimulationManager.SimSpeed()

	if (DistanceTraveled > Distance):
		Kill()
	
	

	global_position += offset * SimulationManager.SimSpeed()
	
	
	$ColorRect/TrailLine.Update(SimulatedDelta)
	
	activationdistance += offset.length() * SimulationManager.SimSpeed()
	
	
	
	if (activationdistance < 50):
		return
	
	
	
	if (CurrentTarget != null):
		HoneAtEnemy(CurrentTarget)
	
func CheckForBodiesOnTrajectory(Dir : Vector2) -> Node2D:
	var Body : Node2D
	
	var shape_cast = ShapeCast2D.new()
	add_child(shape_cast)
	shape_cast.exclude_parent = true
	shape_cast.collide_with_areas = true
	shape_cast.collision_mask = $MissileBody.collision_mask
	shape_cast.shape = CapsuleShape2D.new()
	# Set ShapeCast destination
	shape_cast.target_position = global_position + Dir

	# Perform the ShapeCast
	shape_cast.force_shapecast_update()
	if shape_cast.get_collision_count() > 0:
		Body = shape_cast.get_collider(0)
	shape_cast.queue_free()
	return Body

func StopSeeing() -> void:
	VisibleBy.clear()

func OnShipDest(Sh : MapShip) -> void:
	FoundShips.erase(Sh)
func OnMissDest(Mis : Missile) -> void:
	FoundShips.erase(Mis)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (Killed):
		return
	var bod = area.get_parent()
	if (bod == FiredBy):
		return
	
	if (bod is HostileShip):
		if (bod.Destroyed):
			return
		
	if (!FoundShips.has(bod)):
		FoundShips.append(bod)
		if (bod is MapShip):
			bod.connect("OnShipDestroyed" ,OnShipDest)
		else : if (bod is Missile):
			bod.connect("OnShipDestroyed" ,OnMissDest)
		if (FiredBy is PlayerDrivenShip):
			if (bod is HostileShip):
				bod.OnShipSeen(self)
				
func _on_area_2d_area_exited(area: Area2D) -> void:
	if (Killed):
		return
	if (FoundShips.has(area.get_parent())):
		FoundShips.erase(area.get_parent())
		if (area.get_parent() is MapShip):
			area.get_parent().disconnect("OnShipDestroyed" ,OnShipDest)
		else : if (area.get_parent() is Missile):
			area.get_parent().disconnect("OnShipDestroyed" ,OnMissDest)
		if (FiredBy is PlayerDrivenShip):
			if (area.get_parent() is HostileShip):
				area.get_parent().OnShipUnseen(self)
				
func _on_missile_body_area_entered(area: Area2D) -> void:
	if (area.get_parent() == FiredBy):
		return
	
	if (activationdistance < 50):
		return
	
	var Bod = area.get_parent()
	
	if (FoundShips.size() == 0):
		return
		
	if (abs(Altitude - Bod.Altitude) > 200):
		return
		
	if (Bod is HostileShip):
		if (FiredBy is HostileShip):
			Bod.Damage(Damage)
			Kill()
			return
		if (Bod.Destroyed):
			return
	if (area.get_parent() is Missile):
		Bod.Kill()
		Kill()
		return
	var s : MapShip = Bod
	var Command : MapShip
	if (s.Command == null):
		Command = s
	else:
		Command = s.Command
	
	var Squad : Array[MapShip]
	
	Squad.append(Command)
	Squad.append_array(Command.GetDroneDock().GetDockedShips())
	
	var PlSquad : Array[MapShip]
	var HostileSquad : Array[MapShip]
	if (Command is HostileShip):
		HostileSquad = Squad
	else:
		PlSquad = Squad
	var Mis : Array[BattleShipStats]
	for g in Amm:
		Mis.append(GetBattleStats())
	ShipMet.emit(PlSquad, HostileSquad, Mis)
	
	#area.get_parent().Damage(Damage)
	#if (area.get_parent().IsDead()):
		#RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.TARGET_DEST)
	call_deferred("Kill")
		
func _on_missile_body_area_exited(area: Area2D) -> void:
	var IsRadar = area.get_collision_layer_value(2)
	if (IsRadar):
		if (area.get_parent() is PlayerDrivenShip):
			OnShipUnseen(area.get_parent())
func _exit_tree() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)

func HoneAtEnemy(Ship : Node2D):
	
	# Get the current position and velocity of the ship
	var ship_position = Ship.global_position
	var ship_velocity = Ship.GetShipSpeedVec()
	TargetAltitude = Ship.Altitude + 100
	#var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * (WeatherManage.WindSpeed / WeatherManage.MAX_WIND_SPEED) * 0.2
	# Predict where the ship will be in a future time `t`
	var time_to_interception = (global_position.distance_to(ship_position) / GetAffectedSpeed()) / 60

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	look_at(predicted_position)

func GetAffectedSpeed() -> float:
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * (WeatherManage.WindSpeed / WeatherManage.MAX_WIND_SPEED) * 0.2
	var Spd = $AccelPosition.position.x * 360
	var AffectedSpeed = Spd + (Spd * WindVel)
	return AffectedSpeed

func GetdB() -> float:
	var sounds : Array[float]
	for g in Amm:
		sounds.append(Speed / 500)
	var finaldB = Helper.CombineNoiseAmplitude(sounds)
	return finaldB

func GetShipSpeedVec() -> Vector2:
	var Spd = $AccelPosition.global_position - global_position
	var AffectedSpeed = Spd + (WindVector * 0.1)
	return AffectedSpeed

func GetSaveData() -> MissileSaveData:
	var dat = MissileSaveData.new()
	dat.Pos = global_position
	dat.Rot = global_rotation
	dat.MisName = MissileName
	dat.MisSpeed = Speed
	dat.Distance = Distance
	dat.Scene = scene_file_path
	dat.DistanceTraveled = DistanceTraveled
	
	return dat
	
func OnShipSeen(SeenBy : MapShip):
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	SimulationManager.GetInstance().SpeedToggle(false)
	Map.GetInstance().GetCamera().FrameCamToPos(global_position, 1, false)
func OnShipUnseen(UnSeenBy : MapShip):
	VisibleBy.erase(UnSeenBy)

func Kill() -> void:
	OnShipDestroyed.emit(self)
	StopSeeing()
	queue_free()
	Killed = true
	#get_parent().remove_child(self)

func GetBattleStats() -> BattleShipStats:
	
	var stats = BattleShipStats.new()
	stats.Hull = 50
	stats.CurrentHull = 50
	stats.Speed = Speed
	stats.FirePower = Damage
	stats.ShipIcon = ResourceLoader.load("res://Assets/ShipTextures/Missile.png")
	stats.CaptainIcon = ResourceLoader.load("res://Assets/ShipTextures/Missile.png")
	stats.Name = GetShipName()
	var cards : Array[CardStats] = [C]
	stats.Cards = cards
	stats.Weight = 1
	stats.MaxShield =  50
	#stats.Ammo = Cpt.GetCharacterInventory().GetCardAmmo()
	stats.Funds = 0
	stats.Convoy = false
	stats.Friendly = Friendly
	return stats

func UpdateCameraZoom(NewZoom : float) -> void:
	MissileVisual.visible = NewZoom > 1.5
