extends Node3D


# FIXME:
# 1. Make it apply force to broken off body parts
# 2. Make it dismemeber random parts from body
# 3. Add explosion with volumetric smoke

func start() -> void:
	#Engine.time_scale = 0.1

	const groups := ["mannequin", "item", "body_part"]
	const MAX_DISTANCE := 5.0

	for node in Global.recursively_get_all_children_in_groups(Global._world, groups):
		var distance := self.global_transform.origin.distance_to(node.global_transform.origin)
		if distance <= MAX_DISTANCE:
			#print([node, distance])
			var direction : Vector3 = self.global_transform.origin - node.global_transform.origin
			var angle : Vector3 = -direction.normalized()
			var power := 30.0
			var power_percent := 1.0 - (distance / MAX_DISTANCE)
			var force := power_percent * power
			if node.is_in_group("mannequin"):
				node.owner.die()
				#node.push_at_angle(angle, 1000.0)
			elif node.is_in_group("body_part"):
				#print(["explosion hit", node])
				if node and node.owner:
					node.owner.emit_signal("hit", node, self.global_transform.origin, angle, force, Global.BulletType._50BMG)
			elif node.is_in_group("item"):
				node.apply_central_impulse(force * angle)




func _on_timer_die_timeout() -> void:
	print("_on_timer_die_timeout")

	#Engine.time_scale = 1.0
	self.queue_free()
