extends Resource

class_name DroneDockEventHandler

signal OnDroneArmed(Target : MapShip)
signal OnDroneDissarmed(Target : MapShip)
signal OnDroneDirectionChanged(NewDir : float, Target : MapShip)
signal DroneLaunched(Dr : PlayerDrivenShip, Target : MapShip)
signal DroneAdded(Dr : PlayerDrivenShip, Target : MapShip)
signal DroneDischarged(Dr : PlayerDrivenShip)
signal DroneDocked(Dr : PlayerDrivenShip, Target : MapShip)
signal DroneUndocked(Dr : PlayerDrivenShip)
signal DroneRangeChanged(NewRange : float, Target : MapShip)
signal OnDroneDockInstantiated(Target : MapShip)

func DroneDirectionChanged(Dir : float, Target : MapShip) -> void:
	OnDroneDirectionChanged.emit(Dir, Target)
func DroneArmed(Target : MapShip) -> void:
	OnDroneArmed.emit(Target)
func DroneDissarmed(Target : MapShip) -> void:
	OnDroneDissarmed.emit(Target)
func OnDroneLaunched(Dr : PlayerDrivenShip, Target : MapShip) -> void:
	DroneLaunched.emit(Dr, Target)
func OnDroneAdded(Dr : PlayerDrivenShip, Target : MapShip) -> void:
	DroneAdded.emit(Dr, Target)
func OnDroneDischarged(Dr : PlayerDrivenShip) -> void:
	DroneDischarged.emit(Dr)
func OnDronRangeChanged(NewRange : float,Target : MapShip) -> void:
	DroneRangeChanged.emit(NewRange, Target)
func OnDroneDocked(Dr : PlayerDrivenShip, Target : MapShip) -> void:
	DroneDocked.emit(Dr, Target)
func OnDroneUnDocked(Dr : PlayerDrivenShip, Target : MapShip) -> void:
	DroneUndocked.emit(Dr, Target)
func OnDockInstanced(Target : MapShip) -> void:
	OnDroneDockInstantiated.emit(Target)
