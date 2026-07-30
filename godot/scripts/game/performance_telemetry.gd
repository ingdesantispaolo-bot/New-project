extends Node

## Telemetria leggera per release profiling. In Web pubblica un solo snapshot
## JSON ogni mezzo secondo; non conserva dati personali e non usa rete.

const SAMPLE_SECONDS := 0.5

var _elapsed := 0.0
var _by_scene: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < SAMPLE_SECONDS:
		return
	_elapsed = 0.0
	var scene_name := _scene_name()
	var fps := float(Performance.get_monitor(Performance.TIME_FPS))
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var memory_bytes := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var resource_count := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var previous: Dictionary = _by_scene.get(scene_name, {})
	var samples := int(previous.get("samples", 0)) + 1
	var minimum_fps := fps if samples == 1 or float(previous.get("minFps", 0.0)) <= 0.0 else minf(float(previous["minFps"]), fps)
	var steady_minimum_fps := float(previous.get("steadyMinFps", 0.0))
	if samples >= 3:
		steady_minimum_fps = fps if steady_minimum_fps <= 0.0 else minf(steady_minimum_fps, fps)
	_by_scene[scene_name] = {
		"samples": samples,
		"fps": snappedf(fps, 0.1),
		"minFps": snappedf(minimum_fps, 0.1),
		"steadyMinFps": snappedf(steady_minimum_fps, 0.1),
		"drawCalls": draw_calls,
		"maxDrawCalls": maxi(draw_calls, int(previous.get("maxDrawCalls", 0))),
		"memoryMiB": snappedf(float(memory_bytes) / 1048576.0, 0.1),
		"peakMemoryMiB": maxf(float(memory_bytes) / 1048576.0, float(previous.get("peakMemoryMiB", 0.0))),
		"nodes": node_count,
		"maxNodes": maxi(node_count, int(previous.get("maxNodes", 0))),
		"resources": resource_count,
	}
	if OS.has_feature("web"):
		var snapshot := {
			"scene": scene_name,
			"current": _by_scene[scene_name],
			"byScene": _by_scene,
			"sampledAtMs": Time.get_ticks_msec(),
		}
		JavaScriptBridge.eval("window.__eliTelemetry = %s;" % JSON.stringify(snapshot))

func snapshot() -> Dictionary:
	return {"scene": _scene_name(), "byScene": _by_scene.duplicate(true)}

func _scene_name() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return "startup"
	var exercise := scene.find_child("ExercisePlayer", true, false) as CanvasItem
	if exercise != null and exercise.visible:
		return "exercise"
	var normalized := scene.name.to_snake_case()
	if "outdoor" in normalized:
		return "world"
	if "hub" in normalized:
		return "ship"
	if "boot" in normalized:
		return "boot"
	return normalized
