extends Resource

class_name DroneDockEventHandler

signal OnDroneArmed
signal OnDroneDissarmed
signal OnDroneDirectionChanged(NewDir : float)
signal DroneLaunched
signal DroneAdded(Dr : Drone)
signal DroneDocked(Dr : Drone)
signal DroneUndocked(Dr : Drone)
signal DroneRangeChanged(NewRange : float)

func DroneDirectionChanged(Dir : float) -> void:
	OnDroneDirectionChanged.emit(Dir)
func DroneArmed() -> void:
	OnDroneArmed.emit()
func DroneDissarmed() -> void:
	OnDroneDissarmed.emit()
func OnDroneLaunched() -> void:
	DroneLaunched.emit()
func OnDroneAdded(Dr : Drone) -> void:
	DroneAdded.emit(Dr)
func OnDronRangeChanged(NewRange : float) -> void:
	DroneRangeChanged.emit(NewRange)
func OnDroneDocked(Dr : Drone) -> void:
	DroneDocked.emit(Dr)
func OnDroneUnDocked(Dr : Drone) -> void:
	DroneUndocked.emit(Dr)
