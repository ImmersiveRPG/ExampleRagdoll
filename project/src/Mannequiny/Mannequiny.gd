# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

#tool
extends Spatial

signal hit(origin, bullet_type, collider)

var is_ragdoll := false
var _bone_names := []
var _skeleton : Skeleton = null
export var is_syncing_bones := true

onready var collision_2_body_part := {
	$"root/Skeleton/Physical Bone neck_1" : Global.BodyPart.Head,
	$"root/Skeleton/Physical Bone spine_2" : Global.BodyPart.Torso,
	$"root/Skeleton/Physical Bone pelvis" : Global.BodyPart.Pelvis,
	$"root/Skeleton/Physical Bone upperarml" : Global.BodyPart.UpperArmL,
	$"root/Skeleton/Physical Bone upperarmr" : Global.BodyPart.UpperArmR,
	$"root/Skeleton/Physical Bone lowerarml" : Global.BodyPart.LowerArmL,
	$"root/Skeleton/Physical Bone lowerarmr" : Global.BodyPart.LowerArmR,
	$"root/Skeleton/Physical Bone handr" : Global.BodyPart.LowerArmR,
	$"root/Skeleton/Physical Bone handl" : Global.BodyPart.LowerArmL,
	$"root/Skeleton/Physical Bone thighl" : Global.BodyPart.UpperLegL,
	$"root/Skeleton/Physical Bone thighr" : Global.BodyPart.UpperLegR,
	$"root/Skeleton/Physical Bone calfl" : Global.BodyPart.LowerLegL,
	$"root/Skeleton/Physical Bone calfr" : Global.BodyPart.LowerLegR,
	$"root/Skeleton/Physical Bone footl" : Global.BodyPart.LowerLegL,
	$"root/Skeleton/Physical Bone footr" : Global.BodyPart.LowerLegR,
}

func _ready() -> void:
	_skeleton = $root/Skeleton

	# Get a list of all bone names
	var total = _skeleton.get_bone_count()
	for i in total:
		var name = _skeleton.get_bone_name(i)
		if _skeleton.has_node("Physical Bone %s" % [name]):
			_bone_names.append(name)

func _on_hit(origin : Vector3, bullet_type : int, collider : Node) -> void:
	# Forward hit to NPC with body part info
	var body_part = collision_2_body_part[collider]
	self.owner.emit_signal("hit_body_part", origin, body_part, bullet_type)

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

func break_body_part(broke_part : int) -> void:
	#Engine.time_scale = 0.1

	# Duplicate the skeleton (without attached signals)
	var flags := 0
	#flags += DUPLICATE_SIGNALS
	flags += DUPLICATE_GROUPS
	flags += DUPLICATE_SCRIPTS
	flags += DUPLICATE_USE_INSTANCING
	var broken_skeleton = _skeleton.duplicate(flags)
	broken_skeleton.set_script(load("res://src/Mannequiny/skeleton_part.gd"))
	#broken_skeleton.get_parent().remove_child(broken_skeleton)
	Global._world.add_child(broken_skeleton)
	broken_skeleton.global_transform = _skeleton.global_transform
	broken_skeleton.start(broke_part)

#	var marker = Global._world.get_node("Marker")
#	#print([marker, marker.name, marker.get_script()])
#	marker.target_node = broken_skeleton.get_path()

	var to_not_remove := []
	var mount_id := -1
	match broke_part:
		Global.BodyPart.Head:
			mount_id = _skeleton.find_bone("spine_1")
			to_not_remove = Global.head_bone_names
		Global.BodyPart.Torso:
			return
		Global.BodyPart.Pelvis:
			return
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR:
			mount_id = _skeleton.find_bone("spine_1")
			to_not_remove = Global.right_arm_bone_names
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL:
			mount_id = _skeleton.find_bone("spine_1")
			to_not_remove = Global.left_arm_bone_names
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR:
			mount_id = _skeleton.find_bone("spine_1")
			to_not_remove = Global.right_leg_bone_names
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL:
			mount_id = _skeleton.find_bone("spine_1")
			to_not_remove = Global.left_leg_bone_names
		_:
			push_error("Unexpected Global.BodyPart: %s" % [broke_part])
			return

	# Hide broken animation bones by shrinking and tucking them inside mount
	var tran := _skeleton.get_bone_global_pose(mount_id)
	tran = Global.shrink(tran, 0.0001)
	for name in to_not_remove:
		var bone_id := _skeleton.find_bone(name)
		_skeleton.set_bone_global_pose_override(bone_id, tran, 1.0, true)
