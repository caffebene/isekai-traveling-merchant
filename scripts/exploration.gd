extends "res://scripts/item_art.gd"
signal finished
const Combat = preload("res://scripts/exploration_state.gd")
const HoverTip = preload("res://scripts/interact_hover_tip.gd")
const CELL_SIZE := 24.0
const ENEMY_ART := ["slime","wolf","golem","red_wolf","treant","hollow_stag"]
const ENEMY_HEIGHT := [240.0,280.0,270.0,255.0,600.0,510.0]
const FOREST_BACKGROUND := preload("res://assets/exploration/boisterous/forest-distance.png")
const PLAYER_FEET := Vector2(420,1000)
const PLAYER_HEIGHT := 500.0
const ENEMY_FEET := Vector2(1160,760)
const UI_CENTER_X := 800.0
const INVENTORY_PANEL_POSITION := Vector2(220,110)
const LOOT_PANEL_CENTER_X := 1160.0
const PLAYER_STATUS_ANCHOR := Vector2(190,795)
const NOTICE_Y := 96.0
const TRAVEL_DURATION := 0.475
const ARRIVAL_DURATION := 0.175
const TRAVEL_BLUR := preload("res://scripts/forest_travel_blur.gdshader")
var background_blur: ShaderMaterial
var traveling := false
var travel_elapsed := 0.0
var arrival := 1.0
var state
var combat = Combat.new()
var font: SystemFont
var drag := -1
var rotated := false
var offset := Vector2.ZERO
var pointer := Vector2.ZERO
var primary: Button
var escape_button: Button
var fight_button: Button
var victory_return_button: Button
var continue_button: Button
var hover_tip: Control
var hover_item_id := -1
var confirm_action := ""
var notice := ""
var textures: Dictionary = {}
var ally_texture: Texture2D = preload("res://assets/exploration/boisterous/sylvie-ally.png")
var ally_attack_time := 0.0
var ally_heal_time := 0.0
var visual_time := 0.0
var player_hit := 0.0
var enemy_hit := 0.0
var floats: Array[Dictionary] = []
var dialogue_button: Button
var event_buttons: Array[Button] = []
var event_option_selection := ""
var event_hover := false
var event_animation := 0.0
var attack_time := 0.0
var use_time := 0.0
var shock_time := 0.0
var enemy_lunge := 0.0
var freeze_time := 0.0
var repair_time := 0.0
var active_weapon := -1
var active_weapon_key := ""
var used_key := ""
var effect_origin := Vector2.ZERO
var scene_shift := Vector2.ZERO
var merchant_frames: Array[Texture2D] = []
var leaf_time := 0.0
var result_line := ""
var event_rewards: Array = []
var reward_flight := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = Chrome.font()
	theme = Chrome.theme()
	var ally_frame := AtlasTexture.new()
	ally_frame.atlas = ally_texture
	ally_frame.region = ally_texture.get_image().get_used_rect()
	ally_texture = ally_frame
	var background := TextureRect.new()
	var forest_image := FOREST_BACKGROUND.get_image()
	forest_image.generate_mipmaps()
	background.texture = ImageTexture.create_from_image(forest_image)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = Vector2(1600,900)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -1
	background_blur = ShaderMaterial.new()
	background_blur.shader = TRAVEL_BLUR
	background.material = background_blur
	add_child(background)
	hover_tip = HoverTip.new()
	hover_tip.name = "InteractHoverTip"
	add_child(hover_tip)
	for key in ["merchant"] + ENEMY_ART + ["chest","court","frog","well","mushrooms","logging","mining","camp","snail","hunter"]:
		var file_name: String = "stage/merchant-side.png" if key == "merchant" else "%s.png" % key
		var fresh := "res://assets/exploration/boisterous/%s.png" % key
		textures[key] = load(fresh) if ResourceLoader.exists(fresh) else load("res://assets/exploration/%s" % file_name)
		if textures[key] != null:
			var cropped := AtlasTexture.new()
			cropped.atlas = textures[key]
			cropped.region = textures[key].get_image().get_used_rect()
			textures[key] = cropped
	for pose in ["idle","walk","attack","hit","use","surprise"]:
		var source: Texture2D = load("res://assets/exploration/boisterous/merchant-%s.png" % pose)
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = source.get_image().get_used_rect()
		merchant_frames.append(frame)
	combat.presentation.connect(_on_presentation)
	combat.start(state)
	primary = button("探索",Rect2(UI_CENTER_X-110,810,220,52),_primary,true)
	escape_button = button("逃跑",Rect2(UI_CENTER_X-270,810,250,52),_escape)
	fight_button = button("开始战斗",Rect2(UI_CENTER_X+20,810,250,52),_fight,true)
	victory_return_button = button("返回商车",Rect2(UI_CENTER_X-270,810,250,52),_victory_return)
	continue_button = button("继续探索",Rect2(UI_CENTER_X+20,810,250,52),_continue_exploration,true)
	for index in range(3):
		var choice := button("",Rect2(1040,310+index*64,480,52),func(): _choose_event(index))
		choice.mouse_entered.connect(func(): event_hover = true)
		choice.mouse_exited.connect(func(): event_hover = false)
		event_buttons.append(choice)
	dialogue_button = button("继续",Rect2(1340,310,180,48),_advance_dialogue,true)
	refresh()

func button(value: String, rect: Rect2, callback: Callable, emphasized := false) -> Button:
	var b := Button.new()
	b.text = value
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_override("font",font)
	Chrome.button(b,emphasized)
	b.pressed.connect(callback)
	add_child(b)
	return b

func label(value: String, at: Vector2, size_value := 18, color := INK, centered := false, heading := false) -> void:
	var face: Font = Chrome.font(true) if heading else font
	var position_value := at
	if centered:
		position_value.x -= face.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x*0.5
	draw_string_outline(face,position_value,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,1,Chrome.BACKGROUND)
	draw_string(face,position_value,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func zone_rect(zone: String) -> Rect2:
	var dimensions := Vector2(state.zone_size(zone))*CELL_SIZE
	if zone == "loot":
		var panel := loot_panel_rect()
		return Rect2(Vector2(panel.get_center().x-dimensions.x*0.5,panel.position.y+63.0),dimensions)
	var center := inventory_panel().get_center()+Vector2(0,14) if zone == "bag" else Vector2(1390,710)
	return Rect2((center-dimensions*0.5).round(),dimensions)

func inventory_panel() -> Rect2:
	var dimensions := Vector2(state.zone_size("bag"))*CELL_SIZE
	var panel_size := Vector2(maxf(290,dimensions.x+72),maxf(242,dimensions.y+94))
	return Rect2(INVENTORY_PANEL_POSITION,panel_size)

func loot_panel_rect() -> Rect2:
	var dimensions := Vector2(state.zone_size("loot"))*CELL_SIZE
	var panel_size := dimensions+Vector2(46,86)
	return Rect2(Vector2(LOOT_PANEL_CENTER_X-panel_size.x*0.5,110),panel_size)

func item_rect(item: Dictionary) -> Rect2:
	return Rect2(zone_rect(item.zone).position+Vector2(item.cell)*CELL_SIZE,Vector2(state.dimensions(item))*CELL_SIZE)

func inventory_shell(rect: Rect2) -> void:
	Chrome.draw_window(self,rect)

func grid(zone: String) -> void:
	Chrome.draw_grid(self,zone_rect(zone),state.zone_size(zone))

func bar(rect: Rect2, value: float, maximum: float, color: Color) -> void:
	draw_style_box(Chrome.box(Chrome.GRID,Chrome.DIVIDER),rect.grow(2))
	var width := rect.size.x*clampf(value/maximum,0,1)
	draw_rect(Rect2(rect.position,Vector2(width,rect.size.y)),color)
	if width > 0:
		draw_line(rect.position+Vector2(0,1),rect.position+Vector2(width,1),color.lightened(0.3),1)

func character(key: String, feet: Vector2, height: float, hit: float, facing: float, defeated := false) -> void:
	var texture: Texture2D = textures[key]
	var merchant := key == "merchant"
	if merchant and not merchant_frames.is_empty():
		var pose := 1 if traveling else 3 if player_hit > 0.0 else 2 if attack_time > 0.0 else 4 if use_time > 0.0 else 5 if shock_time > 0.0 else 0
		texture = merchant_frames[pose]
	var dimensions := texture.get_size() * height / texture.get_height()
	var bob := sin(visual_time*2.6)*2.0
	var angle := 0.0
	var squash := Vector2.ONE
	var offset_value := Vector2.ZERO
	if merchant:
		if traveling:
			bob = -absf(sin(travel_elapsed * TAU * 3.0))*9.0
			angle = sin(visual_time*9.0)*0.014
		if attack_time > 0:
			offset_value.x = sin(attack_time/0.48*PI)*24.0
		if player_hit > 0:
			offset_value.x = -sin(player_hit/0.3*PI)*18.0
			angle = -0.04
	else:
		var windup := clampf((combat.enemy_clock-2.4)/0.6,0.0,1.0) if combat.phase == "battle" else 0.0
		if key == "slime":
			squash = Vector2(1.0+windup*0.23,1.0-windup*0.25)
			if enemy_lunge > 0:
				offset_value = Vector2(-sin(enemy_lunge/0.5*PI)*180.0,-sin(enemy_lunge/0.5*PI)*65.0)
			if hit > 0:
				squash += Vector2(sin(hit*60)*0.10,-sin(hit*60)*0.10)
			if defeated:
				squash = Vector2(1.45,0.18)
		elif key == "wolf":
			squash.y -= windup*0.18
			offset_value.x -= sin(enemy_lunge/0.5*PI)*190.0 if enemy_lunge > 0 else 0.0
			angle = sin(hit*35)*0.07 if hit > 0 else -windup*0.03
			if defeated:
				angle = 0.16
				squash.y = 0.35
		elif key in ["treant","hollow_stag"]:
			angle = windup*0.05 - (sin(enemy_lunge/0.5*PI)*0.12 if enemy_lunge > 0 else 0.0)
			offset_value.y = absf(sin(visual_time*4.0))*5.0 if repair_time > 0 else 0.0
			if defeated:
				angle = 0.13
				squash.y = 0.65
		elif key in ["chest","court","frog","well","mushrooms","logging","mining","camp","snail","hunter"]:
			bob = -absf(sin(visual_time*(6.0 if event_hover else 2.0)))* (12.0 if event_hover else 4.0)
			if key == "court":
				bob -= 5.0*absf(sin(visual_time*4.0))
			elif key == "frog":
				bob -= 14.0+sin(visual_time*2.0)*10.0
			elif key == "well" and event_hover:
				squash = Vector2(1.03,0.97)
			elif key == "camp":
				squash = Vector2(1.0+sin(visual_time*5.0)*0.025,1.0+sin(visual_time*5.0)*0.045)
			elif key == "logging":
				angle = sin(visual_time*2.0)*0.025
			if event_animation > 0:
				angle = sin(event_animation*15)*0.10
				if key == "chest":
					offset_value.x = sin(event_animation*8)*24.0
				elif key == "court":
					offset_value.y -= absf(sin(event_animation*8))*16.0
				elif key == "frog":
					squash = Vector2(1.0+sin(event_animation*7)*0.06,1.0)
				elif key == "well":
					offset_value.y -= absf(sin(event_animation*7))*12.0
				elif key == "logging":
					angle = sin(event_animation*24)*0.08
				elif key == "mining":
					offset_value.x = sin(event_animation*32)*8.0
					squash.y = 1.0-absf(sin(event_animation*16))*0.07
				elif key == "snail":
					offset_value.x = (1.2-event_animation)*28.0
			offset_value.y += (1.0-smoothstep(0,1,arrival))*90.0
		if hit > 0:
			offset_value.x += sin(hit/0.3*PI)*18.0
	var at := feet+offset_value+Vector2(0,bob)+scene_shift
	draw_set_transform(at,0,Vector2(1,0.18))
	draw_circle(Vector2.ZERO,dimensions.x*0.32,Color("13201955"))
	draw_set_transform(at,angle,squash)
	var tint := Color(1.3,0.82,0.72,1.0) if hit > 0.12 else Color.WHITE
	if defeated:
		tint.a = 0.5
	var rect := Rect2(Vector2(-dimensions.x*0.5,-dimensions.y),dimensions)
	if key == "chest" or key == "slime":
		var fraction := 0.38 if key == "chest" else 0.28 if key == "slime" else 0.38
		var cut := dimensions.y*fraction
		var source_cut := texture.get_height()*fraction
		draw_texture_rect_region(texture,Rect2(rect.position+Vector2(0,cut),Vector2(dimensions.x,dimensions.y-cut)),Rect2(0,source_cut,texture.get_width(),texture.get_height()-source_cut),tint)
		var hinge := rect.position+Vector2(0,cut)
		var sway := sin(visual_time*3.0)*0.015 if key != "chest" else sin(visual_time*(7.0 if event_hover else 2.0))*0.05
		draw_set_transform(at+(hinge*squash).rotated(angle),angle+sway,squash)
		draw_texture_rect_region(texture,Rect2(0,-cut,dimensions.x,cut),Rect2(0,0,texture.get_width(),source_cut),tint)
	else:
		draw_texture_rect(texture,rect,false,tint)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if textures.is_empty():
		return
	character("merchant",PLAYER_FEET,PLAYER_HEIGHT,player_hit,-1,combat.phase == "defeat")
	draw_rect(Rect2(0,0,1600,86),Color(Chrome.BACKGROUND,0.94))
	draw_line(Vector2(0,85),Vector2(1600,85),Chrome.DIVIDER)
	label("胡闹森林",Vector2(800,55),24,Chrome.TEXT,true,true)
	if combat.route_index >= 0 or combat.encounter > 0:
		var threat := "首领" if combat.boss else "精英" if combat.elite else "普通"
		label("遭遇 %d · %s" % [maxi(0,combat.route_index+1),"事件" if not combat.event.is_empty() else threat],Vector2(1488,52),17,INK,true)
	var panel := inventory_panel()
	inventory_shell(panel)
	label("旅行背包",Vector2(panel.get_center().x,panel.position.y+32),20,Chrome.HEADER_TEXT,true,true)
	grid("bag")
	if drag < 0:
		for hovered in state.items:
			if hovered.zone == "bag" and _footprint_has_point(hovered,item_rect(hovered),pointer):
				_draw_bag_bonus_area(state,hovered,zone_rect("bag"),Vector2.ONE*CELL_SIZE,hovered.cell)
				_draw_footprint(hovered,item_rect(hovered),Color(Chrome.TEXT,0.12))
				break
	var dims: Vector2i = state.zone_size("bag")
	if combat.can_collect() and not traveling:
		var loot_panel := loot_panel_rect()
		inventory_shell(loot_panel)
		label("战利品",Vector2(loot_panel.get_center().x,loot_panel.position.y+32),20,Chrome.HEADER_TEXT,true,true)
		grid("loot")
	for item in state.items:
		if item.zone not in ["bag","loot"] or item.id == drag or (item.zone == "loot" and (traveling or not combat.can_collect())):
			continue
		var r := item_rect(item)
		_draw_footprint(item,r,Color(Color(state.CATALOG[item.key].color),0.09))
		_draw_item(item,r,_footprint_has_point(item,r,pointer))
		if item.id == active_weapon and attack_time > 0:
			_draw_footprint(item,r,Color.TRANSPARENT,Color(Chrome.ACCENT,attack_time/0.48),3.0)
		if item.zone == "bag" and combat.phase == "battle" and item.key in combat.WEAPON_KEYS:
			var progress: float = float(combat.basic_clock)/combat.weapon_interval(item)
			draw_rect(Rect2(r.position+Vector2(2,r.size.y-4),Vector2((r.size.x-4)*progress,2)),GOLD)
	if drag >= 0:
		_draw_drag()
	if not combat.enemy.is_empty() and not traveling:
		var settle := smoothstep(0.0,1.0,arrival)
		var art_index := enemy_art_index()
		character(ENEMY_ART[art_index],ENEMY_FEET + Vector2(20,-18)*(1.0-settle),ENEMY_HEIGHT[art_index]*lerpf(0.88,1.0,settle),enemy_hit,1,combat.enemy_hp == 0)
	if combat.companion == "sylvie" and not traveling:
		var ally_size := ally_texture.get_size()*280.0/ally_texture.get_height()
		var ally_at := Vector2(760,790)+scene_shift+Vector2(sin(ally_attack_time/0.4*PI)*15,0)
		draw_texture_rect(ally_texture,Rect2(ally_at-Vector2(ally_size.x/2,ally_size.y),ally_size),false)
	_draw_stage_effects()
	_draw_event_panel()
	for entry in floats:
		label(entry.text,entry.at,28,Color("bce4b3") if entry.heal else Color("ffe1a4"),true)
	_health_card(PLAYER_STATUS_ANCHOR,"旅行商人",combat.hp,60,combat.shield)
	if not combat.enemy.is_empty() and not traveling and combat.phase in ["ready","battle"]:
		_health_card(Vector2(ENEMY_FEET.x, maxf(130,ENEMY_FEET.y - ENEMY_HEIGHT[enemy_art_index()] - 85)),combat.enemy.name,combat.enemy_hp,combat.enemy.hp)
	if combat.phase == "defeat" and not traveling:
		_defeat_popup()
	if notice != "":
		var width := font.get_string_size(notice,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+32
		draw_style_box(Chrome.box(Chrome.PANEL,Chrome.WARNING),Rect2(UI_CENTER_X-width/2,NOTICE_Y,width,31))
		label(notice,Vector2(UI_CENTER_X,NOTICE_Y+22),16,INK,true)
	if drag < 0 and not traveling and combat.phase != "defeat" and event_option_selection == "":
		_sync_item_hover()
	else:
		_hide_item_hover()

func _health_card(at: Vector2, title: String, hp: int, maximum: int, shield := 0) -> void:
	draw_style_box(Chrome.box(Chrome.PANEL,Chrome.DIVIDER),Rect2(at-Vector2(135,18),Vector2(270,80)))
	label(title,at+Vector2(0,3),17,INK,true)
	bar(Rect2(at+Vector2(-111,17),Vector2(222,8)),hp,maximum,Chrome.WARNING)
	label("%d / %d" % [hp,maximum],at+Vector2(0,47),14,INK,true)
	if shield > 0:
		label("护盾 %d" % shield,at+Vector2(97,47),12,Chrome.SUCCESS,true)

func _defeat_popup() -> void:
	draw_rect(Rect2(0,86,1600,814),Chrome.SHADE)
	var popup := Rect2(490,320,620,190)
	Chrome.draw_window(self,popup)
	label("你已战败",Vector2(popup.get_center().x,popup.position.y+32),24,Chrome.HEADER_TEXT,true,true)
	var kept: int = state.protected_bag_ids().size()
	label("遗失未保护的物品" if kept > 0 else "旅行背包物品全部遗失",Vector2(popup.get_center().x,popup.position.y+122),16,Chrome.MUTED,true)

func _draw_drag() -> void:
	var item := find_item(drag).duplicate()
	if item.is_empty():
		return
	item.rotated = rotated
	for zone in ["bag","loot"]:
		if zone == "loot" and not combat.can_collect():
			continue
		if zone_rect(zone).has_point(pointer):
			var cell := Vector2i(((pointer-offset-zone_rect(zone).position)/CELL_SIZE).round())
			var valid: bool = state.placement_error(item,zone) == "" and state.fits(item,zone,cell,drag)
			var preview := Rect2(zone_rect(zone).position+Vector2(cell)*CELL_SIZE,Vector2(state.dimensions(item))*CELL_SIZE)
			if zone == "bag":
				_draw_bag_bonus_area(state,item,zone_rect(zone),Vector2.ONE*CELL_SIZE,cell)
			_draw_footprint(item,preview,Chrome.placement(valid),Chrome.SUCCESS if valid else Chrome.WARNING)
	_draw_item(item,Rect2(pointer-offset,Vector2(state.dimensions(item))*CELL_SIZE),true)

func _sync_item_hover() -> void:
	if hover_tip == null:
		return
	for item in state.items:
		if item.zone not in ["bag","loot"] or (item.zone == "loot" and not combat.can_collect()) or not _footprint_has_point(item,item_rect(item),pointer):
			continue
		var rect := item_rect(item)
		hover_item_id = item.id
		hover_tip.show_item("battle_item:%d" % item.id,state.item_card_data(item),ITEM_TEXTURES[item.key],Vector2(rect.end.x,rect.position.y))
		return
	_hide_item_hover()

func _hide_item_hover() -> void:
	hover_item_id = -1
	if hover_tip != null:
		hover_tip.hide_tip()

func find_item(id: int) -> Dictionary:
	for item in state.items:
		if item.id == id:
			return item
	return {}

func enemy_art_index() -> int:
	return ENEMY_ART.find(combat.enemy.art) if combat.enemy.has("art") else maxi(0,(combat.encounter-1) % ENEMY_ART.size())

func _process(delta: float) -> void:
	pointer = get_local_mouse_position()
	visual_time += delta
	ally_attack_time = maxf(0,ally_attack_time-delta)
	ally_heal_time = maxf(0,ally_heal_time-delta)
	var visual_delta := 0.0 if freeze_time > 0 else delta
	freeze_time = maxf(0,freeze_time-delta)
	player_hit = maxf(0,player_hit-visual_delta)
	enemy_hit = maxf(0,enemy_hit-visual_delta)
	attack_time = maxf(0,attack_time-visual_delta)
	use_time = maxf(0,use_time-delta)
	shock_time = maxf(0,shock_time-delta)
	enemy_lunge = maxf(0,enemy_lunge-visual_delta)
	repair_time = maxf(0,repair_time-delta)
	leaf_time = maxf(0,leaf_time-delta)
	reward_flight = maxf(0,reward_flight-delta)
	scene_shift = Vector2(sin(visual_time*73.0),cos(visual_time*61.0))*3.0 if freeze_time > 0 else Vector2.ZERO
	if event_animation > 0:
		event_animation = maxf(0,event_animation-delta)
		if event_animation == 0:
			combat.finish_event()
	if traveling:
		_advance_travel(delta)
	elif arrival < 1.0:
		arrival = minf(1.0,arrival + delta / ARRIVAL_DURATION)
	else:
		combat.tick(delta)
	for entry in floats:
		entry.life -= delta
		entry.at.y -= delta*38
	floats = floats.filter(func(entry): return entry.life > 0)
	var blur := smoothstep(0.0,0.15,travel_elapsed/TRAVEL_DURATION) if traveling else 1.0-arrival
	background_blur.set_shader_parameter("blur_radius",8.0*blur)
	refresh()
	queue_redraw()

func _on_presentation(data: Dictionary) -> void:
	match data.kind:
		"companion_attack":
			ally_attack_time = 0.4
		"companion_enter":
			player_hit = 0.0
			use_time = 0.75
			used_key = ""
			ally_heal_time = 0.75
		"story_enter":
			drag = -1
		"attack":
			attack_time = 0.48
			active_weapon = int(data.weapon_id)
			active_weapon_key = data.key
		"hit":
			var target: Vector2 = ENEMY_FEET-Vector2(0,ENEMY_HEIGHT[enemy_art_index()]*0.70) if data.actor != "enemy" else PLAYER_FEET-Vector2(0,PLAYER_HEIGHT*0.82)
			if data.actor != "enemy":
				enemy_hit = 0.45 if data.get("critical",false) else 0.3
			else:
				player_hit = 0.3
				enemy_lunge = 0.5
				leaf_time = 0.8
			if int(data.damage) >= 10:
				freeze_time = 0.10
			floats.append({"text":"−%d" % data.damage if int(data.damage)>0 else "抵挡", "at":target, "life":1.0, "heal":false})
			if int(data.shield)>0:
				floats.append({"text":"护盾 −%d" % data.shield,"at":target+Vector2(0,32),"life":1.0,"heal":true})
		"heal":
			floats.append({"text":"＋%d" % data.heal,"at":PLAYER_FEET-Vector2(0,400),"life":1.0,"heal":true})
		"use":
			use_time = 0.75
			used_key = data.key
			var item: Dictionary = data.item
			effect_origin = item_rect(item).get_center() if not item.is_empty() else inventory_panel().get_center()
			if int(data.heal)>0:
				floats.append({"text":"＋%d" % data.heal,"at":PLAYER_FEET-Vector2(0,400),"life":1.0,"heal":true})
		"event_enter":
			result_line = ""
			shock_time = 0.9
		"event_result":
			event_animation = 1.4
			shock_time = 1.4
			result_line = data.text
			event_rewards = data.rewards
			if data.get("tool_key","") != "":
				active_weapon = int(data.tool_id)
				active_weapon_key = data.tool_key
				attack_time = 0.48
				shock_time = 0.0
				leaf_time = 0.8
			if int(data.hp_delta) != 0:
				floats.append({"text":"%+d" % data.hp_delta,"at":PLAYER_FEET-Vector2(0,400),"life":1.4,"heal":data.hp_delta>0})
		"boss_repair":
			repair_time = 2.0
		"victory":
			leaf_time = 1.0
			reward_flight = 0.8

func _choose_event(index: int) -> void:
	if traveling or arrival < 1.0 or not combat.choices_available() or index >= combat.event.options.size():
		return
	var option: Dictionary = combat.event.options[index]
	if option.has("item") or option.has("tool"):
		var matching: Array = combat.event_items(option)
		if matching.size() > 1:
			event_option_selection = option.id
			notice = "选择%s" % ("斧头" if option.get("tool","") == "axe" else "镐子" if option.has("tool") else state.CATALOG[option.item].name)
			return
	var error: String = combat.choose_event(option.id,combat.event_item_id(option))
	if error != "":
		notice = error
	else:
		notice = ""
		drag = -1
		event_option_selection = ""
		event_hover = false
	refresh()

func _advance_dialogue() -> void:
	if traveling or arrival < 1.0:
		return
	combat.advance_dialogue()
	refresh()

func _draw_event_panel() -> void:
	if combat.phase == "story" and not traveling:
		var rect := Rect2(1020,110,520,258)
		Chrome.draw_window(self,rect)
		label("林心之路",Vector2(1280,145),20,Chrome.HEADER_TEXT,true,true)
		var page: Dictionary = combat.current_dialogue()
		label(page.speaker,Vector2(1040,185),16,Chrome.ACCENT)
		_draw_wrapped_line(page.text,Rect2(1040,200,480,100))
		return
	if combat.event.is_empty() or traveling:
		return
	character(combat.event.art,Vector2(1160,790),230.0 if combat.event.art == "mushrooms" else 250.0,0.0,1)
	if combat.phase in ["event","event_resolving","event_result"]:
		var choosing: bool = combat.choices_available()
		var rect := Rect2(1020,110,520,410 if choosing else 258)
		Chrome.draw_window(self,rect)
		label(combat.event.name,Vector2(1280,145),20,Chrome.HEADER_TEXT,true,true)
		label("%dG" % state.gold,Vector2(1450,145),16,Chrome.MUTED)
		var page: Dictionary = combat.current_dialogue()
		label("旁白" if combat.phase == "event_resolving" else page.get("speaker",""),Vector2(1040,185),16,Chrome.ACCENT)
		_draw_wrapped_line(result_line if combat.phase == "event_resolving" else page.get("text",""),Rect2(1040,200,480,100))
	elif combat.phase == "event_loot":
		pass

func _draw_wrapped_line(value: String, rect: Rect2, text_size: int = 16, text_color: Color = Chrome.TEXT) -> void:
	var line := ""
	var y := rect.position.y+text_size+2.0
	for character_value in value:
		if font.get_string_size(line+character_value,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x > rect.size.x:
			label(line,Vector2(rect.position.x,y),text_size,text_color)
			line = ""
			y += text_size+8.0
		line += character_value
	label(line,Vector2(rect.position.x,y),text_size,text_color)

func _draw_stage_effects() -> void:
	if not traveling and combat.phase in ["ready","battle"] and combat.enemy_first_attack and combat.enemy.has("arrival_line"):
		label(combat.enemy.arrival_line,Vector2(1150,470),18,Chrome.TEXT,true)
	if attack_time > 0:
		var t := 1.0-attack_time/0.48
		var origin := Vector2(505,650)+scene_shift
		var destination := ENEMY_FEET-Vector2(0,130)+scene_shift
		var point := origin.lerp(destination,clampf(t*1.7,0,1))
		draw_line(origin.lerp(destination,maxf(0,t*1.7-0.22)),point,Color(Chrome.ACCENT,1.0-t),5.0,true)
		if active_weapon_key != "":
			var texture: Texture2D = ITEM_TEXTURES[active_weapon_key]
			var dimensions := texture.get_size()*72.0/texture.get_height()
			draw_set_transform(point,PI*0.38)
			draw_texture_rect(texture,Rect2(-dimensions*0.5,dimensions),false,Color(1,1,1,1.0-t))
			draw_set_transform(Vector2.ZERO)
	if use_time > 0 and used_key != "":
		var t := 1.0-use_time/0.75
		var at := effect_origin.lerp(Vector2(450,660),smoothstep(0,1,t))
		draw_texture_rect(ITEM_TEXTURES[used_key],Rect2(at-Vector2(16,25),Vector2(32,50)),false,Color(1,1,1,1-t*0.6))
		draw_arc(Vector2(420,720),48+40*t,0,TAU,40,Color(Chrome.SUCCESS,1-t),3.0,true)
	if combat.shield > 0:
		draw_arc(Vector2(440,690)+scene_shift,112,-1.8,1.5,32,Color(Chrome.SUCCESS,0.35),3.0,true)
	if ally_heal_time > 0:
		var t := 1.0-ally_heal_time/0.75
		draw_arc(Vector2(440,700)+scene_shift,48+70*t,0,TAU,40,Color(Chrome.SUCCESS,1-t),3.0,true)
	if leaf_time > 0:
		var debris_color: Color = Chrome.ACCENT if combat.event.get("art","") == "mining" else Chrome.SUCCESS
		for index in range(6):
			var t := 1.0-leaf_time
			var at := ENEMY_FEET+Vector2(index*18-50,-145+t*100+sin(index+t*8)*12)+scene_shift
			draw_arc(at,6,0,PI,8,Color(debris_color,leaf_time),3.0,true)
	if ally_attack_time > 0:
		var t := 1.0-ally_attack_time/0.4
		var origin := Vector2(760,615)+scene_shift
		var target := ENEMY_FEET-Vector2(0,230)+scene_shift
		draw_line(origin.lerp(target,maxf(0,t-0.18)),origin.lerp(target,t),Chrome.SUCCESS,4,true)
	if repair_time > 0:
		var at := Vector2(1130,350)+scene_shift
		var texture: Texture2D = ITEM_TEXTURES.ancient_wood
		draw_set_transform(at,sin(visual_time*7)*0.25)
		draw_texture_rect(texture,Rect2(-28,-28,56,56),false)
		draw_set_transform(Vector2.ZERO)
		label("谁把我的树枝打断了？！",Vector2(930,460),18,Chrome.TEXT)
	var flight_time := event_animation if event_animation > 0 else reward_flight
	if flight_time > 0:
		var rewards: Array = event_rewards if event_animation > 0 else state.items.filter(func(i): return i.zone == "loot").map(func(i): return i.key)
		for index in range(rewards.size()):
			var duration := 1.4 if event_animation > 0 else 0.8
			var t := clampf(1.0-flight_time/duration-index*0.07,0,1)
			var at := Vector2(1160,640).lerp(loot_panel_rect().get_center(),t)-Vector2(0,sin(t*PI)*95)
			draw_texture_rect(ITEM_TEXTURES[rewards[index]],Rect2(at-Vector2(18,18),Vector2(36,36)),false,Color(1,1,1,1-t*0.4))
	if combat.pending_verdict or combat.active_verdict:
		label("蘑菇的追索",Vector2(24,64),14,Chrome.WARNING)
	if combat.wish_debt:
		label("未结清的愿望",Vector2(24,44),14,Chrome.WARNING)

func refresh() -> void:
	primary.visible = traveling or combat.phase == "idle"
	primary.disabled = traveling
	primary.text = "前进中…" if traveling else "探索"
	escape_button.visible = not traveling and combat.phase in ["ready","battle"]
	escape_button.position = Vector2(UI_CENTER_X-125,810) if combat.phase == "battle" else Vector2(UI_CENTER_X-270,810)
	fight_button.visible = not traveling and combat.phase == "ready"
	victory_return_button.visible = not traveling and (combat.can_collect() or combat.phase in ["defeat","event","event_result"])
	continue_button.visible = not traveling and combat.can_collect()
	victory_return_button.position = Vector2(UI_CENTER_X-270,810) if combat.can_collect() else Vector2(UI_CENTER_X-110,810)
	victory_return_button.text = "丢弃并返回" if confirm_action == "return" else "返回商车"
	continue_button.text = "丢弃并继续" if confirm_action == "next" else "继续探索"
	dialogue_button.visible = not traveling and ((combat.phase == "event" and not combat.choices_available()) or combat.phase in ["event_result","story"])
	dialogue_button.disabled = arrival < 1.0
	dialogue_button.text = "继续"
	for index in range(event_buttons.size()):
		var choice := event_buttons[index]
		choice.visible = not traveling and combat.choices_available() and index < combat.event.options.size()
		if choice.visible:
			var option: Dictionary = combat.event.options[index]
			choice.text = option.label
			choice.disabled = arrival < 1.0 or combat.event_option_error(option,combat.event_item_id(option)) != ""
			choice.tooltip_text = combat.event_option_error(option,combat.event_item_id(option))


func _primary() -> void:
	if traveling:
		return
	drag = -1
	notice = ""
	if confirm_action != "":
		var action := confirm_action
		confirm_action = ""
		if action == "return":
			leave()
		else:
			_begin_travel()
	elif combat.phase == "idle":
		_begin_travel()
	elif combat.phase == "ready":
		_fight()
	elif combat.can_collect():
		_continue_exploration()
	else:
		_defeat_return()

func has_loot() -> bool:
	return state.items.any(func(i): return i.zone == "loot")

func _return() -> void:
	if traveling or not combat.can_collect():
		return
	drag = -1
	if has_loot():
		confirm_action = "return"
		notice = "未拾取物品将丢弃"
	else:
		leave()

func _return_event_result() -> void:
	if confirm_action == "return":
		leave()
	else:
		confirm_action = "return"
		notice = "未拾取物品将丢弃"

func _escape() -> void:
	if traveling or combat.phase not in ["ready","battle"]:
		return
	drag = -1
	notice = ""
	confirm_action = ""
	combat.flee()
	finished.emit()

func _fight() -> void:
	if traveling or combat.phase != "ready":
		return
	drag = -1
	notice = ""
	confirm_action = ""
	combat.begin_battle()

func _victory_return() -> void:
	if traveling:
		return
	if combat.phase == "defeat":
		_defeat_return()
		return
	if combat.phase in ["event","event_result"]:
		if has_loot():
			_return_event_result()
		else:
			leave()
		return
	if not combat.can_collect():
		return
	if confirm_action == "return":
		confirm_action = ""
		leave()
	elif has_loot():
		confirm_action = "return"
		notice = "未拾取物品将丢弃"
	else:
		leave()

func _continue_exploration() -> void:
	if traveling or not combat.can_collect():
		return
	if confirm_action == "next":
		confirm_action = ""
		_begin_travel()
	elif has_loot():
		confirm_action = "next"
		notice = "未拾取物品将丢弃"
	else:
		_begin_travel()

func _defeat_return() -> void:
	if traveling or combat.phase != "defeat":
		return
	drag = -1
	confirm_action = ""
	notice = ""
	leave()

func leave() -> void:
	combat.leave()
	finished.emit()

func _auto_pickup_loot(id: int) -> void:
	if not combat.can_collect():
		return
	var item := find_item(id)
	if item.is_empty() or item.zone != "loot":
		return
	var orientations: Array[bool] = [item.rotated]
	var current_size: Vector2i = state.dimensions(item)
	if current_size.x != current_size.y:
		orientations.append(not item.rotated)
	for orientation in orientations:
		var candidate := item.duplicate()
		candidate.rotated = orientation
		var cell: Vector2i = state.free_cell(candidate,"bag")
		if cell.x < 0:
			continue
		notice = state.move_item(id,"bag",cell,orientation)
		confirm_action = ""
		return
	notice = "背包空间不足"
	confirm_action = ""

func _gui_input(event: InputEvent) -> void:
	if traveling:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			drag = -1
			event_option_selection = ""
			notice = ""
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and (combat.phase in ["idle","ready","battle","event"] or combat.can_collect()):
			for item in state.items:
				if item.zone == "loot" and not combat.can_collect():
					continue
				if item.zone in ["bag","loot"] and _footprint_has_point(item,item_rect(item),pointer):
					if event_option_selection != "" and combat.phase == "event" and item.zone == "bag":
						var error: String = combat.choose_event(event_option_selection,item.id)
						notice = error
						if error == "":
							event_option_selection = ""
						refresh()
						return
					if item.zone == "loot" and (event.double_click or event.ctrl_pressed):
						_auto_pickup_loot(item.id)
						get_viewport().set_input_as_handled()
						return
					if item.zone == "bag" and event.double_click and combat.phase in ["ready","battle"]:
						combat.use_item(item.id)
						notice = combat.message if not find_item(item.id).is_empty() else ""
						get_viewport().set_input_as_handled()
						return
					if combat.phase == "battle":
						continue
					drag = item.id
					rotated = item.rotated
					offset = pointer-item_rect(item).position
					break

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and event_option_selection != "":
		event_option_selection = ""
		notice = ""
		get_viewport().set_input_as_handled()
		return
	if drag < 0:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			rotated = not rotated
			offset = Vector2.ONE * CELL_SIZE * 0.5
		if event.keycode == KEY_ESCAPE:
			drag = -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if zone_rect("bag").has_point(get_local_mouse_position()):
			var at := Vector2i(((get_local_mouse_position()-offset-zone_rect("bag").position)/CELL_SIZE).round())
			var error: String = state.move_item(drag,"bag",at,rotated)
			notice = error
			confirm_action = ""
		elif combat.can_collect() and zone_rect("loot").has_point(get_local_mouse_position()):
			var at := Vector2i(((get_local_mouse_position()-offset-zone_rect("loot").position)/CELL_SIZE).round())
			var error: String = state.move_item(drag,"loot",at,rotated)
			notice = error
			confirm_action = ""
		drag = -1
		get_viewport().set_input_as_handled()


func _begin_travel() -> void:
	if traveling or (combat.phase != "idle" and not combat.can_collect()):
		return
	traveling = true
	travel_elapsed = 0.0
	drag = -1
	floats.clear()
	combat.clear_loot()
	refresh()

func _advance_travel(delta: float) -> void:
	travel_elapsed = minf(TRAVEL_DURATION,travel_elapsed+delta)
	if travel_elapsed >= TRAVEL_DURATION:
		_finish_travel()

func _finish_travel() -> void:
	traveling = false
	arrival = 0.0
	combat.next_node()
