extends Panel
signal offer_submitted(value: int)
signal accepted
signal withdrawn
signal close_requested
const PopupSkin = preload("res://scripts/popup_style.gd")
var price: SpinBox
var accept: Button
var haggle: Button
var cancel: Button
var close: Button
var rows: VBoxContainer
var summary: Label
var heading: Label
var intent: Label
var offer_label: Label
var buy_tab: Button
var sell_tab: Button
var columns: HBoxContainer
var scroll: ScrollContainer
var state_ref
var dragging := false
var drag_offset := Vector2.ZERO
var keep_open := false

func _draw() -> void:
 var rect := Rect2(Vector2.ZERO,size)
 var shadow := PopupSkin.window_points(Rect2(rect.position+Vector2(5,5),rect.size),10)
 draw_colored_polygon(shadow,Color(0,0,0,0.58))
 draw_colored_polygon(PopupSkin.window_points(rect,10),PopupSkin.PANEL)
 var outline := PopupSkin.window_points(rect,10)
 outline.append(outline[0])
 draw_polyline(outline,PopupSkin.BRASS,1.0,true)
 var header_rect := Rect2(Vector2.ZERO,Vector2(size.x,48))
 draw_colored_polygon(PopupSkin.header_points(header_rect,10),PopupSkin.PANEL_ALT)
 draw_rect(Rect2(0,0,7,48),PopupSkin.ORANGE)
 draw_rect(Rect2(size.x-44,16,26,2),PopupSkin.CYAN)
 draw_line(Vector2(12,48),Vector2(size.x-12,48),PopupSkin.BRASS,1.0)

func _ready() -> void:
 size = Vector2(400,460)
 mouse_filter = Control.MOUSE_FILTER_STOP
 add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var header := Panel.new()
 header.position = Vector2(1,1)
 header.size = Vector2(398,48)
 header.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 header.mouse_default_cursor_shape = Control.CURSOR_MOVE
 add_child(header)
 var accent := ColorRect.new()
 accent.position = Vector2(0,0)
 accent.size = Vector2(4,48)
 accent.color = PopupSkin.ORANGE
 accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
 header.add_child(accent)
 var signal_mark := ColorRect.new()
 signal_mark.position = Vector2(352,12)
 signal_mark.size = Vector2(28,2)
 signal_mark.color = PopupSkin.CYAN
 signal_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
 header.add_child(signal_mark)
 heading = _label("交易清单",Vector2(20,12),20)
 heading.add_theme_color_override("font_color",PopupSkin.PAPER)
 heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 close = Button.new()
 close.text = "×"
 close.position = Vector2(350,8)
 close.size = Vector2(30,30)
 close.add_theme_font_size_override("font_size",18)
 PopupSkin.button(close)
 close.add_theme_stylebox_override("normal",PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.BRASS,0))
 close.add_theme_stylebox_override("hover",PopupSkin.box(PopupSkin.ORANGE,PopupSkin.DARK,0))
 close.pressed.connect(func(): close_requested.emit())
 header.add_child(close)
 header.gui_input.connect(func(e):
  if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
   dragging = e.pressed
   drag_offset = get_global_mouse_position()-global_position
   header.accept_event()
  elif e is InputEventMouseMotion and dragging:
   position = (get_global_mouse_position()-drag_offset).clamp(Vector2(8,8),Vector2(1592,860)-size)
   header.accept_event()
 )
 intent = _label("",Vector2(20,62),13)
 intent.size = Vector2(360,44)
 intent.add_theme_color_override("font_color",PopupSkin.MUTED)
 buy_tab = _button("买入",Vector2(20,112),Vector2(176,32))
 sell_tab = _button("卖出",Vector2(204,112),Vector2(176,32))
 buy_tab.pressed.connect(func(): _select_tab("buy"))
 sell_tab.pressed.connect(func(): _select_tab("sell"))
 columns = HBoxContainer.new()
 columns.position = Vector2(28,158)
 columns.add_theme_constant_override("separation",0)
 add_child(columns)
 for entry in [["商品",202],["类别",66],["估值",76]]:
  var l := Label.new()
  l.text = entry[0]
  l.custom_minimum_size.x = entry[1]
  l.add_theme_font_size_override("font_size",12)
  l.add_theme_color_override("font_color",PopupSkin.MUTED)
  columns.add_child(l)
 scroll = ScrollContainer.new()
 scroll.position = Vector2(20,184)
 scroll.size = Vector2(360,100)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 rows = VBoxContainer.new()
 rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation",4)
 scroll.add_child(rows)
 summary = _label("",Vector2.ZERO,16)
 offer_label = _label("我的还价",Vector2.ZERO,13)
 offer_label.add_theme_color_override("font_color",PopupSkin.MUTED)
 price = SpinBox.new()
 price.min_value = 1
 price.max_value = 9999
 price.suffix = "G"
 price.size = Vector2(190,38)
 price.add_theme_font_size_override("font_size",18)
 var line := price.get_line_edit()
 line.alignment = HORIZONTAL_ALIGNMENT_CENTER
 line.add_theme_stylebox_override("normal",PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.BRASS,0))
 line.add_theme_stylebox_override("focus",PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.ORANGE,0))
 line.add_theme_color_override("font_color",PopupSkin.INK)
 add_child(price)
 haggle = _button("提出还价",Vector2.ZERO,Vector2(158,38))
 haggle.pressed.connect(func(): offer_submitted.emit(int(price.value)))
 accept = _button("接受报价",Vector2.ZERO,Vector2(238,44),true)
 accept.pressed.connect(func(): accepted.emit())
 cancel = _button("撤回物品",Vector2.ZERO,Vector2(110,44))
 cancel.pressed.connect(func(): withdrawn.emit())

func _label(value: String, pos: Vector2, font_size := 15) -> Label:
 var l := Label.new()
 l.text = value
 l.position = pos
 l.add_theme_color_override("font_color",PopupSkin.INK)
 l.add_theme_font_size_override("font_size",font_size)
 add_child(l)
 return l

func _button(value: String, pos: Vector2, dimensions: Vector2, primary := false) -> Button:
 var b := Button.new()
 b.text = value
 b.position = pos
 b.size = dimensions
 PopupSkin.button(b,primary)
 add_child(b)
 return b

func _set_tab_style(button: Button, active: bool) -> void:
 PopupSkin.button(button,active)

func _select_tab(tab: String) -> void:
 if state_ref == null:
  return
 state_ref.select_trade_tab(tab)
 refresh(state_ref)

func refresh(state) -> void:
 state_ref = state
 var settled_items: Array[Dictionary] = state.settled_counter_items()
 visible = keep_open or state.has_pending_trade() or not settled_items.is_empty()
 if not visible:
  return
 var buying_items: Array[Dictionary] = state.buying_items()
 var selling_items: Array[Dictionary] = state.selling_items()
 buy_tab.visible = not buying_items.is_empty() and not selling_items.is_empty()
 sell_tab.visible = buy_tab.visible
 buy_tab.disabled = buying_items.is_empty()
 sell_tab.disabled = selling_items.is_empty()
 intent.text = "顾客资金  %d / %d G" % [state.customer_funds,state.customer_funds_limit]
 if state.customer_buy_category != "":
  intent.text += "\n收购偏好  %s" % state.customer_buy_category
 elif state.customer_sell_key == "*":
  var categories: Array[String] = []
  for key in state.customer_goods:
   var category: String = state.CATALOG[key].category
   if not categories.has(category):
    categories.append(category)
  intent.text += "\n出售商品  "+"、".join(categories)
 elif state.customer_sell_key != "":
  intent.text += "\n出售商品  %s" % state.CATALOG[state.customer_sell_key].name
 var both := not buying_items.is_empty() and not selling_items.is_empty()
 buy_tab.position = Vector2(20,112)
 sell_tab.position = Vector2(204 if both else 20,112)
 buy_tab.size = Vector2(176 if both else 360,32)
 sell_tab.size = Vector2(176 if both else 360,32)
 if state.active_trade_tab == "buy" and buying_items.is_empty() and not selling_items.is_empty():
  state.select_trade_tab("sell")
 elif state.active_trade_tab == "sell" and selling_items.is_empty() and not buying_items.is_empty():
  state.select_trade_tab("buy")
 _set_tab_style(buy_tab,state.active_trade_tab == "buy")
 _set_tab_style(sell_tab,state.active_trade_tab == "sell")
 var active_items: Array[Dictionary] = state.buying_items() if state.active_trade_tab == "buy" else state.selling_items()
 var list_height := clampi(maxi(1,active_items.size()) * 36,72,144)
 var awaiting_more := keep_open and active_items.is_empty() and settled_items.is_empty()
 columns.position.y = 158 if both else 112
 scroll.position.y = 184 if both else 138
 scroll.size = Vector2(360,list_height)
 var controls_y := int(scroll.position.y) + list_height + 18
 summary.position = Vector2(20,controls_y)
 offer_label.position = Vector2(20,controls_y+36)
 price.position = Vector2(20,controls_y+60)
 haggle.position = Vector2(222,controls_y+60)
 accept.position = Vector2(20,controls_y+116)
 cancel.position = Vector2(270,controls_y+116)
 size.y = controls_y + 180
 position = position.clamp(Vector2(8,8),Vector2(1592,860)-size)
 for child in rows.get_children():
  rows.remove_child(child)
  child.queue_free()
 if awaiting_more:
  var hint := Label.new()
  hint.text = "顾客还有 %d G，可以继续上货。" % state.customer_funds
  hint.add_theme_font_size_override("font_size",14)
  hint.add_theme_color_override("font_color",PopupSkin.MUTED)
  rows.add_child(hint)
 elif active_items.is_empty() and not settled_items.is_empty():
  var hint := Label.new()
  hint.text = "已支付物品仍在柜台，请手动收纳。"
  hint.add_theme_font_size_override("font_size",14)
  hint.add_theme_color_override("font_color",PopupSkin.MUTED)
  rows.add_child(hint)
 for item in active_items:
  var data: Dictionary = state.CATALOG[item.key]
  var row_panel := PanelContainer.new()
  row_panel.custom_minimum_size.y = 32
  var row_skin := PopupSkin.box(PopupSkin.PANEL_ALT,Color("39464c"),0)
  row_skin.content_margin_left = 8
  row_skin.content_margin_right = 8
  row_panel.add_theme_stylebox_override("panel",row_skin)
  rows.add_child(row_panel)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",0)
  row_panel.add_child(row)
  var item_name: String = ("✓ " if item.get("settled",false) else "") + str(data.name)
  for entry in [[item_name,202],[data.category,66],[str(data.value)+" G",60]]:
   var l := Label.new()
   l.text = entry[0]
   l.custom_minimum_size.x = entry[1]
   l.add_theme_font_size_override("font_size",14)
   l.add_theme_color_override("font_color",PopupSkin.INK)
   l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   row.add_child(l)
 var heading_name := "继续交易" if awaiting_more else ("交易清单" if both else ("买入清单" if not buying_items.is_empty() else "卖出清单"))
 heading.text = "%s · %d 件" % [heading_name,state.counter_items().size()]
 if not buying_items.is_empty() and not selling_items.is_empty():
  summary.text = "购买 %d G  /  出售 %d G" % [state.buy_offer,state.sell_offer]
 elif not buying_items.is_empty():
  summary.text = "估值 %d G   ·   对方报价 %d G" % [state.buying_value(),state.buy_offer]
 elif not selling_items.is_empty():
  summary.text = "估值 %d G   ·   对方报价 %d G" % [state.selling_value(),state.sell_offer]
 elif awaiting_more:
  summary.text = "顾客余款 %d G · 可继续摆货" % state.customer_funds
 else:
  summary.text = "已支付物品：请手动拖回库存"
 price.visible = not awaiting_more
 offer_label.visible = not awaiting_more
 haggle.visible = not awaiting_more
 price.value = maxi(1,state.offer)
 haggle.disabled = state.patience <= 0
 accept.disabled = not state.has_pending_trade()
 if not buying_items.is_empty() and not selling_items.is_empty():
  accept.text = "完成混合交易"
 elif not buying_items.is_empty():
  accept.text = "支付 %d G" % state.buy_offer
 elif not selling_items.is_empty():
  accept.text = "收取 %d G" % state.sell_offer
 elif awaiting_more:
  accept.text = "等待更多货物"
 else:
  accept.text = "已完成"
 cancel.disabled = not state.has_pending_trade()
