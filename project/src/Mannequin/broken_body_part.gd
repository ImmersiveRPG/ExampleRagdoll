# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/workhorsy/PatreonRagdolls1

extends Skeleton3D

signal hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int)

var _broken_part := -1
var _mount_bone : PhysicalBone3D = null
var _is_first_show := true
var _owner_npc : Node = null
var _is_attached_to_parent_skeleton := true


func start(owner_npc : Node, broken_part : Global.BodyPart, parent_skeleton : Skeleton3D) -> void:
	# Hide self until after first process event
	#self.hide()

	# Hook up signals
	var err = self.connect("hit", Callable(self, "_on_hit"))
	assert(err == OK)

	_owner_npc = owner_npc
	_broken_part = broken_part

	var parent_mount_bone := Global.get_skeleton_mount_bone(parent_skeleton, _broken_part)

	_mount_bone = Global.get_skeleton_mount_bone(self, _broken_part)
	var animation_bones = Global.get_skeleton_animation_bones(self, _broken_part)

	# Move the skeleton and mount to the parent mount location
	_mount_bone.global_transform = parent_mount_bone.global_transform# + parent_mount_bone.body_offset.origin
	self.global_transform = parent_skeleton.global_transform

	# Move physical bones to location of animation bones
	for entry in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		var physical_bone = self.get_node_or_null("Physical Bone %s" % [entry])
		if physical_bone:
			var bone_id = self.find_bone(entry)
			physical_bone.global_transform = self.get_bone_global_pose(bone_id)
			physical_bone.global_transform.origin += self.global_transform.origin

	# Remove all non broken part physical bones
	for entry in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		if not animation_bones.has(entry):
			var physical_bone = self.get_node_or_null("Physical Bone %s" % [entry])
			if physical_bone:
				physical_bone.queue_free()

	# Start ragdolling and turn gravity back on
	for child in self.get_children():
		if child is PhysicalBone3D:
			child.gravity_scale = 1.0
	self.physical_bones_start_simulation()

	# Tuck all animation bones that are not removed into mount bone
	var trans := _mount_bone.global_transform
	trans.origin -= self.global_transform.origin
	trans = Global.transform_shrink(trans, 0.001)
	for entry in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		if not animation_bones.has(entry):
			var bone_id := self.find_bone(entry)
			self.set_bone_global_pose_override(bone_id, trans, 1.0, true)

func _on_hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	# Forward hit to NPC with body part info
	var name := collider.name.trim_prefix("Physical Bone ")
	var body_part := Global.physical_bone_2_body_part(name)

	if _owner_npc == null or not is_instance_valid(_owner_npc):
		_owner_npc = null

	if _is_attached_to_parent_skeleton and _owner_npc != null:
		_owner_npc.emit_signal("hit_body_part", collider, body_part, origin, angle, force, bullet_type)
	else:
		collider.apply_central_impulse(angle * force)

func _process(_delta : float) -> void:
	# Move skeleton position to mount location
	self.global_transform.origin = _mount_bone.global_transform.origin

	# Show self if end of first process event
	if _is_first_show:
		#self.show()
		_is_first_show = false
