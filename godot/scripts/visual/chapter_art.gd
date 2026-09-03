class_name ChapterArt
extends RefCounted

const TAVOLE := [
	"res://assets/story/chapter-01-awakening-v1.webp",
	"res://assets/story/chapter-02-machines-signals-v1.webp",
	"res://assets/story/chapter-03-living-systems-v1.webp",
	"res://assets/story/chapter-04-hidden-threshold-v1.webp",
	"res://assets/story/chapter-05-awake-guardian-v1.webp",
	"res://assets/story/chapter-06-convergence-v1.webp",
]

static func path_for_world(level: int) -> String:
	var chapter := clampi(floori(float(level - 1) / 4.0), 0, TAVOLE.size() - 1)
	return str(TAVOLE[chapter])

static func texture_for_world(level: int) -> Texture2D:
	var path := path_for_world(level)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
