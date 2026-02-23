extends Node2D

class_name MissileDock

@export var MissileDockEventH : MissileDockEventHandler

var ArmedMissile : MissileItem
var AimRot : float

func _ready() -> void:
	MissileDockEventH.connect("OnMissileDirectionChanged", MissileAimDirChanged)
	MissileDockEventH.connect("OnMissileArmed", MissileArmed)
	MissileDockEventH.connect("OnMissileDissarmed", MissileDissarmed)
	MissileDockEventH.connect("MissileLaunched", LaunchMissile)
	#MissileDockEventH.connect("MissileAdded", AddMissile)
	#MissileDockEventH.connect("MissileRemoved", MissileRemoved)

func IsOwner(Owner : Captain) -> bool:
	return Owner == get_parent().Cpt

func MissileArmed(Mis : MissileItem, Owner : Captain) -> void:
	if (!IsOwner(Owner)):
		return
	ArmedMissile = Mis
	#$MissileLine.set_point_position(1, Vector2(Mis.Distance, 0))
	#$MissileLine.set_point_position(0, Vector2(50, 0))
	#$MissileLine.visible = true

func MissileDissarmed(Owner : Captain) -> void:
	if (!IsOwner(Owner)):
		return
	ArmedMissile = null
	#$MissileLine.visible = false

func MissileAimDirChanged(NewDir : float, Owner : Captain) -> void:
	if (!IsOwner(Owner)):
		return
	AimRot += NewDir
	#$MissileLine.rotation += NewDir
	
func LaunchMissile(Mis : MissileItem, _Owner : Captain, User : Captain) -> void:
	if (!IsOwner(User)):
		return
	var MissileScene : PackedScene = ResourceLoader.load(Mis.MissileFile)
	var missile = MissileScene.instantiate() as Missile
	missile.FiredBy = get_parent()
	missile.SetData(Mis)
	missile.global_rotation = AimRot
	missile.global_position = global_position
	missile.Altitude = get_parent().Altitude
	missile.Friendly = true
	missile.ShipMet.connect(Map.GetInstance().EnemyMet)
	get_parent().get_parent().add_child(missile)
	
	MapPointerManager.GetInstance().AddShip(missile, true)
	#MissileDockEventH.MissileLaunched(Mis)
#func UpdateCameraZoom(NewZoom : float) -> void:
	#$MissileLine.width =  2 / NewZoom
