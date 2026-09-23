extends Control
## The wagon interior, interchangeable city view, and customer portrait are separate layers.
@export var city_background: Texture2D
@export var customer_portrait: Texture2D
@onready var exterior: TextureRect = $Window/Exterior
@onready var customer = $Window/Customer
var arrival_tween: Tween

func _ready() -> void:
 if city_background == null and exterior.texture != null:
  city_background = exterior.texture
 set_city(city_background)
 set_customer(customer_portrait)

func set_city(texture: Texture2D) -> void:
 city_background = texture
 exterior.texture = texture
 exterior.visible = texture != null

func set_customer(texture: Texture2D) -> void:
 customer_portrait = texture
 customer.texture = texture
 customer.visible = texture != null
 if arrival_tween:
  arrival_tween.kill()
 if texture:
  customer.modulate.a = 0.0
  arrival_tween = create_tween()
  arrival_tween.tween_property(customer,"modulate:a",1.0,0.3)

func set_time_of_day(night: bool) -> void:
 modulate = Color("777dae") if night else Color.WHITE
