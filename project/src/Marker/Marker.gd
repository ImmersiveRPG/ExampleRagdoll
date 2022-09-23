extends Spatial


export var target_node : NodePath

func _process(delta : float) -> void:
	if target_node != null:
		var target = self.get_node(self.target_node)
		self.global_transform.origin = target.global_transform.origin
