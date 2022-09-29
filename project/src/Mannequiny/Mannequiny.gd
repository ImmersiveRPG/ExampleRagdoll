# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

tool
extends Spatial

signal hit(collider, origin, angle, force, bullet_type)

onready var _skeleton : Skeleton = $root/Skeleton
export var is_syncing_bones := true

var is_ragdoll := false
var _bone_names := []
var _has_body_part := {}

func _ready() -> void:
	# Init lookup tables of body parts
	for part in Global.BodyPart:
		var value = Global.BodyPart[part]
		_has_body_part[value] = true

	# Get a list of all bone names that have a physical and animation bone
	var total = _skeleton.get_bone_count()
	for i in total:
		var name = _skeleton.get_bone_name(i)
		if _skeleton.has_node("Physical Bone %s" % [name]):
			_bone_names.append(name)

func _on_hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	# Forward hit to NPC with body part info
	var name = collider.name.trim_prefix("Physical Bone ")
	var body_part = Global.physical_bone_2_body_part(name)
	self.owner.emit_signal("hit_body_part", body_part, origin, angle, force, bullet_type)

func _process(delta : float) -> void:
	if not is_ragdoll: return

	# Get the location of the spine animation bone
	var mount_id := _skeleton.find_bone("spine_1")
	var transform := _skeleton.get_bone_global_pose(mount_id)
	transform = Global.transform_shrink(transform, 0.001)

	# Get all broken body parts
	var to_tuck := 0
	for part in Global.BodyPart:
		var body_part = Global.BodyPart[part]
		if not self._has_body_part[body_part]:
			to_tuck |= body_part

	# Tuck all animation bones that attach to broken body parts
	var animation_bones = Global.body_parts_2_animation_bones(to_tuck)
	for name in animation_bones:
		var bone_id := _skeleton.find_bone(name)
		_skeleton.set_bone_global_pose_override(bone_id, transform, 1.0, true)

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

func start_ragdoll() -> void:
	$AnimationPlayer.stop()
	_skeleton.physical_bones_start_simulation()
	self.is_ragdoll = true

func apply_force_to_body_part(body_part : int, angle : Vector3, force : float) -> void:
	var name = Global.body_parts_2_animation_bones(body_part)[0]
	var physical_bone = self.get_node("root/Skeleton/Physical Bone %s" % [name])
	physical_bone.apply_central_impulse(angle * force)

func break_off_body_part(body_part : int, origin : Vector3, angle : Vector3, force : float) -> void:
	# Just return if does not have body part
	if not self._has_body_part[body_part]: return

	# Remove the body part and any connected parts
	match body_part:
		Global.BodyPart.Head:
			self._has_body_part[Global.BodyPart.Head] = false
		Global.BodyPart.Torso:
			self._has_body_part[Global.BodyPart.Torso] = false
		Global.BodyPart.Pelvis:
			self._has_body_part[Global.BodyPart.Pelvis] = false
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			self._has_body_part[Global.BodyPart.UpperArmR] = false
			self._has_body_part[Global.BodyPart.LowerArmR] = false
			self._has_body_part[Global.BodyPart.HandR] = false
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			self._has_body_part[Global.BodyPart.UpperArmL] = false
			self._has_body_part[Global.BodyPart.LowerArmL] = false
			self._has_body_part[Global.BodyPart.HandL] = false
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			self._has_body_part[Global.BodyPart.UpperLegR] = false
			self._has_body_part[Global.BodyPart.LowerLegR] = false
			self._has_body_part[Global.BodyPart.FootR] = false
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			self._has_body_part[Global.BodyPart.UpperLegL] = false
			self._has_body_part[Global.BodyPart.LowerLegL] = false
			self._has_body_part[Global.BodyPart.FootL] = false
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])
			return

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
			to_hide = Global.body_parts_2_animation_bones(Global.BodyPart.Head)
		Global.BodyPart.Torso:
			return
		Global.BodyPart.Pelvis:
			return
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmR | Global.BodyPart.LowerArmR | Global.BodyPart.HandR)
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmL | Global.BodyPart.LowerArmL | Global.BodyPart.HandL)
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegR | Global.BodyPart.LowerLegR | Global.BodyPart.FootR)
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			mount_id = _skeleton.find_bone("spine_1")
			to_hide = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegL | Global.BodyPart.LowerLegL | Global.BodyPart.FootL)
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])
			return

	# Hide animation bones by shrinking and tucking them inside mount
	var transform := _skeleton.get_bone_global_pose(mount_id)
	transform = Global.transform_shrink(transform, 0.0001)
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

	# Set the skeleton to owner of all its child nodes
	for child in Global.recursively_get_all_children(skeleton):
		if child != skeleton:
			child.owner = skeleton

	# Add script
	var script = load("res://src/Mannequiny/BrokenBodyPart.gd")
	skeleton.set_script(script)

	# Set position
	Global._world.add_child(skeleton)
	skeleton.global_transform = _skeleton.global_transform
	skeleton.global_rotation = _skeleton.global_rotation

	skeleton.start(body_part)
	#RuntimeInstancer.create_marker(skeleton)
	return skeleton
