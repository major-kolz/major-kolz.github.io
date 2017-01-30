marker = txttab(13) .. "• "
p168_img = 'img/locations/p168.png;img/image_frame.png'

local function w(text) -- write
	pn( txttab(10) .. text )
end

--====================| Предметы |====================-- 
-- Сие безобразие с xact'ами в именах творится ради нескольких кнопок в ряд в инвентаре
myself = xact('', function() 
	local self = ref(arg1)
	local t = type(self.inv)
	if t == "function" then
		self:inv()
	else
		p( self.inv )
	end
end)
this_item = xact('', function()
	ref(arg1):act()
end)
rem_item = xact( '', function()
	drop_it:used( ref(arg1) )
	return true
end)
use_wpn = xact( '', function()
	local it = ref(arg1)
	if pl_fighter._weaponSlot == it then
		pl_fighter._weaponSlot = false
		p "[В бою вы не будете использовать дополнительное оружие]"
	else
		pl_fighter._weaponSlot = it
		p "[Вы будете использовать это оружие в бою]"
	end
	return true
end)

function equip(v)
	local old_disp = v.disp
	v.disp = function(s)
		local view;

		local h = here()
		if h == p296 or h == p168_supply or h == p168_mech 
			or h == p168_main or h == p168_arsenal	
		then
			view = "{rem_item(" .. deref(s) .. ")|×" .. img 'blank:6x11' .. "}" .. txttab(25) 
		elseif (exist('fight!') and not disabled(exist('fight!'))) then
			if s.weapon then
				view = "{use_wpn(" .. deref(s) .. ")|¤" .. img 'blank:6x11' .. "}" .. txttab(25) 
			else
				view = txttab(25)
			end
		else
			view = txttab(13)
		end

		local reference = s.nam
		if old_disp then
			reference = old_disp(s)
		end
		view = view .. "{myself(" .. deref(s) .. ")|• " .. reference .. "}"
		if s._count then
			view = view .. " (" .. s._count .. ")"
		end
		if s == respirator then
			view = view .. " (8 шт.)"
		end

		return view
	end
	if v.dsc then
		local old_dsc = v.dsc;
		v.dsc = function(s)
			if not old_dsc(s) then
				return
			end

			p( "- {this_item(" .. deref(s) .. ")|" .. old_dsc(s) .. "}" )
			if s.desc then
				p( s.desc )
			end
			pn ''
		end
	else
		v.dsc = function(s)
			p( "- {this_item(" .. deref(s) .. ")|" .. s.nam .. "}" )
			if s.desc then
				p( s.desc )
			end
			pn ''
		end
	end

	v.act = function(s)
		if cargo_status.space > 0 then
			cargo_status.space = cargo_status.space - 1
		else
			prnd {
				"Нет места",
				"Больше нет места",
				"Больше снаряжения отряд не унесет",
			}
			return
		end
		if s.taking then
			p( s.taking )
		else
			p( "Вы взяли: " .. unfold(s.nam, true) )
		end
	
		if s._count then
			if exist(s, equipment) then
				s._count = s._count + (s.step or 1)
			else
				place(s, equipment)
				add_inv_pointer();
			end
		else
			add_inv_pointer();
			move(s, equipment)
		end
		if equipment._toOpen then
			disable(s)
		end
	end
	stead.add_var( v, { busy = false })

	return stat(v)
end

local function energ_equip(v)
	v.disp = function(s)
		if exist(accumulator, equipment) and accumulator._charge then
			return s.nam
		else
			return txtem(txtst(s.nam))
		end
	end

	local old_inv = v.inv
	v.inv = function(s)
		if exist(accumulator, equipment) and accumulator._charge then
			p(old_inv)
		else
			p[[Для работы устройства нужен заряженный аккумулятор]]
		end
	end

	return equip(v)
end

repair_kit = equip{
	_count = 1,
	nam = "Аптечка",
	apply = function(s)
		s._count = s._count - 1
		if s._count == 0 then
			disable(s)
		end
	end,
	inv = function(s)
		p[["Походной набор оказания мед. помощи, одноразовый". В наличии: ]]
		pn(s._count)
		p "^Если хотите дать Аптечку бойцу - воспользуйтесь меню бойца из списка \"Личный состав\""
	end,
};

explosive = equip {
	nam = "Взрывчатка",
	inv = [[Набор подрывника]];
}

repellent = equip {
	nam = "Репеллент";
	inv = "Баллон распылителя средства против насекомых",
}

modulator = energ_equip {
	nam = "Модулятор";
	desc = "-- при помощи акустических частот отпугивает ночью от лагеря некоторые виды тварей " .. txtem "(требует внешний источник питания)";
	inv = [[При помощи акустических частот отпугивает ночью от лагеря некоторые виды тварей]]
}

tent = equip {
	nam = "Палатка",
	inv = "Портативный полевой лагерь, рассчитанный на вместимость до 10 человек",
}

accumulator = equip {
	_charge = true;
	nam = "Аккумулятор";
	disp = function(s)
		if s._charge then
			return s.nam
		else
			return txtem( txtst(s.nam) )
		end
	end,
	inv = _if( '_charge',
		"Заряжен, судя по индикатору",
		"Аккумулятор полностью разряжен, от него и светодиод теперь не запитаешь"
	);
	desc = "-- переносная модель под <i>бытовой</i> разъём",
	apply = function(s)
		s._charge = false;
	end,
}

solar_panel = equip {
	nam = "Солнечная панель",
	desc = "для подзарядки аккумулятора";
	inv = [[Рулон гибкого фоточувствительного материала с коробкой преобразователя]];
}

alphinist_equip = equip {
	nam = "Альпинистское снаряжение";
	disp = function() return [[Альпин. снаряжение]]; end,
	inv = [[Тросы, крюки, карабины...]];
}

welding_unit = energ_equip {
	nam = "Сварочный аппарат",
	desc = txtem "(требует внешний источник питания)",
	inv = [[Хм...]];
}

scuba_equip = equip {
	nam = "Снаряжение аквалангиста",
	disp = function() return "Акваланг" end,
	inv = "Сложное технологическое приспособления, принцип действия которого для вас неведом"
}

respirator = equip {
	nam = "Респираторное оборудование",
	disp = function(s) return "Противогаз" end,
	inv = [[Обеспечивает полную защиту дыхательных путей до тех пор пока не истощится внутренняя батарее или окончательно не забьются фильтры]];
}

use_antistress = xact( '', function() 
	if not visited 'p4' then
		p "Сейчас нет необходимости в стимуляорах";
	else
		moral(40); disable 'antistress'; return true 
	end
end )
antistress = equip {
	nam = "Антистресс",
	inv = [[Отключает усталость, снимает чувство подавленности, вызывает легкую эйфорию (повышает показатель морали на сорок пунктов). [{use_antistress|Применить}] ]];
}

packed_lunces = equip {
	nam = "Провиант",
	_count = 3,
	step = 3,
	desc = "- индивидуальный походной рацион питания",
	taking = "Данный паек упакован в трехдневные блоки",
	eat = function(s)
		if not exist(packed_lunces, equipment) or packed_lunces._count <= 0 then
			pn[[У вашего отряда закончились припасы и вы вынуждены прекратить миссию.]];
			walk 'p560'
		end
		the_day = the_day + 1;
		s._count = s._count - 1;
		if s._count % 3 == 0 then
			cargo_status.space = cargo_status.space - 1;
		end
	end,
	inv = function(s)
		local day_case
		local num = s._count % 10

		if num == 1 then
			day_case = "день"
		elseif num ~= 0 and num < 5 then 
			day_case = "дня"
		else 
			day_case = "дней"
		end

		if here() == p168_mech or here() == p168_supply or here() == p168_main or here() == p168_arsenal then 
			p( "Провиант на " .. s._count .. " " .. day_case )
		else
			p( "Провианта осталось на " .. s._count .. " " .. day_case )
		end
	end,
}

packed_lunces_no = obj {
	nam = "Провиант",
	dsc = "- {Провиант} - индивидуальный базовый рацион питания^", 
	act = "Для наших целей - долгосрочная полевая операция - данный тип сухпая не подходит.",
}

laser_cutter = energ_equip{
	nam = "Лазерный резак";
	desc = txtem "(требует внешний источник питания)",
	inv = [[Хм... С помощью этой штуки можно вытащить бойца из покореженного бронекостюма. Или разобрать боевого дрона на куски. Если тот отключен.]];
}
--====================| Доп. оружие |====================-- 
function weapon_in_equip( v )
	v.weapon = true;
	local old_disp = v.disp
	v.disp = function(s)
		local view = s.nam
		if old_disp then view = old_disp(s) end
		if pl_fighter._weaponSlot == s then
			return txtu(view)
		else
			return view
		end
	end
	if v._count then
		v.apply = function(s)
			s._count = s._count - 1;
			cargo_status.space = cargo_status.space - 1;
			if s._count == 0 then
				remove(s, equipment)
			end
			return true
		end
	end

	return equip(v)
end

launcher_in_equip = weapon_in_equip{
	nam = "Гранатомёт";
	dsc = function(s)
		if not arsenal_tab1._on then
			if exist(s, equipment) then
				return txtem "Гранатомётный выстрел"
			else
				return "Гранатомёт"
			end
		end
	end,
	inv = function(s)
		pn( "Снарядов к орудию: " .. s._count );
		if seen "fight!" then
			p( txtem"[Чтобы экипировать оружие, нажмите на кнопку слева]" )
		end
	end,
	_count = 3;
}

flamethrower_in_equip = weapon_in_equip{
	nam = "Огнемёт";
	dsc = function(s)
		if not arsenal_tab1._on then
			if exist(s, equipment) then
				return txtem "Топливный баллон для огнемета"
			else
				return "Огнемёт"
			end
		end
	end,
	inv = function(s)
		pn( "Топливных баллонов осталось: " .. s._count );
		if seen "fight!" then
			p( txtem"[Чтобы экипировать оружие, нажмите на кнопку слева]" )
		end
	end,
	_count = 1;
	dice = { shot, shot, shot, shock, void, void };
}

acousticGun_in_equip = weapon_in_equip{
	nam = "Акустический пистолет",
	disp = function(s) return "Акустич. пистолет" end,
	reusable = true;
	inv = function(s)
	 	pn [[Не летальное оглушающее оружие]];
		if seen "fight!" then
			p( txtem"[Чтобы экипировать оружие, нажмите на кнопку слева]" )
		end
	end,
	dice = { shock, shock, void, void, void }; 
}

vibrationMachete_in_equip = weapon_in_equip{
	nam = "Вибро-мачете",
	desc = "-- пригодно как оружие ближнего боя, так и для разрезания лиан и небольших стволов",
	reusable = true;
	inv = function(s)
	   pn [[Для разрезания лиан и небольших стволов деревьев]]
		if seen "fight!" then
			p( txtem"[Чтобы экипировать оружие, нажмите на кнопку слева]" )
		end
	end,
	dice = { shot, shot, shot, void, void, void };
}

infrasoundShield_in_equip = weapon_in_equip{
	nam = "Инфразвуковой щит",
	reusable = true;
	dice = { masterShield, masterShield, void, void, void, void };
	inv = function(s)
		pn[[Генерирует компактный защитный купол]];
		if seen "fight!" then
			p( txtem"[Чтобы экипировать оружие, нажмите на кнопку слева]" )
		end
	end,
}

--====================| Интерфейс подбора экипировки |====================-- 
cargo_status = stat {
	var {
		space = 24;
	},
	nam = _say( txttab(25) .. txtem "Места свободно: @space" )
}

drop_it = obj {
	nam = txttab(10) .. txtb "Выложить",
	inv = "Чтобы удалить предмет из списка - используйте его на этот элемент",
	where_was = {
		repair_kit = 'p168_mech',
		repellent = 'p168_mech',
		modulator = 'p168_mech',
		tent = 'p168_mech',
		solar_panel = 'p168_mech',
		accumulator = 'p168_mech',
		welding_unit = 'p168_mech',
		laser_cutter = 'p168_mech',
		launcher_in_equip = 'arsenal_tab2',
		flamethrower_in_equip = 'arsenal_tab2',
		acousticGun_in_equip = 'arsenal_tab2',
		vibrationMachete_in_equip = 'arsenal_tab2',
		infrasoundShield_in_equip = 'arsenal_tab2',
		explosive = 'arsenal_tab2',
		alphinist_equip = 'p168_supply',
		respirator = 'p168_supply',
		scuba_equip = 'p168_supply',
		antistress = 'p168_supply',
		packed_lunces = 'p168_supply',
	},
	use = function(s, w) s:used(w) return true end,
	used = function(s, w)
		local to = s.where_was[ deref(w) ]
		if w._count and w._count > (w.step or 1) then
			w._count = w._count - (w.step or 1)
			cargo_status.space = cargo_status.space + 1
		else
			cargo_status.space = cargo_status.space + 1
			drop(w, ref(to) )
			redraw_inv_pointers()
			remove(w, equipment)
		end
		if to == 'arsenal_tab2' then
			arsenal_tab2:act()
		end
		return true
	end,
}

p168_main = room {
	nam = true,
	pic = p168_img,
	entered = function(here, from)
		if from == p168 then
			theme.inv.geom(588, 50, 195, 523)

			format.para = false;
			take 'equipment'
			place( cargo_status, equipment )
			take 'crew'
			disable_all( team.obj )
			disable_all( arsenal_tab2.obj )

			place( packed_lunces, equipment ); packed_lunces._count = 15
			place( tent, equipment )
			place( repellent, equipment )
			place( launcher_in_equip, equipment );
			cargo_status.space = 10
			
			the_item_counter = 5 -- пять предметов в equipment (с cargo_status)
			equipment._toOpen = true;
			equipment:menu()
			crew._toOpen = false;
			crew:menu()
		end
	end,
	exit = function(s, to)
		if to == p169 then
			if not p168_arsenal._getWeapon then
				p "Решено, что отряд будет вооружен \"Янусом\" - нужно составить соответствующий запрос в арсенал"
				return false;
			end
			if packed_lunces._count == 15 then
				p "В выбранном вами шаблоне предусматривалась усредненная операция в пятнадцать дней. Ваша же миссия, расчетно, может занять двадцать дней. Нужно взять больше провианта"
				return false
			end
			if packed_lunces._count < 20 then
				p "Маловато провианта... Ориентировочная длительность операции целых 20 дней!"
				return false
			end
			if packed_lunces._count > 21 and not s.warning then
				p "Многовато получилось провианта, с большим запасом"
				s.warning = true
				return false
			end
			if cargo_status.space > 3 then
				p "Отправиться налегке, идея, в общем-то, хорошая. Но не для столь длительной операции. Лучше взять еще что-то..."
				return false
			end
			if exist(welding_unit, equipment) and not exist (accumulator, equipment) then
				p[[Сварочный аппарат не будет работать без аккумулятора]]
				return false
			end
			if exist(modulator, equipment) and not exist (accumulator, equipment) then
				p[[Модулятор не будет работать без аккумулятора]]
				return false
			end
			if exist(laser_cutter, equipment) and not exist (accumulator, equipment) then
				p[[Резак не будет работать без аккумулятора]]
				return false
			end

			format.para = true;
			theme.inv.geom(600, 50, 185, 523)
			sprite.free( spr.background )
			spr.background = sprite.load 'img/bg.png'
			theme.gfx.bg( spr.background )
			remove( cargo_status, equipment )
			remove( drop_it, equipment )
		end
	end,
	obj = {
		'headline', 'team',
		xact( 'register', "Под этим шифром материалы хранятся в базе данных и, теоретически, любой знающий его может к ним обратится. На практике, все упирается в уровни допуска.^ Младшему офицерскому составу доступны лишь рассекреченные старые операции -- для ознакомления, передачи опыта." ),
		xact( 'lieutenant', "Ссылка на ваше личное дело. Все обращения фиксируются и анализируются службой безопасности на предмет нездорового любопытства." ),

		vway( 'configrm', '^' .. txtc "{Завершить экипировку} ", 'p169' ),
	},
	way = {
		vroom( [["Мех.отдел"]], 'p168_mech' ),
		vroom( [["Арсенал"]], 'p168_arsenal'),
		vroom( [["Снабжение"^]], 'p168_supply' ), 
	},
}

headline = obj{
	nam = true;
	_open = true;
	_hided = false;
	dsc = function(s)
		if not s._hided then
			if s._open then
				pn "[-] {Описание}"
				w "Шифр: {register|XKRT-200749-Q4}"
				w [[Кодовое имя: "Планета Анунак"]]
				w "Командир: {lieutenant|лейтенант Ирвин}"
				w "Расчетная длительность: 20 дней"
			else
				p "[+] {Описание}^"
			end
		else
			s._hided = false;
		end
	end,
	act = function(s) 
		team._open = false;
		disable_all( team.obj )
		s._open = not s._open; 
		return true 
	end,
}

team = obj{
	nam = true,
	_open = false,
	dsc = _if( '_open', "^[-] {Оперативная группа}^", "^[+] {Оперативная группа}^" ),
	act = function(s)
		headline._open = false
		s._open = not s._open;
		if s._open then
			enable_all( s.obj )
		else
			disable_all( s.obj )
		end
		return true
	end,
	obj = {
		'armor_headline', 'Ralf_armor', 'Vince_armor', 'Wayne_armor', 
		'Zed_armor', 'Spike_armor', 'Dave_armor', 'Lloyd_armor', 'Irwin_armor',
	},
};

function armor()
	local v = {}
	v.nam = true;
	v._powerArmor = true;
	v.who = function(s)
		local iam = deref(s)
		return ref( iam:sub( 1, iam:find('_')-1 ) )
	end
	v.dsc = function(s)
		p( txttab(10) .. s:who().nam )
		if p168_arsenal._getWeapon then
			p( txttab'25%' .. [["Янус" М-2]] )
		else
			p( txttab'33%' .. [[-]] )
		end

		local armor_selector
		if s._powerArmor then
			armor_selector = "{Экзоскелет}" .. txttab'68%' .. "| <b>Бронекостюм</b>"
		else
			armor_selector = "<b>Экзоскелет</b>" .. txttab'68%' .. "| {Бронекостюм}"
		end
		pn( txttab'50%' .. armor_selector )
	end
	v.act = function(s)
		s._powerArmor = not s._powerArmor
		headline._hided = true
		if s._powerArmor then
			cargo_status.space = cargo_status.space - 1
			p "Классическая версия боевого костюма пехоты. Приличная защита, неплохая маневренность и автономность";
			s:who().me._hp = 4
			s:who().me._currLife = 4
		else
			cargo_status.space = cargo_status.space + 1
			s:who().me._hp = 3
			s:who().me._currLife = 3
			p "Облегченная версия, с минимумом брони. За счет освободившегося веса боец может нести больше поклажи";
		end
		return true
	end
	return obj(v)
end

armor_headline = obj{
	nam = true,
	dsc = txtu( txttab(10) .. "Имя" .. txttab'25%' .. [[Вооружение]] .. txttab'58%' .. "Обмундирование") .. "^"
}

Irwin_armor = armor()
Lloyd_armor = armor()
Dave_armor = armor()
Spike_armor = armor()
Zed_armor = armor()
Wayne_armor = armor()
Vince_armor = armor()
Ralf_armor = armor()

---------------------
p168_arsenal = room{
	nam = true,
	pic = p168_img;
	_getWeapon = false;
	obj = {
		'arsenal_tab1', 'arsenal_tab2', 'arsenal_tab1_obj'
	}, 
	way = {
		vroom( "Назад^", 'p168_main' ),
	},
}

arsenal_tab1 = obj{
	nam = true;
	_on = true;
	dsc = function(s)
		if s._on then
			p( txtu [[Основное оружие]] );
		else
			p [[{Основное оружие}]];
		end
	end,
	act = function(s)
		s._on = true;
		enable_all(arsenal_tab1_obj);
		arsenal_tab2.obj:disable_all();
		enable 'launcher_in_equip'
		enable 'flamethrower_in_equip'
		return true;
	end,
}

arsenal_tab1_obj = obj{
	nam = true;
	obj = {
		'wpn1',
		'wpn2', 
		'wpn3',
		'wpn4',
		'wpn5',
	},
};

arsenal_tab2 = obj{
	nam = true;
	dsc = function(s)
		if not arsenal_tab1._on then
			p( txtu [[Дополнительно]] );
		else
			p [[{Дополнительно}]];
		end
		pn "^"
	end,
	act = function(s)
		arsenal_tab1._on = false;
		s.obj:enable_all();
		disable_all(arsenal_tab1_obj);
		return true;
	end,
	obj = {
		'launcher_in_equip', 'flamethrower_in_equip', 'acousticGun_in_equip', 
		'vibrationMachete_in_equip', 'infrasoundShield_in_equip', 
		'explosive'
	},
}

wpn1 = obj{
	nam = true,
	dsc = [[- {"Зевс"} -- плазменная автоматическая пушка]],
	act = function(s)
		p [["Нулевая тактическая эффективность для столь малого отряда"]]
	end,
}

wpn2 = obj{
	nam = true,
	dsc = [[^- {"Янус"} -- гибридная штурмовая винтовка]],	
	act = function(s)
		p [["Оружие выполнено в излишне громоздком формакторе"]]
	end,
}

wpn3 = obj{
	nam = true,
	dsc = function(s)
		local link = [["Янус" М-2]]
		if p168_arsenal._getWeapon then
			link = txtb(link)
		end
		p( "^- {" .. link .. "} -- гибридная штурмовая винтовка, модифицированная" )
	end,
	act = function(s)
		p "Вы составляете запрос и прикрепляете его к профилю миссии"
		p168_arsenal._getWeapon = true
	end,
}

wpn4 = obj{
	nam = true,
	dsc = [[^- {"Баал"} -- тактический дротикомет]],
	act = function(s)
		p [["Полезен лишь для операций в духе скрытного проникновение"]]
	end,
}

wpn5 = obj{
	nam = true,
	dsc = [[^- {"Дажьбог"} -- кинетический карабин дальнего радиуса действия^^]],
	act = function(s)
		p [["В условиях джунглей дистанционного боя не бывает"]]
	end,
}

p168_supply = room{
	nam = true,
	pic = p168_img;
	obj = {
		'antistress', 'respirator', 'alphinist_equip', 'scuba_equip', 'packed_lunces_no', 'packed_lunces'
	}, 
	way = {
		vroom( "Назад^", 'p168_main' ),
	}
};

p168_mech = room{
	nam = true,
	pic = p168_img;
	obj = {
		'modulator', 'repair_kit', 'accumulator', 'solar_panel',  'welding_unit', 'laser_cutter'
	}, 
	way = {
		vroom( "Назад^", 'p168_main' ),
	}
};
