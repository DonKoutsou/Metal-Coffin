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
	var TopoVisual = TopographyVisualNoise.get_image()
	TopoVisual.resize(TopoVisualNoiseSize, TopoVisualNoiseSize ,Image.INTERPOLATE_NEAREST)
	TopoVisual.clear_mipmaps()
	#ResourceSaver.save(ImageTexture.create_from_image(TopoVisual), "res://Noises/Topography/TEX_Topo_Noise_Visual.tres")
	TopoVisual.convert(Image.FORMAT_RGBA8)
	var Ter = TopoVisual.save_png("res://Noises/Topography/TEX_Topo_Noise_Visual.png")
	print("Saving Topology Noise Visual Map Resault : {0}".format([Ter]))
	
	
	var TopoData = TopographyDataNoise.get_image()
	TopoData.resize(TopoDataNoiseSize, TopoDataNoiseSize ,Image.INTERPOLATE_NEAREST)
	TopoData.clear_mipmaps()
	#TopoData.convert(Image.FORMAT_RGBA8)
	#var TopoDataError = TopoData.save_png("res://Noises/Topography/TEX_Topo_Noise_Data.png")
	#print("Saving Topology Noise Data Map Resault : {0}".format([TopoDataError]))
	ResourceSaver.save(TopoData, "res://Noises/Topography/TEX_Topo_Noise_Data.tres")

	var GroundVisual = GroundVisualNoise.get_image()
	GroundVisual.resize(NoiseSize, NoiseSize ,Image.INTERPOLATE_NEAREST)
	GroundVisual.clear_mipmaps()
	GroundVisual.convert(Image.FORMAT_RGBA8)
	var GroundVisualError = GroundVisual.save_png("res://Noises/Ground/TEX_GroundVisualNoise.png")
	print("Saving Ground Noise Visual Map Resault : {0}".format([GroundVisualError]))
	ResourceSaver.save(ImageTexture.create_from_image(GroundVisual), "res://Noises/Ground/TEX_GroundVisualNoise.tres")
	
	var MaskT = GroundVisualNoiseMask.get_image()
	MaskT.resize(NoiseSize, NoiseSize ,Image.INTERPOLATE_NEAREST)
	MaskT.clear_mipmaps()
	MaskT.convert(Image.FORMAT_RGBA8)
	var GroundMaskError = MaskT.save_png("res://Noises/Ground/TEX_GroundVisualNoiseMask.png")
	print("Saving Ground Noise Mask Map Resault : {0}".format([GroundMaskError]))
	#ResourceSaver.save(ImageTexture.create_from_image(MaskT), "res://Noises/Ground/TEX_GroundVisualNoiseMask.tres",ResourceSaver.FLAG_NONE)

	var WeatherData = WeatherDataNoise.get_image()
	WeatherData.resize(WeatherDataNoiseSize, WeatherDataNoiseSize ,Image.INTERPOLATE_NEAREST)
	WeatherData.clear_mipmaps()
	#WeatherData.convert(Image.FORMAT_RGBA8)
	#var WeatherDataError = WeatherData.save_png("res://Noises/Weather/TEX_WeatherDataNoise.png")
	#print("Saving Weather Noise Data Map Resault : {0}".format([WeatherDataError]))
	ResourceSaver.save(WeatherData, "res://Noises/Weather/TEX_WeatherDataNoise.tres")
	
	var WeatherVisual = WeatherVisualNoise.get_image()
	WeatherVisual.resize(WeatherVisualNoiseSize, WeatherVisualNoiseSize ,Image.INTERPOLATE_NEAREST)
	WeatherVisual.clear_mipmaps()
	#WeatherVisual.convert(Image.FORMAT_RGBA8)
	#var WeatherVisualError = WeatherVisual.save_png("res://Noises/Weather/TEX_WeatherVisualNoise.png")
	#print("Saving Weather Noise Visual Map Resault : {0}".format([WeatherVisualError]))
	ResourceSaver.save(ImageTexture.create_from_image(WeatherVisual), "res://Noises/Weather/TEX_WeatherVisualNoise.tres")
