extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAILED: " + message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var shop = load("res://main.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	check(shop.dialogue_active,"dialogue frame opens with the customer conversation")
	check(shop.dialogue_background.visible,"dialogue frame texture is visible")
	check(shop.dialogue_prev_button.visible and shop.dialogue_next_button.visible,"dialogue navigation buttons are visible")
	for n in range(10):
		shop._advance_dialogue(10.0)
	check(shop.dialogue_active and not shop.dialogue_playing,"dialogue frame remains open after the last line")
	check(shop.dialogue_line_index == shop.dialogue_lines.size()-1,"dialogue ends on the last line")
	check(shop.dialogue_next_button.disabled,"next button disables at the last line")
	check(not shop.dialogue_prev_button.disabled,"previous button remains available for browsing")
	shop.dialogue_prev_button.emit_signal("pressed")
	check(shop.dialogue_line_index == shop.dialogue_lines.size()-2,"previous button browses to the previous line")
	shop.dialogue_next_button.emit_signal("pressed")
	check(shop.dialogue_line_index == shop.dialogue_lines.size()-1,"next button browses forward without closing the frame")
	shop._start_conversation(["这是一段需要被限制在对话框黑色内容区内的较长测试对白。"])
	shop._advance_dialogue(10.0)
	check(shop.dialogue_text_label.text.contains("\n"),"long dialogue text wraps inside the content area")
	shop._clear_dialogue()
	check(not shop.dialogue_active and not shop.dialogue_background.visible,"clearing the customer hides the dialogue frame")
	print("PASS: %d dialogue checks" % checks if failures == 0 else "FAIL: %d dialogue checks (%d failures)" % [checks,failures])
	quit(1 if failures else 0)
