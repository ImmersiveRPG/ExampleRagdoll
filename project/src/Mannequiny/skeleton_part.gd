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
var arm_bone_names := [
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

func _ready() -> void:
	pass

func shrink(tran : Transform, percent : float) -> Transform:
	var origin := tran.origin
	tran = tran.scaled(Vector3.ONE * percent)
	tran.origin = origin
	return tran

func _process(delta : float) -> void:
	if is_arm_broken:
		# Tuck all animation bones that are not arm into sholder
		var pos = self.get_node("Physical Bone upperarmr").global_transform
		pos = shrink(pos, 0.1)
		for name in all_bone_names:
			if not arm_bone_names.has(name):
				var bone_id = self.find_bone(name)
				self.set_bone_global_pose_override(bone_id, pos, 1.0, true)
