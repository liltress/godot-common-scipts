extends Node

## Singleton (Autoload) for saving progress to disc and retrieving it as needed

## Saves as a JSON to the godot data dir (platform dependent).
## Data is stored as Key Value pairs, Keys entered as Strings.
## Values can be any JSON supported type.

## Supports managing several files, differentiated by `_save_file_index`

## Ideal for unstructured data: misc flags, who has the player talked to, things that would be annoying to plan ahead.
## Unideal for structured data: character stats, inventories, positions of objects. 
## For those things make a custon solution with Godot Resources.

var debug := false ## enables saving to file with Actions

var _save_loaded := false
var _save_file_index: int
const _game_dir := "user://"

var _progress: Dictionary

enum SaveFileWriteResult { CreatedNewEntry, OverWrittenEntry, NotWrittenEntryExists, NotWrittenNoEntry, CreatedNewFile, OverwrittenFile }

func _ready() -> void:
	load_file(1)

func save_path(save_file_index) -> String:
	return "{0}saves/{1}/save.json".format([_game_dir, save_file_index])
func save_folder_path(save_file_index) -> String:
	return "{0}saves/{1}".format([_game_dir, save_file_index])

func _physics_process(_delta: float) -> void:
	if not _debug:
		return
	if Input.is_action_just_pressed("save_hotkey"):
		write_file_to_disc(_save_file_index)
	if Input.is_action_just_pressed("debug_save_entry"):
		write_new_entry("debug_{0}".format([Time.get_time_string_from_system()]), true)

func load_file(new_file_index: int) -> void: ## Loads file if there isnt one already.
	var _progress_file: FileAccess
	if _save_loaded:
		push_warning("attempted to load file while one already was")
		return
	_save_file_index = new_file_index
	_progress_file = FileAccess.open(save_path(new_file_index), FileAccess.READ)
	if _progress_file == null:
		push_warning("no save file found for this index, making a fresh one")
		_progress = {}
	else:
		_progress = JSON.parse_string(_progress_file.get_as_text())

func unload_file() -> void: ## Unloads save, does not save progress. Avoid doing mid-game.
	_save_loaded = false
	_progress = {}

func write_file_to_disc(file_index):
	var _progress_file: FileAccess
	if FileAccess.file_exists(save_path(file_index)):
		print("overwriting save")
	else:
		print("writing new save")
		DirAccess.open("user://").make_dir_recursive("saves/{0}".format([_save_file_index]))
		
	_progress_file = FileAccess.open(save_path(file_index), FileAccess.ModeFlags.WRITE)
	print(_progress_file)
	print(save_path(file_index))
		
	_progress_file.store_string(JSON.stringify(_progress))

func entry_exists(entry_id: StringName) -> bool: ## Checks if a save file entry exists.
	return _progress.has(entry_id)

func write_entry(entry_id: StringName, val) -> SaveFileWriteResult: ## Writes an entry, overwrites if it already exists.
	var res: SaveFileWriteResult
	if entry_exists(entry_id): res = SaveFileWriteResult.OverWrittenEntry
	else: res = SaveFileWriteResult.CreatedNewEntry
	
	_progress[entry_id] = val
	
	return res

func write_new_entry(entry_id, val) -> SaveFileWriteResult: ## Writes an entry, only if it doesnt exist already.
	if entry_exists(entry_id):
		return SaveFileWriteResult.NotWrittenEntryExists
	write_entry(entry_id, val)
	return SaveFileWriteResult.CreatedNewEntry

func overwrite_entry(entry_id, val) -> SaveFileWriteResult: ## Writes only over an existing entry.
	if entry_exists(entry_id):
		write_entry(entry_id, val)
		return SaveFileWriteResult.OverWrittenEntry
	return SaveFileWriteResult.NotWrittenNoEntry

func read_entry(entry_id): ## Returns value under the given ID, take caution as it can be any given JSON type.
	return _progress[entry_id]
