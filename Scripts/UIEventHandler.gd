extends Resource

class_name UIEventHandler

signal AccelerationEnded(Value : float)
signal AccelerationChanged(Value : float)
signal SpeedSet(Value : float)
signal SpeedForced(Value : float)
#signal AccelerationForced(ForceVal : float)
signal DroneButtonPressed()
signal MissileButtonPressed()
signal RadarButtonPressed()
#signal SteerDirForced(ForcedVal : float)
signal SteerDirChanged(NewDir : float)
signal SteerOffseted(Offset : float)

#Drone tab
signal ShipSwitchPressed()
signal ShipUpdated(NewShip : MapShip)

#signal CoverToggled(t : bool)
signal MarkerEditorToggled(t : bool)
signal MarkerEditorCleared()
signal DrawLinePressed()
signal DrawTextPressed()
signal MarkerEditorYRangeChanged(NewValue : float)
signal MarkerEditorXRangeChanged(NewVlaue : float)

signal RegroupPressed()
signal LandPressed()
signal OpenHatchPressed()
#signal SimPausePressed()
signal InventoryPressed()
signal PausePressed()
signal FleetSeparationPressed()
#signal SimStepChanged(NewStep : float)

signal ScreenUIToggled(t : bool)

signal Storm(value : float)
signal ForecastToggled(t : bool)
signal GridPressed(t : bool)
signal ZoomToggled(t : bool)
signal TeamToggled(t : bool)
signal SonarToggled(t : bool)
#signal AlarmRaised

signal ShipDamaged(DammageAmm : float)

func OnSpeedSet(Speed : float) -> void:
	SpeedSet.emit(Speed)

func OnSpeedForced(Speed : float) -> void:
	SpeedForced.emit(Speed)

func OnScreenUIToggled(t : bool):
	ScreenUIToggled.emit(t)

func OnAccelerationEnded(value_changed: float) -> void:
	AccelerationEnded.emit(value_changed)


func OnAccelerationChanged(value: float) -> void:
	AccelerationChanged.emit(value)

#func OnAccelerationForced(NewVal : float) -> void:
	#AccelerationForced.emit(NewVal)

func OnDroneButtonPressed() -> void:
	DroneButtonPressed.emit()


func OnMissileButtonPressed() -> void:
	MissileButtonPressed.emit()


func OnRadarButtonPressed() -> void:
	RadarButtonPressed.emit()

func OnSteeringDirectionChanged(NewValue: float) -> void:
	SteerDirChanged.emit(NewValue)


func OnSteerOffseted(Offset: float) -> void:
	SteerOffseted.emit(Offset)


func OnShipSwitchPressed() -> void:
	ShipSwitchPressed.emit()

func OnShipUpdated(NewShip : MapShip) -> void:
	ShipUpdated.emit(NewShip)

#func OnSteerDirForced(NewVal : float) -> void:
	#SteerDirForced.emit(NewVal)

func OnMarkerEditorToggled(t : bool) -> void:
	MarkerEditorToggled.emit(t)

func OnMarkerEditorClearLinesPressed() -> void:
	MarkerEditorCleared.emit()

func OnMarkerEditorDrawLinePressed() -> void:
	DrawLinePressed.emit()

func OnMarkerEditorDrawTextPressed() -> void:
	DrawTextPressed.emit()

func OnMarkerEditorYRangeChanged(NewVal : float) -> void:
	MarkerEditorYRangeChanged.emit(NewVal)

func OnMarkerEditorXRangeChanged(NewVal : float) -> void:
	MarkerEditorXRangeChanged.emit(NewVal)

func OnRegroupPressed() -> void:
	RegroupPressed.emit()


func OnLandPressed() -> void:
	LandPressed.emit()

func OnOpenHatchPressed() -> void:
	OpenHatchPressed.emit()

#func OnSimPausePressed() -> void:
	#SimPausePressed.emit()


func OnInventoryPressed() -> void:
	InventoryPressed.emit()

func OnFleetSeparationPressed() -> void:
	FleetSeparationPressed.emit()

func OnPausePressed() -> void:
	PausePressed.emit()

func OnStorm(value : float) -> void:
	Storm.emit(value)
#func OnButtonCoverToggled(t : bool) -> void:
	#CoverToggled.emit(t)

func OnControlledShipDamaged(DammageAmm : float) -> void:
	ShipDamaged.emit(DammageAmm)
#func OnSimmulationStepChanged(NewStep: int) -> void:
	#SimStepChanged.emit(NewStep)

func OnForecastPressed(t : bool) -> void:
	ForecastToggled.emit(t)

func OnGridPressed(t : bool) -> void:
	GridPressed.emit(t)

func OnZoomTogglePressed(t : bool) -> void:
	ZoomToggled.emit(t)

func OnTeamTogglePressed(t : bool) -> void:
	TeamToggled.emit(t)

func OnSonarPressed(t : bool) -> void:
	SonarToggled.emit(t)
