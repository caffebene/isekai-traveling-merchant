extends SceneTree

var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error("FAILED: " + message)
		quit(1)
		assert(value, message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node3D = load("res://scenes/battle_multilayer.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layers: Node3D = scene.get_node("Layers")
	var camera: Camera3D = scene.get_node("CameraRig/Camera3D")
	var ghost: Sprite3D = layers.get_node("TransitionGhost")
	check(scene is Node3D, "battle scene is a real 3D world")
	check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "battle scene uses a perspective camera")
	check(layers.get_child_count() == 9, "scene contains eight slices and one transition ghost")
	check(layers.get_child(0) is Sprite3D and layers.get_child(7) is Sprite3D, "all scene slices are Sprite3D planes")
	check(scene.get_node("Layers/Forest_01").texture != null, "first layer has an imported texture")
	check(scene.get_node("Layers/Forest_08").texture != null, "last layer has an imported texture")
	check(ghost.texture == scene.get_node("Layers/Forest_01").texture, "transition ghost reuses the outgoing layer texture")
	var first_material := scene.get_node("Layers/Forest_01").material_override as StandardMaterial3D
	var initial_ghost_material := ghost.material_override as StandardMaterial3D
	check(first_material.vertex_color_use_as_albedo, "front layer material applies Sprite3D fade modulation")
	check(initial_ghost_material.vertex_color_use_as_albedo, "transition ghost material applies Sprite3D fade modulation")
	check(scene.get_node("ProgressAnchor") != null, "scene has a forward progress anchor")
	check(scene.layer_order() == ["Forest_01", "Forest_02", "Forest_03", "Forest_04", "Forest_05", "Forest_06", "Forest_07", "Forest_08"], "initial layer queue is near to far")
	check(scene.get_child_count() == 4, "scene contains only 3D presentation nodes and no UI or gameplay nodes")
	check(camera.position == Vector3.ZERO, "camera stays fixed while the scene transition is presented")
	var first_z: float = scene.get_node("Layers/Forest_01").position.z
	var second_z: float = scene.get_node("Layers/Forest_02").position.z
	check(is_equal_approx(first_z, -scene.spacing), "first layer starts exactly one forward step ahead")
	check(is_equal_approx(first_z - second_z, scene.spacing), "layer interval equals the configured forward distance")
	check(scene.get_node("Layers/Forest_02").pixel_size > scene.get_node("Layers/Forest_01").pixel_size, "second layer is compensated to avoid excessive perspective shrink")
	# 过渡中首层淡出、Ghost（新增第 9 层）淡入，二者都从前进开始播放。
	scene.set_journey(0.0, 0.0, 0.95, true)
	scene.set_journey(0.03, 0.4, 0.95, true)
	scene._process(0.05)
	check(scene.transition_active, "transition remains active while moving")
	check(ghost.visible, "transition ghost is visible during travel")
	check(scene.get_node("Layers/Forest_01").modulate.a > 0.0 and scene.get_node("Layers/Forest_01").modulate.a < 1.0, "front layer fades during travel")
	check(ghost.modulate.a > 0.0 and ghost.modulate.a < 1.0, "ninth layer fades in during travel")
	check(camera.position == Vector3.ZERO, "camera remains fixed during the transition")
	scene.set_journey(0.075, 0.95, 0.95, true)
	check(scene.pending_finish, "background marks the completed travel for commit")
	check(not scene.is_journey_transition_complete(), "background is not complete before its visual commit")
	for _step in range(4):
		scene._process(0.033)
	check(scene.is_journey_transition_complete(), "background completes its transition before encounter")
	check(scene.layer_order()[0] == "Forest_02" and scene.layer_order()[7] == "Forest_01", "crossed layer is committed after the ghost transition")
	check(not ghost.visible, "transition ghost is hidden after commit")
	var encounter_camera: Vector3 = camera.position
	var encounter_order: Array[String] = scene.layer_order()
	scene.set_journey(0.075, 0.95, 0.95, false)
	check(scene.get_node("CameraRig/Camera3D").position == encounter_camera, "encounter state does not change the camera at the same depth")
	check(scene.layer_order() == encounter_order, "encounter state does not rebuild the layer queue")
	# 第二次前进时 Ghost 必须同步 Sprite 与材质纹理，否则遇怪提交帧会突变。
	scene.set_journey(0.075, 0.0, 0.95, true)
	var second_outgoing: Sprite3D = scene.layers[0]
	var ghost_material := ghost.material_override as StandardMaterial3D
	check(ghost.texture == second_outgoing.texture, "second transition ghost uses the current outgoing sprite texture")
	check(ghost_material.albedo_texture == second_outgoing.texture, "second transition ghost material uses the current outgoing texture")
	print("PASS: %d battle scene 3D checks" % checks)
	quit()
