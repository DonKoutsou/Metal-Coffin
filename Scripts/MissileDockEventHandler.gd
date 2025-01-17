extends Resource

class_name MissileDockEventHandler

signal OnMissileArmed(Mis : MissileItem, Owner : Captain)
signal OnMissileDissarmed(Owner : Captain)
signal OnMissileDirectionChanged(NewDir : float, Owner : Captain)
signal MissileLaunched(Mis : MissileItem, Owner : Captain)
signal MissileAdded(Mis : MissileItem, Owner : Captain)
signal MissileRemoved(Mis : MissileItem, Owner : Captain)

func MissileDirectionChanged(Dir : float, Owner : Captain) -> void:
	OnMissileDirectionChanged.emit(Dir, Owner)
func MissileArmed(Mis : MissileItem, Owner : Captain) -> void:
	OnMissileArmed.emit(Mis, Owner)
func MissileDissarmed(Owner : Captain) -> void:
	OnMissileDissarmed.emit(Owner)
func OnMissileLaunched(Mis : MissileItem, Owner : Captain) -> void:
	MissileLaunched.emit(Mis, Owner)
func OnMissileAdded(Mis : MissileItem, Owner : Captain) -> void:
	MissileAdded.emit(Mis, Owner)
func OnMissileRemoved(Mis : MissileItem, Owner : Captain) -> void:
	MissileRemoved.emit(Mis, Owner)
