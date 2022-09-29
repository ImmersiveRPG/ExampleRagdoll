# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Skeleton

signal hit(collider, origin, angle, force, bullet_type)

var _broken_part := -1
var _animation_bones := []
var _mount_bone : PhysicalBone = null
var _is_first_show := true

func _ready() -> void:
	# Hook up signals
	var err = self.connect("hit", self, "_on_hit")
	assert(err == OK)

func start(broken_part : int) -> void:
	# Hide self until after first process event
	self.hide()

	_broken_part = broken_part

	match _broken_part:
		Global.BodyPart.Head:
			var name = Global.body_parts_2_animation_bones(Global.BodyPart.Head)[0]
			_mount_bone = self.get_node("Physical Bone %s" % [name])
			_animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.Head)

		Global.BodyPart.Torso:
			return
		Global.BodyPart.Pelvis:
			return

		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			var name = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmR)[0]
			_mount_bone = self.get_node("Physical Bone %s" % [name])
			_animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmR | Global.BodyPart.LowerArmR | Global.BodyPart.HandR)
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			var name = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmL)[0]
			_mount_bone = self.get_node("Physical Bone %s" % [name])
			_animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmL | Global.BodyPart.LowerArmL | Global.BodyPart.HandL)
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			var name = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegR)[0]
			_mount_bone = self.get_node("Physical Bone %s" % [name])
			_animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegR | Global.BodyPart.LowerLegR | Global.BodyPart.FootR)
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			var name = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegL)[0]
			_mount_bone = self.get_node("Physical Bone %s" % [name])
			_animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegL | Global.BodyPart.LowerLegL | Global.BodyPart.FootL)
		_:
			push_error("Unexpected Global.BodyPart: %s" % [_broken_part])
			return

	# Move physical bones to location of animation bones
	for name in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		var physical_bone = self.get_node_or_null("Physical Bone %s" % [name])
		if physical_bone:
			var bone_id = self.find_bone(name)
			physical_bone.global_transform = self.get_bone_global_pose(bone_id)
			#physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y)
			physical_bone.global_transform.origin += self.global_transform.origin

	# Remove all non broken part physical bones
	for name in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		if not _animation_bones.has(name):
			var physical_bone = self.get_node_or_null("Physical Bone %s" % [name])
			if physical_bone:
				physical_bone.queue_free()

	self.physical_bones_start_simulation()

func _on_hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	collider.apply_central_impulse(angle * force)

func _process(_delta : float) -> void:
	# Move skeleton position to mount location
	self.global_transform.origin = _mount_bone.global_transform.origin

	# Tuck all animation bones that are not removed into mount bone
	var pos = _mount_bone.global_transform
	pos.origin -= self.global_transform.origin
	pos = Global.transform_shrink(pos, 0.001)
	for name in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		if not _animation_bones.has(name):
			var bone_id = self.find_bone(name)
			self.set_bone_global_pose_override(bone_id, pos, 1.0, true)

	# Show self if end of first process event
	if _is_first_show:
		self.show()
		_is_first_show = false
