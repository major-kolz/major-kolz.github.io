-- $Name: Накорми котёнка$
-- $Version: 0.1$
-- $Author: Очинский Валерий$
instead_version "2.4.1"
-- traker module start
package = {} package.preload = {}
package.preload['traker'] = function()
traker = obj {
	nam = 'traker';
	dsc = [[It's a {mooving traker}.]];
	act = 'Do not trak me!';
	var { nowin = main };
	forcelife = true;
	life = function(s)
		if player_moved() then
			game.walkfromvar = s.nowin
			s.nowin = here(); -- Updating 'now in'
		end;
	end;
}

walkfrom = function()
	return (game.walkfromvar);
end

stead.module_init(function()
	lifeon('traker');
	stead.add_var(game, {walkfromvar = main});
	traker.nowin = main;
end);
end
-- traker module end
-- nolife2 module start
package.preload['nolife2'] = function()
local attr = "nolife"
local forceatrr = "forcelife"
obj = stead.inherit(obj, function(v)
	if v.life ~= nil then
		v.life = stead.hook(v.life, function(f, s, ...)
			if stead.call_bool(here(), attr) and not stead.call_bool(s, forceattr) then
				return true;
			end
			return f(s, ...)
		end)
	end;
	return v;
end)
end
-- nolife2 module end
require "para" -- красивые отступы
require "dash" -- замена символов два минуса на тире
require "quotes" -- замена простых кавычек "" на типографские «»
require "nouse" -- для удобства
require "timer" -- Проснись, котёночек, проснись!
require "hideinv"
--require 'traker'
--require 'nolife2'
package.preload['traker']()
package.preload['nolife2']()
game.act = 'Не тыкать! А то пожалуюсь автору!';
game.nouse = 'Странная идея...';
game.inv = 'Экзотика...';
game.timer=function()
	timer:del();
	lifeon('kitten');
	kitten.sleep = false;
	kitten.hungry = true;
	if where(kitten) == here() then
		kitten.knowhungry = true;
		return "Котёнок потянулся, мяукнул и подбежал к вам. Похоже, он проголодался!";
	else
		return "Вы услышали мяуканье. Похоже, это проснулся котёнок!";
	end;
	timer:stop();
end

function init()
    place (kitten, main);
    timer:set(10000)
end

mat = obj {
	nam = "подстилка";
	dsc = function(s)
		if kitten.sleep then
			p "На {подстилке}, у стены, свернувшись клубочком, сладко спит <a:02>котёнок</a>.";
		else
			p "У стены лежит любимая {подстилка} котёнка.";
		end
	end;
	act = function(s)
		if kitten.sleep then
			return kitten:act();
		else
			p "Он на ней обычно отдыхает.";
		end
	end;
};

kitten = obj {
	nam = 'котёнок';
        var {
                sleep = true;
                hungry = false;
                knowhungry = false;
        };
        dontwalk = list { 'fridgeroom' };
	dsc = function(s)
		if s.sleep then
			return false;
		else
			p "{Котёнок} трётся у ваших ног.";
		end;
	end;
	act = function(s)
		if not s.knowhungry then
--			s.sleep = false;
--			lifeon(s);
			p "Вы почесали котёнка за ушами...";
		else
			p "Кажется, он очень проголодался!";	
		end;
	end;
	life = function(s)
		if s.dontwalk:srch(here()) ~= nil then
			return
		end;
		if player_moved() and walkfrom() == where(s) then
			move(s, here(), where(s));
			return "Котёнок побежал за вами.", true
		end;
		if where(s) ~= here() then
			return
		end;
		if not s.sleep and s.hungry and not s.knowhungry and player_moved() then
			s.knowhungry = true;
			return "Котёнок подбежал к вам. Похоже, он хочет есть!";
		end
		r = rnd(5);
		if r < 2 then
			p "Котёнок разевает свой ротик и мяукает.";
		end;
	end;
	used = function(s, w)
		if w ~= saucer or not saucer.full then
			return;
		elseif s.sleep then
			return "Не надо его тревожить.";
		elseif not s.knowhungry then
			return "Он не голоден.";
		elseif not saucer.warm then
			return "Молоко холодное. Он может заболеть.";
		else
			dropf (saucer);
			saucer.full = false;
			saucer.warm = false;
			kitten.hungry = false;
			kitten.knowhungry = false;
			return walk ('theend');
		end;
	end;
};

microwave = obj {
	nam = "микроволновка";
	dsc = "На нём стоит {микроволновка}.";
	act = "Не надо её просто так включать..."
}

saucer = obj {
	nam = "блюдце";
	disp = function(s)
		if s.warm then
			return img('pictures/saucer-full-warm.png') ..' блюдце';
		elseif s.full then
			return img('pictures/saucer-full.png') ..' блюдце';
		else
			return img('pictures/saucer-empty.png') ..' блюдце'
		end
	end;
	var {
		full = false;
		warm = false;
	};
	dsc = "В углу стоит {блюдце}.";
	act = "Из него обычно пьёт котёнок.";
	tak = "Вы взяли блюдце.";
	inv = function(s)
		if s.full and s.warm then
			return "Блюдце с тёплым молоком.";
		elseif s.full and not warm then
			return "Блюдце с холодным молоком.";
		else
			return "Пустое блюдце.";
		end; 
	end;
	use = function(s, w)
		if w == microwave and s.full and not s.warm then
			s.warm = true;
			return "Вы ставите блюдце с молоком в микроволновку, закрываете дверцу и греете молоко 15 секунд. Потом достаёте блюдце.";
		elseif w == microwave and s.full and s.warm then
			return "Вы уже погрели молоко."
		elseif w == microwave and not s.full then
			return "Блюдце пустое."
		end;
	end;
	used = function(s, w)
		if w == milkpkg and not s.full then
			s.full = true;
			return "Вы наполнили блюдце молоком.";
		elseif w == milkpkg and s.full then
			return "Вы уже налили молоко в блюдце."
		end;
	end;
	nouse = "Блюдцем?"
};

fridge = obj {
	nam = "холодильник";
	dsc = "Тихо гудит {холодильник}.";
	act = code [[ walk(fridgeroom) ]];
	obj = { 'microwave' };
};

milkpkg = obj {
	nam = "пакет молока";
	disp = img('pictures/milk.png') ..' пакет молока';
	dsc = "На нижней полке стоит {пакет с молоком}.";
	tak = function(s)
		if not kitten.knowhungry then
			return "Он вам не нужен.", false
		else
			return "Вы взяли пакет.", true
		end
	end;
	inv = "Вы встряхиваете пакет. Там ещё много молока!";
	use = function(s, w)
		if w == fridge then
			dropf(s, fridgeroom);
			return "Вы убираете молоко в холдильник.";
		elseif w == microwave then
			return "Молоко лучше греть в блюдце.";
		end;
	end;
	nouse = "Полить молоком?"
};

-- Дальше -- комнаты

main = room {
	nam = "жилая комната";
	dsc = [[Вы в своей комнате.]];
	enter = function()
		set_music("music/little forest spider.it")
	end,
	obj = { 'mat', 'kitten'};
	way = { 'kitchen' };
};

kitchen = room {
	nam = "кухня";
	dsc = "Небольшая комната, где вы обычно едите.";
	obj = { 'saucer', 'fridge' };
	way = { 'main' };
};

fridgeroom = room {
	nam = "холодильник";
	dsc = "Вы смотрите на полки холодильника.";
--	nolife = true;
	enter = "Вы осторожно открываете дверцу и заглядываете внутрь.";
	exit = "Вы осторожно закрываете дверцу.";
	act = function(s, w)
		if w == "назад" then
			back();
		elseif not kitten.knowhungry then
			return "Вы не хотите есть.";
		elseif w == "сардельки" or w == "сосиски" then
			return "Вы не голодны, а котёнок ещё слишком мал для такой еды.";
		elseif w == "сыр" then
			return "Сыр едят мыши, а не котята!"
		end;
	end;
	obj = { 'milkpkg', 
	vobj("сардельки", "На верхней полке лежат {сардельки},"),
	vobj("сосиски", "{сосиски}"), 
	vobj("сыр", "и {кусок сыра}."),
	vobj("назад", "Вы можете {закрыть} дверцу холодильника.") };
};

theend = room {
   hideinv = true,
   nam = "конец";
   forcedsc = true;
   nolife = true;
   dsc = [[Вы ставите блюдце на пол. Котёнок подходит к блюдцу и начинает лакать молоко. Насытившись, он начинает вылизываться. Потом, сворачиваетсяя калачиком на своей подстилке и снова засыпает...^^
       Вот и конец этой доброй истории. Особая благодарность выражается кошкам и котятам.]];
	
}
