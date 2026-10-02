extends "res://scripts/item_art.gd"
const MUTED = Chrome.MUTED
const DARK = Chrome.BACKGROUND
const CELL = Vector2(24,24)
const BAG_CELL = CELL
const COUNTER_RECT := Rect2(382,485,1032,96)
# The red line in the countertop art is the actual support plane. The
# rectangle still describes the full visible counter surface for horizontal
# clamping, but physics must stop at its top edge rather than the cabinet
# opening below it.
const COUNTER_BASELINE_Y := COUNTER_RECT.position.y
# The area above the stock/cabinet is intentionally one continuous drop field.
# It is not subdivided into counter cells; dropping anywhere here starts a fall.
const COUNTER_DROP_RECT := Rect2(300,84,1140,COUNTER_BASELINE_Y-84.0)
const PopupSkin = preload("res://scripts/popup_style.gd")
const WorkbenchView = preload("res://scripts/workbench_view.gd")
const HoverTip = preload("res://scripts/interact_hover_tip.gd")
var ZONES = {
	"stock": {"rect":Rect2(Vector2(462,531),Vector2(State.SIZES.stock)*CELL),"cell":CELL}}
var state = State.new()
var font: SystemFont
var hover_id := -1
var drag_id := -1
var drag_rotated := false
var drag_offset := Vector2.ZERO
var mouse := Vector2.ZERO
var toast := ""
var toast_time := 0.0
var hover_tip: Control
var hover_target := ""
var dialogue := ""
var dialogue_lines: Array[String] = []
var dialogue_line_index := 0
var dialogue_char_index := 0
var dialogue_timer := 0.0
var dialogue_pause := 0.0
var dialogue_line_recorded := false
var dialogue_active := false
var dialogue_playing := false
var dialogue_history: Array[Dictionary] = []
const DIALOGUE_CHAR_INTERVAL := 0.11
const DIALOGUE_LINE_GAP := 0.32
const DIALOGUE_END_GAP := 0.78
const DIALOGUE_RECT := Rect2(960,104,360,170)
const DIALOGUE_BODY_LIMIT := 18
var dialogue_prev_button: Button
var dialogue_next_button: Button
var dialogue_background: Panel
var dialogue_speaker_label: Label
var dialogue_text_label: Label
var dialogue_dot_nodes: Array[Panel] = []
var price: SpinBox
var accept: Button
var haggle: Button
var cancel: Button
var next_button: Button
var trade_panel: Panel
var trade_panel_dismissed := false
var customer_index := 0
var art_buttons: Array[TextureButton] = []
const CUSTOMERS = [
	{"name":"希尔薇","role":"森林采集者","portrait":"res://assets/approved-layout/customer-sylvie.png","buy_category":"材料","sell_key":"","goods":[],"funds":120,"conversation":["晚上好，我从森林边缘赶来。","我只想收购材料类物品，其他东西暂时没有意愿。","如果价格合适，就在柜台成交吧。"]},
	{"name":"莱昂","role":"旅剑士","portrait":"res://assets/customers/knight.png","buy_category":"武器","sell_key":"sword","goods":["sword","sword"],"funds":160,"conversation":["旅商，借你的灯看一眼。","我带来两把旅人长剑，也收购你打造的武器。","看过成色之后，我们再谈报价。"]},
	{"name":"绫叶","role":"草药师","portrait":"res://assets/customers/apothecary.png","buy_category":"药剂","sell_key":"","goods":[],"funds":180,"conversation":["你好，我刚从南坡回来。","我只想收购药剂，别的种类先不考虑。","请把你能接受的价格写在交易单上。"]},
	{"name":"布洛克","role":"矿石商人","portrait":"res://assets/customers/miner.png","buy_category":"","sell_key":"*","goods":["ore","ore","ore","copper_ore","copper_ore","copper_ore","slime_mucus","slime_mucus","ancient_wood","ancient_wood"],"funds":100,"conversation":["让开一点，矿箱很重。","我带来了矿石和燃料，正好能用来打造装备。","看过成色之后，我们再谈报价。"]}]
var exploration: Control
var modal: Panel
var market_board: Control
var module_shop: Control
var tip_layer: Control
var trade_visible := false
var open_machine := -1
var press_position := Vector2.ZERO
var machine_popups: Dictionary = {}
var machine_window_nodes: Dictionary = {}
var machine_closes: Dictionary = {}
var recipe_buttons: Dictionary = {}
var machine_dragging_id := -1
var machine_drag_offset := Vector2.ZERO
var bag_window_node: Control
var bag_close: Button
var open_bag := false
var bag_popup := Rect2(24,320,200,250)
var bag_dragging := false
var bag_drag_offset := Vector2.ZERO
var recorder_button: Button
var recorder_panel: Panel
var recorder_close: Button
var recorder_rows: VBoxContainer
var recorder_dragging := false
var recorder_drag_offset := Vector2.ZERO
var door_art: TextureButton
var bed_art: TextureButton
var table_art: TextureRect
var computer_art: TextureButton
var phone_art: TextureButton
var bell_art: TextureButton
var door_closer_art: TextureButton
var shutter_clip: Control
var shutter_animating := false
var shutter_closed := false
var business_active := true
var next_day_ready := false
var bell_hold_active := false
var bell_hold_time := 0.0
var bell_hold_completed := false
const BELL_HOLD_DURATION := 1.15
const SHUTTER_SIZE := Vector2(1024,362)
const DOOR_ART_RECT := Rect2(-8,-8,225,928)
const BED_ART_RECT := Rect2(1250,488,422,450)
const TABLE_ART_RECT := Rect2(155,168,1362,876)
func _ready() -> void:
	font = PopupSkin.font()
	theme = PopupSkin.theme()
	hover_tip = HoverTip.new()
	hover_tip.name = "InteractHoverTip"
	add_child(hover_tip)
	_install_scene_art()
	_button("营业中",Rect2(1400,20,158,36),func(): _notify("收摊后可从左侧车门外出，或在右侧床铺休息。"))
	_button("行情",Rect2(305,20,86,36),_open_market_board)
	_button("改装",Rect2(401,20,86,36),_open_module_shop)
	_button("?",Rect2(1350,20,36,36),_show_help)
	next_button = _button("下一位客人",Rect2(1430,795,150,36),_next_trade)
	recorder_button = _button("历史对话",Rect2(1430,837,150,28),_open_recorder)
	recorder_button.visible = false
	customer_bag_button = _button("顾客背包",Rect2(1250,20,90,36),_open_customer_bag)
	bag_window_node = _popup_host(bag_popup)
	bag_close = _popup_close(bag_window_node, _close_bag)
	bag_window_node.hide()
	customer_bag_window_node = _popup_host(customer_bag_rect)
	customer_bag_close = _popup_close(customer_bag_window_node, _close_customer_bag)
	customer_bag_window_node.hide()
	trade_panel = Panel.new()
	trade_panel.set_script(preload("res://scripts/trade_panel.gd"))
	trade_panel.position = Vector2(1180,354)
	trade_panel.z_index = 40
	add_child(trade_panel)
	price = trade_panel.price
	accept = trade_panel.accept
	haggle = trade_panel.haggle
	cancel = trade_panel.cancel
	trade_panel.offer_submitted.connect(func(value): price.value=value; _haggle())
	trade_panel.accepted.connect(_settle)
	trade_panel.withdrawn.connect(_cancel_trade)
	trade_panel.connect("close_requested",_close_trade_panel)
	_create_dialogue_controls()
	_apply_customer_profile()
	_sync()
	_start_customer_conversation()
	if "--smoke-ui" in OS.get_cmdline_user_args():
		_smoke_ui.call_deferred()
func _button(text_value: String, rect: Rect2, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = rect.position
	b.size = rect.size
	PopupSkin.button(b,primary)
	b.pressed.connect(action)
	add_child(b)
	return b
func _popup_host(rect: Rect2) -> Control:
	var host := Control.new()
	host.position = rect.position
	host.size = rect.size
	host.z_index = 30
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	return host
func _popup_close(host: Control, action: Callable) -> Button:
	var b := Button.new()
	b.text = "×"
	b.position = Vector2(host.size.x - 42,8)
	b.size = Vector2(30,30)
	_style_popup_close(b)
	b.pressed.connect(action)
	host.add_child(b)
	return b
func _process(delta: float) -> void:
	mouse = get_local_mouse_position()
	_step_counter_physics(delta)
	var build_summary_over := open_bag and _bag_build_summary_rect().has_point(mouse)
	var next_hover_id := -1 if drag_id >= 0 or _full_overlay_open() or is_instance_valid(exploration) or build_summary_over else _item_at(mouse)
	if next_hover_id != hover_id:
		if hover_id >= 0:
			_hide_hover_tip("item:%d" % hover_id)
		hover_id = next_hover_id
	if hover_id >= 0 and not hover_target.begins_with("art:"):
		var hovered_item := _find_item(hover_id)
		if not hovered_item.is_empty():
			var item_data: Dictionary = State.CATALOG[hovered_item.key]
			_show_hover_tip("item:%d" % hover_id,str(item_data.name),_item_hover_anchor(hovered_item),false,_item_hover_details(hovered_item))
	elif not hover_target.begins_with("art:"):
		if not _show_workbench_preview():
			_hide_hover_tip()
	# Drawn popup surfaces must shield underlying scene buttons, including the door.
	var machine_over := false
	for popup_value in machine_popups.values():
		var popup: Rect2 = popup_value
		if popup.has_point(mouse):
			machine_over = true
			break
	var recorder_over := recorder_panel != null and is_instance_valid(recorder_panel) and recorder_panel.get_global_rect().has_point(mouse)
	var over_popup := not _full_overlay_open() and not is_instance_valid(exploration) and ((open_bag and (bag_popup.has_point(mouse) or _bag_build_summary_rect().has_point(mouse))) or machine_over or recorder_over or (customer_bag_open and customer_bag_rect.has_point(mouse)))
	for child in get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE if over_popup else Control.MOUSE_FILTER_STOP
	for b in art_buttons:
		var art_blocked := drag_id >= 0 or _full_overlay_open() or is_instance_valid(exploration) or shutter_animating or over_popup
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE if art_blocked else Control.MOUSE_FILTER_STOP
	if toast_time > 0:
		toast_time -= delta
	if dialogue_active:
		_advance_dialogue(delta)
		_update_dialogue_controls()
	if bell_hold_active:
		bell_hold_time += delta
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_cancel_bell_hold()
		elif bell_hold_time >= BELL_HOLD_DURATION:
			_complete_bell_hold()
	queue_redraw()

func _show_hover_tip(key: String, text_value: String, screen_pos: Vector2, tilted := true, body_text := "", tip_z := 4096, side := 1.0, target_rect := Rect2(), alignment := "") -> void:
	if hover_tip == null:
		return
	hover_target = key
	hover_tip.show_tip(key,text_value,screen_pos,tilted,body_text,tip_z,side,target_rect,alignment)

func _hide_hover_tip(key := "") -> void:
	if hover_tip == null:
		return
	if key != "" and hover_target != key:
		return
	hover_target = ""
	hover_tip.hide_tip(key)

func _item_hover_anchor(item: Dictionary) -> Vector2:
	var rect := _item_hit_rect(item)
	return Vector2(rect.end.x,rect.position.y)

func _item_hover_details(item: Dictionary) -> String:
	return state.item_hover_details(item)
func _install_scene_art() -> void:
	# Keep the supplied props as explicit scene nodes so the art is visible in
	# the editor and remains inspectable/editable outside of runtime.
	door_art = get_node("DoorArt") as TextureButton
	bed_art = get_node("BedArt") as TextureButton
	table_art = get_node("TableArt") as TextureRect
	computer_art = get_node("ComputerArt") as TextureButton
	phone_art = get_node("PhoneArt") as TextureButton
	bell_art = get_node("CallBellArt") as TextureButton
	door_closer_art = get_node("DoorCloserArt") as TextureButton
	shutter_clip = get_node("RollerShutterClip") as Control
	_bind_art_hotspot(door_art,"车门",_door)
	_bind_art_hotspot(bed_art,"卧铺",_end_day)
	_bind_art_hotspot(computer_art,"交易终端",_open_trade_panel)
	_bind_art_hotspot(phone_art,"手机",_open_recorder)
	_bind_art_visual(bell_art,"呼叫铃")
	bell_art.gui_input.connect(_bell_gui_input)
	_bind_art_hotspot(door_closer_art,"关门器",_toggle_shutter)
	table_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_art.show_behind_parent = false
	shutter_clip.visible = false
	shutter_clip.size = Vector2(SHUTTER_SIZE.x,0)
func _panel(rect: Rect2, bg := PopupSkin.PANEL, border := PopupSkin.FRAME) -> void:
	draw_colored_polygon(PopupSkin.window_points(Rect2(rect.position+Vector2(4,4),rect.size),8),Color(0,0,0,0.45))
	draw_colored_polygon(PopupSkin.window_points(rect,8),bg)
	var outline := PopupSkin.window_points(rect,8)
	outline.append(outline[0])
	draw_polyline(outline,border,1.0,true)
func _text(value: String, at: Vector2, size_value := 16, color := INK, use_serif := false) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func _create_dialogue_controls() -> void:
	dialogue_background = Panel.new()
	dialogue_background.name = "DialogueBackground"
	dialogue_background.position = DIALOGUE_RECT.position
	dialogue_background.size = DIALOGUE_RECT.size
	PopupSkin.window(dialogue_background)
	dialogue_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_background.z_index = 110
	$ArtLayers.add_child(dialogue_background)
	dialogue_speaker_label = Label.new()
	dialogue_speaker_label.name = "DialogueSpeaker"
	dialogue_speaker_label.position = DIALOGUE_RECT.position + Vector2(20,12)
	dialogue_speaker_label.size = Vector2(240,28)
	dialogue_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_speaker_label.add_theme_font_override("font",PopupSkin.font(true))
	dialogue_speaker_label.add_theme_font_size_override("font_size",20)
	dialogue_speaker_label.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
	dialogue_speaker_label.z_index = 110
	$ArtLayers.add_child(dialogue_speaker_label)
	dialogue_text_label = Label.new()
	dialogue_text_label.name = "DialogueText"
	dialogue_text_label.position = DIALOGUE_RECT.position + Vector2(20,52)
	dialogue_text_label.size = Vector2(320,72)
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_text_label.clip_text = true
	dialogue_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text_label.add_theme_font_override("font",font)
	dialogue_text_label.add_theme_font_size_override("font_size",16)
	dialogue_text_label.add_theme_color_override("font_color",PopupSkin.TEXT)
	dialogue_text_label.z_index = 110
	$ArtLayers.add_child(dialogue_text_label)
	for i in range(5):
		var dot := Panel.new()
		dot.name = "DialogueDot%d" % i
		dot.size = Vector2(8,8)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.z_index = 110
		$ArtLayers.add_child(dot)
		dialogue_dot_nodes.append(dot)
	dialogue_prev_button = Button.new()
	dialogue_prev_button.name = "DialoguePrevious"
	dialogue_prev_button.text = "◀"
	dialogue_prev_button.focus_mode = Control.FOCUS_NONE
	dialogue_prev_button.z_index = 110
	_style_dialogue_nav_button(dialogue_prev_button)
	dialogue_prev_button.pressed.connect(_dialogue_previous)
	$ArtLayers.add_child(dialogue_prev_button)
	dialogue_next_button = Button.new()
	dialogue_next_button.name = "DialogueNext"
	dialogue_next_button.text = "▶"
	dialogue_next_button.focus_mode = Control.FOCUS_NONE
	dialogue_next_button.z_index = 110
	_style_dialogue_nav_button(dialogue_next_button)
	dialogue_next_button.pressed.connect(_dialogue_next)
	$ArtLayers.add_child(dialogue_next_button)
	_update_dialogue_controls()
func _style_dialogue_nav_button(button: Button) -> void:
	button.size = Vector2(38,34)
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size",22)
	button.add_theme_color_override("font_color",PopupSkin.TEXT)
	button.add_theme_color_override("font_hover_color",PopupSkin.ORANGE.lightened(0.12))
	button.add_theme_color_override("font_pressed_color",PopupSkin.ORANGE)
	button.add_theme_color_override("font_disabled_color",Color("667078"))
	for mode in ["normal","hover","pressed","disabled","focus"]:
		button.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
func _update_dialogue_controls() -> void:
	if dialogue_background == null or dialogue_prev_button == null or dialogue_next_button == null:
		return
	dialogue_background.visible = dialogue_active
	dialogue_speaker_label.visible = dialogue_active
	dialogue_speaker_label.text = CUSTOMERS[customer_index].name
	dialogue_text_label.visible = dialogue_active
	dialogue_text_label.text = _dialogue_display_text()
	dialogue_prev_button.position = DIALOGUE_RECT.position + Vector2(256,128)
	dialogue_next_button.position = DIALOGUE_RECT.position + Vector2(304,128)
	dialogue_prev_button.visible = dialogue_active
	dialogue_next_button.visible = dialogue_active
	dialogue_prev_button.disabled = dialogue_line_index <= 0
	dialogue_next_button.disabled = not dialogue_playing and dialogue_line_index >= dialogue_lines.size()-1
	for i in range(dialogue_dot_nodes.size()):
		var dot := dialogue_dot_nodes[i]
		dot.visible = dialogue_active and i < dialogue_lines.size()
		dot.position = DIALOGUE_RECT.position + Vector2(20+i*12,145)
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = PopupSkin.ORANGE if i == dialogue_line_index else Color("697277")
		dot_style.set_corner_radius_all(4)
		dot.add_theme_stylebox_override("panel",dot_style)
func _draw() -> void:
	var status_rect := Rect2(20,16,275,64)
	PopupSkin.draw_window(self,status_rect,false)
	draw_colored_polygon(PopupSkin.header_points(Rect2(status_rect.position,Vector2(status_rect.size.x,36))),PopupSkin.HEADER)
	draw_rect(Rect2(status_rect.position,Vector2(6,status_rect.size.y)),PopupSkin.ORANGE)
	draw_line(status_rect.position+Vector2(16,39),status_rect.position+Vector2(status_rect.size.x-16,39),PopupSkin.DIVIDER,1.0)
	PopupSkin.title(self,"第 %02d 天 · %s" % [state.day,state.economy.city_name()],status_rect.position+Vector2(20,26),20)
	_text("距启程 %d 天" % state.economy.days_until_departure(state.day),status_rect.position+Vector2(20,56),14,PopupSkin.MUTED)
	draw_string(PopupSkin.font(true),status_rect.position+Vector2(145,57),"%d G" % state.gold,HORIZONTAL_ALIGNMENT_RIGHT,114,18,PopupSkin.TEXT)
	if bell_hold_active and bell_art != null:
		var progress := clampf(bell_hold_time / BELL_HOLD_DURATION,0.0,1.0)
		var bell_center := bell_art.position + bell_art.size*0.5
		draw_arc(bell_center,62.0,0.0,TAU,64,Color(0.05,0.08,0.09,0.72),5.0,true)
		draw_arc(bell_center,62.0,-PI*0.5,-PI*0.5+TAU*progress,64,PopupSkin.ORANGE,6.0,true)
		_text("长按呼叫",bell_center+Vector2(-31,82),13,PopupSkin.TEXT)
	# The counter is a continuous physical surface, not an inventory grid.
	_draw_counter_items()
	_draw_zone("stock",true)
	for item in state.items:
		if item.id != drag_id and ZONES.has(item.zone) and item.zone not in ["bag","customer"] and not item.zone.begins_with("machine_"):
			_draw_item(item,_item_rect(item),false)
	if customer_bag_open:
		_draw_bag_shell(customer_bag_rect,"%s的背包" % CUSTOMERS[customer_index].name,"")
		_draw_zone("customer",true)
		for item in state.items:
			if item.id != drag_id and item.zone == "customer":
				_draw_item(item,_item_rect(item),false)
	if open_bag:
		var installed := " · ".join(state.economy.modules.map(func(id): return state.economy.module_name(id)))
		_draw_bag_shell(bag_popup,"旅行背包 · %d×%d" % [state.bag_size.x,state.bag_size.y],installed)
		_draw_zone("bag",true)
		_draw_bag_layout_guides_shop()
		for item in state.items:
			if item.id != drag_id and item.zone == "bag":
				var bag_item_rect := _item_rect(item)
				_draw_item(item,bag_item_rect,false)
				_draw_bag_effect_badge_shop(item,bag_item_rect)
		_draw_bag_build_summary()
	var machine_draw_order := _machine_ids_topmost()
	machine_draw_order.reverse()
	for machine_id in machine_draw_order:
		var machine := _find_item(machine_id)
		if machine.is_empty() or not machine_popups.has(machine_id):
			continue
		var popup: Rect2 = machine_popups[machine_id]
		if machine.key in ["furnace","alembic"]:
			WorkbenchView.draw_window(self,popup,machine_id)
			continue
		var machine_zone := state.machine_zone(machine_id)
		_draw_bag_shell(popup,State.CATALOG[machine.key].name,"次日产出")
		_draw_zone(machine_zone,true)
		for item in state.items:
			if item.id != drag_id and item.zone == machine_zone:
				_draw_item(item,_item_rect(item),false)
	if drag_id >= 0:
		var item := _find_item(drag_id).duplicate()
		if not item.is_empty():
			item.rotated = drag_rotated
			item.counter_angle = 0.0
			var d: Vector2i = state.dimensions(item)
			var zone := _zone_at(mouse)
			if zone == "counter":
				var ghost_rect := Rect2(mouse-drag_offset,Vector2(d)*CELL)
				draw_rect(ghost_rect,PopupSkin.placement(true,0.18),true)
				draw_rect(ghost_rect.grow(-1),PopupSkin.TEXT,false,2)
			elif zone != "":
				var at := _cell_at(mouse-drag_offset,zone)
				var pos: Vector2 = ZONES[zone].rect.position+Vector2(at)*ZONES[zone].cell
				var valid: bool = _valid_drop(item,zone,at)
				draw_rect(Rect2(pos,Vector2(d)*ZONES[zone].cell),PopupSkin.placement(valid))
			var ghost_cell: Vector2 = BAG_CELL if item.zone == "bag" else CELL
			if zone != "" and zone != "counter":
				ghost_cell = ZONES[zone].cell
			_draw_item(item,Rect2(mouse-drag_offset,Vector2(d)*ghost_cell),true)
	if toast_time > 0:
		var w := font.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+54
		var toast_x := clampf(120.0,8.0,1600.0-w-8.0)
		_panel(Rect2(toast_x,812,w,42),PopupSkin.PANEL,PopupSkin.WARNING)
		_text(toast,Vector2(toast_x+27,839),15)
func _draw_zone(zone: String, visible_grid: bool) -> void:
	if zone == "counter":
		return
	if zone == "stock" and drag_id < 0:
		return
	var config: Dictionary = ZONES[zone]
	var rect: Rect2 = config.rect
	PopupSkin.draw_grid(self,rect,state.zone_size(zone),config.cell)

func _draw_bag_layout_guides_shop() -> void:
	if not ZONES.has("bag"):
		return
	var rect: Rect2 = ZONES.bag.rect
	var belt := Rect2(rect.position,Vector2(BAG_CELL.x*2.0,rect.size.y))
	draw_rect(belt,Color(PopupSkin.CYAN,0.08),true)
	draw_rect(belt,Color(PopupSkin.CYAN,0.45),false,2.0)
	_text("腰包 0行动",belt.position+Vector2(4,14),9,PopupSkin.CYAN)
	for weapon in state.items:
		if weapon.zone != "bag" or State.CATALOG[weapon.key].category != "武器":
			continue
		for support in state.bag_adjacent_items(weapon):
			if State.CATALOG[support.key].category != "矿石" and support.key != "power":
				continue
			var color := Color("e0ad70cc") if State.CATALOG[support.key].category == "矿石" else Color("b798e0cc")
			draw_line(_item_rect(weapon).get_center(),_item_rect(support).get_center(),color,4.0,true)

func _draw_bag_effect_badge_shop(item: Dictionary, rect: Rect2) -> void:
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
	var value := " · ".join(badges)
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x+10.0
	var badge := Rect2(rect.position+Vector2(2,2),Vector2(width,17))
	draw_style_box(PopupSkin.box(PopupSkin.BACKGROUND,PopupSkin.CYAN),badge)
	_text(value,badge.position+Vector2(5,12),9,PopupSkin.TEXT)

func _draw_bag_build_summary() -> void:
	var bag_items: Array[Dictionary] = state.items.filter(func(i): return i.zone == "bag")
	var weapons: Array[Dictionary] = bag_items.filter(func(i): return State.CATALOG[i.key].category == "武器")
	var protected_ids: Array[int] = state.protected_bag_ids()
	var protected_names: Array[String] = []
	for item in bag_items:
		if protected_ids.has(item.id):
			protected_names.append(str(State.CATALOG[item.key].name))
	var belt_names: Array[String] = []
	for item in bag_items:
		if state.bag_effects(item).free_use:
			belt_names.append(str(State.CATALOG[item.key].name))
	var summary := _bag_build_summary_rect()
	_panel(summary,PopupSkin.PANEL,PopupSkin.FRAME)
	_text("当前组合效果",summary.position+Vector2(18,28),17,PopupSkin.TEXT)
	var y := 54.0
	if weapons.is_empty():
		_text("武器：徒手攻击 5",summary.position+Vector2(18,y),13,PopupSkin.MUTED)
		y += 24
	else:
		for weapon in weapons:
			var effects: Dictionary = state.bag_effects(weapon)
			var base_attack: int = int(State.CATALOG[weapon.key].get("attack",8))
			var color := PopupSkin.CYAN if int(effects.damage_bonus) > 0 else PopupSkin.MUTED
			_text("%s：攻击 %d → %d · %.2f 秒" % [State.CATALOG[weapon.key].name,base_attack,effects.final_attack,effects.attack_interval],summary.position+Vector2(18,y),13,color)
			y += 24
	_text("腰包：%s" % ("、".join(belt_names)+" · 0 行动力" if not belt_names.is_empty() else "未放入消耗品"),summary.position+Vector2(18,y),13,PopupSkin.MUTED)
	y += 24
	if state.economy.has_module("hidden_compartment"):
		_text("夹层保护：%s" % ("、".join(protected_names) if not protected_names.is_empty() else "等待装入物品"),summary.position+Vector2(18,y),13,PopupSkin.CYAN)
		y += 24
	if state.economy.has_module("roof_rack"):
		_text("车顶货架：36 → 48 格",summary.position+Vector2(18,y),13,PopupSkin.CYAN)

func _bag_build_summary_rect() -> Rect2:
	var weapon_count: int = state.items.filter(func(i): return i.zone == "bag" and State.CATALOG[i.key].category == "武器").size()
	return Rect2(bag_popup.end.x+12,bag_popup.position.y,350,maxf(154,(weapon_count+3)*25+62))
func _item_rect(item: Dictionary) -> Rect2:
	if item.zone == "counter":
		var counter_position := _ensure_counter_position(item)
		var counter_size := Vector2(state.dimensions(item))*CELL
		return Rect2(counter_position-counter_size*0.5,counter_size)
	var zone: Dictionary = ZONES[item.zone]
	return Rect2(zone.rect.position+Vector2(item.cell)*zone.cell,Vector2(state.dimensions(item))*zone.cell)
func _ensure_counter_position(item: Dictionary) -> Vector2:
	var counter_position: Vector2 = item.get("counter_position",Vector2(-1,-1))
	if counter_position.x < 0.0:
		counter_position = _counter_spawn_position(item)
		item.counter_position = counter_position
		item.counter_sleeping = false
	return counter_position
func _counter_aabb(item: Dictionary) -> Rect2:
	var center := _ensure_counter_position(item)
	if counter_world == null:
		return Rect2(center-Vector2(state.dimensions(item))*CELL*0.5,Vector2(state.dimensions(item))*CELL)
	var data: Dictionary = counter_world.geometry(item.key,ITEM_TEXTURES[item.key],Vector2(State.CATALOG[item.key].size)*CELL)
	var angle := float(item.get("counter_angle",0.0))+(PI/2.0 if item.rotated else 0.0)
	var bounds := Rect2()
	var initialized := false
	for polygon in data.polygons:
		for point: Vector2 in polygon:
			var transformed := center+point.rotated(angle)
			if not initialized:
				bounds = Rect2(transformed,Vector2.ZERO)
				initialized = true
			else:
				bounds = bounds.expand(transformed)
	return bounds
func _item_hit_rect(item: Dictionary) -> Rect2:
	return _counter_aabb(item) if item.zone == "counter" else _item_rect(item)
func _counter_items_sorted() -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for item in state.counter_items():
		sorted.append(item)
	sorted.sort_custom(func(a,b):
		return float(a.get("counter_position",Vector2.ZERO).y) > float(b.get("counter_position",Vector2.ZERO).y)
	)
	return sorted
func _draw_counter_items() -> void:
	for item in _counter_items_sorted():
		if item.id == drag_id:
			continue
		var item_rect := _item_rect(item)
		var aabb := _counter_aabb(item)
		# A soft contact shadow makes a stacked item read as resting on the
		# tabletop/support below it while keeping the artwork unobscured.
		draw_set_transform(Vector2(item.counter_position.x,aabb.end.y-2.0),0.0,Vector2(maxf(aabb.size.x*0.42,14.0),5.0))
		draw_circle(Vector2.ZERO,1.0,Color(0.03,0.05,0.05,0.25))
		draw_set_transform(Vector2.ZERO)
		_draw_item(item,item_rect,false)
func _counter_spawn_position(item: Dictionary) -> Vector2:
	var usable_width := COUNTER_RECT.size.x-96.0
	var x := COUNTER_RECT.position.x+48.0+fmod(float(item.id*97),usable_width)
	return Vector2(x,COUNTER_DROP_RECT.position.y+42.0)
var counter_world: Node2D

func _step_counter_physics(_delta: float) -> void:
	if counter_world == null:
		counter_world = preload("res://scripts/counter_physics.gd").new()
		add_child(counter_world)
		counter_world.setup(COUNTER_RECT)
	var items: Array[Dictionary] = state.counter_items()
	for item in items:
		_ensure_counter_position(item)
	counter_world.sync(items,drag_id,ITEM_TEXTURES,State.CATALOG,CELL)

func _place_on_counter(id: int, center: Vector2, rotated: bool) -> void:
	if not _customer_present():
		_notify("没有顾客时无法进行交易。")
		return
	var item := _find_item(id)
	if item.is_empty():
		return
	var half := Vector2(state.dimensions(item))*CELL*0.5
	center.x = clampf(center.x,COUNTER_RECT.position.x+half.x,COUNTER_RECT.end.x-half.x)
	var result: String = state.move_item_to_counter(id,center,rotated)
	if result != "":
		_notify(result)
	else:
		if counter_world != null:
			counter_world.remove_item(id)
		_clear_notification()
		_show_customer_reaction()
func _find_item(id: int) -> Dictionary:
	for item in state.items:
		if item.id == id:
			return item
	return {}
func _machine_ids_topmost() -> Array[int]:
	var ids: Array[int] = []
	for key in machine_popups.keys():
		ids.append(int(key))
	ids.reverse()
	return ids
func _item_at(p: Vector2) -> int:
	if customer_bag_open and customer_bag_rect.has_point(p):
		for item in state.items:
			if item.zone == "customer" and _item_hit_rect(item).has_point(p):
				return item.id
		return -1
	if open_bag and ZONES.has("bag") and ZONES["bag"].rect.has_point(p):
		for i in range(state.items.size()-1,-1,-1):
			if state.items[i].zone == "bag" and _item_hit_rect(state.items[i]).has_point(p):
				return state.items[i].id
		return -1
	for machine_id in _machine_ids_topmost():
		var popup: Rect2 = machine_popups[machine_id]
		for machine_zone in state.machine_zones(machine_id):
			if ZONES.has(machine_zone) and ZONES[machine_zone].rect.has_point(p):
				for i in range(state.items.size()-1,-1,-1):
					if state.items[i].zone == machine_zone and _item_hit_rect(state.items[i]).has_point(p):
						return state.items[i].id
				return -1
		if popup.has_point(p):
			return -1
	if open_bag and bag_popup.has_point(p):
		return -1
	for i in range(state.items.size()-1,-1,-1):
		if (state.items[i].zone == "counter" or ZONES.has(state.items[i].zone)) and _item_hit_rect(state.items[i]).has_point(p):
			return state.items[i].id
	return -1
func _zone_at(p: Vector2) -> String:
	if customer_bag_open and customer_bag_rect.has_point(p):
		return "customer" if ZONES.customer.rect.has_point(p) else ""
	if open_bag and ZONES.has("bag") and ZONES["bag"].rect.has_point(p):
		return "bag"
	for machine_id in _machine_ids_topmost():
		var popup: Rect2 = machine_popups[machine_id]
		for machine_zone in state.machine_zones(machine_id):
			if ZONES.has(machine_zone) and ZONES[machine_zone].rect.has_point(p):
				return machine_zone
		if popup.has_point(p):
			return ""
	if open_bag and bag_popup.has_point(p):
		return ""
	if COUNTER_DROP_RECT.has_point(p):
		return "counter"
	for zone in ZONES:
		if ZONES[zone].rect.has_point(p):
			return zone
	return ""
func _cell_at(p: Vector2, zone: String) -> Vector2i:
	return Vector2i(((p-ZONES[zone].rect.position)/ZONES[zone].cell).round())
func _finish_drag(point: Vector2) -> void:
	if drag_id < 0:
		return
	var id := drag_id
	var zone := _zone_at(point)
	if zone == "counter":
		var item := _find_item(id)
		var item_size := Vector2(state.dimensions(item))*CELL
		_place_on_counter(id,point-drag_offset+item_size*0.5,drag_rotated)
	elif zone != "":
		var error: String = state.move_item(id,zone,_cell_at(point-drag_offset,zone),drag_rotated)
		if error != "":
			_notify(error)
		else:
			_clear_notification()
			_show_customer_reaction()
	drag_id = -1
	_sync()
func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(exploration):
		return
	if is_instance_valid(market_board) or is_instance_valid(module_shop):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_market_board()
			_close_module_shop()
		return
	if modal != null:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_modal()
		return
	if recorder_panel != null and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_recorder()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and drag_id >= 0:
			drag_rotated = not drag_rotated
			drag_offset = Vector2(16,16)
		if event.keycode == KEY_ESCAPE:
			drag_id = -1
			if open_bag:
				_close_bag()
			elif not machine_popups.is_empty():
				_close_machine(_machine_ids_topmost()[0])
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			drag_id = -1
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			var id := _item_at(get_local_mouse_position())
			if id < 0:
				return
			if _find_item(id).key == "small_bag" and event.double_click:
				_open_bag()
				return
			if event.double_click:
				drag_id = -1
				_quick_move(id)
				return
			press_position = get_local_mouse_position()
			drag_id = id
			drag_rotated = _find_item(id).rotated
			drag_offset = get_local_mouse_position()-_item_rect(_find_item(id)).position
		elif drag_id >= 0:
			_finish_drag(get_local_mouse_position())
func _quick_move(id: int) -> void:
	var item := _find_item(id)
	if item.is_empty():
		return
	if item.key == "small_bag":
		_open_bag()
		return
	if State.MACHINES.has(item.key):
		_open_machine(id)
		return
	var target := "counter" if item.zone != "counter" else ("stock" if item.owner == "player" else "customer")
	if target == "counter":
		_place_on_counter(id,_counter_spawn_position(item),item.rotated)
		_sync()
		return
	var at: Vector2i = state.free_cell(item,target)
	if at.x < 0:
		_notify("空间不足。可以按 R 旋转物品再放置。")
		return
	var result: String = state.move_item(id,target,at,item.rotated)
	if result != "":
		_notify(result)
	else:
		_clear_notification()
		_show_customer_reaction()
	_sync()
func _sync() -> void:
	trade_visible = not state.counter_items().is_empty()
	if _customer_present():
		trade_panel.refresh(state)
	else:
		trade_panel.keep_open = false
		trade_panel.hide()
	if trade_panel_dismissed:
		trade_panel.hide()
	queue_redraw()
func _open_trade_panel() -> void:
	if trade_panel == null:
		return
	if not _customer_present():
		_notify("没有顾客时无法进行交易。")
		return
	if trade_panel.visible:
		_close_trade_panel()
		return
	trade_panel_dismissed = false
	trade_panel.keep_open = true
	trade_panel.refresh(state)
	queue_redraw()
	get_viewport().set_input_as_handled()
func _close_trade_panel() -> void:
	if trade_panel == null:
		return
	trade_panel_dismissed = true
	trade_panel.keep_open = false
	trade_panel.hide()
	queue_redraw()
func _customer_present() -> bool:
	return business_active and not shutter_closed and not shutter_animating and $ArtLayers/Window/Customer.visible and $ArtLayers/Window/Customer.texture != null
func _bell_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if shutter_closed or shutter_animating:
			_notify("卷帘门关闭时无法呼叫顾客。")
		elif next_button.disabled:
			_notify("正在安排下一位顾客，请稍候。")
		elif not _customer_present():
			call_deferred("_next_trade")
		elif not state.counter_items().is_empty():
			_notify("先为柜台上的物品腾出存放空间。")
		else:
			bell_hold_active = true
			bell_hold_time = 0.0
			bell_hold_completed = false
			_clear_notification()
		get_viewport().set_input_as_handled()
	else:
		if bell_hold_active:
			_cancel_bell_hold()
		get_viewport().set_input_as_handled()
func _cancel_bell_hold() -> void:
	if not bell_hold_active:
		return
	bell_hold_active = false
	bell_hold_time = 0.0
	bell_hold_completed = false
	_notify("需要长按呼叫下一位顾客。")
	queue_redraw()
func _complete_bell_hold() -> void:
	if not bell_hold_active:
		return
	bell_hold_active = false
	bell_hold_completed = true
	bell_hold_time = BELL_HOLD_DURATION
	call_deferred("_next_trade")
	queue_redraw()
func _apply_customer_profile() -> void:
	var profile: Dictionary = CUSTOMERS[customer_index]
	trade_panel.keep_open = false
	trade_panel_dismissed = false
	state.configure_customer(
		str(profile.get("buy_category","")),
		str(profile.get("sell_key","")),
		Array(profile.get("goods",[])),
		int(profile.get("funds",150)),
		str(profile.name)
	)
	_close_customer_bag()
	customer_bag_button.visible = state.customer_sell_key != ""
	if customer_bag_button.visible:
		_open_customer_bag()
func _notify(value: String) -> void:
	if value != "" and not _is_interest_reaction(value):
		toast = value
		toast_time = 3.8
func _clear_notification() -> void:
	toast = ""
	toast_time = 0.0
func _show_customer_reaction() -> void:
	if _customer_present() and state.last_reaction != "":
		_start_conversation([state.last_reaction])
func _is_interest_reaction(value: String) -> bool:
	return value in [
		"顾客眼睛一亮：眼下正缺这个。",
		"顾客眼睛一亮：我很喜欢这个。",
		"顾客点头：这个正合我意。",
        "顾客有点兴趣：这个可以看看。"
	]
func _start_customer_conversation() -> void:
	if not _customer_present():
		return
	var profile: Dictionary = CUSTOMERS[customer_index]
	var lines: Array = Array(profile.conversation).duplicate()
	if state.economy.relationship(str(profile.name)) > 0:
		lines[-1] = "%s\n行情：%s" % [lines[-1],state.economy.intelligence(state.day,str(profile.name)).replace("\n","；")]
	_start_conversation(lines)
func _start_conversation(lines: Array) -> void:
	dialogue_lines.clear()
	for line in lines:
		var text_line := str(line).strip_edges()
		if text_line != "":
			dialogue_lines.append(text_line)
	dialogue_line_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	dialogue_pause = 0.0
	dialogue_line_recorded = false
	dialogue = ""
	dialogue_active = not dialogue_lines.is_empty()
	dialogue_playing = dialogue_active
	_update_dialogue_controls()
	queue_redraw()
func _advance_dialogue(delta: float) -> void:
	if not dialogue_active or not dialogue_playing:
		return
	if dialogue_line_index >= dialogue_lines.size():
		_finish_dialogue()
		return
	if dialogue_pause > 0.0:
		dialogue_pause -= delta
		if dialogue_pause <= 0.0:
			if dialogue_line_index < dialogue_lines.size()-1:
				_set_dialogue_line(dialogue_line_index+1,false)
			else:
				_finish_dialogue()
		return
	var line := dialogue_lines[dialogue_line_index]
	if dialogue_char_index >= line.length():
		if not dialogue_line_recorded:
			_record_dialogue_line(line)
			dialogue_line_recorded = true
		dialogue_pause = DIALOGUE_END_GAP if dialogue_line_index == dialogue_lines.size()-1 else DIALOGUE_LINE_GAP
		_update_dialogue_controls()
		return
	dialogue_timer += delta
	var count := int(dialogue_timer / DIALOGUE_CHAR_INTERVAL)
	if count <= 0:
		return
	dialogue_timer -= float(count) * DIALOGUE_CHAR_INTERVAL
	dialogue_char_index = mini(dialogue_char_index + count,line.length())
	dialogue = line.substr(0,dialogue_char_index)
	_update_dialogue_controls()
func _finish_dialogue() -> void:
	if dialogue_lines.is_empty():
		_clear_dialogue()
		return
	if not dialogue_line_recorded:
		_record_dialogue_line(dialogue_lines[dialogue_line_index])
		dialogue_line_recorded = true
	dialogue_active = true
	dialogue_playing = false
	dialogue_line_index = dialogue_lines.size()-1
	dialogue_char_index = dialogue_lines[dialogue_line_index].length()
	dialogue = dialogue_lines[dialogue_line_index]
	dialogue_line_recorded = true
	dialogue_timer = 0.0
	dialogue_pause = 0.0
	_update_dialogue_controls()
	queue_redraw()
func _clear_dialogue() -> void:
	dialogue_active = false
	dialogue_playing = false
	dialogue_lines.clear()
	dialogue_line_index = 0
	dialogue_char_index = 0
	dialogue_timer = 0.0
	dialogue_pause = 0.0
	dialogue_line_recorded = false
	dialogue = ""
	_update_dialogue_controls()
	queue_redraw()
func _set_dialogue_line(index: int, reveal: bool) -> void:
	if dialogue_lines.is_empty():
		return
	dialogue_line_index = clampi(index,0,dialogue_lines.size()-1)
	dialogue_char_index = dialogue_lines[dialogue_line_index].length() if reveal else 0
	dialogue_timer = 0.0
	dialogue_pause = 0.0
	dialogue_line_recorded = false
	dialogue = dialogue_lines[dialogue_line_index].substr(0,dialogue_char_index)
	_update_dialogue_controls()
	queue_redraw()
func _dialogue_previous() -> void:
	if not dialogue_active or dialogue_lines.is_empty() or dialogue_line_index <= 0:
		return
	dialogue_playing = false
	_set_dialogue_line(dialogue_line_index-1,true)
func _dialogue_next() -> void:
	if not dialogue_active or dialogue_lines.is_empty():
		return
	if dialogue_playing:
		var current_line := dialogue_lines[dialogue_line_index]
		if dialogue_char_index < current_line.length():
			dialogue_char_index = current_line.length()
			dialogue = current_line
			if not dialogue_line_recorded:
				_record_dialogue_line(current_line)
				dialogue_line_recorded = true
			dialogue_pause = 0.0
			_update_dialogue_controls()
			queue_redraw()
			return
		if dialogue_line_index < dialogue_lines.size()-1:
			_set_dialogue_line(dialogue_line_index+1,false)
		else:
			_finish_dialogue()
		return
	if dialogue_line_index < dialogue_lines.size()-1:
		_set_dialogue_line(dialogue_line_index+1,true)
func _record_dialogue_line(line: String) -> void:
	dialogue_history.append({
		"speaker": CUSTOMERS[customer_index].name,
		"role": CUSTOMERS[customer_index].role,
		"text": line
	})
	if dialogue_history.size() > 80:
		dialogue_history.pop_front()
	if recorder_panel != null and is_instance_valid(recorder_panel):
		_refresh_recorder()
func _dialogue_display_text() -> String:
	if dialogue == "":
		return "…"
	var wrapped := _wrap_dialogue(dialogue,DIALOGUE_BODY_LIMIT)
	var result := ""
	for line in wrapped:
		if result != "":
			result += "\n"
		result += line
	return result
func _wrap_dialogue(value: String, limit: int = 18) -> Array[String]:
	var result: Array[String] = []
	for source_line in value.split("\n"):
		var remaining := source_line
		while remaining.length() > limit:
			result.append(remaining.substr(0,limit))
			remaining = remaining.substr(limit)
		result.append(remaining)
	return result
func _haggle() -> void:
	if not _customer_present():
		_notify("没有顾客时无法议价。")
		return
	_start_conversation([state.negotiate(int(price.value))])
	_sync()
func _settle() -> void:
	if not _customer_present():
		_notify("没有顾客时无法结算交易。")
		return
	var had_buying_items := not state.buying_items().is_empty()
	var had_selling_items := not state.selling_items().is_empty()
	var result: String = state.settle()
	if result.begins_with("交易完成"):
		_clear_notification()
		var can_continue: bool = (had_buying_items and state.gold > 0) or (had_selling_items and state.customer_funds > 0)
		trade_panel.keep_open = can_continue
		_start_conversation(["谢谢你的报价，这批货物我收下了。", "还有没有更多货？"])
	else:
		_notify(result)
		_start_conversation([result])
	_sync()
func _cancel_trade() -> void:
	state.cancel_trade()
	_sync()
	if state.counter_items().is_empty():
		_clear_notification()
	else:
		_notify("部分货架已满，请先整理空间再撤回。")
func _next_trade() -> void:
	bell_hold_completed = false
	if not business_active or shutter_closed or shutter_animating:
		_notify("卷帘门关闭时无法呼叫顾客。")
		return
	if next_button.disabled:
		return
	state.cancel_trade()
	if not state.counter_items().is_empty():
		_notify("先为柜台上的物品腾出存放空间。")
		return
	next_button.disabled = true
	drag_id = -1
	trade_panel.keep_open = false
	_clear_dialogue()
	$ArtLayers.set_customer(null)
	state.items = state.items.filter(func(i): return i.owner != "customer")
	_sync()
	await get_tree().create_timer(0.45).timeout
	if not business_active or shutter_closed or shutter_animating:
		next_button.disabled = false
		return
	customer_index = (customer_index+1)%CUSTOMERS.size()
	var profile: Dictionary = CUSTOMERS[customer_index]
	$ArtLayers.set_customer(load(profile.portrait))
	_apply_customer_profile()
	_start_customer_conversation()
	next_button.disabled = false
	_sync()
func _show_help() -> void:
	_open_modal("商车经营指南","柜台 · 双击或拖放商品开始买卖\n交易 · 输入报价还价，或接受报价\n背包 · 双击打开；R 旋转，右键 / Esc 取消拖放\n设备 · 双击放入材料，休息后收取产物\n手机 · 查看历史对话\n呼叫铃 · 点击呼叫顾客；长按送走当前顾客\n卷帘门 · 关闭后可休息、探索或旅行\n行情 / 改装 · 查看物价、事件与商车模块", "开始经营",_close_modal)

func _open_recorder() -> void:
	if recorder_panel != null and is_instance_valid(recorder_panel):
		_close_recorder()
		return
	recorder_panel = Panel.new()
	recorder_panel.position = Vector2(1180,292)
	recorder_panel.size = Vector2(320,540)
	recorder_panel.z_index = 50
	recorder_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	PopupSkin.window(recorder_panel)
	add_child(recorder_panel)
	var header := Panel.new()
	header.size = Vector2(320,48)
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	recorder_panel.add_child(header)
	var title := Label.new()
	title.text = "历史对话"
	title.position = Vector2(16,10)
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
	title.add_theme_font_override("font",PopupSkin.font(true))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title)
	recorder_close = Button.new()
	recorder_close.text = "×"
	recorder_close.position = Vector2(276,8)
	PopupSkin.close_button(recorder_close)
	recorder_close.pressed.connect(_close_recorder)
	header.add_child(recorder_close)
	header.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			recorder_dragging = event.pressed
			recorder_drag_offset = get_global_mouse_position()-recorder_panel.global_position
			header.accept_event()
		elif event is InputEventMouseMotion and recorder_dragging:
			recorder_panel.position = (get_global_mouse_position()-recorder_drag_offset).clamp(Vector2(8,8),Vector2(1600,868)-recorder_panel.size)
			header.accept_event()
	)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16,64)
	scroll.size = Vector2(288,460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	recorder_panel.add_child(scroll)
	recorder_rows = VBoxContainer.new()
	recorder_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recorder_rows.add_theme_constant_override("separation",8)
	scroll.add_child(recorder_rows)
	_refresh_recorder()
func _close_recorder() -> void:
	recorder_dragging = false
	if recorder_panel != null:
		recorder_panel.queue_free()
	recorder_panel = null
	recorder_rows = null
func _refresh_recorder() -> void:
	if recorder_rows == null or not is_instance_valid(recorder_rows):
		return
	for child in recorder_rows.get_children():
		recorder_rows.remove_child(child)
		child.queue_free()
	if dialogue_history.is_empty():
		var empty := Label.new()
		empty.text = "暂无记录"
		empty.add_theme_font_size_override("font_size",14)
		empty.add_theme_color_override("font_color",MUTED)
		recorder_rows.add_child(empty)
		return
	for entry in dialogue_history:
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 54
		var skin := PopupSkin.box(PopupSkin.PANEL_ALT if recorder_rows.get_child_count() % 2 == 0 else PopupSkin.PANEL,PopupSkin.DIVIDER,0)
		row.add_theme_stylebox_override("panel",skin)
		recorder_rows.add_child(row)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",1)
		row.add_child(column)
		var speaker := Label.new()
		speaker.text = "%s · %s" % [entry.speaker,entry.role]
		speaker.add_theme_font_size_override("font_size",14)
		speaker.add_theme_color_override("font_color",PopupSkin.MUTED)
		column.add_child(speaker)
		var line := Label.new()
		line.text = entry.text
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size",16)
		line.add_theme_color_override("font_color",INK)
		column.add_child(line)
func _open_modal(title_value: String, body: String, action_text: String, action: Callable, cancel_text := "") -> void:
	if modal != null:
		return
	drag_id = -1
	modal = Panel.new()
	modal.z_index = 100
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_theme_stylebox_override("panel",PopupSkin.box(PopupSkin.SHADE,Color.TRANSPARENT))
	add_child(modal)
	var line_count := 0
	for body_line in body.split("\n"):
		line_count += maxi(1,ceili(font.get_string_size(body_line,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x/550.0))
	var height := clampi(144+line_count*28,224,492)
	var card := Panel.new()
	card.position = Vector2(490,(900-height)/2.0)
	card.size = Vector2(620,height)
	PopupSkin.window(card)
	modal.add_child(card)
	var title_label := Label.new()
	title_label.text = title_value
	title_label.position = Vector2(24,8)
	title_label.add_theme_font_size_override("font_size",24)
	title_label.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
	title_label.add_theme_font_override("font",PopupSkin.font(true))
	card.add_child(title_label)
	var label := Label.new()
	label.text = body
	label.position = Vector2(35,72)
	label.size = Vector2(550,height-144)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",INK)
	card.add_child(label)
	var action_y := card.position.y+height-64
	var b := _button(action_text,Rect2(525,action_y,550,40),action,true)
	remove_child(b)
	if cancel_text != "":
		b.position = Vector2(525,action_y)
		b.size = Vector2(265,40)
	modal.add_child(b)
	if cancel_text != "":
		var cancel_button := _button(cancel_text,Rect2(810,action_y,265,40),_close_modal)
		remove_child(cancel_button)
		modal.add_child(cancel_button)
func _close_modal() -> void:
	if modal != null:
		modal.queue_free()
		modal = null
func _end_day() -> void:
	if not shutter_closed:
		_notify("请先关闭卷帘门后再与卧铺交互。")
		return
	if next_day_ready and not business_active:
		_notify("请先打开卷帘门开始今日营业。")
		return
	var travel_line := "\n商路今日开放，可在行情板启程。" if state.can_travel() else ""
	_open_modal("今日营业结束", "第 %d 天 · %s%s\n\n完成交易     %d 笔\n经营收支     %+d G\n持有金币     %d G\n\n可休息进入下一天，或从车门外出探索。" % [state.day,state.economy.city_name(),travel_line,state.completed,state.earnings,state.gold],"休息 · 开始下一天",_begin_day)

func _open_market_board() -> void:
	if is_instance_valid(market_board):
		_close_market_board()
		return
	_close_module_shop()
	market_board = preload("res://scripts/market_board.gd").new()
	market_board.setup(state,ITEM_TEXTURES)
	market_board.close_requested.connect(_close_market_board)
	market_board.travel_requested.connect(_travel_city)
	add_child(market_board)

func _close_market_board() -> void:
	if is_instance_valid(market_board):
		market_board.queue_free()
	market_board = null

func _travel_city() -> void:
	if not shutter_closed:
		_close_market_board()
		_notify("请先结束营业并关闭卷帘门。")
		return
	var result := state.travel_to_next_city()
	if result.begins_with("已抵达"):
		customer_index = 0
		_prepare_next_day()
	_close_market_board()
	_sync()
	_notify(result)

func _open_module_shop() -> void:
	if is_instance_valid(module_shop):
		_close_module_shop()
		return
	_close_market_board()
	module_shop = preload("res://scripts/module_shop.gd").new()
	module_shop.setup(state)
	module_shop.close_requested.connect(_close_module_shop)
	module_shop.purchase_requested.connect(_buy_module)
	add_child(module_shop)

func _close_module_shop() -> void:
	if is_instance_valid(module_shop):
		module_shop.queue_free()
	module_shop = null

func _full_overlay_open() -> bool:
	return modal != null or is_instance_valid(market_board) or is_instance_valid(module_shop)

func _buy_module(module_id: String) -> void:
	var result := state.install_module(module_id)
	if open_bag:
		_sync_bag_window()
	if is_instance_valid(module_shop):
		module_shop.refresh(result)
	_notify(result)
func _smoke_ui() -> void:
	await get_tree().process_frame
	assert(mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(door_art != null and bed_art != null and table_art != null)
	assert(door_art.texture_click_mask != null and bed_art.texture_click_mask != null)
	assert(table_art.z_index > bed_art.z_index and bed_art.z_index > door_art.z_index)
	assert(State.SIZES.customer == Vector2i(24,4))
	assert(State.SIZES.counter == Vector2i(43,4))
	assert(State.SIZES.stock == Vector2i(30,12))
	assert(recorder_button != null)
	assert(dialogue_active)
	assert(state.customer_buy_category == "材料")
	assert(not ZONES.has("display"))
	assert(not customer_bag_open and not ZONES.has("customer"))
	assert(state.items.all(func(i): return i.zone != "display"))
	var unwanted_item: Dictionary = state.items.filter(func(i): return i.owner == "player" and i.key == "sword")[0]
	assert(state.move_item(unwanted_item.id,"counter",Vector2i(0,0),true) == "")
	assert(unwanted_item.trade_rejected and state.last_reaction == "我没有意愿买这个。")
	state.cancel_trade()
	var item: Dictionary = state.items.filter(func(i): return i.owner == "player" and i.key == "herb")[0]
	_quick_move(item.id)
	await get_tree().process_frame
	assert(toast_time == 0.0)
	assert(dialogue_lines.size() == 1 and dialogue_lines[0] == "顾客有点兴趣：这个可以看看。")
	assert(accept.visible)
	assert(trade_panel.intent.text.contains("材料"))
	_haggle()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/交易页面.png")
	_settle()
	assert(toast_time == 0.0)
	assert(trade_panel.visible)
	assert(dialogue_lines.size() == 2 and dialogue_lines[1] == "还有没有更多货？")
	assert(state.counter_items().is_empty())
	assert(item.owner == "customer" and item.zone == "customer")
	state.configure_customer("材料","sword",["sword"])
	var mixed_buy: Dictionary = state.items.filter(func(i): return i.owner == "customer")[0]
	assert(state.move_item(mixed_buy.id,"counter",state.free_cell(mixed_buy,"counter"),mixed_buy.rotated) == "")
	var mixed_sell: Dictionary = state.items.filter(func(i): return i.owner == "player" and i.key == "herb")[0]
	assert(state.move_item(mixed_sell.id,"counter",state.free_cell(mixed_sell,"counter"),false) == "")
	_sync()
	assert(trade_panel.buy_tab.visible and trade_panel.sell_tab.visible)
	_settle()
	assert(mixed_buy.owner == "player" and mixed_buy.zone == "counter" and mixed_buy.settled)
	assert(state.move_item(mixed_buy.id,"stock",state.free_cell(mixed_buy,"stock"),mixed_buy.rotated) == "")
	assert(state.counter_items().is_empty())
	_show_help()
	await get_tree().process_frame
	assert(modal != null)
	_close_modal()
	_door()
	assert(modal == null and toast.contains("车门"))
	_end_day()
	assert(modal == null and toast.contains("卧铺"))
	_close_shutter()
	await get_tree().create_timer(0.9).timeout
	assert(shutter_closed and shutter_clip.visible and shutter_clip.size.y == SHUTTER_SIZE.y)
	_door()
	assert(modal != null)
	_close_modal()
	_end_day()
	assert(modal != null)
	_close_modal()
	_prepare_next_day()
	_open_shutter_for_business()
	await get_tree().create_timer(0.9).timeout
	# Verify that the customer layer can be removed without changing the city.
	var town_texture: Texture2D = $ArtLayers/Window/Exterior.texture
	$ArtLayers.set_customer(null)
	assert(not $ArtLayers/Window/Customer.visible)
	assert($ArtLayers/Window/Exterior.texture == town_texture)
	$ArtLayers.set_customer(load("res://assets/approved-layout/customer-sylvie.png"))
	state = State.new()
	customer_index = 0
	_apply_customer_profile()
	dialogue_history.clear()
	_start_conversation(["开场测试：欢迎来到风栖镇。","需求测试：请把合适的货物放上柜台。"])
	for n in range(10):
		_advance_dialogue(10.0)
	assert(dialogue_active and not dialogue_playing and dialogue == "需求测试：请把合适的货物放上柜台。")
	assert(dialogue_history.size() == 2)
	_open_recorder()
	assert(recorder_panel != null and recorder_rows.get_child_count() == 2)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/历史对话.png")
	_close_recorder()
	_start_customer_conversation()
	toast_time = 0.0
	_sync()
	var backpack: Dictionary = state.items.filter(func(i): return i.key == "small_bag")[0]
	_open_bag()
	assert(open_bag and ZONES.has("bag"))
	assert(bag_popup.size == Vector2(200,250))
	assert(ZONES["bag"].rect.size == Vector2(state.zone_size("bag")) * BAG_CELL)
	assert(_zone_at(ZONES.bag.rect.get_center()) == "bag")
	var backpack_item: Dictionary = state.items.filter(func(i): return i.key == "berry" and i.owner == "player")[0]
	assert(state.move_item(backpack_item.id,"bag",Vector2i.ZERO,false) == "")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/背包弹窗.png")
	_close_bag()
	assert(not open_bag and not ZONES.has("bag"))
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/经营页面.png")
	var device: Dictionary = state.items.filter(func(i): return i.key == "pot")[0]
	var ingredient: Dictionary = state.items.filter(func(i): return i.key == "meat" and i.owner == "player")[0]
	_open_machine(device.id)
	assert(ZONES.has(state.machine_zone(device.id)))
	assert(state.move_item(ingredient.id,state.machine_zone(device.id),Vector2i(1,1),false) == "")
	assert(ingredient.key == "meat")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/设备加工.png")
	state.advance_day()
	assert(ingredient.key == "steak")
	_close_machine()
	assert(not ZONES.has(state.machine_zone(device.id)))
	# Customer replacement must return unpaid items without changing gold.
	var before_gold: int = state.gold
	for n in range(4):
		var pending_items: Array[Dictionary] = state.items.filter(func(i): return i.owner == "customer")
		if not pending_items.is_empty():
			_quick_move(pending_items[0].id)
		await _next_trade()
		assert(state.counter_items().is_empty())
		assert(state.gold == before_gold)
		assert(customer_index == (n+1)%4)
		assert(state.items.filter(func(i): return i.owner == "customer").size() == CUSTOMERS[customer_index].goods.size())
		assert(customer_bag_open == (state.customer_sell_key != ""))
		if customer_bag_open:
			var offered: Dictionary = state.items.filter(func(i): return i.owner == "customer")[0]
			var hit: Vector2 = _item_rect(offered).get_center()
			assert(_zone_at(hit) == "customer" and _item_at(hit) == offered.id)
			_close_customer_bag()
			assert(not ZONES.has("customer") and _item_at(hit) != offered.id)
			_open_customer_bag()
			_quick_move(offered.id)
			assert(offered.zone == "counter")
			_cancel_trade()
			assert(offered.zone == "customer")
			assert(toast_time == 0.0)
		await get_tree().create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/customer-%d.png" % customer_index)
	for n in range(10):
		state.add_item("herb","stock","player")
	var sale_items: Array = state.items.filter(func(i): return i.owner == "player" and not State.MACHINES.has(i.key) and i.zone == "stock" and State.CATALOG[i.key].category == state.customer_buy_category)
	for n in range(mini(12,sale_items.size())):
		_quick_move(sale_items[n].id)
	assert(trade_panel.rows.get_child_count() == state.selling_items().size())
	assert(trade_panel.rows.get_child_count() > 8)
	trade_panel.position = Vector2(1180,354)
	trade_panel.z_index = 40
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/testing/previews/清单与轮廓.png")
	print("UI_SMOKE_OK: walnut scene, customer backpack visibility/hit testing/return, four customers, trade and inventory")
	get_tree().quit()
func _hotspot(title_value: String, rect: Rect2, action: Callable) -> Button:
	var b := Button.new()
	b.name = title_value
	b.position = rect.position
	b.size = rect.size
	b.flat = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for mode in ["normal","pressed","focus"]:
		b.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover",_style(Color("ddc6890c"),Color("d0ad7080"),8))
	b.pressed.connect(action)
	add_child(b)
	return b
func _toggle_shutter() -> void:
	if shutter_animating:
		return
	if shutter_closed:
		if next_day_ready and not business_active:
			_open_shutter_for_business()
		else:
			_notify("今日营业已经结束，请点击卧铺进入下一天。")
		return
	_request_close_shutter()
func _request_close_shutter() -> void:
	if _full_overlay_open():
		return
	_open_modal("关闭今日营业？", "关闭卷帘门将结束今日营业，是否关闭？", "关闭并结束营业", _close_shutter, "继续营业")
func _close_shutter() -> void:
	if shutter_closed:
		_notify("卷帘门已经关闭。")
		return
	if shutter_animating:
		return
	_close_modal()
	shutter_animating = true
	bell_hold_active = false
	bell_hold_time = 0.0
	drag_id = -1
	business_active = false
	next_day_ready = false
	state.cancel_trade()
	_clear_dialogue()
	trade_panel.keep_open = false
	# A closing shop has no customer as soon as the shutter action begins.
	# Clear the visual/customer inventory immediately so pending async customer
	# changes cannot reopen a trade during the shutter animation.
	$ArtLayers.set_customer(null)
	state.items = state.items.filter(func(i): return i.owner != "customer")
	_close_customer_bag()
	customer_bag_button.visible = false
	shutter_clip.visible = true
	shutter_clip.size = Vector2(SHUTTER_SIZE.x,0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shutter_clip,"size:y",SHUTTER_SIZE.y,0.75)
	tween.tween_callback(_finish_shutter_close)
	_sync()
func _finish_shutter_close() -> void:
	shutter_clip.size = SHUTTER_SIZE
	shutter_closed = true
	shutter_animating = false
	business_active = false
	next_day_ready = false
	$ArtLayers.set_customer(null)
	state.items = state.items.filter(func(i): return i.owner != "customer")
	_close_customer_bag()
	customer_bag_button.visible = false
	_sync()
	_notify("卷帘门已关闭，车门与卧铺现在可以交互。")
func _prepare_next_day() -> void:
	shutter_closed = true
	shutter_animating = false
	business_active = false
	next_day_ready = true
	bell_hold_active = false
	bell_hold_time = 0.0
	shutter_clip.visible = true
	shutter_clip.size = SHUTTER_SIZE
	$ArtLayers.set_customer(null)
	state.items = state.items.filter(func(i): return i.owner != "customer")
	_close_customer_bag()
	customer_bag_button.visible = false
	_sync()
func _open_shutter_for_business() -> void:
	if not shutter_closed or not next_day_ready or shutter_animating:
		return
	shutter_animating = true
	bell_hold_active = false
	bell_hold_time = 0.0
	shutter_clip.visible = true
	shutter_clip.size = SHUTTER_SIZE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shutter_clip,"size:y",0.0,0.75)
	tween.tween_callback(_finish_shutter_open)
	_sync()
func _finish_shutter_open() -> void:
	shutter_clip.size = Vector2(SHUTTER_SIZE.x,0.0)
	shutter_clip.visible = false
	shutter_closed = false
	shutter_animating = false
	next_day_ready = false
	business_active = true
	customer_index = 0
	$ArtLayers.set_customer(load(CUSTOMERS[0].portrait))
	_apply_customer_profile()
	_start_customer_conversation()
	_sync()
	_notify("第 %d 天营业开始，欢迎第一位客人。" % state.day)
func _door() -> void:
	if not shutter_closed:
		_notify("请先关闭卷帘门后再与车门交互。")
		return
	_open_modal("商车门口 · 野外探索", "月下森林\n\n可以持续探索，直到生命归零或主动返回商车。", "前往野外",_start_exploration)
func _start_exploration() -> void:
	_close_modal()
	_close_bag()
	_close_machine()
	drag_id = -1
	state.cancel_trade()
	exploration = load("res://scripts/exploration.gd").new()
	exploration.z_index = 200
	exploration.state = state
	exploration.finished.connect(func():
		var fled: bool = exploration.combat.last_fled
		var lost_item_name: String = exploration.combat.last_lost_item_name
		exploration.queue_free()
		exploration = null
		_sync()
		if fled:
			var result := "你已成功逃回商车，但遗落了「%s」物品。" % lost_item_name if lost_item_name != "" else "你已成功逃回商车，没有遗落物品。"
			_open_modal("逃跑成功",result,"知道了",_close_modal)
	)
	add_child(exploration)
func _valid_drop(item: Dictionary, zone: String, at: Vector2i) -> bool:
	if state.placement_error(item,zone) != "":
		return false
	if item.owner == "customer" and zone not in ["customer","counter"]:
		return false
	if item.owner == "player" and zone == "customer":
		return false
	if zone == "counter":
		return _customer_present()
	return state.fits(item,zone,at,item.id)
func _input(event: InputEvent) -> void:
	if _full_overlay_open():
		return
	if is_instance_valid(exploration):
		return
	if modal == null and _customer_bag_input(event):
		return
	if open_bag:
		var local_mouse := get_local_mouse_position()
		if _bag_build_summary_rect().has_point(local_mouse):
			get_viewport().set_input_as_handled()
			return
		var title_rect := Rect2(bag_popup.position, Vector2(bag_popup.size.x, 48))
		var close_rect := Rect2(bag_popup.position + bag_close.position, bag_close.size)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and title_rect.has_point(local_mouse) and not close_rect.has_point(local_mouse):
				bag_dragging = true
				bag_drag_offset = local_mouse - bag_popup.position
				get_viewport().set_input_as_handled()
				return
			if not event.pressed and bag_dragging:
				bag_dragging = false
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseMotion and bag_dragging:
			bag_popup.position = (local_mouse - bag_drag_offset).clamp(
				Vector2(8, 8),
				Vector2(1600, 900) - bag_popup.size - Vector2(8, 8)
			)
			_sync_bag_window()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
	if not machine_popups.is_empty() and _machine_window_input(event):
		return
	# Capture release before Control buttons consume it. A release in the
	# continuous counter field becomes a physical drop; other zones retain their
	# existing grid placement behavior.
	if drag_id >= 0 and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if trade_panel.visible and trade_panel.get_global_rect().has_point(get_global_mouse_position()):
			drag_id = -1
			get_viewport().set_input_as_handled()
			return
		if State.MACHINES.has(_find_item(drag_id).key) and get_local_mouse_position().distance_to(press_position) < 5:
			_open_machine(drag_id)
			drag_id = -1
			get_viewport().set_input_as_handled()
			return
		_finish_drag(get_local_mouse_position())
		_sync()
		get_viewport().set_input_as_handled()
func _machine_default_position(id: int) -> Vector2:
	var machine := _find_item(id)
	match str(machine.get("key", "")):
		"furnace":
			return Vector2(280,492)
		"alembic":
			return Vector2(816,470)
		"pot":
			return Vector2(24,600)
	return Vector2(24,600)
func _open_machine(id: int) -> void:
	var machine := _find_item(id)
	if machine.is_empty() or not State.MACHINES.has(machine.key):
		return
	if machine_popups.has(id):
		open_machine = id
		machine_window_nodes[id].show()
		_sync_machine_window(id)
		queue_redraw()
		return
	var popup := Rect2(_machine_default_position(id),Vector2(232,226))
	machine_popups[id] = popup
	var host := _popup_host(popup)
	var close := _popup_close(host,_close_machine.bind(id))
	if machine.key in ["furnace","alembic"]:
		var recipes := Button.new()
		recipes.text = "配方"
		recipes.position = Vector2(370 if machine.key == "furnace" else 234,8)
		recipes.size = Vector2(96,32)
		PopupSkin.button(recipes)
		recipes.add_theme_font_size_override("font_size",16)
		recipes.pressed.connect(_open_recipe_drawings.bind(machine.key))
		host.add_child(recipes)
		recipe_buttons[id] = recipes
	machine_window_nodes[id] = host
	machine_closes[id] = close
	open_machine = id
	_sync_machine_window(id)
	host.show()
	queue_redraw()
func _open_bag() -> void:
	open_bag = true
	_sync_bag_window()
	bag_window_node.show()
	queue_redraw()
func _close_bag() -> void:
	bag_dragging = false
	open_bag = false
	ZONES.erase("bag")
	if bag_window_node != null:
		bag_window_node.hide()
	queue_redraw()
func _sync_bag_window() -> void:
	var grid_size := Vector2(state.zone_size("bag"))*BAG_CELL
	bag_popup.size = Vector2(maxf(200,grid_size.x+40),grid_size.y+106)
	bag_window_node.position = bag_popup.position
	bag_window_node.size = bag_popup.size
	ZONES["bag"] = {
		"rect":Rect2(bag_popup.position + Vector2((bag_popup.size.x-grid_size.x)/2,64), Vector2(state.zone_size("bag")) * BAG_CELL),
		"cell":BAG_CELL
	}
	bag_close.position = Vector2(bag_popup.size.x - 42, 8)

func _sync_machine_window(id: int) -> void:
	if not machine_popups.has(id):
		return
	if _find_item(id).key in ["furnace","alembic"]:
		var is_alchemy: bool = _find_item(id).key == "alembic"
		var rect: Rect2 = machine_popups[id]
		rect.size = Vector2(384 if is_alchemy else 520,388 if is_alchemy else 340)
		machine_popups[id] = rect
		var workbench_host: Control = machine_window_nodes[id]
		workbench_host.position = rect.position
		workbench_host.size = rect.size
		var zones: Array = [state.machine_zone(id),state.machine_output_zone(id)] if is_alchemy else [state.machine_fuel_zone(id),state.machine_zone(id),state.machine_output_zone(id)]
		var xs: Array = [28,260] if is_alchemy else [28,164,396]
		for n in range(zones.size()):
			ZONES[zones[n]] = {"rect":Rect2(rect.position+Vector2(xs[n],90),Vector2(state.zone_size(zones[n]))*CELL),"cell":CELL}
		if is_alchemy:
			ZONES[state.machine_fuel_zone(id)] = {"rect":Rect2(rect.position+Vector2(68,320),Vector2(288,48)),"cell":CELL}
		machine_closes[id].position = Vector2(rect.size.x-44,12)
		return
	var zone := state.machine_zone(id)
	var grid_size := Vector2(state.zone_size(zone))*CELL
	var popup: Rect2 = machine_popups[id]
	popup.size = Vector2(maxf(200,grid_size.x+40),grid_size.y+106)
	machine_popups[id] = popup
	var host: Control = machine_window_nodes[id]
	host.position = popup.position
	host.size = popup.size
	ZONES[zone] = {
		"rect":Rect2(popup.position + Vector2((popup.size.x-grid_size.x)/2,64),grid_size),
		"cell":CELL
	}
	var close: Button = machine_closes[id]
	close.position = Vector2(popup.size.x - 42, 8)

func _close_machine(id: int = -1) -> void:
	if id < 0:
		for key in machine_popups.keys().duplicate():
			_close_machine(int(key))
		open_machine = -1
		machine_dragging_id = -1
		queue_redraw()
		return
	if not machine_popups.has(id):
		return
	for zone in state.machine_zones(id):
		ZONES.erase(zone)
	recipe_buttons.erase(id)
	if machine_dragging_id == id:
		machine_dragging_id = -1
	var host: Control = machine_window_nodes[id]
	host.queue_free()
	machine_window_nodes.erase(id)
	machine_closes.erase(id)
	machine_popups.erase(id)
	var remaining := _machine_ids_topmost()
	open_machine = remaining[0] if not remaining.is_empty() else -1
	queue_redraw()

func _machine_window_input(event: InputEvent) -> bool:
	if machine_popups.is_empty():
		return false
	var point := get_local_mouse_position()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and drag_id < 0:
		_close_machine(_machine_ids_topmost()[0])
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for machine_id in _machine_ids_topmost():
				var popup: Rect2 = machine_popups[machine_id]
				var title_rect := Rect2(popup.position,Vector2(popup.size.x,48))
				var close: Button = machine_closes[machine_id]
				var close_rect := Rect2(popup.position + close.position,close.size)
				if recipe_buttons.has(machine_id) and recipe_buttons[machine_id].get_global_rect().has_point(point):
					return false
				if title_rect.has_point(point) and not close_rect.has_point(point):
					machine_dragging_id = machine_id
					machine_drag_offset = point-popup.position
					get_viewport().set_input_as_handled()
					return true
		if not event.pressed and machine_dragging_id >= 0:
			machine_dragging_id = -1
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventMouseMotion and machine_dragging_id >= 0:
		var popup: Rect2 = machine_popups[machine_dragging_id]
		popup.position = (point-machine_drag_offset).clamp(
			Vector2(8,8),Vector2(1600,868)-popup.size
		)
		machine_popups[machine_dragging_id] = popup
		_sync_machine_window(machine_dragging_id)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return true
	return false
func _bind_art_hotspot(b: TextureButton, label: String, action: Callable) -> void:
	_bind_art_visual(b,label)
	b.pressed.connect(action)
func _bind_art_visual(b: TextureButton, label: String) -> void:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(b.texture_normal.get_image(),0.1)
	b.texture_click_mask = bitmap
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.show_behind_parent = false
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://scripts/hover_outline.gdshader")
	b.material = shader_material
	b.mouse_entered.connect(func():
		shader_material.set_shader_parameter("hovered",true)
		var rect := b.get_global_rect()
		var use_right := rect.position.x + rect.size.x + 120.0 < get_viewport_rect().size.x
		var anchor := rect.position + (Vector2(rect.size.x,8.0) if use_right else Vector2(0,8.0))
		var alignment := "vertical_center" if b == door_art else ("horizontal_center" if b == bed_art else "")
		_show_hover_tip("art:%s" % b.name,label,anchor,true,"",4096,1.0 if use_right else -1.0,rect,alignment)
	)
	b.mouse_exited.connect(func():
		shader_material.set_shader_parameter("hovered",false)
		_hide_hover_tip("art:%s" % b.name)
	)
	art_buttons.append(b)
func _begin_day() -> void:
	state.advance_day()
	customer_index = 0
	_prepare_next_day()
	_close_modal()
	_sync()
	_notify("第 %d 天已开始，点击关门器打开卷帘门营业。" % state.day)
# A customer inventory is an independent window; there is no physical customer tray.
var customer_bag_open := false
var customer_bag_rect := Rect2(24,104,616,186)
var customer_bag_button: Button
var customer_bag_close: Button
var customer_bag_window_node: Control
var customer_bag_dragging := false
var customer_bag_offset := Vector2.ZERO
func _open_customer_bag() -> void:
	if state.customer_sell_key == "":
		return
	customer_bag_open = true
	_sync_customer_bag()
	customer_bag_window_node.show()
	queue_redraw()
func _close_customer_bag() -> void:
	customer_bag_open = false
	customer_bag_dragging = false
	ZONES.erase("customer")
	if customer_bag_window_node != null:
		customer_bag_window_node.hide()
	queue_redraw()
func _sync_customer_bag() -> void:
	customer_bag_window_node.position = customer_bag_rect.position
	customer_bag_window_node.size = customer_bag_rect.size
	ZONES["customer"] = {"rect":Rect2(customer_bag_rect.position+Vector2(20,64),Vector2(State.SIZES.customer)*CELL),"cell":CELL}
	customer_bag_close.position = Vector2(customer_bag_rect.size.x-42,8)
func _customer_bag_input(event: InputEvent) -> bool:
	if not customer_bag_open:
		return false
	var point := get_local_mouse_position()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and drag_id < 0:
		_close_customer_bag()
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Rect2(customer_bag_rect.position,Vector2(customer_bag_rect.size.x-46,48)).has_point(point):
			customer_bag_dragging = true
			customer_bag_offset = point-customer_bag_rect.position
			get_viewport().set_input_as_handled()
			return true
		if not event.pressed and customer_bag_dragging:
			customer_bag_dragging = false
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventMouseMotion and customer_bag_dragging:
		customer_bag_rect.position = (point-customer_bag_offset).clamp(Vector2(8,80),Vector2(1592,860)-customer_bag_rect.size)
		_sync_customer_bag()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return true
	return false
func _style_popup_close(button: Button) -> void:
	PopupSkin.close_button(button)
func _draw_bag_shell(rect: Rect2, title: String, hint: String) -> void:
	PopupSkin.draw_window(self,rect)
	PopupSkin.title(self,title,rect.position+Vector2(18,32))
	if hint != "":
		_text(hint,rect.position+Vector2(18,rect.size.y-12),14,PopupSkin.MUTED)

func _open_recipe_drawings(machine_key: String = "furnace") -> void:
	if modal != null:
		return
	drag_id = -1
	machine_dragging_id = -1
	_hide_hover_tip()
	modal = Panel.new()
	modal.z_index = 100
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_theme_stylebox_override("panel",PopupSkin.box(PopupSkin.SHADE,Color.TRANSPARENT))
	add_child(modal)
	var drawing := WorkbenchView.new()
	drawing.alchemy = machine_key == "alembic"
	drawing.position = Vector2(480,184)
	drawing.size = Vector2(640,480)
	modal.add_child(drawing)
	var close := _popup_close(drawing,_close_modal)
	close.position = Vector2(598,17)
	for direction in [-1,1]:
		var button := Button.new()
		button.text = "上一张" if direction < 0 else "下一张"
		button.position = Vector2(28 if direction < 0 else 500,438)
		button.size = Vector2(112,30)
		PopupSkin.button(button)
		button.pressed.connect(func():
			drawing.page = posmod(drawing.page+direction,drawing.recipe_count())
			drawing.queue_redraw()
		)
		drawing.add_child(button)

func _show_workbench_preview() -> bool:
	if drag_id < 0 and not _full_overlay_open() and not is_instance_valid(exploration):
		for machine_id in _machine_ids_topmost():
			if not machine_popups[machine_id].has_point(mouse):
				continue
			if _find_item(machine_id).key == "alembic":
				var output_zone := state.machine_output_zone(machine_id)
				var plan: Dictionary = state.alchemy_preview(machine_id)
				if ZONES[output_zone].rect.has_point(mouse) and plan.output != "":
					var detail: String = plan.status
					if plan.quantity > 0:
						detail += ("\n" if detail != "" else "")+"产出 × %d" % plan.quantity
					_show_hover_tip("alchemy_preview:%s:%s:%d" % [plan.preview_name,plan.status,plan.quantity],plan.preview_name,mouse+Vector2(18,0),false,detail)
					return true
			if _find_item(machine_id).key == "furnace":
				var output_zone := state.machine_output_zone(machine_id)
				var plan: Dictionary = state.workbench_preview(machine_id)
				if ZONES[output_zone].rect.has_point(mouse) and plan.output != "":
					var detail: String = plan.status
					if plan.purity > 0:
						detail += "\n纯度 %d%% · 耐久 %d / %d" % [plan.purity,plan.max_durability,plan.max_durability]
					if plan.fuel_id >= 0:
						detail += "\n消耗 %d 份矿石、1 份%s" % [plan.inputs.size(),State.CATALOG[_find_item(plan.fuel_id).key].name]
					_show_hover_tip("workbench_preview:%s:%d:%s" % [plan.output,plan.purity,plan.status],State.CATALOG[plan.output].name,mouse+Vector2(18,0),false,detail)
					return true
			break
	return false
