class_name CityEconomy
extends RefCounted

const CYCLE_DAYS := 7
const TRAVEL_COST := 35
const CITIES := {
	"windrest": {
		"name":"风栖镇",
		"market":"南门集市",
		"base":{"材料":0.78,"矿石":1.28,"武器":1.22,"药剂":0.94,"食物":1.05,"燃料":1.08},
		"events":[
			{"start":3,"duration":2,"name":"炼药师集会","forecast":"炼药师将在第 3 天集会","effects":{"herb":1.45,"berry":1.20,"potion":1.40,"power":1.35}},
			{"start":6,"duration":2,"name":"骑士团驻扎","forecast":"骑士团将在第 6 天抵达","effects":{"sword":1.55,"iron_sword":1.55,"copper_sword":1.55,"copper_axe":1.55,"copper_pickaxe":1.42,"iron_axe":1.55,"iron_pickaxe":1.42,"tempered_sword":1.60,"tempered_axe":1.60,"bread":1.24,"steak":1.30}},
		],
	},
	"ironvale": {
		"name":"铁砧城",
		"market":"炉桥商圈",
		"base":{"材料":1.36,"矿石":0.72,"武器":0.88,"药剂":1.30,"食物":1.24,"燃料":0.80},
		"events":[
			{"start":2,"duration":2,"name":"矿队归来","forecast":"矿队将在第 2 天归来","effects":{"ore":0.68,"copper_ore":0.72,"slime_mucus":0.82,"ancient_wood":0.86}},
			{"start":5,"duration":2,"name":"矿井整修","forecast":"矿井将在第 5 天停工整修","effects":{"ore":1.55,"copper_ore":1.42,"sword":1.22,"iron_sword":1.30,"copper_sword":1.20,"copper_axe":1.20,"iron_axe":1.30,"bread":1.18,"steak":1.24}},
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
	var local_day := cycle_day(world_day)
	var horizon := 3 if relationship(customer_name) >= 2 else 2
	var lines: Array[String] = []
	var active := active_event(world_day)
	if not active.is_empty():
		lines.append("今日：%s" % active.name)
	for event in CITIES[city_id].events:
		var wait: int = int(event.start) - local_day
		if wait > 0 and wait <= horizon:
			lines.append("%d 天后：%s" % [wait,event.name])
	if lines.is_empty():
		lines.append("近日行情平稳")
	return "\n".join(lines)

func market_report(catalog: Dictionary, world_day: int) -> String:
	var samples := ["herb","ore","potion","iron_sword","steak"]
	var lines: Array[String] = ["%s · 周期第 %d 天" % [city_name(),cycle_day(world_day)],intelligence(world_day)]
	for key in samples:
		if not catalog.has(key):
			continue
		var data: Dictionary = catalog[key]
		var current := value(key,data.category,data.value,world_day)
		var change := roundi((float(current)/float(data.value)-1.0)*100.0)
		lines.append("%s  %d G  %+.0f%%" % [data.name,current,change])
	return "\n".join(lines)

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
