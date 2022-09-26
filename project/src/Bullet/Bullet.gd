# Copyright (c) 2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleRagdoll

extends Spatial

# Get the bullet info
var _bullet_type := -1
var _mass := -1.0
var _max_distance := -1.0
var _speed := 1219.0
var _ignore_collision_distance := 0.0
var _velocity : Vector3

var _total_distance := 0.0
onready var _ray = $RayCast



func _physics_process(delta : float) -> void:
	# Move the bullet
	var distance := _velocity.length() * delta
	self.transform.origin -= _velocity * delta

	# Change the ray start position to the bullets's previous position
	# NOTE: The ray is backwards, so if it is hitting multiple targets, we
	# get the target closest to the bullet start position.
	# Also make the ray at least 1 meter long
	if distance > 1.0:
		_ray.cast_to.z = -distance
		_ray.transform.origin.z = distance
	else:
		_ray.cast_to.z = -1.0
		_ray.transform.origin.z = 1.0

	if _ignore_collision_distance > 0.0:
		_ignore_collision_distance -= distance

	# Delete the bullet if it hit something
	_ray.force_raycast_update()
	if _ray.is_colliding() and _ignore_collision_distance <= 0.0:
		_ignore_collision_distance = 2.0
		var collider = _ray.get_collider()

		# Move the bullet back to the position of the collision
		self.global_transform.origin = _ray.get_collision_point()

		# Add bullet spark
		RuntimeInstancer.create_bullet_spark(self.global_transform.origin)

		if collider.is_in_group("body_part"):
			var force := _mass * _velocity.length()
			collider.owner.emit_signal("hit", self.global_transform.origin, -self.transform.basis.z, force, _bullet_type, collider)

			self.queue_free()
		else:
			print("Bullet hit %s" % [collider.name])

	# Delete the bullet if it has gone its max distance
	_total_distance += distance
	if _total_distance > _max_distance:
		self.queue_free()

func start(bullet_type : int) -> void:
	# Get the bullet info from the database
	_bullet_type = bullet_type
	var entry = Global.DB["Bullets"][_bullet_type]
	_mass = entry["mass"]
	_max_distance = entry["max_distance"]
	var speed = entry["speed"]
	_velocity = self.transform.basis.z * speed
	#print("Loaded values for %s" % self.name)

	# Add bullet glow
	RuntimeInstancer.create_bullet_glow(self)
