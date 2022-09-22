# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

#tool
extends Spatial

signal hit(origin, collider)

var is_ragdoll := false
var _bone_names := []
var _skeleton : Skeleton = null
var _skeleton_rag_doll : Skeleton = null
export var is_syncing_bones := true

onready var collision_2_body_part := {
	$"root/Skeleton/Physical Bone neck_1" : Global.BodyPart.Head,
	$"root/Skeleton/Physical Bone spine_2" : Global.BodyPart.Torso,
	$"root/Skeleton/Physical Bone pelvis" : Global.BodyPart.Pelvis,
	$"root/Skeleton/Physical Bone upperarml" : Global.BodyPart.UpperArm,
	$"root/Skeleton/Physical Bone upperarmr" : Global.BodyPart.UpperArm,
	$"root/Skeleton/Physical Bone lowerarml" : Global.BodyPart.LowerArm,
	$"root/Skeleton/Physical Bone lowerarmr" : Global.BodyPart.LowerArm,
	$"root/Skeleton/Physical Bone handr" : Global.BodyPart.LowerArm,
	$"root/Skeleton/Physical Bone handl" : Global.BodyPart.LowerArm,
	$"root/Skeleton/Physical Bone thighl" : Global.BodyPart.UpperLeg,
	$"root/Skeleton/Physical Bone thighr" : Global.BodyPart.UpperLeg,
	$"root/Skeleton/Physical Bone calfl" : Global.BodyPart.LowerLeg,
	$"root/Skeleton/Physical Bone calfr" : Global.BodyPart.LowerLeg,
	$"root/Skeleton/Physical Bone footl" : Global.BodyPart.LowerLeg,
	$"root/Skeleton/Physical Bone footr" : Global.BodyPart.LowerLeg,
}

func _ready() -> void:
	_skeleton = $root/Skeleton
	_skeleton_rag_doll = $root/SkeletonRagDoll

	# Get a list of all bone names
	var total = _skeleton.get_bone_count()
	for i in total:
		var name = _skeleton.get_bone_name(i)
		if _skeleton.has_node("Physical Bone %s" % [name]):
			_bone_names.append(name)

func _on_hit(origin : Vector3, collider : Node) -> void:
	# Forward hit to NPC with body part info
	var body_part = collision_2_body_part[collider]
	self.owner.emit_signal("hit_body_part", origin, body_part)

func _on_skeleton_updated() -> void:
	if not is_syncing_bones: return
	if is_ragdoll: return

	var parent_rotation = Vector3(0.0, deg2rad(180.0), 0.0)
	if not Engine.editor_hint:
		parent_rotation = self.get_parent().get_parent().rotation

	# Join the animation bones and physical bones
	for entry in _bone_names:
		var physical_bone = _skeleton.get_node_or_null("Physical Bone %s" % [entry])
		var bone_id = _skeleton.find_bone(entry)

		# Move physical bone to location of animation bone
		if physical_bone:
			physical_bone.global_transform = _skeleton.get_bone_global_pose(bone_id)
			physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y - deg2rad(180.0))
			physical_bone.global_transform.origin += self.global_transform.origin

func shrink(tran : Transform, percent : float) -> Transform:
	var origin := tran.origin
	tran = tran.scaled(Vector3.ONE * percent)
	tran.origin = origin
	return tran

func break_arm() -> void:
	var arm_bone_names := [
#		"pelvis",
#		"thighl",
#		"calfl",
#		"footl",
#		"balll",
#		"thighr",
#		"calfr",
#		"footr",
#		"ballr",
#		"spine_1",
#		"spine_2",
#		"neck_1",
#		"head",
#		"clavicler",
		"upperarmr",
		"lowerarmr",
		"handr",
		"thumb_1_r",
		"thumb_2_r",
		"thumb_3_r",
		"ring_1_r",
		"ring_2_r",
		"ring_3_r",
		"middle_1_r",
		"middle_2_r",
		"middle_3_r",
		"index_1_r",
		"index_2_r",
		"index_3_r",
#		"claviclel",
#		"upperarml",
#		"lowerarml",
#		"handl",
#		"thumb_1_l",
#		"thumb_2_l",
#		"thumb_3_l",
#		"ring_1_l",
#		"ring_2_l",
#		"ring_3_l",
#		"middle_1_l",
#		"middle_2_l",
#		"middle_3_l",
#		"index_1_l",
#		"index_2_l",
#		"index_3_l",
	]

	_skeleton_rag_doll.get_parent().remove_child(_skeleton_rag_doll)
	Global._world.add_child(_skeleton_rag_doll)
	if true:
		var reset_id := _skeleton_rag_doll.find_bone("clavicler")
		var reset_tran := _skeleton_rag_doll.get_bone_global_pose(reset_id)
		reset_tran = shrink(reset_tran, 0.0001)

		# Get all bone names
		var all_bone_names := []
		var total = _skeleton_rag_doll.get_bone_count()
		for i in total:
			var name = _skeleton_rag_doll.get_bone_name(i)
			all_bone_names.append(name)
#			print(name)

		# Save all bone transforms
		var transforms := {}
		for name in all_bone_names:
			var bone_id = _skeleton_rag_doll.find_bone(name)
			var tran := _skeleton_rag_doll.get_bone_global_pose(bone_id)
			transforms[name] = tran

		# Shrink all bone transforms
		for name in all_bone_names:
			var bone_id = _skeleton_rag_doll.find_bone(name)
			_skeleton_rag_doll.set_bone_global_pose_override(bone_id, reset_tran, 1.0, true)

		# Reset arm bone transforms to normal
		for name in arm_bone_names:
			var bone_id = _skeleton_rag_doll.find_bone(name)
			var tran = transforms[name]
			_skeleton_rag_doll.set_bone_global_pose_override(bone_id, tran, 1.0, true)

	##arm_bone = _skeleton_rag_doll.get_node("Physical Bone upperarmr")
	_skeleton_rag_doll.global_transform.origin = _skeleton.global_transform.origin
	_skeleton_rag_doll.get_node("Physical Bone upperarmr").global_transform.origin = _skeleton.get_node("Physical Bone upperarmr").global_transform.origin
	_skeleton_rag_doll.physical_bones_start_simulation()

	# Hide arm animation bones
	var spine_id := _skeleton.find_bone("spine_1")
	var tran := _skeleton.get_bone_global_pose(spine_id)
	tran = shrink(tran, 0.0001)
	for name in arm_bone_names:
		var bone_id := _skeleton.find_bone(name)
		_skeleton.set_bone_global_pose_override(bone_id, tran, 1.0, true)

func _on_skeleton_rag_doll_skeleton_updated() -> void:
	pass

