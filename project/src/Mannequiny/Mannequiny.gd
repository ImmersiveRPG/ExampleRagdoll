# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

#tool
extends Spatial

signal hit(origin, bullet_type, collider)
signal hit_body_part(origin, body_part, bullet_type)

var is_ragdoll := false
var _bone_names := []
var _skeleton : Skeleton = null

func _ready() -> void:
	_skeleton = $root/Skeleton

	# Get a list of all bone names
	var total = _skeleton.get_bone_count()
	for i in total:
		var name = _skeleton.get_bone_name(i)
		if _skeleton.has_node("Physical Bone %s" % [name]):
			_bone_names.append(name)

func _on_hit(origin : Vector3, bullet_type : int, collider : Area) -> void:
	#print("?? _on_hit(%s, %s)" % [bullet_type, collider])
	var collision_2_body_part := {
		$"root/Skeleton/Physical Bone neck_1/Head" : Global.BodyPart.Head,
		$"root/Skeleton/Physical Bone spine_2/Chest" : Global.BodyPart.Torso,
		$"root/Skeleton/Physical Bone pelvis/Pelvis" : Global.BodyPart.Pelvis,
		$"root/Skeleton/Physical Bone upperarml/ArmUpperLeft" : Global.BodyPart.UpperArm,
		$"root/Skeleton/Physical Bone upperarmr/ArmUpperRight" : Global.BodyPart.UpperArm,
		$"root/Skeleton/Physical Bone lowerarml/ArmLowerLeft" : Global.BodyPart.LowerArm,
		$"root/Skeleton/Physical Bone lowerarmr/ArmLowerRight" : Global.BodyPart.LowerArm,
		$"root/Skeleton/Physical Bone thighl/LegUpperLeft" : Global.BodyPart.UpperLeg,
		$"root/Skeleton/Physical Bone thighr/LegUpperRight" : Global.BodyPart.UpperLeg,
		$"root/Skeleton/Physical Bone calfl/LegLowerLeft" : Global.BodyPart.LowerLeg,
		$"root/Skeleton/Physical Bone calfr/LegLowerRight" : Global.BodyPart.LowerLeg,
	}

	var body_part = collision_2_body_part[collider]
	self.emit_signal("hit_body_part", origin, body_part, bullet_type)

func _on_skeleton_updated() -> void:
	var parent_rotation = Vector3(0.0, deg2rad(180.0), 0.0)
	parent_rotation = self.get_parent().get_parent().rotation

	# Join the animation bones and physical bones
	for entry in _bone_names:
		var physical_bone = _skeleton.get_node_or_null("Physical Bone %s" % [entry])
		var bone_id = _skeleton.find_bone(entry)

		# Move animation bone to location of physical bone
		if is_ragdoll:
			# FIXME: Add air friction to prevent bones from flopping all over when they
			# should slowly stop moving
			pass
			#_skeleton.get_bone_global_pose(bone_id).origin = physical_bone.global_transform.origin - self.global_transform.origin
		# Move physical bone to location of animation bone
		elif physical_bone:
			physical_bone.global_transform = _skeleton.get_bone_global_pose(bone_id)
			physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y - deg2rad(180.0))
			physical_bone.global_transform.origin += self.global_transform.origin
