extends RefCounted
## Authored people, weighted arrivals and facts from completed trades.
const FACTIONS = {
	"forest":"森林守望", "craft":"炉桥工班", "town":"南门街坊",
	"watch":"巡夜队", "night":"夜路行会"
}
const PEOPLE = [
	{"name":"希尔薇","role":"森林采集者","faction":"forest","portrait":"res://assets/approved-layout/customer-sylvie.png","buy_category":"材料","pool":[],"count":[0,0],"funds":[110,150],"weight":3,"city":"windrest",
		"greetings":[["篮子放这儿行吗？底上有泥，我垫块布。","收些草叶和果子。今早那片林子，连鸟都没叫。"],["今天没采到什么。草根底下全是蚂蚁。","你这儿有新鲜材料吗？我挑一点带走。"]],
		"return":["又碰上你了。车轮上的泥还没干，刚回来？","我收材料。上回那批没发霉，这次还找你。"],"thanks":["这些材料我收下了，谢谢你。"]},
	{"name":"莱昂","role":"旅剑士","faction":"watch","portrait":"res://assets/customers/knight.png","buy_category":"武器","pool":["sword","sword","copper_sword"],"count":[1,2],"funds":[140,190],"weight":2,"city":"windrest",
		"greetings":[["这把剑是旧的，先说清楚。拿它砍过柴。","我也看看你的武器，缺口别藏在鞘里就行。"],["路上替人押了趟货。钱没多少，手倒磨破了。","有趁手的刀剑吗？带来的这几件也能换。"]],
		"return":["还认得我？上回那把剑还在，没拿去换酒。","今天想换点装备。照老规矩，先看刃口。"],"thanks":["这些武器我收下了，回去慢慢试。"]},
	{"name":"绫叶","role":"草药师","faction":"forest","portrait":"res://assets/customers/apothecary.png","buy_category":"药剂","pool":["herb","herb","berry"],"count":[1,3],"funds":[150,200],"weight":2,"city":"windrest",
		"greetings":[["药瓶借我对着灯看看。别晃，沉底的也要看。","我带了些草叶。药剂不够，得从你这儿补。"],["学徒把两篮草混一起了，我分了半天。","这些挑过了。你要是有药剂，也让我看看。"]],
		"return":["上回的瓶塞挺紧。我走回去，一滴没漏。","今天还是收药剂。草叶也带了一小包。"],"thanks":["药剂我收好了，谢谢。店里正好需要补些货。"]},
	{"name":"布洛克","role":"矿石商人","faction":"craft","portrait":"res://assets/customers/miner.png","buy_category":"","pool":["ore","ore","copper_ore","copper_ore","slime_mucus","ancient_wood"],"count":[3,6],"funds":[100,130],"weight":3,"city":"ironvale",
		"greetings":[["别帮我抬，箱扣松了。掉出来砸脚可不赔。","矿石和炉料都在这儿，你自己挑。"],["这批是今天下井带出来的，灰还没拍干净。","按块算。你买回去怎么烧，我不插嘴。"]],
		"return":["又来卸货。你上回收的那批，炉子吃得下吧？","工头赫伯特催着修支架，我还得赶回去。"],"thanks":["货我收下了，钱你点一下。"]},
	{"name":"奥林","role":"森林猎人","faction":"forest","portrait":"res://assets/exploration/boisterous/hunter-customer.png","buy_category":"药剂","pool":["meat","meat","berry"],"count":[1,3],"funds":[120,160],"weight":2,"city":"windrest","unlock":"hunter",
		"greetings":[["是你啊。腿能使劲了，就是下雨还疼。","那天的药我记着。带了些猎获，你看看。"],["今早走得慢，兔子都不拿正眼瞧我。","收了点别的。也想再买瓶药，省得拖累人。"]],
		"return":["绷带换过了，别瞪我。今天没往深处走。","带点肉来换药。伤好了也得留一瓶。"],"thanks":["药我收好了。有药备着，进林子也踏实些。"]},
	{"name":"米菈","role":"客栈掌厨","faction":"town","portrait":"res://assets/customers/mila.png","buy_category":"食物","pool":["meat","berry","bread"],"count":[1,3],"funds":[100,150],"weight":3,"city":"windrest",
		"greetings":[["锅还在火上，我就出来一会儿。","收面包和熟肉。别拿生的糊弄我，今晚来不及做。"],["住客嫌早饭太硬，他自己牙掉了一半。","有软点的口粮吗？厨房剩的原料也拿来卖。"]],
		"return":["上回的饭送到南门了。有人连纸袋都舔。","伊芙还在给晚归的人留饭，我再买些熟食。"],"thanks":["吃的我收下了，谢谢。我得赶回去准备晚饭了。"]},
	{"name":"诺拉","role":"巡夜队长","faction":"watch","portrait":"res://assets/customers/nora.png","buy_category":"武器","pool":["potion","bread"],"count":[1,2],"funds":[150,200],"weight":2,"city":"windrest",
		"greetings":[["剑给我看看。新来的小子拿缺口对着自己练。","得换几件装备。带的补给多了些，你要就算便宜点。"],["昨晚铃响三次，两次是猫。第三次真有狼。","先看武器吧。人手不够，家伙不能再凑合。"]],
		"return":["昨晚没人挂彩。那小子终于知道握哪头了。","还收武器，备用的也行。"],"thanks":["武器我收下了，回去就发给队员们。"]},
	{"name":"阿雀","role":"夜路跑腿","faction":"night","portrait":"res://assets/customers/sparrow.png","buy_category":"药剂","pool":["slime_mucus","ancient_wood","copper_ore"],"count":[1,3],"funds":[110,170],"weight":1,"city":"ironvale",
		"greetings":[["别叫我小偷。我是跑腿的，鞋都跑开胶了。","这些炉料有货主，只是货主不想自己搬。要吗？"],["灯留着，别照我脸。一夜没睡，难看。","收点药剂。走夜路的人，不全靠胆子。"]],
		"return":["认得我就好。这次走正门，鞋上少点泥。","有力量药剂吗？护送车卡在坡底，得有人推。"],"thanks":["药剂我收好了，谢谢。这趟路上正好用得着。"]},
	{"name":"赫伯特","role":"矿队工头","faction":"craft","portrait":"res://assets/customers/herbert.png","buy_category":"燃料","pool":["ore","copper_ore"],"count":[2,4],"funds":[150,200],"weight":2,"city":"ironvale","unlock":"foreman",
		"greetings":[["布洛克说你收货痛快，让我来这儿。","支架该换了。矿材我有，缺烧得住的炉料。"],["昨天停了半班，没人往松支架底下钻。","得赶紧补好。收古木和粘液，带了矿石来换。"]],
		"return":["那段支架换上了。夜班的人敢往里走了。","剩下的也得修，再收些炉料。"],"thanks":["炉料我收下了，谢谢。我得赶紧带回去，工人们还等着呢。"]},
	{"name":"伊芙","role":"南门互助会","faction":"town","portrait":"res://assets/customers/eve.png","buy_category":"食物","pool":["herb","berry"],"count":[1,3],"funds":[100,140],"weight":2,"city":"windrest","unlock":"supper",
		"greetings":[["米菈说她买的饭是你供的，我来认个门。","南门还有几个人没领到。能再匀些熟食吗？"],["那个总说不饿的老人，昨晚吃了两份。","我带了院子里的草和果子。卖了钱好添晚饭。"]],
		"return":["桌子添了一张。孩子非要坐在外头，说能看马。","今晚照旧，有面包和熟肉我都收。"],"thanks":["谢谢，我这就把吃的送过去。"]}
]

static func memory(store) -> Dictionary:
	if store.customer_memory.is_empty():
		store.customer_memory = {"draw":0,"last":{},"visits":{},"affinity":{},"supplied":{},"unlocks":{},"credited":{},"announced":{},"visit_serial":0}
	return store.customer_memory

static func eligible(store, p: Dictionary) -> bool:
	var m := memory(store)
	match str(p.get("unlock","")):
		"hunter": return bool(store.story_progress.hunter_saved)
		"foreman": return bool(m.unlocks.get("foreman",false))
		"supper": return bool(m.unlocks.get("supper",false))
	return true

static func draw(store, rng: RandomNumberGenerator, previous: int = -1) -> int:
	var m := memory(store)
	m.draw += 1
	var candidates: Array[int] = []
	for i in range(PEOPLE.size()):
		if i != previous and eligible(store,PEOPLE[i]): candidates.append(i)
	# Random traffic, with a bounded wait for every unlocked person.
	var overdue: Array[int] = candidates.filter(func(i): return int(m.draw)-int(m.last.get(PEOPLE[i].name,0)) >= PEOPLE.size()*2)
	var chosen := -1
	if not overdue.is_empty():
		overdue.sort_custom(func(a,b): return int(m.last.get(PEOPLE[a].name,0)) < int(m.last.get(PEOPLE[b].name,0)))
		chosen = overdue[0]
	else:
		var pool: Array[int] = []
		for i in candidates:
			var p: Dictionary = PEOPLE[i]
			var weight := int(p.weight) + (2 if p.city == store.economy.city_id else 0) + mini(2,int(m.affinity.get(p.faction,0))/3)
			if p.name == "希尔薇" and store.story_progress.stage in ["requested","delivered","rescued"]: weight += 2
			for n in range(weight): pool.append(i)
		chosen = pool[rng.randi_range(0,pool.size()-1)]
	m.last[PEOPLE[chosen].name] = m.draw
	return chosen

static func arrival(store, index: int, rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = PEOPLE[index].duplicate(true)
	var m := memory(store)
	m.visit_serial += 1
	m.visits[p.name] = int(m.visits.get(p.name,0))+1
	var goods: Array[String] = []
	var pool: Array = p.pool.duplicate()
	if p.name == "诺拉" and m.unlocks.get("watch_equipped",false): pool.append("iron_sword")
	if p.name == "阿雀" and m.unlocks.get("night_supply",false): pool.append_array(["ancient_wood","ancient_wood"])
	if p.name == "赫伯特" and m.unlocks.get("mine_repaired",false): pool.append("iron_sword")
	if p.name == "伊芙" and m.unlocks.get("supper_running",false): pool.append("potion")
	for n in range(rng.randi_range(p.count[0],p.count[1])):
		goods.append(pool[rng.randi_range(0,pool.size()-1)])
	p.goods = goods
	p.sell_key = "*" if not goods.is_empty() else ""
	p.funds = rng.randi_range(p.funds[0],p.funds[1])
	var variants: Array = p.greetings
	var variant := rng.randi_range(0,variants.size()-1)
	# A return line requires a real completed trade with this individual.
	var return_ready: bool = store.economy.relationship(p.name)>0
	if p.name == "绫叶": return_ready = return_ready and int(m.supplied.get("绫叶:sold:potion",0))+int(m.supplied.get("绫叶:sold:power",0))>0
	if p.name == "米菈": return_ready = return_ready and int(m.supplied.get("米菈:sold:bread",0))+int(m.supplied.get("米菈:sold:steak",0))>0
	if p.name == "诺拉": return_ready = return_ready and bool(m.unlocks.get("watch_equipped",false))
	if p.name == "赫伯特": return_ready = return_ready and bool(m.unlocks.get("mine_repaired",false))
	if p.name == "伊芙": return_ready = return_ready and bool(m.unlocks.get("supper_running",false))
	p.conversation = p["return"].duplicate() if return_ready and rng.randf()<0.5 else variants[variant].duplicate()
	return p

static func completed(store, name_value: String, sold: Array, bought: Array) -> void:
	var profiles: Array = PEOPLE.filter(func(p): return p.name==name_value)
	if profiles.is_empty(): return
	var p: Dictionary = profiles[0]
	var m := memory(store)
	if int(m.credited.get(name_value,-1)) != int(m.visit_serial):
		m.credited[name_value] = m.visit_serial
		m.affinity[p.faction] = mini(10,int(m.affinity.get(p.faction,0))+1)
	for item in sold:
		var key := name_value+":sold:"+str(item.key)
		m.supplied[key] = int(m.supplied.get(key,0))+1
	for item in bought:
		var key := name_value+":bought:"+str(item.key)
		m.supplied[key] = int(m.supplied.get(key,0))+1
	if int(m.supplied.get("布洛克:bought:ore",0))+int(m.supplied.get("布洛克:bought:copper_ore",0)) >= 3:
		m.unlocks.foreman = true
	if int(m.supplied.get("米菈:sold:bread",0))+int(m.supplied.get("米菈:sold:steak",0)) >= 3:
		m.unlocks.supper = true
	var blades := 0
	for key in store.CATALOG:
		if store.CATALOG[key].category=="武器": blades += int(m.supplied.get("诺拉:sold:"+key,0))
	if blades >= 2: m.unlocks.watch_equipped = true
	if int(m.supplied.get("阿雀:sold:power",0)) >= 2: m.unlocks.night_supply = true
	if int(m.supplied.get("赫伯特:sold:ancient_wood",0))+int(m.supplied.get("赫伯特:sold:slime_mucus",0)) >= 3:
		m.unlocks.mine_repaired = true
	if int(m.supplied.get("伊芙:sold:bread",0))+int(m.supplied.get("伊芙:sold:steak",0)) >= 3:
		m.unlocks.supper_running = true

static func thanks(store, name_value: String, bought: bool, sold: bool = false) -> Array:
	var profiles: Array = PEOPLE.filter(func(person): return person.name==name_value)
	if profiles.is_empty(): return ["钱和货都对上了，谢谢。"]
	var p: Dictionary = profiles[0]
	var m := memory(store)
	match name_value:
		"布洛克":
			if m.unlocks.get("foreman",false) and not m.announced.has("foreman"):
				m.announced.foreman = true
				return ["谢谢你收下这些矿，我也省得再跑几家。","工头赫伯特正缺炉料，我让他来找你。"]
		"米菈":
			if m.unlocks.get("supper",false) and not m.announced.has("supper"):
				m.announced.supper = true
				return ["谢谢，我先把这些吃的送去南门。","伊芙也在找人买熟食，我让她来看看。"]
		"诺拉":
			if m.unlocks.get("watch_equipped",false) and not m.announced.has("watch_equipped"):
				m.announced.watch_equipped = true
				return ["新人的武器总算凑齐了，谢谢。","队里还有几把用不上的旧剑。下次我带来，你看看要不要。"]
		"阿雀":
			if m.unlocks.get("night_supply",false) and not m.announced.has("night_supply"):
				m.announced.night_supply = true
				return ["这些力量药剂正好用得上，那辆货车还卡在坡上呢。","等我们把货送到，回程给你捎些古藤木。"]
		"赫伯特":
			if m.unlocks.get("mine_repaired",false) and not m.announced.has("mine_repaired"):
				m.announced.mine_repaired = true
				return ["炉料够了，剩下的支架也能换了。","矿队有几把备用剑。忙完这阵，我拿来给你看看。"]
		"伊芙":
			if m.unlocks.get("supper_running",false) and not m.announced.has("supper_running"):
				m.announced.supper_running = true
				return ["谢谢，明天的晚饭也有着落了。","我们还有些多出来的药剂。下次我带来卖，换点饭钱。"]
	if bought and sold:
		return [MIXED_REPLIES.get(name_value,"钱和货都对上了，谢谢。")]
	if bought:
		return [PURCHASE_REPLIES.get(name_value,"钱收到了，东西你拿好。")]
	return p.thanks.duplicate()

const PURCHASE_REPLIES = {
	"希尔薇":"钱收到了，谢谢。",
	"莱昂":"钱收到了。剑你拿好，路上小心。",
	"绫叶":"这些药材你拿好，回去早点用。",
	"布洛克":"钱收到了。以后缺矿石或炉料，再来找我。",
	"奥林":"这趟总算没白跑。东西你拿好。",
	"米菈":"东西你拿好。卖掉这些，我也能少拎点回去。",
	"诺拉":"东西你收好，我把这笔记到账上。",
	"阿雀":"钱收到了，多谢。以后有货我再来找你。",
	"赫伯特":"东西你收好。要是还缺什么，我下次再带。",
	"伊芙":"谢谢，这些钱正好拿去添些饭菜。"
}
const MIXED_REPLIES = {
	"希尔薇":"钱和货都对上了，谢谢。",
	"莱昂":"你挑的剑拿好。这些武器我也收下了，回去试试。",
	"绫叶":"药剂我收下了，药材你拿好。谢谢。",
	"布洛克":"钱和货都对上了，谢谢。",
	"奥林":"药我收下了，你买的东西也拿好。谢谢你。",
	"米菈":"你买的东西拿好，这些吃的我带回客栈。",
	"诺拉":"武器我收下了。你挑的东西也别忘了拿。",
	"阿雀":"药剂我收好了。你买的东西也拿好，钱已经算清了。",
	"赫伯特":"这些炉料我收下了，你挑的东西拿好。",
	"伊芙":"我把吃的带回去。你买的东西也收好，别落在这儿。"
}

static func intelligence(store, p: Dictionary) -> Array:
	var news: Array = store.economy.news_articles(store.day,p.name)
	if news.is_empty(): return []
	var article: Dictionary = news[0]
	var lines := {
		"炼药师集会":["南门客栈住满了药师，连后院都堆着药箱。","听米菈说，有药师在订房。学徒先来打听草叶了。"],
		"骑士团驻扎":["城外扎了营。伙夫买走一车面包，还嫌不够。","城外在清空地，军需官已经来问过刀剑了。"],
		"矿队归来":["矿队回来了。炉桥堵得连手推车都挤不过去。","山口有人看见矿车了，车轮压得挺深。"],
		"矿井整修":["矿井封了半边。工人没下井，饭还是得吃。","听说支架松了，工头正找人筹材料呢。"]
	}
	if not lines.has(article.title): return []
	return [lines[article.title][0 if article.active else 1]]
