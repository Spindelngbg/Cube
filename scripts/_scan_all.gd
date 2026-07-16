extends SceneTree

func _init() -> void:
	call_deferred("_scan")

func _scan() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	_collect("res://addons", files)
	var failed := 0
	for path in files:
		if path.ends_with("_scan_all.gd") or path.ends_with("_diag.gd"):
			continue
		var res := ResourceLoader.load(path)
		if res == null:
			failed += 1
			print("FAIL ", path)
	print("TOTAL=", files.size(), " FAILED=", failed)
	quit()

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir.path_join(name)
		if d.current_is_dir():
			_collect(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()