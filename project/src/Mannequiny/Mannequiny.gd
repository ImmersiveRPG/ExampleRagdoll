# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

tool
extends Spatial

signal hit(collider, origin, angle, force, bullet_type)

var is_ragdoll := false
var _bone_names := []
var _skeleton : Skeleton = null
export var is_syncing_bones := true

onready var physical_bone_2_body_part := {
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

onready var body_part_2_physical_bone := {
	Global.BodyPart.Head : $"root/Skeleton/Physical Bone neck_1",
	Global.BodyPart.Torso : $"root/Skeleton/Physical Bone spine_2",
	Global.BodyPart.Pelvis : $"root/Skeleton/Physical Bone pelvis",
	Global.BodyPart.UpperArmL : $"root/Skeleton/Physical Bone upperarml",
	Global.BodyPart.UpperArmR : $"root/Skeleton/Physical Bone upperarmr",
	Global.BodyPart.LowerArmL : $"root/Skeleton/Physical Bone lowerarml",
	Global.BodyPart.LowerArmR : $"root/Skeleton/Physical Bone lowerarmr",
	Global.BodyPart.LowerArmR : $"root/Skeleton/Physical Bone handr",
	Global.BodyPart.LowerArmL : $"root/Skeleton/Physical Bone handl",
	Global.BodyPart.UpperLegL : $"root/Skeleton/Physical Bone thighl",
	Global.BodyPart.UpperLegR : $"root/Skeleton/Physical Bone thighr",
	Global.BodyPart.LowerLegL : $"root/Skeleton/Physical Bone calfl",
	Global.BodyPart.LowerLegR : $"root/Skeleton/Physical Bone calfr",
	Global.BodyPart.LowerLegL : $"root/Skeleton/Physical Bone footl",
	Global.BodyPart.LowerLegR : $"root/Skeleton/Physical Bone footr",
}

func _ready() -> void:
	_skeleton = $root/Skeleton

	# Get a list of all bone names that have a physical and animation bone
	var total = _skeleton.get_bone_count()
	for i in total:
		var name = _skeleton.get_bone_name(i)
		if _skeleton.has_node("Physical Bone %s" % [name]):
			_bone_names.append(name)

func _on_hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	# Forward hit to NPC with body part info
	var body_part = physical_bone_2_body_part[collider]
	self.owner.emit_signal("hit_body_part", body_part, origin, angle, force, bullet_type)

func _on_skeleton_updated() -> void:
	if not is_syncing_bones: return
	if is_ragdoll: return
	if not _skeleton: return

	var parent_rotation = Vector3(0.0, 0.0, 0.0)
	if not Engine.editor_hint:
		parent_rotation = self.get_parent().get_parent().rotation

	# Join the animation bones and physical bones
	for entry in _bone_names:
		var physical_bone = _skeleton.get_node_or_null("Physical Bone %s" % [entry])
		if not physical_bone:
			continue

		# Move physical bone to location of animation bone
		var bone_id = _skeleton.find_bone(entry)
		if physical_bone:
			physical_bone.global_transform = _skeleton.get_bone_global_pose(bone_id)
			physical_bone.global_transform = physical_bone.global_transform.rotated(Vector3.UP, parent_rotation.y)
			physical_bone.global_transform.origin += self.global_transform.origin

func break_off_body_part(body_part : int, origin : Vector3, angle : Vector3, force : float) -> void:
	#Engine.time_scale = 0.1

	# Duplicate the body part and fling it
	var broken_skeleton = self.duplicate_body_part_into_own_skeleton(body_part)
	broken_skeleton._mount_bone.apply_central_impulse(angle * force)

	# Hide the body part
	self.hide_body_part(body_part)

func hide_body_part(body_part : int) -> void:
	# Get the names of all the animation bones for this body part
	var to_hide := []
	var mount_id := -1
	match body_part:
		Global.BodyPart.Head:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.head_bone_names
		Global.BodyPart.Torso:
			return
		Global.BodyPart.Pelvis:
			return
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.right_arm_bone_names
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.left_arm_bone_names
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.right_leg_bone_names
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.left_leg_bone_names
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])
			return

	# Hide animation bones by shrinking and tucking them inside mount
	var transform := _skeleton.get_bone_global_pose(mount_id)
	transform = Global.shrink_transform(transform, 0.0001)
	for name in to_hide:
		var bone_id := _skeleton.find_bone(name)
		_skeleton.set_bone_global_pose_override(bone_id, transform, 1.0, true)

func duplicate_body_part_into_own_skeleton(body_part : int) -> Skeleton:
	# Duplicate the skeleton without attached signals
	var flags := 0
	#flags += DUPLICATE_SIGNALS
	flags += DUPLICATE_GROUPS
	flags += DUPLICATE_SCRIPTS
	flags += DUPLICATE_USE_INSTANCING
	var skeleton = _skeleton.duplicate(flags)

	# Add script
	skeleton.set_script(load("res://src/Mannequiny/broken_body_part.gd"))
	#skeleton.get_parent().remove_child(skeleton)
	Global._world.add_child(skeleton)
	skeleton.global_transform = _skeleton.global_transform
	skeleton.global_rotation = _skeleton.global_rotation

	skeleton.start(body_part)
	return skeleton

