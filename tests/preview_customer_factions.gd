extends SceneTree
var shop
var samples: Array=[]
func _initialize() -> void:
	run.call_deferred()
func capture(label_value: String) -> void:
	shop._sync(); shop.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/testing/previews/unified-ui/46-customers-%s-%dx%d.png" % [label_value,root.size.x,root.size.y])
func stage_item(key: String, owner: String) -> void:
	shop.state.add_item(key,"stock" if owner=="player" else "customer",owner,"stock",0)
	var item: Dictionary=shop.state.items.back()
	assert(shop.state.move_item_to_counter(item.id,Vector2(600,400),item.rotated)=="")
func run() -> void:
	shop=load("res://main.tscn").instantiate(); root.add_child(shop); await process_frame
	shop.set_process(false); shop.customer_rng.seed=81
	var names := ["sylvie","leon","aya","brock","olin","mila","nora","sparrow","herbert","eve"]
	# Direct selections cover portraits; no claim that locked people arrived unearned.
	for index in range(shop.CUSTOMERS.size()):
		shop.customer_index=index; shop._apply_customer_profile(); shop._start_customer_conversation()
		shop._set_dialogue_line(0,true)
		var p: Dictionary=shop.customer_profile
		samples.append({"name":p.name,"faction":p.faction,"goods":p.goods,"funds":p.funds})
		await capture(names[index])
	shop.customer_index=0; shop._apply_customer_profile(); shop._start_customer_conversation()
	assert(not shop.dialogue_lines.has(shop.ForestStory.REQUEST_LINE))
	stage_item("herb","player"); shop._settle(); shop._set_dialogue_line(1,true)
	assert(shop.state.story_progress.stage=="requested")
	await capture("sylvie-request-after-trade")
	shop.customer_index=3; shop._apply_customer_profile()
	shop.state.items=shop.state.items.filter(func(i): return i.owner!="customer")
	shop.state.customer_goods.assign(["ore"])
	shop.state.gold=1000
	for n in range(3): stage_item("ore","customer")
	shop._settle(); shop._set_dialogue_line(0,true)
	assert(shop.state.customer_memory.unlocks.foreman)
	await capture("foreman-introduction")
	shop.customer_index=5; shop._apply_customer_profile()
	for n in range(3): stage_item("bread","player")
	shop._settle(); shop._set_dialogue_line(0,true)
	assert(shop.state.customer_memory.unlocks.supper)
	await capture("supper-introduction")
	var output=FileAccess.open("res://docs/testing/previews/unified-ui/46-customer-samples.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(samples,"\t"))
	print("CUSTOMER_FACTIONS_PREVIEW: 10 portraits, earned request and 2 actual introductions")
	quit(0)
