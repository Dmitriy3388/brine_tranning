extends Node

const PROFILES_DIR = "user://profiles/"

func _ready():
	# Создаём папку для профилей, если её нет
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_absolute(PROFILES_DIR)

func create_profile(name: String, gender: String) -> Dictionary:
	var profile = {
		"name": name,
		"gender": gender,
		"level": 1,
		"experience": 0,
		"stars": 0,
		"unlocked_games": ["game_2"],
		"created": Time.get_datetime_string_from_system()
	}
	save_profile(name, profile)
	return profile

func save_profile(name: String, data: Dictionary):
	var file = FileAccess.open(PROFILES_DIR + name + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_profile(name: String) -> Dictionary:
	var path = PROFILES_DIR + name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	return json

func get_all_profiles() -> Array:
	var profiles = []
	var dir = DirAccess.open(PROFILES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var name = file_name.replace(".json", "")
				profiles.append(load_profile(name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return profiles
