# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Spatial
class_name PathMarker

var _offset := Vector3.ZERO

func _ready() -> void:
	# Pick random color from palette
	var color : Color = Palette.next_rand_color()

	# Create a new material with random color
	var mat := SpatialMaterial.new()
	mat.flags_transparent = true
	mat.albedo_color = color

	# Set path color
	var polygon : CSGPolygon = $CSGPolygon
	polygon.material = mat

	# Set arrow color
	var arrow : MeshInstance = $Path/PathFollow/Arrow/MeshInstance3
	var mesh = arrow.mesh
	#mesh.surface_set_material(0, mat)
	arrow.material_override = mat

	$AnimationPlayer.play("Default")

func update() -> bool:
	# Remove first point
	$Path.curve.remove_point(0)

	# Only show if there are points
	var is_empty := self.empty()
	self.visible = not is_empty

	return is_empty

func empty() -> bool:
	return $Path.curve.get_point_count() == 0

func first() -> Vector3:
	return $Path.curve.get_point_position(0) - self._offset

func get_slope() -> float:
	var curve = $Path.curve
	if curve.get_point_count() < 2:
		return 10.0
	else:
		var first = curve.get_point_position(0) - self._offset
		var second = curve.get_point_position(1) - self._offset
		return abs(first.y - second.y)

func change_path(points : Array, offset := Vector3.ZERO) -> void:
	var path = $Path
	self._offset = offset

	# Create a new curve from the points and set the path to use it
	var curve := Curve3D.new()
	for p in points:
		curve.add_point(p)
	path.curve = curve

	# Only show if there are points
	self.visible = not points.empty()
