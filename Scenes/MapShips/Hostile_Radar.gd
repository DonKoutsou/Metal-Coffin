extends Radar

class_name HostileRadar

signal OnPlayerVisualContact(Ship : MapShip, SeenBy : HostileShip)
signal OnPlayerVisualLost(Ship : MapShip, LostBy : HostileShip)

var Stationary : bool = false

func EvaluateRadarTargets(Altitude : float) -> void:
	for g in InsideRadar:
		if (TopographyMap.WithinLineOfSight(global_position, Altitude, g.global_position, g.Altitude)):
			if (Stationary):
				GarissonVisualContact(g)
			else:
				OnPlayerVisualContact.emit(g, self)
		else:
			if (Stationary):
				GarissonLostVisualContact(g)
			else:
				OnPlayerVisualLost.emit(g, self)
	
	if (GarrissonVisualContacts.size() > 0 and VisualContactCountdown > 0):
		VisualContactCountdown -= 0.05 * SimulationManager.SimulationSpeed
		if (VisualContactCountdown < 0):
			for c in GarrissonVisualContacts:
				OnPlayerVisualContact.emit(c, self)

func BodyEnteredRadar(Body : Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		InsideRadar.append(Body.get_parent())
		

var GarrissonVisualContacts : Array[MapShip]
var VisualContactCountdown = 20
signal VisualContactCountdownStarted(Value : float)

func GarissonVisualContact(Ship : MapShip) -> void:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.GARISSION_ALARM)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.GARISSION_ALARM)
		ActionTracker.GetInstance().QueueTutorial("Surprise Atack", "When entering enemy cities you are given a small time frame where you can surprise the enemy\n That time is signified by the red bar bellow the enemie's ship marker.\nIf the bar finishes the alarm will be raised and an enemy patrol will start heading your way. Its recomended to invade cities with faster ships and initiating combat fast before getting detected", [])
	if (GarrissonVisualContacts.has(Ship)):
		return
	
	if (GarrissonVisualContacts.size() == 0):
		#if (Patrol):
			#VisualContactCountdown = 5
		#else:
		var HeatSignature = Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST)
		VisualContactCountdown = 20 - (20 * (HeatSignature / 100))
		VisualContactCountdownStarted.emit(VisualContactCountdown)
			
	if (VisualContactCountdown < 0):
		OnPlayerVisualContact.emit(Ship, self)
		
	GarrissonVisualContacts.append(Ship)

func GarissonLostVisualContact(Ship : MapShip) -> void:
	if (VisualContactCountdown <= 0):
		OnPlayerVisualLost.emit(Ship, self)

	GarrissonVisualContacts.erase(Ship)
	if (GarrissonVisualContacts.size() == 0):
		VisualContactCountdown = 20

func BodyLeftRadar(Body : Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		InsideRadar.erase(Body.get_parent())
		if (Stationary):
			GarissonLostVisualContact(Body.get_parent())
		else:
			OnPlayerVisualLost.emit(Body.get_parent(), self)
