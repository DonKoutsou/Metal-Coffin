extends Elint

class_name HostileElint

signal ElintContact(Ship : MapShip, t : bool)

func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = -1
	var ClosestShip : MapShip
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g] as MapShip
		if (!ship.RadarShape.Working):
			continue
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_squared_to(ship.global_position), ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.VISUAL_RANGE))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			ClosestShip = ship
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > -1):
		if (ClosestShip.Command != null):
			ElintContact.emit(ClosestShip.Command ,true)
		else:
			ElintContact.emit(ClosestShip ,true)

#-----------------------------------------------------------------------------------
func UpdateELINTTRange():
	(collision_shape_2d.shape as CircleShape2D).radius = ElintStat.GetCurrentValue(false)
	ElintRangeChanged.emit()

#-----------------------------------------------------------------------------------
func GetElintLevel(DistSq : float, RadarL : float) -> int:
	var Lvl = -1
	var RadarLSq = RadarL * RadarL
	var ElintDist = ElintStat.GetCurrentValue(false)
	if (ElintDist == 0 or RadarL <= MapShip.BASE_SHIP_VIZ):
		return Lvl
	if (DistSq < RadarLSq):
		Lvl = 3
	else : if (DistSq < RadarLSq * 2):
		Lvl = 2
	else : if (DistSq < RadarLSq * 10):
		Lvl = 1
	return Lvl

func BodyEnteredElint(area: Area2D) -> void:
	if (area.get_parent() is HostileShip):
		return
	super(area)
	
func BodyLeftElint(area: Area2D) -> void:
	if (area.get_parent() is HostileShip):
		return
	if (area.get_parent() == self):
		return
	ElintContacts.erase(area.get_parent())
	ElintContact.emit(area.get_parent(), false)
