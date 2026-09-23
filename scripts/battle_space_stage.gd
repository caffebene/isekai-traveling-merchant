extends SubViewport

## SubViewport adapter used by the existing exploration/battle presenter.
## The presenter keeps its current UI and combat flow; this adapter only swaps
## the artwork source to the standalone perspective 3D battle scene.
const BATTLE_SCENE := preload("res://scenes/battle_multilayer.tscn")
const VIEW_SIZE := Vector2i(1600, 900)

var world: Node3D
var camera: Camera3D

func _ready() -> void:
	size = VIEW_SIZE
	transparent_bg = true
	own_world_3d = true
	msaa_3d = Viewport.MSAA_2X
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world = BATTLE_SCENE.instantiate()
	add_child(world)
	camera = world.get_node("CameraRig/Camera3D")
	camera.current = true

func set_journey(depth: float, elapsed: float, duration: float, moving: bool) -> void:
	if world != null and world.has_method("set_journey"):
		world.set_journey(depth, elapsed, duration, moving)

func is_journey_transition_complete() -> bool:
	if world == null:
		return true
	if world.has_method("is_journey_transition_complete"):
		return bool(world.is_journey_transition_complete())
	return true

func get_journey_depth_step() -> float:
	if world != null and world.has_method("get_journey_depth_step"):
		return world.get_journey_depth_step()
	return 0.075
