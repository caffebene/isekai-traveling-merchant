extends Control

signal close_requested
signal purchase_requested(module_id: String)

const PopupSkin = preload("res://scripts/popup_style.gd")
const INK := Color("eaddbd")
const MUTED := Color("aaa58f")
const GOLD := Color("d0ad70")
const ACTIVE := Color("7fc9c0")
const LOCKED := Color("6e7370")
const MODULES := [
	{"id":"roof_rack","name":"车顶货架","tag":"空间","effect":"旅行背包","before":"6 × 6 · 36 格","after":"8 × 6 · 48 格","proof":"安装后背包立即增加两列"},
	{"id":"hidden_compartment","name":"隐藏夹层","tag":"保险","effect":"探索战败","before":"背包物品全部遗失","after":"保留价值最高的 2 件","proof":"受保护物品显示锁形标记"},
	{"id":"field_kitchen","name":"行军灶","tag":"续航","effect":"食物恢复","before":"面包 12 · 烤肉 20","after":"面包 20 · 烤肉 28","proof":"物品悬停显示最终恢复值"},
]

var state
var font: SystemFont
var cards := HBoxContainer.new()
var status_label: Label
var gold_label: Label

func setup(store) -> void:
	state = store

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
	window.position = Vector2(190,150)
	window.size = Vector2(1220,600)
	window.add_theme_stylebox_override("panel",PopupSkin.box(Color("182326fa"),GOLD,10))
	add_child(window)
	_label(window,"商车改装台",Vector2(32,22),28,GOLD)
	_label(window,"选择会改变规则的模块 · 最多安装 2 个",Vector2(32,62),15,MUTED)
	gold_label = _label(window,"",Vector2(1000,30),16,INK)
	var close := _button(window,"×",Vector2(1164,18),Vector2(34,34),false)
	close.pressed.connect(func(): close_requested.emit())
	cards.position = Vector2(30,108)
	cards.size = Vector2(1160,390)
	cards.add_theme_constant_override("separation",18)
	window.add_child(cards)
	status_label = _label(window,"",Vector2(32,536),15,ACTIVE)
	refresh()

func refresh(message := "") -> void:
	if state == null or not is_instance_valid(cards):
		return
	for child in cards.get_children():
		child.queue_free()
	gold_label.text = "金币  %d G  ·  插槽 %d / 2" % [state.gold,state.economy.modules.size()]
	status_label.text = message
	for definition in MODULES:
		_add_card(definition)

func _add_card(definition: Dictionary) -> void:
	var installed: bool = state.economy.has_module(definition.id)
	var full: bool = state.economy.modules.size() >= 2
	var affordable: bool = state.gold >= state.economy.module_cost(definition.id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(374,390)
	card.add_theme_stylebox_override("panel",PopupSkin.box(Color("20332ff0") if installed else Color("151f22ef"),ACTIVE if installed else Color("526267"),7))
	cards.add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",10)
	card.add_child(body)
	var tag := Label.new()
	tag.text = "%s  ·  %s" % [definition.tag,"已启用" if installed else "未安装"]
	tag.add_theme_font_override("font",font)
	tag.add_theme_font_size_override("font_size",13)
	tag.add_theme_color_override("font_color",ACTIVE if installed else MUTED)
	body.add_child(tag)
	var title := Label.new()
	title.text = definition.name
	title.add_theme_font_override("font",font)
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",INK)
	body.add_child(title)
	var effect := Label.new()
	effect.text = definition.effect
	effect.add_theme_font_override("font",font)
	effect.add_theme_font_size_override("font_size",14)
	effect.add_theme_color_override("font_color",GOLD)
	body.add_child(effect)
	_add_rule(body,"改装前",definition.before,MUTED)
	_add_rule(body,"改装后",definition.after,ACTIVE)
	var proof := Label.new()
	proof.text = definition.proof
	proof.custom_minimum_size.y = 52
	proof.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	proof.add_theme_font_override("font",font)
	proof.add_theme_font_size_override("font_size",13)
	proof.add_theme_color_override("font_color",INK)
	body.add_child(proof)
	var price: int = state.economy.module_cost(definition.id)
	var button := Button.new()
	button.text = "已安装" if installed else "插槽已满" if full else "金币不足 · %d G" % price if not affordable else "安装 · %d G" % price
	button.custom_minimum_size = Vector2(0,44)
	button.disabled = installed or full or not affordable
	button.add_theme_font_override("font",font)
	PopupSkin.button(button,not button.disabled)
	button.pressed.connect(func(): purchase_requested.emit(str(definition.id)))
	body.add_child(button)

func _add_rule(parent: Node, key: String, value: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",PopupSkin.box(Color("11191cd9"),Color("39494c"),3))
	parent.add_child(panel)
	var label := Label.new()
	label.text = "%s\n%s" % [key,value]
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",color)
	panel.add_child(label)

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
