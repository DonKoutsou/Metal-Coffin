extends Resource

class_name MissileDockEventHandler

signal OnMissileArmed(Mis : MissileItem)
signal OnMissileDissarmed
signal OnMissileDirectionChanged(NewDir : float)
signal MissileLaunched(Mis : MissileItem, Owner : Captain)
signal MissileAdded(Mis : MissileItem, Owner : Captain)
signal MissileRemoved(Mis : MissileItem, Owner : Captain)

func MissileDirectionChanged(Dir : float) -> void:
	OnMissileDirectionChanged.emit(Dir)
func MissileArmed(Mis : MissileItem) -> void:
	OnMissileArmed.emit(Mis)
func MissileDissarmed() -> void:
	OnMissileDissarmed.emit()
func OnMissileLaunched(Mis : MissileItem, Owner : Captain) -> void:
	MissileLaunched.emit(Mis, Owner)
func OnMissileAdded(Mis : MissileItem, Owner : Captain) -> void:
	MissileAdded.emit(Mis, Owner)
func OnMissileRemoved(Mis : MissileItem, Owner : Captain) -> void:
	MissileRemoved.emit(Mis, Owner)
