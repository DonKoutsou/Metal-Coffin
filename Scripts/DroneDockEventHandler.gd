extends Resource

class_name DroneDockEventHandler

signal OnDroneArmed
signal OnDroneDissarmed
signal OnDroneDirectionChanged(NewDir : float)
signal DroneLaunched(Dr : Drone)
signal DroneAdded(Dr : Drone)
signal DroneDischarged(Dr : Drone)
signal DroneDocked(Dr : Drone)
signal DroneUndocked(Dr : Drone)
signal DroneRangeChanged(NewRange : float)

func DroneDirectionChanged(Dir : float) -> void:
	OnDroneDirectionChanged.emit(Dir)
func DroneArmed() -> void:
	OnDroneArmed.emit()
func DroneDissarmed() -> void:
	OnDroneDissarmed.emit()
func OnDroneLaunched(Dr : Drone) -> void:
	DroneLaunched.emit(Dr)
func OnDroneAdded(Dr : Drone) -> void:
	DroneAdded.emit(Dr)
func OnDroneDischarged(Dr : Drone) -> void:
	DroneDischarged.emit(Dr)
func OnDronRangeChanged(NewRange : float) -> void:
	DroneRangeChanged.emit(NewRange)
func OnDroneDocked(Dr : Drone) -> void:
	DroneDocked.emit(Dr)
func OnDroneUnDocked(Dr : Drone) -> void:
	DroneUndocked.emit(Dr)
