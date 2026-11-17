class_name PixelArt
extends RefCounted

const CELL := 32
const CHARACTER_HEIGHT := 48
const PATH := "res://assets/art/32/"


static func atlas_frame(atlas: Texture2D, frame: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(frame * CELL, 0, CELL, CELL)
	texture.filter_clip = true
	return texture
