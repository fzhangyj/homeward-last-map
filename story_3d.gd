extends "res://legacy_2d/game.gd"

# The original, complete Chinese narrative stays in one place. The 3D host owns
# movement, camera, staging and persistence; this canvas owns readable UI.
var host: Node3D

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimHei", "sans-serif"])
	audio = AudioStreamPlayer.new()
	add_child(audio)
	save_exists = FileAccess.file_exists(host.save_path)
	set_process_unhandled_input(false)
	var pref = ConfigFile.new()
	if pref.load("user://preferences.cfg") == OK: volume = float(pref.get_value("audio", "volume", 0.35))

func configure_world() -> void:
	super.configure_world()
	if is_instance_valid(host): host.build_region()

func _process(delta: float) -> void:
	elapsed += delta
	notice_time = maxf(0, notice_time-delta)
	transition = maxf(0, transition-delta)
	if mode == "play" and volume > 0.001:
		music_time += delta
		if music_time > 2.2:
			music_time = 0
			tone([220.0,261.63,329.63,293.66,196.0,261.63,246.94,164.81][(music_note+chapter)%8],1.9,0.09)
			music_note += 1
	queue_redraw()

func new_game() -> void:
	host.cancel_cinematic()
	super.new_game()
	host.begin_cinematic("intro")

func talk(lines: Array, action: String="") -> void:
	super.talk(lines,action)
	if action in ["knight","sister","echo","tree","next"]:
		host.begin_cinematic("departure" if action=="next" else action)

func finish_action(action: String) -> void:
	if not host.cinematic.is_empty(): host.end_cinematic()
	if action=="rest" and not goal_complete():
		stamina=100
		toast("炉火让体力恢复了。完成主要事件后，再来和大家告别。")
		return
	super.finish_action(action)

func click(p: Vector2) -> void:
	if mode=="play" and dialogue.is_empty() and overlay.is_empty():
		for i in 3:
			if Rect2(946+i*100,24,92,40).has_point(p):
				overlay=["map","journal","party"][i]; return
		if Rect2(476,608,328,53).has_point(p) and not nearest.is_empty():
			interact(nearest); return
		return
	super.click(p)

func save_game() -> void:
	if is_instance_valid(host): host.save_progress()

func load_game() -> void:
	host.load_progress()

func forward_input(event: InputEvent) -> void:
	super._unhandled_input(event)

func _draw() -> void:
	if font == null: return
	if mode == "title":
		draw_rect(Rect2(0,0,590,800),Color(0.025,0.06,0.085,0.88))
		text("A JOURNEY IN THREE DIMENSIONS",Vector2(109,148),13,Color("a4c2b4"))
		text("归途",Vector2(102,278),106,Color("eee3c6"))
		text("最后一张地图",Vector2(113,329),31,Color("d7c59f"))
		text("越过山与海，记住每一个人的名字。",Vector2(113,379),16,Color("b8c9bd"))
		button(Rect2(110,426,270,58),"启程   →",true)
		button(Rect2(110,496,270,52),"继续旅途   C",false,save_exists)
		button(Rect2(110,580,46,34),"−")
		text("音量 %d%%" % roundi(volume*100),Vector2(221,604),16,Color("b7c8bd"),true)
		button(Rect2(286,580,46,34),"+")
		text("实时 3D 探索 · 序章 / 七段航路 / 尾声",Vector2(112,678),16,Color("b6c4ad"))
		text("Enter 启程 · 右键拖动视角 · Q / R 转向",Vector2(112,714),14,Color("8da89b"))
		return
	if host.cinematic.is_empty():
		panel(Rect2(22,22,525,116),Color(0.035,0.08,0.10,0.89),Color("728b7b"))
		text(CHAPTERS[chapter],Vector2(43,55),23,col(2))
		wrap_text(task(),Vector2(43,87),485,15,Color("d6dfcd"),1.45)
		for i in 3: button(Rect2(946+i*100,24,92,40),["地图 M","日记 J","伙伴 P"][i])
		panel(Rect2(22,697,570,80),Color(0.035,0.08,0.10,0.86),Color("56746b"))
		text("WASD 行走 · Shift 快行 · Space 跳跃 · E 交谈",Vector2(39,725),14)
		text("右键拖动 / Q R 转向 · 滚轮远近 · Esc 暂停 · F5 保存",Vector2(39,751),13,Color("9db8a9"))
		draw_rect(Rect2(39,763,210,4),Color("3e574e"))
		draw_rect(Rect2(39,763,210*stamina/100,4),col(2))
		if not nearest.is_empty() and dialogue.is_empty() and overlay.is_empty():
			var title=""
			for o in objects:
				if o.id==nearest: title=o.name
			panel(Rect2(476,608,328,53),Color(0.04,0.09,0.11,0.93),col(2))
			text("E  ·  "+title,Vector2(640,643),20,col(2),true)
		host.draw_compass(self)
	else:
		draw_rect(Rect2(0,0,1280,72),Color(0.01,0.025,0.035,0.98))
		draw_rect(Rect2(0,745,1280,55),Color(0.01,0.025,0.035,0.98))
		text(host.cinematic_title(),Vector2(42,43),22,col(2))
		# Footer starts far enough left to fit inside the letterbox.
		draw_rect(Rect2(850,8,430,51),Color("03080c"))
		text("E / Enter 下一句 · Esc 跳过演出",Vector2(878,43),14,Color("b1c3b7"))
	if not overlay.is_empty(): draw_overlay()
	if not dialogue.is_empty(): draw_dialogue()
	if notice_time>0 and dialogue.is_empty():
		panel(Rect2(250,151,780,57),Color("19323a"),Color("b9a378"))
		wrap_text(notice,Vector2(270,175),740,15)
	if host.fade_alpha>0: draw_rect(Rect2(0,0,1280,800),Color(0.015,0.03,0.04,host.fade_alpha))
