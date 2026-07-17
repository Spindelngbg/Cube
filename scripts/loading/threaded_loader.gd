class_name ThreadedLoader
extends RefCounted

## Bakgrundsladdning via ResourceLoader.load_threaded_request (worker-trådar).
## Scene tree får bara röras på main thread — den här klassen bara laddar resurser.


static func request(path: String, use_sub_threads: bool = true) -> Error:
	var p := path.strip_edges()
	if p == "" or not ResourceLoader.exists(p):
		return ERR_FILE_NOT_FOUND
	var status := ResourceLoader.load_threaded_get_status(p)
	if (
		status == ResourceLoader.THREAD_LOAD_IN_PROGRESS
		or status == ResourceLoader.THREAD_LOAD_LOADED
	):
		return OK
	return ResourceLoader.load_threaded_request(
		p,
		"",
		use_sub_threads,
		ResourceLoader.CACHE_MODE_REUSE
	)


static func request_many(paths: PackedStringArray, use_sub_threads: bool = true) -> int:
	var started := 0
	var seen: Dictionary = {}
	for path in paths:
		var p := str(path).strip_edges()
		if p == "" or seen.has(p):
			continue
		seen[p] = true
		var err := request(p, use_sub_threads)
		if err == OK or err == ERR_BUSY:
			started += 1
	return started


## Vänta tills path är klar. Returnerar resursen eller null.
static func await_path(host: Node, path: String) -> Resource:
	var p := path.strip_edges()
	if p == "" or host == null:
		return null
	if not ResourceLoader.exists(p):
		return null

	var status := ResourceLoader.load_threaded_get_status(p)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		request(p, true)
		status = ResourceLoader.load_threaded_get_status(p)

	while true:
		var progress: Array = []
		status = ResourceLoader.load_threaded_get_status(p, progress)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				return ResourceLoader.load_threaded_get(p)
			ResourceLoader.THREAD_LOAD_FAILED:
				return ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REUSE)
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				return ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REUSE)
			_:
				if not is_instance_valid(host) or host.get_tree() == null:
					return ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REUSE)
				await host.get_tree().process_frame
	return null


## Ladda många paths parallellt. Returnerar Dictionary path -> Resource.
static func await_paths(
	host: Node,
	paths: PackedStringArray,
	use_sub_threads: bool = true,
	on_progress: Callable = Callable()
) -> Dictionary:
	var unique: PackedStringArray = []
	var seen: Dictionary = {}
	for path in paths:
		var p := str(path).strip_edges()
		if p == "" or seen.has(p) or not ResourceLoader.exists(p):
			continue
		seen[p] = true
		unique.append(p)

	request_many(unique, use_sub_threads)

	var results: Dictionary = {}
	var pending: Array[String] = []
	for p in unique:
		pending.append(p)

	var total := float(maxi(pending.size(), 1))
	while not pending.is_empty():
		var still: Array[String] = []
		var done_count := unique.size() - pending.size()
		for p in pending:
			var progress: Array = []
			var status := ResourceLoader.load_threaded_get_status(p, progress)
			match status:
				ResourceLoader.THREAD_LOAD_LOADED:
					results[p] = ResourceLoader.load_threaded_get(p)
					done_count += 1
				ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					results[p] = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REUSE)
					done_count += 1
				_:
					still.append(p)
		pending = still
		if on_progress.is_valid():
			var frac := 1.0 - (float(pending.size()) / total)
			on_progress.call(clampf(frac, 0.0, 1.0), unique.size() - pending.size(), unique.size())
		if not pending.is_empty():
			if host == null or not is_instance_valid(host) or host.get_tree() == null:
				for p2 in pending:
					results[p2] = ResourceLoader.load(p2, "", ResourceLoader.CACHE_MODE_REUSE)
				break
			await host.get_tree().process_frame
	return results


static func await_packed_scene(host: Node, path: String, use_sub_threads: bool = true) -> PackedScene:
	request(path, use_sub_threads)
	var res: Resource = await await_path(host, path)
	return res as PackedScene


static func progress_of(path: String) -> float:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return 1.0
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		return 0.0
	if progress.is_empty():
		return 0.0
	return clampf(float(progress[0]), 0.0, 1.0)
