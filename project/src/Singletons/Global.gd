# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/workhorsy/PatreonRagdolls1

extends Node

const INT32_MAX := int(int(pow(2, 31)) - 1)
const INT64_MAX := int(int(pow(2, 63)) - 1)
const FLOAT64_MAX := float(INT64_MAX)

const AIR_FRICTION := 10.0
const FLOOR_FRICTION := 60.0
const GRAVITY := -40.0
const MOUSE_SENSITIVITY := 0.1
const MOUSE_ACCELERATION_X := 10.0
const MOUSE_ACCELERATION_Y := 10.0
const MOUSE_Y_MAX := 70.0
const MOUSE_Y_VEHICLE_MIN := -10.0
const MOUSE_Y_VEHICLE_MAX := 10.0
const MOUSE_Y_MIN := -60.0

@onready var _scene_bullet := ResourceLoader.load("res://src/Bullet/bullet.tscn")
@onready var _scene_bullet_glow := ResourceLoader.load("res://src/BulletGlow/bullet_glow.tscn")
@onready var _scene_bullet_spark := ResourceLoader.load("res://src/BulletSpark/bullet_spark.tscn")

enum Layers {
	terrain = 1 << 0,
	item = 1 << 1,
	player = 1 << 2,
	npc = 1 << 3,
	position_trigger = 1 << 4,
	furniture = 1 << 5,
	structure = 1 << 6,
	interact_point = 1 << 7,
	vehicle = 1 << 8,
	destructible = 1 << 9,
	smell = 1 << 10,
	sun = 1 << 11,
	liquid = 1 << 12,
	body_part = 1 << 13,
	animal = 1 << 14,
	label = 1 << 15,
	temperature = 1 << 16,
}

enum BodyPart {
	Head = 1 << 0,
	TorsoUpper = 1 << 1,
	TorsoMiddle = 1 << 2,
	TorsoLower = 1 << 3,
	Pelvis = 1 << 4,
	UpperArmL = 1 << 5,
	UpperArmR = 1 << 6,
	LowerArmL = 1 << 7,
	LowerArmR = 1 << 8,
	HandL = 1 << 9,
	HandR = 1 << 10,
	UpperLegL = 1 << 11,
	UpperLegR = 1 << 12,
	LowerLegL = 1 << 13,
	LowerLegR = 1 << 14,
	FootL = 1 << 15,
	FootR = 1 << 16,
}

enum BodyPartStatus {
	Normal,
	Crippled,
	Destroyed
}

enum BulletType {
	_50BMG,
	_308,
	_556,
	_45,
	_9MM,
	_22LR,
	_12Gauge,
}

const DB = {
	"Bullets" : {
		BulletType._50BMG : {
			"mass" : 0.023,
			"speed" : 1219.0,
			"max_distance" : 5000.0,
		},
		BulletType._308 : {
			"mass" : 0.018,
			"speed" : 1219.0,
			"max_distance" : 5000.0,
		},
		BulletType._556 : {
			"mass" : 0.016,
			"speed" : 1219.0,
			"max_distance" : 5000.0,
		},
		BulletType._45 : {
			"mass" : 0.0099,
			"speed" : 300.0,
			"max_distance" : 2000.0,
		},
		BulletType._9MM : {
			"mass" : 0.0075,
			"speed" : 400.0,
			"max_distance" : 2000.0,
		},
		BulletType._22LR : {
			"mass" : 0.0050,
			"speed" : 300.0,
			"max_distance" : 2000.0,
		},
		BulletType._12Gauge : {
			"mass" : 0.0025,
			"speed" : 200.0,
			"max_distance" : 500.0,
		},
	}
}

# Scales a transform without affecting the origin
func transform_shrink(tran : Transform3D, percent : float) -> Transform3D:
	var origin := tran.origin
	tran = tran.scaled(Vector3.ONE * percent)
	tran.origin = origin
	return tran

func rand_vector(min_val : float, max_val : float) -> Vector3:
	return Vector3(
		randf_range(min_val, max_val),
		randf_range(min_val, max_val),
		randf_range(min_val, max_val)
	)

func array_random_index(array : Array) -> int:
	var i : int = randi_range(0, array.size() - 1)
	return i

func array_random_value(array : Array):
	var i : int = array_random_index(array)
	return array[i]

func enum_all_values(the_enum : Dictionary) -> int:
	var retval := 0
	for values in the_enum.values():
		retval += values
	return retval

func enum_name_from_value(the_enum : Dictionary, enum_value : int) -> String:
	for entry in the_enum:
		var value = the_enum[entry]
		if value == enum_value:
			return entry

	return ""

func enum_max_value(the_enum : Dictionary) -> int:
	var max_value := -1
	for value in the_enum.values():
		if value > max_value:
			max_value = value

	return max_value

func recursively_get_all_children(target : Node) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.is_empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		matches.append(entry)

	return matches

func recursively_get_all_children_in_filter(target : Node, filter_cb : Callable) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.is_empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		if filter_cb.call(entry):
			matches.append(entry)

	return matches

func recursively_get_all_children_in_group(target : Node, group_name : String) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.is_empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		if entry.is_in_group(group_name):
			matches.append(entry)

	return matches

func get_input_action_name(event : InputEvent) -> String:
	# Get the action name for the key pressed
	#print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	for action in InputMap.get_actions():
		for entry in InputMap.action_get_events(action):
			if entry is InputEventKey and event is InputEventKey:
				if event.physical_keycode == entry.physical_keycode:
					return action
			elif entry is InputEventMouseButton and event is InputEventMouseButton:
				return action

	#print("###################################")
	return ""

const bone_names := {
	BodyPart.Head : [
		"mixamorig_Neck",
		"mixamorig_Head",
	],
	BodyPart.TorsoUpper : [
		"mixamorig_Spine2",
		"mixamorig_LeftShoulder",
		"mixamorig_RightShoulder",
	],
	BodyPart.TorsoMiddle : [
		"mixamorig_Spine1",
	],
	BodyPart.TorsoLower : [
		"mixamorig_Spine",
	],
	BodyPart.Pelvis : [
		"mixamorig_Hips",
	],
	BodyPart.UpperArmL : [
		"mixamorig_LeftArm",
	],
	BodyPart.UpperArmR : [
		"mixamorig_RightArm",
	],
	BodyPart.LowerArmL : [
		"mixamorig_LeftForeArm",
	],
	BodyPart.LowerArmR : [
		"mixamorig_RightForeArm",
	],
	BodyPart.HandL : [
		"mixamorig_LeftHand",
		"mixamorig_LeftHandThumb1",
		"mixamorig_LeftHandThumb2",
		"mixamorig_LeftHandThumb3",
		"mixamorig_LeftHandIndex1",
		"mixamorig_LeftHandIndex2",
		"mixamorig_LeftHandIndex3",
		"mixamorig_LeftHandMiddle1",
		"mixamorig_LeftHandMiddle2",
		"mixamorig_LeftHandMiddle3",
		"mixamorig_LeftHandRing1",
		"mixamorig_LeftHandRing2",
		"mixamorig_LeftHandRing3",
		"mixamorig_LeftHandPinky1",
		"mixamorig_LeftHandPinky2",
		"mixamorig_LeftHandPinky3",
	],
	BodyPart.HandR : [
		"mixamorig_RightHand",
		"mixamorig_RightHandThumb1",
		"mixamorig_RightHandThumb2",
		"mixamorig_RightHandThumb3",
		"mixamorig_RightHandIndex1",
		"mixamorig_RightHandIndex2",
		"mixamorig_RightHandIndex3",
		"mixamorig_RightHandMiddle1",
		"mixamorig_RightHandMiddle2",
		"mixamorig_RightHandMiddle3",
		"mixamorig_RightHandRing1",
		"mixamorig_RightHandRing2",
		"mixamorig_RightHandRing3",
		"mixamorig_RightHandPinky1",
		"mixamorig_RightHandPinky2",
		"mixamorig_RightHandPinky3",
	],
	BodyPart.UpperLegL : [
		"mixamorig_LeftUpLeg",
	],
	BodyPart.UpperLegR : [
		"mixamorig_RightUpLeg",
	],
	BodyPart.LowerLegL : [
		"mixamorig_LeftLeg",
	],
	BodyPart.LowerLegR : [
		"mixamorig_RightLeg",
	],
	BodyPart.FootL : [
		"mixamorig_LeftFoot",
		"mixamorig_LeftToeBase",
	],
	BodyPart.FootR : [
		"mixamorig_RightFoot",
		"mixamorig_RightToeBase",
	],
}

func body_parts_2_animation_bones(body_parts : int) -> Array:
	var values := []

	for key in BodyPart.values():
		if body_parts & key > 0:
			for entry in bone_names[key]:
				values.append(entry)

	return values

func physical_bone_2_body_part(entry : String) -> int:
	for body_part_value in bone_names:
		#print(body_part_value)
		var animations = bone_names[body_part_value]
		for animation in animations:
			if entry == animation:
				return body_part_value
	return -1

func get_skeleton_mount_bone(skeleton : Skeleton3D, body_part : Global.BodyPart) -> PhysicalBone3D:
	var mount_bone : PhysicalBone3D = null

	match body_part:
		Global.BodyPart.Head:
			var entry = Global.body_parts_2_animation_bones(Global.BodyPart.Head)[0]
			mount_bone = skeleton.get_node("Physical Bone %s" % [entry])
		Global.BodyPart.TorsoUpper, Global.BodyPart.TorsoMiddle, Global.BodyPart.TorsoLower:
			pass
		Global.BodyPart.Pelvis:
			pass
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			var entry = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmR)[0]
			mount_bone = skeleton.get_node("Physical Bone %s" % [entry])
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			var entry = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmL)[0]
			mount_bone = skeleton.get_node("Physical Bone %s" % [entry])
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			var entry = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegR)[0]
			mount_bone = skeleton.get_node("Physical Bone %s" % [entry])
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			var entry = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegL)[0]
			mount_bone = skeleton.get_node("Physical Bone %s" % [entry])
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])

	return mount_bone

func get_skeleton_animation_bones(skeleton : Skeleton3D, body_part : Global.BodyPart) -> Array:
	var animation_bones := []

	match body_part:
		Global.BodyPart.Head:
			animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.Head)
		Global.BodyPart.TorsoUpper, Global.BodyPart.TorsoMiddle, Global.BodyPart.TorsoLower:
			pass
		Global.BodyPart.Pelvis:
			pass
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmR | Global.BodyPart.LowerArmR | Global.BodyPart.HandR)
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperArmL | Global.BodyPart.LowerArmL | Global.BodyPart.HandL)
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegR | Global.BodyPart.LowerLegR | Global.BodyPart.FootR)
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			animation_bones = Global.body_parts_2_animation_bones(Global.BodyPart.UpperLegL | Global.BodyPart.LowerLegL | Global.BodyPart.FootL)
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])

	return animation_bones

func get_skeleton_tuck_bone(skeleton : Skeleton3D, body_part : Global.BodyPart) -> int:
	var tuck_bone_id := -1
	match body_part:
		Global.BodyPart.Head:
			tuck_bone_id = skeleton.find_bone(Global.bone_names[Global.BodyPart.TorsoUpper][0])
		Global.BodyPart.TorsoUpper, Global.BodyPart.TorsoMiddle, Global.BodyPart.TorsoLower:
			pass
		Global.BodyPart.Pelvis:
			pass
		Global.BodyPart.UpperArmR, Global.BodyPart.LowerArmR, Global.BodyPart.HandR:
			tuck_bone_id = skeleton.find_bone(Global.bone_names[Global.BodyPart.TorsoMiddle][0])
		Global.BodyPart.UpperArmL, Global.BodyPart.LowerArmL, Global.BodyPart.HandL:
			tuck_bone_id = skeleton.find_bone(Global.bone_names[Global.BodyPart.TorsoMiddle][0])
		Global.BodyPart.UpperLegR, Global.BodyPart.LowerLegR, Global.BodyPart.FootR:
			tuck_bone_id = skeleton.find_bone(Global.bone_names[Global.BodyPart.Pelvis][0])
		Global.BodyPart.UpperLegL, Global.BodyPart.LowerLegL, Global.BodyPart.FootL:
			tuck_bone_id = skeleton.find_bone(Global.bone_names[Global.BodyPart.Pelvis][0])
		_:
			push_error("Unexpected Global.BodyPart: %s" % [body_part])

	return tuck_bone_id

func hookes_law(displacement : Vector3, current_velocity : Vector3, stiffness : float, damping : float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func safe_look_at(spatial : Node3D, target: Vector3) -> void:
	var origin : Vector3 = spatial.global_transform.origin
	var v_z := (origin - target).normalized()

	# Just return if at same position
	if origin == target:
		return

	# Find an up vector that we can rotate around
	var up := Vector3.ZERO
	for entry in [Vector3.UP, Vector3.RIGHT, Vector3.BACK]:
		var v_x : Vector3 = entry.cross(v_z).normalized()
		if v_x.length() != 0:
			up = entry
			break

	# Look at the target
	if up != Vector3.ZERO:
		spatial.look_at(target, up)

func create_bullet_spark(pos : Vector3) -> void:
	var spark = _scene_bullet_spark.instantiate()
	Global._world.add_child(spark)
	spark.global_transform.origin = pos

func create_bullet(parent : Node, start_pos : Vector3, target_pos : Vector3, bullet_type : BulletType, spread : float) -> void:
	var bullet = _scene_bullet.instantiate()
	parent.add_child(bullet)
	bullet.global_transform.origin = start_pos
	Global.safe_look_at(bullet, target_pos)

	var rand = Global.rand_vector(-spread, spread)
	#print(rand)
	bullet.rotate_x(deg_to_rad(rand.x))
	bullet.rotate_y(deg_to_rad(rand.y))
	bullet.rotate_z(deg_to_rad(rand.z))

	bullet.start(bullet_type)

var _world : Node = null
