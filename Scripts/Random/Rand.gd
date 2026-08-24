extends RefCounted

class_name Rand

static var customSeed : int = -1

var r : Xoroshiro128
var mut : Mutex

func GetState() -> Dictionary:
	mut.lock()
	var randomState = r.get_state()
	mut.unlock()
	return randomState

func Init(state : Dictionary = {}) -> void:
	r = Xoroshiro128.new()
	r.set_seed(customSeed)
	if (state.size() > 0):
		r.set_state(state)
	mut = Mutex.new()

func RandFRange(from : float, to : float) -> float:
	mut.lock()
	var randomFloat = r.range_float(from, to)
	mut.unlock()
	#print("Got random {0}".format([randomFloat]))
	return randomFloat

func RandF() -> float:
	mut.lock()
	var randomFloat = r.next_float()
	mut.unlock()
	#print("Got random {0}".format([randomFloat]))
	return randomFloat

func RandI() -> int:
	mut.lock()
	var randomInt = r.next_i32()
	mut.unlock()
	#print("Got random {0}".format([randomInt]))
	return randomInt

func RandWeighted(weights : PackedFloat32Array) -> int:
	mut.lock()
	var randomInt = r.rand_weighted(weights)
	mut.unlock()
	#print("Got random {0}".format([randomInt]))
	return randomInt

func RandIRange(from : int, to : int) -> int:
	mut.lock()
	var randomInt = r.range_int(from, to)
	mut.unlock()
	#print("Got random {0}".format([randomInt]))
	return randomInt

func RandBool() -> bool:
	mut.lock()
	var randomBool = r.next_bool()
	mut.unlock()
	#print("Got random {0}".format([randomBool]))
	return randomBool

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := RandIRange(0, i)

		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

static func NewRand(state : Dictionary = {}) -> Rand:
	var rand = Rand.new()
	rand.Init(state)
	print("Started new random with state {0}".format([rand.GetState()]))
	return rand
