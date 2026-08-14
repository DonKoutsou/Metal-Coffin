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
				OnPlayerVisualContact.emit(g, get_parent())
		else:
			if (Stationary):
				GarissonLostVisualContact(g)
			else:
				OnPlayerVisualLost.emit(g, get_parent())
	
	if (GarrissonVisualContacts.size() > 0 and VisualContactCountdown > 0):
		VisualContactCountdown -= 0.05 * SimulationManager.SimulationSpeed
		if (VisualContactCountdown < 0):
			for c in GarrissonVisualContacts:
				OnPlayerVisualContact.emit(c, get_parent())

func BodyEnteredRadar(Body : Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		InsideRadar.append(Body.get_parent())
		

var GarrissonVisualContacts : Array[MapShip]
var VisualContactCountdown = 20
signal VisualContactCountdownStarted(Value : float)

func GarissonVisualContact(Ship : MapShip) -> void:
	ActionTracker.OnActionCompleted(ActionTracker.Action.GARISSION_ALARM)

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
		OnPlayerVisualContact.emit(Ship, get_parent())
		
	GarrissonVisualContacts.append(Ship)

func GarissonLostVisualContact(Ship : MapShip) -> void:
	if (VisualContactCountdown <= 0):
		OnPlayerVisualLost.emit(Ship, get_parent())

	GarrissonVisualContacts.erase(Ship)
	if (GarrissonVisualContacts.size() == 0):
		VisualContactCountdown = 20

func BodyLeftRadar(Body : Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		InsideRadar.erase(Body.get_parent())
		if (Stationary):
			GarissonLostVisualContact(Body.get_parent())
		else:
			OnPlayerVisualLost.emit(Body.get_parent(), get_parent())
