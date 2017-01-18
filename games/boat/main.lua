--$Name: В одной шлюпке$
--$Version: 0.1.1$
--$Author: Константин Таро, Николай Коновалов$

---    Версии    ---
-- v0.0.1:
-- 	Исправил ошибку с не-отключением действий "Напасть" и "Обмен" при мертвой команде
-- 	Выправил сдвинутые траурные ленты

instead_version "2.4.1";

require 'xact'
require 'format'
format.para   = true;   -- Отступы в начале абзаца;
format.dash   = true;   -- Замена двойного минуса на длинное тире;
format.quotes = true;   -- Замена " " на типографские << >>;

require 'snapshots'
require 'useful'

start = function()
	if here() == trading then
		game.scene_use = true
	end
end

--====================| Предметы |====================-- 
items = {}
local counter = 0
item = function(name, desc)
	counter = counter + 1
	thing = obj{
		nam = name;
		isItem = true;
		dsc = function(s)
			if disabled(s) then
				return
			end

			if here() ~= trading then
				local row = txttab('45%', 'right') .. "{" .. name .. "}" .. txttab '50%' .." -- " .. txttab '60%' .. s.owner

				local disabled_count = 0
				for _, thing in ipairs(items) do
					if disabled(thing) then
						disabled_count = disabled_count + 1;
					end
				end
				p("^" .. txty( 107 - (#items-disabled_count) * 6 .. '%') .. row)
				if here() ~= lot and oarer == s.bearer and not s.drawed then
					p( "{oar_description|" .. img 'img/oar.png' .. "}" )
				end
			else
				if s:mine(Jim) then
					pn( txttab '5%' .. "(Джим) " .. "{" .. name .. "}" )
				else
					local thing = name
					if s.bearer.symphaty == 0 then
						thing = txtst(name)
					end
					pn( txttab '60%' .. "{" .. thing .. "}" .. " (" .. s.owner .. ")" )
				end
			end
		end,
		act = desc;
		assign = function(s, to)
			s.owner = names[to.num]
			s.bearer = to
		end,
		var {
			owner = '',
			bearer = {},
			num = counter,
		},
		mine = function(s, man)
			return not disabled(s) and s.bearer == man
		end,
		use = function(s, w)
			if s:mine(Jim) then
				if w.isPerson then
					if w.symphaty ~= 0 then
						local thing = s.nam  
						if s == bottle or s.isFish then
							thing = thing:sub(1, -3)
							thing = thing .. "у"
						end
						p( w.nam .. " принял " .. thing )
						if s.isFish then
							w.process_fish = false
						end
						s:assign(w)
					else
						pr( w.nam .. " отказался от \"ваших подачек\"" )
					end
				end
			elseif w.isPerson then
				p [["Предмет не у меня -- как я его передам кому-то?"]];
			end
		end,
		used = function(s, w)
			if not w.isItem then
				return
			end

			local partner = s.bearer

			if s.owner == "Джим" and w.owner ~= "Джим" then
				w:used(s)
				return true
			elseif s.owner == "Джим" and w.owner == "Джим" then
				p "Вы попытались прикинули ценность двух своих предметов -- и сразу сообразили, что в деньгах её измерять в данной ситуации смысла не имеет."
				return true
			end

			if partner.symphaty == 0 then
				p(s.owner .. " грубо велел вам отвалить.")
				return true
			end

			local my_value = calc_value(s, partner)
			local his_value = calc_value(w, partner)
			if partner.symphaty == 1 then
				if my_value < his_value then
					s:assign(Jim)
					w:assign(partner)
					affirm_trade(w, s, partner)
				else
					p(s.owner .. [[ холодно отказался со словами: "А мне какая выгода?".]])
				end
			else
				if my_value <= his_value then  -- is profitable - make the deal
					if isHot() and s == umbrella and w == fishing_gear and partner ~= Trelony then
						p [["Ну нет: поймаю - не поймаю -- а макушку пропечет однозначно"]]
					else
						if w == bottle and partner == Billy_Bons and my_value == 3 then
							p [[Ммм... Ладно, давай сюда эту бутылку.]];
						elseif s.isFish and partner == Trelony then
							p [["Конечно бери, я себе еще поймаю"]];
						end

						s:assign(Jim)
						w:assign(partner)
					end
				else
					refuse_trade(w, s, partner)
				end
			end

			return true
		end,
	}

	stead.table.insert(items, thing )
	
	return thing
end

doubloon = item("Дублон",
	[[Золотая монета крупного достоинства.]])
bottle = item("Бутылка", 
	"Сосуд с какой-то крепкой алкогольной дрянью.")
knife = item("Нож",
	[[Послужит подспорьем в драке.]])
fishing_gear = item("Снасти",
	[[Леска, крючок да грузило. Можно попытать удачу в рыбной ловле.]])
umbrella = item("Зонтик",
	[[Укроет от палящих солнечных лучей.]])

fish = function()
	local res = item("Рыба", [[Отличная вещь на ужин, поможет вам восстановить силы.]])
	local old_assign = res.assign
	res.isFish = true
	res:disable()
	res.eat = function(s)
		if not disabled(s) then
			s.bearer:eat_fish()
		end
	end

	return res
end

fish1 = fish()
fish2 = fish()
fish3 = fish()

display_items = obj{
	nam = '';
	dsc = false;
	obj = items,
}

--====================| Персонажи |====================-- 
counter = 0
function person(name, pwr)
	counter = counter + 1
	return obj{
		isPerson = true;
		nam = name,
		dsc = function(s)
			if here() == evening then
				pn( txtb(s.nam) .. ": " .. s.msg )
			end
		end,
		var {
			power = pwr,
			new_power = 0;
			symphaty = 2;
			isDead = false;
			msg = '';
			num = counter;
			do_oaring = 0;
			drink_when_oaring = false;
		};
		oaring = function(s)
			s.do_oaring = s.do_oaring - 1
			if bottle:mine(s) then
				s.drink_when_oaring = true
			end
		end,
		boiling = function(s)
			if umbrella:mine(s) then
				s.msg = s.msg .. "укрылся от Жары под Зонтиком; "
			else
				s.new_power = s.new_power - 1
				s.msg = s.msg .. "(-1) Силы от Жары; "
			end
		end,
		relation = function(s, dr)
			s.symphaty = s.symphaty + dr
			if s.symphaty > 2 then
				s.symphaty = 2
			elseif s.symphaty < 0 then
				s.symphaty = 0
			end
		end,
		powering = function(s, dp, m)
			if not s.isDead then
				s.new_power = s.new_power + dp
				s.msg = s.msg .. m .. "; "
			end
		end,
		apply_power = function(s)
			if s.do_oaring < 0 then
				if s.drink_when_oaring then
					s.drink_when_oaring = false
					local dp = s.do_oaring + 1
					if dp == 0 then
						s.msg = s.msg .. "Бутылка притупила усталость от гребли; "
					else
						s:powering(dp, "(" .. dp .. ") Силы за греблю (Бутылка притупила усталость)")
					end
				else
					s:powering(s.do_oaring, "(" .. s.do_oaring .. ") Силы за греблю")
				end
				s.do_oaring = 0
			end

			s.power = s.power + s.new_power
			if s.power > pwr then
				s.power = pwr
			end
			s.new_power = 0
		end,
		fishing = function(s)
			local trelony_catch = s == Trelony and rnd(100) < 66
			local another_catch = s ~= Trelony and rnd(100) < 25
			local may_take = disabled 'fish3'

			if (trelony_catch or another_catch) and may_take then
				take_fish(s)
				return true
			end
			s.process_fish = false
			return false
		end,
		use = function(s, w)
			if w.isPerson then
				p [[-- В смысле "сам и помогай"? -- переспрашиваете вы.]];
			elseif w.isItem then
				if w:mine(s) then
					p [[Да, предмет у него.]];
				else
					p [[Вряд ли владелец просто  согласиться отдать предмет...]];
				end
			end 
		end,
		act = function(s)
			p [["Мне всегда говорил что доброе слово может помочь попавшему в трудности человеку -- но тот ли этот случай?"]];
		end,
		used = function(s, w)
			if w == help_with_oaring then
				if s == oarer then
					oarer = Jim
					if s.symphaty > 0 then
						p [["О, спасибо тебе, Джим!"]]
					else
						p[["Кто я такой чтобы отказывать тебе в удовольствии погрести?" -- с издевкой произнес]]
						p(s.nam)
					end
				end
			end
		end,
		fish_count = function(s)
			local count = 0
			for i=1, 3 do
				local f = ref('fish'..i)
				if f:mine(s) and not disabled(f) then
					count = count + 1
				end
			end

			return count
		end,
		eat_fish = function(s)
			i = s:fish_count()

			if s.process_fish then
				return
			end
			if i == 0 then
				s.msg = s.msg .. "Снасти не принесли сегодня улов; "
				return
			end

			if s == Jim and know_fish_juce_trick then
				s:powering(i*2, "(+".. i ..") от съеденной рыбы; (+".. i ..") от выжатой из рыбы влаги")
			else
				s:powering(i, "(+".. i ..") Силы от съеденной рыбы")
			end
			s.process_fish = true
		end,
	}
end

Jim = person("Джим", 6)
Blind_Pew = person("Слепой Пью", 7)
Silver = person("Сильвер", 8)
Trelony = person("Трелони", 9)
Billy_Bons = person("Билли Бонс", 10)

team = {Jim, Blind_Pew, Silver, Trelony, Billy_Bons}

--====================| Механика |====================-- 
global{
	day = 0,
	day_time = 0,
	travel_end = 20,
	weather = 0,
	water = 60,
	know_fish_juce_trick = false,
	broken_mast = false,
	broken_oar = false,
	wrist_lie = false,
	oarer = false,
	drink_first_time_alone = true;
}

names = {
	"Джим",
	"Пью",
	"Сильвер",
	"Трелони",
	"Билли";
}

describe = {
	"Штиль, жара"; 
	"Штиль, жара"; 
	"Ветрено, прохладно"; 
	"Ветрено, жара"; 
	"Сильное волнение, прохладно"; 
	"Шторм, прохладно"
}

describe_img = {
	"calm",
	"calm",
	"windy",
	"windy",
	"storm",
	"storm"
}

oar_description = xact( '', "Этому персонажу выпало сегодня грести на веслах." )

if not old_vobj then  -- prevent recursion when restoring snapshot
	old_vobj = vobj
	vobj = function(id, text)
		if text == ">>>" then
			text = "{>>>}"
		else
			text = "• {" .. text .. "}^"
		end

		return old_vobj(id, text)
	end
end

symphaty_indicator = menu{
	nam = function(s)
		local x = { 84, 175, 266, 376 }
		local xD = { 91, 185, 278, 378 }
		local who = { 'Pew', 'Silver', 'Trelony', 'Billy' }
		for i=1, 4 do
			if team[i+1].isDead then -- Pew is second
				pr( txttab(tostring(xD[i])) .. img('img/dead_' .. who[i] .. '.png') )
			else
				local offset = txttab(tostring( 65 + x[i]))
				if i == 3 then
					offset = txttab(tostring( 71 + x[i]))  -- txty will work once, at end
				elseif i == 4 then
					offset = txttab(tostring( 60 + x[i]))
				end
				pr( offset .. img 'blank:1x101' ..  img('img/symphaty_' .. team[i+1].symphaty .. '.png') )
			end
		end
	end,
	menu = [[Показывает отношение персонажей к вам.]];
}

take_fish = function(to)
	local the_fish = fish1
	if not disabled 'fish1' then
		if not disabled 'fish2' then
			the_fish = fish3
		else
			if not disabled 'fish3' then
				p( names[to.num] .. " упустил рыбу! Прямо из рук выскользнула!")
				return
			else
				the_fish = fish2
			end
		end
	end

	the_fish:assign(to)
	enable(the_fish)
end

power_101 = xact( '', "Главная и единственная характеристика персонажа. Достижение нуля означает гибель. Также используется для расчета победителя в драке." )

powers = menu{
	nam = function(s)
		pr( txty '58%' )
		local pos = { 0, 90, 178, 273, 365 }
		for i, man in ipairs(team) do
			if not man.isDead then
				local x = 37 + pos[i]
				if i == 5 and Billy_Bons.power < 10 then
					x = x + 10
				end
				local pwr = man.power
				if pwr < 0 then
					pwr = 0
				end
				pr( txttab(tostring(x)) .. man.power )
			end
		end
	end,
	menu = [[Показатель {power_101|"Силы"} персонажа: как только он опуститься до ноля -- персонаж погибнет.]];
}

water_indicator = menu{
	nam = function(s)
		if water < 0 then
			water = 0
		end
		p( txty '85%' .. txttab '186' .. water .. "/60" .. img 'img/water.png')
	end,
	menu = [[Количество оставшейся питьевой воды. Чтобы утолить жажду персонаж в день выпивает одну порцию. В противном случае жажда будет отнимет (-1) {power_101|Силы}.]];
}

function scene(r)
	r.nam = function(s)
		p( "День " .. day .. ": " .. describe[weather] )
		if #s.way == 0 then
			p '^'
			local time_tip = {
				[0] = "Утро",
				"Полдень",
				"Вечер",
				"Ночь",
			}
			pn( txtem(time_tip[day_time]) )
		end
	end
	r.pic = function(s)
		picture = describe_img[weather] 
		if s == evening then
			picture = 'evening'
		elseif s == morning and weather < 3 then
			picture = 'morning'
		end

		return 'img/' .. picture .. '.jpg'
	end

	if not r.obj then
		r.obj = {}
	end
	stead.table.insert(r.obj, display_items)
 
	return room(r)
end

function info(self)
	self.act = code[[ walk(self._to) ]]
	self.obj = { vobj( 'next', ">>>" ) }

	return scene(self)
end

function use_barrel()
	if water == 0 then
		for _, man in ipairs(team) do
			man:powering(-1, "жажда (-1) Силы")
		end

		p "Бочка пуста. Дерево уже успело высохнуть -- и вы думаете что его ребристая потрескавшаяся фактура отлично передает состояние вашего горла."
		return
	end

	local live_men = 0
	for _, man in ipairs(team) do
		if not man.isDead then
			live_men = live_men + 1;
		end
	end

	if live_men <= water then
		if live_men == 1 then
			if drink_first_time_alone then
				p "С утра вы приложились к бочке с водой — и странное ощущение что кто-то буравит вашу спину нахлынуло на вас. Вы оглянулись — но в лодке вы совершенно одни..."
				drink_first_time_alone = false
			else
				p "Вы зачерпнули воды из бочки и промочили горло."
			end
			set_sound 'snd/drinking.ogg'
		else
			for _, man in ipairs(team) do
				if not man.isDead then
					water = water - 1
				end
			end

			p "С утра каждый приложился (под пристальным взглядом остальных) к бочке с водой."
			set_sound 'snd/drinking.ogg'
		end
	else
		max_power_who, count = most_powerful()
		max_power_who = max_power_who[1]
		water = 0
		if count == 1 then
			p [[Воды на всех не хватит. За последние глотки живительной влаги разгорелся спор.]];
			p(max_power_who.nam .. " пинками отогнал всех от бочонка и сам выпил всю воду!")
			max_power_who:powering(water, "(+" .. water ..") Силы за остаток воды")
			for _, man in ipairs(team) do
				if man ~= max_power_who then
					man:powering(-1, "жажда: (-1) Силы")
				end
			end
		else
			p [[Воды осталось всего несколько глотков. Все бросились к бочонку с живительной влагой. Завязалась потасовка в результате которой бочонок опрокинулся и вода вытекла на дно лодки!]];
			for _, man in ipairs(team) do
				man:powering(-1, "жажда: (-1) Силы")
			end
		end
	end
end

died = xact( '', [[Ночь он для чего-то перегнулся через борт, к морской воде -- но ослаб настолько что не совладал с равновесием и выпал за борт. Что было при нём -- с тем и утонул.]] )

function process_fish()
	fish1:eat()
	fish2:eat()
	fish3:eat()

	disable 'fish1'
	disable 'fish2'
	disable 'fish3'
end

function end_day()
	oarer = false

	if bottle:mine(Billy_Bons) then
		Billy_Bons:powering( -1, "(-1) Силы от пьянства (Бутылка)")
	end

	process_fish()

	for _, man in ipairs(team) do
		if not man.isDead then
			man:apply_power()
			if man.msg == '' then
				man.msg = '-'
			end
		end
	end

	for i, man in ipairs(team) do
		if man.power < 1 and not man.isDead then
			p( man.nam .. " {died|умер}!")
			man.isDead = true
			for _, thing in ipairs(items) do
				if thing:mine(man) then
					disable( thing )
				end
			end
		end
	end

	if Jim.power <= 0 then
		walk 'loose'
	elseif day >= travel_end - 1 then
		walk 'win'
	end
end

function fight( with, JimIsArgessor )
	local he = team[with]
	local his_power = math.floor(he.power)
	local my_power = math.floor(Jim.power)

	if JimIsArgessor then
		he:relation(-1)
	end

	local my_msg = txtb "Джим" .. " Сила (" .. my_power .. ")"
	local his_msg = he.nam .. " Сила (" .. his_power .. ")"

	if knife:mine(he) then
		his_msg = his_msg .. " + Нож (3)"
		his_power = his_power + 3
	elseif knife:mine(Jim) then
		my_msg = my_msg .. " + Нож (3)"
		my_power = my_power + 3
	end

	local hold = rnd(6)
	my_msg = my_msg .. " + Кубик (" .. math.floor(hold) .. ")"
	my_power = my_power + hold
	local hold = rnd(6)
	his_msg = his_msg .. " + Кубик (" .. math.floor(hold) .. ")"
	his_power = his_power + hold 

	pn(my_msg) 
	pn(his_msg)
	p("Результат = " .. math.floor(my_power) .. "/" .. math.floor(his_power) .. ".")
	local lost_pwr = -1
	local lost_msg = "(" .. lost_pwr .. ") Силы от ушибов, полученных в драке"
	if my_power > his_power then
		p( txtb "Джим" .. " победил.")
		he.power = he.power - 1
		he:powering(lost_pwr, lost_msg)
		for _, thing in ipairs(items) do
			if thing.bearer == he then
				thing:assign(Jim)
			end
		end
	elseif his_power > my_power then
		p( he.nam .. " победил.")
		Jim:powering(lost_pwr, lost_msg)
		for _, thing in ipairs(items) do
			if thing.bearer == Jim then
				thing:assign(he)
			end
		end
	else
		p "Силы были равны, разошлись ни с чем."
		he:powering(lost_pwr, lost_msg)
		Jim:powering(lost_pwr, lost_msg)
	end

	pn '^'
end 

function most_powerful()
	local might_men = {}
	power_max = 0

	for _, man in ipairs(team) do
		if not man.isDead then
			local man_power = man.power
			if knife:mine(man) then
				man_power = man_power + 3;
			end

			if man_power > power_max then
				power_max = man_power
				might_men = { man }
			elseif man_power == power_max then
				stead.table.insert(might_men, man)
			end
		end
	end

	return might_men, #might_men
end

function items_transfer(from, to)
	for _, thing in ipairs(items) do
		if thing.bearer == from then
			thing:assign(to)
		end
	end
end

function isHot() 
	return weather == 1 or weather == 2 or weather == 4	
end

function isCalm()
	return weather < 3
end

function calc_value(item, who)
	if item == doubloon then
		if who ~= Trelony then
			return 3
		else
			return 1
		end
	elseif item == bottle then 
		if who == Billy_Bons then
			return 3
		else
			return 1
		end
	elseif item == umbrella then 
		if isHot() then
			if day_time < 2 then
				return 3
			else
				return 1
			end
		else
			return 1
		end
	elseif item == fishing_gear then 
		return 3
	elseif item == knife then 
		return 1
	elseif item == help_with_oaring then
		return 3
	elseif item.isFish then
		if who ~= Trelony then
			return 3
		else
			return 1
		end
	end
end

function refuse_trade(price, thing, partner)
	if price == knife then 
		if thing == umbrella then
			p [["Скорее Солнце напечет мне голову, чем мне жизненно понадобиться что-то заострить."]];
		elseif thing == doubloon then
			p [["Нож за дублон? Сдурел что ли?"]]
		elseif thing.isFish then
			p [["Ну нет, я этой рыбиной подкрепиться планировал".]];
		elseif thing == fishing_gear then
			if partner == oarer then
				p [["Ну и что, что я гребу?! Хочешь снасти -- предложи что-то стоящее взамен."]];
			else
				p [["Я лучше попытаю счастья в рыбалке"]];
			end
		end
	elseif price == bottle then
		if thing.ishFish then
			p [["Ну нет, я этой рыбиной подкрепиться планировал"]];
		elseif thing == doubloon then
			p [["Это, конечно, была бы не самая дорогая выпивка в моей жизни -- но я все равно воздержусь."]];
		elseif thing == umbrella then
			if partner == Silver then
				p [["Джим, мальчик мой, неужели я похож на человека теряющего голову от выпивки?"]];
			else
				p [["Пить по такой жаре, на голодный желудок..."]];
			end
		end
	elseif price == umbrella then
		if not isHot() then
			p [[А толку от зонтика? -- не жарко же.]];
		else
			p [[Жара спадает -- от зонтика уже не так много пользы.]];
		end
	elseif price == doubloon then  -- trading with Trelony
		if thing == umbrella then
			p [["Ты предлагаешь мне спрятаться от теплового ударе в тени этой монетки?" -- фыркнул Трелони.]];
		else
			p [["Ха, думаешь, раз моя шхуна затонула, -- так я теперь за каждой монетой буду бегать?" -- с насмешкой вопрошает Трелони.]]
		end
	elseif price == bottle then
		if thing.isFish then
			p [["Ну нет, я лучше поем, чем выпью"]];
		end
	end
end

function affirm_trade(price, thing)
	if thing == umbrella then
		if isHot() then
			p [["Давай: жара-то спала уже"]];
		else
			p [["Хорошо. Солнце сегодня не такое уж и страшное"]];
		end
	elseif thing.isFish then -- trading with Trelony
		if Trelony.fish_count > 1 then
			p [["Да не вопрос, бери вторую"]];
		else
			p [["Конечно, я себе еще поймаю"]];
		end
	end
end

function randomNPC()
	local circled = false
	local i = rnd(2, 5)
	while team[i].isDead do
		i = i + 1
		if i > 5 then
			i = 2
			if not circled then
				circled = true
			else
				return false
			end
		end
	end

	return team[i]
end

function getRandom(t)
	return t[ rnd(#t) ]
end
--====================| Игра |====================-- 
start_game = menu {
	nam = txty '80%' .. txttab '194' .. "Начать игру!",
	menu = function(s)
		walk 'prologue'
	end,
};

main = room{
	nam = "Перед началом игры^";
	entered = function(s)
		take 'start_game'
	end,
	left = function(s)
		drop 'start_game'
	end,
	dsc = [[Добро пожаловать!^ Это игра о выживании пяти человек в маленькой шлюпке посреди океана.^^ 
	<b>Советы:</b>
	^• Если вы не успели прочесть какой-то текст -- попробуйте нажать на заглавие вверху пергамента.
	^• В игре присутствуют скрытые механики -- потому будьте внимательны к тому <i>что</i> происходит и при <i>каких</i> условиях ;)
	]];
}

prologue = room{
	nam = function(s)
		if s.has_to_read then
			p "День 0: Жуткий шторм^^"
		else
			p "День 1: Штиль, похладно^^"
		end
	end,
	entered = function(s)
		set_music 'mus/storm.ogg'
	end,
	pic = function(s)
		if s.has_to_read then
			return "img/espanola.jpg";
		else
			return "img/calm.jpg";
		end
	end,
	var{
		has_to_read = true;
	};
	forcedsc = true;
	exit = function()
		takef 'powers'
		takef 'symphaty_indicator'
		doubloon:assign(Jim)
		bottle:assign(Silver)
		knife:assign(Blind_Pew)
		fishing_gear:assign(Billy_Bons)
		umbrella:assign(Trelony)

		take 'water_indicator'

		day = 1
		weather = 1
		set_music 'mus/calm.ogg'

		make_snapshot()
	end,
	dsc1 = [[Шторм обрушился на «Эспаньолу» внезапно как сыч на сонную мышь. Команда боролась за жизнь шхуны, но силы оказались неравными. Корабль потерял грот-мачту и ее обломки, запутавшись в снастях, сильно накренили судно на левый борт. В трюме отрылась большая течь. 
Десятиметровые волны накатывали на палубу, грозя смыть за борт любого храбреца осмелившегося противостоять стихии. Вконец отчаявшись, капитан Смоллетт приказал экипажу спускать шлюпки на воду. Вы молились всем богам в надежде выжить в этой бешеной свистопляске волн.^

	-- Эй! Джим!! – услышали вы сквозь завывание ветра крик Джона Сильвера – Скорее залезай в шлюпку. Еще немного и корабль опрокинется!^
	Схватившись руками за мокрый канат, вы перелезли через парапет и спрыгнули в пляшущую под вами утлую посудину.^

	-- Джим. Держись за уключину – вы оглянулись и увидели в шлюпке Сквайра Трелони. Его парик висел на его голове, как дохлая мокрая курица. Вы мигом последовали его совету и ухватились за уключину. ^
	Набежавшая волна отшвырнула вашу шлюпку от борта «Эспаньолы» и через некоторое время вы уже с трудом различали ее скорбный силуэт в сгущающихся ночных сумерках.^^

	В шлюпке кроме вас, Трелони и Сильвера находились так же Слепой Пью и Билли Бонс.^
	-- Три тысячи чертей! Отличная погодка. Не правда ли Джим? – прокричал Билли Бонс – Я бы сейчас выпил пару пинт ямайского рома!...^^{start_it|>>>}]];
	dsc = function(s)
		if s.has_to_read then
			p(s.dsc1)
		else
			p(s.dsc2)
		end
	end,
	act = function(s)
		if s.has_to_read then
			s.has_to_read = false
			set_music 'mus/calm.ogg'
		else
			walk 'lot'
		end

		return true
	end,
	obj = {
		xact( 'barrel', code[[take 'water_indicator'; return true]] ),
		xact( 'start_it', code[[prologue:act(); return true]] ),
	},
	dsc2 = [[Наутро шторм утих так же внезапно как и появился. Измученные и промокшие до нитки пассажиры начали проверять свои пожитки. Легкий ветерок гнал спокойную волну. Солнце начало заметно припекать.^
	-- Сильвер! Как думаешь, наши парни с «Эспаньолы» уцелели? – спросил Билли Бонс.^
	-- Не знаю. Я видел как капитан Смоллетт и доктор Ливси с тремя матросами отчаливали от кормы. Видно шторм отнес их шлюпку далеко от нас. Если конечно море не поглотило их грешные души – ответил Сильвер и наскоро перекрестился.^
	-- Черт с ними – раздался скрипучий голос Слепого Пью – Главное мы целы. Джон, как далеко мы от ближайшего берега?^
	-- На этой посудине мы доберемся до суши дней через пятнадцать. Нужно держаться  по курсу зюд-вест – Сильвер снял свою потертую треуголку, почесал свою проплешину и осмотрел горизонт.^
	-- Пятнадцать дней?! – скорбно простонал Пью – Будь проклят тот день когда я согласился сесть на эту дырявую шхуну.^
	-- С чего это вдруг она «дырявая»? – возмутился Трелони – Я заплатил за нее пятнадцать тысяч фунтов! Это был отличный корабль. И совсем новый.^
	-- А-а-а… – вяло отмахнулся Пью, и уставился своими пустыми глазницами куда-то вдаль…^^

	-- У нас тут есть небольшой запас пресной воды – Билли Бонс выкатил из-под сидения пузатый {barrel|бочонок} – Если будем экономить, то пожалуй на две недели хватит, в расчете на пять человек. Есть пара весел и мачта с парусом. Еще тут нашел леску с крючком. Возьму это себе. Можно будет ловить рыбу. Еды у нас нет. А что у вас, господа?
	-- У меня есть зонтик – отозвался Трелони. В открытом океане довольно жарко. Это поможет мне оставаться в тени и не страдать от жары.^
	-- А у меня есть вот это – угрюмо просипел Слепой Пью и показал раскладной нож.^ 
	-- Ну, а у меня бутылка доброго рому! – хитро подмигнув вам, Сильвер как фокусник, достал из-под отворота своего сюртука темно-зеленую закупоренную бутыль.^
	Вы пошарили в своем кармане и достали оттуда один золотой дублон:^
	-- У меня только это!^
	-- Что это?... – недовольно пробурчал Слепой Пью – Говори толком. Я же незрячий!^
	-- У меня есть один золотой дублон.^
	-- Э-э… Тут он тебе не поможет – презрительно скривился Билли Бонс – Вот леска с крючком. Это нужная вещь – Билли достал снасти и подергал леску, проверяя ее на прочность - Отличная штука. Хочешь, я продам ее тебе за один дублон?^
	-- Эй! Билли. Оставь парня в покое – оборвал ваш разговор Сильвер - Давайте бросим жребий, чтобы решить, кто будет грести на веслах? Ветер совсем утих.^^{start_it|>>>}]];
}

morning = scene{
	entered = function(s)
		day = day + 1

		for i = 2, #items do  -- do not shuffle doubloon
			if not disabled( items[i] ) then
				local who = rnd(5)
				while team[who].isDead do
					who = who + 1
					if who > 5 then
						who = 1
						break -- Jim alive
					end
				end
				items[i]:assign(team[who])
			end
		end

		use_barrel()

		weather = rnd(6)
		if weather < 3 then
			set_music 'mus/calm.ogg'
		else
			if weather < 5 then
				set_music 'mus/windy.ogg'
			else
				set_music 'mus/storm.ogg'
				if weather == 6 then
					set_sound 'snd/light_and_thunder.ogg'
				end
			end
		end
	end,
	dsc = function(s)
		if not isCalm() then
			p [[Слава Господу! Сегодня ветреная погода и грести никому не нужно. Лодка идет под парусом.]];
		end
	end,
	act = function(s)
		if isCalm() then
			if broken_oar then
				walk 'drift'
			else
				walk 'lot'
			end
		elseif broken_mast then
			walk 'lot'
		else
			walk 'choice'
		end
	end,
	obj = {
		vobj( 'next', ">>>" ),
	};
}

lot = scene{
	var {
		on_rows = false;
	},
	enter = function(s)
		s.on_rows = false
	end;
	left = code[[set_sound 'snd/oaring.ogg']];
	forcedsc = true;
	dsc = function(s)
		if isCalm() then
			p [[Штиль...]]
		else
			p [[Ветер был отличный - но мачта сломана и вы не можете поставить парус.]]
		end
		p [[^ Нужно идти на веслах. Вы собираетесь в кучку и {loting|кидаете жребий}.]];
	end,
	random = function(s)

		p "Грести сегодня будет {xwalk(choice)|"
		local r = rnd(5)
		if wrist_lie then
			r = rnd(2, 5)
		end

		while team[r].isDead do
			r = r + 1
			if r > 5 then
				r = 1
				break
			end
		end

		if not s.on_rows then -- prevent re-dicing
			s.on_rows = r
		else
			r = s.on_rows
		end

		oarer = team[r]
		pr(names[r])
		p '}.'
	end,
	obj = {
		xact('loting', code[[lot:random()]]);
	},
}	

drift = info{
	dsc = [[Штиль, парус висит бесполезной тряпкой. Весло сломано - вам не остается ничего другого, кроме как ждать ветра]];
	left = function(s)
		travel_end = travel_end + 1;
	end,
	_to = 'choice'
}

actions = scene {
	enter = function(s, from)
		s.waited = false
		if Blind_Pew.isDead or not has_items(Blind_Pew) then
			disable( exist 'steal' )
		else
			enable( exist 'steal' )
		end

		if day_time == 2 and oarer ~= Jim then
			enable( exist 'sleep' )
		else
			disable( exist 'sleep' )
		end

		if fishing_gear:mine(Jim) and oarer ~= Jim then
			enable( exist 'fishing' )
		else
			disable( exist 'fishing' )
		end

		if not randomNPC() then
			disable( exist 'talk' )
			disable( exist 'trade' )
			disable( exist 'attack' )
			enable( exist 'wait' )
		end

		if from == s or from == "conversation" or from == "to_fight" then
			if day_time == 1 then
				p "Полдень";
			else
				p "Вечер";
			end
		end
	end,
	exit = function(s, to)
		if to == trading then
			return
		end

		if not broken_oar and isCalm() then
			oarer:oaring()
		end

		if to ~= 'sleep' then
			if isHot() and day_time == 2 then
				for _, man in ipairs(team) do
					man:boiling()
				end
			end
		end
	end,
	talk = function()
		walk 'conversation'
		for _, man in ipairs(team) do
			man:relation(1)
		end
	end,
	steal = function()
		items_transfer(Blind_Pew, Jim)

		walk 'evening'
	end,
	attack = function()
		walk 'to_fight'
	end,
	sleep = function()
		local most_strong_hater = { power = 0; nobody = true }
		local id = -1
		for i, man in ipairs(team) do
			if man.symphaty < 0 and man.power > most_strong_hater.power then
				most_strong_hater = man
				id = i
			end
		end

		if not most_strong_hater.nobody and rnd(2) == 2 then
			if doubloon.owner == names[Jim.num] then
				doubloon.owner = names[id]
				items_transfer(Jim, most_strong_hater)
				pn( most_strong_hater.nam .. " напал на вас, но вам удалось откупиться дублоном." )
			else
				pn( most_strong_hater.nam .. " напал на вас пока вы отдыхали." )
				fight(id)
			end
		else
			Jim:powering(1, "сон восстанавливает (+1) Силы")
		end

		walk 'evening'
	end,
	wait = function()
		actions.waited = true
		walk 'evening'
	end,
	trade = function()
		walk 'trading'
	end,
	fishing = function()
		walk 'try_catch_fish'
	end,
	act = function(s, action)
		s[action]();
	end,
	obj = {
		vobj( 'talk', "Поговорить" ),
		vobj( 'trade', "Обменяться предметами"),
		vobj( 'steal', "Украсть предмет у слепого Пью" ),
		vobj( 'attack', "Напасть" ),
		vobj( 'sleep', "Отдохнуть" ),
		vobj( 'fishing', "Рыбачить" ),
		vobj( 'wait', "Просто смотреть в океан" ):disable(),
	},
};

try_catch_fish = room{
	nam = '';
	enter = function(s)
		s.result = Jim:fishing()
		walk 'evening'
	end
}

trading = scene{
	dsc = [[Какой предмет на какой вы хотите обменять?]];
	entered = function()
		game.scene_use = true
		for_nothing:disable()
		for_nothing:enable()
	end,
	left = function(s)
		game.scene_use = false
		p [[Поторговаться и бартер отняли у вас не так уж и много времени.]];
	end,
	obj = {
		[#items+1] = 'help_with_oaring', -- place items first
		[#items+2] = 'for_nothing',
		[#items+3] = 'outsource_oaring',
	},
	way = {
		vroom( "Закончить обмен", 'actions' ),
	},
}

help_with_oaring = obj{
	nam = 'help with oaring',
	dsc = function(s)
		if not broken_oar and oarer and oarer ~= Jim then
			p(txttab '5%' .. "{Взяться погрести}")
			pr( "за " .. names[oarer.num] )
			if oarer == Silver then
				pr "a"
			end
			p "."
		end
	end,
	used = function(s, w) s:use(w) end,
	use = function(s, w)
		if w.owner then
			if w.owner ~= names[oarer.num] then
				if w.owner == 'Джим' then
					p [[-- Я соглашусь грести за тебя -- но взамен ты возьмешь мой предмет.^
					-- Чего? -- ошарашено переспрашивает]]
					pn(names[oarer.num] .. ".")
					p "-- Ой, погоди - не то хотел сказать, -- поспешно выпаливаете вы."
				else
					p [["Не думаю, что у них настолько хорошие отношения, чтобы]]
					p(w.owner)
					p [[согласился заплатить мне за помощь]]
					pr(names[oarer.num])
					if oarer == Silver then
						pr "у"
					end
					p [["]]
				end
			else
				w:assign(Jim)
				oarer = Jim
				p [["Конечно, давай!"]]
			end
		elseif w ~= oarer then
			p [["Чем я ему помогу, если буду грести за другого?.."]]
		end 

		return false
	end,
}

for_nothing = obj{
	nam = '',
	dsc = function(s)
		p( "^^" .. "Просто помочь:" )
		local first = true
		if not disabled(Blind_Pew) then
			p " {Blind_Pew|Пью}"
			first = false
		end

		if not disabled(Silver) then
			if not first then
				p " | "
			end
			p( "{Silver|Сильверу}" )
			first = false
		end

		if not disabled(Trelony) then
			if not first then
				p " | "
			end
			p( "{Trelony|Трелони}")
			first = false
		end

		if not disabled(Billy_Bons) then
			if not first then
				p " | "
			end
			p( "{Billy_Bons|Билли}")
			first = false
		end
	end,
	obj = {
		'Blind_Pew', 'Silver', 'Trelony', 'Billy_Bons'
	},
}

deal = function(reference)
	return obj{
		nam = '';
		dsc = false;
		act = function(s)
			if reference.power < 3 then
				p [["Сомневаюсь, что он согласиться - вон как плохо выглядит."]];
			else 
				switch(reference.symphaty+1) { -- start from 0
					[[-- Мне нужно чтобы ты погреб за меня?^ -- Иди к черту!]],
					[[-- Погребешь за меня?^ -- С чего бы?]],
					[[-- Можешь погрести за меня?^ -- Извини, Джим, сейчас не время делать такие подарки]];
				}
			end
		end,
		use = function(s, w)
			if w.isPerson then
				if w == reference then
					switch(w.symphaty+1) {
						[["Издеваешься, гаденыш?!"]],
						[["Ага, смешно"]],
						[["Ха, и как же погрести за тебя мне поможет? Ах, для здоровья, говоришь, полезно..."]];
					}
				else
					p [["Что-то мне кажется, это поможет тебе, а не ]];
					pr (names[reference.num])
					p [["]]
				end
			elseif w.isItem then
				if w.bearer == reference then
					pn [[-- Я гребу -- и отдаю за это предмет?]];
					pn [[-- Ага, -- подтверждаете вы.]]
					pn [[-- Джим, это все не так работает...]]
				elseif w.bearer == Jim then
					if calc_value(w, reference) == 3 then
						if reference.power < 3 then
							p [["Заманчиво -- но я не чувствую в себе сил на такой подвиг"]];
						elseif w == fishing_gear then
							p [["А толку мне с них? Все равно руки греблей будут заняты."]];
						else
							p [["Ладно, по рукам."]];
							oarer = reference
							w:assign(reference)
						end
					end
				else
					p [["Вот как уговоришь его -- тогда и приходи"]];
				end
			end 
		end,
		used = function(s, w)
			if w.isPerson then
				if w == reference then
					p [["Чем мне поможет погрести за тебя?"]]
				else
					p [["Думаешь гребля - именно то, чего мне не хватает сейчас?"]]
				end
			else
				s:use(w)
			end 
		end,
	}
end

deal_bp = deal(Blind_Pew)
deal_s  = deal(Silver)
deal_t  = deal(Trelony)
deal_bb = deal(Billy_Bons)

outsource_oaring = obj{
	nam = 'outsource_oaring',
	dsc = function(s)
		if not broken_oar and oarer and oarer == Jim then
			p( "^" .. "Предложить погрести: {deal_bp|Пью}" )
			p( " | {deal_s|Сильверу}" )
			p( " | {deal_t|Трелони}")
			p( " | {deal_bb|Билли}")
		end
	end,
	obj = {
		'deal_bp', 'deal_s', 'deal_t', 'deal_bb'
	},
}

to_fight = scene{
	dsc = [[На кого Джим нападет?]],
	entered = function(s)
		for i, man in ipairs(team) do
			if man.isDead then
				exist(tostring(i)):disable()
			end
		end
	end,
	act = function(s, num)
		fight(tonumber(num), true)
		walk "evening"
	end,
	obj = {
		vobj( 2, "На Слепого Пью" ), -- Пью второй в списке
		vobj( 3, "На Сильвера" ),
		vobj( 4, "На Трелони" ),
		vobj( 5, "На Билли Бонса" );
	},
}

evening = scene{
	enter = function(s, from)
		if not disabled 'fishing_gear' and not fishing_gear:mine(Jim) then
			if oarer ~= fishing_gear.bearer or broken_oar then
				fishing_gear.bearer:fishing() 
			else
				pn( names[fishing_gear.bearer.num] .. " не мог рыбачить так как греб -- но и удочку никому просто так отдавать не соглашался." )
			end
		end

		if day_time == 2 then
			day_time = 3
			stop_sound()
			end_day()
		else
			day_time = day_time + 1
			if from == conversation then
				p [[За разговорами время пролетело незаметно: уже]];
				if day_time == 1 then
					p [[полдень.]];
				else
					p [[вечер.]];
				end
			elseif from == actions then
				if actions.waited then
					p [[Вы просто смотрели на волны...]];
				else
					p [[Украсть предметы оказалось делом не простым, пришлось долго выжидать подходящего момента.]];
				end
			elseif from == try_catch_fish then
				if from.result then
					p [[Вы долго вымучивали снасть -- и удача улыбнулась вам!]];
				else
					p [[Вы потратили кучу времени со снастью -- но рыбу так поймать и не удалось.]];
				end
			end

			if oarer == Jim then
				p [[^Вы потратили изрядно сил налегая на весла.]];
				if isHot() and not umbrella:mine(Jim) then
					p [[А Солнце тем временем методично прожаривало вам макушку и плечи.]];
				end
			end

			walk 'actions'
		end
	end,
	left = function(s)
		for _, man in ipairs(team) do
			man.msg = ''
			if man.isDead and not disabled(man) then
				disable(man)
			end
		end
		day_time = 0
	end,
	act = function(s)
		walk 'morning'
	end,
	obj = {
		'Jim', 'Blind_Pew', 'Silver', 'Trelony', 'Billy_Bons';
		obj{ nam = "no matter", dsc = "^" };
		vobj( 'next_day', "<i>На следующий день</i>" ),
	};
}

loose = room{
	nam = "Вы проиграли...^^";
	act = code[[ restore_snapshot(); return true ]];
	dsc = [[Увы, Джим помер от обезвоживания организма. Попробуйте заново пройти эту миссию.]];
	obj = {
		old_vobj( 'next', "{Попробовать еще раз}");
	},
}

win = room{
	nam = "...^^";
	entered = code[[ set_music 'mus/finale.ogg'; disable 'water_indicator' ]];
	dsc = [[В небе все чаще стали появляться чайки, и это было хорошим знаком. Значит, берег уже недалеко.^^

	И правда, ближе к вечеру на горизонте показалась темная полоса побережья. Вот уже видны прибрежные заросли и кромка прибоя.^^

	Шлюпка зашуршала дном о гальку берега и уткнулась носом в берег.^^

	Вы выскочили на твердую почву, и чуть было не упали. Вас пошатывало. За дни плавания на утлом суденышке вы привыкли к непрерывной качке.]];
	pic = 'img/final.jpg';
	act = code[[walk 'win2']];
	obj = {
		vobj( 'next', '>>>' )
	},
}

win2 = room{
	nam = "...^^";
	pic = 'img/final.jpg';
	act = code[[ restore_snapshot(); return true ]];
	dsc = function(s)
		local bp = not Blind_Pew.isDead
		local s = not Silver.isDead
		local t = not Trelony.isDead
		local bb = not Billy_Bons.isDead
		if not(bp or s or t or bb) then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам чудом удалось выжить. Жаль, ваши товарищи не могли разделить с вами этого счастья. Их тела покоятся на дне океана. Однако, вам еще предстояло найти людей…^^
			Вы надеялись, что это не необитаемый остров. Иначе бы вас ждала печальная участь.]];
		elseif t and not (bp or s or bb) then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с Трелони чудом удалось выжить.^^
	Билли Бонс, Сильвер и Пью погибли. Ну что ж, значит такая у них судьба.]];
		elseif bp and not (t or s or bb) then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.]];
			if knife:mine(Blind_Pew) then
				p [[^^Внезапно Пью ударил вас ножом в живот и вы упали на колени прямо на прибрежную гальку.^
				-- Ты всегда мне не нравился Джим – прошипел пират.]];
			end
		elseif bb and not (bp or t or s)then
			p[[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.^^

			-- Тут наши пути расходятся, Джим – проговорил Билли Бонс – Мне не нужна лишняя обуза. Ну-ка, давай сюда все свои вещи. Они тебе не понадобятся.^

			Пират отобрал у вас все вещи и направился в лес. Вас он бросил на произвол судьбы.]]
		elseif s and not(bp or t or bb) then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.^^

			-- Ну-ка помоги мне Джим – пропыхтел Сильвер, тяжело ковыляя на своей деревянной ноге – Тебе повезло что я сейчас с тобой. Я знаю, где мы находимся. Мне знакомы эти берега. Тут всего три дня пути до поселка. Нужно лишь пройти через лес. Держись меня сынок и никогда не пропадешь! – улыбнулся Сильвер, похлопав вас по плечу.^

			Вы двинулись в сторону леса.]];
		elseif bb and s and not bp then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.^^

			-- Тут наши пути расходятся, Джим – проговорил Билли Бонс – Мне не нужна лишняя обуза. Ну-ка, давай сюда все свои вещи. Они тебе не понадобятся.^
			-- Погоди, Билли! – одернул его Сильвер - Ну-ка Джим, помоги мне – пропыхтел Джон, тяжело ковыляя на своей деревянной ноге – Тебе повезло, что я сейчас с тобой. Я знаю, где мы находимся. Мне знакомы эти берега. Тут всего три дня пути до поселка. Нужно лишь пройти через лес. Держись меня сынок и никогда не пропадешь! – улыбнулся Сильвер, похлопав вас по плечу.^^

			Вы вместе двинулись в сторону леса.]];
		elseif bp and s and not bb then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.^^

			Внезапно Пью ударил вас кулаком в живот и вы упали на колени прямо на прибрежную гальку.^
			-- Ты всегда мне не нравился Джим – прошипел пират – Надо выпустить ему кишки.^
			-- Эй! Полегче, Пью!! Убери свои грязные лапы. Или тыт хочешь чтобы я бросил тебя тут слепого на диком берегу?  – одернул его Сильвер - Ну-ка Джим, помоги мне – пропыхтел Джон, тяжело ковыляя на своей деревянной ноге – Тебе повезло, Джим, что я сейчас с тобой. Я знаю, где мы находимся. Мне знакомы эти берега. Тут всего три дня пути до поселка. Нужно лишь пройти через лес. Держись меня сынок и никогда не пропадешь! – улыбнулся Сильвер и  похлопал вас по плечу.^^
			Вы вместе двинулись в сторону леса.]]
		elseif bb and bp and not s then
			p [[Сердце от радости стучало в вашей груди. Вы спасены. Вам с несколькими спутниками чудом удалось выжить.^^
			-- Тут наши пути расходятся, Джим – проговорил Билли Бонс – Мне не нужна лишняя обуза. Ну-ка, давай сюда все свои вещи. Они тебе не понадобятся.^
			Вы попробовали возмутиться, но внезапно Пью ударил вас кулаком в живот. Вы упали на колени, прямо на прибрежную гальку.^
			-- Ты всегда мне не нравился Джим – прошипел пират – Билли, надо выпустить ему кишки.^
			-- Оставь его – отмахнулся Билли Бонс – Он и сам подохнет в этих диких местах.^
			Пираты отобрали у вас все вещи и направились в лес. Вас они бросили на произвол судьбы.]];
		end

		p "^^"
		p( txtc [[КОНЕЦ]] )
	end,
	obj = {
		old_vobj( 'next', "{Сыграть еще раз}");
	},
}

--====================| События |====================-- 
choice = scene{
	nam = actions.nam;
	pic = actions.pic;
	_hapened = {},
	var {
		pos = 1;
	};
	enter = function(s, w)
		if not randomNPC() then
			walk 'actions'
			return
		end

		local len = #events
		local num = rnd(len)

		s.circled = false
		while true do
			local condition = events[num][1]
			if not s._hapened[num] and ( not condition or condition() ) then -- 'false' or function for condition
				s.pos = num
				break
			end

			num = num + 1
			if num > len then
				num = 1
				if not s.circled then
					s.circled = true
				else
					walk 'actions'
					return
				end
			end
		end
		s._hapened[num] = true

		exist('1').dsc = "1) " .. "{" .. events[s.pos][3][1] .. "}"
		exist('2').dsc = "^2) " .. "{" .. events[s.pos][4][1] .. "}"
	end,
	obj = {
		vobj( 1, "nothing" ),
		vobj( 2, "nothing" ),
	},
	dsc = function(s)
		return events[s.pos][2]
	end,
	act = function(s, what)
		if what == '1' then
			events[s.pos][3][2]()
		else
			events[s.pos][4][2]()
		end

		walk 'actions'
	end,
}

function check_events( events_table )
	for i, event in ipairs(events_table) do
		if #event ~= 4 then
			error("Событие " .. i .. ": должно быть 4 элемента")
		end

		if type(event[1]) ~= "function" and type(event[1]) ~= "boolean" then
			error("Событие " .. i .. ": проверьте условие")
		end

		if type(event[2]) ~= "string" then
			error("Событие " .. i .. ": проверьте описание")
		end

		if #event[3] ~= 2 then
			error("Событие " .. i .. ": проверьте ветку 1")
		end
		if #event[4] ~= 2 then
			error("Событие " .. i .. ": проверьте ветку 2")
		end
		if type(event[3][1]) ~= "string" then
			error("Событие " .. i .. ": проверьте текст первой ветки")
		end
		if type(event[4][1]) ~= "string" then
			error("Событие " .. i .. ": проверьте текст второй ветки")
		end
		if type(event[3][2]) ~= "function" then
			error("Событие " .. i .. ": проверьте реакцию первой ветки")
		end
		if type(event[4][2]) ~= "function" then
			error("Событие " .. i .. ": проверьте реакцию второй ветки")
		end
	end

	return events_table
end

function alive(required)
	return function()
		if required.isPerson then  -- single person required
			return not required.isDead
		else
			for _, man in ipairs(required) do
				if man.isDead then 
					return false
				end
			end

			return false
		end
	end
end

function has_items(who)
	for _, thing in ipairs(items) do
		if thing:mine(who) then
			return true
		end
	end

	return false
end

events = check_events{
	-- Структура: { ready, text, { act1, code1 }, { act2, code2 } }
	{ false,
		[[Летучая рыба выпрыгнула из воды и упала в лодку. Все бросились к ней. Возникла потасовка.]], 
		{ [[Попытаетесь завладеть рыбой]], function()
			if rnd(2) == 2 then 
				take_fish(Jim)
				p [[Вы успели всех распихать и завладели рыбой (+1 Силы).]];
			else 
				local who = most_powerful()
				who = who[1]
				if who ~= Jim then
					p [[Вы получили несколько крепких пинков и отползли в сторону. Рыбой завладел]]
					p (who.nam);
				else
					p [[Вы рванули за рыбиной словно за частью своей души. В неведомом доселе боевом раже вы раздавали зуботычины и отвешивали пинки — и завоевали тушку в бою.]]
				end
				take_fish(who)
			end 
		end }, 
		{ [[или не будете ввязываться в драку]], function()
			p "Вы решили не ввязываться в драку и сберечь свои силы."
			local who = most_powerful()
			who = who[1]
			p [[Рыбой завладел]]
			p (who.nam);
			take_fish(who)
		end } 
	},

	{ alive{ Billy_Bons, Trelony },
		[[Билли Бонс от скуки начал рассказывать свои морские байки, чтобы как-то развлечься от долгого безделья. После одной из его морских историй в разговор вмешался Трелони и заявил что это все «враки». Слово за слово и вот уже назревает потасовка. Билли Бонс не на шутку разошелся и полез с кулаками на вашего товарища.]],
		{ [[Заступитесь за Трелони]], function()
			p [[Вы заступились за Трелони и в шлюпке загорелась нешуточная потасовка.]];
			if Jim.power + Trelony.power > Billy_Bons.power then
				p [[Матерый пират долго и успешно держался против вас двоих, но под конец вы таки накостыляли ему.]]
				Billy_Bons:powering(-1, "зуботычины в потасовке (-1)")
			else
				p [[Вас было двое против одного -- и вы не плохо держались -- но даже численное преимущество, не помогло против такого опытного драчуна, как Билли Бонс.]];
				Jim:powering(-1, "зуботычины в потасовке (-1)")
				Trelony:powering(-1, "зуботычины в потасовке (-1)")
			end
		end },
		{ [[или не будет ввязываться в драку]], function()
			p [[Билли Бонс крепко отделал Трелони. Трелони ожидал что вы поддержите его в драке, но вы сделали вид, что вас это не касается. Трелони крепко на вас обиделся.]];
			Trelony:powering(-1, "зуботычины в потасовке (-1)")
			Trelony:relation(-1)
		end },
	},
	
	{ code[[ return fishing_gear:mine(Jim) ]],
		[[Клюнула крупная рыбина. Она тянет за леску и тащит вашу лодку в направлении противоположном вашему курсу. Если рыба утащит вас далеко от вашего курса, то вам придется плыть к берегу дольше.]],
		{ [[Обрубить леску (снасти будут потеряны)]], function()
			p [[Вы обрубили леску...]]
			fishing_gear:disable()
		end },
		{ [[или будете  надеяться, что рыбина скоро устанет и ее удастся вытащить на борт.]], function()
			p [[Рыбина тащила вас прорву времени. Наконец она выдохлась, и вы смогли подтащить ее к лодке. К вашему удивлению это оказалась не рыба, а большая черепаха. Вы закатили знатную пирушку. Черепашье мясо было очень сытным.^ Увы, у вас нет способа его как-то приготовить, чтобы не протухло. Потому вы скидываете остатки черепахи в воду.]]
			day_time = day_time + 1
			for _, man in ipairs(team) do
				man:powering(1, "(+1) за черепашье мясо")
			end
			travel_end = travel_end + 1
		end },
	};

	{ alive(Trelony),
		[[Трелони попросил у вас одолжить ему вашу куртку. Деревянное сидение оказалось для него слишком жестким, и он хотел подстелить себе под зад что-то мягкое.]],
		{ [[Одолжите ему свою куртку]], function()
			p [[Спасибо Джим. Ох! Моя бедная задница. Я не привык днями напролет сидеть на деревянном табурете. Ах, сейчас бы, сюда мое мягкое кожаное кресло.]];
			Trelony:relation(1)
		end },
		{ [[или откажетесь]], function()
			p [["Не думал, Джим, что ты окажешься таким скупердяем."]];
			Trelony:relation(-1)
		end },
	},

	-- №5						
	{ alive(Blind_Pew),
		[[В утренней прохладе, пока еще солнце достаточно милосердно, вас всех сморила дремота...]],
		{ [[Мирно посапывать]], function()
			if has_items(Jim) then
				p [[Каким-то непонятным образом пронырливый Пью украл у в вас все ваши вещи!]]
				items_transfer(Jim, Blind_Pew)
			else
				victim = {}
				for i, man in ipairs(team) do
					if i ~= 2 then -- Pew itself
						if has_items(man) then
							victim = man
							break
						end
					end
				end

				p [[Каким-то непонятным образом]]
				p (victim.nam) 
				p [[был обворован пронырливым Пью!]]
				items_transfer(victim, Blind_Pew)
			end
		end },
		{ [[Перевернуться во сне]], function()
			if has_items(Jim) then
				p [[Каким-то непонятным образом пронырливый Пью украл у в вас все ваши вещи!]]
				items_transfer(Jim, Blind_Pew)
			else
				victim = {}
				for i, man in ipairs(team) do
					if i ~= 2 then -- Pew itself
						if has_items(man) then
							victim = man
							break
						end
					end
				end

				p [[Каким-то непонятным образом]]
				p (victim.nam) 
				p [[был обворован пронырливым Пью!]]
				items_transfer(victim, Blind_Pew)
			end
		end },
	},

	{ alive{Blind_Pew, Silver, Billy_Bons},
		[[В лодке возникла течь. На дне шлюпки хлюпает вода. Если ничего не делать, то лодка потонет. Посовещавшись, было решено, что для затычки щелей отлично подходит треуголка Сильвера. Если нарезать ее на длинные полосы, то можно законопатить щели при помощи ножа. Сильвер наотрез отказался отдать свою треуголку на это богоугодное дело. Он говорит, что без своей шляпы он получит солнечный удар. Кажется, пираты собираются на него напасть и силой отобрать треуголку.]],
		{ [[Присоединитесь к заговорщиками и поможете силой отобрать у Сильвера треуголку]], function()
			p [[Вы помогли своим товарищам по несчастью отобрать у Сильвера треуголку. Разрезав его шляпу на полоски, вы законопатили щели в лодке.]];
			Silver:relation(-1)
		end },
		{ [[или Заступитесь за старика Сильвера]], function()
			p [[Вы заступились за Сильвера и ваши товарищи по несчастью вынуждены были придумывать другой способ решения проблемы с течью. Вскоре было решено порезать на полосы часть одежды и законопатить лодку. После того как течь была устранена, Сильвер с благодарностью похлопал вас по плечу и сказал, что он всегда знал что вы «хороший малый»]];
			Silver:relation(1) -- up to maximum; overhead will be neutralized
			Silver:relation(1)
			Silver:relation(1)
		end },
	},

	{ alive(Trelony),
		[[Трелони больше всех ворчал и жаловался на неудобства вашего плавания. Деревянные сидения в лодке были твердыми, прилечь на дне шлюпки было противно. Там хлюпала соленая и вонючая вода с примесью мочи. Пираты почему-то предпочитали мочиться прямо на дно лодки. Даже пройтись и немного размять затекшие и опухшие ноги, было невозможно.^
	Трелони постоянно просил вас о всяких мелких услугах. То попросит поменяться с вами местами в шлюпке, то изнемогая от жары, попросит вас помахать ему шляпой, то потребует поддержать его за талию, пока он, стоя раскорякой в шаткой посудине мочится в океан. ]],
		{ [[Будете выполнять его капризы]], function()
			p [[К концу дня вы полностью вымотались от постоянной заботы о вашем друге]];
			Jim:powering(-1, "вымотался от постоянной заботы о Трелони (-1) Силы")
		end },
		{ [[или откажетесь быть у него на побегушках]], function()
			p [[Трелони постоянно ныл по поводу своих страданий, желая вызвать в вас жалость, но вы делали вид, что не слышите его стенаний. Странно, что такой сильный и здоровый мужчина был таким изнеженным и требовательным к комфорту, как кисейная барышня.]];
		end },
	},

	{ alive{Billy_Bons, Blind_Pew, Trelony},
		[[Билли Бонс и Пью надоели жалобы Трелони на неудобства плавания на шлюпке. Они решили проучить вашего приятеля, и после небольшой словесной перепалки между ними завязалась драка.]],
		{ [[Заступитесь за Трелони]], function()
			p [[Вы встали на сторону Трелони и ему удалось отбиться от наседавших на него Билли и Пью. Вам и Трелони тоже досталось]]
			Jim:powering(-1, "(-1) Силы потеряно в драке")
			Trelony:powering(-1, "(-1) Силы потеряно в драке")
			Billy_Bons:powering(-1, "(-1) Силы потеряно в драке")
			Blind_Pew:powering(-1, "(-1) Силы потеряно в драке")
		end },
		{ [[или не будете ввязываться в драку]], function()
			p [[Билли и Пью повалили Трелони на дно шлюпки и изрядно поколотили. После этой взбучки Трелони перестал ныть и жаловаться на тяготы морского плавания и смотрел на всех угрюмо.]];
			Trelony:powering(-2, "(-2) Силы из-за побоев")
			Trelony:relation(-1)
		end },
	},

	{ alive(Trelony),
		[[Среди дня, когда все дремали, вы заметили, что Трелони выпил из бочонка две дневных порции пресной воды. Возможно, он это делает уже не первый раз? Если так пойдет и дальше, то запасов воды на всех не хватит. А впереди еще много дней пути.]],
		{ [[Пригрозите Трелони, что если он еще раз так сделает, вы расскажете о его хитрости пиратам]], function()
			p [[Трелони пообещал, что не будет воровать воду, но затаил на вас обиду]];
			Trelony:relation(-1)
		end },
		{ [[или сделаете вид, что не видели проделок вашего товарища]], function()
			p [[Вы решили никому не говорить об этом происшествии. Ведь Трелони ваш друг.]]
			water = water - 6
		end },
	},

	-- №10						
	{ alive(Billy_Bons),
		[[Когда вы встали возле борта лодки, чтобы справить малую нужду, Билли Бонс неожиданно толкнул вас в спину, и вы вывалились за борт. Когда вы вынырнули на поверхность океана, Билли хохотал своей дурацкой шутке. Вы с трудом забрались обратно в шлюпку.]],
		{ [[Пригрозите Билли Бонсу, что в следующий раз в ответ на подобную выходку вы врежете ему по морде]], function()
			p [[В ответ на вашу угрозу, Билли захохотал еще громче и похвалил за вашу смелость]];
			Billy_Bons:relation(1)
		end },
		{ [[или Просто промолчите]], function()
			p [[Вы бросали в сторону Билли Бонса гневные взгляды. Билли презрительно назвал вас трусом не способным даже постоять за себя]]
			Billy_Bons:relation(-1)
		end },
	},

	{ false,
		[[Когда среди дня все ваши товарищи по несчастью погрузились в дрему, вы подумали, что сейчас пока никто не видит, можно сделать пару глотков воды из бочонка.]],
		{ [[Выпьете немного пресной воды]], function()
			p [[Вы незаметно отпили пару глотков из бочонка]];
			Jim:powering(1, "пару глотков украдкой: (+1) Силы")
			water = water - 1
		end },
		{ [[или не будете обкрадывать ваших товарищей]], function()
			p [[Вы не стали подличать. Это было бы бесчестно с вашей стороны.]];
		end },
	},

	{ alive(Silver, Trelony),
		[[Вокруг вашей шлюпки собралась целая стая акул. Над поверхностью волн то и дело появлялись острые треугольники их плавников. Ваши спутники настороженно следили за хищниками.^
		Сильвер предложил Трелони поменяться с ним местами. Пират хотел устроиться поближе к мачте. Трелони не стал возражать.]],
		{ [[Предложите Сильверу сесть на ваше место]], function()
			p [[Сильвер нехотя поменялся с вами местами]];
		end },
		{ [[или пусть меняется местами с Трелони]], function()
			p [[Трелони встал, чтобы поменяться местами с Сильвером и тут старый пройдоха резко налег на один борт и лодка сильно накренилась. Трелони потерял равновесие и, вскрикнув, рухнул за борт. Стая акул тут же набросилась на несчастного. Вода окрасилась алым цветом. Вы в ужасе смотрели на бурлящую воду, где хищники рвали на части тело вашего товарища.]];
			Trelony.isDead = true
			for _, thing in ipairs(items) do
				if thing:mine(Trelony) then
					thing:disable()
				end
			end
		end },
	},

	{ alive(Silver),
		[[Сильвер по секрету рассказал вам, что пресную воду можно добыть из пойманной рыбы. Выдавленный из рыбы сок не соленый. Пару глотков вонючей и теплой воды,  это лучше чем ничего.]],
		{ [[Послушаете совета Сильвера и когда поймаете рыбу, то прежде чем ее съесть сначала выжмет из нее сок и выпьете]], function()
			know_fish_juce_trick = true
		end },
		{ [[Или считаете, что старый пират хочет вам навредить, и не будете пить сок от рыбы]], function()
		end },
	},

	-- №14						
	{ code[[return isCalm() and day > 12]],
		[[Внезапно одно весло треснуло и переломилось пополам. Теперь в штиль грести было невозможно. Вам оставалось лишь ждать ветра, чтобы идти на парусе. Это намного замедляло ваше продвижение и ставило под угрозу ваше выживание.^
	Кто-то предложил сделать весло из мачты. Но тогда если будет ветер, то вы уже не сможете идти под парусом. Нужно что-то решать. Ваши товарищи решили голосовать. Ваш голос оказался решающим.]],
		{ [[Скажете, что нужно делать весло из мачты]], function()
			broken_mast = true
		end },
		{ [[Откажетесь делать весло из мачты]], function()
			broken_oar = true
		end },
	},

	{ code[[ return not broken_oar and day > 10 ]],
		[[Вы настолько устали, что уже не знали как вам сохранить свои и без того скудные силы. Вам в голову начали приходить всякие подлые мыслишки. Вы подумали, что можно было бы притвориться, будто у вас произошел вывих запястья, и тогда вас не будут сажать грести на веслах.]],
		{ [[Притворитесь, что у вас вывихнуло запястье]], function()
			wrist_lie = true
		end },
		{ [[Или не станете хитрить]], function()
		end },
	},

	{ code[[ return not Trelony.isDead and day > 10 and Trelony.power < 4]],
		[[Вы все чаще стали замечать, что Трелони говорит сам с собой. В его глазах вы заметили бесовские огоньки. Кажется, ваш товарищ начинает понемногу сходить с ума.]],
		{ [[Постараетесь почаще с ним разговаривать, хотя это и отнимает у вас последние силы]], function()
			p [[Вы подбадриваете и веселите Трелони как можете. Кажется, приступ помешательство отступил от него]]
			Trelony:relation(1)
			Jim:powering(-1, "растормошить Трелони (-1) Силы")
		end },
		{ [[Или пусть все идет своим чередом. Каждый сам за себя]], function()
			p [[Внезапно Трелони вскочил и набросился на одного из пиратов с криком «Ублюдки! Это вы во всем виноваты!» В ходе драки Трелони получил несколько ударов кулаком в челюсть и притих. Кажется, разум снова вернулся к нему]];
			Trelony:powering(-2, "(-2) Силы в драке")
		end },
	},

	{ code[[ return alive{Blind_Pew, Billy_Bons, Silver}() and day > 10 ]],
		[[Пью предложил для того чтобы восстановить силы – бросить жребий. Кому не повезет – тому отрежут одну ногу по колено и съедят. Раненому наложат жгут и перевяжут. От этих слов у вас по спине пробежал холодок, а ноги занемели от страха. Остальные пираты угрюмо согласились. Почему-то все недвусмысленные взгляды пираты обратили на вас.^
	-- Да! Пью, дело говорит – отозвался Билли Бонс -  Спасения ждать не приходится.  До суши много дней пути. А жить всем хочется. Пусть решает Фортуна или Господь – это уж кто во что верит.^
	-- Я согласен, но только, чур я не участвую в жеребьевке – сказал Сильвер.^
	-- Это почему?! – возмутился Пью.^
	-- Ты остолоп, Пью?!! У меня же всего одна нога. Не могу же я пожертвовать своей единственной ногой.^
	Пираты согласились с его доводами и вопросительно посмотрели на вашу ногу.]],
		{ [[Вы наотрез откажетесь от этого безумного плана]], function()
			p [[-- А зря, Джим! – сказал Билли Бонс – Человеческое мясо довольно вкусное и питательное. Или ты брезгуешь мясом Пью? Ты не смотри, что от него воняет как от засцанного котами темного проулка. Это потому что он никогда не моется... И тут пираты дружно расхохотались, видя ваше испуганное напряженное лицо. Вместе с ними вовсю хохотал и Пью. Только сейчас вы поняли, что они шутили.]];
		end },
		{ [[Или предложите съесть ногу Пью, раз он предложил этот план]], function()
			p [[-- Джим! – воскликнул Пью - ты как истинный христианин должен был бы сам предложить свою ногу для того чтобы поддержать силы своих товарищей. Разве не так? А ты оказывается сам не прочь полакомиться человечиной. Вот оказывается, каков наш «святоша Джим»!... Пираты разразились дружным хохотом.^
	Только сейчас вы поняли, что они зло пошутили над вами.]];
			Blind_Pew:relation(-1)
		end },
	},

	{ code[[return not Blind_Pew.isDead and day > 5]],
		[[Пары глотков пресной воды, что вы выпивали каждый день, организму явно не хватало. Вы отощали, кожа засохла и сморщилась как у семидесятилетнего старика. Вы увидели, что Пью несколько раз в день черпает из океана морскую воду и делает несколько глотков. Вы слышали от бывалых моряков, что пить морскую воду нельзя. От этого рассудок может помутиться и человек порой сходит с ума.]],
		{ [[Сказать об этом Пью]], function()
			p [[Вы сказали Пью, что пить морскую воду опасно для здоровья. Пью ухмыльнулся и сказал, что если делать в день всего пару глотков морской воды, то это не опасно. Главное не пить много и часто.]];
		end },
		{ [[или Пусть делает как хочет]], function()
			p [[Вы промолчали. Кажется Пью уже несколько дней пьет забортную воду. Странно, что его еще не скрутило. Вы больше беспокоились не о Пью, а о себе. Если у Слепого Пью помутится разум, то он может ночью наброситься на вас и зарезать или выбросить за борт.]];
		end },
	},

}

--====================| Разговоры |====================-- 
conversation = room{
	pic = actions.pic;
	var {
		who = "Собеседник",
		pos = 1,
	};
	_talked = {};
	enter = function(s)
		len = #talks
		num = rnd(len)

		s.circled = false
		while true do
			if not s._talked[num] then
				with = talks[num][1]
				text = talks[num][2]
				man = false
				if not with.isPerson then
					for _, who in ipairs(with) do
						if not who.isDead then
							man = who
							break
						end
					end
				else
					man = with
				end
					
				if man and not man.isDead then
					s._talked[num] = true
					s.pos = num
					s.who = man.nam

					return true
				end
			end

			num = num + 1
			if num > len then
				num = 1
				if not s.circled then
					s.circled = true
				else
					s.pos = 0
					s.who = randomNPC().nam
					return true
				end
			end
		end
	end,
	nam = function(s)
		return s.who .. "^^"
	end,
	dsc = function(s)
		if s.pos == 0 then
			themes = {
				[["Летучего голландца"?]],
				[[капитана Ингленда и почтовую бригантину?]],
				[[капитана Хаксли?]],
				[[капитана Боннета?]],
				[["Свинцовый галеон"?]],
				[[капитана Флинта?]],
			}
			if rnd(2) == 2 then
				p [[Джим, а я рассказывал тебе историю про]];
				p(getRandom(themes))
				p [[Ах да! Рассказывал...]];
			else
				p [[Я рассказывал про ]]
				p(getRandom(themes))
				p [[А ну да, рассказывал]];
			end
		else
			return talks[s.pos][2]
		end
	end,
	act = function(s)
		walk 'evening'
	end,
	obj = {
		vobj( true, ">>>" ),
	};
}

function check_talks( talks_table )
	for i, talk in ipairs(talks_table) do
		required_persons = talk[1]
		if not required_persons.isPerson then
			for _, man in ipairs(required_persons) do
				if not man.isPerson then
					error("Беседа " .. i .. ": проверьте перечень затребованных персонажей")
				end
			end
		end

		if type(talk[2]) ~= "string" then
			error("Беседа " .. i .. ": проверьте текст")
		end
	end

	return talks_table
end

talks = check_talks {
	{ Silver, [[А ты знаешь Джим, что я родился в Бристоле?! Славный и красивый город. Правда в Бристоле не только прекрасные дворцы, но и жестокие сердца. Видывал я, как вдовы рыдают и клянут все на свете, узнав, что их мужья сгнили под африканским солнцем или сгинули в морской пучине во время шторма в Карибском море.^
	Многие здесь сходят на берег с сотней гиней в карманах, но чаще ты встретишь таких, кто воспевает хвалу Господу за то, что он в милости своей позволил им вернуться домой живыми после кораблекрушения, бунта или желтой лихорадки, как это бывало и со мной.^
	Мда-а… Разрази меня гром! Сдается мне, что настали наши последние деньки. Такие вот грустные дела, мой мальчик.]] },

	{ Blind_Pew, [[Я в юности как-то учился подмастерьем у сапожника. Но скажу честно, Джим, не больно-то нравилось мне это сапожное дело. Бывало, часами сидел, стиснув зубы, молча проклинал унылую рутину, надоедливую точность, с которой надо резать, кроить, шить и прибивать. Сапожник часто лупил меня почем зря.^
	Вскоре я окончательно понял, какое мрачное будущее меня  ожидает -- всю жизнь провести среди вони кож, постоянно подвергаясь оскорблениям и попрекам неблагодарных клиентов. Через полгода, я сбежал от сапожника, прихватив с собой все его сбережения. Ха-ха! И поделом этому старому олуху.]] },

	{ Billy_Bons, [[Знаешь Джим, когда я впервые увидел, как убивают людей? Хе-хе! Это было в Гвинее, когда я еще юнгой плавал на работорговом судне. Мы тогда посетили деревню, где удостоились аудиенции у тамошнего местного царька.^ 
	Эта аудиенция, собственно, и была целью нашего путешествия, поскольку монополией на торговлю «черным деревом» в этой местности владело само Его светлейшее, хотя и чернокожее величество.^
	Окруженный женами, стражей и рабами, король жил в большой просторной хижине. Как сейчас помню! За троном царька стоял палач, опоясанный мечом, готовый в любой момент исполнять приказы своего государя. По непонятным мне тогда причинам, Его чернокожее величество в знак своего дружелюбия по отношению к нам, приказало принести в жертву двух полуголых африканцев. Из извлекли из толпы стоящих вокруг подданных и тут же обезглавили. Горячая кровь несчастных забрызгала пурпурную мантию короля, но тот обратил на это не больше внимания, чем на несколько капель дождя. Да, Джим! Вот так раз-два и нету человека. Одно слово -- Варвары!]] },

	{ Silver, [[А знаешь Джим, когда я в первый раз попал в тюрягу? Когда мне было всего пятнадцать лет, я примкнул к шайке контрабандистов, промышлявших вначале в Бристольском заливе, но постепенно развернувших свою доходную, хотя и предосудительную деятельность на берегах Глостершира. Предметами беспошлинного ввоза были чай, французский коньяк, джин и дорогие шелковые ткани.^
	Разрази меня гром! Доходы контрабандистов, превосходили всяческое воображение. Хотя спиртное разбавлялось наполовину, покупатели все равно отрывали его с руками. Таможенная охрана не представляла серьезной опасности, и если ее чиновникам удавалось случайно застать нас на месте преступления, -- туго набитый кошелек прекрасно разрешал все недоразумения и безотказно вызывал приступ временной слепоты у служителей закона Его Величества. Эх! Славные были деньки, Джим.]] },

	{ Silver, [[Ты знаешь Джим, что мне в моей жизни довелось даже побывать рабом. Когда на корабле работорговцев где я служил матросом произошел мятежь и рабы вырвались из трюмов на палубу, произошла кровавая бойня. Нам тогда с трудом удалось обуздать этих обезумевших черномазых. Капитан и еще несколько матросов погибли. А когда мы, наконец бросили якорь в Барбадосе, помощник капитана заявил, что это мятеж подняли не рабы, а несколько моряков с нашего судна. В список «бунтовщиков» попал и я. Нас обвинили в убийстве капитана, осудили и продали в рабство. Разрази меня гром!^
	Да, Джим, легко человеку примириться с судьбой и принять наказание, если оно справедливо и, так сказать, законно. Но вердикт этих напыщенных судей с Барбадоса -- это же насмешка над правосудием, Джим!
	Представь, будто это тебя упрятали в загон для черномазых, а там важные господа, плантаторы пускают тебе табачный дым в лицо, дочери их смеются, глядя на тебя, и даже черные рабы насмехаются над тобой и глазеют, как в балагане. Боже мой, Джим, легче было, когда хирург пилил мне ногу -- тогда я просто вцепился зубами в руку, чтобы не орать от боли. А тогда на рынке рабов я чуть не разревелся, как маленький ребенок, потому что пал так низко, а все из-за вранья этой гнусной крысы Дженкинса. О-о! Джим! Именно тогда я понял цену всем этим чванливым капитанам, жирным торгашам и судейским. Они меня засудили по ИХ закону, но, Боже праведный, именно тогда я поклялся добраться до них, как только представится возможность, даже если придется нарушить все эти проклятые законы.^
	Разрази меня гром! С тех пор я решил отплатить им сполна за все мои унижения и дырявого фартинга не дал бы за их головы!]] },

	{ Silver, [[Джим! Я рассказывал тебе про то, как я в юности занимался контрабандой? Ах, ну да! Рассказывал…^
	Чего-то вспомнил, как однажды мы поймали одного особенно ретивого таможенника по прозвищу Ястребиный Глаз. Желая отомстить за то, что он совал всюду свой нос, подстерегал и вынюхивал. Мы завязали ему глаза, связали ноги и закричали -- «Сбросим его со скалы, ребята! Смерть ему!»^
	Несчастный молил о пощаде, но ребята толкали его к краю уступа, пока он отчаянным усилием, уже падая, не извернулся и не вцепился что было сил в узкую трещину в скале.^
	Вот уж была потеха! Разрази меня гром!^
	Пятнадцать минут Ястребиный Глаз висел на руках и звал на помощь. Потом пальцы его разжались, и с нечеловеческим воплем он рухнул вниз.^
	Шутка заключалась в том, что, пролетев едва три фута, он попал в кучу морского песка.^
Мы специально сбросили его с низкого уступа на берегу моря. С тех пор этот таможенник больше нам не докучал.^ 
	Хе-хе…Такие-то дела, Джим!]] },

	{ {Silver, Billy_Bons}, [[Эх, Джим! И где только не мотало меня по морям. Помнится, когда я служил на корабле у капитана Ингленда, мы обошли Африку и бросили якорь на Мадагаскаре.^
	До этого я слышал, что на пираты на Мадагаскаре живут как магараджи  роскошных дворцах. Хе-хе! Но это все оказались обычные морские байки.^ 
	На Мадагаскаре экипаж нашей «Кассандры» вытянул корабль на сушу и занялся кренгованием. После этого нагрузили припасов, нарубили дров и запаслись водой. Наконец, оставив за кормой безопасную гавань, попойки и проституток, мы взяли курс на север, обогнули Сейшельские острова и двинулись к Индии.^ 
	Мда-а… Давно это было.]] },

	{ Silver, [[А ведь у меня Джим было когда-то свое доходное дел. В ту пору я с моей милой женушкой Аннет жил на Ямайке, где управлял трактиром под названием «Порто-Белло». Я был тогда уважаемым гражданином и даже имел счет в девятьсот фунтов в Королевском банке Ямайки.^
	В продолжение почти трех лет я жил в Монтегю-Бей, дымил трубкой и отдавал должное отменным блюдам, на которые оказалась такой мастерицей моя жена. Здесь у меня  родился сын, которого окрестили Филиппом.^
	Но эта спокойная и размеренная жизнь вскоре надоела мне до чертиков. Посетители моего трактира рассказывали о своих похождениях, посвящали меня в свои секреты об утраченных и найденных сокровищах, о несчастных их владельцах, познакомившихся с виселицей.^
	Наконец я не выдержал и снова отправился в плаванье, нанявшись квартирмейстером на бриг «Морж», которым тогда командовал капитан Флинт.^ 
	Эх!... Разрази меня гром! Зря я тогда разменял спокойную жизнь на мытарства и игру со смертью. Но что было, того уж не вернешь. Видно такая у меня судьба, Джим…]] },

	{ Blind_Pew, [[Когда мы с Флинтом и его ребятами решили пешком прогуляться через джунгли к испанскому форту Санта-Лена – вот тогда я чуть не отдал концы. Жара, ядовитые змеи, топкая трясина. Я своим глазами видел, как Джоб Андерсон, случайно наступил на огромную шипящую змею, но благодаря своему большому весу раздавил ее сапогом.^
	Жратвы мы с собой не взяли. В итоге заблудились, и проплутали по джунглям целую неделю. Чуть не подохли тогда от голода. Хорошо, что я тогда пошел на разведку и наткнулся на деревеньку местных дикарей. Чтобы эти остолопы не предупредили испанцев о нашем приближении, я приказал своим парням всех вырезать. Не жалели ни детей ни женщин. Это было легко! Наелись тогда до отвала. Жареные поросята… М-м-м… Пальчики оближешь! Эх! Сейчас бы мне хоть кусочек сочной свинины… Черт как же жрать охота!]] },

	{ Blind_Pew, [[Знаешь, Джим. Я никогда не боялся ни Бога ни Дьявола. Но был в моей жизни один момент, когда я почувствовал холодный ужас. Это когда я услышал крик рулевого -- «Испанский галеон по левому борту!» Это было, когда  корабль капитана Флинта груженый сокровищами держал курс на Нью-Провиденс. Испанец имел по двадцать орудий с каждого борта и одним залпом мог запросто сдуть наше судно с поверхности океана. Предчувствие меня не обмануло. Именно в том бою я потерял свои глаза. Будь прокляты эти гнусные испанцы!]] },

	{ Silver, [[Эх! И до чего же жрать охота. Джим, если бы я не был христианином, а скажем индейцем или негром с Берега Слоновой кости, то клянусь, съел бы тебя сейчас со всеми твоими потрохами.^
	Гы-гы! Не бойся, Джим. Я шучу.  Просто вспомнил свой трактир в Бристоле, где всего за  
шесть пенсов всякий голодный посетитель мог вволю поесть моих телячьих котлет, жареных голубей, спаржи, молодой баранины и яблочного пирога.^ 
	Разрази меня гром! Я сейчас не отказался бы и от заплесневелого сухаря.]] },

	{ Billy_Bons, [[А знаешь Джим откуда у меня на щеке этот длинный шрам? Это случилось в Порт-Рояле. Мы с ребятами оказались на мели и проводили целые недели в пивных, проматывая остатки нашей добычи. Наш корабль тогда разбился о рифы и на шлюпках мы доплыли до порта. И тут в порту бросил якорь бриг «Морж» из Плимута. В его трюме находилось около сотни каторжников, которых собирались продать на плантации в Каролине. На наше счастье на этом судне находился мой старый приятель Джон Сильвер. Он то и придумал хитроумный план по захвату судна. Сильвер занимался на «Морже» закупкой провизии и предложил нашим парням спрятаться в бочках, которые под видом провианта он вечером погрузил на корабль. А ночью мы вылезли и перерезали вахтенных и солдат. Хе-хе! Так мы заполучили корабль, с которым потом долго бороздили океаны и моря. В той самой стычке я и получил сабельный удар от одного из офицеров. Будь он проклят!]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Джим, я еще не рассказал тебе о прошлом капитана Флинта? Нет? Ну так слушай.^
	Флинт стал на путь разбоя еще в юности, плавал с Инглендом, Девисом, Черной Бородой и даже со Стид-Беннетом, пока сам не стал капитаном. Он был сыном каторжника, сосланного на Барбадос в конце прошлого столетия за участие в бунте против короля Джеймса.^
	Наш Флинт был у него третий сын и мог бы вырасти почтенным плантатором или судовладельцем, если бы не испанцы, которые во что бы то ни стало хотели изгнать англичан, французов и голландцев, так как испанский король объявил своими владениями всю Вест-Индию и Мэйн.^
	Однажды ночью на поселение напал испанец-приватир и сжег все дотла, повесив старика Флинта и двоих старших сыновей на жердях под крышей их собственного дома. Младший Флинт отсиделся в зарослях, а потом примкнул к французским буканьерам в районе Сан-Доминго. Вместе с ними он много лет успешно сражался против испанцев.^
	Позже, он воспользовался королевской амнистией, однако лишь затем, чтобы получить передышку и попытаться раздобыть судно покрупнее. Мелкие суда и шхуны теперь его не соблазняли, он мечтал атаковать серебряный караван или большое поселение на материке.^
	И надо сказать, Джим что это ему в итоге удалось. Но это уже другая история…]] },

	{ {Silver, Billy_Bons}, [[Скажи Джим, кто по-твоему лучше? Пират или плантатор?^
	Ага! Вижу по твоим глазам, что пиратское дело тебе не по вкусу. Эх, Джим, простая ты душа!^ 
	Один человек выжимает пот из невольников, пока за сахар и табак не купит место в парламенте -- и это называется коммерцией. Другой, действует более откровенно, идет напролом, рискуя башкой, срывает куш на море -- это называется пиратством! А какая, в сущности, между ними разница?^
	Каждый год из Англии сотни судов везут на плантации Виржинии или на Багамы в своих трюмах несчастных каторжников. А в чем они провинились?! А?!^
	В том, что, движимые голодом, присвоили какую-нибудь мелочь, или воспротивились несправедливости ленд-лордов? Где уж тут высшая справедливость! Неужели человек должен унижаться и ползать на брюхе, чтобы прокормить своих детей?^
	Что молчишь?... То-то же!]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Джим, хочешь, я расскажу тебе про пиратское братство?^
	Самая хорошая охота была в проливе между Флоридой и Багамскими островами, но мы часто крейсировали и вдоль северного побережья Кубы, не брезгуя мелкой добычей. Иногда спускались на юго-запад до Подветренных и Наветренных островов.^
	Многие английские и французские губернаторы земель, отторгнутых от Испании, жили с нами в полном согласии. В Англии и во Франции найдется немало семейств, чьи поместья были куплены на выручку от краденого добра, которое поставляли губернаторам Флинт и другие пираты.^ 
	В то время я плавал на «Морже», и с этим судном мы могли потягаться на ходу и в бою с любым судном в водах Мэйна. Девять из десяти кораблей, которым мы бросали вызов, поднимали белый флаг после первого же нашего выстрела. А если доходило до схватки, абордажный отряд в два счета расправлялся с врагом.^
	Иногда Флинт приводил захваченное судно в какой-нибудь порт, где и сбывал его по дешевой цене. Однако чаще он отпускал ограбленное судно, надеясь, что оно еще доставит ему хорошую добычу.^
	Если в бою с нами судно противника получало сильные повреждения, мы поджигали его и бросали на произвол судьбы вместе со строптивым капитаном.^
	Случалось, хоть и очень редко, что нам давали отпор. Однажды мы замахнулись на американский люгер, да только там были отменные пушкари, потому что мы получили дюжину пробоин и потеряли бизань-мачту. Пришлось улепетывать на Гренадины, где мы зализывали свои раны.^
	Да, Джим я многое, что могу тебе расскзать…]] },

	{ Silver, [[Джим, помнишь моего попугая? Он достался мне в качестве приза после того как мы взяли на абордаж испанский бриг у северного берега Кубы. Его звали «Пэдро». Умная птица.^ 
	Я вообще Джим люблю всякую живность. Не веришь? Ну и зря.^
	У меня одно время даже была ручная беломордая обезьянка. Я раздобыл ее на Мартинике. Она любила подолгу виснуть на вантах и кувыркаться на потеху нашим парням. Ребята в шутку прозвали ее «Епископом». Хех!  Она все время бормотала что-то неразборчивое - ни дать ни взять священник, читающий проповедь.^ 
	Обезьянка прожила на «Морже» довольно долго и успела стать всеобщей любимицей, но однажды ночью она добралась до запальных шнуров в пороховом погребе и чуть не подожгла корабль. После этого случая мне пришлось выпустить ее в джунгли на одном из Гренадинских островов.^
	Мда-а…]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[(поет)^
	<i>«Пятнадцать человек на сундук мертвеца.
	Йо-хо-хо, и бутылка рому!
	Пей, и дьявол тебя доведет до конца.
	Йо-хо-хо, и бутылка рому!»</i>

	Джим, а ты знаешь, про что эта песенка? Нет?! Ну, так слушай…^
	Когда мы плавали в Карибском море,  то обычно запасались пресной водой на одном из Подветренных островов. Это был даже не остров, а скорее длинная высокая скала, с виду напоминающая гроб. Мы называли ее «Сундук Мертвеца», и пиратская песенка, посвящена как раз этой скале.^ 
	За много лет до того на этом острове очутилось пятнадцать буканьеров, спасшихся с разбитого корабля. После крушения им удалось выловить лишь несколько бочонков рома, прибитых волнами к берегу. Есть, понятно, было нечего, и когда их подобрал один из проходящих мимо кораблей, все они были мертвецки пьяны...]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Когда я плавал с капитаном Инглендом, был у нас такой случай. В ту пору мы курсировали у берегов Мадагаскара в поисках легкой добычи. И вот однажды на горизонте заметили мачты двух кораблей. Это был торговый барк и бригантина под английскими флагами. Ингленд приказал их преследовать, и мы понеслись за ними на всех парусах.^
	Ближе к вечеру мы догнали барк и взяли его на абордаж. Команда не сопротивлялась. У них на борту не было ни пушек, ни мушкетов. Трюмы барка были забиты тюками чая. Этот товар был нам не нужен и ребята от злости начали просто выбрасывать эти чайные тюки в море. Когда эта забава всем надоела, мы подняли паруса. От капитана барка мы узнали, что бригантина, которой удалось далеко от нас уйти, была обычным почтовым судном и не имела в трюмах ничего ценного.^
	Однако капитан Ингленд приказал начать за ней погоню. Парни были в недоумении и решили, что Ингленд что-то разнюхал, когда допрашивал капитана торгового барка.^
	Два дня мы гнались за этой чертовой бригантиной и наконец, догнали ее.^
	Капитан Ингленд приказал никому не покидать корабля и сам в сопровождении всего четырех матросов отчалил на шлюпке к бригантине, которая приспустив все свои паруса, покорно покачивалась на волнах неподалеку от нас.^
	Капитан Ингленд один поднялся на борт бригантины и, не говоря ни слова, прошел мимо застывших в ужасе матросов и капитана прямиком в каюту, где в сундуке хранилась почта и личные вещи офицеров.^
	Через минуту он вышел оттуда и так же, не говоря ни слова, спустился в шлюпку и направился к нашему кораблю. Никто ничего не мог понять…^^

	Наши парни шептались, что в каюте Ингленд нашел что-то очень ценное и прячет это от команды. Особо горячие головы предлагали призвать Ингленда к ответу и потребовать свою долю.^
	Чуть позже, когда боцман напрямую спросил Ингленда, - Какого черта мы два дня гнались за этой бригантиной?! – капитан ответил, что он положил в сундук с почтой письмо для своей матушки.^
	Парни долго не могли поверить в это. Многие считали Ингленда жестоким и бессердечным пиратом. Но, как оказалось, к своей матушке он питал самые теплые чувства.]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Знавал я одного капитана по имени Хаксли. Он промышлял у берегов Индии и грабил корабли Ост-Индской компании. О его пиратах ходили самые невероятные слухи. Экипажи ограбленных им судов рассказывали, что пираты капитана Хаксли все как один огромного роста верзилы. Как ему удалось подобрать такую команду?...^
	Все разъяснилось спустя пару лет. Оказывается, этот хитрец Хаксли заставил всю свою команду ходить на ходулях и приказал пошить для них длинные штаны. С другого судна все пираты казались рослыми великанами и вызывали ужас у подвергшихся нападению экипажей кораблей.^^

	Хех! Бывает же такое!...]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Вспомнил я тут одну забавную историю!^
	Один отставной майор по имени Боннет владел на Барбадосе плантацией сахарного тростника. Он был женат.^
	Жена пилила его днем и ночью, превратив его жизнь в сущий ад. В конце концов Боннет не выдержал. Сухопутный человек, не нюхавший морского воздуха и не имеющий никакого представления о корабельной жизни, он махнул рукой на все блага цивилизации и удрал на пиратском корабле, только бы быть подальше от жены.  Боннет со временем стал помощником капитана. Пошел вдоль юго-восточного побережья Северной Америки и пиратствовал сначала вместе с Тичем, затем самостоятельно, пока не был схвачен и повешен на одной из стоянок во время килевания судна.^
	Мда-а… Это ж надо было так сварливой жене довести мужа, чтобы он от нее сбежал к пиратам!! Хе-хе!!]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Джим, а ты не слышал историю про «Свинцовый галеон»? Нет. Так слушай…^^

	Однажды капитан Ориньи узнал от лазутчиков, что неподалеку от Подветренных островов на рифах сел на мель испанский галеон «Сан-Розарио». Он быстро направил свое судно к тем местам, намереваясь, пока к испанцам не подошла помощь – ограбить судно.^
	Каково же было удивление и досада Ориньи и его команды, когда на борту испанца они обнаружили лишь свинцовые слитки.  Ограбив на судне все самое ценное, Ориньи удалился прочь. Один из его матросов захватил с собой пару свинцовых слитков, чтобы выплавить из них пули для мушкета. Когда он начал их плавить то обнаружил, что эти слитки серебряные. Хитрые испанцы лишь сверху покрыли слитки свинцом!^
	Когда Ориньи узнал про свою оплошность, то чуть было не застрелился от досады. Это же надо! Так глупо упустить из рук свою Удачу!]] },

	{ {Silver, Blind_Pew, Billy_Bons}, [[Джим, ты наверняка слышал историю о «Летучем голландце»? Да?!^
	А знаешь ли ты откуда взялась эта легенда?... Нет?^
	Ну так я тебе расскажу.^^

	Впервые призрак «Летучего голландца» встретил английский фрегат «Корона» у мыса Доброй Надежды. Фрегат шел вдоль скалистого побережья южной Африки, солнце начало подниматься над горизонтом, как вдруг вся команда увидела, как из дымки между фрегатом и берегом возник корабль. Он на всех парусах двигался прямиком на прибрежные скалы.^
	Все застыли в изумлении. Откуда взялся этот корабль непонятно! Еще немного и судно разобьется в щепки о скалы. И тут корабль словно растворился в воздухе.^
	С тех пор в этом самом месте призрак «Летучего голландца» видело еще несколько проплывающих мимо кораблей. Свидетелей этого явления было много. Капитаны кораблей считали, что появление этого призрака сулит несчастье.^
	Однако, спустя несколько лет один ученый грамотей, проплывая у этих мест, оказался свидетелем явления призрака.^
	Этот ученый оказался весьма дотошным малым и выявил причину появления «Летучего голландца». Всему виной было солнечное освещение, утренняя дымка над океаном и прибрежная скала, которая странным образом напоминала силуэт парусного судна. Скала создавала живое марево над поверхностью океана, которое было похоже на парусник. Как только солнце поднималось немного выше к зениту – призрак исчезал.^^

	Вот такая история. Хе-хе!... Признайся Джим, а ты ведь наверняка верил в реальность существования «Летучего голландца». Верно? По глазам вижу, что верил. Ах-ха-ха!!!]] },
}
