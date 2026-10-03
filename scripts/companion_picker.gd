extends Panel
signal departed(id: String)
const Chrome = preload("res://scripts/popup_style.gd")
var selected := ""
var cards: Array[Button] = []
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_theme_stylebox_override("panel",Chrome.box(Chrome.SHADE,Color.TRANSPARENT))
 var panel := Panel.new()
 panel.position=Vector2(400,200); panel.size=Vector2(800,500)
 Chrome.window(panel); add_child(panel)
 var title := Label.new()
 title.text="探索同行"; title.position=Vector2(24,12); title.size=Vector2(752,32)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_override("font",Chrome.font(true)); title.add_theme_font_size_override("font_size",24)
 title.add_theme_color_override("font_color",Chrome.HEADER_TEXT); panel.add_child(title)
 for index in range(2):
  var card := Button.new()
  card.clip_contents=true
  card.position=Vector2(50+index*400,72); card.size=Vector2(300,320)
  var caption := Label.new()
  caption.text="独自探索" if index==0 else "希尔薇 · 弓援护"
  caption.position=Vector2(12,264); caption.size=Vector2(276,32)
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  caption.add_theme_font_override("font",Chrome.font(true))
  caption.add_theme_font_size_override("font_size",20)
  caption.add_theme_color_override("font_color",Chrome.HEADER_TEXT)
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(caption)
  card.alignment=HORIZONTAL_ALIGNMENT_CENTER
  card.add_theme_constant_override("outline_size",0)
  var texture := TextureRect.new()
  texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  texture.texture=load("res://assets/exploration/boisterous/merchant-idle.png" if index==0 else "res://assets/approved-layout/customer-sylvie.png")
  texture.position=Vector2(20,12); texture.size=Vector2(260,230)
  texture.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(texture)
  card.pressed.connect(func(): select("" if index==0 else "sylvie"))
  panel.add_child(card); cards.append(card)
 var depart := Button.new()
 depart.text="前往野外"; depart.position=Vector2(420,428); depart.size=Vector2(330,48)
 Chrome.button(depart,true); depart.pressed.connect(func(): departed.emit(selected)); panel.add_child(depart)
 var cancel := Button.new()
 cancel.text="返回"; cancel.position=Vector2(50,428); cancel.size=Vector2(330,48)
 Chrome.button(cancel); cancel.pressed.connect(func(): departed.emit("cancel")); panel.add_child(cancel)
 select(selected)
func select(id: String) -> void:
 selected=id
 for index in range(cards.size()):
  Chrome.button(cards[index],(id=="" and index==0) or (id=="sylvie" and index==1))
func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  departed.emit("cancel"); get_viewport().set_input_as_handled()
