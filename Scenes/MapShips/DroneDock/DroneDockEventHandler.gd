extends Resource

class_name DroneDockEventHandler

signal OnDroneArmed(Target : MapShip)
signal OnDroneDissarmed(Target : MapShip)
signal OnDroneDirectionChanged(NewDir : float, Target : MapShip)
signal DroneLaunched(Dr : MapShip, Target : MapShip)
signal DroneAdded(Dr : MapShip, Target : MapShip)
signal DroneDischarged(Dr : MapShip)
signal DroneDocked(Dr : MapShip, Target : MapShip)
signal DroneUndocked(Dr : MapShip)
signal DroneRangeChanged(NewRange : float, Target : MapShip)
signal OnDroneDockInstantiated(Target : MapShip)

func DroneDirectionChanged(Dir : float, Target : MapShip) -> void:
	OnDroneDirectionChanged.emit(Dir, Target)
func DroneArmed(Target : MapShip) -> void:
	OnDroneArmed.emit(Target)
func DroneDissarmed(Target : MapShip) -> void:
	OnDroneDissarmed.emit(Target)
func OnDroneLaunched(Dr : MapShip, Target : MapShip) -> void:
	DroneLaunched.emit(Dr, Target)
func OnDroneAdded(Dr : MapShip, Target : MapShip) -> void:
	DroneAdded.emit(Dr, Target)
func OnDroneDischarged(Dr : MapShip) -> void:
	DroneDischarged.emit(Dr)
func OnDronRangeChanged(NewRange : float,Target : MapShip) -> void:
	DroneRangeChanged.emit(NewRange, Target)
func OnDroneDocked(Dr : MapShip, Target : MapShip) -> void:
	DroneDocked.emit(Dr, Target)
func OnDroneUnDocked(Dr : MapShip, Target : MapShip) -> void:
	DroneUndocked.emit(Dr, Target)
func OnDockInstanced(Target : MapShip) -> void:
	OnDroneDockInstantiated.emit(Target)
