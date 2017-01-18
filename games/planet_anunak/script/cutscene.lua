-- Модуль для последовательной подачи текста cutscene, модернизированный  
-- Основа: http://instead.syscall.ru/wiki/ru/gamedev/modules/cutscene, автор: Пётр Косых	
--
-- Отличия от основной версии: 
--		тэги теперь облекаются в квадратные скобки, а не в фигурные (можно вставлять в текст xact)
--		Внешний вид [cut] "по-умолчанию" теперь определяется полем _cutDefTxt (">>>"). 
--		[cut] и [upd] переводят последующий текст на новую строчку
--		[cut] теперь предварен _cutPrefix (по-умолчанию: "^" - кнопка выводится через пустую строку, так как один перевод от предыдущего пункта)  
--		Добавлен тэг [upd], что эквивалентен прошлому {cut}{cls}. 
--		[upd] вызывает метод update() комнаты-cutscene
--		Удален cls (upd покрывает функциональность)
--		Можно использовать left
--		Переход к следующему состоянию по нажатию space
-- https://github.com/major-kolz/instead-tools/blob/master/cutscene.lua
-- v1.3 by major kolz

require "timer"
require "xact"
require "kbd"

stead.module_init(function()
	hook_keys('space')
end)

local function get_token(txt, pos)
	pos = tonumber(pos) or 1;
	local s, e;
	e = pos
	while true do -- ищем открывающуюся скобку [
		s, e = txt:find("[\\%[]", e);
		if not s then
			break
		end
		if txt:sub(s, s) == '\\' then
			e = e + 2
		else
			break
		end
	end
	local nest = 1
	local ss, ee
	ee = e
	while s do -- ищем закрывающуюся (учитывая вложенность)
		ss, ee = txt:find("[\\%[%]]", ee + 1);
		if ss then
			if txt:sub(ss, ss) == '\\' then
				ee = ee + 1
			elseif txt:sub(ss, ss) == '%]' then
				nest = nest + 1
			else
				nest = nest - 1
			end
			if nest == 0 then
				return s, ee
			end
		else
			break
		end
	end
	return nil
end

local function parse_token(txt)
	local s, e, t
	t = txt:sub(2, -2)
	local c = t:gsub("^([a-zA-Z]+)[ \t]*.*$", "%1");
	local a = t:gsub("^[^ \t]+[ \t]*(.*)$", "%1");
	if a then a = a:gsub("[ \t]+$", "") end
	return c, a
end

cutscene = function(v)
	v.txt = v.dsc
	v.forcedsc = true
	v._cutPrefix = v._cutPrefix or "^";		-- предварять cut-кнопку пустой строкой
	v._cutDefTxt = v._cutDefTxt or ">>>";	-- определим внешний вид cut-кнопки (наверное, можно и картинку через img ) 
	v._readFrom = 1;								-- счетчик для не отображаемой (просмотренной) части
	v._lastButton = 0;							-- запоминаем какое действие должны сделать для kbd
	v._foldHere = 0;								-- будущее значение _readFrom

	v.update = v.update or function() return false end;

	v.left_react = false;
	if v.left then
		v.left_react = v.left	
	end
	v.left = function(s, w)
		timer:set(s._timer);
		s:reset()
		if s.left_react then
			local t = type( s.left_react );
			if t == "string" then
				p( s.left_react );
			elseif t == "function" then
				s:left_react(w);
			else
				error("Illegal 'left' handler! Type is: " .. t )
			end
		end
		s.sole_passible_path = nil;
	end;

	if v.timer then
		error ("Do not use timer in cutscene.", 2)
	end
	v.timer = function(s)
		s._fading = nil
		s._state = s._state + 1
		timer:stop()
		s:step()
		return true
	end;
	if not v.pic then
		v.pic = function(s)
			return s._pic
		end;
	end
	if not v.fading then
		v.fading = function(s)
			return s._fading
		end
	end
	v.reset = function(s)
		s._state = 1
		s._code = 1
		s._fading = nil
		s._txt = nil
		s._dsc = nil
		s._pic = nil
	end
	v:reset()

	v.entered_react = false; 
	if v.entered then
		v.entered_react = v.entered
	end
	v.entered = function(self)
		if self.entered_react then
			local t = type( self.entered_react );
			if t == "string" then
				p( self.entered_react );
			elseif t == "function" then
				self:entered_react();
			else
				error("Illegal 'entered' handler! Type is: " .. t )
			end
		end
		self:reset()
		self._timer = timer:get()
		self:step();
	end;
	v.kbd = function(self, down, key)
		if key == "space" and down then
			if self._lastButton == 0 then
				if self.sole_passible_path then
					walk( self.sole_passible_path )
				elseif exist'fight!' and not disabled(exist'fight!') then
					for i, v in ipairs(self.obj) do
						if v.nam == "fight!" then
							v:act()
						end
					end
				else
					set_sound 'snd/error.ogg'
				end
			else
				if self._lastButton == 1 then
					self:step();
				else
					self:step_upd();
				end
			end
		end
		return true;
	end
	v.step = function(self)
		local search_start, search_end, c, a 					-- search start, search end, command descriptor, command argument
		local phrases_left = v._state
		local txt = ''
		local code = 0
		local out = ''
		local new_phrase = false

		self._lastButton = 0

		if not self._txt then
			if type(self.txt) == 'table' then
				local k,v 
				for k,v in ipairs(self.txt) do
					if type(v) == 'function' then
						v = v()
					end
					txt = txt .. tostring(v)
				end
			else
				txt = stead.call(self, 'txt')
			end
			self._txt = txt
		else
			txt = self._txt
		end

		while phrases_left > 0 and txt do
			if not search_end then
				search_end = self._readFrom
			end
			local oe = search_end
			search_start, search_end = get_token(txt, search_end)
			if not search_start then
				c = nil
				out = out..txt:sub(oe)
				break
			end
			local strip = true
			c, a = parse_token(txt:sub(search_start, search_end))
			if c == "pause" or c == "fading" then
				phrases_left = phrases_left - 1
			elseif c == "cut" or c == "upd" then
				phrases_left = phrases_left - 1
				new_phrase = true
			elseif c == "pic" then
				if a == '' then 
					error( "Forgot argument (path to resource) for 'pic'", 2 )
				end
				self._pic = a
			elseif c == "code" then
				code = code + 1
				if code >= self._code then
					local f = stead.eval(a)
					if not f then
						error ("Wrong expression in cutscene: "..tostring(a))
					end
					self._code = self._code + 1
					f()
				end
			elseif c == "walk" then
				if a and a ~= "" then
					return stead.walk(a)
				end
				strip = false
			else
				error( "Illegal command: " .. c );
			end

			if strip then
				if new_phrase then
					new_phrase = false
					out = out .. txt:sub(oe, search_start - 1) .. "^"
				else
					out = out..txt:sub(oe, search_start - 1)
				end
			elseif c then
				out = out..txt:sub(oe, search_end)
			else
				out = put..txt:sub(oe)
			end
			search_end = search_end + 1
		end

		v._dsc = out
		if c == 'pause' then
			if not a or a == "" then
				a = 1000
			end
			timer:set(tonumber(a))
		elseif c == 'cut' then
			self._state = self._state + 1
			if not a or a == "" then
				a = v._cutDefTxt
			end
			v._dsc = v._dsc .. v._cutPrefix .. "{cut|"..a.."}";
			self._lastButton = 1
		elseif c == 'upd' then
			self._state = 1
			if not a or a == "" then
				a = v._cutDefTxt
			end
			v._dsc = v._dsc .. v._cutPrefix .. "{upd|"..a.."}";
			self._foldHere = search_end
			self._lastButton = 2
		elseif c == "fading" then
			if not a or a == "" then
				a = game.gui.fading
			end
			self._fading = tonumber(a)
			timer:set(10)
		end
	end
	v.step_upd = function(self)
		self:update();
		self._readFrom = self._foldHere;
		self._code = 1
		self:step(); 
	end
	v.dsc = function(s)
		if s._dsc then
			return s._dsc
		end
	end
	if not v.obj then
		v.obj = { }
	end
	stead.table.insert(v.obj, 1, xact('cut', function() here():step(); return true; end ))
	stead.table.insert(v.obj, 2, xact('upd', function() here():step_upd() return true; end ))
			 
	return room(v)
end
