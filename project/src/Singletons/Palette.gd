# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll


extends Node


const _color_palette := [
	Color("#ffffcdf3"),
	Color("#ffff9233"),
	Color("#ffffee33"),
	Color("#ff29d0d0"),

	Color("#ffad2323"),
	Color("#ffe9debb"),
	Color("#ff81c57a"),
	Color("#ff9dafff"),

	Color("#ff8126c0"),
	Color("#ff814a19"),
	Color("#ff1d6914"),
	Color("#ff2a4bd7"),

	Color("#ffffffff"),
	Color("#ffa0a0a0"),
	Color("#ff575757"),
	Color("#ff000000"),
]

var _colors := []

func next_rand_color() -> Color:
	# Refill the colors with palette if empty
	if _colors.empty():
		_colors = _color_palette.duplicate(true)

	# Pop a random color from the palette
	var color : Color = Global.array_pop_random_value(_colors)

	return color
