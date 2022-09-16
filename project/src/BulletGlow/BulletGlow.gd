# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

class_name BulletGlow
extends ImmediateGeometry

var _points := []
var _prev_pos := Vector3.ZERO
var _parent_bullet : Node = null

func _physics_process(delta : float) -> void:
	# If the parent bullet still exists, add a point when it moves at least a meter
	if _parent_bullet != null and is_instance_valid(_parent_bullet):
		var position = _parent_bullet.global_transform.origin
		var distance = _prev_pos.distance_to(position)
		if distance > 1.0:
			_prev_pos = position

			# Save position as local space
			_points.append(position - self.global_transform.origin)

			if _points.size() > 5:
				_points.pop_front()
	else:
		# If the bullet is destroyed, delete the points
		if not _points.empty():
			_points.pop_front()
		else:
			self.queue_free()

func _process(delta : float) -> void:
	# Draw the line
	clear()
	begin(1, null)
	for i in _points.size():
		if i + 1 < _points.size():
			var a = _points[i]
			var b = _points[i + 1]
			add_vertex(a)
			add_vertex(b)
	end()

func start(bullet : Node) -> void:
	_parent_bullet = bullet
	self._physics_process(0.0)
