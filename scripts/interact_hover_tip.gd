extends Control
## Shared scene labels and reference-based item information cards.
## The chrome is kept as a runtime layer so the same interaction treatment can
## be reused without baking text into any artwork.

const TIP_SIZE := Vector2(180, 48)
const ITEM_TIP_SIZE := Vector2(396, 520)
const ROOT_PADDING := Vector2(14, 18)
const TOPMOST_Z := 4096
const SHOW_SCALE_TIME := 0.16
const SHOW_FADE_TIME := 0.10
const HIDE_SCALE_TIME := 0.10
const HIDE_FADE_TIME := 0.08
const Chrome = preload("res://scripts/popup_style.gd")
const BLACK = Chrome.BACKGROUND
const WHITE = Chrome.TEXT

var motion_panel: Control
var panel: Panel
var label: Label
var body_label: Label
var bold_font: SystemFont
var tween: Tween
var current_key := ""
var card_signature := 0
var item_card: Control
var market_label: Label
var purchase_label: Label
var quantity_label: Label
var stat_labels: Array[Label] = []

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 z_index = TOPMOST_Z
 bold_font = Chrome.font(true)

 motion_panel = Control.new()
 motion_panel.name = "PanelMotion"
 motion_panel.position = Vector2.ZERO
 motion_panel.size = TIP_SIZE
 motion_panel.pivot_offset = Vector2(0, TIP_SIZE.y)
 motion_panel.rotation_degrees = 0.0
 motion_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(motion_panel)

 panel = Panel.new()
 panel.name = "Panel"
 panel.size = TIP_SIZE
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel", _panel_style())
 motion_panel.add_child(panel)

 label = Label.new()
 label.name = "Label"
 label.position = Vector2(14, 4)
 label.size = Vector2(TIP_SIZE.x - 28, TIP_SIZE.y - 8)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size", 16)
 label.add_theme_font_override("font", bold_font)
 label.add_theme_color_override("font_color", WHITE)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(label)
 hide()

func _panel_style() -> StyleBoxFlat:
 return Chrome.panel()

func _card_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, centered := false) -> Label:
 var node := Label.new()
 node.text = text_value
 node.position = rect.position
 node.size = rect.size
 node.add_theme_font_override("font",Chrome.font(font_size >= 20))
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",color)
 node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
 node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func _card_panel(parent: Control, rect: Rect2, fill: Color, edge: Color, radius := 6) -> Panel:
 var node := Panel.new()
 node.position = rect.position
 node.size = rect.size
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_theme_stylebox_override("panel",Chrome.box(fill,edge,radius))
 parent.add_child(node)
 return node

func show_item(key: String, data: Dictionary, texture: Texture2D, screen_pos: Vector2) -> void:
 var signature := hash(data)
 if current_key == key and visible and card_signature == signature:
  return
 card_signature = signature
 if current_key == key:
  current_key = ""
 # Reuse the same positioning, animation and hide lifecycle as scene tips.
 show_tip(key,str(data.name),screen_pos,false)
 label.hide()
 if body_label != null:
  body_label.queue_free()
  body_label = null
 if item_card != null:
  panel.remove_child(item_card)
  item_card.queue_free()
 item_card = Control.new()
 item_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(item_card)
 stat_labels.clear()
 var width := ITEM_TIP_SIZE.x
 var description: String = str(data.description)
 var line_count := 0
 for line in description.split("\n"):
  line_count += maxi(1,ceili(Chrome.font().get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x/(width-48)))
 var description_height := maxi(48,line_count*26)
 var stats_y := 356+description_height
 var height: int = stats_y+40+data.stats.size()*36+20
 var target_size := Vector2(width,height)
 size = target_size+ROOT_PADDING
 motion_panel.size = target_size
 motion_panel.pivot_offset = Vector2(0,height)
 panel.size = target_size
 item_card.size = target_size
 var image_panel := _card_panel(item_card,Rect2(20,20,width-40,148),Color("180f0b"),Chrome.FRAME,8)
 var image := preload("res://scripts/quality_icon.gd").new()
 image.quality = int(data.get("quality",-1))
 image.texture = texture
 image.position = Vector2(62,12)
 image.size = Vector2(width-164,124)
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 image_panel.add_child(image)
 var badge := _card_panel(item_card,Rect2(width-110,28,80,28),Chrome.PANEL_ALT,Chrome.FRAME)
 quantity_label = _card_label(badge,"数量：%d" % data.quantity,Rect2(0,0,80,28),14,Chrome.TEXT,true)
 _card_label(item_card,str(data.name),Rect2(20,180,width-40,38),28,Chrome.HEADER_TEXT,true)
 var slot_width := (width-48)/2
 var market := _card_panel(item_card,Rect2(20,230,slot_width,48),Chrome.PANEL_ALT,Chrome.FRAME)
 var purchase := _card_panel(item_card,Rect2(28+slot_width,230,slot_width,48),Chrome.PANEL_ALT,Chrome.FRAME)
 _card_label(market,"当前市场价格",Rect2(0,2,slot_width,20),14,Chrome.MUTED,true)
 market_label = _card_label(market,"%d G" % int(data.market_price),Rect2(0,22,slot_width,24),16,Chrome.HEADER_TEXT,true)
 _card_label(purchase,"购入价格",Rect2(0,2,slot_width,20),14,Chrome.MUTED,true)
 purchase_label = _card_label(purchase,"—" if data.purchase_price == null else "%d G" % int(data.purchase_price),Rect2(0,22,slot_width,24),16,Chrome.HEADER_TEXT,true)
 body_label = _card_label(item_card,description,Rect2(24,292,width-48,description_height),16,Chrome.TEXT,true)
 body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var types_y := 304+description_height
 _card_panel(item_card,Rect2(20,types_y,width-40,1),Chrome.DIVIDER,Color.TRANSPARENT,0)
 _card_label(item_card,"类型",Rect2(20,types_y+8,100,24),14,Chrome.MUTED)
 var tag_x := 20.0
 for index in range(data.tags.size()):
  var tag: String = data.tags[index]
  var tag_width := maxf(64,Chrome.font().get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+24)
  var tag_panel := _card_panel(item_card,Rect2(tag_x,types_y+36,tag_width,30),Color("183321") if index == 0 else Color("442b17"),Chrome.SUCCESS if index == 0 else Chrome.FRAME)
  _card_label(tag_panel,tag,Rect2(0,0,tag_width,30),16,Chrome.SUCCESS.lightened(0.2) if index == 0 else Chrome.HEADER_TEXT,true)
  tag_x += tag_width+8
 # Type section ends before the detailed numeric rows.
 stats_y = types_y+82
 if not data.stats.is_empty():
  _card_panel(item_card,Rect2(20,stats_y,width-40,1),Chrome.DIVIDER,Color.TRANSPARENT,0)
  _card_label(item_card,"详细数值",Rect2(20,stats_y+8,width-40,24),14,Chrome.MUTED)
 var row_y: int = stats_y if data.stats.is_empty() else stats_y+40
 var row_step := 26 if stats_y+40+data.stats.size()*36+20 > 760 else 36
 for stat in data.stats:
  var row := _card_panel(item_card,Rect2(20,row_y,width-40,row_step-4),Color("211710"),Chrome.SUCCESS.darkened(0.25))
  _card_label(row,str(stat.label),Rect2(10,0,140,row_step-4),16,Chrome.TEXT)
  var value := _card_label(row,str(stat.value),Rect2(146,0,width-196,row_step-4),16,Chrome.SUCCESS)
  value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  stat_labels.append(value)
  row_y += row_step
 panel.size.y = row_y+20
 item_card.size = panel.size
 motion_panel.size.y = panel.size.y
 size.y = panel.size.y+ROOT_PADDING.y
 motion_panel.pivot_offset = Vector2(0,panel.size.y)
 position = _tip_position(screen_pos,panel.size,true)

func show_tip(key: String, text_value: String, screen_pos: Vector2, tilted := true, body_text := "", tip_z := TOPMOST_Z, side := 1.0, target_rect := Rect2(), alignment := "") -> void:
 if current_key == key and visible:
  return
 if tween:
  tween.kill()
 current_key = key
 label.show()
 if item_card != null:
  item_card.hide()
 z_index = tip_z
 var item_tip := body_text != ""
 var target_size := ITEM_TIP_SIZE if item_tip else TIP_SIZE
 if item_tip:
  var body_font := Chrome.font()
  var lines := 0
  for line_text in body_text.split("\n"):
   lines += maxi(1,ceili(body_font.get_string_size(line_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/(target_size.x-28)))
  target_size.y = maxf(target_size.y,60+lines*22)
 var root_size := target_size + ROOT_PADDING
 size = root_size
 motion_panel.size = target_size
 motion_panel.pivot_offset = Vector2(0, target_size.y)
 motion_panel.rotation_degrees = 0.0
 panel.size = target_size
 label.text = text_value
 label.position = Vector2(14, 5) if item_tip else Vector2(14, 4)
 label.size = Vector2(target_size.x - 28, 30 if item_tip else target_size.y - 8)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if item_tip else HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size", 16 if item_tip else 17)
 if body_label != null and body_label.get_parent() != panel:
  body_label.get_parent().remove_child(body_label)
  panel.add_child(body_label)
 if body_label == null:
  body_label = Label.new()
  body_label.name = "Body"
  body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  panel.add_child(body_label)
 body_label.visible = item_tip
 if item_tip:
  body_label.text = body_text
  body_label.position = Vector2(14, 39)
  body_label.size = Vector2(target_size.x - 28, target_size.y - 46)
  body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
  body_label.add_theme_font_override("font",Chrome.font())
  body_label.add_theme_font_size_override("font_size", 14)
  body_label.add_theme_color_override("font_color", Chrome.MUTED)
 position = _tip_position(screen_pos,target_size,item_tip,side,target_rect,alignment)
 show()
 motion_panel.scale = Vector2(0.18, 0.82)
 motion_panel.modulate.a = 0.0
 tween = create_tween()
 tween.set_parallel(true)
 tween.tween_property(motion_panel, "scale", Vector2.ONE, SHOW_SCALE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_property(motion_panel, "modulate:a", 1.0, SHOW_FADE_TIME)

func hide_tip(key := "") -> void:
 if key != "" and current_key != key:
  return
 if not visible:
  current_key = ""
  return
 if tween:
  tween.kill()
 current_key = ""
 tween = create_tween()
 tween.set_parallel(true)
 tween.tween_property(motion_panel, "scale", Vector2(0.7, 0.9), HIDE_SCALE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_property(motion_panel, "modulate:a", 0.0, HIDE_FADE_TIME)
 tween.chain().tween_callback(func():
  if current_key == "":
   hide()
 )

func _tip_position(screen_pos: Vector2, target_size: Vector2, item_tip: bool, side := 1.0, target_rect := Rect2(), alignment := "") -> Vector2:
 var horizontal_offset := -target_size.x * 0.10 if side > 0.0 else -target_size.x * 0.90
 var desired := screen_pos + (Vector2(20, 18) if item_tip else Vector2(horizontal_offset, -target_size.y * 0.70))
 if item_tip and desired.x+target_size.x > get_viewport_rect().size.x-8:
  desired.x = screen_pos.x-target_size.x-20
 if not target_rect.has_area():
  return desired.clamp(Vector2(8, 8), get_viewport_rect().size - size - Vector2(8, 8))
 if alignment == "vertical_center":
  desired.y = target_rect.position.y + (target_rect.size.y - target_size.y) * 0.5
 elif alignment == "horizontal_center":
  desired.x = target_rect.position.x + (target_rect.size.x - target_size.x) * 0.5
 var viewport_size := get_viewport_rect().size
 return desired.clamp(Vector2(8, 8), viewport_size - size - Vector2(8, 8))
