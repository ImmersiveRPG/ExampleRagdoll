# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/workhorsy/PatreonRagdolls1

extends Skeleton3D

var _animation_skeleton : Skeleton3D

@export var linear_spring_stiffness := 1200.0
@export var linear_spring_damping := 40.0
const linear_force_max := 9999.0

@export var angular_spring_stiffness := 4000.0
@export var angular_spring_damping := 80.0
const angular_force_max := 9999.0

var _is_syncing := false

func _ready() -> void:
	# Turn off bone gravity and start reacting to physics
	for child in self.get_children():
		if child is PhysicalBone3D:
			child.gravity_scale = 0.0
			#var col = child.get_node("CollisionShape3D")
			#col.disabled = true

	self.physical_bones_start_simulation()

func _physics_process(delta : float) -> void:
	if not _is_syncing: return

	for bone in self.get_children().filter(func(c): return c is PhysicalBone3D):
		# Get the locations of the physical and animation bones
		var animation_transform := _animation_skeleton.global_transform * _animation_skeleton.get_bone_global_pose(bone.get_bone_id())
		var physics_transform := self.global_transform * self.get_bone_global_pose(bone.get_bone_id())

		# Get the differences
		var position_difference := animation_transform.origin - physics_transform.origin
		var rotation_difference := animation_transform.basis * physics_transform.basis.inverse()

		# Set the linear velocity
		if position_difference.length_squared() <= 1.0:
			var force := Global.hookes_law(position_difference, bone.linear_velocity, self.linear_spring_stiffness, self.linear_spring_damping)
			force = force.limit_length(self.linear_force_max)
			bone.linear_velocity += force * delta
		# If the distance is too far, just use the animation position
		else:
			bone.global_position = animation_transform.origin
			bone.linear_velocity = Vector3.ZERO

		# Set the angular velocity
		var torque := Global.hookes_law(rotation_difference.get_euler(), bone.angular_velocity, self.angular_spring_stiffness, self.angular_spring_damping)
		torque = torque.limit_length(self.angular_force_max)
		bone.angular_velocity += torque * delta
