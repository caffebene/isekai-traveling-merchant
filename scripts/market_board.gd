extends Control

signal close_requested
signal travel_requested

const PopupSkin = preload("res://scripts/popup_style.gd")
const INK := Color("eaddbd")
const MUTED := Color("aaa58f")
const GOLD := Color("d0ad70")
const UP := Color("ee9a70")
const DOWN := Color("7fc9c0")

var state
var item_textures: Dictionary
var font: SystemFont
var rows: VBoxContainer
var events_column: VBoxContainer
var travel_button: Button

func setup(store, textures: Dictionary) -> void:
	state = store
	item_textures = textures

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC","Noto Sans CJK SC","Microsoft YaHei"])
	var shade := ColorRect.new()
	shade.color = Color("081014d6")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var window := Panel.new()
	window.position = Vector2(180,72)
	window.size = Vector2(1240,756)
	window.add_theme_stylebox_override("panel",PopupSkin.box(Color("182326fa"),GOLD,10))
	add_child(window)
	var title := _label(window,"商路行情簿",Vector2(32,20),27,GOLD)
	var city := _label(window,"%s · 周期第 %d 天" % [state.economy.city_name(),state.economy.cycle_day(state.day)],Vector2(32,57),16,INK)
	city.add_theme_color_override("font_color",INK)
	var departure := "商路今日开放" if state.can_travel() else "%d 天后开放商路" % state.economy.days_until_departure(state.day)
	_label(window,departure,Vector2(970,28),15,DOWN if state.can_travel() else MUTED)
	var close := _button(window,"×",Vector2(1184,18),Vector2(34,34),false)
	close.pressed.connect(func(): close_requested.emit())

	var left := Panel.new()
	left.position = Vector2(24,94)
	left.size = Vector2(760,578)
	left.add_theme_stylebox_override("panel",PopupSkin.box(Color("111a1de8"),Color("526267"),6))
	window.add_child(left)
	_label(left,"当前商品行情",Vector2(20,14),19,INK)
	_label(left,"商品",Vector2(76,48),12,MUTED)
	_label(left,"基础",Vector2(322,48),12,MUTED)
	_label(left,"现价",Vector2(392,48),12,MUTED)
	_label(left,"涨跌",Vector2(466,48),12,MUTED)
	_label(left,"价格原因",Vector2(548,48),12,MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12,70)
	scroll.size = Vector2(736,494)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",4)
	scroll.add_child(rows)

	var right := Panel.new()
	right.position = Vector2(800,94)
	right.size = Vector2(416,578)
	right.add_theme_stylebox_override("panel",PopupSkin.box(Color("111a1de8"),Color("526267"),6))
	window.add_child(right)
	_label(right,"事件日历 · 精确预测",Vector2(20,14),19,INK)
	var event_scroll := ScrollContainer.new()
	event_scroll.position = Vector2(12,50)
	event_scroll.size = Vector2(392,514)
	event_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(event_scroll)
	events_column = VBoxContainer.new()
	events_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	events_column.add_theme_constant_override("separation",10)
	event_scroll.add_child(events_column)

	travel_button = _button(window,"前往%s · %d G" % [state.economy.other_city_name(),state.economy.TRAVEL_COST],Vector2(958,690),Vector2(258,44),true)
	travel_button.visible = state.can_travel()
	travel_button.pressed.connect(func(): travel_requested.emit())
	_label(window,"行情价直接用于柜台报价；连续倾销会继续压低同类商品价格。",Vector2(32,703),13,MUTED)
	refresh()

func refresh() -> void:
	if state == null or rows == null:
		return
	for child in rows.get_children():
		child.queue_free()
	var keys: Array[String] = []
	for key in state.CATALOG:
		if str(state.CATALOG[key].category) not in ["设备","容器","杂物"]:
			keys.append(str(key))
	keys.sort_custom(func(a,b):
		var ad: Dictionary = state.economy.price_breakdown(a,state.CATALOG[a].category,state.CATALOG[a].value,state.day)
		var bd: Dictionary = state.economy.price_breakdown(b,state.CATALOG[b].category,state.CATALOG[b].value,state.day)
		return absi(int(ad.percent)) > absi(int(bd.percent)) if absi(int(ad.percent)) != absi(int(bd.percent)) else str(state.CATALOG[a].name) < str(state.CATALOG[b].name)
	)
	for key in keys:
		_add_market_row(key)
	for child in events_column.get_children():
		child.queue_free()
	for event in state.economy.CITIES[state.economy.city_id].events:
		_add_event_card(event)

func _add_market_row(key: String) -> void:
	var data: Dictionary = state.CATALOG[key]
	var quote: Dictionary = state.economy.price_breakdown(key,data.category,data.value,state.day)
	var row := Panel.new()
	row.custom_minimum_size = Vector2(716,58)
	row.add_theme_stylebox_override("panel",PopupSkin.box(Color("1d2a2dcf") if rows.get_child_count()%2 == 0 else Color("172326cf"),Color("334448"),3))
	rows.add_child(row)
	if item_textures.has(key):
		var icon_clip := Control.new()
		icon_clip.position = Vector2(12,7)
		icon_clip.size = Vector2(44,44)
		icon_clip.custom_minimum_size = Vector2(44,44)
		icon_clip.clip_contents = true
		icon_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_clip)
		var icon := TextureRect.new()
		icon.texture = item_textures[key]
		icon.position = Vector2.ZERO
		icon.size = Vector2(44,44)
		icon.custom_minimum_size = Vector2(44,44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_clip.add_child(icon)
	_label(row,str(data.name),Vector2(64,8),15,INK)
	_label(row,str(data.category),Vector2(64,31),11,MUTED)
	_label(row,"%d G" % int(quote.base),Vector2(310,19),14,MUTED)
	_label(row,"%d G" % int(quote.current),Vector2(380,19),16,INK)
	var percent: int = int(quote.percent)
	var color := UP if percent > 0 else DOWN if percent < 0 else MUTED
	_label(row,"%+d%%" % percent,Vector2(454,19),16,color)
	var reason := "；".join(Array(quote.reasons))
	var reason_label := _label(row,reason,Vector2(526,10),12,color)
	reason_label.size = Vector2(178,42)
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _add_event_card(event: Dictionary) -> void:
	var local_day: int = state.economy.cycle_day(state.day)
	var start: int = int(event.start)
	var finish: int = start + int(event.duration) - 1
	var active: bool = local_day >= start and local_day <= finish
	var wait: int = start-local_day
	var state_text := "今日生效" if active else "%d 天后" % wait if wait > 0 else "本周期已结束"
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(370,220)
	card.add_theme_stylebox_override("panel",PopupSkin.box(Color("26322df0") if active else Color("192427e8"),UP if active else Color("46585c"),5))
	events_column.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	card.add_child(column)
	var heading := Label.new()
	heading.text = "%s  ·  第 %d–%d 天  ·  %s" % [event.name,start,finish,state_text]
	heading.add_theme_font_override("font",font)
	heading.add_theme_font_size_override("font_size",16)
	heading.add_theme_color_override("font_color",UP if active else GOLD)
	column.add_child(heading)
	for key in state.economy.event_items(event,state.CATALOG):
		var data: Dictionary = state.CATALOG[key]
		var price: int = state.economy.event_price(key,event,state.CATALOG)
		var percent: int = state.economy.event_change_percent(key,event)
		var line := Label.new()
		line.text = "%s  %+.0f%%  →  %d G" % [data.name,percent,price]
		line.add_theme_font_override("font",font)
		line.add_theme_font_size_override("font_size",12)
		line.add_theme_color_override("font_color",UP if percent > 0 else DOWN)
		column.add_child(line)

func _label(parent: Node, value: String, at: Vector2, size_value: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, at: Vector2, dimensions: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.add_theme_font_override("font",font)
	PopupSkin.button(button,primary)
	parent.add_child(button)
	return button
