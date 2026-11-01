extends Node2D

const SAVE = "user://homeward_v1.json"
const WORLD = Vector2(2260,1480)
const CHAPTERS = ["序章 · 留一盏灯","第一章 · 会走路的森林","第二章 · 钟城的第三天","第三章 · 雪上的星图","第四章 · 沙海无回声","第五章 · 黑海的灯","第六章 · 黄昏原野","第七章 · 归乡树","尾声 · 海边旅店"]
const REGIONS = ["旧港","迁徙林","沉钟城","永昼雪岭","无名沙海","黑海灯塔","黄昏原野","归乡树","海边旅店"]
const SUBS = ["有些路，要先学会告别。","树记得风，却忘了孩子的名字。","如果今天永远不结束，明天谁来等你？","在太阳不落下的地方，寻找一颗星。","你往前走。我替你看一会儿家。","每一盏灯，都是一个人在等。","记忆比人走得慢。","地图的最后一笔，是家的方向。","明天的早餐，还是两份。"]
const COLORS = [["173c48","285966","dfb97a","8bc7c5"],["163c36","2c5848","e3cf93","b7dba1"],["1b3b4b","345b6b","e9bc76","8dc7ca"],["647d91","a2b5c0","ffe0a6","d7edf1"],["73503f","ad7d54","ffe0a0","e6b87d"],["142c43","29485b","f4cc8a","91c3d5"],["594851","a37068","ffcf92","dfa58e"],["294746","4c7061","f6df9e","adceb2"],["294c58","497b88","ffe0a6","bce0da"]]
var font: SystemFont
var mode = "title"
var chapter = 0
var player = Vector2(500,1050)
var camera = Vector2.ZERO
var facing = 1
var walking = false
var elapsed = 0.0
var flags: Dictionary = {}
var inventory: Array = []
var journal: Array = []
var objects: Array = []
var decorations: Array = []
var motes: Array = []
var dialogue: Array = []
var dialogue_index = 0
var after_dialogue = ""
var overlay = ""
var nearest = ""
var notice = ""
var notice_time = 0.0
var transition = 0.0
var volume = 0.35
var stamina = 100.0
var puzzle: Dictionary = {}
var puzzle_cursor = 0
var puzzle_values: Array = []
var mouse_pos = Vector2.ZERO
var audio: AudioStreamPlayer
var music_time = 0.0
var music_note = 0
var save_exists = false
var completed = false
var debug_test = false
var test_checks = 0
var save_path = SAVE
var test_failed = false
var journal_offset = 0

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC","SimHei","sans-serif"])
	font.font_weight = 400
	audio = AudioStreamPlayer.new()
	add_child(audio)
	save_exists = FileAccess.file_exists(SAVE)
	var pref = ConfigFile.new()
	if pref.load("user://preferences.cfg") == OK: volume = float(pref.get_value("audio","volume",0.35))
	configure_world()
	if "--self-test" in OS.get_cmdline_user_args():
		debug_test = true
		save_path = "user://homeward_integration_test.json"
		call_deferred("run_self_test")
	elif "--capture" in OS.get_cmdline_user_args():
		debug_test = true
		save_path = "user://homeward_capture_test.json"
		call_deferred("capture_gallery")

func col(i: int) -> Color: return Color(COLORS[chapter][i])
func has(key: String) -> bool: return bool(flags.get(str(chapter)+":"+key,false))
func flag(key: String) -> void: flags[str(chapter)+":"+key] = true
func count(prefix: String, n: int) -> int:
	var value = 0
	for i in n:
		if has(prefix+str(i)): value += 1
	return value
func obj(id: String, title: String, p: Vector2, kind: String) -> void:
	objects.append({"id":id,"name":title,"pos":p,"kind":kind})

func configure_world() -> void:
	objects.clear(); decorations.clear(); motes.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 43629+chapter*71
	for i in 225: decorations.append({"p":Vector2(rng.randf_range(30,2230),rng.randf_range(50,1440)),"s":rng.randf_range(0.6,1.45),"r":rng.randf(),"n":i})
	for i in 50: motes.append(Vector3(rng.randf_range(0,1280),rng.randf_range(0,800),rng.randf_range(0.3,1)))
	obj("camp","飞艇营地",Vector2(410,1080),"camp")
	obj("exit","下一段航路",Vector2(1980,330),"exit")
	match chapter:
		0:
			obj("letter","妹妹的信",Vector2(760,940),"letter")
			obj("cup","两只旧茶杯",Vector2(1110,730),"tea")
			obj("captain","顾停舟",Vector2(1600,540),"captain")
		1:
			obj("child","树洞里的孩子",Vector2(1660,520),"child")
			obj("name0","沾露的纸片",Vector2(790,990),"paper")
			obj("name1","枝间的纸片",Vector2(1120,490),"paper")
			obj("name2","苔石上的纸片",Vector2(1740,1000),"paper")
			obj("bell","森林风铃",Vector2(1410,720),"bell")
		2:
			obj("keeper","守钟人",Vector2(1430,500),"keeper")
			obj("clock0","晨钟 · 06",Vector2(760,900),"clock")
			obj("clock1","午钟 · 12",Vector2(1120,630),"clock")
			obj("clock2","暮钟 · 18",Vector2(1700,950),"clock")
			obj("mechanism","中央钟盘",Vector2(1530,770),"mechanism")
		3:
			obj("aman","雪中的少年",Vector2(850,1040),"aman")
			obj("star0","西方星镜",Vector2(820,520),"crystal")
			obj("star1","北方星镜",Vector2(1410,350),"crystal")
			obj("star2","东方星镜",Vector2(1760,930),"crystal")
			obj("observatory","旧观星台",Vector2(1450,650),"observatory")
		4:
			obj("water0","背风处的水囊",Vector2(850,1000),"water")
			obj("water1","破船边的水囊",Vector2(1250,780),"water")
			obj("water2","石墙下的水囊",Vector2(1640,1050),"water")
			obj("stake0","西侧风锚",Vector2(800,570),"stake")
			obj("stake1","北侧风锚",Vector2(1350,430),"stake")
			obj("stake2","东侧风锚",Vector2(1790,700),"stake")
			obj("knight","沈知微",Vector2(1820,420),"knight")
		5:
			obj("lamp0","岸边引航灯",Vector2(780,960),"lamp")
			obj("lamp1","礁石引航灯",Vector2(1120,570),"lamp")
			obj("lamp2","长堤引航灯",Vector2(1680,980),"lamp")
			obj("lighthouse","黑海灯塔",Vector2(1570,480),"lighthouse")
			obj("sister","陆杳",Vector2(1800,650),"sister")
		6:
			obj("memory0","没系好的围巾",Vector2(820,1000),"scarf")
			obj("memory1","多盛的一碗汤",Vector2(1130,530),"tea")
			obj("memory2","磨圆的骑士徽章",Vector2(1690,900),"badge")
			obj("echo","风里的沈知微",Vector2(1620,500),"echo")
		7:
			obj("lost0","卖糖人的名字",Vector2(780,970),"wisp")
			obj("lost1","写信人的名字",Vector2(960,500),"wisp")
			obj("lost2","等船人的名字",Vector2(1660,1020),"wisp")
			obj("lost3","小满的名字",Vector2(1810,650),"wisp")
			obj("tree","归乡树之门",Vector2(1430,460),"tree")
		8:
			objects.clear()
			obj("inn","海边旅店",Vector2(1220,680),"inn")
			obj("breakfast","两份早餐",Vector2(870,940),"tea")
			obj("postcard","远方来信",Vector2(1600,890),"letter")
			obj("sea","一起看海",Vector2(1580,460),"sister")
	camera = (player-Vector2(640,430)).clamp(Vector2.ZERO,WORLD-Vector2(1280,800))
	nearest = ""
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	notice_time = maxf(0,notice_time-delta)
	transition = maxf(0,transition-delta)
	if mode == "play" and dialogue.is_empty() and overlay.is_empty():
		var move = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		walking = move.length()>0.1
		if move.x != 0: facing = 1 if move.x>0 else -1
		var speed = 225.0
		if Input.is_physical_key_pressed(KEY_SHIFT) and stamina>3:
			speed *= 1.6
			if walking: stamina = maxf(0,stamina-delta*19)
		else: stamina = minf(100,stamina+delta*16)
		if chapter == 4 and in_sandwind(player):
			speed *= 0.6
			stamina = maxf(0,stamina-delta*24)
			if stamina<=0:
				player = Vector2(410,1020); stamina = 70
				toast("沙风把你推回营地。绕开流动的风带，水囊也能恢复体力。")
		player = (player+move.normalized()*speed*delta).clamp(Vector2(100,180),WORLD-Vector2(100,90))
		camera = camera.lerp((player-Vector2(640,430)).clamp(Vector2.ZERO,WORLD-Vector2(1280,800)),minf(delta*7,1))
		update_nearest()
	else: walking = false
	if mode == "play" and volume>0.001:
		music_time += delta
		if music_time>2.2:
			music_time = 0
			var notes = [220.0,261.63,329.63,293.66,196.0,261.63,246.94,164.81]
			tone(notes[(music_note+chapter)%8],1.9,0.09); music_note += 1
	queue_redraw()

func in_sandwind(p: Vector2) -> bool:
	return (p.x>980 and p.x<1120 and p.y>750) or (p.x>1460 and p.x<1580 and p.y<750)
func tone(hz: float, duration: float = 0.2, gain: float = 0.18) -> void:
	if debug_test or volume<=0: return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	var bytes = PackedByteArray()
	var n = int(22050*duration)
	bytes.resize(n*2)
	for i in n:
		var t = float(i)/22050
		var env = minf(t*14,1)*exp(-t*2.6)*minf((duration-t)*12,1)
		bytes.encode_s16(i*2,int((sin(TAU*hz*t)+sin(TAU*hz*2*t)*0.22)*env*gain*18000))
	stream.data = bytes; audio.stream = stream
	audio.volume_db = linear_to_db(maxf(0.001,volume)); audio.play()
func update_nearest() -> void:
	nearest = ""
	var distance = 106.0
	for o in objects:
		if has(o.id) and o.kind in ["paper","water","wisp","crystal","scarf","badge"]: continue
		var d = player.distance_to(o.pos)
		if d<distance: distance = d; nearest = o.id

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: mouse_pos = get_global_mouse_position()
	if event is InputEventMouseButton and event.pressed and overlay=="journal":
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: journal_offset=mini(journal_offset+1,maxi(0,journal.size()-3))
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: journal_offset=maxi(0,journal_offset-1)
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: click(get_global_mouse_position())
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key = event.physical_keycode
	if mode == "title":
		if key==KEY_ENTER: new_game()
		if key==KEY_C and save_exists: load_game()
		return
	if not dialogue.is_empty():
		if key in [KEY_E,KEY_SPACE,KEY_ENTER]: next_dialogue()
		return
	if overlay == "puzzle":
		if key==KEY_ESCAPE: overlay = ""
		elif key in [KEY_LEFT,KEY_A]: puzzle_cursor = wrapi(puzzle_cursor-1,0,3)
		elif key in [KEY_RIGHT,KEY_D]: puzzle_cursor = (puzzle_cursor+1)%3
		elif key in [KEY_UP,KEY_W,KEY_E,KEY_SPACE]: cycle_puzzle(puzzle_cursor)
		elif key==KEY_ENTER: submit_puzzle()
		return
	if key==KEY_ESCAPE: overlay = "" if not overlay.is_empty() else "pause"; return
	if overlay=="journal" and key in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
		journal_offset=clampi(journal_offset+(1 if key in [KEY_UP,KEY_LEFT] else -1),0,maxi(0,journal.size()-3)); return
	if key==KEY_M: overlay = "" if overlay=="map" else "map"
	elif key==KEY_J: overlay = "" if overlay=="journal" else "journal"
	elif key==KEY_P: overlay = "" if overlay=="party" else "party"
	elif key==KEY_F5: save_game(); toast("航行记录已保存。")
	elif key in [KEY_E,KEY_SPACE] and overlay.is_empty() and not nearest.is_empty(): interact(nearest)

func click(p: Vector2) -> void:
	if mode=="title":
		if Rect2(110,426,270,58).has_point(p): new_game()
		elif Rect2(110,496,270,52).has_point(p) and save_exists: load_game()
		elif Rect2(110,580,46,34).has_point(p): change_volume(-0.1)
		elif Rect2(286,580,46,34).has_point(p): change_volume(0.1)
		return
	if not dialogue.is_empty(): next_dialogue(); return
	if overlay=="puzzle":
		for i in 3:
			if Rect2(415+i*155,330,140,130).has_point(p): cycle_puzzle(i)
		if Rect2(510,535,260,48).has_point(p): submit_puzzle()
		if Rect2(956,174,40,40).has_point(p): overlay = ""
		return
	if overlay=="pause":
		if Rect2(500,290,280,48).has_point(p): overlay = ""
		elif Rect2(500,355,280,48).has_point(p): save_game(); toast("航行记录已保存。")
		elif Rect2(500,420,280,48).has_point(p): save_game(); mode="title"; overlay=""
		elif Rect2(507,502,44,40).has_point(p): change_volume(-0.1)
		elif Rect2(729,502,44,40).has_point(p): change_volume(0.1)
		return
	if not overlay.is_empty(): overlay=""; return
	if Rect2(1000,27,70,34).has_point(p): overlay="map"
	elif Rect2(1080,27,70,34).has_point(p): overlay="journal"
	elif Rect2(1160,27,80,34).has_point(p): overlay="party"
	elif Rect2(505,686,270,48).has_point(p) and not nearest.is_empty(): interact(nearest)
func change_volume(amount: float) -> void:
	volume=clampf(volume+amount,0,1)
	var pref=ConfigFile.new(); pref.set_value("audio","volume",volume); pref.save("user://preferences.cfg")
	tone(440)

func new_game() -> void:
	chapter=0; flags.clear(); inventory.clear(); journal.clear(); completed=false
	player=Vector2(500,1080); stamina=100; mode="play"; overlay=""
	configure_world(); transition=2
	add_journal("留一盏灯","妹妹陆杳失踪后的第七天，一封没有邮戳的信出现在门缝里。信上说：哥哥，别把我的杯子收起来。")
	talk([["陆寻","陆杳的字。最后一行被雨洇开了……「在地图没有画出的地方，等我。」"],["陆寻","先去码头看看吧。她总说，顾停舟的飞艇什么地方都去得了。"]])
	save_game()
func talk(lines: Array, action: String="") -> void:
	dialogue=lines; dialogue_index=0; after_dialogue=action; walking=false; tone(523.25,0.12,0.13)
func next_dialogue() -> void:
	dialogue_index+=1
	if dialogue_index>=dialogue.size():
		dialogue.clear()
		var action=after_dialogue
		after_dialogue=""; finish_action(action); save_game()
func toast(message: String) -> void: notice=message; notice_time=4
func add_journal(title: String, body: String) -> void:
	for entry in journal:
		if entry.title==title: return
	journal.append({"title":title,"body":body,"chapter":chapter})
func collect(id: String, item: String, lines: Array) -> void:
	flag(id)
	if not item in inventory: inventory.append(item)
	talk(lines); tone(659.25,0.32)

func interact(id: String) -> void:
	if id=="camp": camp(); return
	if id=="exit": leave_region(); return
	match chapter:
		0:
			match id:
				"letter": collect(id,"一封没写完的信",[["陆杳的信","哥哥，别把我的杯子收起来。还有……这次换你来找我，好不好？"],["陆寻","纸背有一片森林。树根像脚，正朝海的另一边走去。"]])
				"cup": collect(id,"一只缺口茶杯",[["陆寻","你说过，缺了口的杯子也能盛热茶。我把它带上了。"],["陆寻","另一只，留在家里。"]])
				"captain":
					if not has("letter"): talk([["顾停舟","要去哪里？先想好。飞艇可不认得「随便」。"]]); return
					talk([["顾停舟","地图上的迁徙林？上船吧。我认识一位骑士，她也在找路。"],["沈知微","我是沈知微。你领口没系好……别动。好了，走吧。"],["闻笛","再加我一个。我在找一首歌的后半段。船长，船票能赊吗？"],["顾停舟","……能洗碗就行。"]],"captain")
		1:
			if id.begins_with("name"):
				if has(id): return
				collect(id,"森林名字碎片",[["纸上的字","「"+["小","满","回家"][int(id[-1])]+"」——字迹正在慢慢变淡。"],["陆寻","把它念出来，纸就不再透明了。名字原来需要有人记得。"]])
			elif id=="bell":
				if count("name",3)<3: talk([["闻笛","风铃缺了三个音。去找散在森林里的纸片吧，地图能标出它们。"]])
				else: talk([["闻笛","小——满——回家。对，就是这样。"],["森林","枝叶让出了一条路。一个孩子从树洞里抬起了头。"]],"bell")
			elif id=="child":
				if not has("bell"): talk([["孩子","你是来接我的吗？……对不起，我不记得自己叫什么。"],["沈知微","我们去找。你先待在这里，别害怕。"]])
				else: talk([["小满","小满……是我的名字？我记得了！有人叫我的时候，我就能回家。"],["陆寻","你见过带着一只缺口杯子的姐姐吗？"],["小满","她把杯子留给了一个怕冷的人。然后去了钟声不会停的城市。"],["沈知微","来，抓紧我的袖子。营地的汤还热着。"]],"child")
		2:
			if id.begins_with("clock"):
				collect(id,"钟城旧时刻表",[["铜牌",["清晨六点：父亲出门。","正午十二点：孩子等船。","傍晚六点：回家吃饭。"][int(id[-1])]],["顾停舟","小时候，我爸总在傍晚六点回来。后来，钟停了。"]])
			elif id=="keeper": talk([["守钟人","别修钟。今天过去了，我儿子就回不来了。"],["顾停舟","您等了多久？"],["守钟人","三天……也可能，很多个三天。"]],"keeper")
			elif id=="mechanism":
				if count("clock",3)<3: talk([["陆寻","还缺时刻。要先读完城中三座小钟上的铜牌。"]])
				elif has(id): talk([["顾停舟","钟已经走了。今天，终于成了昨天。"]])
				else: open_puzzle("clock")
		3:
			if id=="aman": talk([["少年","别踩那块雪。底下是空的。"],["陆寻","你在这里等谁？"],["阿满","忘了。叫我阿满就好……好像有人这样叫过我。"],["闻笛","先喝茶。船长的杯子分你一个。"],["阿满","谢谢。很久没有人给过我热的东西了。"]],"aman")
			elif id.begins_with("star"): collect(id,"三面星镜",[["星镜",["西镜：灯在归途左侧。","北镜：树在归途中央。","东镜：海在归途右侧。"][int(id[-1])]],["陆寻","镜子里，太阳下去了一瞬。我看见了星星。"]])
			elif id=="observatory":
				if count("star",3)<3 or not has("aman"): talk([["陆寻","需要三面星镜，还需要那个知道雪下道路的少年。"]])
				elif has(id): talk([["阿满","星光都朝着黑海。但我们得先穿过沙海。"]])
				else: open_puzzle("stars")
		4:
			if id.begins_with("water"): collect(id,"沙海水囊",[["陆寻","还能喝。给大家留一些。"],["沈知微","你先喝。……我不渴。"]]); stamina=100
			elif id.begins_with("stake"):
				if count("water",3)<3: talk([["顾停舟","修风锚得有力气。先找齐三个水囊，按地图绕开风带。"]])
				else: collect(id,"重钉的风锚",[["沈知微","钉稳了。再紧一扣。"],["陆寻","她总把绳结打得很紧，像怕什么东西散掉。"]])
			elif id=="knight":
				if has("knight"):
					talk([["陆寻","围巾已经带好了。该回营地，看看那碗汤。"]]); return
				if count("stake",3)<3: talk([["沈知微","东边的风会越来越大。三枚风锚钉好，我们就能过去。"]])
				else: talk([["顾停舟","风墙要合上了！有人得在这边拉住闸绳！"],["沈知微","我来。"],["陆寻","说好一起的。"],["沈知微","嗯。你领口又散了。我最后替你系一次。"],["沈知微","陆寻，你往前走。我替你看一会儿家。"],["陆寻","风里只剩一条绷紧的绳。她的围巾，轻轻落在了我手上。"]],"knight")
		5:
			if id.begins_with("lamp"): collect(id,"点亮的引航灯",[["引航灯","灯芯重新亮起。远处有另一点光，回应了它。"],["闻笛","姐姐怕黑。我每次回家，总会把门口的灯留下。"]])
			elif id=="lighthouse":
				if count("lamp",3)<3: talk([["闻笛","先点亮三盏引航灯。黑海上的人，看不见回家的方向。"]])
				elif has(id): talk([["闻笛","她不记得我了。但她会跟着这首歌，轻轻打拍子。"]])
				else: open_puzzle("melody")
			elif id=="sister":
				if not has("lighthouse"): talk([["陆寻","浓雾里有个人影。得先点亮灯塔。"]])
				else: talk([["陆杳","哥哥。"],["陆寻","我有很多话想问。最后只问了一句：饿不饿？"],["陆杳","嗯。想喝家里的汤。"],["陆杳","失去名字的人会被带到归乡树。我想带他们回去，结果连自己的路也忘了。"],["闻笛","你们去吧。守灯人是我姐姐。她忘了我，但她还怕黑。"],["闻笛","这次我不赶路了。等她想起的时候，门口要有人。"]],"sister")
		6:
			if id.begins_with("memory"):
				var stories=[[["陆杳","这条围巾，针脚怎么歪歪的？"],["陆寻","她不擅长这个。可每次都替别人系好。"]],[["记忆里的沈知微","多盛了一碗。谁还没回来？"],["陆寻","那时没人回答。她就一直把汤温着。"]],[["陆寻","徽章背后刻着四个字：平安回家。"],["陆杳","她一定，是个很好的人。"]]]
				collect(id,"沈知微的记忆",stories[int(id[-1])])
			elif id=="echo":
				if count("memory",3)<3: talk([["风","原野里散着三段记忆。有人，把日常留在了这里。"]])
				else: talk([["沈知微的记忆","领口，自己会系了吗？"],["陆寻","会了。还有汤，留一碗就够了。"],["沈知微的记忆","那就好。"],["陆寻","我想说你看，妹妹回来了。可风太轻，她已经走远了。"],["陆杳","哥哥，我们带她回家吧。用记得她的方式。"]],"echo")
		7:
			if id.begins_with("lost"): collect(id,"归来的名字",[["陆寻","我记得你。你叫"+["林伯","江禾","周远","小满"][int(id[-1])]+"。"],["失名者","原来……还有人记得。"]])
			elif id=="tree":
				if count("lost",4)<4: talk([["阿满","门要听见四个名字才会打开。一个也不能落下。"]])
				elif has(id): talk([["陆杳","我们走吧。阿满在替每个人照着路。"]])
				else: talk([["阿满","我想起来了。我是第一批没有名字的人。树需要有人在这里，记住回去的方向。"],["陆寻","那你呢？"],["阿满","你给过我一杯热茶。现在我知道，家是什么样了。"],["陆杳","我会记得你，阿满。"],["阿满","把那只杯子留给我吧。以后迷路的人来了，也有热的东西喝。"],["陆寻","我把缺口茶杯放在树根下。门外，四个名字亮了起来。"]],"tree")
		8:
			match id:
				"breakfast": talk([["陆杳","今天也是两份？"],["陆寻","嗯。不过汤，多煮了一点。"],["陆杳","万一有人路过。"],["陆寻","万一有人回家。"]],"breakfast")
				"postcard": talk([["顾停舟的明信片","老头现在每天都准点吃饭。昨天还问我，那个爱赊船票的乐师，什么时候来。——停舟"],["闻笛的附言","她今天跟着歌，叫了一声我的小名。别告诉别人，我哭得很难听。"]],"postcard")
				"inn": talk([["陆寻","我们把这间旅店取名叫「归途」。门口一直留一盏灯。"],["陆杳","你把地图画完了吗？"],["陆寻","没有。给明天的客人，留一点空白。"]],"inn")
				"sea": talk([["陆杳","哥哥，看。潮水又回来了。"],["陆寻","嗯。我们也回来了。"],["归途 · 完","献给每一个记得别人名字的人。\n谢谢你，把他们带回家。"]],"ending")

func finish_action(action: String) -> void:
	if action.is_empty(): return
	if action=="next": advance_chapter(); return
	flag(action)
	if action in ["captain","child","mechanism","observatory","knight","sister","echo","tree"]:
		flags.erase(str(chapter)+":rest")
	match action:
		"child": add_journal("一个被叫出的名字","小满被森林遗忘了。我们捡齐三个字，叫出了他的名字。原来记住一个人，真的能把他带回家。")
		"mechanism": add_journal("傍晚六点","守钟人是顾停舟的父亲。钟停在他没能回来那天。今天，顾停舟终于说：爸，我回来了。父亲松开了钟锤。")
		"observatory": add_journal("白昼里的星星","星镜照出了妹妹的影子，她在黑海。阿满认得星图的终点：归乡树。他的影子，却比我们所有人都旧。")
		"knight": inventory.append("沈知微的围巾"); add_journal("最后一次系好的领口","沈知微留在沙海拉住闸绳。她总说自己不渴，总把最后一碗汤留给别人。风停时，我们少了一个人。")
		"sister": add_journal("门口有人","终于找到陆杳。闻笛也找到了姐姐，她已经不记得他。他决定留下，每天唱同一首歌。门口总要有人。")
		"echo": add_journal("自己系领口","我在黄昏里跟沈知微告别。会自己系领口了，但还会多温一碗汤。记得她，不需要把时间停住。")
		"tree": add_journal("给下一个迷路的人","阿满留下守住归乡树。我们带回了四个名字，把杯子留给他。有些人没有同路到最后，却替我们照亮了整条路。")
		"ending": completed=true; overlay="credits"
		"rest": stamina=100; toast("炉火正暖。大家休息好了，进度已保存。")
	if action in ["bell","child","mechanism","observatory","knight","lighthouse","sister","echo","tree"]: tone(783.99,0.7)

func camp() -> void:
	var lines: Array=[]
	match chapter:
		0: lines=[["码头的炉火","潮风把火吹得一歪。你把妹妹的信折好，放进贴身的口袋。"],["陆寻","等找到她，就一起回来。"]]
		1: lines=[["顾停舟","今晚是蘑菇汤。三个人找柴，一个人洗碗，合理吧？"],["闻笛","为什么总看我？"],["沈知微","陆寻，你那碗在炉子旁边。刚又热了一次。"]]
		2: lines=[["顾停舟","我以为，离家越远就越自由。结果真的要回去了，手却在抖。"],["沈知微","害怕也能回家。这又不冲突。"],["闻笛","船长，茶给你倒好了。别洒。"]]
		3: lines=[["阿满","你们睡着以后，还会有人记得今天吗？"],["陆寻","会。我写在日记里了。"],["阿满","……把我也写上吧。"],["陆寻","写上了。阿满，喝茶时喜欢用两只手捧着杯子。"]]
		4:
			if has("knight"): lines=[["顾停舟","今天的汤……少盛一碗吗？"],["陆寻","先放着吧。"],["阿满","我替她看着，不会让它凉的。"]]
			else: lines=[["沈知微","水还够。你先喝。"],["陆寻","你每次都这样说。"],["沈知微","那下次，你替我留一碗汤。"]]
		5: lines=[["顾停舟","闻笛那家伙，临走还把碗都洗好了。"],["陆杳" if has("sister") else "阿满","下次回来，他会给我们唱一首完整的歌吧。"],["顾停舟","嗯。这次不收船票。"]]
		6: lines=[["陆杳","我一直以为，是我把大家弄丢了。"],["陆寻","你把他们的名字带出来了。剩下的路，我们一起走。"],["陆杳","领口散了。"],["陆寻","我知道。让我自己来。"]]
		7: lines=[["阿满","以后还会有人迷路吗？"],["陆寻","会吧。"],["阿满","那就给他们留一盏灯。还有，一杯热茶。"]]
	talk(lines,"rest")

func goal_complete() -> bool:
	return has(["captain","child","mechanism","observatory","knight","sister","echo","tree","ending"][chapter]) and (chapter!=0 or has("cup"))
func leave_region() -> void:
	if not goal_complete(): talk([["陆寻","还有一件事没做完。"],["旅途提示",task()]]); return
	if not has("rest"): talk([["顾停舟","先回营地歇一会儿吧。别把话都留到明天。"],["旅途提示","去西南方的飞艇营地交谈。地图 M 可查看位置。"]]); return
	var messages=["飞艇离开旧港。门口那盏灯，越来越小。","森林向身后走去。小满的名字，留在了日记第一页。","钟声追着飞艇响了很远。顾停舟一直没有回头。","太阳终于落下了一寸。星光指向沙海另一边。","飞艇穿过风墙。没有人说话。围巾仍然是暖的。","灯塔一直亮着。像一只久久没有放下的手。","风吹过原野。陆寻第一次，自己系好了领口。","树根下，那只缺口茶杯冒出了一点热气。"]
	talk([["航行记录",messages[chapter]]],"next")
func advance_chapter() -> void:
	chapter=mini(chapter+1,8); player=Vector2(500,1040); stamina=100
	configure_world(); transition=2.5; save_game()
func task() -> String:
	match chapter:
		0:
			if not has("letter"): return "读妹妹的信，寻找她留下的方向。"
			if not has("cup"): return "把缺口茶杯带上。它在旧港的石桌旁。"
			if not has("captain"): return "与东北方的飞艇船长顾停舟交谈。"
		1:
			if count("name",3)<3: return "找回名字纸片 %d / 3 · 按 M 查看标记" % count("name",3)
			if not has("bell"): return "用三个字，唤响森林中央的风铃。"
			if not has("child"): return "去树洞接回小满，叫出他的名字。"
		2:
			if count("clock",3)<3: return "读三座小钟的时刻铜牌 %d / 3" % count("clock",3)
			if not has("mechanism"): return "修好中央钟盘：让一天依次走向傍晚。"
		3:
			if not has("aman"): return "与雪地里的少年交谈。"
			if count("star",3)<3: return "收集三面星镜 %d / 3" % count("star",3)
			if not has("observatory"): return "在旧观星台排列灯、树与海的星图。"
		4:
			if count("water",3)<3: return "寻找水囊 %d / 3 · 避开金色沙风带" % count("water",3)
			if count("stake",3)<3: return "钉稳三枚风锚 %d / 3" % count("stake",3)
			if not has("knight"): return "风墙即将合拢，去找沈知微。"
		5:
			if count("lamp",3)<3: return "点亮三盏引航灯 %d / 3" % count("lamp",3)
			if not has("lighthouse"): return "去灯塔，奏响闻笛记忆中的旋律。"
			if not has("sister"): return "灯已亮起。去见陆杳。"
		6:
			if count("memory",3)<3: return "拾起原野里三段日常记忆 %d / 3" % count("memory",3)
			if not has("echo"): return "去原野的尽头，和沈知微好好告别。"
		7:
			if count("lost",4)<4: return "叫出四位失名者的名字 %d / 4" % count("lost",4)
			if not has("tree"): return "走到归乡树前，完成地图最后一笔。"
		8: return "这里是家了。读信、吃早餐，和妹妹一起看海。"
	if not has("rest"): return "回西南方营地歇脚，和伙伴聊一聊。"
	return "前往东北方的航路标，启程下一站。"

func open_puzzle(kind: String) -> void:
	puzzle_cursor=0; puzzle_values=[0,0,0]
	match kind:
		"clock": puzzle={"kind":kind,"title":"把一天还给钟城","hint":"晨钟 → 午钟 → 暮钟。铜牌上写着父亲回家的一天。","options":["18 时","06 时","12 时"],"solution":[1,2,0]}
		"stars": puzzle={"kind":kind,"title":"在永昼里拼出夜空","hint":"西镜照灯，北镜照树，东镜照海。按从左到右排列。","options":["树","海","灯"],"solution":[2,0,1]}
		"melody": puzzle={"kind":kind,"title":"给等灯人的一首歌","hint":"闻笛轻声哼唱：低音「归」→ 中音「途」→ 高音「家」。","options":["归 · 低","家 · 高","途 · 中"],"solution":[0,2,1]}
	overlay="puzzle"
func cycle_puzzle(i: int) -> void:
	puzzle_cursor=i; puzzle_values[i]=(puzzle_values[i]+1)%3
	tone([392.0,261.63,329.63][puzzle_values[i]],0.3)
func submit_puzzle() -> void:
	if puzzle_values!=puzzle.solution: toast("还差一点。再想想留下的提示。每个方块都可以切换。"); return
	overlay=""
	match puzzle.kind:
		"clock": talk([["钟声","六点。十二点。十八点。城市的水面第一次映出了晚霞。"],["顾停舟","爸。别等了。我已经回来了。"],["守钟人","停舟……你长这么高了？"],["顾停舟","嗯。今晚六点，回家吃饭。"]],"mechanism")
		"stars": talk([["陆寻","星图里有个人。陆杳——她在海边！"],["阿满","黑海灯塔。她在等一个记得她的人。"],["闻笛","等等。那首歌……我也听见了。"]],"observatory")
		"melody": talk([["闻笛","归——途——家。姐姐，我把后半首找回来了。"],["守灯的女人","你是谁？……为什么这首歌，我也会唱？"],["闻笛","没关系。我们明天，再唱一次。"],["陆寻","雾散了。长堤那头，有人在向我挥手。"]],"lighthouse")

func save_game() -> void:
	var data={"version":1,"chapter":chapter,"player":[player.x,player.y],"flags":flags,"inventory":inventory,"journal":journal,"completed":completed}
	var file=FileAccess.open(save_path,FileAccess.WRITE)
	if file==null: toast("暂时无法写入存档。请检查用户目录权限。"); return
	file.store_string(JSON.stringify(data)); file.close(); save_exists=true
func load_game() -> void:
	var file=FileAccess.open(save_path,FileAccess.READ)
	if file==null: return
	var data=JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version")!=1 or not data.get("flags") is Dictionary or not data.get("journal") is Array or not data.get("inventory") is Array:
		toast("存档无法读取，可以开始新的旅途。"); return
	chapter=clampi(int(data.get("chapter",0)),0,8)
	flags=data.flags; inventory=data.inventory; journal=data.journal; completed=bool(data.get("completed",false))
	var p=data.get("player",[500,1040])
	player=Vector2(float(p[0]),float(p[1])).clamp(Vector2(100,180),WORLD-Vector2(100,90))
	mode="play"; overlay=""; dialogue.clear(); stamina=100
	configure_world(); transition=1.8; toast("欢迎回来。上一段航路，已经替你记下。")

# ---- Original vector scenery / UI ------------------------------------------------
func _draw() -> void:
	if font==null: return
	if mode=="title": draw_title(); return
	draw_set_transform(-camera)
	draw_terrain()
	var sorted = objects.duplicate()
	sorted.append({"id":"player","pos":player,"kind":"player","name":"陆寻"})
	sorted.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	for o in sorted:
		if (o.pos-camera).x < -330 or (o.pos-camera).x > 1600 or (o.pos-camera).y < -100 or (o.pos-camera).y > 1100: continue
		if o.kind=="player": character(player,"陆寻",1.0,walking)
		else: draw_object(o)
	draw_set_transform(Vector2.ZERO)
	draw_atmosphere()
	draw_hud()
	if transition>0:
		var alpha=minf(transition/0.8,1.0)
		draw_rect(Rect2(325,210,630,112),Color(0.04,0.08,0.1,alpha*0.9))
		text(CHAPTERS[chapter],Vector2(640,254),29,Color(0.96,0.87,0.67,alpha),true)
		text(SUBS[chapter],Vector2(640,290),17,Color(0.82,0.87,0.84,alpha),true)
	if not overlay.is_empty(): draw_overlay()
	if not dialogue.is_empty(): draw_dialogue()
	if notice_time>0:
		panel(Rect2(300,145,680,52),Color("192f39"),Color("b9a378"))
		text(notice,Vector2(640,178),16,Color("e6dcc3"),true)

func text(value: String, p: Vector2, size: int=20, color: Color=Color("e9e3d2"), centered: bool=false) -> void:
	var q=p
	if centered: q.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5
	draw_string(font,q,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func wrap_text(value: String, p: Vector2, width: float, size: int=20, color: Color=Color("e9e3d2"), spacing: float=1.65) -> float:
	var line=""
	var y=p.y
	for ch in value:
		if ch=="\n" or (font.get_string_size(line+ch,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not ch in "，。！？；：、）】》」』…"):
			text(line,Vector2(p.x,y),size,color); y+=size*spacing; line=""
			if ch=="\n": continue
		line+=ch
	if not line.is_empty(): text(line,Vector2(p.x,y),size,color); y+=size*spacing
	return y
func panel(rect: Rect2, fill: Color=Color("102733"), edge: Color=Color("58717a")) -> void:
	draw_style_box(box(fill,edge),rect)
func box(fill: Color, edge: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=fill; style.border_color=edge
	style.set_border_width_all(1); style.set_corner_radius_all(8)
	return style
func button(rect: Rect2, label: String, primary: bool=false, enabled: bool=true) -> void:
	var hovered=rect.has_point(mouse_pos)
	var fill=Color("d9bb83") if primary else Color("233f49")
	if hovered and enabled: fill=fill.lightened(0.13)
	if not enabled: fill=Color("26363c")
	panel(rect,fill,Color("b79e72") if primary else Color("58717a"))
	text(label,rect.position+Vector2(rect.size.x*0.5,rect.size.y*0.5+7),20,Color("21323a") if primary else (Color("e9e1cc") if enabled else Color("708187")),true)
func ellipse(p: Vector2, radii: Vector2, color: Color) -> void:
	var points=PackedVector2Array()
	for i in 32: points.append(p+Vector2(cos(float(i)/32*TAU)*radii.x,sin(float(i)/32*TAU)*radii.y))
	draw_colored_polygon(points,color)
func poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)
func glow(p: Vector2, radius: float, color: Color) -> void:
	for i in range(5,0,-1): draw_circle(p,radius*float(i)/5,Color(color,0.018+0.018*(5-i)))
func diamond(p: Vector2, radius: float, color: Color) -> void:
	poly([p+Vector2(0,-radius),p+Vector2(radius*0.7,0),p+Vector2(0,radius),p+Vector2(-radius*0.7,0)],color)

func draw_terrain() -> void:
	draw_rect(Rect2(Vector2.ZERO,WORLD),col(0))
	# Soft islands, with translucent edges separating water and land.
	var land=PackedVector2Array([Vector2(70,1300),Vector2(70,750),Vector2(340,320),Vector2(760,180),Vector2(1220,220),Vector2(1730,100),Vector2(2170,290),Vector2(2240,750),Vector2(2070,1300),Vector2(1560,1440),Vector2(840,1360),Vector2(430,1440)])
	draw_colored_polygon(land,col(1))
	draw_polyline(land,Color(col(3),0.12),26,true)
	# Contour lines and coast foam.
	for i in 18:
		var y=100.0+i*81
		var points=PackedVector2Array()
		for x in range(0,2300,40): points.append(Vector2(x,y+sin(x*0.004+i)*24))
		draw_polyline(points,Color(col(3),0.028),1.3,true)
	var path=PackedVector2Array([Vector2(380,1100),Vector2(700,1000),Vector2(1010,830),Vector2(1270,750),Vector2(1470,540),Vector2(1740,470),Vector2(2000,330)])
	draw_polyline(path,col(0).lightened(0.08),104,true)
	draw_polyline(path,Color(col(2),0.12),88,true)
	var branch=PackedVector2Array([Vector2(1000,830),Vector2(1100,520),Vector2(1400,350)])
	draw_polyline(branch,Color(col(2),0.09),62,true)
	for d in decorations:
		var p: Vector2=d.p
		if p.x<camera.x-160 or p.x>camera.x+1450 or p.y<camera.y-80 or p.y>camera.y+1050: continue
		# Preserve the central trail and interaction clearings.
		var clear=false
		for o in objects:
			if p.distance_to(o.pos)<135: clear=true; break
		if clear: continue
		var s: float=d.s
		match chapter:
			0,8:
				if d.n%7==0: house(p,s,Color("5e6d6b"),false)
				elif d.n%3==0: rock(p,s,col(0).lightened(0.17))
				else: grass(p,s,col(3))
			1:
				if d.n%3!=0: tree(p,s,Color("21473c"),Color("5b8661"))
				else: grass(p,s,Color("91b77d"))
			2:
				if d.n%5==0: house(p,s,Color("4c6973"),true)
				elif d.n%3==0:
					for j in 3: draw_line(p+Vector2(j*16,0),p+Vector2(j*16+22,7),Color("79969c"),2)
				else: rock(p,s,Color("36505d"))
			3:
				if d.n%4==0: tree(p,s,Color("506c7d"),Color("cedbdd"),true)
				elif d.n%3==0:
					poly([p+Vector2(-45,10)*s,p+Vector2(-3,-80)*s,p+Vector2(60,20)*s],Color("839cae"))
					poly([p+Vector2(-21,-36)*s,p+Vector2(-3,-80)*s,p+Vector2(20,-47)*s,p+Vector2(3,-52)*s],Color("d8e4e6"))
				else: rock(p,s,Color("b9cbd1"))
			4:
				if d.n%4==0:
					poly([p+Vector2(-40,0)*s,p+Vector2(-22,-70)*s,p+Vector2(18,-80)*s,p+Vector2(35,2)*s],Color("805a45"))
					draw_line(p+Vector2(-21,-68)*s,p+Vector2(18,-78)*s,Color("c09a6b"),4)
				else:
					draw_arc(p,30*s,3.4,5.9,14,Color("d6a879"),1.4,true)
			5:
				if d.n%5==0:
					rock(p,s,Color("172b3b")); draw_line(p+Vector2(-24,-10),p+Vector2(16,-13),Color("7898a0"),1)
				else:
					draw_line(p,p+Vector2(35*s,0),Color("486b7b"),1)
			6:
				if d.n%6==0: tree(p,s,Color("6b4b50"),Color("be8267"))
				else: grass(p,s,Color("ddac83"))
			7:
				if d.n%4==0: tree(p,s,Color("315347"),Color("86a57a"))
				else: grass(p,s,Color("c0ca8e"))
	if chapter==4:
		for r in [Rect2(980,750,140,620),Rect2(1460,180,120,570)]:
			draw_rect(r,Color(0.97,0.78,0.44,0.1))
			for i in 26:
				var y=r.position.y+fmod(i*29+elapsed*85,r.size.y)
				draw_line(Vector2(r.position.x+6,y),Vector2(r.end.x-6,y-26),Color(1,0.84,0.57,0.31),2,true)
	if chapter==5:
		# A pier is the safe walkway through the black water.
		var pier=PackedVector2Array([Vector2(540,1060),Vector2(900,890),Vector2(1150,760),Vector2(1570,530),Vector2(1800,650)])
		draw_polyline(pier,Color("192d3d"),87,true); draw_polyline(pier,Color("5a6c71"),67,true)
		for i in 45:
			var p=Vector2(560+i*23,1045-i*12)
			draw_line(p+Vector2(-16,-22),p+Vector2(16,22),Color("344e5a"),3)
	if chapter==7:
		# The ancient tree's long roots reach across the whole island.
		for i in 9:
			var a=float(i)/9*TAU
			var start=Vector2(1430,460)
			var points=PackedVector2Array([start,start+Vector2(cos(a)*200,sin(a)*130),start+Vector2(cos(a)*460,sin(a)*350),start+Vector2(cos(a+0.2)*740,sin(a+0.2)*580)])
			draw_polyline(points,Color("6a7c60"),14,true)
			draw_polyline(points,Color("b8bd83"),2,true)

func grass(p: Vector2,s: float,color: Color) -> void:
	for i in 5:
		var wind=sin(elapsed*1.4+p.x*0.01+i)*3
		draw_line(p+Vector2(i*5-10,0),p+Vector2(i*8-18+wind,-(12+i%3*7)*s),Color(color,0.30),1.4,true)
	if int(p.x)%7==0: draw_circle(p+Vector2(0,-22*s),2.5,Color(color,0.7))
func rock(p: Vector2,s: float,color: Color) -> void:
	ellipse(p+Vector2(5,7),Vector2(35,12)*s,Color(0,0,0,0.13))
	poly([p+Vector2(-31,0)*s,p+Vector2(-20,-24)*s,p+Vector2(6,-33)*s,p+Vector2(32,-12)*s,p+Vector2(36,2)*s],color)
	poly([p+Vector2(-20,-24)*s,p+Vector2(6,-33)*s,p+Vector2(22,-16)*s,p+Vector2(-4,-14)*s],color.lightened(0.11))
func tree(p: Vector2,s: float,dark: Color,light: Color,pine: bool=false) -> void:
	ellipse(p+Vector2(12,8),Vector2(49,18)*s,Color(0,0,0,0.13))
	draw_line(p,p+Vector2(0,-93*s),dark.darkened(0.28),12*s)
	if pine:
		for i in 3:
			var y=-45-i*25
			poly([p+Vector2(-44+i*8,y+26)*s,p+Vector2(0,y-48)*s,p+Vector2(44-i*8,y+26)*s],light.darkened(i*0.06))
	else:
		for i in 5:
			var q=p+Vector2(sin(i*2.1)*30,-83+cos(i*2.4)*20)*s
			draw_circle(q,37*s,dark.lerp(light,float(i)/8))
		draw_arc(p+Vector2(-8,-85)*s,40*s,3.5,5.6,16,Color(light,0.32),3*s,true)
		for i in 3: draw_circle(p+Vector2(-26+i*20,-103+i%2*9)*s,3*s,Color(light,0.55))
func house(p: Vector2,s: float,color: Color,clock_city: bool) -> void:
	ellipse(p+Vector2(12,8),Vector2(68,22)*s,Color(0,0,0,0.18))
	draw_rect(Rect2(p+Vector2(-43,-82)*s,Vector2(85,84)*s),color)
	poly([p+Vector2(-56,-80)*s,p+Vector2(-1,-127)*s,p+Vector2(56,-80)*s],color.darkened(0.34))
	draw_line(p+Vector2(-56,-80)*s,p+Vector2(-1,-127)*s,color.lightened(0.2),3*s)
	draw_rect(Rect2(p+Vector2(-8,-39)*s,Vector2(20,41)*s),color.darkened(0.38))
	for x in [-26,24]:
		glow(p+Vector2(x,-61)*s,22*s,Color("e5c18a"))
		draw_rect(Rect2(p+Vector2(x-7,-70)*s,Vector2(14,20)*s),Color("cfac75"))
	if clock_city:
		draw_circle(p+Vector2(0,-91)*s,13*s,Color("d0b887"))
		draw_line(p+Vector2(0,-91)*s,p+Vector2(0,-101)*s,Color("40505a"),2)

func ship(p: Vector2,s: float=1.0) -> void:
	# A hand-drawn dirigible: stitched envelope, timber gondola, running lights.
	ellipse(p+Vector2(12,90)*s,Vector2(130,28)*s,Color(0,0,0,0.16))
	for x in [-62,62]: draw_line(p+Vector2(x,-46)*s,p+Vector2(x*0.6,32)*s,Color("8b8c78"),2*s)
	ellipse(p+Vector2(0,-80)*s,Vector2(146,62)*s,Color("b1b5a0"))
	ellipse(p+Vector2(-10,-91)*s,Vector2(129,43)*s,Color("d2cfb1"))
	for x in [-75,-35,10,55]:
		draw_arc(p+Vector2(x,-80)*s,45*s,-1.35,1.35,22,Color("8b9b90"),1.5*s,true)
	poly([p+Vector2(-130,-76)*s,p+Vector2(-180,-119)*s,p+Vector2(-165,-70)*s,p+Vector2(-180,-35)*s],Color("627d79"))
	draw_line(p+Vector2(-113,-57)*s,p+Vector2(111,-57)*s,Color("59716b"),9*s)
	poly([p+Vector2(-61,17)*s,p+Vector2(68,17)*s,p+Vector2(40,58)*s,p+Vector2(-39,58)*s],Color("6a5445"))
	draw_rect(Rect2(p+Vector2(-36,-7)*s,Vector2(73,31)*s),Color("4f6a6c"))
	for x in [-23,0,23]: draw_rect(Rect2(p+Vector2(x-6,1)*s,Vector2(13,13)*s),Color("e6c78e"))
	glow(p+Vector2(52,25)*s,43*s,Color("ffcf83")); draw_circle(p+Vector2(52,25)*s,4*s,Color("ffdc98"))
	text("归 途",p+Vector2(0,-78)*s,int(17*s),Color("456269"),true)

func character(p: Vector2,who: String,alpha: float=1.0,moving: bool=false) -> void:
	var bob=sin(elapsed*11)*2 if moving else sin(elapsed*2)*0.7
	var colors={"陆寻":"d5c39a","沈知微":"aabfc5","顾停舟":"697d89","闻笛":"8dafa2","阿满":"c7c8a1","陆杳":"d9b29d","小满":"9dba96","守钟人":"96897a"}
	var coat=Color(colors.get(who,"9dba96"),alpha)
	ellipse(p+Vector2(1,3),Vector2(16,7),Color(0.015,0.025,0.03,alpha*0.28))
	var q=p+Vector2(0,bob)
	var step=sin(elapsed*11)*4 if moving else 0.0
	draw_line(q+Vector2(-5,-10),q+Vector2(-6+step,1),Color("243b43",alpha),5)
	draw_line(q+Vector2(5,-10),q+Vector2(6-step,1),Color("243b43",alpha),5)
	poly([q+Vector2(-9,-32),q+Vector2(8,-32),q+Vector2(14,-10),q+Vector2(-14,-10)],coat)
	draw_line(q+Vector2(-10,-29),q+Vector2(-15,-17),coat.darkened(0.16),5)
	draw_line(q+Vector2(10,-29),q+Vector2(15,-18),coat.darkened(0.16),5)
	draw_circle(q+Vector2(0,-41),10,Color("e3c6a4",alpha))
	poly([q+Vector2(-10,-42),q+Vector2(-9,-49),q+Vector2(1,-54),q+Vector2(9,-47),q+Vector2(10,-39),q+Vector2(2,-45),q+Vector2(-4,-41)],Color("32414a",alpha))
	draw_circle(q+Vector2(4*facing,-41),1.1,Color("344249",alpha))
	var scarf=Color("b6745d",alpha) if who=="陆寻" else Color("d9d4bc",alpha)
	draw_line(q+Vector2(-8,-32),q+Vector2(8,-32),scarf,4)
	poly([q+Vector2(5,-32),q+Vector2(20+sin(elapsed*3)*3,-29),q+Vector2(13,-24),q+Vector2(5,-28)],scarf)
	if who=="陆寻":
		draw_rect(Rect2(q+Vector2(-12,-25),Vector2(8,12)),Color("806f58"))
		glow(q+Vector2(-14,-15),26,Color("ffd48c")); draw_circle(q+Vector2(-14,-15),3,Color("ffe0a0"))
	if who=="沈知微": draw_line(q+Vector2(12,-32),q+Vector2(18,0),Color("c9d8d8",alpha),2.5)

func draw_object(o: Dictionary) -> void:
	var p: Vector2=o.pos
	var done=has(o.id)
	var gold=col(2)
	if done and o.kind in ["paper","water","wisp","crystal","scarf","badge"]:
		draw_arc(p,12,0,TAU,24,Color(gold,0.16),1,true); return
	match o.kind:
		"camp":
			ship(p+Vector2(-48,-104),0.9)
			draw_line(p+Vector2(-55,-50),p+Vector2(-115,16),Color("a4a590"),2)
			for x in [-18,10]: draw_line(p+Vector2(x,9),p+Vector2(-x,-1),Color("705343"),7)
			glow(p+Vector2(0,-6),80,Color("ffc47d"))
			poly([p+Vector2(-11,0),p+Vector2(-3,-33-sin(elapsed*8)*5),p+Vector2(3,-15),p+Vector2(11,-29),p+Vector2(14,0)],Color("df9a56"))
			poly([p+Vector2(-6,0),p+Vector2(1,-21),p+Vector2(7,0)],Color("ffe4a1"))
			character(p+Vector2(67,14),"顾停舟")
			if chapter>=1 and chapter<=4 and not (chapter==4 and has("knight")): character(p+Vector2(-75,55),"沈知微")
			if chapter>=1 and chapter<=5 and not (chapter==5 and has("sister")): character(p+Vector2(20,63),"闻笛")
			if chapter>=3 and chapter<=7: character(p+Vector2(102,63),"阿满")
			if chapter>=6: character(p+Vector2(-26,67),"陆杳")
		"exit":
			draw_line(p,p+Vector2(0,-70),Color("a9a58b"),5)
			poly([p+Vector2(-4,-68),p+Vector2(49,-68),p+Vector2(62,-54),p+Vector2(49,-42),p+Vector2(-4,-42)],Color("d3bd8c"))
			text("航路",p+Vector2(26,-50),14,Color("314852"),true)
			if goal_complete() and has("rest"): glow(p+Vector2(26,-55),70,gold)
		"captain": character(p,"顾停舟")
		"knight":
			if not done: character(p,"沈知微")
			else:
				draw_line(p+Vector2(0,-16),p+Vector2(70,-150),Color("d3c0a0"),2)
				draw_line(p+Vector2(-10,0),p+Vector2(8,-42),Color("c6cbd0"),3)
		"aman": character(p,"阿满")
		"keeper":
			draw_circle(p+Vector2(20,-44),43,Color("3b555f")); character(p,"守钟人")
		"child":
			tree(p+Vector2(0,-4),1.5,Color("1c4037"),Color("5c7f58"))
			ellipse(p+Vector2(0,-35),Vector2(25,33),Color("102d2b")); character(p+Vector2(0,9),"小满",1.0 if done else 0.55)
		"sister":
			character(p,"陆杳",1.0 if chapter==8 or has("lighthouse") else 0.24)
		"echo": character(p,"沈知微",0.35+sin(elapsed*2)*0.07); glow(p+Vector2(0,-25),65,gold)
		"clock","mechanism":
			var s=1.6 if o.kind=="mechanism" else 1.0
			rock(p,1.2,Color("36515b"))
			draw_rect(Rect2(p+Vector2(-15,-70)*s,Vector2(30,73)*s),Color("647d82"))
			draw_circle(p+Vector2(0,-86)*s,35*s,Color("304852"))
			draw_arc(p+Vector2(0,-86)*s,31*s,0,TAU,40,gold,3,true)
			for i in 12:
				var a=i*TAU/12
				draw_line(p+Vector2(sin(a)*25,-86-cos(a)*25)*s,p+Vector2(sin(a)*28,-86-cos(a)*28)*s,gold,1.2)
			var angle=elapsed*0.22 if has("mechanism") else -PI*0.5
			draw_line(p+Vector2(0,-86)*s,p+Vector2(cos(angle)*21,-86+sin(angle)*21)*s,gold,2)
			draw_line(p+Vector2(0,-86)*s,p+Vector2(-10,-99)*s,gold,3)
		"observatory":
			for i in 4: ellipse(p+Vector2(0,9-i*5),Vector2(105-i*9,42-i*3),Color("7e98a4").lightened(i*0.04))
			draw_arc(p+Vector2(0,-36),65,0,TAU,48,gold,2,true)
			draw_arc(p+Vector2(0,-36),46,0,TAU,48,Color("d5e6e6"),1,true)
			for i in 6: diamond(p+Vector2(cos(i*TAU/6)*59,-36+sin(i*TAU/6)*59),4,gold)
			glow(p+Vector2(0,-36),80,gold)
		"lighthouse":
			ellipse(p+Vector2(5,10),Vector2(77,28),Color("102534"))
			poly([p+Vector2(-46,0),p+Vector2(-28,-184),p+Vector2(28,-184),p+Vector2(46,0)],Color("8b999b"))
			poly([p+Vector2(9,0),p+Vector2(9,-184),p+Vector2(28,-184),p+Vector2(46,0)],Color("637b84"))
			for y in [-50,-110]: draw_line(p+Vector2(-36,y),p+Vector2(36,y),Color("c1bda7"),14)
			draw_rect(Rect2(p+Vector2(-38,-208),Vector2(76,29)),Color("d9bd7d") if done else Color("405a68"))
			poly([p+Vector2(-49,-210),p+Vector2(0,-245),p+Vector2(49,-210)],Color("3c5565"))
			if done:
				glow(p+Vector2(0,-195),165,gold)
				poly([p+Vector2(0,-195),p+Vector2(-580,-350),p+Vector2(-580,-110)],Color(gold,0.045))
		"tree":
			var base=p+Vector2(0,0)
			for i in 7:
				var a=PI+i*0.48
				draw_line(base+Vector2(0,-86),base+Vector2(cos(a)*165,-170+sin(a)*95),Color("9c9e77"),15-i)
			poly([p+Vector2(-59,13),p+Vector2(-34,-115),p+Vector2(-45,-224),p+Vector2(15,-245),p+Vector2(50,-130),p+Vector2(57,13)],Color("7c8e6e"))
			for i in 11:
				var q=p+Vector2(sin(i*2.4)*170,-240+cos(i*1.7)*75)
				draw_circle(q,75,Color("648969").lightened(float(i%3)*0.05))
			ellipse(p+Vector2(0,-61),Vector2(32,67),Color("223e3e"))
			draw_arc(p+Vector2(0,-61),38,PI,TAU,32,gold,2,true)
			glow(p+Vector2(0,-61),120,gold)
			if done: character(p+Vector2(35,18),"阿满")
		"inn": house(p,2.8,Color("8b9690"),false); text("归 途 旅 店",p+Vector2(0,-110),21,Color("f1ddb1"),true)
		"bell":
			draw_line(p+Vector2(-32,0),p+Vector2(-32,-94),Color("87977e"),6)
			draw_line(p+Vector2(-32,-94),p+Vector2(30,-94),Color("87977e"),5)
			for i in 3:
				var x=-10+i*16
				draw_line(p+Vector2(x,-92),p+Vector2(x,-52+sin(elapsed*2+i)*3),Color("cbd3b1"),1)
				draw_circle(p+Vector2(x,-50+sin(elapsed*2+i)*3),6,gold)
		"lamp":
			draw_line(p,p+Vector2(0,-67),Color("80928c"),6)
			draw_rect(Rect2(p+Vector2(-11,-85),Vector2(22,27)),gold if done else Color("4c6670"))
			if done: glow(p+Vector2(0,-71),90,gold)
		"stake":
			draw_line(p,p+Vector2(-6,-60),Color("c1a57d"),8)
			poly([p+Vector2(-7,-58),p+Vector2(43,-44),p+Vector2(-5,-30)],Color("be8d66") if not done else Color("e3c58c"))
		"tea":
			ellipse(p,Vector2(35,15),Color("776c58")); draw_rect(Rect2(p+Vector2(-25,-12),Vector2(50,11)),Color("b4a384"))
			for x in [-13,12]:
				draw_rect(Rect2(p+Vector2(x-5,-26),Vector2(12,13)),Color("ded4b4")); draw_arc(p+Vector2(x+8,-20),4,-1.5,1.5,12,Color("ded4b4"),2)
				draw_arc(p+Vector2(x,-36),5,0.2,2.8,12,Color(0.9,0.9,0.8,0.3),1,true)
		"crystal":
			rock(p,0.9,Color("829ca7")); diamond(p+Vector2(0,-40),25,Color("d4e9e7")); diamond(p+Vector2(0,-40),16,Color("9bc4d0"))
		"water":
			draw_line(p+Vector2(0,-32),p+Vector2(0,-9),Color("e1cca1"),16); draw_line(p+Vector2(-4,-35),p+Vector2(5,-35),Color("664e40"),7)
		"scarf":
			poly([p+Vector2(-24,-12),p+Vector2(25,-21),p+Vector2(29,-9),p+Vector2(-11,0),p+Vector2(-7,20),p+Vector2(-20,21)],Color("d3c6a7"))
		"badge": diamond(p+Vector2(0,-19),23,gold); diamond(p+Vector2(0,-19),15,Color("6e7879"))
		"wisp":
			var q=p+Vector2(0,-35+sin(elapsed*2+p.x)*7)
			glow(q,75,gold); diamond(q,13,Color("f6e3ad")); draw_arc(q,23,0.4,5.4,24,Color(gold,0.5),1,true)
		_:
			poly([p+Vector2(-15,-30),p+Vector2(13,-35),p+Vector2(18,-8),p+Vector2(-13,-4)],Color("e4d7b0"))
			for y in [-24,-18,-12]: draw_line(p+Vector2(-7,y),p+Vector2(8,y-2),Color("8b927a"),1)
	if not done and o.kind not in ["camp","exit","lighthouse","tree"]:
		var mark=p+Vector2(0,-76 if o.kind in ["captain","knight","aman","child","keeper","sister","echo"] else -55)
		diamond(mark+Vector2(0,sin(elapsed*2+p.x)*3),4,Color(gold,0.8))
	if player.distance_to(p)<200 and o.id!=nearest:
		var width=font.get_string_size(o.name,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+24
		panel(Rect2(p+Vector2(-width*0.5,17),Vector2(width,29)),Color(0.05,0.13,0.17,0.88),Color(col(3),0.3))
		text(o.name,p+Vector2(0,37),15,gold if o.id==nearest else Color("d5ded2"),true)
	if o.id==nearest: draw_arc(p,33,0,TAU,40,Color(gold,0.55),1.6,true)

func draw_atmosphere() -> void:
	for m in motes:
		var p=Vector2(fposmod(m.x+elapsed*(9 if chapter!=3 else 24)*m.z,1280),fposmod(m.y+sin(elapsed*0.3+m.x)*18+elapsed*(12 if chapter==3 else -4)*m.z,800))
		var color=Color(col(2),0.18+0.25*m.z)
		if chapter==3: draw_line(p,p+Vector2(-3,5),Color(0.94,0.98,1,0.5),1.4,true)
		elif chapter==6:
			ellipse(p,Vector2(3,1.4)*m.z,Color(0.95,0.67,0.47,0.45))
		else: draw_circle(p,1.1+m.z,color)
	# Film-like vignette around the playable viewport.
	for i in 10:
		var a=0.013*(10-i)
		draw_rect(Rect2(i*8,i*8,1280-i*16,800-i*16),Color(0.015,0.035,0.05,a),false,8)
	if chapter in [0,2,5,8]:
		for i in 3:
			var x=fposmod(elapsed*11+i*490,1750)-300
			ellipse(Vector2(x,500+i*85),Vector2(340,30),Color(col(3),0.025))

func draw_hud() -> void:
	panel(Rect2(25,24,487,105),Color(0.035,0.10,0.135,0.93),Color(col(3),0.30))
	text(CHAPTERS[chapter],Vector2(47,57),22,col(2))
	wrap_text(task(),Vector2(47,87),443,16,Color("d2ddd4"),1.45)
	for i in 8:
		var color=col(2) if i<chapter else Color(col(3),0.25)
		draw_circle(Vector2(545+i*18,42),3,color)
	button(Rect2(1000,27,70,34),"地图")
	button(Rect2(1080,27,70,34),"日记")
	button(Rect2(1160,27,80,34),"伙伴")
	text("M",Vector2(1035,81),12,Color("a4b7b5"),true)
	text("J",Vector2(1115,81),12,Color("a4b7b5"),true)
	text("P",Vector2(1200,81),12,Color("a4b7b5"),true)
	# A small compass gives orientation even before opening the map.
	draw_circle(Vector2(1207,157),29,Color(0.04,0.11,0.15,0.72))
	poly([Vector2(1207,136),Vector2(1200,164),Vector2(1207,160),Vector2(1214,164)],col(2))
	text("北",Vector2(1207,121),13,Color("d2d9cb"),true)
	panel(Rect2(26,747,1228,33),Color(0.035,0.10,0.135,0.87),Color(col(3),0.16))
	text("WASD / 方向键 移动     Shift 快行     E / 空格 交谈     M 地图     J 日记     P 伙伴     Esc 暂停     F5 保存",Vector2(47,769),14,Color("b9cac4"))
	draw_rect(Rect2(1031,760,120,5),Color("3d5358"))
	draw_rect(Rect2(1031,760,120*stamina/100,5),col(2))
	text("体力",Vector2(1165,769),13,Color("c5d4c9"))
	if not nearest.is_empty() and dialogue.is_empty() and overlay.is_empty():
		var title=""
		for o in objects:
			if o.id==nearest: title=o.name
		button(Rect2(505,686,270,48),"E   "+title,true)
	# Offscreen direction to the first needed objective.
	var target=objective_position()
	if target!=Vector2.ZERO:
		var screen=target-camera
		if screen.x<60 or screen.x>1220 or screen.y<170 or screen.y>650:
			var edge=screen.clamp(Vector2(70,190),Vector2(1210,640))
			diamond(edge,12,col(2)); text("目标",edge+Vector2(0,32),13,col(2),true)

func objective_position() -> Vector2:
	var ids: Array=[]
	match chapter:
		0: ids=["letter","cup","captain"]
		1: ids=["name0","name1","name2","bell","child"]
		2: ids=["clock0","clock1","clock2","mechanism"]
		3: ids=["aman","star0","star1","star2","observatory"]
		4: ids=["water0","water1","water2","stake0","stake1","stake2","knight"]
		5: ids=["lamp0","lamp1","lamp2","lighthouse","sister"]
		6: ids=["memory0","memory1","memory2","echo"]
		7: ids=["lost0","lost1","lost2","lost3","tree"]
		8: ids=["breakfast","postcard","inn","sea"]
	for id in ids:
		if not has(id):
			for o in objects:
				if o.id==id: return o.pos
	if chapter<8:
		for o in objects:
			if o.id==("exit" if has("rest") else "camp"): return o.pos
	return Vector2.ZERO

func draw_title() -> void:
	draw_rect(Rect2(0,0,1280,800),Color("112b3a"))
	# An illuminated ink-and-paper landscape: sea, far ridges, migrating islands.
	for i in 26:
		var c=Color("173548").lerp(Color("7f9996"),float(i)/40)
		draw_rect(Rect2(0,i*26,1280,27),c)
	glow(Vector2(964,198),155,Color("ffe0a2"))
	draw_circle(Vector2(964,198),53,Color("e1d9b7"))
	draw_circle(Vector2(942,183),52,Color("4e6f79"))
	poly([Vector2(470,510),Vector2(660,305),Vector2(780,440),Vector2(920,273),Vector2(1110,460),Vector2(1280,345),Vector2(1280,800),Vector2(470,800)],Color("496a73"))
	poly([Vector2(510,600),Vector2(740,418),Vector2(845,560),Vector2(1070,390),Vector2(1280,540),Vector2(1280,800),Vector2(510,800)],Color("284c5d"))
	for i in 21:
		var y=500+i*15
		draw_line(Vector2(500+sin(i)*40,y),Vector2(1280,y),Color(0.57,0.73,0.73,0.07),1)
	poly([Vector2(620,800),Vector2(820,654),Vector2(1030,619),Vector2(1280,692),Vector2(1280,800)],Color("172f3c"))
	for i in 10: tree(Vector2(900+i*41,720+sin(i)*32),0.7+float(i%3)*0.12,Color("1b3942"),Color("456458"))
	ship(Vector2(857,394+sin(elapsed*0.6)*9),1.12)
	character(Vector2(857,716),"陆寻")
	character(Vector2(894,723),"陆杳")
	glow(Vector2(847,700),70,Color("ffd48c"))
	# Quiet cartographic curves behind the typography.
	for i in 5:
		draw_arc(Vector2(93,290),190+i*38,-1.5,1.9,64,Color(0.74,0.79,0.71,0.055),1,true)
	draw_rect(Rect2(0,0,575,800),Color(0.035,0.09,0.13,0.72))
	text("AN ORIGINAL STORY OF REMEMBERING",Vector2(111,135),12,Color("a4b6ac"))
	draw_line(Vector2(112,158),Vector2(175,158),Color("cbb989"),2)
	text("归途",Vector2(102,278),106,Color("eee3c6"))
	text("最后一张地图",Vector2(113,329),31,Color("d7c59f"))
	text("有些人留在远方，却把你送回了家。",Vector2(113,379),16,Color("aebfb7"))
	button(Rect2(110,426,270,58),"启程   →",true)
	button(Rect2(110,496,270,52),"继续旅途   C",false,save_exists)
	button(Rect2(110,580,46,34),"−")
	text("音量  %d%%" % roundi(volume*100),Vector2(221,604),16,Color("b7c8bd"),true)
	button(Rect2(286,580,46,34),"+")
	text("WASD 移动 · E 交谈 · M 地图",Vector2(112,665),14,Color("92aaa6"))
	text("序章 / 七段航路 / 一个归处",Vector2(112,695),14,Color("92aaa6"))
	text("紧凑原创剧情冒险  ·  Enter 启程",Vector2(112,751),12,Color("6e8c8f"))
	for i in 29:
		var x=fposmod(i*173+elapsed*(4+i%3),1280)
		var y=fposmod(i*97+sin(elapsed*0.3+i)*18,780)
		draw_circle(Vector2(x,y),1.1,Color(0.93,0.85,0.64,0.25))
	if notice_time>0: text(notice,Vector2(640,785),14,Color("f5d99b"),true)

func draw_dialogue() -> void:
	# Letterbox keeps the world visible while voices occupy a calm, readable space.
	draw_rect(Rect2(0,0,1280,11),Color(0.02,0.05,0.07,0.7))
	panel(Rect2(80,551,1120,183),Color(0.035,0.09,0.125,0.98),Color("9a916d"))
	var line: Array=dialogue[dialogue_index]
	var who: String=line[0]
	draw_line(Vector2(106,576),Vector2(106,699),Color("c5b184"),3)
	text(who,Vector2(129,590),22,Color("e6ca91"))
	wrap_text(line[1],Vector2(130,632),1018,22,Color("e1e6da"),1.65)
	# Right-align the footer without depending on Control layout.
	var footer="E / 空格 / 点击 继续    %d / %d" % [dialogue_index+1,dialogue.size()]
	draw_rect(Rect2(880,696,308,31),Color("0c202c"))
	text(footer,Vector2(1033,718),13,Color("9bb0ab"),true)

func draw_overlay() -> void:
	draw_rect(Rect2(0,0,1280,800),Color(0.01,0.035,0.055,0.77))
	if overlay=="pause":
		panel(Rect2(430,180,420,420),Color("132c37"),Color("8d927a"))
		text("把旅途暂放一会儿",Vector2(640,244),26,col(2),true)
		button(Rect2(500,290,280,48),"回到旅途",true)
		button(Rect2(500,355,280,48),"保存航行记录")
		button(Rect2(500,420,280,48),"保存并回到标题")
		button(Rect2(507,502,44,40),"−")
		text("音量 %d%%" % roundi(volume*100),Vector2(640,530),18,Color("c6d2c6"),true)
		button(Rect2(729,502,44,40),"+")
		text("Esc 返回",Vector2(640,579),14,Color("8fa7a3"),true)
		return
	if overlay=="credits":
		panel(Rect2(300,150,680,500),Color("142f39"),Color("b9a57b"))
		text("归途",Vector2(640,258),64,Color("eadbb8"),true)
		text("最后一张地图",Vector2(640,303),25,col(2),true)
		text("我们没有把所有人都带回来。",Vector2(640,382),20,Color("d4dfd4"),true)
		text("但没有一个人，被留在遗忘里。",Vector2(640,420),20,Color("d4dfd4"),true)
		text("谢谢你，记住了他们的名字。",Vector2(640,490),22,col(2),true)
		text("点击或 Esc 返回海边旅店 · 可继续读信与散步",Vector2(640,585),15,Color("98b0a8"),true)
		return
	if overlay=="puzzle":
		panel(Rect2(285,160,730,480),Color("142e39"),Color("afa27e"))
		text(puzzle.title,Vector2(640,225),28,col(2),true)
		wrap_text(puzzle.hint,Vector2(340,274),610,17,Color("c4d3ca"))
		text("×",Vector2(974,201),25,Color("a7b9ae"),true)
		for i in 3:
			var rect=Rect2(415+i*155,330,140,130)
			panel(rect,Color("314b52") if puzzle_cursor==i else Color("1e3944"),col(2) if puzzle_cursor==i else Color("657c7d"))
			text(puzzle.options[puzzle_values[i]],rect.position+Vector2(70,75),27,col(2),true)
			text("点击切换",rect.position+Vector2(70,111),12,Color("91aaa6"),true)
		text("← → 选位 · ↑ / E 切换 · Enter 确认 · Esc 离开",Vector2(640,500),14,Color("9fb3ad"),true)
		button(Rect2(510,535,260,48),"让记忆归位",true)
		return
	panel(Rect2(135,105,1010,598),Color("142e39"),Color("7f917e"))
	var title={"map":"最后一张地图","journal":"旅途手记","party":"同路的人"}.get(overlay,"")
	text(title,Vector2(175,155),29,col(2))
	text("点击任意处 / Esc 收起",Vector2(919,152),14,Color("8fa9a5"))
	draw_line(Vector2(175,179),Vector2(1105,179),Color("526e70"),1)
	match overlay:
		"map": draw_map()
		"journal": draw_journal()
		"party": draw_party()

func draw_map() -> void:
	# Local paper map with every actionable point. No hidden mandatory searches.
	var rect=Rect2(177,209,620,388)
	panel(rect,Color("253f46"),Color("607a75"))
	for i in 12: draw_line(Vector2(177+i*56,209),Vector2(177+i*56,597),Color(0.6,0.72,0.66,0.07),1)
	for i in 8: draw_line(Vector2(177,209+i*55),Vector2(797,209+i*55),Color(0.6,0.72,0.66,0.07),1)
	var route=PackedVector2Array()
	for p in [Vector2(410,1080),Vector2(760,950),Vector2(1100,760),Vector2(1450,540),Vector2(1980,330)]: route.append(rect.position+Vector2(p.x/WORLD.x*620,p.y/WORLD.y*388))
	draw_polyline(route,Color("879c87"),2,true)
	for o in objects:
		var p=rect.position+Vector2(o.pos.x/WORLD.x*620,o.pos.y/WORLD.y*388)
		var done=has(o.id)
		if o.kind=="camp": draw_circle(p,6,col(3))
		elif o.kind=="exit": diamond(p,8,col(2))
		else: draw_circle(p,4,Color("738c83") if done else col(2))
		text(o.name,p+Vector2(9,-7 if int(o.pos.x)%2==0 else 18),12,Color("7c968d") if done else Color("ded8b8"))
	var pp=rect.position+Vector2(player.x/WORLD.x*620,player.y/WORLD.y*388)
	draw_circle(pp,8,Color("f1e5c3")); draw_circle(pp,4,Color("415e65"))
	text("你在这里",pp+Vector2(-16,26),13,Color("fff0bc"))
	text("N ↑",Vector2(757,239),16,col(2))
	text(REGIONS[chapter],Vector2(493,631),21,col(2),true)
	text("实心金点：未完成  ·  灰点：已记住  ·  浅蓝：营地",Vector2(177,665),14,Color("b1c3b5"))
	text("航路",Vector2(844,236),19,col(2))
	for i in 9:
		var p=Vector2(850,274+i*39)
		if i<8: draw_line(p,p+Vector2(0,33),Color("61786f"),1)
		draw_circle(p,5,col(2) if i<=chapter else Color("4b6563"))
		text(REGIONS[i],p+Vector2(19,6),17,Color("e6d6af") if i==chapter else Color("8ea7a0"))
	if chapter==4: wrap_text("沙风带在 x≈1000 与 x≈1500 两段，体力见底会回到营地。可以从两侧绕行。",Vector2(175,688),900,12,Color("d8ba8f"))

func draw_journal() -> void:
	var start=maxi(0,journal.size()-3-journal_offset)
	var y=220.0
	for i in range(start,mini(start+3,journal.size())):
		var e=journal[i]
		text("%02d   %s" % [i+1,e.title],Vector2(179,y),21,col(2))
		y=wrap_text(e.body,Vector2(223,y+34),825,17,Color("c9d7cb"),1.65)+22
	text("随身的纪念",Vector2(179,584),19,col(2))
	var items=" · ".join(inventory)
	wrap_text(items if not items.is_empty() else "口袋里暂时只有海风。",Vector2(179,616),900,14,Color("91aaa3"),1.5)
	text("↑ ↓ / 鼠标滚轮 翻阅旧页 · 正在阅读 %d—%d / %d 篇" % [start+1,mini(start+3,journal.size()),journal.size()],Vector2(179,677),13,Color("7f9b97"))

func party_data() -> Array:
	var knight_state="替大家多温一碗汤。" if chapter<4 or (chapter==4 and not has("knight")) else "留在沙海。她替你系好的领口，你已学会自己系。"
	var musician_state="找一首歌的后半段，洗一船人的碗。" if chapter<5 or (chapter==5 and not has("sister")) else "留在灯塔陪伴姐姐。每天唱同一首歌。"
	var aman_state="双手捧着茶杯的古代少年。希望有人把他写进日记。" if chapter<7 or (chapter==7 and not has("tree")) else "守在归乡树下，为下一个迷路的人温茶。"
	return [["沈知微","骑士",knight_state],["顾停舟","飞艇船长","相信自由，也终于相信傍晚六点的家。"],["闻笛","乐师",musician_state],["阿满","古代少年",aman_state],["陆杳","妹妹","正在等一个记得她的人。" if chapter<5 or (chapter==5 and not has("sister")) else "已经找到她。这次，一起回家。"]]
func draw_party() -> void:
	var data=party_data()
	for i in data.size():
		var y=225+i*83
		character(Vector2(205,y+39),data[i][0])
		text(data[i][0],Vector2(248,y+3),21,col(2))
		text(data[i][1],Vector2(354,y+3),13,Color("8ca69f"))
		wrap_text(data[i][2],Vector2(248,y+30),810,16,Color("c5d4ca"),1.5)
	text("在飞艇营地 E 交谈、休息 · 有些日常，后来会成为回家的路标",Vector2(179,681),14,Color("8ca69f"))

# ---- Integration route uses the same gates, interactions and puzzle callbacks ----
func expect(condition: bool, message: String) -> void:
	if not condition:
		push_error("SELFTEST FAILED: "+message)
		test_failed=true
		return
	test_checks+=1
func drain_dialogue() -> void:
	var guard=0
	while not dialogue.is_empty() and guard<60: next_dialogue(); guard+=1
	expect(guard<60,"dialogue terminates")
func test_interact(id: String) -> void:
	var found=false
	for o in objects:
		if o.id==id:
			player=o.pos+Vector2(0,40); found=true; break
	expect(found,"object exists: "+id)
	update_nearest()
	expect(nearest==id,"interaction reach: "+id)
	interact(nearest); drain_dialogue()
func test_puzzle(kind: String, id: String) -> void:
	test_interact(id)
	expect(overlay=="puzzle" and puzzle.kind==kind,"puzzle opened: "+kind)
	submit_puzzle()
	expect(overlay=="puzzle","wrong solution stays open")
	for i in 3:
		for j in int(puzzle.solution[i]): cycle_puzzle(i)
	submit_puzzle(); drain_dialogue()
	expect(has(id),"puzzle completed: "+kind)
func run_self_test() -> void:
	print("HOMEWARD INTEGRATION TEST START")
	new_game(); drain_dialogue()
	expect(chapter==0,"new game starts prologue")
	# Feed real keyboard events through Godot's input pipeline.
	var start_position=player
	feed_key(KEY_D,true)
	await get_tree().create_timer(0.16).timeout
	feed_key(KEY_D,false)
	expect(player.x>start_position.x+8,"physical D key moves player")
	feed_key(KEY_M,true); feed_key(KEY_M,false)
	await get_tree().process_frame
	expect(overlay=="map","M opens map through input pipeline")
	feed_key(KEY_ESCAPE,true); feed_key(KEY_ESCAPE,false)
	await get_tree().process_frame
	expect(overlay.is_empty(),"Escape closes overlay")
	player=Vector2(760,980); update_nearest()
	feed_key(KEY_E,true); feed_key(KEY_E,false)
	await get_tree().process_frame
	expect(not dialogue.is_empty(),"E interacts through input pipeline")
	drain_dialogue()
	expect(has("letter"),"keyboard interaction records collection")
	var sequences=[
		["letter","cup","captain"],
		["name0","name1","name2","bell","child"],
		["keeper","clock0","clock1","clock2"],
		["aman","star0","star1","star2"],
		["water0","water1","water2","stake0","stake1","stake2","knight"],
		["lamp0","lamp1","lamp2"],
		["memory0","memory1","memory2","echo"],
		["lost0","lost1","lost2","lost3","tree"]]
	for stage in 8:
		expect(chapter==stage,"chapter reached: "+str(stage))
		leave_region(); drain_dialogue()
		expect(chapter==stage,"exit blocked before objectives")
		for id in sequences[stage]: test_interact(id)
		if stage==2: test_puzzle("clock","mechanism")
		if stage==3: test_puzzle("stars","observatory")
		if stage==5: test_puzzle("melody","lighthouse"); test_interact("sister")
		expect(goal_complete(),"chapter goal complete: "+str(stage))
		leave_region(); drain_dialogue()
		expect(chapter==stage,"camp required before departure")
		test_interact("camp")
		expect(has("rest"),"camp conversation saved")
		test_interact("exit")
		expect(chapter==stage+1,"departure reaches next chapter")
		print("PASS chapter ",stage," -> ",chapter)
	expect(chapter==8,"epilogue reached")
	for id in ["breakfast","postcard","inn","sea"]: test_interact(id)
	expect(completed and overlay=="credits","ending reached")
	expect(journal.size()==8,"all eight journal entries")
	expect(inventory.has("沈知微的围巾"),"keepsake retained")
	expect(in_sandwind(Vector2(1000,900)),"wind hazard active")
	expect(not in_sandwind(Vector2(1150,900)),"wind can be bypassed")
	# Explicit roundtrip of the same serializer without touching any player's save.
	var snapshot={"chapter":chapter,"flags":flags,"journal":journal,"inventory":inventory,"player":[player.x,player.y],"completed":completed}
	var restored=JSON.parse_string(JSON.stringify(snapshot))
	expect(restored.chapter==8 and restored.completed,"save schema roundtrip")
	expect(restored.flags.get("4:knight",false) and restored.flags.get("7:tree",false),"story flags survive roundtrip")
	save_game()
	chapter=0; flags={}; inventory=[]; journal=[]; completed=false
	load_game()
	expect(chapter==8 and completed,"real save file reloads ending")
	expect(flags.get("7:tree",false) and journal.size()==8,"real save reloads all journal and story flags")
	DirAccess.remove_absolute(save_path)
	if test_failed: print("HOMEWARD SELFTEST FAILED")
	else: print("HOMEWARD SELFTEST PASS: ",test_checks," checks; prologue + 7 chapters + epilogue; 3 puzzles; 8 camp gates; keyboard movement; real save/load.")
	get_tree().quit(1 if test_failed else 0)

func feed_key(key: int, pressed: bool) -> void:
	var event=InputEventKey.new()
	event.physical_keycode=key; event.keycode=key; event.pressed=pressed
	Input.parse_input_event(event)

func capture_gallery() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/screenshots")
	await get_tree().create_timer(0.6).timeout
	await screenshot("00-title")
	new_game()
	await screenshot("01-dialogue")
	drain_dialogue()
	for i in range(1,9):
		chapter=i; player=Vector2(1110,770); dialogue.clear(); overlay=""; transition=0
		if i==7: player=Vector2(1430,510)
		configure_world()
		await screenshot("%02d-region" % (i+1))
		if i==1:
			overlay="map"; await screenshot("10-map"); overlay=""
		if i==2:
			open_puzzle("clock"); await screenshot("11-puzzle"); overlay=""
	for entry in [[1,"child"],[2,"mechanism"],[3,"observatory"],[4,"knight"],[5,"sister"],[6,"echo"],[7,"tree"]]:
		chapter=entry[0]; finish_action(entry[1])
	chapter=8; configure_world()
	inventory=["一封没写完的信","一只缺口茶杯","森林名字碎片","钟城旧时刻表","三面星镜","沙海水囊","重钉的风锚","沈知微的围巾","点亮的引航灯","沈知微的记忆","归来的名字"]
	overlay="journal"
	await screenshot("12-journal")
	overlay="party"
	await screenshot("13-party")
	DirAccess.remove_absolute(save_path)
	print("SCREENSHOT GALLERY COMPLETE: tests/screenshots")
	get_tree().quit()
func screenshot(filename: String) -> void:
	queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var result=get_viewport().get_texture().get_image().save_png("res://tests/screenshots/"+filename+".png")
	print("SCREENSHOT ",filename," result=",result)

