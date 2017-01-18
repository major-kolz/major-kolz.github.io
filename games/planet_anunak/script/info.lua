require 'hideinv'

function info_page(page)
	page.exit = function(_, to)
		if to == info._from then
			isGame = true; 
			theme.menu.gfx.button('img/menu.png', 737, 580); 
			if to == p168_supply or to == p168_mech or to == p168_main or to == p168_arsenal then
				format.para = false
			end
		end
	end

	return room(page)
end

back_to_game =	vroom( '^Обратно в игру', function() 
	return info._from
end );

info = info_page{
	nam = "Игровая справка";
	dsc = [[^ Вы можете "разворачивать" переходы между параграфами клавишей "пробел"
	^^
	Навигация стрелками и кнопками "pageUp"/"pageDown" позволит быстро выбрать желаемый вариант развития событий. Нумпад - отличный вариант из-за второго enter'a
	^^
	Быстрое сохранение/загрузка: F8/F9
	^^
	Вы проиграете, если закончится провиант, до нуля упадет мораль или погибнет более 4х человек.
	]];
	info = true;
	hideinv = true;
	enter = function( s, frm )
		if not frm.info then
			s._from = frm;
		end

		if frm == p168_supply or frm == p168_mech or frm == p168_main then
			walk 'info_equip'
		elseif frm == p168_arsenal then
			walk 'info_addWeapon'
		elseif frm.isBattle or exist('fight!', frm) then
			walk 'info_battle'
		elseif frm == p104 or frm == night_camp then
			walk 'info_camping'
		end

		return true;
	end,
	toplay = function(s)
		walk( s._from )
	end,
	way = {
		'info_equip', 'info_camping', 'info_addWeapon', 'info_battle',
		back_to_game,
	};
}

info_equip = info_page{
	info = true;
	hideinv = true;
	forcedsc = true;
	nam = "Экипировка",
	dsc = [[В свою миссию на планету Анунак вы можете взять некоторое количество предметов -- при наличии в определенных ситуациях станет доступной возможность выбрать еще один вариант действия. Не все из открывающихся возможностей непременно являются лучшим выходом из ситуации, так что будьте внимательны.
	^^
	Предметы Аптечка и Антистресс можно применить в любой момент, а не только в отведенных сюжетом -- они восстанавливают {battle_ability|Боеспособность} бойцов и {moral|Мораль} отряда.
	^^
	Часть предметов является {xwalk(info_addWeapon)|Дополнительным оружием}.
	^^
	Провиант является специальным предметом -- его окончание означает сворачивание миссии. Одна единица Провианта расходуется в день автоматически.
	]],
	way = {
		vroom( "Общее", 'info' ),
		'info_camping', 'info_addWeapon', 'info_battle';

		back_to_game,
	};
	obj = {
		xact( 'battle_ability', "Потеря боеспособности не ведет к смерти бойца. Если у вас четыре небоеспособных человека -- вы можете продолжать игру, четыре же смерти ведут к проигрышу" ),
		xact( 'moral', "В случае падении Морали до нуля, миссия считается проваленной" ),
	},
}

info_addWeapon = info_page{
	info = true;
	hideinv = true;
	forcedsc = true;
	dsc = [[Перед боем вы можете экипировать <i>Дополнительное оружие</i> (для этого слева появляются специальные кнопки) - оно займет специальный (первый) слот. В начале каждого раунда, как и для бойцов, для него будет "бросаться кубик" что определит его действия на этот раунд.^^"Грани" <i>Доп.оружия</i>:^ 
	• Гранатомет -- 4 {expl|Взрыва} \ 2 {vd|Пустоты}. Одноразовое: после выпадания не-{vd|Пустой} грани кубик для этого слота больше не бросается.^ 
	• Огнемёт -- 3 {expl|Взрыва} \ {sht|Выстрел} \ 2 {vd|Пустоты}. Одноразовое. ^ 
	• Акустический пистолет -- 2 {shck|Шока} \ 4 {vd|Пустоты}^ 
	• Вибро-мачете -- 3 {sht|Выстрела} \ 3 {vd|Пустоты}^ 
	• Инфразвуковой генератор -- 2 {shld|Щита} \ 4 {vd|Пустоты} ]],

	nam = "Доп. оружие",
	obj = {
		xact( 'expl', "Наносит 5 единиц урона" ),
		xact( 'vd', "Оружие пропускает ход" ),
		xact( 'sht', "Наносит 1 единицу урона" ),
		xact( 'shck', "Один кубик противника пропускает ход" ),
		xact( 'shld', "Каждый боец получает на этот ход дополнительную единицу защиты" ),
	},
	way = {
		vroom( "Общее", 'info' ),
		'info_equip', 'info_camping', 'info_battle';

		back_to_game,
	}, 
};

info_battle = info_page{
	info = true;
	hideinv = true;
	nam = "Боевка",
	dsc = [[^ Механика боя - пошаговая. В начале каждого раунда игрок выбирает одну из пяти возможных <i>тактик</i>, "бросаются кубики", после чего рассчитываются результаты действий каждой из сторон и, после нажатия на кнопку "конец раунда", проигрываются соответствующие анимации и выводится <i>лог</i> урона]],
	obj = {
		'info_battle_tab',
	},
	way = {
		vroom( "Общее", 'info' ),
		'info_equip', 'info_camping', 'info_addWeapon';

		back_to_game,
	}, 
};

info_battle_tab = obj{
	nam = true;
	isTactics = true;
	dsc = function(s)
		pn ''
		if s.isTactics then
			pn( txtc "<u>Доступные тактики</u> | {Расшифровка граней}" )
			p(s.tactics)
		else
			pn( txtc "{Доступные тактики}	| <u>Расшифровка граней</u>" )
			s:dices()
		end
		p [[^^ В бою можно использовать {xwalk(info_addWeapon)|Дополнительное оружие}.]]
	end,
	act = function(s)
		s.isTactics = not s.isTactics
		return true
	end,
	tactics = [[
	• <b>Моральная поддержка</b> -- отменяется одна выпавшая иконка Бегства у отряда^
	• <b>Управление огнем</b> -- если у командира выпадет иконка Глаз, то к атаке отряда бонус +2 Ущерба врагу (если ни у кого из бойцов не выпало ни одного "Взрыва", то бонус пропадает.^
	• <b>Глухая оборона</b> -- одна иконка Взрыва отряда не засчитывается, но зато все ущербы ШОК врага не действуют на отряд.^
	• <b>Маскировка</b> --  игрок после броска кубиков врага, может заставить врага перебросить его кубики атаки (единожды)^
	• <b>Маневрировать</b> -- право единожды перебросить кубики отряда^^
	<i>Просмотреть подсказку по конкретной тактике можно и непосредственно в бою - по нажатию на расположенную слева от тактики кнопку с символом "?"</i>]];
	dices = function(s)
		local w = function( nam, txt ) 
			pn( img('img/dices/crew/' .. nam .. '.png') .. " -- " .. txt ) 
		end
		local wE = function( nam, txt ) 
			pn( img('img/dices/enemy/' .. nam .. '.png') .. " -- " .. txt ) 
		end
		w( 'empty', "боец бездействует этот ход" )
		w( 'eye', "см. тактику 'Управление огнем' (только у Ирвина)" )
		w( 'protect', "нейтрализует одну единицу нанесенного бойцу урона" )
		w( 'run', "боец выбывает из боя" )
		w( 'shocked', "боец выбывает из боя на один ход" )
		w( 'shot', "нанесет противнику единицу урона" )
		pn ''
		wE( 'claw', "противник нанесет единицу урона" )
		wE( 'jaw', "противник нанесет две единицы урона" )
		wE( 'run', "при выпадении на всех кубиках противника вам засчитывается досрочная победа" )
	end,
}

info_camping = info_page{
	info = true;
	hideinv = true;
	nam = "Ночевки",
	dsc = [[По завершению каждого дня, отряд устраивается на ночевку -- результат которой выбирается случайным образом. Ночь может пройти без происшествий, а может случится и так, что вы подвергнетесь нападению.^
	Наличие определенных {xwalk(info_equip)|предметов} в инвентаре может сделать благоприятные варианты более вероятными.]],
	way = {
		vroom( "Общее", 'info' ),
		'info_equip', 'info_addWeapon', 'info_battle';

		back_to_game,
	}, 
}