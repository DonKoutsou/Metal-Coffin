extends Node2D

class_name PlayerShip

signal ScreenEnter()
signal ScreenExit()

func UpdateFuelRange(fuel : float, fuel_ef : float):
	var distall = fuel * 10 * fuel_ef
	$Fuel/Fuel_Range.size = Vector2(distall, distall) * 2
	$Fuel/Fuel_Range/Label.visible = distall > 100
	$Fuel/Fuel_Range.position = Vector2(-(distall), -(distall))

func UpdateVizRange(rang : float):
	($Radar/CollisionShape2D.shape as CircleShape2D).radius = rang
	$Radar/Radar_Range.size = Vector2(rang, rang) * 2
	$Radar/Radar_Range/Label2.visible = rang > 100
	$Radar/Radar_Range.position = Vector2(-(rang), -(rang))

func UpdateAnalyzerRange(rang : float):
	($Analyzer/CollisionShape2D.shape as CircleShape2D).radius = rang
	$Analyzer/Analyzer_Range.size = Vector2(rang, rang) * 2
	$Analyzer/Analyzer_Range/Label2.visible = rang > 100
	$Analyzer/Analyzer_Range.position = Vector2(-(rang), -(rang))


func _on_player_viz_notifier_screen_entered() -> void:
	ScreenEnter.emit()


func _on_player_viz_notifier_screen_exited() -> void:
	ScreenExit.emit()
