# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/workhorsy/PatreonRagdolls1

extends Node3D

signal hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int)

var _physics_skeleton : Skeleton3D = null

var is_ragdoll := false
var _bone_names := []
var _body_part_status := {}

func _ready() -> void:
	# Setup duplication flags to get everything except scripts
	var flags := 0
	flags += DUPLICATE_SIGNALS
	flags += DUPLICATE_GROUPS
	#flags += DUPLICATE_SCRIPTS
	flags += DUPLICATE_USE_INSTANTIATION

	# Duplicate the animation skeleton into a new one for physics
	var animation_skeleton = $Armature/Skeleton3D
	var physics_skeleton = animation_skeleton.duplicate(flags)
	physics_skeleton.name = "PhysicsSkeleton3D"
	_physics_skeleton = physics_skeleton

	# Remove all the parts no longer needed from the animation skeleton
	for child in animation_skeleton.get_children():
		if child is PhysicalBone3D or child is BoneAttachment3D or child is MeshInstance3D:
			child.queue_free()

	# Set the script on the physics skeleton
	var script := load("res://src/Mannequin/physics_skeleton.gd")
	physics_skeleton.set_script(script)
	physics_skeleton._animation_skeleton = animation_skeleton
	physics_skeleton._is_syncing = false

	$Armature.add_child(physics_skeleton)

	# Set the skeleton's children to have the same owner as the original
	for child in Global.recursively_get_all_children(physics_skeleton):
		if child != physics_skeleton:
			child.owner = animation_skeleton.owner

	physics_skeleton._is_syncing = true

	# Init lookup tables of body parts
	for part in Global.BodyPart.values():
		_body_part_status[part] = Global.BodyPartStatus.Normal

	# Get a list of all bone names that have a physical and animation bone
	var total := _physics_skeleton.get_bone_count()
	#print(total)
	for i in total:
		var entry := _physics_skeleton.get_bone_name(i)
		#print(entry)
		if _physics_skeleton.has_node("Physical Bone %s" % [entry]):
			_bone_names.append(entry)
	#print(_bone_names)

func _on_hit(collider : Node, origin : Vector3, angle : Vector3, force : float, bullet_type : int) -> void:
	# Forward hit to NPC with body part info
	var name := collider.name.trim_prefix("Physical Bone ")
	var body_part := Global.physical_bone_2_body_part(name)
	self.owner.emit_signal("hit_body_part", collider, body_part, origin, angle, force, bullet_type)

# FIXME: This should only need to be done once on ragdoll start
func _process(_delta : float) -> void:
	if not is_ragdoll: return

	# Get the location of the spine animation bone
	var mount_id := _physics_skeleton.find_bone(Global.bone_names[Global.BodyPart.TorsoMiddle][0])
	var trans := _physics_skeleton.get_bone_global_pose(mount_id)
	trans = Global.transform_shrink(trans, 0.001)

	# Get all broken body parts
	var to_tuck := 0
	for part in Global.BodyPart:
		var body_part = Global.BodyPart[part]
		if _body_part_status[body_part] != Global.BodyPartStatus.Normal:
			to_tuck |= body_part

	# Tuck all animation bones that attach to broken body parts
	var animation_bones = Global.body_parts_2_animation_bones(to_tuck)
	for entry in animation_bones:
		var bone_id := _physics_skeleton.find_bone(entry)
		_physics_skeleton.set_bone_global_pose_override(bone_id, trans, 1.0, true)

func apply_force_to_body_part(body_part : Global.BodyPart, angle : Vector3, force : float) -> void:
	var entry = Global.body_parts_2_animation_bones(body_part)[0]
	var physical_bone = self.get_node("root/Skeleton/Physical Bone %s" % [entry])
	physical_bone.apply_central_impulse(angle * force)

func push_at_angle(angle : Vector3, force : float) -> void:
	# Get the physical bones of all the large parts
	var bones := []
	for entry in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
		var physical_bone = _physics_skeleton.get_node_or_null("Physical Bone %s" % [entry])
		if physical_bone:
			bones.append(physical_bone)

	# Fling the physical bones
	force = force / float(bones.size())
	for bone in bones:
		bone.apply_central_impulse(angle * force)

func set_body_part_status(body_part : Global.BodyPart, status : Global.BodyPartStatus) -> void:
	# Just return if the current part status is worse than the new body part status
	var prev_status = self._body_part_status[body_part]
	if prev_status >= status: return

	# Update the body part status and any connected parts
	match body_part:
		Global.BodyPart.Head:
			self._body_part_status[Global.BodyPart.Head] = status
		Global.BodyPart.TorsoUpper, Global.BodyPart.TorsoMiddle, Global.BodyPart.TorsoLower:
			self._body_part_status[Global.BodyPart.TorsoUpper] = status
			self._body_part_status[Global.BodyPart.TorsoMiddle] = status
			self._body_part_status[Global.BodyPart.TorsoLower] = status
		Global.BodyPart.Pelvis:
			self._body_part_status[Global.BodyPart.Pelvis] = status
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			self._body_part_status[Global.BodyPart.UpperArmR] = status
			self._body_part_status[Global.BodyPart.LowerArmR] = status
			self._body_part_status[Global.BodyPart.HandR] = status
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			self._body_part_status[Global.BodyPart.UpperArmL] = status
			self._body_part_status[Global.BodyPart.LowerArmL] = status
			self._body_part_status[Global.BodyPart.HandL] = status
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			self._body_part_status[Global.BodyPart.UpperLegR] = status
			self._body_part_status[Global.BodyPart.LowerLegR] = status
			self._body_part_status[Global.BodyPart.FootR] = status
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			self._body_part_status[Global.BodyPart.UpperLegL] = status
			self._body_part_status[Global.BodyPart.LowerLegL] = status
			self._body_part_status[Global.BodyPart.FootL] = status
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])
			return

	# Change the body part to crippled or destroyed
	match self._body_part_status[body_part]:
		Global.BodyPartStatus.Normal:
			pass
		Global.BodyPartStatus.Crippled:
			self._set_body_part_crippled(body_part)
		Global.BodyPartStatus.Destroyed:
			if prev_status == Global.BodyPartStatus.Normal:
				self._set_body_part_crippled(body_part)
			self._set_body_part_destroyed(body_part)
		_:
			push_error("Unexpected Global.BodyPartStatus: %s" % [body_part])


func _set_body_part_crippled(body_part : Global.BodyPart) -> void:
	# Figure out where to mount the crippled body part
	var tuck_bone_id := Global.get_skeleton_tuck_bone(_physics_skeleton, body_part)
	var to_hide := Global.get_skeleton_animation_bones(_physics_skeleton, body_part)

	# Duplicate the body part and attach it to the mount
	var broken_skeleton = self._duplicate_body_part_into_own_skeleton(body_part)
	#broken_skeleton._mount_bone.apply_central_impulse(angle * force)

	# Hide the original body part
	self._hide_body_part(to_hide, tuck_bone_id)

func _set_body_part_destroyed(body_part : Global.BodyPart) -> void:
	# Disconnect the body part from the mount
	var pin_joint = null
	match body_part:
		Global.BodyPart.Head:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorNeck/Anchor/PinJoint3D
		Global.BodyPart.UpperArmR:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorRightShoulder/Anchor/PinJoint3D
		Global.BodyPart.UpperArmL:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorLeftShoulder/Anchor/PinJoint3D
		Global.BodyPart.UpperLegR:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorRightHip/Anchor/PinJoint3D
		Global.BodyPart.UpperLegL:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorLeftHip/Anchor/PinJoint3D
		_:
			pass

	if pin_joint:
		var broken_skeleton = get_node(pin_joint.node_b).owner
		broken_skeleton._is_attached_to_parent_skeleton = false
		pin_joint.node_b = NodePath()

func _hide_body_part(to_hide : Array, tuck_bone_id : int) -> void:
	# Hide animation bones by shrinking and tucking them inside the tuck bone
	# and removing physical bones
	var trans := _physics_skeleton.get_bone_global_pose(tuck_bone_id)
	trans = Global.transform_shrink(trans, 0.0001)
	for entry in to_hide:
		var bone_id := _physics_skeleton.find_bone(entry)
		_physics_skeleton.set_bone_global_pose_override(bone_id, trans, 1.0, true)
		var bone := _physics_skeleton.get_node_or_null("Physical Bone %s" % [entry])
		if bone:
			bone.collision_layer = 0
			bone.collision_mask = 0
			bone.get_parent().remove_child(bone)
			bone.queue_free()

func _duplicate_body_part_into_own_skeleton(body_part : Global.BodyPart) -> Skeleton3D:
	# Duplicate the skeleton without attached signals
	var flags := 0
	#flags += DUPLICATE_SIGNALS
	flags += DUPLICATE_GROUPS
	#flags += DUPLICATE_SCRIPTS
	flags += DUPLICATE_USE_INSTANTIATION
	var skeleton = _physics_skeleton.duplicate(flags)

	# Remove any bone attachments
	for child in Global.recursively_get_all_children(skeleton):
		if child is BoneAttachment3D:
			child.get_parent().remove_child(child)
			child.queue_free()

	# Set the skeleton to owner of all its child nodes
	for child in Global.recursively_get_all_children(skeleton):
		if child != skeleton:
			child.owner = skeleton

	# Have bones stop reacting to physics
	skeleton.physical_bones_stop_simulation()
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			child.gravity_scale = 0.0

	# Set position
	Global._world.add_child(skeleton)
	#skeleton.global_transform = _physics_skeleton.global_transform # FIXME: Do we need this?
	#skeleton.global_rotation = _physics_skeleton.global_rotation # FIXME: Do we need this?

	# Add script
	var script = load("res://src/Mannequin/broken_body_part.gd")
	skeleton.set_script(script)
	skeleton.start(self.owner, body_part, _physics_skeleton)

	var pin_joint : PinJoint3D = null
	var anchor : StaticBody3D = null

	match body_part:
		Global.BodyPart.Head:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorNeck/Anchor/PinJoint3D
			anchor = $Armature/PhysicsSkeleton3D/AnchorNeck/Anchor
		Global.BodyPart.UpperArmR:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorRightShoulder/Anchor/PinJoint3D
			anchor = $Armature/PhysicsSkeleton3D/AnchorRightShoulder/Anchor
		Global.BodyPart.UpperArmL:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorLeftShoulder/Anchor/PinJoint3D
			anchor = $Armature/PhysicsSkeleton3D/AnchorLeftShoulder/Anchor
		Global.BodyPart.UpperLegR:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorRightHip/Anchor/PinJoint3D
			anchor = $Armature/PhysicsSkeleton3D/AnchorRightHip/Anchor
		Global.BodyPart.UpperLegL:
			pin_joint = $Armature/PhysicsSkeleton3D/AnchorLeftHip/Anchor/PinJoint3D
			anchor = $Armature/PhysicsSkeleton3D/AnchorLeftHip/Anchor
		_:
			pass

	# Move the PinJoint and Skeleton to anchor location, and pin Skeleton to anchor
	if pin_joint and anchor:
		skeleton.global_transform.origin = anchor.global_transform.origin
		skeleton._mount_bone.global_transform.origin = anchor.global_transform.origin - skeleton._mount_bone.body_offset.origin
		pin_joint.node_b = skeleton._mount_bone.get_path()

	return skeleton

func _start_ragdoll() -> void:
	$AnimationPlayer.stop()
	is_ragdoll = true

	for child in _physics_skeleton.get_children():
		if child is PhysicalBone3D:
			child.gravity_scale = 1.0
	_physics_skeleton._is_syncing = false

func _stop_ragdoll() -> void:
	$AnimationPlayer.play("idle")
	is_ragdoll = false

	for child in _physics_skeleton.get_children():
		if child is PhysicalBone3D:
			child.gravity_scale = 0.0
	_physics_skeleton._is_syncing = true
