class_name CityEconomy
extends RefCounted

const CYCLE_DAYS := 7
const TRAVEL_COST := 35
const CITIES := {
	"windrest": {
		"name":"风栖镇",
		"market":"南门集市",
		"dispatch":"林间采集者在南门卸下成捆草叶，药铺门前总能见到新鲜的山野货。运来的矿车却要翻过几道山口，铁匠常常守在城门旁等货。",
		"life":"钟楼下的旧告示换成了手绘地图。巡夜人说，来往旅客终于不再把通向森林的小巷当作城门。",
		"base":{"材料":0.78,"矿石":1.28,"武器":1.22,"药剂":0.94,"食物":1.05,"燃料":1.08},
		"events":[
			{"start":3,"duration":2,"name":"炼药师集会","forecast":"炼药师陆续订下客房，药铺正在清理柜台，准备接待远道而来的同行。",
			"news":"戴着各色徽章的炼药师聚在南门附近。学徒提着篮子四处寻找新鲜草叶与浆果，几家药铺的防护和力量药剂也被来访者反复询问。",
			"rumor":"客栈接连收到炼药师的来信。掌柜忙着腾出后院，药铺学徒已经开始寻访采集者，想为来客备些新鲜的草叶、浆果和试药材料。",
			"effects":{"herb":1.45,"berry":1.20,"potion":1.40,"power":1.35}},
			{"start":6,"duration":2,"name":"骑士团驻扎","forecast":"城外有人看见骑士团的旗帜，营地的补给车正在打听城里的铺子。",
			"news":"骑士团在城外扎下帐篷。军需官挨家询问能上阵的刀剑和开营地用的工具，伙夫则在烘焙铺与烤肉摊前排起长队。",
			"rumor":"运粮车带来骑士团将经过此地的消息。城外空地正在清理，先行的军需官向铁匠和食摊打听，能否备齐驻营所需的装备与口粮。",
			"effects":{"sword":1.55,"iron_sword":1.55,"copper_sword":1.55,"copper_axe":1.55,"copper_pickaxe":1.42,"iron_axe":1.55,"iron_pickaxe":1.42,"tempered_sword":1.60,"tempered_axe":1.60,"bread":1.24,"steak":1.30}},
		],
	},
	"ironvale": {
		"name":"铁砧城",
		"market":"炉桥商圈",
		"dispatch":"炉桥旁的矿车从清晨排到午后，锻造铺与燃料商就设在矿仓附近。卖草药、鲜食和药剂的外乡商车一到，往往先被工人们围住。",
		"life":"工人们给炉桥栏杆刷上了新漆，沿桥挂起旧矿灯。下班的人停下脚步，猜哪一盏曾跟着祖辈进过最深的矿道。",
		"base":{"材料":1.36,"矿石":0.72,"武器":0.88,"药剂":1.30,"食物":1.24,"燃料":0.80},
		"events":[
			{"start":2,"duration":2,"name":"矿队归来","forecast":"满载的矿队正沿山路返城，仓库管理员已经腾出空地。",
			"news":"远行矿队的货车挤满炉桥，矿石和途中收集的粘液、古木正在卸货。仓库几乎堆到门口，摊主忙着重新安排摆货的地方。",
			"rumor":"山路驿站传来消息：远行矿队的车轮压得很深，随车还带着野外采集物。仓库管理员正在腾出空地，等着这批货进城。",
			"effects":{"ore":0.68,"copper_ore":0.72,"slime_mucus":0.82,"ancient_wood":0.86}},
			{"start":5,"duration":2,"name":"矿井整修","forecast":"矿井支架需要整修，工头正在联络外来的供货商。",
			"news":"矿井暂时封住入口，矿车停在轨道旁。整修工人四处筹措补用的矿材与趁手刀斧，留在地面的工班仍要按时领到面包和热食。",
			"rumor":"工头发现几处支架松动，正准备召集工班整修。外来的供货商被请去谈话，话题从补用矿材、刀斧一直说到工班的饭食。",
			"effects":{"ore":1.55,"copper_ore":1.42,"sword":1.22,"iron_sword":1.30,"copper_sword":1.20,"copper_axe":1.20,"iron_axe":1.30,"bread":1.18,"steak":1.24}},
		],
	},
}

var city_id := "windrest"
var sold_pressure: Dictionary = {}
var relationships: Dictionary = {}
var modules: Array[String] = []

func city_name() -> String:
	return CITIES[city_id].name

func market_name() -> String:
	return CITIES[city_id].market

func cycle_day(world_day: int) -> int:
	return (world_day - 1) % CYCLE_DAYS + 1

func days_until_departure(world_day: int) -> int:
	return CYCLE_DAYS - cycle_day(world_day)

func can_travel(world_day: int) -> bool:
	return cycle_day(world_day) == CYCLE_DAYS

func other_city_id() -> String:
	return "ironvale" if city_id == "windrest" else "windrest"

func other_city_name() -> String:
	return CITIES[other_city_id()].name

func travel() -> void:
	city_id = other_city_id()

func active_event(world_day: int) -> Dictionary:
	var local_day := cycle_day(world_day)
	for event in CITIES[city_id].events:
		var finish: int = int(event.start) + int(event.duration) - 1
		if local_day >= int(event.start) and local_day <= finish:
			return event
	return {}

func multiplier(item_key: String, category: String, world_day: int) -> float:
	var base: float = float(CITIES[city_id].base.get(category,1.0))
	var event := active_event(world_day)
	if not event.is_empty():
		base *= float(event.effects.get(item_key,event.effects.get(category,1.0)))
	var city_pressure: Dictionary = sold_pressure.get(city_id,{})
	base *= clampf(1.0 - float(city_pressure.get(category,0)) * 0.04,0.72,1.0)
	return clampf(base,0.55,1.85)

func base_multiplier(item_key: String, category: String) -> float:
	return float(CITIES[city_id].base.get(category,1.0))

func event_multiplier(item_key: String, world_day: int) -> float:
	var event := active_event(world_day)
	return 1.0 if event.is_empty() else float(event.effects.get(item_key,1.0))

func pressure_multiplier(category: String) -> float:
	var city_pressure: Dictionary = sold_pressure.get(city_id,{})
	return clampf(1.0 - float(city_pressure.get(category,0)) * 0.04,0.72,1.0)

func price_breakdown(item_key: String, category: String, base_value: int, world_day: int) -> Dictionary:
	var city_factor := base_multiplier(item_key,category)
	var event_factor := event_multiplier(item_key,world_day)
	var pressure_factor := pressure_multiplier(category)
	var final_factor := clampf(city_factor*event_factor*pressure_factor,0.55,1.85)
	var reasons: Array[String] = []
	if not is_equal_approx(city_factor,1.0):
		reasons.append("%s供需 %+.0f%%" % [city_name(),(city_factor-1.0)*100.0])
	if not is_equal_approx(event_factor,1.0):
		reasons.append("%s %+.0f%%" % [active_event(world_day).name,(event_factor-1.0)*100.0])
	if pressure_factor < 1.0:
		reasons.append("近期售出过多 %.0f%%" % [(pressure_factor-1.0)*100.0])
	if reasons.is_empty():
		reasons.append("行情平稳")
	return {
		"base":base_value,
		"current":maxi(1,roundi(base_value*final_factor)),
		"percent":roundi((final_factor-1.0)*100.0),
		"city_factor":city_factor,
		"event_factor":event_factor,
		"pressure_factor":pressure_factor,
		"reasons":reasons,
	}

func event_items(event: Dictionary, catalog: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in event.get("effects",{}):
		if catalog.has(key):
			keys.append(str(key))
	keys.sort_custom(func(a,b): return str(catalog[a].name) < str(catalog[b].name))
	return keys

func event_price(item_key: String, event: Dictionary, catalog: Dictionary) -> int:
	var data: Dictionary = catalog[item_key]
	var factor := base_multiplier(item_key,data.category) * float(event.effects.get(item_key,1.0)) * pressure_multiplier(data.category)
	return maxi(1,roundi(int(data.value)*clampf(factor,0.55,1.85)))

func event_change_percent(item_key: String, event: Dictionary) -> int:
	return roundi((float(event.effects.get(item_key,1.0))-1.0)*100.0)

func value(item_key: String, category: String, base_value: int, world_day: int) -> int:
	return maxi(1,roundi(base_value * multiplier(item_key,category,world_day)))

func record_sale(category: String, count := 1) -> void:
	if not sold_pressure.has(city_id):
		sold_pressure[city_id] = {}
	var city_pressure: Dictionary = sold_pressure[city_id]
	city_pressure[category] = int(city_pressure.get(category,0)) + count

func advance_day() -> void:
	for id in sold_pressure:
		var city_pressure: Dictionary = sold_pressure[id]
		for category in city_pressure.keys():
			city_pressure[category] = maxi(0,int(city_pressure[category])-1)

func relationship(customer_name: String) -> int:
	return int(relationships.get(customer_name,0))

func record_trade(customer_name: String) -> int:
	if customer_name == "":
		return 0
	relationships[customer_name] = mini(5,relationship(customer_name)+1)
	return relationship(customer_name)

func intelligence(world_day: int, customer_name := "") -> String:
	var lines: Array[String] = []
	for article in news_articles(world_day,customer_name):
		lines.append("%s：%s。%s" % [article.section,article.title,article.body])
	if lines.is_empty():
		lines.append("街头没有新的消息，商贩们仍在照常摆摊。")
	return "\n".join(lines)

func news_articles(world_day: int, customer_name := "") -> Array[Dictionary]:
	var local_day := cycle_day(world_day)
	var horizon := 3 if relationship(customer_name) >= 2 else 2
	var articles: Array[Dictionary] = []
	for event in CITIES[city_id].events:
		var start: int = int(event.start)
		var active := local_day >= start and local_day < start+int(event.duration)
		var upcoming := start > local_day and start-local_day <= horizon
		if active or upcoming:
			articles.append({"section":"本城新闻" if active else "街头消息","title":str(event.name),"body":str(event.news if active else event.rumor),"active":active})
	return articles

func local_dispatches() -> Array[Dictionary]:
	var reports: Array[Dictionary] = [{"section":"市集来信","title":market_name(),"body":str(CITIES[city_id].dispatch)}]
	var city_pressure: Dictionary = sold_pressure.get(city_id,{})
	var goods: Array[String] = []
	var descriptions := {"材料":"草叶与野外采集物","矿石":"矿材","武器":"刀剑工具","药剂":"药铺的瓶罐","食物":"吃食","燃料":"燃料"}
	for category in descriptions:
		if int(city_pressure.get(category,0)) > 0:
			goods.append(descriptions[category])
	if goods.is_empty():
		reports.append({"section":"街巷拾闻","title":"城里的一角","body":str(CITIES[city_id].life)})
	else:
		reports.append({"section":"市集来信","title":"摊位上的旧货","body":"最近流入集市的%s还堆在货架上。有摊主忙着挑拣手里的存货，来送货的人只好再多走几家铺子。" % "、".join(goods)})
	return reports

func market_report(_catalog: Dictionary, world_day: int) -> String:
	var lines: Array[String] = ["%s商报 · 第 %d 天" % [city_name(),world_day],intelligence(world_day)]
	for article in local_dispatches():
		lines.append("%s：%s" % [article.title,article.body])
	return "\n\n".join(lines)

func module_cost(module_id: String) -> int:
	return {"roof_rack":180,"hidden_compartment":240,"field_kitchen":210}.get(module_id,9999)

func module_name(module_id: String) -> String:
	return {"roof_rack":"车顶货架","hidden_compartment":"隐藏夹层","field_kitchen":"行军灶"}.get(module_id,module_id)

func install_module(module_id: String) -> bool:
	if modules.has(module_id) or modules.size() >= 2:
		return false
	modules.append(module_id)
	return true

func has_module(module_id: String) -> bool:
	return modules.has(module_id)
