--$Name: Каскад$
--$Version: 0.1$
--$Author: Николай Коновалов$

instead_version "2.4.1";

require 'timer'
require 'xact'
require 'hideinv'
require 'format'
format.para   = true;   -- Отступы в начале абзаца;
format.dash   = true;   -- Замена двойного минуса на длинное тире;
format.quotes = true;   -- Замена " " на типографские << >>;

game.timer = function(s)
	loc = here()
	if loc == main then
		if not disabled(door)  then
			set_sound 'music/toggle_click.ogg'
			if loc.timer_use == 1 then
				timer:set(1700)
			elseif loc.timer_use == 2 then
				timer:set(250)
			else
				timer:stop()
			end
			loc.timer_use = loc.timer_use + 1
		else
			timer:stop()
			prnd{
				"Уф. Мысли расползаются...",
				"Потерял нить рассуждения, надо собраться.",
				"Сосредоточиться становится все труднее.",
			}
			p( "^^" ..  thoughts.text[thoughts.state] )
		end
	else
		timer:stop()

	end
end

function unfold( handler, returnIt )	-- Вспомогательная функция, обеспечивающая полиморфизм данных
	local t = type(handler)					-- В зависимости от типа (строка/функция), либо выводит, либо исполняет handler
	if t == "string" then
		if returnIt then
			return handler
		else
			p( handler );
		end
	elseif t == "function" then
		handler();
	else
		error( "Check data's fields! One of them is: " .. t ); 
	end
end

function prnd( arg, needReturn )			-- Возвращает случайную реплику из таблицы arg
	return unfold( arg[ rnd(#arg) ], needReturn );
end

function _prnd( arg )
	return function()
		prnd( arg )
	end
end

function switch( condition )				-- Оператор выбора для условия condition
	return function(data)					-- data может иметь поле def: на случай недопустимых значений condition 
		local react = data[condition] or data.def or function() return true end;
		unfold( react )
		if data.event then					-- Поле event вызывается каждый раз. Можно присвоить функцию со счетчиком, к примеру
			unfold( data.event )
		end
	end
end

mplayer = obj{
	nam = "";
	var {
		track = 1
	},
	playlist = {
		'music/dark_night.ogg',
		'music/do_not_run.ogg'
	},
	life = function(s)
		if not is_music() then
			if corridor.state > 6 then
				set_music 'music/do_not_run.ogg'
				return
			end

			set_music(s.playlist[s.track], 1)
			if s.track == #s.playlist then
				s.track = 1
			else
				s.track = s.track + 1 
			end
		end
	end
}

main = room {
	nam = function(s)
		if not disabled(lamp) then
			p '...'
		else
			p "Спальня"
		end
	end,
	var {
		state = 1,
		walking = 1,
		timer_use = 1,
	},
	entered = function(s)
		set_music 'music/spirit_world.ogg'
	end,
	forcedsc = true;
	dsc = function(s)
		switch(s.state){
			game_intro,
			game_intro1,
			false,
			"nothing"
		}
	end,
	start = function(s, status)
		if status == 1 then
			s.state = 2
		elseif status == 2 then
			s.forcedsc = false
			s.state = 3
			p [[Ну конечно! Показать телу, что все в порядке -- и дальше спать.]];
			lamp:enable();
		else
			p(stand_up)
			lamp:disable();
			dark_room:enable();
		end
	end,
	obj = {
		xact('pre_begin', function() here():start(1); return true end),
		xact('begin', function() here():start(2); return true end),
		xact('walk_in_nigth', function() here():start(3); return true end),
		xact('foot', "Как-то не догадался я взять с собой тапочки. Это как с отдыхом на море: берешь плавки, шорты, крем от загара. А ветровку на случай штормовой погоды -- как-то забываешь..."),
		xact('go_for_light', function() dark_room.walk_num = 1; return true end),
		xact('go_to_table', function() door:disable(); dark_room:enable(); return true end),
		xact( 'swith_to_light_room', code[[walk 'bedroom'; take 'hand_lamp']] ),
		'lamp', 'dark_room', 'door', 'table', 'thoughts'
	},
};

lamp = obj{
	nam = '',
	dsc = function(s)
		if not s.go_up then
			p "{dark|Мрак} и {silence|тишина}"
		else
			p "{dark|Тьма} и {silence|тишина}"
		end
		if s.click < 2 then
			p [[обволакивают меня.]];
		else
			p [[наседают на меня.]];
		end
		if s.visible then
			p "^ Справа от кровати можно нащупать {настольную лампу}."
		end
	end,
	var {
		click = 0;	
		go_up = false;
	};
	dark_act = function(s)
		if s.click == 0 then
			p "Я протягиваю руку и нашариваю {lmp|выключатель} настольной лампы."
		elseif s.click == 1 then
			p "Что такое? Почему свет не зажегся?"
		else
			if not s.go_up then
				p [[Тьма словно-бы сгустилась...]];
				s.click = 3;
			else
				p [[Значит нужно включить верхний свет. Выключатель находится у двери... По ту сторону комнаты... Из кровати определенно не дотянутся -- придется {walk_in_nigth|вставать}.]]
			end
		end
	end,
	silence_act = function(s)
		if s.click == 0 then
			p "Неправильная тишина. Кроме слегка учащенного дыхания -- никаких звуков. Так не бывает...";			
		elseif s.click == 1 then
			p "..."
		elseif s.click == 2 then
			p "Если задержать дыхание, то можно услышать собственное сердцебиение."
		else
			p "Я задерживаю дыхание и замираю... Что-то не так.^ По вытянутой руке словно мазнули ледяной чешуей -- но усилием воли я подавляю картинку. Это сердце от стресса перестало гнать кровь к конечностям и сосредоточило поток на внутренних органах. Ничего более!"
		end
	end,
	act = function(s)
		if s.click == 0 then
			p "..."
		elseif s.click == 1 then
			p [[Эмм?..]];
		elseif s.click == 2 then
			p [[Что за чёрт?! Почему свет не включается?]];
		else
			if not s.go_up then
				s.go_up = true
				p "Настольная лампа определенно не работает..."
			else
				prnd {
					[[Я нажимаю на выключатель -- но ничего не происходит... В озарении нащупываю шнур: "Выскочил, небось!".
				^ На сердце сразу легчает от такого простого и понятного объяснения. Ладонь скользит вперед и в голове 
				мелькает сотня возможных способов выдернуть штепсель и не заметить этого...^ Чёрт! Он на месте. 
				Плотно вогнан в гнездо, гаденыш.]];
				[[В слепую отыскал замысловатый крендель газоразрядной лампочки. Провернул в одну сторону и другую -- вдруг 
				контакт нарушился? Нажал кнопку...^ Нет. Не контакт. Может перегорела?]];
				"Что за дела? Да включайся же!";
				}
			end
		end
				
		if s.click < 2 then
			s.click = s.click + 1;
		end
		set_sound "music/toggle_click.ogg";
	end,
	obj = {
		xact( 'dark', code[[lamp:dark_act(); return true;]] ),
		xact( 'silence', code[[lamp:silence_act(); return true;]] ),
		xact( 'lmp', code[[lamp.visible = true; lamp:act() return true]] ),
	},
}:disable();

dark_room = obj{
	nam = '';
	var {
		walk_num = 0,
		how_far = 0,
	   isLeft = true
	},
	act = function(s)
		s.how_far = s.how_far + 1;
		s.isLeft = not s.isLeft
		if s.walk_num == 1 and s.how_far == 5 then
			s.how_far = 0
			s:disable()
			if not trigger._checked then
				s.walk_num = 2
				p(arrive_to_door)
			else
				s.walk_num = 3
				cardRider.examine = 4
			end
			door:enable()
		elseif s.walk_num == 2 and s.how_far == 9 then
			s.walk_num = 1  -- возвращаемся тем же путем
			s.how_far = 0
			s:disable()
			p(arrive_to_table)
			table:enable()
		elseif s.walk_num == 3 and s.how_far == 9 then
			s:disable()
			p(seek_light)
		end

		return true
	end,
	dsc = function(s)
		if s.walk_num == 0 then
			p(night_walk1)
		elseif s.walk_num == 1 then
			first_leg = s.isLeft and txttab '40%' or txttab'55%'
			second_leg = s.isLeft and txttab '55%' or txttab'40%'
			height = 92 - 8*s.how_far
			pn(txty(tostring(height) .. '%') .. first_leg .. "{Шаг}")
			p (txty(tostring(height + 8) .. '%') .. second_leg .. "Шаг")
		elseif s.walk_num == 2 then
			if s.how_far < 6 then
				first_leg = s.isLeft and txttab '40%' or txttab'55%'
				second_leg = s.isLeft and txttab '55%' or txttab'40%'
				mov = 8
				height = 52 + mov*s.how_far
				pn(txty(tostring(height) .. '%') .. second_leg .. "Шаг")
				p (txty(tostring(height + mov) .. '%') .. first_leg .. "{Шаг}")
			elseif s.how_far == 6 then
				p (txty'100%' .. txttab'40%' .. txtnb"Шаг           " .. "{Шаг}" )
			elseif s.how_far == 7 then
				pn(txty'100%' .. txttab'40%' .. "{Шаг}")
				p (txty'104%' .. txttab'55%' .. "Шаг" )
			elseif s.how_far == 8 then
				p (txty'104%' .. txttab'40%' .. txtnb"Шаг           " .. "{Шаг}" )
			end
		else	
			if s.how_far == 0 then
				p (txty'52%' .. txttab'40%' .. txtnb"Шаг           " .. "{Шаг}" )
			elseif s.how_far == 1 then
				pn(txty'52%' .. txttab'40%' .. "{Шаг}")
				p (txty'58%' .. txttab'40%' .. "Шаг" )
			elseif s.how_far == 2 then
				pn(txty'52%' .. txttab'48%' .. "Шаг")
				p (txty'58%' .. txttab'40%' .. "{Шаг}" )
			elseif s.how_far == 3 then
				pn(txty'52%' .. txttab'48%' .. "{Шаг}")
				p (txty'62%' .. txttab'52%' .. "Шаг" )
			elseif s.how_far == 4 then
				pn(txty'56%' .. txttab'58%' .. "Шаг")
				p (txty'62%' .. txttab'52%' .. "{Шаг}" )
			elseif s.how_far == 5 then
				pn(txty'56%' .. txttab'58%' .. "{Шаг}")
				p (txty'66%' .. txttab'60%' .. "Шаг" )
			elseif s.how_far == 6 then
				pn(txty'60%' .. txttab'64%' .. "Шаг")
				p (txty'66%' .. txttab'60%' .. "{Шаг}" )
			elseif s.how_far == 7 then
				pn(txty'60%' .. txttab'64%' .. "{Шаг}")
				p (txty'70%' .. txttab'68%' .. "Шаг" )
			elseif s.how_far == 8 then
				pn(txty'62%' .. txttab'72%' .. "Шаг")
				p (txty'70%' .. txttab'68%' .. "{Шаг}" )
			end
		end
	end,
}:disable()

door = obj{
	nam = "_",
	dsc = "Мощный прямоугольник {tight|плотно} перекрывает {дверной проем}.",
	act = "Солидная дверь, такой и бухгалтерию не стыдно запереть.",
	obj = {
		xact( 'tight', "Никогда особо не обращал внимания, но вроде как по косяку идет резиновая прокладка. Но даже если и нет -- звукоизоляция тут на приличном уровне: топот поднимающейся ни свет ни заря первой смены еще ни разу мой сон не прервал. А полы тут в коридорах ой какие гулкие..." ),
		'handle', 'cardRider', 'trigger', 
	},
}:disable()

handle = obj{
	nam = "_",
	dsc = function(s)
		p "^{Ручка} двери, спасибо мышечной памяти, находится сразу."
		if not trigger._checked then
			p" Нажимная, металлическая. Внутренняя сторона приятно закруглена в бессловесной подсказке: \"Тянуть\"."
		end
	end,
	act = _prnd{
		"Нажимная ручка. Почти не сдвигается: замок закрыт.",
		"Я вяло пробую нажать -- заперто.",
	},
}

cardRider = obj{
	nam = "_",
	dsc = function(s)
		if not trigger._checked then
			p "^Под этим ориентиром определяется {считывающая панель}."
		else
			p "Под ней расположен {цифровой замок}."
		end
	end,
	var {
		examine = 1;
	},
	act = function(s)
		if not trigger._checked then
			p "Ага, никаких ключей: личные комнаты запирают персональным кодом, записанным на магнитную карту. У него и другое применение есть -- авторизация на терминалах, к примеру."
		else
			switch(s.examine){
				[[Дверь оснащена электронным замком, для открытия которого нужна идентификационная карточка. Говорят, раньше изнутри все открывалась простой кнопкой, но люди забывали карточки в комнате. А так: не взял -- не вышел.]];
				"А где я карточку оставил?..";
				"{go_to_table|На столе}, конечно!";
				def = "Не будет считаться с моими желаниями до тех пор, пока не подтвержу свое право на таковые наличием ключ-карты.";
			}
			if s.examine < 3 then
				s.examine = s.examine + 1;
			end
		end
	end,
	used = function(s, w)
		if w == key_pass then
			set_music('music/patient_boy.ogg', 1)
			door:disable()
			thoughts:enable()
			lifeon(mplayer)
			return true
		end
	end,
}

trigger = obj{
	nam = "_",
	_checked = false;
	dsc = function(s)
		p "^{Выключатель} находится слева от двери, где-то на уровне пояса."
		if not s._checked then
			p "И это доставляло кучу неудобств, пока привыкал. А потом оказалось, что свет легко включается с порога легким движением опущенной правой руки. Эргономика."
		end
	end,	
	act = function(s)
		if not s._checked then
			s._checked = true
			timer:set(2900)
			p(trigger_failed)
		else
			prnd{
				"Не работает";
				"Угораздило-же...";
				"Жаловаться нужно. Ох...";
				"Я нажал на выключатель. Ничего.";
			};
			set_sound 'music/toggle_click.ogg';
		end
	end,
};

table = obj{
	nam = '',
	_examed = false,
	dsc = function(s)
		p "Предо мной, по ощущениям, находится {стол}: минималистская конторка из одной тумбы и растущей вбок столешницы с двумя стойками-опорами."
		if s._examed then
			p "С краю стоит {t_lamp|настольная лампа}."
		end
	end,
	act = function(s)
		if not s._examed then
			key_pass:enable()
			s._examed = true
			return true
		else
			p "Я, кажется, уже нащупал ключ-карту."
		end
	end,
	obj = {
		xact( 'tablet', "" ),
		xact( 'notebook', "" ),
		xact( 't_lamp', "Как я успел удостоверится -- не работает. Точнее, что-то случилось с электричеством вообще: вряд ли верхний свет и конкретно это розетка связаны как-то по-особенному." ),
		'key_pass'
	},
}:disable()

key_pass = obj{
	nam = "Ключ-карта",
	dsc = [[^ Пошарив рукой по столу, я нащупал {пластиковый прямоугольник}.]],
	tak = function(s) disable(table); enable(dark_room); remove(s, table); return true end,
	inv = function(s)
		if not disabled(thoughts) then
			return false
		end

		p "Небольшой прямоугольник с неприятно-острыми краями."
	end,
	use = function(s, w)
		if w == L_table then
			p [[Вряд ли он мне пригодится, учитывая обстоятельства...]];
			remove(s)
		elseif w == emergency_kit then
			p [[Освобожу-ка руки...]]
			remove(s)
		end	
	end,
	used = function(s, w)
		if w == scissors then
			p [[Даже если ножнички и возьмут пластик -- зачем?]];
		end 
	end,
}:disable()

thoughts = obj{
	nam = "",
	state = 0;
	dsc = function(s) 
		if s.state == 0 then 
			p(thing_seems_so_wrong) 
		end 
	end,
	act = function(s)
		s.state = s.state + 1;
		p( s.text[s.state] )
	end,
	text = {
		"Дверь не сдвинулась с места. Ручку не удалось нажать. Цифровой замок никак не среагировал на ключ-карту. События кажутся такими невероятными, что я прикладываю карту повторно -- ничего. Протягиваю вторую руку -- но нет, я не промахнулся и замок точно под картой.^ Он просто {fact|не реагирует} на неё.",
		"Я не могу выйти... {stupor|Что?..} Замок не работает? Но это {denial|невозможно!}",
		"Замки не могут отказать, ни под каким видом. Все первостепенные системы станции имеют независимую, с резервными слоями, энергоструктуру. {awareness|Вентиляция}, связь с поверхностью, {blindness|замки}, противопожарные системы...",
		"Вентиляция! Черт подери, {panic|вентиляция не работает}! Это гнетущее ощущение безмолвия с которым я проснулся -- оно из-за померкшего гула лопастей. Еле слышимое дребезжание так долго терзало мой слух, что мозг свыкся и стал затирать его.",
		"Отказало электропитание основных линий -- потому комната обесточена. {anxiety|Заглохла вентиляция} и {sanity|потухли цифровые замки}: значит потеряны {skid|системы первого уровня}.",
	},
	obj = {
		xact( 'fact', code[[thoughts:act()]] ),
		xact( 'stupor', "Не открывается? Я не той стороной карточку... Или подождать... Что вообще нужно {wrong|сделать?..}" ),
		xact( 'wrong', function() timer:set( 6000 + (rnd(5)-3)*250 ); p "..." end ),
		xact( 'denial', code[[thoughts:act()]] ),
		xact( 'awareness', code[[thoughts:act()]] ),
		xact( 'blindness', "Даже если бы какой-то контур и отказал бы -- автоматика просто задействовала бы запасной. Такого просто {wrong|не может быть}." ),
		xact( 'panic', code[[thoughts:act()]]),
		xact( 'anxiety', "Задохнутся мне не грозит: какой-никакой, а естественная циркуляция присутствует, да и помещение свои литры вмещает. Но отказала она -- значит и другие системы не работают. Отопление. Не скажу чувствуется ли уже (ведь с кровати встал в чем спал), но мурашки по кожи бегают.^ Самое плохое -- это что и связи нет. Как бы {wrong|проще} было просто позвать ни помощь..." ),
		xact( 'sanity', "Я заперт внутри и без малейшего понятия, что теперь делать.^ Стою босиком на холодном полу, с недоуменно вытянутой рукой, в полной темноте. Определенно важный аспект проблем -- ибо я почти физически чувствую, как напряжение сковывает мысли и рассаживает их по карцерам паники.^^ Стоит одеться, сесть за стол и крепко подумать. И хорошо бы еще и {solution|свет} организовать." ),
		xact( 'solution', "Вот и пришло время пожалеть о покупке гаджета с экранном на электронных чернилах...^^Еще варианты: ... ^^ Огонь? Плохая идея даже при работающей вентиляции. Да, определенно плохая.^ Пытаться выбить дверь также не стоит -- только поранюсь. В аварийном комплекте должна быть аптечка, но толку с неё при вывернутом...^^Ох, я дурак! Аварийный комплект же! Их по нормам комплектуют: респиратор, аптечка, плитка какой-то дряни -- и {come_on|фонарь!}" ),
		xact( 'come_on', code[[enable(dark_room); disable(thoughts); return true]] ),
		xact( 'skid', "Невероятный масштаб повреждений -- что вообще произошло? Взрыв силовых установок, землетрясение?.. При должном размахе это могло бы вырубить станцию -- но тогда меня бы также размазало по стенам.^ Какой-то глюк с сенсорами, что {wrong|система} ужаснулась с данных и решила вырубить все под корень? Ага, совсем без предупреждения, в расчете все по-тихому исправить пока мы спим..." ),
	},
}:disable()

--====================| Спальня в свете |====================--
bedroom = room{
	nam = "Спальня",
	entered = function(s)
		p[[Свет вспыхнул, выставив комнату в том самом необычном свете, что, собственно, и породил данный фразеологизм.]]
		L_table.obj:disable_all()
		bed.obj:disable_all()
		L_door.obj:disable_all()
	end,
	obj = {
		xact( 'go_corridor', code[[walk(corridor)]] ),
		"orientation", "cyber_lock_wires"
	},
}

orientation = obj{
	nam = "",
	var {
		pos = 1;
	},
	dsc = function(s)
		local base = "Справа от меня находится %s, позади -- %s. %s слева.^^"
		if s.pos == 1 then
			base = base:format("{L_table|стол}", "{bed|кровать}", "{L_door|Дверь}")
		elseif s.pos == 2 then
			base = base:format("{bed|кровать}", "{L_door|дверь}", "{wardrobe|Шкаф}")
		elseif s.pos == 3 then
			base = base:format("{L_door|дверь}", "{wardrobe|шкаф}", "{L_table|Стол}" )
		elseif s.pos == 4 then
			base = base:format("{wardrobe|шкаф}", "{L_table|стол}", "{L_door|Кровать}")
		end
		p(base)
	end,
	obj = {
		'wardrobe', 'L_table', 'bed', 'L_door'
	},
}

function change_loc(to)
	for i, o in ipairs{wardrobe, L_table, bed, L_door, } do
		if o.open then
			o.open = false
			o:disable_all()
		end
		if o == to then
			orientation.pos = i
		end
	end
	to.open = true
	to.obj:enable_all()
end

L_table = obj{
	nam = "",
	var {
		open = false;
	},
	dsc = function(s)
		if s.open then
			p "Итак, {стол}."
		end
	end,
	act = function(s)
		if not s.open then
			p "Подхожу к столу."
			change_loc(s)
		else
			p "Скупо отмеренное рабочее пространство. Если поставить планшет стоймя и подключить клавиатуру -- места для локтей лишь и останется."
		end
	end,
	obj = {
		'chair', 'cases'; 'table_lamp', 
	},
};

bed = obj{
	nam = "",
	var {
		open = false,
		state = 1
	},
	dsc = function(s)
		if s.open then
			switch(s.state){
				[[Не застеленная {кровать} выглядит до неуместного обыденно в сложившихся условиях...]],
				[[Я стою перед застеленной {кроватью}.]],
				"Моя {койка}."
			}
				
		end
	end,
	act = function(s)
		if not s.open then
			p "Шагаю к кровати."
			change_loc(s)
		else
			if s.state == 1 then
				p [[У Докинза в "Эгоистичном гене" был описан познавательный орнитологический курьез. Как и любая дикая птица, чайки улетают когда исследователь приближается к ним слишком близко. И, как любой хороший родитель, они весьма обеспокоены о безопасности своего потомства. Но стоит двум этим противоположным стимулам столкнутся -- например, когда человек приближается в высиживающей яйца птице -- как маленький мозг существа клинит и она начинает как ни в чем ни бывало чистить перья: работать над менее важной, но не вступившей в конфликт проблемой.]];
				s.state = 2
			elseif s.state == 2 then
				p[[Заглядываю под кровать и высвечиваю фонарем из темноты свою обувь. Отлично, а то ступни уже мерзнуть начали.]]
				s.state = 3
			else
				p [[К делу!]];
			end
		end
	end,
}

L_door = obj{
	nam = "",
	var {
		open = false,
		state = 1;
	},
	dsc = function(s)
		if s.open then
			p "Злополучная {дверь}."
		end
	end,
	act = function(s)
		if not s.open then
			p "Иду к двери."
			change_loc(s)
		else
			if not seen(cyber_lock) then
				p "Чуда не произошло, все так же закрыта."
				put(cyber_lock, s)
			else
				switch(s.state){
					"И как мне выбраться?..",
					"Дверь открывается вовнутрь -- так что выбить не получится.",
					"Как-нибудь выломать замок, может быть?"
				}
			end
		end
	end,
}

wardrobe = obj{
	nam = "",
	var {
		open = true;
		fix = false;
	},
	dsc = function(s)
		if s.open then
			shoulders = s.fix and "плечиков" or "{shoulder_strap|тремпелей}"
			p "Я стою перед {шкафом}. Внизу его находятся две открытые {shoe_place|полочки} для обуви. {look_inside|Дверцы} скрывают основное рабочее пространство с поперечиной для "
			p (shoulders)
			p "с одеждой. Сверху еще два отделение, {first_cases|одно} над {second_cases|другим}. Шкаф практически упирается в потолок." 
		end
	end,
	act = function(s)
		if not s.open then
			p "Иду к шкафу.";
			change_loc(s)
		else
			p "Высокий, почти в потолок. Жесткой прямоугольной формы, покрыт матовой краской."
		end
	end,
	obj = {
		xact('shoulder_strap', code[[p "Хорошее слово -- жаль диалектизм."; wardrobe.fix = true]]),
		xact( 'shoe_place', "Туфли, в которых я приехал, кеды и вьетнамки для душа. Пара мягких туфлей, в которых я обычно хожу, должна быть у кровати." ),
		xact( 'first_cases', function() 
			p "Всякие ящички, в том числе мой"
			if not have(scissors) then
				p "{scissors|несессер}"
			else
				p "несессер"
			end
			if not have(screw_driver) then
				p "и коробка с {screw_driver|электробритвой}." 
			else
				p "и распотрошенная коробка с электробритвой."
			end
		end),
		'scissors', 'screw_driver', 'second_cases';
		xact( 'look_inside', function() 
			if not have(emergency_kit) then
				p "Прихватить аварийный пакет в чрезвычайной ситуации -- здравая мысль."
				take 'emergency_kit'
			else
				p "Раздумываю мгновенье, не пригодится ли мне тут еще что. Закрываю двери."
			end
		end ),
	},
};

scissors = obj{
	nam = [[Ножницы]],
	act = function(s)
		print('here')
		if not have(s) then
			p [[Зубная паста, лосьон после бритья, презервативы -- это вряд ли пригодится. А вот небольшие ножницы, может, на что-то и сгодятся.]];
			remove(s, wardrobe)
			take(s)
		else
			p [[Больше ничего интересного]];
		end
	end,
	inv = [[Описание]];
	use = function(s, w)
		if w == table_lamp and cyber_lock.state > 2 then
			p "Вскрыть толстую проводку такими куцыми ножницами оказалось очень сложно, но я преодолел этот рубеж дважды и получил в свое распоряжение кусок провода. "
			take 'wire'
		elseif w == cyber_lock then
			if cyber_lock.state < 3 then
				p [[Попробовал открыть ножницами, растопырив кончики -- но те только прогибаются при усилии. Ну его, еще сломаю.]];
			end
		end
	end,
}

emergency_kit = obj{
	nam = "Аварийный набор",
	inv = function(s)
		p "Аптечка, респиратор, плитка какой-то дряни -- память меня не подвела."
	end,
};

second_cases = obj{
	nam = "",
	act = function(s)
		if chair.near_wardrobe then
			p "А толку -- оно пустое же. У меня с собой не столько вещей, чтобы нельзя было утрамбовать в более доступные места -- вот я и не стал заморачиваться со стулом."
		else
			p "Слишком высоко, не достать."
		end
	end,
}

screw_driver = obj{
	nam = "Отвертка",
	act = function(s)
		if cyber_lock.state == 1 then
			p "Еще одна вещь, которую я забыл с собой взять. Пришло спешно покупать после прилета -- хитрый продавец всучил мне еще какую-то навороченную, в две цены от моей забытой."
		else
			p "Вытягивая коробку, откидываю крышку. В своем гнезде вальяжно лежит электробритва, слот рядом занимает её док-станция, чуть пониже -- сменные насадки. Вытягиваю всю поверхность, приподняв одну сторону за тряпичный язык. Под ней находятся две маленькие книжечки, пузырек с маслом, ершик для чистки -- и небольшая отвертка! Черт, идеально."
			take(s)
			remove(s, wardrobe)
		end
	end,
	inv = [[Небольшая крестовая отвертка из коробки с электробритвой.]],
	use = function(s, w)
		if w == cyber_lock then
			if w.state == 2 then
				p "Винты поддавались с трудом, они явно рассчитаны на более крупную отвертку -- но мне удалось с ними справится. Пластину, правда, снять не удалось: из-за ручки. Очевидно, что нужно демонтировать сначала её, а уже потом лезть к замку -- но я не стал заморачиваться."
				cyber_lock.state = 3
			else
				p [[Отверткой тут больше ничего не сделаешь.]];
			end
		elseif w == hand_lamp then
			if cyber_lock.state > 2 then
				if cyber_lock.state == 5 then
					hand_lamp:use(wire)
				else
					p [[Я скрутил с фонаря крышку и взглянул на его источник питания. Плоский, с одной грани две контактные площадки.]];
				end
			else
				p [[Фонарь отлично работает -- так зачем же лезть тогда в свой единственный источник света.]];
			end
		end 
	end,
};

chair = obj{
	nam = "Стул",
	dsc = function(s)
		if L_table.open then
			p [[В пространство под столешницей культурно задвинут {стул}.]]
		elseif wardrobe.open then
			p [[К шкафу приставлен {стул}.]];
		else
			p [[У двери стоит {стул}.]];
		end
	end;
	var {
		near_wardrobe = false,
	},
	tak = function(s)
		if seen(clothe) then
			p "О, на нем моя одежда."
			return false
		else
			p "Разочаровывающе-лёгкий, полые трубки да две \"подушки\" для сиденья и спинки."
			s.near_wardrobe = false
		end
	end,
	inv = [[В руках я держу стул.]],
	use = function(s, w)
		if w == wardrobe or w == L_table then
			if w == wardrobe then
				s.near_wardrobe = true
			end
			drop(s, w)
			return true
		elseif w == L_door then
			p "Слишком легки для подобного, с первого же удара погнется. Оставлю его тут, чтобы  в руках не мешался."
			drop(s, w)
		elseif w == bed then
			p "И то фурнитура -- и то."
		end 
	end,
	obj = { "clothe" };
};

clothe = obj{
	nam = "",
	dsc = [[На стуле сложена моя {одежда}.]],
	act = function(s)
		p "Конечно. Не помешает уж точно."
		remove(s)
	end,
};

table_lamp = obj{
	nam = "",
	dsc = [[С ближнего к кровати краю стоит {лампа}. Столешница пуста, не считая канцелярской мелочи и пустой обертки от конфеты.]],
	act = [[Первый глашатай лихих времен. Гибкая шея, длинный хвост с раз-вилкой на конце -- определенно удачная метафора.]],
};

cases = obj{
	nam = "",
	dsc = [[Покоится на двух ножках\стойках и конторке с {ящичками}.]],
	act = [[Почти пустые: я приехал с минимумом вещей. Нижний вообще использую для хранения чистых носков.]],
};

hand_lamp = obj{
	nam = "Фонарь",
	var {
		equip = true;
	},
	inv = function(s)
		if s.equip then
			p "Светит."
		else
			s.equip = true
			p [[Вставляю аккумулятор обратно в фонарь, щелкаю выключателем -- и тьма отступает.]];
		end
	end,
	use = function(s, w)
	 	if w == wire then
			if not have(wire) then
				if have(chair) then
					drop(chair)
				end
				p(open_lock)
				orientation:disable()
				hand_lamp.equip = false
			else
				p [[Нужно сперва подключить второй конец провода к проводкам блокирующего механизма.]];
			end
		elseif w == cyber_lock then
			p [[Даже  так понятно, что аккумулятор фонаря туда не подсунешь, габаритный слишком. А иначе длины проводков не хватит, чтобы дотянутся до его контактных площадок.]];
	 	end
	end,
	used = function(s, w)
		if w == wire then
			p [[Нужно сперва подключить второй конец провода к проводкам блокирующего механизма.]];
		end 
	end,
};

wire = obj{
	nam = "Провод",
	inv = [[Удлинитель кустарного производства.]];
	dsc = [[С замка свисает {провод}.]],
	act = [[Самодельный удлинитель, осталось приложить к концам напряжение и замок (в теории) откроется. Главное: не сильно тревожить, -- а то отвалится.]],
	use = function(s, w)
		if w == cyber_lock then
			p [[Я совместил крохотные проводки, идущие к замку, с проводами моего шнура и как мог обжал их (длины на "скрутить" не хватало).]];
			drop(s, w)
			w.state = 5
		end 
	end,
};

cyber_lock = obj{
	nam = "",
	dsc = function(s)
		switch(s.state) {
			[[{Замок}.]],
			[[Электронное нутро {замок} надежно сокрыт от глаз за металлической пластиной.]],
			[[Чтобы открученная панель не заслоняла внутренности {замка}, я повернул её вверх на дверной ручке и, словив равновесие, прислонил к двери.]],
			[[Вскрытый замок и два отрезанных мною {проводка} от блокирующего механизма.]];
			[[Вскрытый замок и два отрезанных мною {проводка} от блокирующего механизма.]];
		}
	end,
	var {
		state = 1;
	},
	act = function(s)
		if s.state == 1 then
			p [[Замок почти целиком укрыт за металлической пластиной с нарисованным на ней квадратиком сенсорной области -- к нему и нужно прикладывать карточку. Пластина прикручена шестью утопленными винтиками под крестовую отвертку.]];
			s.state = 2
		elseif s.state == 2 then
			pn"Бросаю еще один пристальный взгляд на замок.^"
			p [[Замок почти целиком укрыт за металлической пластиной с нарисованным на ней квадратиком сенсорной области -- к нему и нужно прикладывать карточку. Пластина прикручена шестью утопленными винтиками под крестовую отвертку.]];
		elseif s.state == 3 then
			p [[Я заглядываю во внутренности замка и, закономерно, почти ничего не понимаю. Почти все пространство занимает печатная плата -- мозг замка. Вверху, у самого основания ручки находится какое-то утолщение, к которому от основной платы идут {cyber_lock_wires|два проводка}.]]
		elseif s.state == 4 then
			p [[Очень короткие, в половину фаланги пальца.]]
		else
			p [[Соединены с импровизированным удлинителем. Соединены хлипко, нужно быть поаккуратнее.]];
		end
	end,
};

cyber_lock_wires = obj{
	nam = "",
	act = function(s)
		p "Хм..."
	end,
	used = function(s, w)
		if w == scissors and cyber_lock.state == 3 then
			cyber_lock.state = 4
			p "Логично предположить, что эти два проводка -- питание блокирующего ручку механизма. Думаю, цифровой замок реагирует на появление в его \"поле видимости\" ключ-карты, считывает записанный на ней код, сверяет его по базе данных -- и принимает решение открывать ли дверь. Что, разумеется, при отсутствии света не провернуть. У лампы должна быть небольшая батарея, что её питает -- она может послужить источником питания. Не для всего замка, разумеется (толку с этого, коли на он он будет слать запросы к потухшему серверу) -- но конкретно к этому механизму.^^ С этой мыслью я аккуратно отрезаю проводки у самой платы."
		end 
	end,
};

--====================| Коридор |====================-- 
corridor = room{
	nam = "Коридор",
	forcedsc = true;
	var {
		state = 1;
		count = 1;
	},
	step = function(s)
		s.count = s.count + 1;
		if s.state == 2 and s.count == 3 then
			s.state = 3
			s.count = 1
			p "Я смотрю в конец коридора и не верю своим глазам..."
		elseif s.state == 3 and s.count == 4 then
			s.state = 4 
			s.count = 1
			p[["Эй, есть там кто-нибудь?!" -- приглушенный выкрик раздается слева, из комнаты Анастасии.]]
		elseif s.state == 4 then
			switch(s.count-1) {
				[["Настя, это Михаил. Ты уже пробовала включить свет?" -- отзываюсь я.]],
				[["Пробовала -- нет его. Но не суть. Миша, у меня с замком проблема, я выйти не могу! Можешь послать запрос на диагностику? И пусть меня откроют!"]],
			}
		elseif s.state == 5 and s.count == 4 then
			p [["Какого лешего..." -- слышу растерянное из-за спины.]];
			s.state = 6 
			s.count = 1
		end
	end,
	draw_row = function(s, where_I_stand, where_I_go, selection)
		where_I_stand = where_I_stand or -1
		where_I_go = where_I_go or -1
		selection = selection or "[+]"
		for i = 1, 5 do
			offset = txttab(tostring(22 + 11*(i-1)) .. '%')
			if i == where_I_stand then
				p(offset .. selection)
			elseif i == where_I_go then
				p(offset .. "{step|x}")
			else
				p(offset .. "+")
			end
		end
	end,
	dsc = function(s)
		if not hand_lamp.equip then
			return
		end

		names = {
			{"К. Анастасии", "Комната Милы"},
			{"К. Елизаветы", "Комната Кирилла"},
		}
		if s.state ~= 7 then
			pn'^^'
		end
		-- К Валерию
		if s.state == 1 then
			if s.count == 1 then
				p("{my_room|Моя комната}" .. txtnb' |')
			else
				p "Моя комната |"
			end

			s:draw_row(s.count, s.count+1)

			if s.count == 5 then
				p "| {Valeryj|Комната Валерия}"
			else
				p "| Комната Валерия"
			end

			
			for _, row in ipairs(names) do
				p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
				p(row[1] .. ' |')
				s:draw_row()
				p('| ' .. row[2])
			end
		-- К Анастасии
		elseif s.state == 2 then
			p "Моя комната |"
			s:draw_row(5-s.count+1, 5-s.count)
			if s.count == 1 then
				p "| {Valeryj|Комната Валерия}"
			else
				p "| Комната Валерия"
			end
			for _, row in ipairs(names) do
				p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
				p(row[1] .. ' |')
				s:draw_row()
				p('| ' .. row[2])
			end
		-- Все еще к Анастасии
		elseif s.state == 3 then
			p "Моя комната |"
			if s.count == 1 then
				s:draw_row(3, -1)
			else
				s:draw_row()
			end
			p "| Комната Валерия"

			if s.count == 1 then
				p("^^^" .. txttab'44%' .. "{step|x}^^^" .. txttab'44%' .. "+^^^")
			elseif s.count == 2 then
				p("^^^" .. txttab'43%' .. "[+]^^^" .. txttab'44%' .. "{step|x}^^^")
			elseif s.count == 3 then
				p("^^^" .. txttab'44%' .. "+^^^" .. txttab'43%' .. "[+]^^^")
			end

			for i, row in ipairs(names) do
				p(row[1] .. ' |')
				if s.count == 3 and i == 1 then
					s:draw_row(-1, 3)
				else
					s:draw_row()
				end
				p('| ' .. row[2])
				if i == 1 then
					p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
				end
			end
			p("^" .. txttab'42%' .. "{gate|——}")
		-- К двери Анастасии
		elseif s.state == 4 then
			names = {
				{"Моя комната", "Комната Валерия"},
				{"К. Анастасии", "Комната Милы"},
				{"К. Елизаветы", "Комната Кирилла"},
			}
			for i, row in ipairs(names) do
				if i == 2 and s.count == 3 then
					p("{Anastasia|К. Анастасии}".. ' |')
				else
					p(row[1] .. ' |')
				end
				if i == 2 then
					s:draw_row(4-s.count, 3-s.count)
				else
					s:draw_row()
				end
				p('| ' .. row[2])
				if i ~= 3 then
					p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
				end
			end
			p("^" .. txttab'42%' .. "{gate|——}")
		-- На шум
		elseif s.state == 5 then
			names = {
				{"Моя комната", "Комната Валерия"},
				{"К. Анастасии", "Комната Милы"},
				{"К. Елизаветы", "Комната Кирилла"},
			}
			for i, row in ipairs(names) do
				if i == 2 and s.count == 1 then
					p("{Anastasia|К. Анастасии}".. ' |')
				else
					p(row[1] .. ' |')
				end
				if i == 2 then
					if s.count < 3 then
						s:draw_row(s.count, s.count+1)
					elseif s.count == 3 then
						s:draw_row(3, -1)
					end
				else
					s:draw_row()
				end
				p('| ' .. row[2])
				if i ~= 3 then
					if i == 2 and s.count == 3 then
						p("^^^" .. txttab'44%' .. "{step|x}^^^" .. txttab'44%' .. "+^^^")
					else
						p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
					end
				end
			end
			p("^" .. txttab'42%' .. "{gate|——}")
		-- На шум вниз
		elseif s.state == 6 then
			names = {
				{"Моя комната", "Комната Валерия"},
				{"К. Анастасии", "Комната Милы"},
				{"К. Елизаветы", "Комната Кирилла"},
			}
			for i, row in ipairs(names) do
				p(row[1] .. ' |')
				if i == 3 then
					if s.count == 2 then
						s:draw_row(-1, 3)
					elseif s.count == 3 then
						s:draw_row(3, -1)
					else
						s:draw_row()
					end
				elseif i == 1 then
					s:draw_row(6-s.count, -1, "{friend|B}")
				else
					s:draw_row()
				end
				p('| ' .. row[2])
				if i ~= 3 then
					if i == 2 then 
						if s.count == 1 then
							p("^^^" .. txttab'43%' .. "[+]^^^" .. txttab'44%' .. "{step|x}^^^")
						elseif s.count == 2 then
							p("^^^" .. txttab'44%' .. "+^^^" .. txttab'43%' .. "[+]^^^")
						else
							p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
						end
					else
						p("^^^" .. txttab'44%' .. "+^^^" .. txttab'44%' .. "+^^^")
					end
				end
			end
			p("^" .. txttab'42%' .. "{gate|——}")
		elseif s.state == 7 then
			p [[Прислушиваюсь -- ничего. Шаги Валерия гулко отдаются по коридору и я затыкаю ухо. Все равно ничего.^ Но мне не могло послышаться! Да и не один я слышал тот удар. Не придумав ничего лучшего, я стучу костяшками по гермовратам.^^ Топот!^ "Эгей, мы здесь!" -- орет над ухом Валерий, я просто несколько раз бью кулаком.^^ КРАНК! Нечто врезается с той стороны гермоврат, ровно напротив моей головы! "Эй, секунду, дайте..." -- мой окрик прерывается жутким визгом. В голове еще слышен звон от того удара, но я точно понимаю, что человеческой глотке такой звук не издать.^ БАМ! Удар, еще удар -- и в гермовратах образовывается выпуклость, ровно на стыке двух половинок. Еще один визг, КРАНК!^^ Выпуклость раскрывается под очередным ударом, давая взглянуть на своего мучителя. Клешня! Стальная клешня манипулятора: изогнутый метал гермоврат упирается в её "запястья" и я могу расслышать гул сервоприводов. Клешня уходит обратно и на мгновенье воцаряется тишина.^^ "Эй..." -- крайне неуверенно начинает Валерий, но его тут же прерывает страшный вой существа по ту сторону. Нет, не существа -- дроида, машины. Не переставая верещать, оно упирает обе клешни в образованную дыру. Опять вой сервоприводов -- оно сейчас распахнет гермоврата!^^ {run|Бежать}]]
		elseif s.state == 8 then
			for i = 1, 7 do
				if 8-s.count == i and i ~=	1 then 
					p(txttab'43%' .. "[+] {friend|B}");
				elseif 7-s.count == i and i ~= 1 then
					p(txttab'44%' .. "{step|x}");
				elseif i == 1 and s.count == 6 then
					p(txttab'40%' .. "{step|x}");
				elseif s.count == 7 and i == 1 then 
					p(txttab'25%' .. "{to_epilogue|Дверь}" .. txttab'40%' .. "[+] {friend|B}");
				elseif i > 8-s.count then
					if i == 5 and s.count > 6 then
						p(txttab'44%' .. "{droid|Д}");
					else
						p(txttab'44%' .. "+");
					end
				end
				if i ~= 7 then
					p '^^^'
				end
			end
			if s.count > 3 then
				if s.count > 6 then
					p("^" .. txttab'43%' .. txtnb"-  -")
				elseif s.count > 4 then
					p("^" .. txttab'43%' .. "-{droid|Д}-")
				else
					p("^" .. txttab'42%' .. "{droid|— -}")
				end
			else
				p("^" .. txttab'42%' .. "{droid|—--}")
			end
		end
	end,
	entered = function(s, w)
		if w == bedroom then
			format.para = false
			p [[Поднимаю руку, обхватываю дверную ручку. Нажать отчего-то страшно...^ Но переступаю через себя и давлю. И выжимаю! Ничто более её не блокирует, у меня получилось открыть дверь!^^ Тяну дверь на себя и та ударяет меня по коленям. Бросаю провод, подхватываю лампу, сдвигаюсь в сторону -- распахиваю дверь и почти прыжком встаю\выхожу в коридор. Тут тоже темнота полнейшая, но я словно бы чувствую распахнутое пространство, ликующе приветствующее сумевшего к нему пробиться.^^Смакую несколько мгновений это ощущение, после чего возвращаюсь к предстоящим проблемам. Станция полностью обесточена: света нет, вентиляция отключена, нет связи. Возможно, системы можно перезапустить или хотя бы добиться работы передатчика?^ И я определено не должен решать эти проблемы в одиночку. Начну с Валерия: кибернетические системы -- это по его профилю.]]
		end
	end,
	obj = {
		xact( 'my_room', "Не вижу смысла сейчас возвращаться." ),
		xact( 'Valeryj', function()
			if not visited 'valerij_dlg' then 
				walk 'valerij_dlg'
			else
				p [[Проверить командный центр -- хорошая идея.]];
			end
		end ),
		xact( 'Anastasia', function()
			if not visited 'anastasia_dlg' then 
				walk 'anastasia_dlg'
			else
				p [[Зачем я сказал "Никуда не уходи"? Куда она уйдет-то из запертой комнаты.]];
			end
		end ),
		xact( 'step', code[[corridor:step(); return true]] ),
		'gate', 'droid', 'friend',
		xact( 'run', code[[corridor.state = 8; corridor.count = 1; format.para = false; return true]] ),
		xact( 'to_epilogue', code[[walk 'epilogue']] ),
	}, 
};

friend = obj{
	nam = '';
	dsc = false;
	act = function(s)
		if corridor.state == 6 then
			switch(corridor.count) {
				"Ага, Валерий уже выбрался из комнаты. Резво. А вот вид гермоврат, похоже, выбил его из колеи.",
				[["С этой стороны не открываются..." -- тоскливо констатирует он.^ "Я слышал какой-то звук..."^ "Ремонтная бригада?" -- оживляется Валерий.]],
				[["Ну что там?"]]
			}
		else
			switch(corridor.count){
				"Я хватаю его за плече и толкаю: \"Беги!\"",
				"Короткое ругательство вырывается из его уст и он рывком устремляется за мной.",
				def="Мы бежим вровень.";
			}
		end
	end,
}

gate = obj{
	nam = "",
	var {
		state = 1
	},
	act = function(s)
		if corridor.state == 3 then
			switch(s.state){
				"Ох ей, это плохо. Коридор перекрыт. Нет-нет, не так: КОРИДОР ПЕРЕКРЫТ ГЕРМОВРАТАМИ! Ладно, в прошлый раз тоже доходчиво было.",
				"Даже на учениях такого не видел. В каких случаях они там используются -- пожар на станции, химическая тревога?..",
				def = "И как мне попасть в командный пункт?.."
			}
			s.state = s.state + 1;
		elseif corridor.state == 4 then
			p "Проблема покруче будет, чем обесточенный замок..."
		elseif corridor.state == 5 then
			p "Ничего более с той стороны не доносится."
		elseif corridor.state == 6 then
			if corridor.count < 3 then
				p "..."
			else
				p "{earing|Прикладываю ухо}"
			end
		end
	end,
	obj = {
		xact( 'earing', code[[ corridor.state=7; format.para = true; set_music('music/patient_boy.ogg', 1); return true]] );
	},
};

droid = obj{
	nam = "",
	act = function(s)
		if corridor.count == 1 then
			p "Судя по завываниям сервоприводов -- гермоврата сопротивляются."
		elseif corridor.count < 4 then
			p "Звук рвущегося железа."
		elseif corridor.count == 4 then
			p "Бросаю взгляд через плече -- черт, дроид протискивается в выбоину!"
		else
			p "Никаких \"оглядывать\" -- бежать и только бежать!"
		end
	end,
};

valerij_dlg = dlg{
	nam = "Валерий",
	hideinv = true,
	entered = [[Я стою перед дверью в комнату Валерия]];
	enter = function(s)
		format.para = true
	end,
	exit = function(s)
		format.para = false
		corridor.state = 2;
		corridor.count = 1
		walk 'corridor'
	end,
	var {
		state = 0;
	},
	phr = {
		{"Валерий!", true, code[[valerij_dlg:upd()]]},
		{"<i>Стучать</i>!", true, code[[valerij_dlg:upd()]]},
		{"Эй! Ау! Валерий!", true, code[[valerij_dlg:upd()]]},

		{tag = 'what', false, "Это я, Михаил. Электричества на всей станции нет, вообще!", "Бред какой-то...", [[pon 'use_card']]},
		{tag = 'who', false, "Тут что-то странное творится, я едва из своей комнаты выбрался.", "Что? Ты пьян что-ли?..", [[poff 'what'; pon 'use_card']]},

		{tag = 'use_card', false, "Так попробуй открыть дверь! Замок тоже не работает", "Замки от отдельного источника запитаны, не паникуй. Жди, я сейчас", [[pon 'help']]};

		{tag = 'help', false, "Ну что?", "Да не гони коней, ищу карту", [[pon 'help2']]};
		{tag = 'help2', false, "Нашел?", "Черт, замок не работает. Как такое возможно?!", [[pon 'manual']]},
		{tag = 'manual', false, "Понятия не имею, потому тебя и разбудил", "Ладно, потом. Что произошло, что со светом случилось?", [[pon 'manual2']]};
		{tag = 'manual2', false, "Я не знаю. Проснулся у себя в комнате, электричества нет", "Как ты выбрался тогда?", [[pon 'instruction']]};
		{tag = 'instruction', false, "Вскрыл панель и запитал блокирующий механизм от батареи фонаря из аварийного комплекта", "О.. Ладно, попробую повторить. А ты сходи в командный центр, посмотри, может там что работает. Пошлешь сигнал, тогда.", [[pon 'ok']]};

		{tag = 'ok', false, "Хорошо", true, [[walk 'corridor']]}
	},
	upd = function(s)
		s.state = s.state + 1;
		if s.state == 3 then 
			p "Наконец-то из-за двери раздается глухое ворчание -- подозреваю, Валерий выругался в голос. Я подождал несколько мгновений и замолотил по двери опять.^ На этот раз послышалось куда более внятное \"Да иду я!\", с куда более внятными злыми нотками. Я опять замер, прислушиваясь. Когда уже был готов снова кричать, из-за двери донеслось растерянное \"Эй, кто там, -- у меня верхний свет не работает, погоди минуты\"."
			s:pon 'what'
			s:pon 'who'
		end
	end,
}

anastasia_dlg = dlg{
	nam = "Анастасия",
	entered = [[Миша, у меня с замком проблема, я выйти не могу! Можешь послать запрос на диагностику? И пусть меня откроют!]],
	enter = function(s, from)
		format.para = true
	end,
	exit = function(s)
		format.para = false
		corridor.state = 5; 
		corridor.count = 1
	end,
	phr = {
		{"Станция обесточена, потому замки не работают и нет электричества", "Что произошло?", [[pon 'what'; poff(2)]]},
		{"Коридор перекрыт гермовратами", "Чем?", [[pon 'why'; poff(1)]]},


		{tag = 'what', false, "Я не знаю, проснулся в темноте...", txtem"Вдруг по коридору проносится гулкое \"БАХ\"", [[poff 'why'; pon 'bang']]},
		{tag = 'why', false, "Гермоврата, они перегораживают...", txtem"Вдруг по коридору проносится гулкое \"БАХ\"", [[poff 'what'; pon 'bang']]};

		{tag = 'bang', false,"Эмм.., ты слышала?", "Конечно, я слышала. Это ведь с той стороны коридора? Это должно быть ремонтная бригада!", [[pon 'suspicious']]},
		{tag = 'suspicious',false, "... Один удар? Это сигнал?", "Миша, что там...", [[pon 'bye']] },
		{tag = 'bye', false,"Настя, я пойду проверю. Никуда не уходи", true, [[walk 'corridor']]}
	},
}
	
--====================| Финал |====================-- 
epilogue = room{
	nam = "Моя комната",
	var{
		state = 1;
	},
	enter = function(s)
		format.para = true;
	end,
	forcedsc = true;
	hideinv = true;
	entered = [[Мы оба вбегаем в мою комнату, едва не заклинив плечами в дверном проеме. Валерий захлопывает дверь, я хватаю стул и вставляю его под ручку. "Хлипко". Упираюсь в него коленом, упираюсь дверью руками в дверь, упираюсь волей против грохочущего по коридору ужаса.^Валерий не долго думая налегает плечом рядом в дверь. Брошенные фонари причудливо очерчивают тени, но выражение ужаса не сложно...^^Толчок. Мы сдерживаем. С той стороны раздается еще один вопль, я различаю в нем предупреждение. Еще {hold_it|толчок}.]],
	dsc = function(s)
		if s.state == 2 then
			p [[Держать! Сила с той стороны двери все напирает и напирает, я чувствую как скользит на пару миллиметров моя нога. С натужным окриком выжимаю из икр еще немного и дверь возвращается на отвоеванные монстром пяди обратно.^ Возвращается легко -- мой вскрик словно бы отпугнул дроида. Он прекратил давить. Он издал еще один жуткий вопль. Он ничего не делает.^^{hit|Удар}]];
		elseif s.state == 3 then
			p [[Удар существа прошибает дверь. Валерий охает и сгибается. Я вижу на его футболке кровь, крупная щепа вонзается куда-то под ребра. Его лицо искривлено, он оседает.^ Клешня бьет еще раз, растопыривается и рвет на себя. Дверь с треском разлетается.^ Я отступаю, понимая что {fin|больше ничего не могу сделать}.]]
		elseif s.state == 4 then
			p [[Дроид вырывает остатки двери и упирает свою морду в мою сторону. Вопль. Я внутренне сжимаюсь, предчувствуя вонзающуюся в меня клешню... Дроид переводит взгляд на Валерия. Рывок, машина опрокидывает человека, нависает за ним. Валерий дергается, пытается отползти -- но клешня прижимает его за горло к полу.^ Я должен что-то сделать: атаковать, бежать -- силы оставили меня. Дроид заносит вторую клешню...^^ И аккуратно опускает её к ране. Хватает за вонзившуюся щепу и вытаскивает её. Часть его брюха откидывается, манипулятор ныряет туда, что-то вытаскивает и тычет в окровавленную футболку. Распространяется горький запах антисептика...^^ {droid_epilogue|Дроид}]]
		elseif s.state == 5 then
			p [["Дроид", -- горло плохо служит мне, но машина расслышала и наставляет свою морду на меня. Еще один жуткий вопль, но я готов к нему. Теперь я готов увидеть в нависшем над человеком механизме большую самоходную аптечку. Готов увидеть в клешне на горле -- фиксацию раненого перед использование медицинского пакета. Готов расслышать в жутком завывании дежурное: "Вы в порядке?".^ Силы окончательно покидают меня. Дроид было дергается в мою, сторону, но я останавливаю его повелительным жестом. Это дроид станции. Аварийный дроид станции. Может оказать первую помощь, разобрать завалы на пути. Голосовой интерфейс. Сломанный, очевидно.^ Голова идет кругом. Я начинаю различать требовательные, с нотками паники выкрики Анастасии, возгласы остальных коллег. И ничего не понимаю. {the_end|Абсолютно}.]];
		end
	end,
	obj = {
		xact( 'hold_it', code[[epilogue.state = 2; return true]] ),
		xact( 'hit', code[[epilogue.state = 3; return true]] ),
		xact( 'fin', code[[epilogue.state = 4; return true]]),
		xact( 'droid_epilogue', code[[epilogue.state = 5; return true]] ),
		xact( 'the_end', code[[walk 'the_end']] ),
	},
}


game_intro = [[Нужна привычка чтобы спокойно спать в тишине. Ведь есть что-то гнетущее в безмолвии мира, что заставляет веки распахнуться, а взгляд -- тщетно метаться в вязкой ночи. И по какой-то причине воспринимаемая в тот момент пустота не дарует закономерного облегчения -- а лишь настораживает еще больше.^
	Лишь потом, после окончательного пробуждения, приходит сбивающее с толку осознание, что в спальне никого нет и быть не может. Мало того, что это бессмысленно, -- так она еще и отгорожена запертой дверью!^^
		{pre_begin|Глубоко вздохнуть}]]
game_intro1 = [[Как и большинство подобных сбоев -- он инстинктивной природы. Напоминание о тех далеких временах, когда ко сну люди отходили в гомонящем лесу и внезапная тишина означала: "Опасность!". Да, уже столетий семь как мы спим исключительно под крышей, в надежных домах -- но резкая перемена фона до сих пор выдергивает нас изо сна.^
		Потому и привычка нужна. Иначе любое собственное движение, малейший шорох, дергают за звоночек доисторической сигнализации. И, что удивительно, та до сих пор отлично справляется: я -- прекрасно понимая причину -- не могу заставить тело скинуть порожденное напряжение.^^
		Благо, есть проверенный способ: {begin|включить свет}]];
stand_up = [[Перспектива оказаться по ту сторону одеяла совсем не радует... Теплая ткань с неодолимой силой прижимает к кровати, а напряженная шея так и просит опустить голову на подушку. Укутаться по-плотнее, отвернуться к стеночке... Нет! Не стоит на том боку спать -- там сердце. Лучше на правом, к стене спиной. Не удобно, зато ребра ни на что не давят. Да, вот так. Натянуть одеяло по уши -- глядишь и глаза согласятся закрыться...^ Я решительно сажусь на кровати. Так не пойдет. Стыдно, в конце концов. Должно было бы быть. А вдруг проводка истлела? Нужно встать, включить свет и удостовериться, что все в порядке. Ну, и шнур потом глянуть.]]
arrive_to_door = [[Уф. Похоже немного перестарался с шагами и почти что врезался в дверь лбом. Надо было руки выставить, о чем я думал...^ В пару прикосновений определяю свое положение относительно двери. Интересно, а можно ли испытать головокружение от того, как воображаемая карта подстраивается под реальный мир?]]
night_walk1 = [[Холодный пластик словно в неком территориальном инстинкте хватает за голые {foot|ступни}. Обуви на том месте, где подсказывает пространственное воображения, не оказалось. Искать их в потемках -- только дольше мёрзнуть. Лучше {go_for_light|свет} зажечь.]]
trigger_failed = [[Я протянул руку в то место, где, по-памяти, должен находится выключатель. Ошибся на какие-то пол ладони.^ Нажимаю...^ Да. Дела...^ Я пощелкал выключателем для верности -- но чуда не случилось. Очень может быть, что с проводкой в моей комнате что-то не так. И что делать? Кому сообщить? Валерию? Или не будет наш "технарь" такой ерундой заниматься? Ладно, "за просто спросить" может и не съест.]]
arrive_to_table = [[Ага: головокружение -- не головокружение -- но рывковая синхронизация ментальной карты с реальностью дезориентирует изрядно. Небось самое близкое к телепортации ощущение что человек может испытать.]]
thing_seems_so_wrong = [[Отточенным движением левой прикладываю ключ-карту к замку и правой нажимаю ручку двери. Рутинная операция, доведенная повторением до автоматизма. Так же рутинно удивляюсь краем мысли, что на всей такой эргономически-кошерной станции цифровые замки они разместили <i>под</i> дверной ручкой -- принуждая руку к рваной траектории "приложил-поднял-нажал", вместо единого плавного движения вниз.^ Это дежурная мысль, регулярно проигрываемая во время процесса и столь же быстро забывающаяся. Левой прикладываю ключ-карту, нажимаю правой на ручку. Тяну. ^ Что-то уже не так. Движение еще исполняется, но обратная связь вовсю вопит на доисторическом языке спинного мозга, что чертовски плохие плохие вещи происходят <i>{прямо сейчас!}</i>]]
seek_light = [[Вот шкаф, вот ручки -- распихиваю. Нутро шкафа того же оттенка слепоты, что и остальное пространство. Но это не особо важно, ибо я точно помню, что небольшая сумка аварийного комплекта лежит внизу отделения.^ Расстегиваю змейку, откидываю клапан и запускаю пятерню внутрь. Пальцы натыкаются на какие-то непонятные объекты, но уже через мгновенье смыкаются на колоколе {swith_to_light_room|фонаря}?]]
open_lock = [[Итак, момент истины. Опускаюсь на корточки перед свисающим проводом и щелкаю выключателем фонаря, снова оказываюсь в абсолютной темноте. Извлекаю аккумулятор и откладываю оставшуюся лампу на колени. Нащупываю две дорожки контактов на аккумуляторе, аккуратно беру шнур. {go_corridor|Совмещаю}.]]




the_end = room{
	nam = "Конец"
}
