# Based on the xoshiro/xoroshiro RNG family by
# David Blackman and Sebastiano Vigna.
# Official implementations are released under CC0:
# https://prng.di.unimi.it/

extends RefCounted
class_name Xoshiro256

#This is kinda scuffed since GD script does not allow unsigned numbers but its ok I guess

# These are unsigned 64-bit constants written as signed 64-bit equivalents.
# 0x9E3779B97F4A7C15
const SPLITMIX_INC: int = -7046029254386353131

# 0xBF58476D1CE4E5B9
const SPLITMIX_MUL1: int = -4658895280553007687

# 0x94D049BB133111EB
const SPLITMIX_MUL2: int = -7723592293110705685

const INT64_MAX: int = 9223372036854775807
const FLOAT_53_SCALE: float = 1.0 / 9007199254740992.0 # 2^53

var _s0: int
var _s1: int
var _s2: int
var _s3: int
var used : int = 0

var _splitmix_state: int

func set_seed(seed_value: int) -> void:
	_splitmix_state = seed_value

	_s0 = _splitmix64()
	_s1 = _splitmix64()
	_s2 = _splitmix64()
	_s3 = _splitmix64()

	# xoshiro state must not be all zero.
	if (_s0 | _s1 | _s2 | _s3) == 0:
		_s0 = SPLITMIX_INC


func _splitmix64() -> int:
	_splitmix_state += SPLITMIX_INC

	var z: int = _splitmix_state
	z = (z ^ _urshift(z, 30)) * SPLITMIX_MUL1
	z = (z ^ _urshift(z, 27)) * SPLITMIX_MUL2
	z = z ^ _urshift(z, 31)

	return z


func _urshift(x: int, n: int) -> int:
	# Logical unsigned right shift for signed 64-bit ints.

	if n <= 0:
		return x

	if n >= 64:
		return 0

	if x >= 0:
		return x >> n

	# For n == 1, the mask is 0x7FFFFFFFFFFFFFFF.
	# We handle it explicitly because 1 << 63 overflows signed int.
	if n == 1:
		return (x >> n) & INT64_MAX

	var mask: int = (1 << (64 - n)) - 1
	return (x >> n) & mask


func _rotl(x: int, k: int) -> int:
	return (x << k) | _urshift(x, 64 - k)


func next_u64() -> int:
	# Returns a signed int containing the raw 64-bit pattern.
	# If the high bit is set, this will appear negative in GDScript.

	var result: int = _rotl(_s1 * 5, 7) * 9

	var t: int = _s1 << 17

	_s2 = _s2 ^ _s0
	_s3 = _s3 ^ _s1
	_s1 = _s1 ^ _s2
	_s0 = _s0 ^ _s3

	_s2 = _s2 ^ t
	_s3 = _rotl(_s3, 45)

	return result


func next_i63() -> int:
	used += 1
	# Non-negative 63-bit integer.
	return _urshift(next_u64(), 1)


func next_i32() -> int:
	used += 1
	# Non-negative 32-bit-ish integer.
	return _urshift(next_u64(), 32)


func next_float() -> float:
	used += 1
	# Returns a float in [0.0, 1.0).
	# Uses the top 53 bits, like common double-generation methods.
	return float(_urshift(next_u64(), 11)) * FLOAT_53_SCALE


func next_bool() -> bool:
	used += 1
	return (next_u64() & 1) != 0


func range_int(min_inclusive: int, max_exclusive: int) -> int:
	if max_exclusive <= min_inclusive:
		#push_error("max_exclusive must be greater than min_inclusive.")
		return min_inclusive
	used += 1
	var span: int = max_exclusive - min_inclusive

	# Rejection sampling using 63-bit non-negative values.
	# This avoids modulo bias.
	var limit: int = INT64_MAX - (INT64_MAX % span)

	while true:
		var r: int = next_i63()
		if r < limit:
			return min_inclusive + (r % span)

	return min_inclusive


func range_float(min_inclusive: float, max_exclusive: float) -> float:
	used += 1
	return min_inclusive + (max_exclusive - min_inclusive) * next_float()

func rand_weighted(weights: Array) -> int:
	var total_weight: float = 0.0

	for weight in weights:
		var w := float(weight)
		if w > 0.0:
			total_weight += w

	if total_weight <= 0.0:
		push_error("rand_weighted() requires at least one positive weight.")
		return -1

	var r := range_float(0.0, total_weight)
	var running_total: float = 0.0

	for i in weights.size():
		var w := float(weights[i])

		if w <= 0.0:
			continue

		running_total += w

		if r < running_total:
			return i

	# Fallback for floating point edge cases.
	for i in range(weights.size() - 1, -1, -1):
		if float(weights[i]) > 0.0:
			return i

	return -1

func get_state() -> Dictionary:
	return {
		"algorithm": "xoshiro256**",
		"s0": str(_s0),
		"s1": str(_s1),
		"s2": str(_s2),
		"s3": str(_s3),
		"USED" : used,
		"splitmix_state": str(_splitmix_state),
	}


func set_state(state: Dictionary) -> void:
	if state.get("algorithm", "") != "xoshiro256**":
		push_error("Invalid RNG state.")
		return

	_s0 = int(state["s0"])
	_s1 = int(state["s1"])
	_s2 = int(state["s2"])
	_s3 = int(state["s3"])
	
	used = state["USED"]
	# Optional. Not required for continuing the xoshiro sequence,
	# but useful to restore the whole object exactly.
	_splitmix_state = int(state.get("splitmix_state", "0"))

	if (_s0 | _s1 | _s2 | _s3) == 0:
		push_error("Invalid xoshiro state: all zero.")
		_s0 = SPLITMIX_INC
