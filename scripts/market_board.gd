extends Control
## Newspaper reports stories, never item quotes or event multipliers.
signal close_requested
signal travel_requested
const PopupSkin = preload("res://scripts/popup_style.gd")
var state
var window: Panel
var masthead: Label
var dateline: Label
var articles_column: VBoxContainer
var local_column: VBoxContainer
var travel_button: Button
var travel_notice: Label

func setup(store, _textures: Dictionary) -> void:
 state = store

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index = 80
 mouse_filter = Control.MOUSE_FILTER_STOP
 theme = PopupSkin.theme()
 var shade := ColorRect.new()
 shade.color = PopupSkin.SHADE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 window = Panel.new()
 window.position = Vector2(280,78)
 window.size = Vector2(1040,744)
 window.add_theme_stylebox_override("panel",PopupSkin.newspaper_panel())
 add_child(window)
 masthead = _label(window,"",Rect2(32,14,700,56),36,true)
 dateline = _label(window,"",Rect2(32,80,650,24),16)
 var edition := _label(window,"市集版",Rect2(860,80,148,24),16)
 edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 var close := Button.new()
 close.text = "×"
 PopupSkin.close_button(close)
 PopupSkin.place_close(close,window.size.x)
 close.pressed.connect(func(): close_requested.emit())
 window.add_child(close)
 _rule(Rect2(32,112,976,2))
 _rule(Rect2(32,118,976,1))
 _rule(Rect2(652,140,1,496))
 _rule(Rect2(32,658,976,1))
 articles_column = _column(Rect2(32,140,592,496))
 local_column = _column(Rect2(680,140,328,496))
 travel_notice = _label(window,"",Rect2(32,676,656,44),16)
 travel_button = Button.new()
 travel_button.position = Vector2(724,684)
 travel_button.size = Vector2(284,40)
 PopupSkin.button(travel_button,true)
 travel_button.pressed.connect(func(): travel_requested.emit())
 window.add_child(travel_button)
 refresh()

func _column(bounds: Rect2) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.position = bounds.position
 scroll.size = bounds.size
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 window.add_child(scroll)
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",24)
 scroll.add_child(column)
 return column

func _rule(bounds: Rect2) -> void:
 var line := ColorRect.new()
 line.position = bounds.position
 line.size = bounds.size
 line.color = PopupSkin.NEWS_RULE
 line.mouse_filter = Control.MOUSE_FILTER_IGNORE
 window.add_child(line)

func _label(parent: Node, value: String, bounds: Rect2, font_size: int, title := false) -> Label:
 var label := Label.new()
 label.text = value
 label.position = bounds.position
 label.size = bounds.size
 label.add_theme_font_override("font",PopupSkin.font(title))
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",PopupSkin.NEWS_INK)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label

func _article(column: VBoxContainer, article: Dictionary, lead := false) -> void:
 var story := VBoxContainer.new()
 story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 story.add_theme_constant_override("separation",12)
 column.add_child(story)
 for field in ["section","title","body"]:
  var label := Label.new()
  label.text = str(article[field])
  label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.add_theme_font_override("font",PopupSkin.font(field == "title"))
  label.add_theme_font_size_override("font_size",28 if field == "title" and lead else 22 if field == "title" else 18 if field == "body" and lead else 16 if field == "body" else 14)
  label.add_theme_color_override("font_color",PopupSkin.NEWS_MUTED if field == "section" else PopupSkin.NEWS_INK)
  if field == "body":
   label.add_theme_constant_override("line_spacing",8)
  story.add_child(label)
 var divider := ColorRect.new()
 divider.color = Color(PopupSkin.NEWS_RULE,0.55)
 divider.custom_minimum_size.y = 1
 divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
 story.add_child(divider)

func refresh() -> void:
 if state == null or articles_column == null:
  return
 masthead.text = "%s商报" % state.economy.city_name()
 dateline.text = "第 %d 天  ·  %s" % [state.day,state.economy.market_name()]
 for column in [articles_column,local_column]:
  for child in column.get_children():
   column.remove_child(child)
   child.queue_free()
 var articles: Array[Dictionary] = state.economy.news_articles(state.day)
 if articles.is_empty():
  articles.append({"section":"本城新闻","title":"市集照常开张","body":"晨钟响过，摊主陆续支起棚子，往来的商车在城门边歇脚。街上还没有传来新的大事，人们正忙着各自的营生。"})
 for article in articles:
  _article(articles_column,article,true)
 for article in state.economy.local_dispatches():
  _article(local_column,article)
 travel_notice.text = "商路通告\n班车已到城门，收摊后可启程。" if state.economy.can_travel(state.day) else "商路通告\n每逢周期末，班车往返两城。"
 travel_button.text = "前往%s · %d G" % [state.economy.other_city_name(),state.economy.TRAVEL_COST]
 travel_button.visible = state.can_travel()
