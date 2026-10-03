extends RefCounted
## Cross-loop facts live on the shared store; possession is never quest completion.
const REQUEST_LINE := "你要是从月蚀古树王那里拿到月蚀树心，能带回来卖给我吗？"
static func customer_lines(store, name_value: String, fallback: Array) -> Array:
	if name_value == "希尔薇":
		match store.story_progress.stage:
			"none":
				if store.story_progress.get("request_available",false):
					return ["谢谢，材料我收下了。有件事想托你帮忙，你最近还会进森林吗？",REQUEST_LINE,"我一直没找到母亲走过的那条路。听说树心能照出路上的记号，我想试一试。"]
			"requested":
				return ["树心的事不急。你别为了赶回来，摸黑走那段路。","带回来的材料我照样收。先把今天的账算清。"]
			"delivered", "rescued":
				return ["树心昨晚亮了。路找到了，可那头空心鹿还守着。","你去的时候等我一下。我收拾好药和弓，跟在后面。"]
			"victory_pending":
				return ["那晚走得急，还有些话没说。下次进林子，我们再聊吧。"]
			"recruited":
				return ["今天来补些材料。弓弦也换好了。","下次出门记得喊我，别又自己先走。"]
	return fallback
static func hear_line(store, name_value: String, line: String) -> void:
	if name_value == "希尔薇" and line == REQUEST_LINE and store.story_progress.stage == "none" and store.story_progress.get("request_available",false):
		store.story_progress.stage = "requested"
static func sold(store, customer: String, batch: Array) -> void:
	if customer == "希尔薇" and store.story_progress.stage == "none":
		store.story_progress.request_available = true
	if customer == "希尔薇" and store.story_progress.stage == "requested" and batch.any(func(i): return i.key == "moonheart"):
		store.story_progress.stage = "delivered"
static func quest_boss_pending(store) -> bool:
	return store.story_progress.stage in ["delivered","rescued"]
static func can_select(store, id: String) -> bool:
	return id == "" or (id == "sylvie" and store.story_progress.stage == "recruited")
static func victory_lines() -> Array:
	return [{"speaker":"希尔薇","text":"别急着站起来，手还抖着呢。我去看看那条路。"},{"speaker":"旅商","text":"等一下……刚才那瓶药的钱，我好像还没付。"},{"speaker":"希尔薇","text":"这时候还算账？先欠着。下次带我一起走，就当还了。"}]
