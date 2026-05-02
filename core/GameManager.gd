extends Node

## Текущий активный профиль
var current_profile: Dictionary = {}

## ID игр и соответствующие им пути к сценам
const GAMES := {
	"game_1": "res://scenes/game_1/game_1.tscn",
	"game_2": "res://scenes/game_2/game_2.tscn",
	"game_3": "res://scenes/game_3/game_3.tscn",
	"game_4": "res://scenes/game_4/game_4.tscn",
	"game_5": "res://scenes/game_5/game_5.tscn",
}

## Порог звёзд для разблокировки игр
const STARS_PER_GAME := {
	"game_1": 0,
	"game_2": 0,
	"game_3": 0,
	"game_4": 0,
	"game_5": 0,
}

## Звёзд за прохождение игры
const STARS_REWARD := 2

## Текущая открытая сцена
var _current_scene: Node = null


func _ready():
	## Запоминаем главную сцену как текущую, чтобы change_scene мог её удалить
	_current_scene = get_tree().current_scene


func set_profile(profile: Dictionary) -> void:
	current_profile = profile
	if not current_profile.has("stars"):
		current_profile["stars"] = 0
	if not current_profile.has("unlocked_games"):
		current_profile["unlocked_games"] = ["game_2"]


func get_stars() -> int:
	return current_profile.get("stars", 0)


func add_stars(amount: int) -> void:
	current_profile["stars"] = current_profile.get("stars", 0) + amount
	if not current_profile.get("name", "").is_empty():
		ProfileManager.save_profile(current_profile["name"], current_profile)


func unlock_game(game_id: String) -> void:
	var unlocked: Array = current_profile.get("unlocked_games", [])
	if game_id not in unlocked:
		unlocked.append(game_id)
		current_profile["unlocked_games"] = unlocked
		if not current_profile.get("name", "").is_empty():
			ProfileManager.save_profile(current_profile["name"], current_profile)


func is_game_unlocked(game_id: String) -> bool:
	if not STARS_PER_GAME.has(game_id):
		return false
	return get_stars() >= STARS_PER_GAME[game_id]


func complete_game(game_id: String) -> void:
	add_stars(STARS_REWARD)
	for id in STARS_PER_GAME:
		if id == game_id:
			continue
		if is_game_unlocked(id) and id not in current_profile.get("unlocked_games", []):
			unlock_game(id)


func change_scene(path: String) -> void:
	if _current_scene and _current_scene != self:
		_current_scene.queue_free()
		_current_scene = null

	var scene = load(path).instantiate()
	get_tree().root.add_child(scene)
	_current_scene = scene


func start_game(game_id: String) -> void:
	if not GAMES.has(game_id):
		return
	if not is_game_unlocked(game_id):
		return
	change_scene(GAMES[game_id])


func open_game_selector() -> void:
	change_scene("res://core/game_selector.tscn")


func open_main_menu() -> void:
	change_scene("res://core/main_menu.tscn")


func open_profile_selector() -> void:
	change_scene("res://core/profile_selector.tscn")


func open_register_popup() -> void:
	change_scene("res://core/register_popup.tscn")
