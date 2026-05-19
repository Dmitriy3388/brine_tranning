extends Node

const PROFILES_DIR = "user://profiles/"

func _ready():
	# Создаём папку для профилей, если её нет
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_absolute(PROFILES_DIR)

func create_profile(name: String, gender: String) -> Dictionary:
	# Защита от дублей
	if profile_exists(name):
		var counter = 1
		var new_name = name + str(counter)
		while profile_exists(new_name):
			counter += 1
			new_name = name + str(counter)
		name = new_name
	
	var profile = {
		"name": name,
		"gender": gender,
		"level": 1,
		"experience": 0,
		"stars": 0,
		"unlocked_games": ["game_1"],
		"created": Time.get_datetime_string_from_system()
	}
	
	save_profile(name, profile)
	return profile

# НОВЫЙ МЕТОД: возвращает только имена профилей (быстро)
func get_all_profile_names() -> Array:
	var profile_names = []
	var dir = DirAccess.open(PROFILES_DIR)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var name = file_name.replace(".json", "")
				profile_names.append(name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return profile_names

# НОВЫЙ МЕТОД: загружает ТОЛЬКО выбранный профиль
func load_profile_light(name: String) -> Dictionary:
	var path = PROFILES_DIR + name + ".json"
	
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	
	# Загружаем только нужные поля (без stars и unlocked_games, если не нужно)
	return {
		"name": json.get("name", ""),
		"gender": json.get("gender", "male"),
		"created": json.get("created", "")
	}

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
				var profile = load_profile(name)
				if not profile.is_empty():
					profiles.append(profile)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return profiles

func profile_exists(name: String) -> bool:
	var path = PROFILES_DIR + name + ".json"
	return FileAccess.file_exists(path)

func delete_profile(name: String) -> bool:
	var path = PROFILES_DIR + name + ".json"
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(PROFILES_DIR)
		return dir.remove(path) == OK
	return false

func rename_profile(old_name: String, new_name: String) -> bool:
	if not profile_exists(old_name):
		return false
	
	if profile_exists(new_name):
		return false
	
	var old_path = PROFILES_DIR + old_name + ".json"
	var new_path = PROFILES_DIR + new_name + ".json"
	
	var dir = DirAccess.open(PROFILES_DIR)
	var error = dir.rename(old_path, new_path)
	
	if error == OK:
		var profile = load_profile(new_name)
		profile["name"] = new_name
		save_profile(new_name, profile)
		return true
	
	return false
