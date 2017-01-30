night_camp = room{
	nam = true;
	pic = "img/locations/night_camp.png;img/image_frame.png";
	obj = {
		'calm_night', 'disturbed_night', 'roach_bite', 'dinoband_attack', 'trex_attack', 'sharkteeth_attack', 'little_pangolin_attack';

		xact( 'goodNight', "Ночь пройдет без происшествий, бойцы отлично выспяться" ),
		'night_camp_run', 'night_camp_go'
	};
	entered = function(s) 
		enable 'night_camp_run'
		disable 'night_camp_go'
		for i = 1, 7 do
			s.obj[i].selected = false;
		end
	end,
	var {
		frame = 1;
		selection = 0;
	},
	run = function(s)
		timer:set(100)
		s.frame = 3
		s.selection = 4 + 7 + rnd(14)
	end,
	timer = function(s)
		s.frame = s.frame + 1;
		if s.frame == s.selection then
			timer:stop()
			enable 'night_camp_go'
			return true
		end

		local pointer = s.frame % 7 + 1
		s.obj[pointer].selected = true
		if pointer == 1 then
			s.obj[1].selected = true
			s.obj[7].selected = false
		else
			s.obj[pointer-1].selected = false
		end

		return true
	end,
	kbd = function(self, down, key)
		if key == "space" and down then
			if not disabled 'night_camp_run' then
				night_camp_run:act()
			else
				night_camp_go:act()
			end
		end

		return true;
	end
}

night_camp_run = obj{
	nam = true;
	dsc = "^^^" .. txtc[[{Ночевка}]];
	act = function(s)
		night_camp:run()
		disable( s )
		return true
	end,
}

night_camp_go = obj{
	nam = true;
	dsc = "^^^" .. txtc[[{Вперед}]];
	act = function(s)
		local evnt
		for i = 1, 7 do
			evnt = night_camp.obj[i]
			if evnt.selected then
				if evnt._count > 0 and evnt:test() then
					walk( 'p' .. evnt.to )
				else
					walk( 'p' .. calm_night.to )
				end
				
				if evnt ~= calm_night then
					evnt._count = evnt._count - 1
				end
				break
			end
		end
	end,
};

---------------------------------
local function event(v)
	if not v._count then
		v._count = 1
	end
	v.dsc = function(s)
		local link = '{' .. s.nam .. '}'
		if s.selected then
			p( txttab '8%' .. '►' )
			link = txtb( link )
		end
		p ( txttab '12%' )

		if s:test() and s._count > 0 then
			p( link )
			if s._count > 1 then 
				p( "(" .. s._count .. ")" )
			end
			if s._count <= 0 then
				p " ← {goodNight|Спокойная ночь}"
			end
			pn''
		else
			if s.selected then
				pn( txtb(txtst(s.nam) .. " ← {goodNight|Спокойная ночь}") )
			else
				pn( txtst(s.nam) .. " ← {goodNight|Спокойная ночь}" )
			end
		end
	end

	return obj(v)
end

calm_night = event{
	nam = "Спокойная ночь",
	act = function(s)
		if s:test() then
			p [[Ничто не потревожит сон бойцов.]];
		else
			p [[Была бы палатка...]]
		end
	end,
	test = function()
		return exist( tent, equipment );
	end;
	to = 75;
}

disturbed_night = event{
	nam = "Тревожная ночь",
	_count = 8;
	act = [[Мелкие неприятности не дадут бойцам как следует выспаться]];
	test = function(camp)
		return true;
	end;
	to = 76;
}

roach_bite = event{
	nam = "Тараканы покусали",
	_count = 4;
	act = function(s)
		if s:test() then
			p [[Тянущиеся к теплу насекомые будут осаждать спальники бойцов]];
		else
			p [[Репеллент исправно отпугивает мерзких насекомых]]
		end
	end,
	test = function()
		return not exist( repellent, equipment )
	end;
	to = 76;
}

dinoband_attack = event{
	nam = "Нападение группы динозавров",
	act = [[Непрошеные гости вторгнуться в ваш лагерь и проверят поклажу]];
	test = function(camp)
		return true;
	end,
	to = 77;
}

trex_attack = event{
	nam = "Нападение тираннозавра",
	to = 78;
	act = [[Атака застанет ваш отряд в расплох]];
	test = function(camp)
		return true;
	end
}

sharkteeth_attack = event{
	nam = "Нападение саблезубого тигра";
	act = function(s)
		if s:test() then
		else
			p [[Акустический модулятор отпугнул этого монстра]];
		end
	end,
	test = function(camp)
		return not ( exist(modulator, equipment) and exist(accumulator, equipment) and accumulator._charge )
	end,
	to = 68;
}

little_pangolin_attack = event{
	nam = "Нападение малого ящера";
	act = function(s)
		if s:test() then
			p [[Привлеченная запахом людских тел юркая хищная тварь наведается в ваш лагерь ]];
		else
			p [[Генерируемые модулятором волны крайне неприятны уху хищника и он старался держаться от них как можно подальше]]
		end
	end,
	test = function(camp)
		return not ( exist(modulator, equipment) and exist(accumulator, equipment) and accumulator._charge )
	end,
	to = 83;
}
