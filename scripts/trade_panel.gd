extends Panel
signal offer_submitted(value: int)
signal accepted
signal withdrawn
signal close_requested
const PopupSkin = preload("res://scripts/popup_style.gd")
const Art = preload("res://scripts/item_art.gd")
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
var scroll: ScrollContainer
var list_caption: Label
var budget: Label
var market_total: Label
var quote: Label
var state_ref
var dragging := false
var drag_offset := Vector2.ZERO
var keep_open := false

func _draw() -> void:
 PopupSkin.draw_window(self,Rect2(Vector2.ZERO,size))
 # One continuous ledger instead of individually boxed table rows.
 draw_style_box(PopupSkin.box(PopupSkin.BACKGROUND,PopupSkin.DIVIDER),Rect2(20,122,360,238))
 draw_line(Vector2(21,158),Vector2(379,158),PopupSkin.DIVIDER,1)
 draw_style_box(PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.DIVIDER),Rect2(20,368,360,48))

func _ready() -> void:
 size = Vector2(400,536)
 theme = PopupSkin.theme()
 mouse_filter = Control.MOUSE_FILTER_STOP
 add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var header := Panel.new()
 header.size = Vector2(400,48)
 header.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 header.mouse_default_cursor_shape = Control.CURSOR_MOVE
 add_child(header)
 heading = _label("交易账单",Vector2(48,8),20)
 heading.size = Vector2(288,32)
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 heading.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
 heading.add_theme_font_override("font",PopupSkin.font(true))
 close = Button.new()
 close.text = "×"
 PopupSkin.close_button(close)
 PopupSkin.place_close(close,400)
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
 intent = _label("",Vector2(20,62),16)
 intent.size = Vector2(224,52)
 intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 intent.add_theme_color_override("font_color",PopupSkin.MUTED)
 var budget_title := _label("顾客预算",Vector2(254,62),14)
 budget_title.size = Vector2(126,20)
 budget_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 budget_title.add_theme_color_override("font_color",PopupSkin.MUTED)
 budget = _label("",Vector2(254,84),24)
 budget.size = Vector2(126,30)
 budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 budget.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
 list_caption = _label("",Vector2(28,128),16)
 list_caption.size = Vector2(344,24)
 list_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 buy_tab = _button("购入",Vector2(24,126),Vector2(172,28))
 sell_tab = _button("出售",Vector2(204,126),Vector2(172,28))
 buy_tab.pressed.connect(func(): _select_tab("buy"))
 sell_tab.pressed.connect(func(): _select_tab("sell"))
 scroll = ScrollContainer.new()
 scroll.position = Vector2(24,164)
 scroll.size = Vector2(352,192)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 rows = VBoxContainer.new()
 rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation",0)
 scroll.add_child(rows)
 summary = _label("",Vector2(30,372),16)
 summary.size = Vector2(224,22)
 market_total = _label("",Vector2(30,395),14)
 market_total.size = Vector2(224,18)
 market_total.add_theme_color_override("font_color",PopupSkin.MUTED)
 quote = _label("",Vector2(264,376),24)
 quote.size = Vector2(106,32)
 quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 quote.add_theme_color_override("font_color",PopupSkin.HEADER_TEXT)
 offer_label = _label("还价",Vector2(20,432),14)
 offer_label.add_theme_color_override("font_color",PopupSkin.MUTED)
 price = SpinBox.new()
 price.min_value = 1
 price.max_value = 9999
 price.step = 1
 price.rounded = true
 price.suffix = "G"
 price.position = Vector2(64,424)
 price.size = Vector2(164,36)
 var line := price.get_line_edit()
 line.alignment = HORIZONTAL_ALIGNMENT_RIGHT
 line.add_theme_stylebox_override("normal",PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.FRAME))
 line.add_theme_stylebox_override("focus",PopupSkin.box(PopupSkin.PANEL_ALT,PopupSkin.ACCENT))
 line.add_theme_color_override("font_color",PopupSkin.TEXT)
 add_child(price)
 haggle = _button("提出还价",Vector2(240,424),Vector2(140,36))
 haggle.pressed.connect(func(): offer_submitted.emit(int(price.value)))
 accept = _button("成交",Vector2(20,476),Vector2(238,40),true)
 accept.pressed.connect(func(): accepted.emit())
 cancel = _button("撤回物品",Vector2(270,476),Vector2(110,40))
 cancel.pressed.connect(func(): withdrawn.emit())

func _label(value: String, pos: Vector2, font_size := 16) -> Label:
 var l := Label.new()
 l.text = value
 l.position = pos
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 l.add_theme_color_override("font_color",PopupSkin.TEXT)
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

func _add_item_row(item: Dictionary, state) -> void:
 var row := HBoxContainer.new()
 row.custom_minimum_size.y = 40
 row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("separation",8)
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 rows.add_child(row)
 row.draw.connect(func(): row.draw_line(Vector2(4,row.size.y-1),Vector2(row.size.x-4,row.size.y-1),Color(PopupSkin.DIVIDER,0.35),1))
 var icon := preload("res://scripts/quality_icon.gd").new()
 icon.texture = Art.ITEM_TEXTURES[item.key]
 icon.quality = state.Quality.tier(item) if state.CATALOG[item.key].category == "武器" else -1
 icon.custom_minimum_size = Vector2(32,36)
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(icon)
 var name_label := Label.new()
 name_label.text = str(state.CATALOG[item.key].name)
 name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 name_label.add_theme_font_size_override("font_size",16)
 name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(name_label)
 var amount := Label.new()
 amount.text = "%d G" % state.item_market_value(item)
 amount.custom_minimum_size.x = 80
 amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 amount.add_theme_font_size_override("font_size",16)
 amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(amount)

func refresh(state) -> void:
 state_ref = state
 var settled_items: Array[Dictionary] = state.settled_counter_items()
 visible = keep_open or state.has_pending_trade() or not settled_items.is_empty()
 if not visible:
  return
 var buying_items: Array[Dictionary] = state.buying_items()
 var selling_items: Array[Dictionary] = state.selling_items()
 var both := not buying_items.is_empty() and not selling_items.is_empty()
 buy_tab.visible = both
 sell_tab.visible = both
 list_caption.visible = not both
 buy_tab.text = "购入 %d 件" % buying_items.size()
 sell_tab.text = "出售 %d 件" % selling_items.size()
 budget.text = "%d G" % state.customer_funds
 intent.text = ""
 if state.customer_buy_category != "":
  intent.text = "收购  "+str(state.customer_buy_category)
 elif state.customer_sell_key == "*":
  var categories: Array[String] = []
  for key in state.customer_goods:
   var category: String = state.CATALOG[key].category
   if not categories.has(category):
    categories.append(category)
  intent.text = "出售  "+"、".join(categories)
 elif state.customer_sell_key != "":
  intent.text = "出售  "+str(state.CATALOG[state.customer_sell_key].name)
 if state.active_trade_tab == "buy" and buying_items.is_empty() and not selling_items.is_empty():
  state.select_trade_tab("sell")
 elif state.active_trade_tab == "sell" and selling_items.is_empty() and not buying_items.is_empty():
  state.select_trade_tab("buy")
 _set_tab_style(buy_tab,state.active_trade_tab == "buy")
 _set_tab_style(sell_tab,state.active_trade_tab == "sell")
 var active_items: Array[Dictionary] = buying_items if state.active_trade_tab == "buy" else selling_items
 var pending: bool = state.has_pending_trade()
 list_caption.text = "%s %d 件" % ["购入" if state.active_trade_tab == "buy" else "出售",active_items.size()] if pending else "清单"
 position = position.clamp(Vector2(8,8),Vector2(1592,860)-size)
 for child in rows.get_children():
  rows.remove_child(child)
  child.queue_free()
 if active_items.is_empty():
  var empty := Label.new()
  empty.text = "暂无待交易物品" if settled_items.is_empty() else "柜台物品已支付"
  empty.add_theme_font_size_override("font_size",14)
  empty.add_theme_color_override("font_color",PopupSkin.MUTED)
  empty.custom_minimum_size.y = 40
  rows.add_child(empty)
 for item in active_items:
  _add_item_row(item,state)
 var balance: int = state.sell_offer-state.buy_offer
 summary.text = "收取" if balance > 0 else "支付" if balance < 0 else "结算"
 quote.text = "%d G" % absi(balance) if pending else "—"
 market_total.text = "购入 %d G / 出售 %d G" % [state.buy_offer,state.sell_offer] if both else "行情合计 %d G" % (state.buying_value() if state.active_trade_tab == "buy" else state.selling_value()) if pending else ""
 price.visible = pending
 offer_label.visible = pending
 haggle.visible = pending
 price.value = maxi(1,state.offer)
 haggle.disabled = state.patience <= 0
 accept.disabled = not pending
 accept.text = "完成混合交易" if both else "购入 %d 件" % buying_items.size() if not buying_items.is_empty() else "出售 %d 件" % selling_items.size() if not selling_items.is_empty() else "成交"
 cancel.disabled = not pending
 queue_redraw()
