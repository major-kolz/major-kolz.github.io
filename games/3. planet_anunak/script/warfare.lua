pl_fighter = player {
	nam = "Бой",
	_weaponSlot = false;
	_equipedWeapon = "-";
	obj = {
		'ui_hint',  'throw_again', 'roundEnd_but',
		'win', 'loose_battle', 'flee', 'persuade', 'capture', 'stats'
	},
}

local function throw_dices()
	disable 'ui_hint'
	disable 'roundEnd_but'
	add_sound( 'snd/dicing' .. math.floor(rnd(3)) .. '.ogg' )
	here()._diceAnimationCounter = 5  -- Логика рисования - в timer'е battle-комнат
	timer:set( 50 )
end

local function setup_additional_weapon()
	local weaponName = pl_fighter._weaponSlot
	if not weaponName then
		slot1 = no_weapon
	else
		weaponName = deref(weaponName)
		weaponName = weaponName : sub( 1, weaponName:find'_' -1)
		here()._addWpnSpr = sprite.load( 'img/equip/' .. spr_equip[weaponName] .. '.png' )
		slot1 = ref(weaponName)
		if slot1 == launcher or slot1 == flamethrower then
			if slot1._count and slot1._count > 0 then
				slot1._hp = 1;
			end
		end
		sprite.copy( here()._addWpnSpr, here().pic, 7, crew_faces_drawing_line )
	end
end

local function enemy_slots_pos()
	local requared_slots = #(here().dices)
	if requared_slots == 2 then
		return { 83, 423 }
	elseif requared_slots == 3 then
		return { 18, 88, 453 }
	elseif requared_slots == 4 then
		return {18, 88, 418, 488}
	else
		error( "Тут что-то напутано с числом слотов у " .. deref(here()) )
	end
end

local function draw_enemy_slots()
	local back_edge
	for dice, pos in ipairs( enemy_slots_pos() ) do
		back_edge = sprite.box(51, 51, '#cc4242');	
		sprite.copy( back_edge, spr.backing, pos, enemy_dices_drawing_line )
	end
	sprite.free(back_edge)
end

local function throw_crew_dices( canvas, isShacking )
	isErr( not canvas, "Не на чем рисовать" )
	for i = 1, 9 do
		local slot = ref( 'slot' .. i )
		local pos = 7 + (i-1)*60

		slot._defenced = false   -- do not pass shield to next round
		
		if slot._isDead then
			dice = spr.crew_dices[spr_dice_indexes.dead]
			sprite.copy( dice, canvas, pos, crew_faces_drawing_line )
			dice = false
		elseif slot._currLife <= 0 then
			if i == 1 and slot1._isSpent then -- weapon
				-- dice = false
			else
				dice = spr.crew_dices[spr_dice_indexes.harmed]
				sprite.copy( dice, canvas, pos, crew_faces_drawing_line )
				dice = spr.crew_dices[spr_dice_indexes.void]
			end
			dice = false
		elseif slot._flighted then
			dice = false
		elseif slot._knockdown then
			if i == 1 then
				sprite.copy( here()._addWpnSpr, canvas, 7, crew_faces_drawing_line )
			end
			sprite.compose( spr.blackout, 0, 0, 50, 50, canvas, pos, crew_faces_drawing_line )
			dice = spr.enemy_dices[spr_edice_indexes.ram]
		else
			if i == 1 and not slot1._isSpent then
				sprite.copy( here()._addWpnSpr, canvas, 7, crew_faces_drawing_line )
			end
			dice = slot:dicing(isShacking)
		end

		if dice then
			local x = pos
			local y = crew_dices_drawing_line
			if isShacking then
				x = x + rnd(3) - 1
				y = y + rnd(3) - 1 -- +/- 2 пикселя
			end
			sprite.copy( dice, canvas, x, y )
		end
	end
end

local function throw_enemy_dices( canvas, isShacking )
	isErr( not canvas, "Не на чем рисовать" )
	local battle = here()
	local edges 
	local y = enemy_dices_drawing_line
	for diceNum, x in ipairs( enemy_slots_pos() ) do
		if battle._shock > 0 then
			battle._shock = battle._shock - 1
			edge = spr.crew_dices[spr_dice_indexes.shock]
		else
			edge = battle.dices[diceNum][rnd(6)](not isShacking)
		end

		if isShacking then
			sprite.copy( edge, canvas, x + rnd(3) - 2, y + rnd(3) - 2 )
		else
			sprite.copy( edge, canvas, x, y )
		end
	end
end

local draw_health_bar = function(canvas)
	isErr( not canvas, "Не на чем рисовать" )
	local man
	for i = 1, 9 do
		man = ref( 'slot' .. i )
		if not man._flighted then
			for hp_i = 1, man._hp do
				local x = 7 + (i-1)*60 + (hp_i-1)*13
				if hp_i <= man._currLife then
					sprite.copy( spr.hp, canvas, x, crew_hpbar_drawing_line)
				else
					sprite.copy( spr.hp_blank, canvas, x, crew_hpbar_drawing_line)
				end
			end
		end
	end
end

local draw_enemy_hp = function(canvas)
	isErr( not canvas, "Не на чем рисовать" )
	for hp_i = 1, here().hp do
		local y = enemy_hp_bar_y + (hp_i-1)*13
		if hp_i <= here()._health then
			sprite.copy( spr.hp, canvas, enemy_hp_bar_x, y )
		else
			sprite.copy( spr.hp_blank, canvas, enemy_hp_bar_x, y )
		end
	end
end

local function describe_selected_person(x, y)
	for i = 1, 9 do
		if x > 7 + (i-1)*60 and x < 56 + (i-1)*60 then
			local who = ref( 'slot' .. i )
			if i == 1 then -- additional weapon
				stats.who = slot1.nam
			else
				stats.who = ref( who.nam ).nam
			end

			if who._isDead then
				stats.status = "мёртв"
			elseif who._flighted then
				stats.status = "бежал"
			elseif who._currLife <= 0 then
				if who == no_weapon then
					stats.status = "отсутствует"
				else
					if i == 1 then
						stats.status = "повреждено"
					else
						stats.status = "небоеспособен"
					end
				end
			elseif who._knockdown then
				stats.status = "оглушён"
			else
				stats.status = ""
				sprite.copy( who.dice[1](), stats.desc, 52, 1)
				sprite.copy( who.dice[2](), stats.desc, 52, 52)
				sprite.copy( who.dice[3](), stats.desc, 1, 103)
				sprite.copy( who.dice[4](), stats.desc, 52, 103)
				sprite.copy( who.dice[5](), stats.desc, 103, 103)
				sprite.copy( who.dice[6](), stats.desc, 52, 154)
			end

			return
		end
	end
end

local function describe_enemy_dice(x, y)
	local enemy = here()
	stats.who = "x" .. #(enemy.dices)
	sprite.copy( enemy.dices[1][1](), stats.desc, 52, 1)
	sprite.copy( enemy.dices[1][2](), stats.desc, 52, 52)
	sprite.copy( enemy.dices[1][3](), stats.desc, 1, 103)
	sprite.copy( enemy.dices[1][4](), stats.desc, 52, 103)
	sprite.copy( enemy.dices[1][5](), stats.desc, 103, 103)
	sprite.copy( enemy.dices[1][6](), stats.desc, 52, 154)
end

--====================| Грани бойцов |====================-- 
local shield = function(self)
	if self then -- self == nil -> want sprite for dice description 
		self._defenced = true;
		here()._capturing = here()._capturing + 1;
	end
	return spr.crew_dices[spr_dice_indexes.shield];
end

local shock = function(self)
	if self then
		here()._shock = here()._shock + 1;
	end
	return spr.crew_dices[spr_dice_indexes.shock]	
end

local flight = function(self)
	local icon = spr.crew_dices[spr_dice_indexes.flight]
	if self then
		if here()._flightPrevent then
			here()._flightPrevent = false
			self._flighted = false
			icon = spr.crew_dices[spr_dice_indexes.void]
		else
			self._flighted = true
		end
	end

	return icon
end

local IrEye = function(self)
	if self then
		--here()._damage = here()._damage + 1;
		self._fireControl = true
	end
	return spr.crew_dices[spr_dice_indexes.eye]
end

local shot = function(self)
	local icon = spr.crew_dices[spr_dice_indexes.shot]
	if self then
		local r = here()
		if r._shockPrevent then
			r._shockPrevent = false
			r._shockPreventing = true
			icon = spr.crew_dices[spr_dice_indexes.void]
		else
			r._damage = r._damage + 1;
		end
	end
	return icon
end

local explode = function(self)
	if self then
		here()._damage = here()._damage + 5;
		here()._addWpnAttacked = true
	end
	return spr.crew_dices[spr_dice_indexes.shot]
end

local void = function(self) 
	if  self then
	end
	return spr.crew_dices[spr_dice_indexes.void]
end

local masterShield = function(self)
	if self then
		self._defenced = true;
		here()._masterShield = true;
	end
	return spr.crew_dices[spr_dice_indexes.shield]
end

--====================| Бойцы |====================-- 
function slot(v)
	v._currLife = v._hp
	v._knockdown = false;
	v._flighted = false;
	v._defenced = false;
	v._isDead = false;

	v.dsc = false;
	if not v.dicing then
		v.dicing = function(s, isShacking)
			if s._knockdown then
				return spr.enemy_dices[spr_edice_indexes.ram]
			else
				if isShacking then	-- не изменяет состояния бойца (просто получить какой-то спрайт)
					return s.dice[rnd(6)]( )
				else
					return s.dice[rnd(6)]( s )
				end
			end
		end
	end

	return obj(v);
end

slot1 = {} -- Дополнительное оружие
slot2 = slot{ nam = "Ralf",  _hp = 4, dice = {shot, shot, flight, shield, flight, void}, }
slot3 = slot{ nam = "Vince", _hp = 4, dice = {shot, shot, void, shot, void, void}, }
slot4 = slot{ nam = "Wayne", _hp = 4, dice = {shot, shot, shield, shield, shield, void}, }
slot5 = slot{ nam = "Zed",   _hp = 4, dice = {shot, shot, shield, shot, flight, void}, }
slot6 = slot{ nam = "Spike", _hp = 4, dice = {shot, shot, flight, flight, flight, shield}, }
slot7 = slot{ nam = "Dave",  _hp = 4, dice = {shot, shot, shield, flight, shield, void}, }
slot8 = slot{ nam = "Lloyd", _hp = 4, dice = {shot, shot, shield, void, shield, flight}, }
slot9 = slot{ nam = "Irwin", _hp = 4, dice = {shot, shot, IrEye, IrEye, IrEye, void}, }

--====================| Дополнительное оружие |====================-- 
function addWpn( v )
	if not v._isSpent then
		v._isSpent = false;
	end
	if not v._hp then
		v._hp = 1;
	end
	v.dicing = function(s, isShacking)
		if isShacking then
			return s.dice[rnd(6)]()
		else
			if s.reusable then
				s._isSpent = false
				s._currLife = s._hp
			end
			return s.dice[rnd(6)]( s )
		end
	end
	return slot(v)
end

no_weapon = addWpn{
	nam = "Доп. оружие",
	_isSpent = true;
	_hp = 0;
	dice = { void, void, void, void, void, void };
}

launcher = addWpn{
	nam = "Гранатомёт",
	dice = { explode, explode, explode, void, void, explode };
}

flamethrower = addWpn{
	nam = "Огнемёт",
	dice = { explode, explode, explode, void, shot, void };
}

acousticGun = addWpn{
	nam = "Акустич. пистолет",
	reusable = true;
	dice = { shock, shock, void, void, void, void }; 
}

vibrationMachete = addWpn{
	nam = "Вибро-мачете",
	reusable = true;
	dice = { shot, shot, shot, void, void, void };
}

infrasoundShield = addWpn{
	nam = "Инфразвуковой щит",
	reusable = true;
	dice = { masterShield, masterShield, void, void, void, void, };
}

--====================| Грани противников |====================-- 
m_jaw = function(isReal)
	if isReal then
		here()._enemyDamage = here()._enemyDamage + 2
	end
	return spr.enemy_dices[spr_edice_indexes.jaw]
end

m_shot = function(isReal)
	if isReal then
		here()._enemyDamage = here()._enemyDamage + 2
	end
	return spr.enemy_dices[spr_edice_indexes.shot]
end

m_claws = function(isReal)
	if isReal then
		here()._enemyDamage = here()._enemyDamage + 1
	end
	return spr.enemy_dices[spr_edice_indexes.claws]
end
m_claws = function(isReal)
	if isReal then
		here()._enemyDamage = here()._enemyDamage + 1
	end
	return spr.enemy_dices[spr_edice_indexes.claws]
end

m_flight = function(isReal) 
	if isReal then
		here()._wantFlight = here()._wantFlight + 1
	end
	return spr.enemy_dices[spr_edice_indexes.flight]
end

m_defence = function(isReal) 
	if isReal then
		here()._defenced = true
	end
	return spr.enemy_dices[spr_edice_indexes.defence]
end

m_ram = function(isReal)
	local icon = spr.enemy_dices[spr_edice_indexes.ram]
	local r = here()
	if isReal then
		if r._shockPreventing then
			r._shockPreventing = false
			icon = spr.enemy_dices[spr_edice_indexes.void]
		else
			r._raming = true;
		end
	end
	return icon
end

m_nothing = function()
	return spr.enemy_dices[spr_edice_indexes.nothing]
end

--====================| Интерфейс |====================-- 
ui_hint = stat {
	nam = "^^" .. txttab(10) .. "Выбор тактики:",
	obj = {
		'moral_support', 'fire_control', 'total_defence', 'camouflage', 'maneuver'	
	},
}

tactic_tip = xact( '', function() 
	switch(tonumber(arg1)){
		[[Отменяется одна выпавшая иконка Бегства у отряда]],
		[[Если у командира выпадет иконка Глаз, то к атаке отряда бонус +2]],
		[[Отменяет все Шоковые грани врага за -1 к атаке отряда]],
		[[Дает право единожды перебросить кубики врага]],
		[[Дает право единожды перебросить кубики отряда]],
	}
end)
tactic_go = xact( '', function() 
	p( ref(arg1):menu() )
end)

tactic = function(v)
	v.disp = function(s) 
		local view = txttab(17)
		view = view .. "{tactic_go(" .. deref(s) .. ")|" .. s.nam .. "}"
		view = view .. txttab(191)
		view = view .. "{tactic_tip(" .. v.n .. ")|·" .. img 'blank:10x9' .. "}" 
		return view
	end
	v.menu = function(s)
		hide_tactic_tips()
		throw_dices()
		here()._tactic = s.n
	end

	return stat(v)
end

moral_support = tactic {
	nam = "Моральная поддержка",
	n = 1,
};
	
fire_control = tactic {
	nam = "Управление огнем",
	n = 2,
};

total_defence = tactic {
	nam = "Глухая оборона",
	n = 3,
};

camouflage = tactic {
	nam = "Маскировка",
	n = 4,	
};

maneuver = tactic {
	nam = "Маневрировать",
	n = 5
};

throw_again = menu {
	nam = '^^^^' .. txtc "Перебросить кости" .. "^",
	menu = function(s)
		run_interphase(here())
		return true;
	end,
};

roundEnd_but = menu {
	nam = function(s) 
		if disabled 'ui_hint' and disabled 'throw_again' then
			p "^^^^^"
		end
		p( txtc "Конец раунда" )
	end,
	menu = function(s)
		phase2( here() );
		return true;
	end,
};

win = menu {
	nam = txtc "^^^^^Победа^",
	menu = function(s)
		walk( here().won )
	end,
}:disable();

loose_battle = menu {
	nam = txtc "^^^^^Проигрыш^",
	menu = function(s)
		lossItems(2)
		walk( here().loose )
	end,
}:disable();

flee = menu {
	nam = txtc "^^^^^Противник сбежал^",
	menu = function(s)
		walk( here().won )
	end,
};

persuade = menu {
	nam = txtc "^^^^^Переговоры^"
}:disable();

capture = menu {
	nam = txtc "^^^^^Схватить^",
	menu = function(s)
		
	end,
}:disable();

stats = stat {
	nam = true,
	var {
		who = "-";
		status = ""
	},
	desc = sprite.load 'img/dice_desc.png';
	disp = function(s)
		if disabled 'ui_hint' and disabled 'throw_again' then 
			if disabled 'roundEnd_but' then
				if here()._diceAnimationCounter > 0 then
					pn '^^^^^^^^^^' -- бросаем кубики
				else
					pn '^^^'
				end
			else
				pn '^^^^'
			end
		else
			if disabled 'roundEnd_but' then
				pn '^^'
			else
				pn '^^^'
			end
		end

		local about
		if s.status == "" then 
			about = img( s.desc )  
		else
			about = "[" .. txtem( s.status ) .. "]"
		end
		
		p( txtc( "^^^^" .. img 'blank:4x1' .. s.who .. "^" .. img 'blank:4x1' .. about ) )
	end,
}

--====================| Логика боя |====================-- 
function phase1(battle)
	local scene_with_dices = sprite.dup(spr.backing)
	local dice = {}
	local used_tactic = battle._tactic
	battle:reset()


	if used_tactic == 1 then
		here()._flightPrevent = true
	elseif used_tactic == 3 then
		here()._shockPrevent = true
	end

	throw_crew_dices( scene_with_dices )
	throw_enemy_dices( scene_with_dices )

	if used_tactic == 2 then
		if slot9._fireControl and battle._damage > 0 then
			battle._damage = battle._damage + 2
		end
	end

	disable 'ui_hint'
	if battle.canCapture and battle._capturing == 4 then
		enable 'capture'
	else
		if used_tactic == 4 or used_tactic == 5 then
			enable 'throw_again'
		end
		enable 'roundEnd_but'
	end

	battle._scene_without_hp = sprite.dup(scene_with_dices);
	draw_health_bar(scene_with_dices)
	draw_enemy_hp( scene_with_dices )
	battle.pic = scene_with_dices -- refresh scene
end

function run_interphase( battle )
	battle._secondThrow = true
	local scene = battle._scene_without_hp
	disable 'throw_again'

	if battle._tactic == 5 then
		local x = 7
		local y = crew_dices_drawing_line
		sprite.copy( spr.backing, x, y, 552, 50, scene, x, y )
	else
		local x = 18
		local y = enemy_dices_drawing_line
		sprite.copy( spr.backing, x, y, 140, 50, scene, x, y )
		x = 418
		sprite.copy( spr.backing, x, y, 140, 50, scene, x, y )
	end

	throw_dices()
end

function interphase( battle )
	local scene = battle._scene_without_hp
	enable 'roundEnd_but'

	if battle._tactic == 5 then
		battle._damage = 0;
		battle._shock = 0;
		battle._capturing = 0;
		battle._masterShield = false;
		throw_crew_dices(scene)
	else
		battle._defence = 0;
		battle._raming = false
		battle._enemyDamage = 0;
		battle._wantFlight = 0;
		throw_enemy_dices(scene)
	end
	draw_health_bar(scene)
	draw_enemy_hp(scene)

	battle.pic = scene
end

function battle_done( battle )
	disable 'ui_hint'
	disable 'roundEnd_but'
	battle.pic = battle._scene_without_hp
	draw_health_bar(battle.pic)
	draw_enemy_hp(battle.pic)
end

function phase2( battle )
	local scene = battle._scene_without_hp
	battle._secondThrow = false;
	disable 'throw_again'
	battle._tactic = 0

	-- Разберемся с дополнительным оружием
	if battle._addWpnAttacked then
		slot1._isSpent = true
		slot1._currLife = 0
		if slot1.reusable then
			sprite.copy( battle._addWpnSpr, scene, 7, crew_faces_drawing_line )
		end
	end

	-- Бойцы атакуют противника
	if battle._damage > battle._defence then
		battle._health = battle._health - battle._damage + battle._defence;
		if battle._health <= 0 then    -- Выиграли в бою
			enable 'win'
			battle_done(battle)
			return
		end
	end
	draw_enemy_hp(scene)
	
	-- Противник сбежал
	if battle._wantFlight == #battle.dices then  
		enable 'flee'
		battle_done(battle)
		return
	end
	
	-- Противник выбирает жертву
	local target
	start = slot1._isSpent and 2 or 1
	local count = 0
	repeat
		battle._target = math.floor(rnd(start,9))
		target = ref( 'slot' .. battle._target )
		count = count + 1
		if count > 2000 then
			local why_error = ""
			for i = start, 9 do
				if not target._flighted and target._currLife > 0 then
					battle._target = i
					break
				end
			end
		end
	until not target._flighted and target._currLife > 0

	-- Атака по бойцу 
	battle._attackAnimationCounter = 5; -- анимация в пять 'тиков' вызовов таймера
	timer:set(180);
	local defence = target._defenced and 1 or 0
	defence = defence + (battle._masterShield and 1 or 0)
	if battle._enemyDamage > defence then
		target._currLife = target._currLife - battle._enemyDamage + defence
	end
	if battle._raming then
		target._knockdown = true
	end

	-- Рисуем последствия атаки (и показываем, кто защищался)
	draw_health_bar(scene)
	local enemy_win = true
	local dice
	for i = 1, 9 do
		local x = 7 + (i-1)*60
		local slot = ref( 'slot' .. i )
		if slot ~= target and slot._knockdown then
			slot._knockdown = false -- нейтрализуем шок от удара с прошлого шага
			local y = crew_faces_drawing_line
			sprite.copy(spr.backing, x, y, 50, 50, scene, x, y);
		end

		enemy_win = enemy_win and (slot._flighted or slot._currLife <= 0)
		local capable = not slot._flighted and not slot._isDead and slot._currLife > 0
		if capable and not (i == 1 and slot1._isSpent) then
			if not slot._defenced then 
				dice = spr.crew_dices[spr_dice_indexes.void]
			end
			local y = crew_dices_drawing_line

			sprite.copy( dice, scene, x, y )
			if battle._masterShield then
				sprite.copy( spr.crew_dices[spr_dice_indexes.master_shield], scene, x+1, y+1 )
			end
		end
	end
	
	if enemy_win then
		battle_done(battle)
		enable 'loose_battle'
		return
	end

	-- Лог
	local desc_log = "Вы нанесли " .. txtb( battle._damage .. " ед.") .." урона"
	if battle._defence > 0 then
		desc_log = desc_log .. txtem( " (из них " .. battle._defence .. " поглощено защитой)" )
	end
	battle.dsc = desc_log .. "^"
	desc_log = "Противник нанес " .. txtb(battle._enemyDamage .. " ед.") .. " урона"
	if defence > 0 then
		desc_log = desc_log .. txtem( " (поглощено защитой: " .. defence .. ")" )
	end
	if battle._raming then
		desc_log = desc_log .. txtem " (наложено оглушение)"
	end
	battle.dsc = battle.dsc .. desc_log

	-- Подготовимся к новому циклу бросков
	enable 'ui_hint'
	disable 'roundEnd_but'

	draw_tactic_tips()
	battle.pic = scene
end
 
function battle(v)
	v.isBattle = true; -- Say game, if we need restore image (need only in battles)
	isErr( v.dices == nil, "Нужно описать противника " .. v.nam )
	for _, dice in ipairs(v.dices) do
		isErr( #dice ~= 6, "Проверьте кубики " .. 	v.nam )
	end
	isErr( v.hp == nil, "Нужно указать HP " .. v.nam)
	
	v.forcedsc = true;
	v.reset = function(s)
		-- Бойцы
		s.dsc = false;
		s._damage = 0;
		s._shock = 0;  -- количество шока, нанесенное врагу
		s._capturing = 0;
		s._masterShield = false;
		slot9._fireControl = false;
		-- Противник
		s._defence = 0;
		s._raming = false
		s._enemyDamage = 0;
		s._wantFlight = 0;
		s._target = 0;
		--
		s._addWpnAttacked = false;
		s._shockPrevent = false;    -- тратим атаку
		s._shockPreventing = false;    -- на нейтрализацию шока
		s._flightPrevent = false;
	end

	v.timer = function(s)
		if s._diceAnimationCounter ~= 0 then
			s._diceAnimationCounter = s._diceAnimationCounter - 1;

			local canvas, that_phase;
			if not s._secondThrow then
				that_phase = phase1
				canvas = sprite.dup(spr.backing)
			else
				that_phase = interphase
				canvas = sprite.dup(s._scene_without_hp)
			end

			if s._diceAnimationCounter == 0 then
				if s._attackAnimationCounter == 0 then
					timer:stop()
				end
				that_phase(s)
			else
				draw_health_bar(canvas)
				draw_enemy_hp(canvas)
				if not s._secondThrow then 
					throw_enemy_dices(canvas, true)
					throw_crew_dices(canvas, true)
				else
					if s._tactic == 5 then
						throw_crew_dices(canvas, true) -- маневрировать
					else
						throw_enemy_dices(canvas, true) -- маскировка
					end
				end
				
				s.pic = canvas
			end
		end

		if s._attackAnimationCounter ~= 0 then
			s._attackAnimationCounter = s._attackAnimationCounter - 1;
			local x = 7 + (s._target-1)*60
			local y = crew_faces_drawing_line
			if s._attackAnimationCounter == 0 then
				if s._diceAnimationCounter == 0 then
					timer:stop()
				end
				if x == 7 then -- addWpn
					sprite.copy( s._addWpnSpr, s.pic, x, y )
				else
					sprite.copy(spr.backing, x, y, 50, 50, s.pic, x, y);
				end
			elseif s._raming and s._attackAnimationCounter == 2 then
				if s._diceAnimationCounter == 0 then
					timer:stop()
				end
				s._attackAnimationCounter = 0
				if x == 7 then -- addWpn
					sprite.copy( s._addWpnSpr, s.pic, x, y )
				else
					sprite.copy(spr.backing, x, y, 50, 50, s.pic, x, y);
				end
				sprite.compose(spr.blackout, 0, 0, 50, 50, s.pic, x, y)
			else
				local alpha = 255 - 255/5 * s._attackAnimationCounter
				local face = sprite.box( 50, 50, 'red' );
				sprite.compose(spr.backing, x, y, 50, 50, face, 0, 0, alpha);
				sprite.copy(face, s.pic, x, y);
				sprite.free(face)
			end
		end

		return true;
	end
	v.restore = function(s)
		draw_tactic_tips()

		spr.backing = sprite.load 'img/backing.png'
		if pl_fighter._weaponSlot then
			sprite.copy( spr.backing, 66, 329, 52, 14, spr.backing, 6, 329 )
		end
		local enemy_face = sprite.load( 'img/enemies/' .. deref(s) .. '.png' )
		sprite.copy( enemy_face, spr.backing, enemy_face_x, enemy_face_y )
		sprite.free(enemy_face)
		s.pic = sprite.dup(spr.backing)
		setup_additional_weapon(s.pic);
		draw_health_bar(s.pic)
		draw_enemy_hp(s.pic)

		s._diceAnimationCounter = 0;
		s._attackAnimationCounter = 0;
	end
	v.enter = function(s, w)
		theme.win.geom(18, 27, 551, 540)
		theme.inv.geom(588, 50, 210, 523)
		pl_fighter.where = deref(s);
		if w.info then -- полная инициализация не требуется
			if type( pl_walker.where ) ~= "string" then
				pl_walker.where = deref(pl_walker.where())
			end
			return
		end

		moral(0)
		disable 'throw_again'
		disable 'roundEnd_but'
		disable 'win'
		disable 'persuade'
		disable 'capture'
		disable 'flee'
		enable 'ui_hint'
		s._enemyDamage = 0;
		s._defence = 0;
		s._wantFlight = 0;
		s._raming = false;
		s._masterShield = false;
		s._health = s.hp
		s:reset()

		if pl_fighter._wantFlight and pl_fighter._weaponSlot._count then
			pl_fighter._weaponSlot:apply();
		end
				
		s:restore()
		change_pl( pl_fighter );


		if isFirstBattle then
			p( txtb [[Вы вступили в первый свой бой!^ Рекомендуется ознакомится со {toInfo|справкой}]] );
			isFirstBattle = false;
		end
	end
	v.exit = function(s, w)
		theme.win.geom(30, 35, 526, 551)
		theme.inv.geom(600, 50, 185, 523)

		if w.info then -- не нужно полноценное зануление
			return
		end

		draw_moral()
		
		s.pic = nil;
		s._damage = nil;
		s._enemyDamage = nil;
		s._defence = nil;
		s._shock = nil;
		s._capturing = nil;
		s._target = nil;
		s._raming = nil;
		s._defence = nil;
		s._diceAnimationCounter = nil;
		s._attackAnimationCounter = nil;
		s._masterShield = nil;
		s._addWpnAttacked = nil;
		s._health = nil;
		s._tactic = nil;
		s._shockPrevent = nil;
		s._shockPreventing = nil;
		s._flightPrevent = nil;

		change_pl 'pl_walker'
		if deref(w) == s.won then
			pl_walker.where = w
		end
	end
	v.fin = function(s)
		change_pl( pl_walker );
	end
	v.click = function(s, bg_x, bg_y, x, y)
		if x then
			if y > crew_dices_drawing_line and y < crew_faces_drawing_line + 69 then
				describe_selected_person(x, y);
			elseif y > 8 and y < 188 then
				describe_enemy_dice(x, y);				
			else
				stats.who = "-"
				stats.desc = sprite.load 'img/dice_desc.png'
			end
			return true
		else
			game.click(game, bg_x, bg_y)
		end
	end
	v.kbd = function(s, down, key)
		if key == "space" and down then
			if disabled(ui_hint) then
				if not disabled(roundEnd_but) then return roundEnd_but:menu() end
				if not disabled(win) then return win:menu() end
				if not disabled(flee) then return flee:menu() end
				if not disabled(loose_battle) then return loose_battle:menu() end
			else
				set_sound 'snd/error.ogg'
			end
		end
	end

	local rb = room(v)
	if not v.won then
		stead.add_var(rb, { won = '', loose = '' })
	end
	return rb
end
