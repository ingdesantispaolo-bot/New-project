extends SceneTree

const PANEL := preload("res://scripts/ui/knowledge_codex_panel.gd")
const OUTPUT := "res://../artifacts/knowledge-codex"

var panel: KnowledgeCodexPanel

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var save := GameSaveManager.new()
	panel = PANEL.new()
	root.add_child(panel)
	panel.setup(save, ContentManager.new())
	panel.mark_encountered("matematica", ["tabelline", "problemi"])
	await _capture("manuale-desktop", Vector2i(1280, 720), "matematica", "tabelline")
	await _capture("manuale-tablet", Vector2i(900, 600), "italiano", "pensiero-linguaggio")
	print("Knowledge Codex probe OK — capture desktop/tablet")
	quit(0)

func _capture(file_name: String, viewport_size: Vector2i, subject: String, topic: String) -> void:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	panel.open_codex(subject, topic, "world")
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, file_name]))
