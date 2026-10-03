extends RefCounted
## Additional encounters use the same option/effect protocol as the original forest stories.
const VARIANTS := {"logging":["hollow","snoring"],"mining":["fractured","echo"],"camp":["sleepy","steady"],"snail":["inspector","moving"],"hunter":["snare","fall"]}
const EVENTS := {
 "hunter":{"name":"受伤的猎人","art":"hunter","options":[
  {"id":"aid","label":"递瓶防护药剂，替他稳住伤势","item":"potion","outcomes":[{"hunter_saved":true,"result":"药剂护住了裂开的伤口。猎人奥林撑着树站起，记下了你商车的灯样。回城后，他会来找你。"}]},
  {"id":"bandage","label":"用干叶替他压住伤口，先缓一缓","outcomes":[{"result":"你帮他压住伤口。他向你道谢，仍得留在树下等同伴来接。"}]},
  {"id":"skip","label":"把水放在他身边，继续赶路","outcomes":[{"result":"猎人收下水，朝林间吹了声求援哨。你继续往前走。"}]}]},
 "logging":{"name":"摇晃的枯树","art":"logging","tool_required":"axe","options":[
  {"id":"chop","label":"用斧头砍下粗枯枝，多带些木料","tool":"axe","tool_cost":3,"outcomes":[{"rewards":["ancient_wood","ancient_wood"],"result":"枯枝落地，你截下两段还能作燃料的古藤木。"},{"rewards":["ancient_wood","berry","berry"],"result":"树洞里滚出一段木头和两颗藏起来的果子，小鸟气得啄了啄空树洞。"}]},
  {"id":"prune","label":"只砍松动的小枝，留着斧刃赶路","tool":"axe","tool_cost":1,"outcomes":[{"rewards":["ancient_wood"],"result":"你避开鸟窝，沿裂口砍下一段干木，收进待带走的行李。"}]},
  {"id":"skip","label":"把鸟窝留在原处，绕开这棵树","outcomes":[{"result":"你收住脚步，没有惊动枝头的住客。"}]}]},
 "mining":{"name":"路边的矿脉","art":"mining","tool_required":"pickaxe","options":[
  {"id":"dig","label":"用镐子凿进矿脉，赌里面料更好","tool":"pickaxe","tool_cost":3,"outcomes":[{"rewards":["ore","ore"],"result":"裂缝露出蓝色矿纹，你取下两块辉铁矿。"},{"damage":5,"rewards":["ore","copper_ore"],"result":"矿壁突然松动。你捞起矿石，脚背却挨了一块碎石。"}]},
  {"id":"chip","label":"沿松动石缝敲一点，留着镐子赶路","tool":"pickaxe","tool_cost":1,"outcomes":[{"rewards":["copper_ore"],"result":"你敲下表层的一块赤铜矿，及时停手。"}]},
  {"id":"skip","label":"不碰这些石头，带着工具继续走","outcomes":[{"result":"石缝的响声留在身后，你没有挥镐。"}]}]},
 "camp":{"name":"倒班篝火","art":"camp","options":[
  {"id":"rest","label":"靠近烤一会儿，赌它别睡着","outcomes":[{"heal":12,"result":"暖意缓缓驱散酸痛。火苗打了个哈欠，却还撑着没有熄灭。"},{"damage":4,"result":"火苗睡着时猛地一歪，火星落上袖口。你拍灭了它，手臂仍烫得发疼。"}]},
  {"id":"fuel","label":"添段古藤木，请它多值一会儿班","item":"ancient_wood","outcomes":[{"heal":24,"camp_supply":true,"result":"古藤木燃起来，火苗精神了不少。你暖好伤处，它还留了一份余火给下回。"}]},
  {"id":"skip","label":"让它打盹，沿着月光继续走","outcomes":[{"result":"你没有添柴，也没有靠近。火苗把脑袋缩回木头间。"}]}]},
 "snail":{"name":"蜗牛收费站","art":"snail","options":[
  {"id":"pay","label":"付点挪壳费，让它把路让开","cost":10,"outcomes":[{"rewards":["herb"],"snail_payment":true,"result":"你付了10G，蜗牛慢慢挪开壳，拿路边的月光草当找零。"}]},
  {"id":"fruit","label":"递颗绯红果，和它商量借个道","item":"berry","outcomes":[{"rewards":["herb"],"snail_fed":true,"result":"蜗牛收下果子，殷勤地抬起木杆，还送你一株月光草。"}]},
  {"id":"skip","label":"从壳边跨过去，赌它懒得追","outcomes":[{"result":"你跨过木杆。蜗牛还在想，这到底算不算过路。"},{"damage":4,"result":"蜗牛忽然伸出触角，你绊了一跤。它赶紧把木杆藏到了壳后。"}]}]}
}

static func build(id: String, memory: Dictionary, variant: String) -> Dictionary:
 var event: Dictionary = EVENTS[id].duplicate(true)
 event["id"] = id
 event["variant"] = variant
 var pages: Array = []
 match id:
  "hunter":
   pages = [{"speaker":"旁白","text":"猎人靠着树，脚边躺着一只断掉的套索，手臂的绷带已经渗红。" if variant=="snare" else "一名猎人坐在斜坡下，弓落在身旁。伤口让他连背起箭袋都很吃力。"},{"speaker":"奥林","text":"我叫奥林。不是狼咬的……是我自己的陷阱。我把路认反了。" if variant=="snare" else "猎鹿时摔下来的。鹿没抓到，倒被树根留住了。"},{"speaker":"奥林","text":"你若有护住伤口的药，我就能撑到城里。没有的话，我还得等同伴的哨声。"}]
  "logging":
   if variant == "hollow":
    pages = [{"speaker":"旁白","text":"枯树的粗枝已经开裂，树洞里传来果子滚动的声音。枝头一只小鸟正抱着行李搬家。"},{"speaker":"小鸟","text":"大枝随你砍，小枝随你挑。先看清哪根上面还有我的床！"}]
   else:
    pages = [{"speaker":"旁白","text":"枯树打着呼噜，每一下都震得粗枝往下掉木屑。你摸了摸背包里的斧头。"},{"speaker":"枯树","text":"枯枝可以拿走……我醒来之前，别让它砸到谁。"},{"speaker":"旅商","text":"你这呼噜，可比伐木声还响。"}]
    event.options[0].outcomes[1] = {"damage":6,"rewards":["ancient_wood"],"result":"呼噜震断了你正在砍的枝条。木头拿到了，肩膀也挨了一下。"}
    event.options[1].outcomes[0].result = "你趁它换气，沿裂口砍下一段干木，及时收斧。"
    event.options[2].label = "让枯树继续打盹，绕开落枝走"
    event.options[2].outcomes[0].result = "你绕过落枝，呼噜声渐渐留在身后。"
  "mining":
   if variant == "fractured":
    pages = [{"speaker":"旁白","text":"岩壁裂开一条细缝，蓝色和铜色矿纹露在外面。你刚蹲下，一小块石头就滚到了脚边。"},{"speaker":"旅商","text":"表层松了。往里凿，怕是得听着点动静。"}]
   else:
    pages = [{"speaker":"旁白","text":"矿石缝里传来一声叹气。你摸到镐柄，那声叹气也跟着紧张起来。"},{"speaker":"矿脉","text":"矿可以拿。敲的时候轻点，我叫得响，但不一定真的疼。"},{"speaker":"旅商","text":"那我先看看，你把哪层藏得最严。"}]
    event.options[0].outcomes[1] = {"rewards":["copper_ore","copper_ore"],"result":"矿脉叫得惊天动地，却只是露出了两块赤铜矿。"}
  "camp":
   if variant == "warm":
    pages = [{"speaker":"旁白","text":"你认出了先前添过柴的火苗。它从古藤木里探出头，余火还没有散尽。"},{"speaker":"火苗","text":"上回的柴够劲。我留了点暖和的，坐过来吧。"}]
    event.options[0].label = "靠近留下的余火，歇好再赶路"
    event.options[0].outcomes = [{"heal":16,"use_camp_fuel":true,"result":"你靠着自己先前添出的余火休息，等暖意退去才起身。"}]
   elif variant == "sleepy":
    pages = [{"speaker":"旁白","text":"一团火苗趴在干柴上打瞌睡。它每点一次头，脚边就溅出几颗火星。"},{"speaker":"火苗","text":"你不睡，我也得下班。除非……再添点够烧的。"}]
   else:
    pages = [{"speaker":"旁白","text":"小篝火把细柴排成一张值班表，煮水的壶还稳稳坐在旁边。"},{"speaker":"火苗","text":"这会儿轮我值班。暖暖手可以，别拿壶当枕头。"}]
    event.options[0].label = "在火边歇歇，暖好身子再赶路"
    event.options[0].outcomes = [{"heal":10,"result":"火苗稳稳烧着，你暖好手和伤处，重新背起行李。"}]
  "snail":
   if variant == "neighbor":
    var thanks := "上回的果子挺甜，这回就不拦你了。" if memory.get("snail_fed",false) else "你已经替我付过两回挪壳费了，这回我自己挪。"
    pages = [{"speaker":"旁白","text":"木杆还没横过来，蜗牛就认出了你，费力地把壳往路边推。"},{"speaker":"蜗牛", "text":thanks}]
    event.options[0] = {"id":"accept","label":"接过放行礼，顺着它让出的路走","outcomes":[{"rewards":["herb"],"result":"蜗牛递来一株月光草，给你留出了路。"}]}
    event.options[2] = {"id":"skip","label":"向它点点头，带着行李继续走","outcomes":[{"result":"你和蜗牛打过招呼，从留好的路上走过去。"}]}
   elif variant == "inspector":
    pages = [{"speaker":"旁白","text":"蜗牛用一根木杆拦住小路，壳边还挂着瘪瘪的钱袋。"},{"speaker":"蜗牛","text":"过路要挪壳，挪壳算搬家。搬家总得有人付点费。"},{"speaker":"旅商","text":"你是不是先把壳横过来，才想起要搬家？"}]
   else:
    pages = [{"speaker":"旁白","text":"蜗牛正把木杆搬到小路中间。看见你，它忽然停住，装作早就站在这里。"},{"speaker":"蜗牛","text":"别看我刚到，收费站的年头可是跟着壳走的。"}]
    event.options[0].outcomes = [{"rewards":["berry","berry"],"snail_payment":true,"result":"你付了10G。蜗牛让开路，又从搬家的行李里翻出两颗果子给你。"}]
 event["dialogue"] = pages
 return event
