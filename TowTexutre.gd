@tool
extends Sprite2D

@export var texture_size: int = 512
@export var city_radius: float = 220.0
@export var noise_scale: float = 0.008
@export var noise_strength: float = 0.8

@export var ring_count: int = 3
@export var radial_count: int = 8

@export var minor_road_threshold: float = 0.68

@export_tool_button("ProduceTexture") var CreateTextureAction = UpdateTexture

func UpdateTexture() -> void:
	var t = generate_city_texture()
	texture = t

func generate_city_texture() -> Texture2D:
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(texture_size / 2, texture_size / 2)

	var density_noise := FastNoiseLite.new()
	density_noise.seed = randi()
	density_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	density_noise.fractal_octaves = 4
	density_noise.frequency = noise_scale

	var road_noise := FastNoiseLite.new()
	road_noise.seed = randi() + 999
	road_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	road_noise.frequency = 0.02

	var city_rotation := randf_range(0.0, TAU)

	for x in texture_size:
		for y in texture_size:
			var pos := Vector2(x, y)
			var local_pos := (pos - center).rotated(city_rotation)
			var dist := local_pos.length()

			# -------------------------
			# Density Field
			# -------------------------
			var falloff = clamp(1.0 - (dist / city_radius), 0.0, 1.0)
			var n := (density_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var density = falloff * lerp(1.0, n, noise_strength)

			var color := get_density_color(density)

			# -------------------------
			# Roads
			# -------------------------
			if density > 0.2:
				var road_strength := get_road_strength(
					local_pos,
					dist,
					center,
					road_noise
				)

				if road_strength > 0.0:
					color = color.darkened(road_strength)

			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)


# -------------------------
# Density → Base Color
# -------------------------
func get_density_color(density: float) -> Color:
	if density > 0.7:
		return Color(0.72, 0.70, 0.65) # Downtown
	elif density > 0.4:
		return Color(0.55, 0.53, 0.50) # Mid-rise
	elif density > 0.2:
		return Color(0.40, 0.42, 0.38) # Suburbs
	else:
		return Color(0.30, 0.33, 0.29, 0) # Rural


# -------------------------
# Road System
# -------------------------
func get_road_strength(
	local_pos: Vector2,
	dist: float,
	center: Vector2,
	road_noise: FastNoiseLite
) -> float:

	var strength := 0.0

	# ---- Ring Roads (Highways) ----
	var ring_spacing = city_radius / float(ring_count + 1)
	for i in range(1, ring_count + 1):
		var target_radius = ring_spacing * i
		if abs(dist - target_radius) < 2.0:
			strength = max(strength, 0.45)

	# ---- Radial Arterials ----
	var angle = atan2(local_pos.y, local_pos.x)
	for i in range(radial_count):
		var target_angle = TAU * float(i) / radial_count
		if abs(wrapf(angle - target_angle, -PI, PI)) < 0.015:
			strength = max(strength, 0.35)

	# ---- Minor Noise Roads ----
	var n = road_noise.get_noise_2d(local_pos.x, local_pos.y)
	if abs(n) > minor_road_threshold:
		strength = max(strength, 0.2)

	return strength
