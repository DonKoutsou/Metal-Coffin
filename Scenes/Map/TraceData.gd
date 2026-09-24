extends RefCounted

class_name TraceData

var Collided : bool
var CollisionPos : Vector2
var CollisionHeight : float

static func NewData(collisionResault : bool, colPos : Vector2, colHeight : float) -> TraceData:
	var newData := TraceData.new()
	newData.Collided = collisionResault
	newData.CollisionPos = colPos
	newData.CollisionHeight = colHeight
	return newData
