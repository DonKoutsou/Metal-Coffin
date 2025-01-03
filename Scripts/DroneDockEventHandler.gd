extends Resource

class_name DroneDockEventHandler

signal OnDroneArmed(Target : MapShip)
signal OnDroneDissarmed(Target : MapShip)
signal OnDroneDirectionChanged(NewDir : float, Target : MapShip)
signal DroneLaunched(Dr : Drone, Target : MapShip)
signal DroneAdded(Dr : Drone, Target : MapShip)
signal DroneDischarged(Dr : Drone)
signal DroneDocked(Dr : Drone, Target : MapShip)
signal DroneUndocked(Dr : Drone)
signal DroneRangeChanged(NewRange : float, Target : MapShip)

func DroneDirectionChanged(Dir : float, Target : MapShip) -> void:
	OnDroneDirectionChanged.emit(Dir, Target)
func DroneArmed(Target : MapShip) -> void:
	OnDroneArmed.emit(Target)
func DroneDissarmed(Target : MapShip) -> void:
	OnDroneDissarmed.emit(Target)
func OnDroneLaunched(Dr : Drone, Target : MapShip) -> void:
	DroneLaunched.emit(Dr, Target)
func OnDroneAdded(Dr : Drone, Target : MapShip) -> void:
	DroneAdded.emit(Dr, Target)
func OnDroneDischarged(Dr : Drone) -> void:
	DroneDischarged.emit(Dr)
func OnDronRangeChanged(NewRange : float,Target : MapShip) -> void:
	DroneRangeChanged.emit(NewRange, Target)
func OnDroneDocked(Dr : Drone, Target : MapShip) -> void:
	DroneDocked.emit(Dr, Target)
func OnDroneUnDocked(Dr : Drone, Target : MapShip) -> void:
	DroneUndocked.emit(Dr, Target)
