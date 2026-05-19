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

signal stars_updated(new_stars)
signal game_exited
const LAST_PROFILE_FILE = "user://last_profile.txt"

## Порог звёзд для разблокировки игр (если не открыта явно через unlocked_games)
const STARS_PER_GAME := {
	"game_1": 0,
	"game_2": 5,
	"game_3": 5,
	"game_4": 10,
	"game_5": 15,
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
	
		# НОВОЕ: Показываем топ-бар при загрузке профиля
	if TopBar:
		TopBar.visible = true
		TopBar._update_display()  # Обновляем данные
	
	if not current_profile.has("stars"):
		current_profile["stars"] = 0
	
	if not current_profile.has("unlocked_games"):
		current_profile["unlocked_games"] = ["game_1"]
	
	# Синхронизируем звёзды с порогами — автоматически разблокируем игры, если хватает звёзд
	_sync_unlocked_by_stars()
	stars_updated.emit(get_stars())
	
## Синхронизация: если звёзд достаточно для игры, но её нет в unlocked_games — добавляем
func _sync_unlocked_by_stars() -> void:
	var current_stars = get_stars()
	var unlocked = current_profile.get("unlocked_games", [])
	var changed = false
	
	for game_id in STARS_PER_GAME:
		if current_stars >= STARS_PER_GAME[game_id] and game_id not in unlocked:
			unlocked.append(game_id)
			changed = true
	
	if changed:
		current_profile["unlocked_games"] = unlocked
		_save_current_profile()

## Сохраняет текущий профиль (если есть имя)
func _save_current_profile() -> void:
	var profile_name = current_profile.get("name", "")
	if not profile_name.is_empty():
		ProfileManager.save_profile(profile_name, current_profile)

func get_stars() -> int:
	return current_profile.get("stars", 0)


func add_stars(amount: int) -> void:
	current_profile["stars"] = current_profile.get("stars", 0) + amount
	_sync_unlocked_by_stars()
	_save_current_profile()
	
	# Отправляем сигнал
	stars_updated.emit(current_profile["stars"])

func unlock_game(game_id: String) -> void:
	var unlocked: Array = current_profile.get("unlocked_games", [])
	if game_id not in unlocked:
		unlocked.append(game_id)
		current_profile["unlocked_games"] = unlocked
		_save_current_profile()

func is_game_unlocked(game_id: String) -> bool:
	# 1. Проверяем, есть ли игра в принципе
	if not GAMES.has(game_id):
		return false
	
	# 2. Проверяем явный список разблокированных (для обратной совместимости)
	var unlocked = current_profile.get("unlocked_games", [])
	if game_id in unlocked:
		return true
	
	# 3. Проверяем порог звёзд
	var required_stars = STARS_PER_GAME.get(game_id, 999)
	return get_stars() >= required_stars

func complete_game(game_id: String) -> void:
	# Начисляем звёзды за прохождение
	add_stars(STARS_REWARD)
	
	# После добавления звёзд синхронизация уже вызвана в add_stars()
	# Дополнительно можно вызвать unlock_game для всех игр, которые стали доступны
	_sync_unlocked_by_stars()

func change_scene(path: String) -> void:
	if _current_scene and _current_scene != self:
		_current_scene.queue_free()
		_current_scene = null
	
	# Пауза перед загрузкой новой сцены, чтобы избежать race condition
	await get_tree().process_frame
	
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
	game_exited.emit()
	change_scene("res://core/game_selector.tscn")

func open_main_menu() -> void:
	if TopBar:
		TopBar.visible = false
	game_exited.emit()
	change_scene("res://core/main_menu.tscn")

func open_profile_selector() -> void:
	change_scene("res://core/profile_selector.tscn")

func open_register_popup() -> void:
	change_scene("res://core/register_popup.tscn")
	
func save_last_profile(profile_name: String) -> void:
	var file = FileAccess.open(LAST_PROFILE_FILE, FileAccess.WRITE)
	file.store_string(profile_name)

func load_last_profile() -> String:
	if not FileAccess.file_exists(LAST_PROFILE_FILE):
		return ""
	var file = FileAccess.open(LAST_PROFILE_FILE, FileAccess.READ)
	return file.get_as_text()

func clear_last_profile() -> void:
	if FileAccess.file_exists(LAST_PROFILE_FILE):
		var dir = DirAccess.open("user://")
		dir.remove(LAST_PROFILE_FILE)

func update_top_bar(score: int = -1, mistakes: int = -1, max_mistakes: int = 0, round_info: String = ""):
	if TopBar and TopBar.has_method("update_game_stats"):
		TopBar.update_game_stats(score, mistakes, max_mistakes, round_info)
