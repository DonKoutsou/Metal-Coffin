extends Resource

class_name MissileDockEventHandler

signal OnMissileArmed(Mis : MissileItem)
signal OnMissileDissarmed
signal OnMissileDirectionChanged(NewDir : float)
signal MissileLaunched(Mis : MissileItem)
signal MissileAdded(Mis : MissileItem)
signal MissileRemoved(Mis : MissileItem)

func MissileDirectionChanged(Dir : float) -> void:
	OnMissileDirectionChanged.emit(Dir)
func MissileArmed(Mis : MissileItem) -> void:
	OnMissileArmed.emit(Mis)
func MissileDissarmed() -> void:
	OnMissileDissarmed.emit()
func OnMissileLaunched(Mis : MissileItem) -> void:
	MissileLaunched.emit(Mis)
func OnMissileAdded(Mis : MissileItem) -> void:
	MissileAdded.emit(Mis)
func OnMissileRemoved(Mis : MissileItem) -> void:
	MissileRemoved.emit(Mis)
