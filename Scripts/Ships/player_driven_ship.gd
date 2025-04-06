extends MapShip

class_name PlayerDrivenShip

func _physics_process(delta: float) -> void:
	
	UpdateElint(delta)
	queue_redraw()
	
	for g in TrailLines:
		g.Update(delta)
	
	if (Paused):
		return
	
	var SimulationSpeed = SimulationManager.SimSpeed()
	
	if (Landing):
		UpdateAltitude(Altitude - (60 * SimulationSpeed))
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			Landing = false
	if (TakingOff):
		UpdateAltitude(Altitude + (60 * SimulationSpeed))
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false
	
	if (AccelChanged):
		var Audioween = create_tween()
		Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", lerp(0.1, 1.0, GetShipSpeed() / GetShipMaxSpeed()), 2)
		if (!$AudioStreamPlayer2D.playing):
			$AudioStreamPlayer2D.play()
		AccelChanged = false

	if (CurrentPort != null):
		Refuel()
		
		Repair()
		
		var inv = Cpt.GetCharacterInventory()
		if (inv._ItemBeingUpgraded != null):
			ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
		else:
			ShipDockActions.emit("Upgrading", false, 0)

	if (Docked or GetShipSpeedVec() == Vector2.ZERO):
		return
	
	var FuelConsumtion = $Aceleration.position.x / Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) * SimulationSpeed
	#Consume fuel on shif if enough
	if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= FuelConsumtion):
		Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelConsumtion)
	# If not enough on ship syphoon some from drones in dock
	else: if (GetDroneDock().DronesHaveFuel(FuelConsumtion)):
		GetDroneDock().SyphonFuelFromDrones(FuelConsumtion)
		#SetFuelShaderRange(GetFuelRange())
	else:
		HaltShip()
		PopUpManager.GetInstance().DoFadeNotif("Your drone has run out of fuel.")
		return

	if (CommingBack):
		updatedronecourse()
	
	for g in GetDroneDock().GetDockedShips():
		var Cap = g.Cpt as Captain
		var dronefuel = ($Aceleration.position.x / Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)) * SimulationSpeed
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK,dronefuel)
		else : if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= dronefuel):
			Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, dronefuel)
		else: if (GetDroneDock().DronesHaveFuel(dronefuel)):
			GetDroneDock().SyphonFuelFromDrones(dronefuel)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("Your drones have run out of fuel.")

	var offset = GetShipSpeedVec()
	global_position += offset * SimulationSpeed
