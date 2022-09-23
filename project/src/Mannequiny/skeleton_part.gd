# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Skeleton

var _broken_part := -1
var _mount_bone : PhysicalBone = null

func start(broken_part : int) -> void:
	_broken_part = broken_part
	var to_not_remove := []

	match _broken_part:
		Global.BrokenPart.RightArm:
			_mount_bone = $"Physical Bone upperarmr"
			to_not_remove = Global.right_arm_bone_names
		Global.BrokenPart.LeftArm:
			_mount_bone = $"Physical Bone upperarml"
			to_not_remove = Global.left_arm_bone_names
		_:
			push_error("Unexpected Global.BrokenPart: %s" % [_broken_part])
			return

	# Move physical bones to location of animation bones
	for entry in Global.all_bone_names:
		var physical_bone = self.get_node_or_null("Physical Bone %s" % [entry])
		if physical_bone:
			var bone_id = self.find_bone(entry)
			physical_bone.global_transform = self.get_bone_global_pose(bone_id)
			#physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y - deg2rad(180.0))
			physical_bone.global_transform.origin += self.global_transform.origin

	# Remove all non broken part physical bones
	for name in Global.all_bone_names:
		if not to_not_remove.has(name):
			var physical_bone = self.get_node_or_null("Physical Bone %s" % [name])
			if physical_bone:
				physical_bone.queue_free()

	self.physical_bones_start_simulation()
	pass

func _process(_delta : float) -> void:
	var to_not_remove := []

	match _broken_part:
		Global.BrokenPart.RightArm:
			to_not_remove = Global.right_arm_bone_names
		Global.BrokenPart.LeftArm:
			to_not_remove = Global.left_arm_bone_names
		_:
			push_error("Unexpected Global.BrokenPart: %s" % [_broken_part])
			return

	# Tuck all animation bones that are not removed into mount bone
	var pos = _mount_bone.global_transform
	pos.origin -= self.global_transform.origin
	pos = Global.shrink(pos, 0.001)
	for name in Global.all_bone_names:
		if not to_not_remove.has(name):
			var bone_id = self.find_bone(name)
			self.set_bone_global_pose_override(bone_id, pos, 1.0, true)
