# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Skeleton

var all_bone_names := [
	"pelvis",
	"thighl",
	"calfl",
	"footl",
	"balll",
	"thighr",
	"calfr",
	"footr",
	"ballr",
	"spine_1",
	"spine_2",
	"neck_1",
	"head",
	"clavicler",
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
	"claviclel",
	"upperarml",
	"lowerarml",
	"handl",
	"thumb_1_l",
	"thumb_2_l",
	"thumb_3_l",
	"ring_1_l",
	"ring_2_l",
	"ring_3_l",
	"middle_1_l",
	"middle_2_l",
	"middle_3_l",
	"index_1_l",
	"index_2_l",
	"index_3_l",
]
var right_arm_bone_names := [
#	"pelvis",
#	"thighl",
#	"calfl",
#	"footl",
#	"balll",
#	"thighr",
#	"calfr",
#	"footr",
#	"ballr",
#	"spine_1",
#	"spine_2",
#	"neck_1",
#	"head",
#	"clavicler",
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
#	"claviclel",
#	"upperarml",
#	"lowerarml",
#	"handl",
#	"thumb_1_l",
#	"thumb_2_l",
#	"thumb_3_l",
#	"ring_1_l",
#	"ring_2_l",
#	"ring_3_l",
#	"middle_1_l",
#	"middle_2_l",
#	"middle_3_l",
#	"index_1_l",
#	"index_2_l",
#	"index_3_l",
]

var is_arm_broken := false
onready var _right_shoulder := $"Physical Bone upperarmr"

func _ready() -> void:
#	# Save all bone transforms
#	var transforms := {}
#	for name in all_bone_names:
#		var bone_id : int = self.find_bone(name)
#		var tran : Transform = self.get_bone_global_pose(bone_id)
#		transforms[name] = tran
	pass

func start() -> void:
	# Move physical bones to location of animation bones
	for entry in all_bone_names:
		var physical_bone = self.get_node_or_null("Physical Bone %s" % [entry])
		if physical_bone:
			var bone_id = self.find_bone(entry)
			physical_bone.global_transform = self.get_bone_global_pose(bone_id)
			#physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y - deg2rad(180.0))
			physical_bone.global_transform.origin += self.global_transform.origin

	# Remove all non arm physical bones
	for name in all_bone_names:
		if not right_arm_bone_names.has(name):
			var physical_bone = self.get_node_or_null("Physical Bone %s" % [name])
			if physical_bone:
				physical_bone.queue_free()

	self.physical_bones_start_simulation()
	self.is_arm_broken = true
	pass

func shrink(tran : Transform, percent : float) -> Transform:
	var origin := tran.origin
	tran = tran.scaled(Vector3.ONE * percent)
	tran.origin = origin
	return tran

func _process(delta : float) -> void:
	if is_arm_broken:
		# Tuck all animation bones that are not arm into sholder
		var pos = _right_shoulder.global_transform
		pos = shrink(pos, 0.001)
		for name in all_bone_names:
			if not right_arm_bone_names.has(name):
				var bone_id = self.find_bone(name)
				self.set_bone_global_pose_override(bone_id, pos, 1.0, true)
