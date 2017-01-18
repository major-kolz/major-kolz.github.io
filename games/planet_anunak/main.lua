--$Name: Планета Анунак$
--$Version: 0.5.1$
--$Author: Константин Таро$

instead_version "2.3.0";

stead.xref = function(str, obj, ...)                                            
        if stead.type(str) ~= 'string' then 
			  return nil
		  end                  

		  if exist(obj, equipment) or exist(obj, crew) or exist(obj, ui_hint) 
			  or here() == main or have(obj)
			  or obj.key_name == "myself" or obj.key_name == "rem_item" 
			  or obj.key_name == "use_wpn" or obj.key_name == "soldier"
			  or obj.key_name == "tactic_tip" or obj.key_name == "tactic_go" then
			  return iface:xref(str, obj, ...);                                       
		  else
			  return iface:xref(txtem(str), obj, ...);                                       
		  end
end

local old_txtst = txtst
txtst = function(str)
	return old_txtst( txtnb(str) ) -- избавляемся от разрывов на пробелах
end
function always()
	return true;
end

require 'xact'
require 'timer'
require 'theme'
require 'sprites'
require 'click'
require 'format'
format.para   = true;   -- Отступы в начале абзаца;
format.dash   = true;   -- Замена двойного минуса на длинное тире;
format.quotes = true;   -- Замена " " на типографские << >>;

dofile 'script/useful.lua'			-- фрагменты кода для повторного использования
dofile 'script/warfare.lua'
dofile 'script/equipment.lua'
dofile 'script/paragraphs.lua'
dofile 'script/camp.lua'
dofile 'script/enemies.lua'
dofile 'script/info.lua'

-- Константы игрового интерфейса
crew_faces_drawing_line = 279
crew_dices_drawing_line = crew_faces_drawing_line - 64
crew_hpbar_drawing_line = crew_faces_drawing_line + 53
enemy_dices_drawing_line = 71
enemy_face_x = 160
enemy_face_y = 10
enemy_hp_bar_x = 392
enemy_hp_bar_y = 13
log_x = 24
log_y = 225
log_offset = 24
marker_offset = 13

---------------------- 
click.bg = true;
global {
	the_words = {};
	the_moral = -1;
	the_day = 0;
	the_item_counter = 2; 
	isGame = true; -- game or info
	isFirstBattle = true;
	the_enemies = {
		"dinosaur1",
		"dinosaur2",
		"dinosaur3",
		"dinosaur4",
		"dinosaur5",
		"dinosaur6",
		"dinosaur7",
		"monster1",
		"monster3",
		"mosquitoes",
		"scorpion",
	}
}

function knowWord( word, remember )
	if the_words[word] then
		return true;
	elseif remember then
		the_words[word] = true;
	end

	return false
end

function moral( dm )
	dm = dm or 10
	the_moral = the_moral + dm;
	if the_moral < 0 then
		the_moral = 0
	elseif the_moral > 101 then
		the_moral = 101
	else
		draw_moral();
	end
end

function draw_moral()
	if the_moral < 0 then -- еще в прологе
		return
	end

	local x = 588
	local y = 26
	local step = 2

	sprite.free( spr.background )
	spr.background = sprite.load 'img/bg.png'

	sprite.copy( spr.moralbar, spr.background, x, y )
	for i = 0, the_moral-1 do
		sprite.copy( spr.moralbar_values, spr.background, x + i*step, y)
		if i%10 == 0 then
			if i == 0 then
				sprite.copy( spr.moralbar_milestone, spr.background, 582+i*step, 7)
			else
				sprite.copy( spr.moralbar_milestone, spr.background, 580+i*step, 7)
			end
		end
	end
	if the_moral > 0 then
		sprite.compose( spr.moralbar_finalizer, spr.background, x + the_moral*step - 2, y - 6 )
		if the_moral%10 == 0 then
			sprite.copy( spr.moralbar_milestone, spr.background, 580+the_moral*step, 7)
		end
	end

	theme.gfx.bg( spr.background )
end

function lossItems( count )
	local length = 0
	for i, item in ipairs( equipment.obj ) do
		if item._count then
			length = length + item._count
		else
			length = length + 1;
		end
	end

	p "Вы потеряли: "
	for removing = 1, count do
		local j = 0
		local pointer = rnd(length)
		for i, item in ipairs( equipment.obj ) do
			if item._count then
				j = j + item._count
			else
				j = j + 1;
			end

			if j > pointer then
				pr( item.nam )
				if removing ~= count then
					p ','
				end
				if item._count then
					if item == packed_lunces then
						item._count = item._count - 3
					else
						item._count = item._count - 1
					end
					if item._count <= 0 then
						remove(item, equipment)
					end
				else
					remove(item, equipment)
				end
				break
			end
		end

		length = length - 1;
	end
end

function lossMan() 
	if not Lloyd.me._isDead then
		Lloyd.me._isDead = true
	elseif not Zed.me._isDead then
		Zed.me._isDead = true
	elseif not Wayne.me._isDead then
		Wayne.me._isDead = true
	else
		Ralf.me._isDead = true
	end
	moral(-20)
	lossItems(3)
end

function add_inv_pointer()
	local x = 587
	local y = 90
	sprite.compose( spr.inv_pointer, spr.background, x, y + 19*(the_item_counter-2) )

	the_item_counter = the_item_counter + 1
	theme.gfx.bg( spr.background )
end

function redraw_inv_pointers()
	if the_moral < 0 then
		sprite.free( spr.background )
		spr.background = sprite.load 'img/bg.png'
	else
		draw_moral()
	end

	the_item_counter = 2
	for i = 1, #equipment.obj - 2 do
		add_inv_pointer()
	end
end

function weapon_selection()
	theme.inv.geom(588, 50, 195, 523);
	local x = 587
	local y = 71
	for i, item in ipairs(equipment.obj) do
		if item.weapon then
			sprite.compose( spr.inv_pointer, spr.background, x, y + 19*(i-1) )
		end
	end
end
		
function draw_tactic_tips()
	local x = 775
	local y = 108
	sprite.compose( spr.tactic_tip, spr.background, x, y )
	theme.gfx.bg( spr.background )
end

function hide_tactic_tips()
	local x = 775
	local y = 108
	sprite.compose( spr.hide_tactic, spr.background, x, y )
	theme.gfx.bg( spr.background )
end

toInfo = xact( '', code[[to_info()]] )

to_info = function()
	isGame = false
	theme.menu.gfx.button('img/menu_info.png', 750, 580) 
	format.para = true;
	walk "info"
end

game.click = function(game, x, y)
	if y > 581 and y < 591 then -- menu bar
		if isGame then
			if x > 764 and x < 775 then
				to_info()		
			end
		else
			if x > 738 and x < 749 then 
				isGame = true
				theme.menu.gfx.button('img/menu.png', 737, 580)
				info:toplay()
			end
		end
		if x > 777 and x < 788 then
			set_sound 'snd/error.ogg'
		end
		return true;
	elseif y > 5 and y < 39 then -- moral bar
		if x > 582 and x < 794 then
			if isGame and the_moral > 0 then
				p( "Мораль отряда: " .. the_moral .. "%" )
			else
				p "Это индикатор морали вашего отряда. Если он доползет до нуля, то по завершению дня ваша миссия досрочно завершится"
			end
			return true;
		end
	end
end

spr = {
	crew_dices = {},
	enemy_dices = {},

	-- не массивы, просто инициализация
	backing = {},
	hp = {},
	hp_blank = {},
	blackout = {},
	background = {},
	moralbar = {},
	moralbar_values = {},
	moralbar_finalizer = {},
	inv_pointer = {},
	tactic_tip = {},
	hide_tactic = {},
}

spr_dice_indexes = {
   flight = 1, 
	dead = 2,
	eye = 3,
	shield = 4,
	harmed = 5,
   shot = 6,
   void = 7,
	shock = 8,
	master_shield = 9,
}

spr_edice_indexes = {
	jaw = 5,
	claws = 6,
	flight = 1,
	defence = 4,
	ram = 7,
	nothing = 2,
	void = 8,
	shot = 3,
}

spr_equip = {
	launcher = "launcher",
	flamethrower = "flamethrower",
	acousticGun = "acousticgun", 
	vibrationMachete = "machete",
	infrasoundShield = "infrasound";
}

function init()
	equipment._toOpen = false;
	crew._toOpen = false;
	slot1 = no_weapon;

	local names = {
		"run", 
		"killed",
		"eye",   -- 3
		"protect", 
		"harmed", 
		"shot",
		"empty",  -- 7
		"shocked",
		"double_protect",
	}
	for _, nam in ipairs(names) do
		stead.table.insert( spr.crew_dices, sprite.load( "img/dices/crew/".. nam .. ".png" ) )
	end

	local titles = {
		"run",
		"missed",
		"shot",
		"defence", -- 4
		"jaw",
		"claw",
		"shock",  -- 7
		"void"
	}
	for _, nam in ipairs(titles) do
		stead.table.insert( spr.enemy_dices, sprite.load( "img/dices/enemy/".. nam .. ".png" ) )
	end

	spr.hp = sprite.load 'img/hp.png'
	spr.hp_blank = sprite.load 'img/hp_blank.png'
	spr.blackout = sprite.box( 50, 50, "black", 128 )
	spr.background = sprite.load 'img/bg.png'
	spr.moralbar = sprite.load 'img/moralbar_empty.png'
	spr.moralbar_values = sprite.load 'img/moralbar_step.png'
	spr.moralbar_finalizer = sprite.load 'img/moralbar_end_pointer.png'
	spr.moralbar_milestone = sprite.load 'img/moralbar_milestone.png'
	spr.inv_pointer = sprite.load 'img/pointer.png'
	spr.tactic_tip = sprite.load 'img/tactic_tip.png'
	spr.hide_tactic = sprite.box(17, 91)
	sprite.copy( spr.background, 775, 108, 17, 91, spr.hide_tactic, 0, 0 )
end;

function start()
	draw_moral();
	if here().isBattle then
		here():restore()
	end

	if not isGame then
		theme.menu.gfx.button('img/menu_info.png', 751, 580)
	end
end

pl_walker = player {
	nam = "Путешествие",
	where = 'main',
	obj = {
		'authors', 'tips', 'about'
	},
}

equipment = menu {
	nam = function(s)
		local view = ''
		local h = here()
		if h == p296 or h == p168_supply or h == p168_mech or h == p168_main or h == p168_arsenal or (exist('fight!') and not disabled(exist('fight!'))) then
			view = txttab(12)
		end
		if s._toOpen then
			p( view .. "[+] <u>Экипировка</u>" )
		else
			p( view .. "[-] <u>Экипировка</u>" )
		end
	end,
	menu = function(s)
		local h = here()
		if h == p296 or h == p168_supply or h == p168_mech or h == p168_main or h == p168_arsenal then
			if s._toOpen then
				the_item_counter = 2
				for i = 2, #(equipment.obj) do 
					add_inv_pointer()
				end
			else
				sprite.free( spr.background )
				spr.background = sprite.load 'img/bg.png'
				theme.gfx.bg( spr.background )
			end
		end
		dropList(s)
		return true
	end,
};

crew = menu {
	nam = function(s)
		local view = ''
		local h = here()
		if h == p296 or h == p168_supply or h == p168_mech 
			or h == p168_main or h == p168_arsenal 
			or (exist('fight!') and not disabled(exist('fight!'))) then
			view = txttab(12)
		end
		if s._toOpen then
			p( view .. "[+] <u>Личный состав</u>" )
		else
			p( view .. "[-] <u>Личный состав</u>" )
		end
	end,
	menu = dropList,
	obj = {
		'Ralf', 'Vince', 'Wayne', 'Zed', 'Spike', 'Dave', 'Lloyd', 'Irwin'
	},
};

soldier = xact( '', code[[ ref(arg1):inv() ]] )
use_med = xact( '', function()
	local who = ref(arg1)
	who.me._currLife = who.me._hp
	repair_kit:apply()
	p( who.nam .. " поправил свое здоровье Аптечкой")
end)
local person_counter = 2;
function person(v)
	v.me = ref( 'slot' .. person_counter ); 
	person_counter = person_counter + 1;
	v.disp = function(s)
		local view;
		local h = here()
		if h == p296 or h == p168_supply or h == p168_mech 
			or h == p168_main or h == p168_arsenal then
			view = txttab(25)
		elseif exist('fight!') and not disabled(exist('fight!')) then
			view = txttab(25)
		else
			view = txttab(12)
		end
		
		if s.me._isDead then
			view = view .. '† ' .. txtst( s.nam )
		else
			local health = s.me._hp 
			if health < 0 then health = 0 end
			view = view .. "{soldier(" .. deref(s) .. ")|♦ " .. s.nam .. "}"
			view = view .. "[" .. s.me._currLife .. "/" .. health .. "]"
		end

		p(view)
	end
	v.inv = function(s)
		if s.me._isDead then
			p "Боец погиб"
		else
			pn "Слева от имени бойца, в круглых скобках, записано состояние его здоровья."
			if s.me._currLife ~= s.me._hp then
				p("Хотите " .. txtu("{use_med(" .. deref(s) .. ")|дать} ") .. s.nam .. "у аптечку?")
			end
		end
	end

	return stat(v);
end
Ralf = person{ nam = "Ральф" }
Vince = person{ nam = "Винс" }
Wayne = person{ nam = "Уэйн" }
Zed = person{ nam = "Зед" }
Spike = person{ nam = "Спайк" }
Dave = person{ nam = "Дейв" }
Lloyd = person{ nam = "Ллойд" }
Irwin = person{ nam = "Ирвин" }

main = room{
	nam = "";
	pic = "img/locations/start.png;img/image_frame.png"; 
	forcedsc = true;
	enter = function(s, from)
		set_music 'mus/menu.ogg'
		change_pl 'pl_walker'
	end,
	state = 1;
	dsc = function(s) 
		pn( txtc( txtb (txtu "Планета Анунак") ) )
		pn ''
		switch(s.state) {
			[[Перед вами интерактивная версия книги-игры "Планета Анунак". В ней вам предстоит примерить роль Ирвина - способного молодого лейтенанта космической пехоты.^ Кстати, ему только что пришел приказ срочно явиться к начальству. Учитывая отличный послужной список и чистую совесть, это может означать только одно - начинается приключение! ^^^^]],
			[[^<b>Константин Таро</b>: идея, текст, подбор иллюстраций и музыкального сопровождения.^^
			<b>Николай Коновалов</b>: перенос на платформу {instead|INSTEAD}.^^^]],
			[[Кнопка <b>меню</b> находится в нижнем правом углу и помечена символом паузы (меню откроется и если нажать 'Esc').^ 
			Рядом расположена кнопка <b>вызова справки</b> (со знаком вопроса).^^
			Перейти к следующему параграфу можно нажатием на 'пробел'.^
			Вы <b>проиграете</b>, если закончится провиант, до нуля упадет мораль или погибнет более 4х человек.^
			INSTEAD сохраняет состояние игры между сессиями автоматически. Сохранятся можно и вручную (через меню). Быстрый save/load -- F8/F9]],
		}
	end,
	left = function(s, w)
		if w == beginning then
			pl_walker.obj:zap()
		end
	end,
	kbd = function(s, down, key)	
		walk 'beginning'
	end,
	obj = {
		vway( '', "► <i>{Приступить}</i>", 'beginning' ),
		xact( 'instead', "Страница проекта: instead.syscall.ru" ),
	},
}

authors = menu{
	nam = "^^^^^" .. txtc "Авторы",
	menu = function(s)
		main.state = 2
		p ''
		return true
	end,
};

tips = menu{
	nam = txtc "Напутствие",
	menu = function(s)
		main.state = 3
		return true
	end,
}

about = menu{
	nam = txtc "Об игре";
	menu = function(s)
		main.state = 1
		return true
	end,
}


