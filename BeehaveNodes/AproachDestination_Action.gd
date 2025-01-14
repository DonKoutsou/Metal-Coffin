@tool
extends ActionLeaf

class_name ApreachDestinationAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	
	#var SimulationSpeed = MainShip.SimulationSpeed
	#var Pos = MainShip.global_position
	#var DestinationPos = MainShip.GetCurrentDestination()
	#
	#if (Pos.distance_to(DestinationPos) > 1):
		#var Speed = MainShip.GetShipSpeed()
		#var MainFuelTank = MainShip.Cpt.GetStat("FUEL_TANK") as ShipStat
		#var DroneD = MainShip.GetDroneDock() as HostileDroneDock
		#for g in DroneD.DockedDrones:
			#var Ship = g as HostileShip
			#var FuelTank = Ship.Cpt.GetStat("FUEL_TANK") as ShipStat
			#var dronefuel = (Speed / 10 / Ship.Cpt.GetStatValue("FUEL_EFFICIENCY")) * SimulationSpeed
			#if (FuelTank.GetCurrentValue() > dronefuel):
				#FuelTank.ConsumeResource(dronefuel)
			#else : if (MainFuelTank.GetCurrentValue() >= dronefuel):
				#MainFuelTank.ConsumeResource(dronefuel)
		#
		#var ftoconsume = Speed / 10 / MainShip.Cpt.GetStatValue("FUEL_EFFICIENCY") * SimulationSpeed
		#if (MainFuelTank.GetCurrentValue() > ftoconsume):
			#MainFuelTank.ConsumeResource(ftoconsume)
		#else: if (DroneD.DronesHaveFuel(ftoconsume)):
			#DroneD.SyphonFuelFromDrones(ftoconsume)
			#
		#MainShip.SetSpeed(MainShip.GetShipMaxSpeed())
		##var SimulationSpeed = Ship.SimulationSpeed
		#MainShip.global_position += MainShip.GetShipSpeedVec() * SimulationSpeed
		#MainShip.ShipLookAt(DestinationPos)
		#return RUNNING
	#
	#MainShip.SetSpeed(0)
	return RUNNING
