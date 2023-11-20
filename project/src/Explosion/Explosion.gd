extends Node3D


# FIXME:
# 1. Make it apply force to broken off body parts
# 2. Make it dismemeber random parts from body
# 3. Add explosion with volumetric smoke

func start() -> void:
	#Engine.time_scale = 0.1

	const groups := ["mannequin", "item", "body_part"]
	const MAX_DISTANCE := 5.0
	#print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	for node in Global.recursively_get_all_children_in_groups(Global._world, groups):
		var distance := self.global_transform.origin.distance_to(node.global_transform.origin)
		if distance <= MAX_DISTANCE:
			var direction : Vector3 = self.global_transform.origin - node.global_transform.origin
			var angle : Vector3 = -direction.normalized()
			var power := 30.0
			var power_percent := 1.0 - (distance / MAX_DISTANCE)
			var force := power_percent * power
			#print([node, distance, power_percent])
			#var n := -1
			if node.is_in_group("mannequin"):
				node.owner.die()
				#node.push_at_angle(angle, 1000.0)

				# Blow off and push all body parts
				if power_percent >= 0.75:
					#n = 0
					const breaks := [
						Global.BodyPart.UpperArmR,
						Global.BodyPart.UpperArmL,
						Global.BodyPart.UpperLegR,
						Global.BodyPart.UpperLegL,
						Global.BodyPart.Head,
					]
					for body_part in breaks:
						var status = Global.BodyPartStatus.Destroyed
						var skeleton = node.set_body_part_status(body_part, status)
						if skeleton:
							# Get the physical bones of all the large parts
							# FIXME: This is duplicating the mannequin func from push_at_angle
							var bones := []
							for entry in Global.body_parts_2_animation_bones(Global.enum_all_values(Global.BodyPart)):
								var physical_bone = skeleton.get_node_or_null("Physical Bone %s" % [entry])
								if physical_bone:
									bones.append(physical_bone)

							for bone in bones:
								bone.apply_central_impulse(angle * force)
				# Just push the body
				else:
					#n = 1
					node.push_at_angle(angle, force)

				#node.push_at_angle(angle, 1000.0)
			elif node.is_in_group("body_part"):
				#n = 2
				node.apply_central_impulse(angle * force)
			elif node.is_in_group("item"):
				#n = 3
				node.apply_central_impulse(force * angle)
			#print([node, n, force])

@onready var _light := $OmniLight3D as OmniLight3D
func _physics_process(delta : float) -> void:
	_light.light_energy = clampf(_light.light_energy - delta * 1.0, 0.0, 100.0)
	_light.light_indirect_energy = clampf(_light.light_indirect_energy - delta * 1.0, 0.0, 100.0)


func _on_timer_die_timeout() -> void:
	#print("_on_timer_die_timeout")

	#Engine.time_scale = 1.0
	self.queue_free()


func _on_timer_stop_particles_timeout() -> void:
	$GPUParticles3D.emitting = false
