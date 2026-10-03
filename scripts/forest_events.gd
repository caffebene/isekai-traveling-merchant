extends RefCounted
const Extra = preload("res://scripts/forest_extra_events.gd")
const TOOL_KEYS := {"axe":["copper_axe","iron_axe","tempered_axe"],"pickaxe":["copper_pickaxe","iron_pickaxe"]}
const ROOT_WEIGHTS := {"chest":2,"mushrooms":2,"frog":2,"well":1,"logging":2,"mining":2,"camp":1,"snail":1,"hunter":1}
## Narrative definitions. Eligibility, dialogue and choices all use real expedition history.
const EVENTS := {
 "chest": {"name":"长腿宝箱", "art":"chest", "options":[
  {"id":"open", "label":"伸手打开，赌里面有点好东西", "outcomes":[{"rewards":["ore","potion"],"result":"箱底滚出了矿石和药剂。"},{"damage":12,"lose":true,"result":"箱盖咬住手腕，又吞走了一件行李。"}]},
  {"id":"feed", "label":"递块面包，先让它松松口", "item":"bread", "outcomes":[{"rewards":["ore","potion"],"result":"宝箱吃下了面包，把珍藏推给你。"}]},
  {"id":"skip", "label":"让它走开，带着行李绕过去", "outcomes":[{"result":"你绕开宝箱。身后的木头脚步没有走远。"}]}]},
 "mushrooms": {"name":"路边蘑菇丛", "art":"mushrooms", "options":[
  {"id":"collect", "label":"拨开蘑菇采草，省一点药钱", "outcomes":[{"rewards":["herb","herb"],"result":"你采下两株月光草，蘑菇丛又安静下来。"},{"rewards":["herb","herb"],"case":true,"result":"药草被拔起，连着的菌丝也掀翻了一顶小蘑菇帽。"}]},
  {"id":"observe", "label":"蹲下看看，听听那阵细声", "outcomes":[{"respect":true,"result":"你等它们说完，顺手把歪掉的小菌帽扶正。"}]},
  {"id":"skip", "label":"避开菌丝，沿着小路继续走", "outcomes":[{"result":"你从空隙跨过去，没有碰到蘑菇。"}]}]},
 "court": {"name":"蘑菇法庭", "art":"court", "options":[
  {"id":"guilty", "label":"掏点赔偿，争取把这事了结", "cost":10, "outcomes":[{"settle_case":true,"result":"你付了赔偿，蘑菇撤掉了拦路的菌丝。"}]},
  {"id":"appeal", "label":"讲清采草经过，赌法官肯听", "outcomes":[{"gold":30,"settle_case":true,"result":"法庭承认索赔过头，退还一笔赔偿。"},{"verdict":true,"settle_case":true,"result":"法官敲下木槌，派森林里的打手执行判决。"}]},
  {"id":"delay", "label":"趁书记员打盹溜走，官司以后再说", "outcomes":[{"delay_case":true,"result":"你溜出菌圈，后面传来书记员追记地址的声音。"}]}]},
 "frog": {"name":"荷叶上的青蛙", "art":"frog", "options":[
  {"id":"kiss", "label":"相信它的奇迹，闭眼亲一下", "outcomes":[{"full_heal":true,"result":"暖意顺着伤口扩散，你恢复了全部生命。"},{"wear":5,"result":"青蛙打了个嗝，湿气爬进背包，武器开始生锈。"}]},
  {"id":"fruit", "label":"递颗绯红果，请它搭把手", "item":"berry", "outcomes":[{"heal":15,"result":"青蛙收了果实，帮你处理了伤口。"}]},
  {"id":"skip", "label":"不碰这份奇迹，绕开荷叶", "outcomes":[{"result":"你从荷叶旁经过，青蛙把胡子重新粘好。"}]}]},
 "well": {"name":"会说话的许愿井", "art":"well", "options":[
  {"id":"pay", "label":"投几枚金币，听听井底的回音", "cost":20, "outcomes":[{"rewards":["power","steak"],"result":"井底送上药剂和烤肉，扣下了20G。"},{"lose":true,"rewards":["wastewater"],"result":"井收下20G，又卷走行李，只吐出一瓶浑水。"}]},
  {"id":"credit", "label":"先拿愿望，答应以后补上报酬", "outcomes":[{"rewards":["power","steak"],"debt":true,"result":"井交出药剂和烤肉，在石壁刻下你的名字。远处一根树枝朝账本伸了过来。"}]},
  {"id":"skip", "label":"把愿望留在心里，继续往前走", "outcomes":[{"result":"你没许愿。井把准备好的账本收了回去。"}]}]}
}

static func say(speaker: String, text: String) -> Dictionary:
 return {"speaker":speaker,"text":text}

static func pick_variant(id: String, choices: Array, memory: Dictionary, rng: RandomNumberGenerator) -> String:
 var pool: Array = choices.filter(func(v): return v != memory.last_variants.get(id,""))
 if pool.is_empty():
  pool = choices
 return pool[rng.randi_range(0,pool.size()-1)]

static func tool_items(kind: String, inventory, wear: int = 1) -> Array:
 if inventory == null:
  return []
 return inventory.items.filter(func(item): return item.zone == "bag" and item.owner == "player" and item.key in TOOL_KEYS.get(kind,[]) and int(item.get("durability",20)) >= wear)

static func eligible(id: String, memory: Dictionary, inventory = null) -> bool:
 if id == "hunter" and (inventory == null or inventory.story_progress.hunter_saved):
  return false
 if Extra.EVENTS.has(id):
  var definition: Dictionary = Extra.EVENTS[id]
  return not tool_items(definition.tool_required,inventory).is_empty() if definition.has("tool_required") else true
 if id == "court":
  return not memory.mushroom_case.is_empty()
 if id == "mushrooms":
  return memory.mushroom_case.is_empty()
 return EVENTS.has(id)

static func build(id: String, memory: Dictionary, rng: RandomNumberGenerator, inventory = null) -> Dictionary:
 if not eligible(id,memory,inventory):
  return {}
 if Extra.EVENTS.has(id):
  var variant: String = "warm" if id == "camp" and int(memory.get("camp_fuel",0)) > 0 else "neighbor" if id == "snail" and (int(memory.get("snail_paid",0)) >= 2 or memory.get("snail_fed",false)) else pick_variant(id,Extra.VARIANTS[id],memory,rng)
  return Extra.build(id,memory,variant)
 var event: Dictionary = EVENTS[id].duplicate(true)
 event["id"] = id
 var pages: Array = []
 var variant := ""
 match id:
  "chest":
   if int(memory.chest_refusals) >= 3:
    variant = "pursuit"
    pages = [say("旁白","熟悉的木头脚步声追了上来。它这次连落叶都没来得及甩掉。"),say("长腿宝箱","你已经赶我走%d回了！我从那棵树追到这棵树，就想问一句——" % int(memory.chest_refusals)),say("旅商","你是想被打开，还是想把我吃掉？")]
   elif int(memory.chest_refusals) > 0:
    variant = "return"
    pages = [say("旁白","你认出了先前被赶走的宝箱。它躲在树后，脚却露在外面。"),say("长腿宝箱","我走开过了。走了两步，觉得咱们还有商量的余地。")]
   elif memory.chest_fed:
    variant = "friend"
    pages = [say("旁白","那只吃过你面包的宝箱又出现了，盖子上还粘着一点面包屑。"),say("长腿宝箱","上回那顿还记着呢。我挖到点东西，你要不要看看？")]
    event.options[0].outcomes = [{"rewards":["ore","herb"],"result":"宝箱把新挖到的矿石和药草交给你。"}]
   else:
    variant = pick_variant(id,["hungry","courier","bashful"],memory,rng)
    match variant:
     "hungry":
      pages = [say("旁白","一只宝箱横在小路上。你靠近时，它从箱底伸出两条腿。"),say("长腿宝箱","先别拔剑！我只是……有点空。"),say("旅商","你说的空，是箱子里，还是肚子里？")]
     "courier":
      pages = [say("旁白","一个宝箱拖着湿透的送货单，停在你脚边。"),say("长腿宝箱","收件人：林子里第一个背大包的人。应该就是你。"),say("旅商","这收件地址写得也太省事了。")]
      event.options[0].outcomes = [{"rewards":["ore","herb"],"result":"箱子交出一份错写地址的包裹：矿石与月光草。"}]
     "bashful":
      pages = [say("旁白","宝箱盖开了一条缝。你一看过去，它又啪地合上。"),say("长腿宝箱","能帮忙开一下吗？我练了半天，还是怕生。")]
      event.options[0].outcomes = [{"rewards":["ore"],"result":"宝箱终于张开盖子，滚出一块矿石。"},{"damage":6,"result":"它紧张得夹住你的手，留下一个牙印。"}]
  "mushrooms":
   if int(memory.mushrooms_respected) >= 2:
    variant = "gift"
    event.options[0].label = "接过它们推来的草，领这份心意"
    event.options[0].outcomes = [{"rewards":["herb","herb"],"result":"蘑菇们主动把两株月光草推到你手边。"}]
    pages = [say("旁白","你又遇见那群小蘑菇。它们没有缩回土里，反而往路边挪了挪。"),say("小蘑菇","是那个会等我们说完、还帮忙扶帽子的人！"),say("旁白","两株月光草被菌丝轻轻推到你面前。")]
   else:
    variant = pick_variant(id,["quiet","moving"],memory,rng)
    if variant == "quiet":
     pages = [say("旁白","路边长着一丛蘑菇，两株月光草挤在菌帽之间。"),say("旁白","你俯身时，下面传来极细的声音，像是在数屋顶漏了几滴水。")]
    else:
     pages = [say("旁白","这丛蘑菇正在慢慢搬家，菌丝拖着两株月光草。旁边的荷叶下露出一双绿眼睛。"),say("小蘑菇","小点声！房顶已经绑好了，别把上面的草扯掉！")]
  "court":
   variant = "witness" if memory.frog_testimony else "roof"
   var incident: String = memory.mushroom_case.get("description","采草时扯翻了一顶菌帽")
   pages = [say("旁白","菌丝拦住小路，蘑菇们抬来木槌。你认出了%s时见过的那顶小帽子。" % memory.mushroom_case.get("place","采草")),say("蘑菇法官","案由：%s。被告就是这位背包旅商。" % incident),say("旅商","原来那天的声音，真的不是风。")]
   if memory.frog_testimony:
    pages.append(say("荷叶证词","青蛙的证词写得歪歪扭扭：采的是药草，房顶是菌丝自己缠上去的。"))
    event.options[1].label = "递上青蛙证词，把经过讲清楚"
    event.options[1].outcomes[0]["weight"] = 3
    event.options[1].outcomes[1]["weight"] = 1
   if int(memory.court_delays) > 0:
    pages.append(say("蘑菇书记员","上回你从左边跑的。这回左边已经补了菌丝。"))
  "frog":
   if not memory.mushroom_case.is_empty() and memory.mushroom_case.get("witness","") == "frog" and not memory.frog_testimony:
    variant = "witness"
    pages = [say("旁白","青蛙坐在荷叶上。你想起采草那天，也是这双绿眼睛躲在叶子下面。"),say("旅商","你当时看见了吧？药草和蘑菇帽是怎么缠上的？"),say("青蛙","看见了。不过本仙说话多，嘴容易干。")]
    event.options[0].label = "先请它治伤，证词的事之后再说"
    event.options[1].label = "递颗绯红果，请它把实情写下来"
    event.options[1].outcomes = [{"testimony":true,"result":"青蛙收下果实，写好一张关于采草经过的证词。"}]
   else:
    variant = pick_variant(id,["healer","repairer"],memory,rng)
    if variant == "healer":
     pages = [say("旁白","一只贴着白胡子的青蛙坐在荷叶上，正给自己擦药。"),say("青蛙","本仙今天值治伤科。伤口、酸痛，还有一点点奇迹。"),say("旅商","你自己的药，怎么涂在胡子上？")]
    else:
     pages = [say("旁白","青蛙拿着一片生锈的铁片，敲得荷叶直晃。"),say("青蛙","今天轮到器械科了。会不会修是一回事，值不值班是另一回事。")]
     event.options[0].label = "把武器交给它，赌一回维修手艺"
     event.options[0].outcomes = [{"repair":5,"result":"青蛙吹干了潮气，背包里的武器恢复了一些耐久。"},{"wear":5,"result":"青蛙敲错了地方，武器又添了几道缺口。"}]
   if int(memory.visits.get(id,0)) > 0 and variant != "witness":
    var previous: String = memory.last_actions.get(id,"")
    pages.insert(1,say("青蛙","上回你从荷叶旁绕过去了，今天终于肯停下了？" if previous == "skip" else "上回那颗绯红果挺甜。今天想看哪一科？" if previous == "fruit" else "上回的手艺先别评价，今天值的是另一科。"))
  "well":
   if memory.well_debt:
    variant = "unpaid"
    pages = [say("旁白","井口翻出一本账册，第一页就写着你的名字。"),say("许愿井","你上回先拿了愿望，还没补报酬。今天是来结账的吗？"),say("旁白","井后的树影动了一下。那根枝条像一只伸出来讨钱的手。")]
    event.options[0].label = "再投几枚金币，赌这次愿望靠谱"
    event.options[1] = {"id":"repay","label":"补上先前的报酬，试着撤掉追索","cost":20,"outcomes":[{"repay":true,"result":"你补上20G。井划掉名字，催收的树影退回林中。"}]}
   else:
    variant = pick_variant(id,["hungry","echo"],memory,rng)
    if variant == "hungry":
     pages = [say("旁白","井口的石缝张成了一张嘴。你一靠近，它就闻了闻背包。"),say("许愿井","有想要的东西吗？先把响的放下来，重的也行。"),say("旅商","你是在听愿望，还是在估行李的价？")]
    else:
     pages = [say("旁白","你探头看井，井底慢半拍地重复了你的动作和声音。"),say("许愿井","今天回声当班。说错愿望，吐出来的东西可不能怪我。")]
     event.options[0].outcomes = [{"rewards":["herb","power"],"result":"回声把愿望听岔了，送上药草和力量药剂，扣下20G。"},{"rewards":["wastewater"],"result":"你付了20G。井底只回了一瓶浑水，没有卷走行李。"}]
 event["variant"] = variant
 event["dialogue"] = pages
 return event

static func outcome(option: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
 var total := 0
 for result in option.outcomes:
  total += int(result.get("weight",1))
 var roll := rng.randi_range(0,total-1)
 for result in option.outcomes:
  roll -= int(result.get("weight",1))
  if roll < 0:
   return result.duplicate(true)
 return {}
