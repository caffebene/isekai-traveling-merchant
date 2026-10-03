extends SceneTree
const Store=preload("res://scripts/trade_state.gd")
const Roster=preload("res://scripts/customer_roster.gd")
const Story=preload("res://scripts/forest_story.gd")
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func transact(s, name_value: String, key: String, count: int, selling: bool, fail:=false) -> String:
	s.items.clear(); s.gold=10000
	s.configure_customer(s.CATALOG[key].category if selling else "","" if selling else "*",[],200,name_value)
	if not selling:
		s.customer_goods.assign([key])
	for n in range(count):
		s.add_item(key,"stock" if selling else "customer","player" if selling else "customer","stock",0)
	var batch: Array=s.items.filter(func(i): return i.key==key)
	for i in batch:
		check(s.move_item_to_counter(i.id,Vector2(650,400),i.rotated)=="","fixture places each real item on the physical counter")
	if fail:
		if selling: s.sell_offer=100000
		else: s.gold=0
	return s.settle()
func run() -> void:
	var s=Store.new(); var rng=RandomNumberGenerator.new(); rng.seed=81
	var counts: Dictionary={}; var previous:=-1; var gaps: Dictionary={}
	for n in range(400):
		var i: int=Roster.draw(s,rng,previous)
		check(i!=previous,"consecutive visitors differ")
		check(i not in [4,8,9],"locked characters never arrive")
		counts[i]=int(counts.get(i,0))+1
		if gaps.has(i): check(n-int(gaps[i])<=30,"every eligible character has bounded waiting")
		gaps[i]=n; previous=i
	check(counts.size()==7,"all seven initial characters arrive")
	var sequences: Array=[]
	for seed_value in [42,42,43]:
		var fresh=Store.new(); rng.seed=seed_value; previous=-1; var seq: Array=[]
		for n in range(25):
			previous=Roster.draw(fresh,rng,previous); seq.append(previous)
		sequences.append(seq)
	check(sequences[0]==sequences[1] and sequences[0]!=sequences[2],"seeded random traffic is reproducible and varied")
	for index in range(Roster.PEOPLE.size()):
		var goods_seen: Dictionary={}; var funds_seen: Dictionary={}
		for n in range(35):
			var p: Dictionary=Roster.arrival(s,index,rng)
			goods_seen[str(p.goods)]=true; funds_seen[p.funds]=true
			check(p.goods.size()>=p.count[0] and p.goods.size()<=p.count[1],"goods quantity respects person's bounds")
			check(p.funds>=100 and p.funds<=200,"budget uses existing transaction limits")
			check(p.conversation!=p["return"],"first-time guests never claim past transactions")
			s.configure_customer(p.buy_category,p.sell_key,p.goods,p.funds,p.name)
			check(s.items.filter(func(i): return i.owner=="customer").size()==p.goods.size(),"real customer grid contains all generated goods")
			for item in s.items.filter(func(i): return i.owner=="customer"):
				check(s.fits(item,"customer",item.cell,item.id),"random goods fit without overlaps")
		check(funds_seen.size()>1,"each guest's budget varies")
		check(goods_seen.size()>1 or index==0,"each selling guest's stock varies")
	s=Store.new()
	check(not Story.customer_lines(s,"希尔薇",[]).has(Story.REQUEST_LINE),"fresh greeting has no quest")
	Story.hear_line(s,"希尔薇",Story.REQUEST_LINE)
	check(s.story_progress.stage=="none","history or arbitrary text cannot bypass transaction")
	transact(s,"希尔薇","herb",1,true,true)
	check(not s.story_progress.get("request_available",false),"failed settlement cannot expose request")
	check(Roster.memory(s).affinity.is_empty(),"failed settlement cannot award faction trust")
	check(transact(s,"莱昂","sword",1,true).begins_with("交易完成"),"other person actually settles")
	check(not s.story_progress.get("request_available",false),"other person cannot expose Sylvie quest")
	check(transact(s,"希尔薇","herb",1,true).begins_with("交易完成"),"first Sylvie trade succeeds")
	check(Story.customer_lines(s,"希尔薇",[]).has(Story.REQUEST_LINE) and s.story_progress.stage=="none","successful trade offers unread request")
	Story.hear_line(s,"希尔薇",Story.REQUEST_LINE)
	check(s.story_progress.stage=="requested","earned request advances on hearing")
	Story.hear_line(s,"希尔薇",Story.REQUEST_LINE)
	check(s.story_progress.stage=="requested","request replay is idempotent")
	s=Store.new(); Roster.arrival(s,3,rng)
	transact(s,"布洛克","ore",3,false,true)
	check(not Roster.eligible(s,Roster.PEOPLE[8]),"failed ore purchase never unlocks foreman")
	check(transact(s,"布洛克","ore",3,false).begins_with("交易完成"),"actual ore purchase succeeds")
	check(Roster.eligible(s,Roster.PEOPLE[8]),"three purchased ores unlock introduced foreman")
	var trust: int=s.customer_memory.affinity.craft
	transact(s,"布洛克","ore",1,false)
	check(s.customer_memory.affinity.craft==trust,"multiple batches in a visit cannot farm faction affinity")
	check(str(Roster.thanks(s,"布洛克",true)).contains("赫伯特"),"introduction appears after completed trade")
	check(not str(Roster.thanks(s,"布洛克",true)).contains("赫伯特"),"introduction not repeated every batch")
	Roster.arrival(s,3,rng); transact(s,"布洛克","ore",1,false)
	check(s.customer_memory.affinity.craft==trust+1,"new visit can build faction affinity")
	check(transact(s,"米菈","bread",3,true).begins_with("交易完成"),"meal supply succeeds")
	check(Roster.eligible(s,Roster.PEOPLE[9]),"actual meals unlock supper volunteer")
	transact(s,"诺拉","sword",2,true)
	check(s.customer_memory.unlocks.get("watch_equipped",false),"actual weapon supply opens surplus stock")
	var sword_found:=false
	for n in range(80): sword_found=sword_found or Roster.arrival(s,6,rng).goods.has("iron_sword")
	check(sword_found,"unlocked surplus is really generated")
	transact(s,"阿雀","power",2,true)
	check(s.customer_memory.unlocks.get("night_supply",false),"night couriers supplied through actual trade")
	transact(s,"赫伯特","slime_mucus",3,true)
	check(s.customer_memory.unlocks.get("mine_repaired",false),"foreman repairs supports only after actual furnace fuel supply")
	var surplus_found:=false
	for n in range(80): surplus_found=surplus_found or Roster.arrival(s,8,rng).goods.has("iron_sword")
	check(surplus_found,"foreman's repaired mine opens real surplus")
	transact(s,"伊芙","bread",3,true)
	check(s.customer_memory.unlocks.get("supper_running",false),"supper expands only after actual meals")
	var medicine_found:=false
	for n in range(80): medicine_found=medicine_found or Roster.arrival(s,9,rng).goods.has("potion")
	check(medicine_found,"community follow-up actually offers medicine")
	s.story_progress.hunter_saved=true
	counts.clear(); previous=-1
	for n in range(250):
		previous=Roster.draw(s,rng,previous); counts[previous]=true
	check(counts.size()==10,"all ten characters enter random traffic after their real unlocks")
	s.advance_day()
	check(Roster.eligible(s,Roster.PEOPLE[8]) and Roster.eligible(s,Roster.PEOPLE[9]),"introductions survive rest")
	var shop=load("res://main.tscn").instantiate(); root.add_child(shop); await process_frame
	shop.customer_index=0; shop._apply_customer_profile(); shop._start_customer_conversation()
	check(not shop.dialogue_lines.has(Story.REQUEST_LINE),"production arrival has no request")
	shop.state.add_item("herb","stock","player")
	var herb: Dictionary=shop.state.items.back()
	shop.state.move_item(herb.id,"counter",Vector2i.ZERO,false)
	shop._settle()
	check(shop.dialogue_lines.has(Story.REQUEST_LINE),"production settlement starts request dialogue")
	shop._set_dialogue_line(1,true)
	check(shop.state.story_progress.stage=="requested","production dialogue completes request gate")
	shop._settle()
	check(shop.state.story_progress.stage=="requested","empty repeat settlement cannot duplicate story")
	shop.free()
	print("CUSTOMER_ROSTER: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
