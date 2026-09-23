extends Node3D

const STEP_DEPTH := 0.075
const BASE_PIXEL_SIZE := 0.0055

@export var spacing := 4.2

@export_range(0.88, 0.99, 0.005)
var layer_screen_ratio := 0.95

@export_range(-1.0, 1.0, 0.05)
var vertical_anchor := -0.20

@export_range(0.0, 0.8, 0.01)
var exit_fade_start := 0.05

@export_range(0.2, 1.0, 0.01)
var exit_fade_end := 0.82

@export_range(0.0, 0.8, 0.01)
var intro_fade_start := 0.05

@export_range(0.2, 1.0, 0.01)
var intro_fade_end := 0.88

@export var transition_follow_speed := 8.0
@export var max_visual_delta := 0.033


var progress_anchor: Node3D
var camera: Camera3D
var layers_root: Node3D

var layers: Array[Sprite3D] = []

var transition_ghost: Sprite3D

var transition_active := false
var transition_target := 0.0
var transition_visual := 0.0

var journey_moving := false

var transition_start_depth := 0.0
var last_depth := 0.0
var has_last_depth := false

var pending_finish := false

var reference_half_height := 0.0
var layout_origin_y := 0.0


func _ready() -> void:
	progress_anchor = get_node("ProgressAnchor") as Node3D
	camera = get_node("CameraRig/Camera3D") as Camera3D
	layers_root = get_node("Layers") as Node3D

	for child in layers_root.get_children():
		if child is Sprite3D:
			var layer: Sprite3D = child as Sprite3D
			layers.append(layer)
			_configure_layer(layer)

	layers.sort_custom(
		func(a: Sprite3D, b: Sprite3D) -> bool:
			return a.position.z > b.position.z
	)

	if layers.is_empty():
		return

	reference_half_height = (
		float(layers[0].texture.get_height())
		* BASE_PIXEL_SIZE
		* 0.5
	)

	camera.position = Vector3.ZERO
	progress_anchor.position = Vector3.ZERO

	_create_transition_ghost()
	_reset_layer_slots()
	_apply_layout()


func _process(delta: float) -> void:
	if transition_active:
		var safe_delta: float = minf(delta, max_visual_delta)

		transition_visual = move_toward(
			transition_visual,
			transition_target,
			safe_delta * transition_follow_speed
		)

		if pending_finish:
			transition_target = 1.0

	_apply_layout()

	if (
		transition_active
		and pending_finish
		and transition_visual >= 0.9999
	):
		_commit_transition()


func set_journey(
	depth: float,
	elapsed: float,
	duration: float,
	moving: bool
) -> void:
	if moving and not journey_moving:
		_begin_transition(depth)

	if transition_active:
		var duration_safe: float = maxf(duration, 0.001)

		var elapsed_progress: float = clampf(
			elapsed / duration_safe,
			0.0,
			1.0
		)

		var depth_progress: float = clampf(
			(depth - transition_start_depth) / STEP_DEPTH,
			0.0,
			1.0
		)

		transition_target = maxf(
			elapsed_progress,
			depth_progress
		)

		# 前进完成后外层仍保持 moving=true，等待背景完成提交。
		# 因此不能只依赖 moving=false 才触发收尾。
		if transition_target >= 0.999 or not moving:
			pending_finish = true
			transition_target = 1.0

	elif not moving:
		transition_target = 0.0
		transition_visual = 0.0

	journey_moving = moving
	last_depth = depth
	has_last_depth = true


func layer_order() -> Array[String]:
	var result: Array[String] = []

	for layer in layers:
		result.append(layer.name)

	return result


func get_journey_depth_step() -> float:
	return STEP_DEPTH


func is_journey_transition_complete() -> bool:
	return not transition_active


func _begin_transition(depth: float) -> void:
	if layers.is_empty():
		return

	if transition_active:
		return

	transition_active = true
	pending_finish = false

	transition_target = 0.0
	transition_visual = 0.0

	if has_last_depth:
		transition_start_depth = last_depth
	else:
		transition_start_depth = depth

	var outgoing: Sprite3D = layers[0]

	_set_layer_texture(
		transition_ghost,
		outgoing.texture
	)
	transition_ghost.visible = true
	transition_ghost.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)


func _commit_transition() -> void:
	if layers.is_empty():
		return

	var used_layer: Sprite3D = (
		layers.pop_front()
		as Sprite3D
	)

	used_layer.position = _slot_position(
		layers.size() - 1,
		0.0
	)

	used_layer.visible = true
	used_layer.modulate = Color.WHITE

	layers.push_back(used_layer)

	transition_ghost.visible = false
	transition_ghost.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	transition_active = false
	pending_finish = false

	transition_target = 0.0
	transition_visual = 0.0

	_reset_layer_slots()
	_apply_layout()


func _create_transition_ghost() -> void:
	var source: Sprite3D = layers[0]

	transition_ghost = (
		source.duplicate()
		as Sprite3D
	)

	transition_ghost.name = "TransitionGhost"

	layers_root.add_child(
		transition_ghost
	)

	_configure_layer(
		transition_ghost
	)

	transition_ghost.visible = false

	transition_ghost.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)


func _reset_layer_slots() -> void:
	for index in range(layers.size()):
		var layer: Sprite3D = layers[index]

		layer.position = _slot_position(
			index,
			0.0
		)

		layer.visible = true
		layer.modulate = Color.WHITE


func _apply_layout() -> void:
	if layers.is_empty():
		return

	var travel: float = 0.0

	if transition_active:
		travel = transition_visual

	for index in range(layers.size()):
		var layer: Sprite3D = layers[index]

		var distance_steps: float = (
			float(index + 1)
			- travel
		)

		distance_steps = maxf(
			distance_steps,
			0.001
		)

		var screen_ratio: float = pow(
			layer_screen_ratio,
			distance_steps - 1.0
		)

		layer.position.z = (
			-distance_steps
			* spacing
		)

		layer.pixel_size = (
			BASE_PIXEL_SIZE
			* screen_ratio
			* distance_steps
		)

		layer.position.x = 0.0

		layer.position.y = (
			layout_origin_y
			+ reference_half_height
			* distance_steps
			* (
				1.0
				- screen_ratio
			)
			* vertical_anchor
		)

		var alpha: float = 1.0

		if (
			transition_active
			and index == 0
		):
			alpha = _get_exit_alpha(
				transition_visual
			)

		layer.modulate = Color(
			1.0,
			1.0,
			1.0,
			alpha
		)

	if transition_active:
		_layout_transition_ghost()


func _layout_transition_ghost() -> void:
	if transition_ghost == null:
		return

	var distance_steps: float = (
		float(layers.size() + 1)
		- transition_visual
	)

	var screen_ratio: float = pow(
		layer_screen_ratio,
		distance_steps - 1.0
	)

	transition_ghost.position.z = (
		-distance_steps
		* spacing
	)

	transition_ghost.position.x = 0.0

	transition_ghost.pixel_size = (
		BASE_PIXEL_SIZE
		* screen_ratio
		* distance_steps
	)

	transition_ghost.position.y = (
		layout_origin_y
		+ reference_half_height
		* distance_steps
		* (
			1.0
			- screen_ratio
		)
		* vertical_anchor
	)

	transition_ghost.modulate = Color(
		1.0,
		1.0,
		1.0,
		_get_intro_alpha(
			transition_visual
		)
	)


func _slot_position(
	index: int,
	progress: float
) -> Vector3:
	var distance_steps: float = (
		float(index + 1)
		- progress
	)

	return Vector3(
		0.0,
		layout_origin_y,
		-distance_steps * spacing
	)


func _get_exit_alpha(
	progress: float
) -> float:
	var end_value: float = maxf(
		exit_fade_end,
		exit_fade_start + 0.001
	)

	var t: float = inverse_lerp(
		exit_fade_start,
		end_value,
		progress
	)

	t = clampf(
		t,
		0.0,
		1.0
	)

	t = smoothstep(
		0.0,
		1.0,
		t
	)

	return 1.0 - t


func _get_intro_alpha(
	progress: float
) -> float:
	var end_value: float = maxf(
		intro_fade_end,
		intro_fade_start + 0.001
	)

	var t: float = inverse_lerp(
		intro_fade_start,
		end_value,
		progress
	)

	t = clampf(
		t,
		0.0,
		1.0
	)

	return smoothstep(
		0.0,
		1.0,
		t
	)


func _configure_layer(
	layer: Sprite3D
) -> void:
	layer.pixel_size = BASE_PIXEL_SIZE

	layer.billboard = (
		BaseMaterial3D.BILLBOARD_DISABLED
	)

	layer.alpha_cut = (
		SpriteBase3D.ALPHA_CUT_DISABLED
	)

	var material := StandardMaterial3D.new()

	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	material.vertex_color_use_as_albedo = true

	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)

	material.albedo_texture = layer.texture

	layer.material_override = material


func _set_layer_texture(
	layer: Sprite3D,
	texture: Texture2D
) -> void:
	layer.texture = texture

	var material := (
		layer.material_override
		as StandardMaterial3D
	)

	if material != null:
		material.albedo_texture = texture
