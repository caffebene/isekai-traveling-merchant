extends Node2D

# Physics and artwork share the same local pixel coordinates.
const LAYER := 1 << 16
var bodies: Dictionary = {}
var shapes: Dictionary = {}
var contact_material := PhysicsMaterial.new()

func setup(surface: Rect2) -> void:
	contact_material.bounce = 0.0
	contact_material.friction = 0.65
	var baseline := surface.position.y
	for rect in [Rect2(surface.position.x, baseline, surface.size.x, 100),
			Rect2(surface.position.x-40, -1000, 40, baseline+1100),
			Rect2(surface.end.x, -1000, 40, baseline+1100)]:
		var wall := StaticBody2D.new()
		wall.collision_layer = LAYER
		wall.collision_mask = LAYER
		wall.physics_material_override = contact_material
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		wall.position = rect.get_center()
		wall.add_child(collision)
		add_child(wall)

func geometry(key: String, texture: Texture2D, size: Vector2) -> Dictionary:
	if shapes.has(key):
		return shapes[key]
	var bitmap := BitMap.new()
	var image := texture.get_image()
	bitmap.create_from_image_alpha(image, 0.18)
	var polygons: Array[PackedVector2Array] = []
	for outline in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 2.0):
		var polygon := PackedVector2Array()
		for point in outline:
			polygon.append(point/Vector2(image.get_size())*size-size*0.5)
		if polygon.size() >= 3:
			polygons.append(polygon)
	# Use the visible pixel area for the center of mass, not the grid center.
	var centroid := Vector2.ZERO
	var count := 0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			if bitmap.get_bit(x,y):
				centroid += (Vector2(x+0.5,y+0.5)/Vector2(image.get_size())-Vector2.ONE*0.5)*size
				count += 1
	var result := {"polygons":polygons, "center":centroid/maxi(count,1), "mass":maxf(float(count)*4.0/float(image.get_width()*image.get_height())*size.x*size.y/2400.0,0.2)}
	shapes[key] = result
	return result

func remove_item(id: int) -> void:
	if not bodies.has(id):
		return
	var body: RigidBody2D = bodies[id]
	bodies.erase(id)
	remove_child(body)
	body.queue_free()
	# Removing a supporting item must wake the remaining pile.
	for remaining: RigidBody2D in bodies.values():
		remaining.sleeping = false

func sync(items: Array[Dictionary], drag_id: int, textures: Dictionary, catalog: Dictionary, cell: Vector2) -> void:
	var active: Dictionary = {}
	for item in items:
		if item.id != drag_id:
			active[item.id] = true
	for id in bodies.keys():
		if not active.has(id):
			remove_item(id)
	for item in items:
		if item.id == drag_id:
			continue
		if not bodies.has(item.id):
			var body := RigidBody2D.new()
			body.collision_layer = LAYER
			body.collision_mask = LAYER
			body.physics_material_override = contact_material
			body.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
			body.gravity_scale = 1800.0/float(ProjectSettings.get_setting("physics/2d/default_gravity",980.0))
			body.linear_damp = 0.8
			body.angular_damp = 1.5
			var data := geometry(item.key,textures[item.key],Vector2(catalog[item.key].size)*cell)
			body.mass = data.mass
			body.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
			body.center_of_mass = data.center
			for polygon in data.polygons:
				var collision := CollisionPolygon2D.new()
				collision.polygon = polygon
				body.add_child(collision)
			body.position = item.counter_position
			body.rotation = float(item.counter_angle)+(PI/2.0 if item.rotated else 0.0)
			body.linear_velocity = item.counter_velocity
			body.angular_velocity = item.counter_angular_velocity
			add_child(body)
			bodies[item.id] = body
		var body: RigidBody2D = bodies[item.id]
		item.counter_position = body.position
		item.counter_angle = body.rotation-(PI/2.0 if item.rotated else 0.0)
		item.counter_velocity = body.linear_velocity
		item.counter_angular_velocity = body.angular_velocity
		item.counter_sleeping = body.sleeping
