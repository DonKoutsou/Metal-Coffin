@tool
extends TextureRect

@export var NoiseSize : int = 1024
@export_group("Ground")
@export var GroundVisualNoise : NoiseTexture2D
@export var GroundVisualNoiseMask : NoiseTexture2D
@export_group("Topography")
@export var TopographyVisualNoise : NoiseTexture2D
@export var TopoVisualNoiseSize : int = 1024
@export var TopographyDataNoise : NoiseTexture2D
@export var TopoDataNoiseSize : int = 256
@export_group("Weather")
@export var WeatherDataNoise : NoiseTexture2D
@export var WeatherDataNoiseSize : int = 512
@export var WeatherVisualNoise : NoiseTexture2D
@export var WeatherVisualNoiseSize : int = 1024

@export_tool_button("Regenerate Texture") var RegenAction = RegenNoiseTexture

func RegenNoiseTexture() -> void:
	var t = TopographyVisualNoise.get_image()
	t.resize(TopoVisualNoiseSize, TopoVisualNoiseSize ,Image.INTERPOLATE_NEAREST)
	t.clear_mipmaps()
	
	ResourceSaver.save(ImageTexture.create_from_image(t), "res://Noises/Topography/TEX_Topo_Noise_Visual.tres")
	
	var TopoData = TopographyDataNoise.get_image()
	TopoData.resize(TopoDataNoiseSize, TopoDataNoiseSize ,Image.INTERPOLATE_NEAREST)
	TopoData.clear_mipmaps()
	ResourceSaver.save(TopoData, "res://Noises/Topography/TEX_Topo_Noise_Data.tres")

	var t2 = GroundVisualNoise.get_image()
	t2.resize(NoiseSize, NoiseSize ,Image.INTERPOLATE_NEAREST)
	t2.clear_mipmaps()
	ResourceSaver.save(ImageTexture.create_from_image(t2), "res://Noises/Ground/TEX_GroundVisualNoise.tres")
	
	var MaskT = GroundVisualNoiseMask.get_image()
	MaskT.resize(NoiseSize, NoiseSize ,Image.INTERPOLATE_NEAREST)
	MaskT.clear_mipmaps()
	ResourceSaver.save(ImageTexture.create_from_image(MaskT), "res://Noises/Ground/TEX_GroundVisualNoiseMask.tres",ResourceSaver.FLAG_NONE)

	var WeatherData = WeatherDataNoise.get_image()
	WeatherData.resize(WeatherDataNoiseSize, WeatherDataNoiseSize ,Image.INTERPOLATE_NEAREST)
	WeatherData.clear_mipmaps()
	ResourceSaver.save(WeatherData, "res://Noises/Weather/TEX_WeatherDataNoise.tres")
	
	var WeatherVisual = WeatherVisualNoise.get_image()
	WeatherVisual.resize(WeatherVisualNoiseSize, WeatherVisualNoiseSize ,Image.INTERPOLATE_NEAREST)
	WeatherVisual.clear_mipmaps()
	ResourceSaver.save(ImageTexture.create_from_image(WeatherVisual), "res://Noises/Weather/TEX_WeatherVisualNoise.tres")
