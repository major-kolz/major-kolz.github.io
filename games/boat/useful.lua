-- Copyright 2015 Nikolay Konovalow
-- Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
-- http://www.apache.org/licenses/LICENSE-2.0>


--====================| Набор полезных функций |====================--
-- Отображение документа:
-- 	табуляция = 3 пробела, 133 символа в строке 
-- Соглашение о именовании:
-- 	нижнее подчеркивание в конце имени  = возвращается значение
-- 	нижнее подчеркивание в начале имени = возвращается функция 
-- 	отсутствие подчеркивание            = процедура (ничего не возвращает)


--| ret = state and <exp1> or <exp2>  Если state истинно, то ret получит <exp1> иначе <exp2>. Из Programming on Lua 2ed, Ierusalimschy
--| В строку темы default помещается 84 символа: 82 знака '*' и 2 '|'
--| string.format позволяет выводить заданное количество знаков, преобразовывать в другие формты
--| txttab позволяет выставить отступ в пикселях. Есть возможность указывать в процентном соотношении - приписывая '%'

function offset_( size ) 					-- Вывести отступ указанной размерности (в пикселях)
	isErr( size == nil or size < 0, "Недопустимая величина отступа: " .. (size or 'nil') );
	return img("blank:" .. size .."x1");
end

--{ Метафункции, облегчают написание кода, не описывающего непосредственно игровые конструкции
function isErr( cond, msg, lvl )			-- Лаконичная форма для отлова ошибок.
	if cond then
		error( msg, lvl or 3 )				-- Если используете непосредственно в комнатах/объектах - передавайте '2' на месте lvl
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

function divBy( text, command_regex, exclusive ) -- Возвращает 1) все подстроки из text, соответствующие command_regex и 2) оставшийся тест
	local start, finish;
	local ordinary, commands = {}, {}

	while text ~= nil do
		start, finish = string.find( text, command_regex )

		if start == nil or finish == nil then break end

		table.insert( ordinary, string.sub( text, 1, start-1 ))
		if exclusive then  -- Отрезать последний символ (замыкающий регион command_regex) 
			table.insert( commands, string.sub( text, start+1, finish-1 ))
		else
			table.insert( commands, string.sub( text, start+1, finish ))
		end
		text = string.sub( text, finish+1 )
	end

	if text ~= nil then
		table.insert( ordinary, text )
	end

	return ordinary, commands
end
--}

function prnd( arg, needReturn )			-- Возвращает случайную реплику из таблицы arg
	isErr( type(arg) ~= "table", "'prnd' get table as argument" )
	return unfold( arg[ rnd(#arg) ], needReturn );
end

function _prnd( arg )
	return function()
		prnd( arg )
	end
end

function _dynout(vis_desc)					-- Динамическое описание сцены по совету v.v.b; вызывая, по очереди выведем весь vis_desc
	local visit = 0;							-- После выхода из игры вывод пойдет сначала
	isErr( type(vis_desc) ~= "table", "_dynout take table as parameter")

	return function ()
		if visit ~= #vis_desc then
			visit = visit + 1;
		end
		return unfold( vis_desc[visit] );	
	end
end

function switch( condition )				-- Оператор выбора для условия condition
	return function(data)					-- data может иметь поле def: на случай недопустимых значений condition 
		isErr( type(data) ~= "table", "Switch data should be table. Got: " .. type(data) );

		local react = data[condition] or data.def or function() return true end;
		unfold( react )
		if data.event then					-- Поле event вызывается каждый раз. Можно присвоить функцию со счетчиком, к примеру
			unfold( data.event )
		end
	end
end

function _visits( variants )				-- Аналог _dynout, завязанный на посещения комнаты (без def будет выход за границы)
	isErr( type(variants) ~= "table", "_visits take table as parameter" )
	return function()
		switch( visits() )( variants )
	end
end

--{ Следующие секцию я подсмотрел у vorov2
-- unfold входит в их число
function sound( nam, chanel )				
	set_sound("snd/" .. nam .. ".ogg", chanel);
end

function music( nam )							
	set_music("mus/" .. nam .. ".ogg");	
end

function image_( nam )						
	return 'img/' .. nam .. '.png';	
end

function _if( cond, pos, neg )			-- Сокращение на случай, если обработчик имеет два состояния и возвращает текст
	return function(s)						-- cond - строка с именем управляющей переменной (из этого объекта/комнаты)
		if s[cond] then
			unfold( pos );
		else
			unfold( neg );
		end
	end
end

function _trig( cond, pos, neg )		-- Для двухступенчатых событий. Первый раз выполняется posact, все остальные - negact 
	return function(s)						-- Пример использования: объекты с вводным(расширенным) и игровым описаниями 
		if s[cond] then
			unfold( pos );
			s[cond] = false;
		else
			unfold( neg );
		end
	end
end
--}

function _say( phrase, ... )				-- Создание обработчика-индикатора (показывают value-поле[/поля] данного объекта)
	-- Рекомендую для act/inv - отображать внутренние счетчики в одну строчку
	local value = {...}
	local react;			
	
	if #value == 0 then						-- Короткая форма: строка, отображаемые поля помечаются @ (пример: "Всего яблок: @count")
		isErr( string.find(phrase, "@") == nil, "Use phrase without placeholder: @<name>" )
		local txt, var = divBy( phrase, '@[a-zA-z0-9_]*' ) 
		react = function( s )
			local handler = ""

			for i = 1, #var do handler = handler .. txt[i] .. s[var[i]]	end

			if #txt == #var then p( handler );
			else                 p( handler .. txt[#txt] )	end
		end
	elseif #value > 0 then				-- Расширенная форма с заполнителями в С-стиле %<...>
		for _, v in ipairs( value ) do isErr( type(v) ~= "string", "Value may be string or table of strings" ) end
		react = function( s )						
			local open_values = {}
			for _, v in ipairs( value ) do table.insert( open_values, s[v] ) end 
			p( string.format(phrase, stead.unpack(open_values)) )
		end
	else
		error( "Check '_say' second argument's: it should be string and (optional) fields' name (strings too)", 2 )
	end

	return react
end

function vis_change( obj )				-- Переключатель состояния объектов 
	if disabled( obj ) then
		obj:enable();
	else
		obj:disable();
	end
end

function _select( variance )			-- Для обработчиков входа-выхода и use/used
	isErr( type(variance) ~= "table", "Argument of '_select' should be table" )	
	if not variance.react then	variance.react = p 	end		-- можно и walk передать, и prnd
	if type( variance.handler  ) == "string" then 				-- если строка - то используем как аналог switch
		local field = variance.handler
		variance.handler = function(s) return s[field] end
	end

	return function( self, arg )
		local id = deref(arg) or variance.handler(self)
		local impact = variance[ id ]
		if impact then
			variance.react( impact )
		elseif variance.def then
			unfold( variance.def )
		end
	end
end

function	_dropList(s)               -- Заготовка для menu (карман) 
	if s._toOpen then
		s._toOpen = false
		s.obj:enable_all();
	else
		s._toOpen = true
		s.obj:disable_all();
	end	
end
-- vim: set tabstop=3 shiftwidth=3 columns=133 foldmethod=syntax
