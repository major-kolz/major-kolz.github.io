--[[
*** Сохранение игровых достижений
** Не зависит от текущей сессии игры и не обнуляется, если начать заново
** Интересно - пишите в тему игры на instead.syscall.ru/forum/
** (!) Склейку строк лучше не трогать: настроено методом тыка
		 Установку курсора - тоже...
--]]

-- 1 арг.: Таблица "ключ" - величина_изменения_параметра
-- 2 арг.: Увеличить на ВИП (true) или затереть полученным значением (false/nil)
function prwrite(formod, change)	
	local file = io.open('progress.txt');
	local incoming = file:read("*a");
	local out = '';
	local pos = 0	-- запись положений модифицируемых параметров
	---||
	
	if file  == nil then
		error 'Ошибка при открытии файла "progress.txt" для редактирования';
	end
	if formod == nil then
		error 'Не передана таблица параметров для сохранения.';	-- см. объявление ф-ции
	elseif type(formod) ~= 'table' then
		error 'Входящее на сохранение - не таблица параметров.';	
	end
	
	-- Подготовка к записи: определение модифицируемых полей, "установка" курсора перед ними
	if type(formod[1]) ~= 'table' then	-- изменяем один параметр
		pos = string.find (incoming, formod[1]) + 1;	-- определяем строку изменяемого параметра
		pos = string.find (incoming, ':', pos) + 1;
		out = string.sub(incoming, 1, pos);				-- весь текст до 
		local old_value = string.sub(incoming, pos, string.find(incoming, ',', pos) -1);
		local newpos = pos + string.len(old_value);
		if change then
			out = out .. formod[2];
		else
			out = out .. ( tonumber(old_value) + tonumber(formod[2]) );
		end
		out = out .. ',';	
		out = out .. string.sub(incoming, newpos + 1);	-- весь текст после
	else											-- много параметров
		local cursor = 1;
		local iter = 1;
		for iter = 1, #formod do
			pos = string.find (incoming, formod[iter][1], cursor) + 1;	
			pos = string.find (incoming, ':', pos) + 1;
			local end_pos_oldvalue = string.find(incoming, ',', pos) - 1;
			out = out .. string.sub(incoming, cursor, pos);
			local old_value = string.sub(incoming, pos, end_pos_oldvalue);
			if change then
				out = out .. formod[iter][2];
			else	
				out = out .. tonumber(old_value) + tonumber(formod[iter][2]);
			end
			cursor = pos;
			cursor = cursor + string.len(old_value) + 1;
			out = out .. ',';
			iter = iter + 1;
		end 
	end
	file:close();

	---||

	file = io.open('progress.txt', "w");
	if file  == nil then
		error 'Ошибка при открытии файла "progress.txt" для чтения';
	end
	
	file:write(out);
	
	file:close();
end

function pread()
	local data = io.open('progress.txt'):read("*a");
	local result = {};
	local start = 0;
	local fin = 1;
	local iter = 1;
	while string.find (data, ':', start) do
		start = string.find (data, ':', start) + 1;
		fin = string.find (data, ',', start) - 1; 
		result[iter] = string.sub(data, start, fin);
		iter = iter + 1;
	end
	
	return result;
end

function init_prsaves()
	file = io.open('progress.txt');
	if file  == nil then
		print 'Создания файла сохранений "progress.txt" в папке с игрой';
		file = io.open('progress.txt', 'a');
		initial = 'init restart: 0, repeat: 0, lvl: 0, comp: 0, die: 0,';
		file:write(initial);
		file:close();
	else
		prwrite({'restart', 1});
	end
end
