extends SceneTree

# Independent acceptance: movement, interactions and puzzles enter through input.
# Pause-menu button hits call the UI click handler because a headless window has no pointer.
# No chapter, position, flags, inventory or puzzle state are assigned by this test.
var game
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("ACCEPTANCE FAIL: " + label)

func key(code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: int) -> void:
	key(code, true)
	await process_frame
	key(code, false)
	await process_frame

func dismiss() -> void:
	var frames = 0
	while not game.dialogue.is_empty() and frames < 50:
		await tap(KEY_E)
		frames += 1
	check(frames < 50, "dialogue ends with E")

func axis_to(target: Vector2) -> void:
	for axis in [0, 1]:
		var difference = target[axis] - game.player[axis]
		if absf(difference) < 12: continue
		var code = (KEY_D if difference > 0 else KEY_A) if axis == 0 else (KEY_S if difference > 0 else KEY_W)
		key(code, true)
		var frames = 0
		while absf(target[axis] - game.player[axis]) > 12 and frames < 1500:
			await process_frame
			frames += 1
		key(code, false)
		await process_frame
		check(frames < 1500, "walk axis reaches target")

func walk(target: Vector2) -> void:
	# Desert crossings use the actual safe gap between each moving wind band.
	if game.chapter == 4:
		var start: Vector2 = game.player
		if (start.x < 1120 and target.x > 980) or (start.x > 980 and target.x < 1120):
			if start.x > 1460:
				await axis_to(Vector2(start.x, 790))
				await axis_to(Vector2(1300, 790))
			await axis_to(Vector2(game.player.x, 710))
			await axis_to(Vector2(900 if target.x < 1120 else 1300, 710))
		if (game.player.x < 1580 and target.x > 1460) or (game.player.x > 1460 and target.x < 1580):
			await axis_to(Vector2(game.player.x, 790))
			await axis_to(Vector2(1630 if target.x > 1460 else 1300, 790))
	await axis_to(target)
	check(game.player.distance_to(target) < 25, "walk reaches object")

func interact(id: String) -> void:
	var target = Vector2.ZERO
	for object in game.objects:
		if object.id == id: target = object.pos
	check(target != Vector2.ZERO, "object exists: " + id)
	await walk(target)
	await process_frame
	check(game.nearest == id, "nearest from walked position: " + id)
	await tap(KEY_E)
	await dismiss()

func puzzle(id: String, solution: Array) -> void:
	await interact(id)
	check(game.overlay == "puzzle", "opens keyboard puzzle")
	await tap(KEY_ENTER)
	check(game.overlay == "puzzle", "wrong answer rejected")
	await tap(KEY_ESCAPE)
	check(game.overlay.is_empty(), "puzzle can be cancelled")
	await tap(KEY_E)
	for column in 3:
		for repeat in solution[column]: await tap(KEY_UP)
		if column < 2: await tap(KEY_RIGHT)
	await tap(KEY_ENTER)
	await dismiss()
	check(game.has(id), "keyboard puzzle solved")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save_path = "user://independent_acceptance.json"
	game.debug_test = true
	await tap(KEY_ENTER)
	await dismiss()
	check(game.chapter == 0 and game.mode == "play", "title Enter starts prologue")
	await tap(KEY_J)
	check(game.overlay == "journal", "J opens journal")
	await tap(KEY_ESCAPE)
	await tap(KEY_P)
	check(game.overlay == "party", "P opens companions")
	await tap(KEY_ESCAPE)
	await tap(KEY_M)
	check(game.overlay == "map", "M opens map")
	await tap(KEY_ESCAPE)
	var sequences = [
		["letter", "cup", "captain"],
		["name2", "name0", "name1", "bell", "child"],
		["clock2", "clock0", "clock1"],
		["star2", "aman", "star0", "star1"],
		["water0", "water1", "water2", "stake2", "stake0", "stake1", "knight"],
		["lamp2", "lamp0", "lamp1"],
		["memory2", "memory0", "memory1", "echo"],
		["lost3", "lost1", "lost0", "lost2", "tree"]
	]
	for stage in 8:
		await interact("exit")
		check(game.chapter == stage, "premature exit stays in chapter")
		for id in sequences[stage]: await interact(id)
		if stage == 2: await puzzle("mechanism", [1, 2, 0])
		if stage == 3: await puzzle("observatory", [2, 0, 1])
		if stage == 5:
			await puzzle("lighthouse", [0, 2, 1])
			await interact("sister")
		check(game.goal_complete(), "objectives complete: " + str(stage))
		await interact("exit")
		check(game.chapter == stage, "camp gate enforced")
		await interact("camp")
		check(game.has("rest"), "camp rest recorded")
		await tap(KEY_F5)
		var before = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
		check(before.chapter == stage and before.flags.get(str(stage)+":rest", false), "F5 writes actual current chapter and rest")
		# Pause menu save/title, then C reload through normal UI actions.
		await tap(KEY_ESCAPE)
		game.click(Vector2(640, 440))
		await process_frame
		check(game.mode == "title", "pause menu returns to title")
		await tap(KEY_C)
		check(game.chapter == stage and game.has("rest"), "C restores chapter and flags")
		check(game.player.distance_to(Vector2(before.player[0], before.player[1])) < 1, "continue restores actual position")
		await interact("exit")
		check(game.chapter == stage + 1, "keyboard departure reaches next chapter")
		print("INDEPENDENT INPUT ROUTE PASS chapter ", stage)
	for id in ["breakfast", "postcard", "inn", "sea"]: await interact(id)
	check(game.completed and game.overlay == "credits", "all keyboard route reaches ending")
	check(game.journal.size() == 8, "eight story journal entries")
	check(game.flags.get("4:knight", false) and game.flags.get("5:sister", false) and game.flags.get("7:tree", false), "three major story events recorded")
	await tap(KEY_ESCAPE)
	await tap(KEY_J)
	await tap(KEY_UP)
	check(game.journal_offset == 1, "journal older pages reachable")
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	game.click(Vector2(640, 440))
	await process_frame
	await tap(KEY_ENTER)
	await dismiss()
	check(game.chapter == 0 and not game.completed and game.flags.is_empty(), "new adventure resets ending and flags")
	DirAccess.remove_absolute(game.save_path)
	print("INDEPENDENT ACCEPTANCE: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
