extends "res://scripts/item_art.gd"
signal finished
const Combat = preload("res://scripts/exploration_state.gd")
const HoverTip = preload("res://scripts/interact_hover_tip.gd")
const CELL_SIZE := 24.0
const ENEMY_ART := ["slime","wolf","golem","red_wolf","treant"]
const ENEMY_HEIGHT := [185.0,235.0,270.0,255.0,315.0]
const Stage = preload("res://scripts/battle_space_stage.gd")
const FOREST_BACKGROUND := preload("res://assets/exploration/stage/forest-distance.png")
const PLAYER_FEET := Vector2(420,1000)
const PLAYER_HEIGHT := 500.0
const ENEMY_FEET := Vector2(1160,760)
const UI_CENTER_X := 800.0
const INVENTORY_PANEL_POSITION := Vector2(220,110)
const LOOT_PANEL_CENTER_X := 1160.0
const PLAYER_STATUS_ANCHOR := Vector2(420,760)
const NOTICE_Y := 96.0
const TRAVEL_DURATION := 0.95
var stage: SubViewport
var traveling := false
var travel_finish_pending := false
var travel_elapsed := 0.0
var journey_depth := 0.0
var journey_depth_step := 0.075
var travel_start_depth := 0.0
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
var visual_time := 0.0
var player_hit := 0.0
var enemy_hit := 0.0
var floats: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = Chrome.font()
	theme = Chrome.theme()
	hover_tip = HoverTip.new()
	hover_tip.name = "InteractHoverTip"
	add_child(hover_tip)
	stage = Stage.new()
	add_child(stage)
	journey_depth_step = stage.get_journey_depth_step()
	for key in ["merchant"] + ENEMY_ART:
		var file_name: String = "stage/merchant-side.png" if key == "merchant" else "%s.png" % key
		textures[key] = load("res://assets/exploration/%s" % file_name)
		if key in ENEMY_ART or key == "merchant":
			var cropped := AtlasTexture.new()
			cropped.atlas = textures[key]
			cropped.region = textures[key].get_image().get_used_rect()
			textures[key] = cropped
	combat.start(state)
	primary = button("探索",Rect2(UI_CENTER_X-110,810,220,52),_primary,true)
	escape_button = button("逃跑",Rect2(UI_CENTER_X-270,810,250,52),_escape)
	fight_button = button("开始战斗",Rect2(UI_CENTER_X+20,810,250,52),_fight,true)
	victory_return_button = button("返回商车",Rect2(UI_CENTER_X-270,810,250,52),_victory_return)
	continue_button = button("继续探索",Rect2(UI_CENTER_X+20,810,250,52),_continue_exploration,true)
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
	var face: Font = font
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
	var dimensions := texture.get_size() * height / texture.get_height()
	var bob := sin(visual_time*2.6)*1.4 if combat.phase != "defeat" else 0.0
	if key == "merchant" and traveling:
		bob = -absf(sin(travel_elapsed * TAU * 3.0)) * 8.0
	var lunge := sin(hit/0.3*PI)*facing*9.0
	var position_value := feet-Vector2(dimensions.x*0.5,dimensions.y)+Vector2(lunge,bob)
	draw_set_transform(feet,0,Vector2(1,0.18))
	draw_circle(Vector2.ZERO,dimensions.x*0.32,Color("13201955"))
	draw_set_transform(Vector2.ZERO)
	var tint := Color(1.3,0.82,0.72,1.0) if hit > 0.12 else Color.WHITE
	if defeated:
		tint = Color(0.65,0.67,0.57,0.4)
	var character_rect := Rect2(position_value,dimensions)
	draw_set_transform(character_rect.get_center())
	_draw_texture_with_outline(texture,dimensions,tint)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if textures.is_empty():
		return
	_draw_forest()
	character("merchant",PLAYER_FEET,PLAYER_HEIGHT,player_hit,-1,combat.phase == "defeat")
	draw_rect(Rect2(0,0,1600,86),Color(Chrome.BACKGROUND,0.94))
	draw_line(Vector2(0,85),Vector2(1600,85),Chrome.DIVIDER)
	label("月下森林",Vector2(800,55),24,Chrome.TEXT,true,true)
	if combat.encounter > 0:
		var threat := "首领" if combat.boss else "精英" if combat.elite else "普通"
		label("深度 %d · %s" % [combat.depth,threat],Vector2(1488,52),17,INK,true)
	var panel := inventory_panel()
	inventory_shell(panel)
	label("旅行背包",Vector2(panel.get_center().x,panel.position.y+32),20,Chrome.HEADER_TEXT,true,true)
	grid("bag")
	_draw_bag_layout_guides()
	var dims: Vector2i = state.zone_size("bag")
	label("%d × %d" % [dims.x,dims.y],Vector2(panel.get_center().x,panel.end.y-19),14,Chrome.MUTED,true)
	if combat.phase == "victory" and not traveling:
		var loot_panel := loot_panel_rect()
		inventory_shell(loot_panel)
		label("战利品",Vector2(loot_panel.get_center().x,loot_panel.position.y+32),20,Chrome.HEADER_TEXT,true,true)
		grid("loot")
	for item in state.items:
		if item.zone not in ["bag","loot"] or item.id == drag or (item.zone == "loot" and traveling):
			continue
		var r := item_rect(item)
		draw_rect(r.grow(-1),Color(Color(state.CATALOG[item.key].color),0.09))
		_draw_item(item,r,r.has_point(pointer))
		if item.zone == "bag":
			_draw_item_effect_badge(item,r)
		if item.zone == "bag" and combat.phase == "battle" and item.key in combat.WEAPON_KEYS:
			var progress: float = float(combat.basic_clock)/combat.weapon_interval(item)
			draw_rect(Rect2(r.position+Vector2(2,r.size.y-4),Vector2((r.size.x-4)*progress,2)),GOLD)
	if drag >= 0:
		_draw_drag()
	if not combat.enemy.is_empty() and not traveling:
		var settle := smoothstep(0.0,1.0,arrival)
		var art_index := enemy_art_index()
		character(ENEMY_ART[art_index],ENEMY_FEET + Vector2(20,-18)*(1.0-settle),ENEMY_HEIGHT[art_index]*lerpf(0.88,1.0,settle),enemy_hit,1,combat.phase == "victory")
	for entry in floats:
		label(entry.text,entry.at,28,Color("bce4b3") if entry.heal else Color("ffe1a4"),true)
	_health_card(PLAYER_STATUS_ANCHOR,"旅行商人",combat.hp,60,combat.shield)
	if not combat.enemy.is_empty() and not traveling:
		_health_card(Vector2(ENEMY_FEET.x, ENEMY_FEET.y - ENEMY_HEIGHT[enemy_art_index()] - 85),combat.enemy.name,combat.enemy_hp,combat.enemy.hp)
	if combat.phase in ["ready","victory"] and not traveling:
		var decision := "备战" if combat.phase == "ready" else "胜利"
		label(decision,Vector2(UI_CENTER_X,755),24,Chrome.TEXT,true,true)
	label(combat.build_summary(),Vector2(panel.get_center().x,panel.end.y+24),14,Chrome.MUTED,true)
	if combat.phase == "defeat" and not traveling:
		_defeat_popup()
	if notice != "":
		var width := font.get_string_size(notice,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+32
		draw_style_box(Chrome.box(Chrome.PANEL,Chrome.WARNING),Rect2(UI_CENTER_X-width/2,NOTICE_Y,width,31))
		label(notice,Vector2(UI_CENTER_X,NOTICE_Y+22),16,INK,true)
	if drag < 0 and not traveling and combat.phase != "defeat":
		_sync_item_hover()
	else:
		_hide_item_hover()

func _health_card(at: Vector2, title: String, hp: int, maximum: int, shield := 0) -> void:
	draw_style_box(Chrome.box(Chrome.PANEL,Chrome.DIVIDER),Rect2(at-Vector2(135,18),Vector2(270,80)))
	label(title,at+Vector2(0,3),17,INK,true)
	bar(Rect2(at+Vector2(-111,17),Vector2(222,8)),hp,maximum,Chrome.WARNING)
	label("%d / %d" % [hp,maximum],at+Vector2(0,47),14,INK,true)
	if shield > 0:
		label("护盾 %d" % shield,at+Vector2(97,47),12,Chrome.CYAN,true)

func _draw_bag_layout_guides() -> void:
	var rect := zone_rect("bag")
	var belt := Rect2(rect.position,Vector2(CELL_SIZE*2.0,rect.size.y))
	draw_rect(belt,Color(Chrome.CYAN,0.08),true)
	draw_rect(belt,Color(Chrome.CYAN,0.45),false,2.0)
	label("腰包 0行动",Vector2(belt.get_center().x,belt.position.y+15),10,Chrome.CYAN,true)
	for weapon in state.items:
		if weapon.zone != "bag" or weapon.key not in combat.WEAPON_KEYS:
			continue
		for support in state.bag_adjacent_items(weapon):
			if state.CATALOG[support.key].category != "矿石" and support.key != "power":
				continue
			var color := Color("e0ad70cc") if state.CATALOG[support.key].category == "矿石" else Color("b798e0cc")
			draw_line(item_rect(weapon).get_center(),item_rect(support).get_center(),color,4.0,true)

func _draw_item_effect_badge(item: Dictionary, rect: Rect2) -> void:
	var effects: Dictionary = state.bag_effects(item)
	var badges: Array[String] = []
	if int(effects.damage_bonus) > 0:
		badges.append("+%d攻" % effects.damage_bonus)
		if float(effects.attack_interval) > 2.0:
			badges.append("%.2f秒" % effects.attack_interval)
	elif int(effects.adjacent_weapons) > 0 and int(effects.support_bonus) > 0:
		badges.append("邻武+%d" % effects.support_bonus)
	if effects.free_use:
		badges.append("0行动")
	if effects.protected:
		badges.append("保留")
	if int(effects.base_heal) > 0 and int(effects.final_heal) > int(effects.base_heal):
		badges.append("回%d" % effects.final_heal)
	if badges.is_empty():
		return
	var text_value := " · ".join(badges)
	var width := font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+12.0
	var badge_rect := Rect2(rect.position+Vector2(2,2),Vector2(width,19))
	draw_style_box(Chrome.box(Chrome.BACKGROUND,Chrome.CYAN),badge_rect)
	label(text_value,badge_rect.position+Vector2(6,14),11,Chrome.TEXT)

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
		if zone == "loot" and combat.phase != "victory":
			continue
		if zone_rect(zone).has_point(pointer):
			var cell := Vector2i(((pointer-offset-zone_rect(zone).position)/CELL_SIZE).round())
			var valid: bool = state.placement_error(item,zone) == "" and state.fits(item,zone,cell,drag)
			var preview := Rect2(zone_rect(zone).position+Vector2(cell)*CELL_SIZE,Vector2(state.dimensions(item))*CELL_SIZE)
			draw_rect(preview,Chrome.placement(valid))
			draw_rect(preview,Chrome.CYAN if valid else Chrome.WARNING,false,1)
	_draw_item(item,Rect2(pointer-offset,Vector2(state.dimensions(item))*CELL_SIZE),true)

func _sync_item_hover() -> void:
	if hover_tip == null:
		return
	for item in state.items:
		if item.zone not in ["bag","loot"] or not item_rect(item).has_point(pointer):
			continue
		var data: Dictionary = state.CATALOG[item.key]
		var rect := item_rect(item)
		var action_hint: String = "双击 / Ctrl+点击自动收纳" if item.zone == "loot" else "每 2 秒自动攻击" if item.key in combat.WEAPON_KEYS else "双击使用" if item.key in combat.USABLE_ITEM_KEYS and combat.phase in ["ready","battle"] else "战斗中无法直接使用"
		hover_item_id = item.id
		hover_tip.show_tip("battle_item:%d" % item.id,str(data.name),Vector2(rect.end.x,rect.position.y),false,state.item_hover_details(item,action_hint))
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
	return maxi(0,(combat.encounter-1) % ENEMY_ART.size())

func _process(delta: float) -> void:
	pointer = get_local_mouse_position()
	visual_time += delta
	player_hit = maxf(0,player_hit-delta)
	enemy_hit = maxf(0,enemy_hit-delta)
	var old_hp: int = combat.hp
	var old_enemy_hp: int = combat.enemy_hp
	if traveling:
		_advance_travel(delta)
	elif arrival < 1.0:
		arrival = minf(1.0,arrival + delta / 0.2)
	else:
		combat.tick(delta)
	if combat.hp != old_hp:
		player_hit = 0.3 if combat.hp < old_hp else 0.0
		floats.append({"text":"%+d" % (combat.hp-old_hp),"at":PLAYER_FEET-Vector2(0,PLAYER_HEIGHT*0.82),"life":1.0,"heal":combat.hp > old_hp})
	if combat.enemy_hp < old_enemy_hp:
		enemy_hit = 0.3
		floats.append({"text":"−%d" % (old_enemy_hp-combat.enemy_hp),"at":ENEMY_FEET-Vector2(0,ENEMY_HEIGHT[enemy_art_index()]+12),"life":1.0,"heal":false})
	for entry in floats:
		entry.life -= delta
		entry.at.y -= delta*38
	floats = floats.filter(func(entry): return entry.life > 0)
	stage.set_journey(journey_depth,travel_elapsed,TRAVEL_DURATION,traveling)
	if traveling and travel_finish_pending and stage.is_journey_transition_complete():
		_finish_travel()
	refresh()
	queue_redraw()

func refresh() -> void:
	primary.visible = traveling or combat.phase == "idle"
	primary.disabled = traveling
	primary.text = "前进中…" if traveling else "探索"
	escape_button.visible = not traveling and combat.phase == "ready"
	fight_button.visible = not traveling and combat.phase == "ready"
	victory_return_button.visible = not traveling and combat.phase in ["victory","defeat"]
	continue_button.visible = not traveling and combat.phase == "victory"
	victory_return_button.position = Vector2(UI_CENTER_X-270,810) if combat.phase == "victory" else Vector2(UI_CENTER_X-110,810)
	victory_return_button.text = "丢弃并返回" if confirm_action == "return" else "返回商车"
	continue_button.text = "丢弃并继续" if confirm_action == "next" else "继续探索"

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
	elif combat.phase == "victory":
		_continue_exploration()
	else:
		_defeat_return()

func has_loot() -> bool:
	return state.items.any(func(i): return i.zone == "loot")

func _return() -> void:
	if traveling or combat.phase not in ["victory"]:
		return
	drag = -1
	if has_loot():
		confirm_action = "return"
		notice = "未拾取物品将丢弃"
	else:
		leave()

func _escape() -> void:
	if traveling or combat.phase != "ready":
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
	if combat.phase != "victory":
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
	if traveling or combat.phase != "victory":
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
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and combat.phase in ["idle","ready","battle","victory"]:
			for item in state.items:
				if item.zone in ["bag","loot"] and item_rect(item).has_point(pointer):
					if item.zone == "loot" and (event.double_click or event.ctrl_pressed):
						_auto_pickup_loot(item.id)
						get_viewport().set_input_as_handled()
						return
					if item.zone == "bag" and event.double_click and combat.phase in ["ready","battle"]:
						combat.use_item(item.id)
						notice = combat.message
						get_viewport().set_input_as_handled()
						return
					if combat.phase == "battle":
						continue
					drag = item.id
					rotated = item.rotated
					offset = pointer-item_rect(item).position
					break

func _input(event: InputEvent) -> void:
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
		elif combat.phase == "victory" and zone_rect("loot").has_point(get_local_mouse_position()):
			var at := Vector2i(((get_local_mouse_position()-offset-zone_rect("loot").position)/CELL_SIZE).round())
			var error: String = state.move_item(drag,"loot",at,rotated)
			notice = error
			confirm_action = ""
		drag = -1
		get_viewport().set_input_as_handled()


func _begin_travel() -> void:
	if traveling or combat.phase not in ["idle","victory"]:
		return
	traveling = true
	travel_finish_pending = false
	travel_elapsed = 0.0
	travel_start_depth = journey_depth
	drag = -1
	floats.clear()
	combat.clear_loot()
	refresh()

func _advance_travel(delta: float) -> void:
	if travel_finish_pending:
		return
	travel_elapsed = minf(TRAVEL_DURATION,travel_elapsed + delta)
	var progress := smoothstep(0.0,1.0,travel_elapsed / TRAVEL_DURATION)
	journey_depth = travel_start_depth + progress * journey_depth_step
	if travel_elapsed >= TRAVEL_DURATION:
		travel_elapsed = TRAVEL_DURATION
		journey_depth = travel_start_depth + journey_depth_step
		travel_finish_pending = true

func _finish_travel() -> void:
	traveling = false
	travel_finish_pending = false
	arrival = 0.0
	combat.next_encounter()

func _draw_forest() -> void:
	# The distant plate fills the transparent opening in the layered forest
	# scene, keeping the battle floor readable while preserving the dark night
	# palette of the existing foreground layers.
	draw_texture_rect(FOREST_BACKGROUND,Rect2(0,0,1600,900),false,Color("65758a"))
	draw_texture_rect(stage.get_texture(),Rect2(0,0,1600,900),false)
