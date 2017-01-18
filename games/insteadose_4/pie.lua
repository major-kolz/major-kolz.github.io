-- $Name:Пирог$
-- $Version: 0.1$
-- $Author: Ordos$

instead_version "2.4.0"
require "para"
require "dash"
require "quotes"
require "xact"
require "hideinv"

game.act = [[Не работает.]]
game.use = [[Это здесь не поможет.]]
game.inv = [[Зачем мне это?]]

main = room {
	nam = [[Пирог]];
	forcedsc = true;
	obj = { vobj('start_game','{Начать игру}') };
	act = function()
		walk('intro');
	end;
	dsc = [[^^Эта игра была написана специально для конкурса "Инстедоз 4 комнаты"^
			Автор: Ordos^
			2016 год.]];
}

intro = room {
	nam = [[Пролог]];
	forcedsc = true;
	dsc = [[Ура! Наконец-то отпуск! Как же долго тянулся этот тяжелый рабочий год.^
	Ну что же -- надо бы это дело отметить! Позову друзей, приготовлю им пирог. Посидим, как в старые добрые времена!^
	]];
	obj = { vobj('continue','{Дальше}') };
	act = function()
		set_music('music/music.mod', 0);
		walk('bedroom');
	end;
}

epilog = room {
	nam = [[Эпилог]];
	forcedsc = true;
	dsc = [[Ну что же. Пирог готов. Друзей я тоже пригласил. Осталось только прибраться немного и встречать гостей, но это я уже сам :)^^
	Спасибо тебе, дорогой игрок, что помог мне -- сам бы я не справился! Ещё хотелось бы сказать "спасибо" автору и всем-всем-всем!
	^]];
}


-----------
-- Сцены --
-----------

kitchen = room {
	nam = [[Кухня]];
	dsc = [[]];
	obj = {
		'microwave',		-- Микроволновка.
		'roulette',			-- Рулетка.
		'chair',			-- Стул.
		'fridge',			-- Холодильник.
		'big_dish',			-- Большая миска.
		'little_dish',		-- Маленькая миска.
		'oven'				-- Духовка.
	};
	way = { 'bedroom',
			'shop'
	};
};

bedroom = room {
	nam = [[Спальня]];
	dsc = [[Моя спальня. Тут я сплю и всячески отдыхаю. Бардак тут, конечно, страшный. Надо бы разобрать как-нибудь на досуге.]];
	obj = {
		'chandelier',	-- Люстра.
		'airplane',		-- Бумажный самолетик.
		'cupboard',		-- Шкаф.
		'phone',		-- Телефон.
		'instruments',	-- Инструменты.
		'book',			-- Книга.
		'costume',		-- Костюм.
		'bed',			-- Кровать.
		'aquarium',		-- Аквариум.
		'drill',		-- Дрель.
		'dart_board',	-- Доска для дротиков.
		'darts',		-- Дротики.
		'bike'			-- Велосипед.
	};
	way = { 'kitchen',
			'shop'
	};
};

shop = room {
	nam = [[Магазин]];
	enter = function()
		if not have(money) then
			p [[В магазин без денег? Коммунизм-таки наступил?]];
			return false;
		end;
		if not bike.isOk then
			p [[Пешком далековато. Надо бы поискать какой-нибудь транспорт.]];
			return false;
		end;
		if pie.egg1 then
			enable(egg2);
		end;
	end;
	exit = function()
		if basket.price > 0 then
			p [[Надо бы оплатить все, что я тут набрал.]];
			return false;
		end;
		if have(basket) then
			remove(basket, me());
			p [[Выходя, я положил корзину к другим.]];
		end;
	end;
	dsc = [[Суперминимаркет. Никогда не понимал, что это значит. Товаров тут тьма -- все полки завалены разным добром. Тут-то я точно найду то, что мне надо.]];
	obj = {
		'girl',			-- Девушка.
		'baskets',		-- Корзины для продуктов.
		'flour',		-- Мука.
		'baking_powder',-- Разрыхлитель.
		'cinnamon',		-- Корица.
		'sugar',		-- Сахар.
		'milk',			-- Молоко.
		'pineapple',	-- Ананас.
		'egg',			-- Яйцо.
		'egg2',			-- Второе яйцо.
		'butter_discount',	-- Масло со скидкой.
		'butter',		-- Масло.
		'apples_discount',	-- Яблоки со скидкой.
		'apples',		-- Яблоки.
		'cash'			-- Касса.
	};
	way = { vroom('Вернуться домой', 'bedroom') };
};


-------------
-- Объекты --
-------------

tasks = obj {
	nam = [[игровые задачи]];
	var {
		VasyaOk = false;		-- Пригласили ли Васю? Да/Нет. true/false.
		PetyaOk = false;		-- Пригласили ли Петю? Да/Нет. true/false.
		MishaOk = false;		-- Пригласили ли Мишу? Да/Нет. true/false.
		pieOk = false;			-- Испекли ли пирог?  Да/Нет. true/false.
	};
};

pie = obj {
	nam = [[пирог]];
	var {
		flour = false;			-- Добавили ли муку? Да/Нет. true/false.
		cinnamon = false;		-- Добавили ли корицу? Да/Нет. true/false.
		baking_powder = false;	-- Добавили ли разрыхлитель? Да/Нет. true/false.
		piece_butter = false;	-- Добавили ли масло? Да/Нет. true/false.
		sugar = false;			-- Добавили ли сахар? Да/Нет. true/false.
		use_drill = false;		-- Использовалась ли дрель? Да/Нет. true/false.
		egg1 = false;			-- Добавили ли яйцо? Да/Нет. true/false.
		egg2 = false;			-- Добавили ли второе яйцо? Да/Нет. true/false.
		milk = false;			-- Добавили ли молоко? Да/Нет. true/false.
		mix = false;			-- Выкинули содержимое одной миски в другую? Да/Нет. true/false.
		apples = false;			-- Добавили ли яблоки? Да/Нет. true/false.
	};
};

roulette = obj {
	nam = [[рулетка]];
	inv = [[Рулетка -- это измерительный прибор.]];
	tak = [[Я взял рулетку.]];
	dsc = [[Внутри лежит {рулетка}.]];
}: disable();

pineapple = obj {
	nam = [[ананас]];
	tak = function()
		if not have(card) and not girl.isOk then
			take(card);
			p [[На полке с ананасами я нашёл карточку.]];
		else
			p [[Не люблю ананасы.]];
		end;
		return false;
	end;
	dsc = [[{Ананас} (1 шт. за 114 руб.).^]];
};

card = obj {
	nam = [[карта]];
	inv = [[Можно, конечно, оставить её себе, но лучше вернуть владельцу.]];
};

girl = obj {
	nam = [[девушка]];
	var {
		isOk = false;		-- Девушка удовлетворена? Да/Нет. true/false.
	};
	act = [[Пересилив свою природную скромность, я подошёл к девушке.^
			-- Привет. Почему ты грустишь?^
			-- А тебе-то что?^
			-- Ну, может, я могу помочь.^
			-- Ну... Может и можешь. Я потеряла свою карточку. Поможешь мне её найти?^
			-- А где она может быть?^
			-- Где-то здесь.]];
	used = function (s, w)
		if w == card then
			remove(card, me());
			s.isOk = true;
			phoneDlg:poff('mih1');
			phoneDlg:pon('mih2');
			disable(girl);
			p [[-- Это твоя карточка?^
				-- Да! Спасибо! Я так тебе благодарна!^
				-- А какие у тебя планы на вечер?^
				-- На вечер? Хм... Никаких вроде.^
				-- У меня сегодня планируется чаепитие с пирогами. Придёшь?^
				-- Ну как-то это странно, конечно... Ну ладно. Приду.^
				-- Тогда до вечера.^
				-- До вечера.]];
		end;
	end;
	dsc = [[Возле кассы грустит {девушка}.]];
};

cash = obj {
	nam = [[касса]];
	act = function()
		if basket.price == 0 then
			p [[Дык я ничего и не взял же.]];
		else
			p ('-- С Вас n-дцать рублей!^-- Сколько-сколько?^-- Глухой что ли?! ' .. basket.price .. '!');
		end;
	end;
	used = function (s, w)
		if w == money then
			p [[Я протянул кассирше деньги -- та скривилась в ответ.^]];
			if basket.price > money.count then
				p ('-- Ну и чего ты мне тут суёшь?! Где ещё ' .. (basket.price - money.count) .. ' ?!^-- Но у меня нет больше.^-- А чего тогда набирал-то, если денег нет?!^^');
				p [[С этими словами, кассирша отобрала у меня корзинку со всем добром и пошла раскладывать всё обратно.]];
				remove(basket, me());
				if have(flour) then
					drop(flour);
				end;
				if have(baking_powder) then
					drop(baking_powder);
				end;
				if have(cinnamon) then
					drop(cinnamon);
				end;
				if have(sugar) then
					drop(sugar);
				end;
				if have(milk) then
					drop(milk);
				end;
				if have(egg) then
					drop(egg);
				end;
				if have(butter_discount) then
					drop(butter_discount);
				end;
				if have(butter) then
					drop(butter);
				end;
				if have(apples_discount) then
					drop(apples_discount);
				end;
				if have(apples) then
					drop(apples);
				end;
				take(cash);
				drop(cash);
				basket.price = 0;
			elseif basket.price <= money.count then
				p [[-- Вот Ваша сдача. Спасибо за покупку.]];
				remove(basket, me());
				money.count = money.count - basket.price;
				basket.price = 0;
			end;
		end;
	end;
	dsc = [[^^Идти на {кассу}.]];
};

apples = obj {
	nam = [[яблоки]];
	tak = function()
		if have(basket) then
			p [[Я взял яблоки.]];
			basket.price = basket.price + 17;
		else
			p [[Я не могу взять яблоки -- мне некуда их положить.]];
			return false;
		end;
	end;
	dsc = [[{Яблоки} (2 шт. за 17 руб.).^]];
};

piece_apples = obj {
	nam = [[резанные яблоки]];
	inv = [[Аккуратно порезанные яблоки.]];
};

apples_discount = obj {
	nam = [[яблоки со скидкой]];
	tak = function()
		if have(basket) then
			p [[Яблоки. Да еще и со скидкой. Конечно, берём!]];
			basket.price = basket.price + 7;
		else
			p [[Я не могу взять яблоки -- мне некуда их положить.]];
			return false;
		end;
	end;
	used = function (s, w)
		if w == knife and have(dart_board) and here()==kitchen then
			remove(apples_discount, me());
			take(piece_apples);
			p [[Я порезал на доске яблоки.]];
		end;
		if w == knife and have(dart_board) and here()~=kitchen then
			p [[Лучше это делать на кухне.]];
		end;
		if w == knife and not have(dart_board) then
			p [[Порезать яблоки нужно. Но на чём?]];
		end;
		if w ~= knife then
			p [[И что? И как? А самое главное -- зачем?]];
		end;
	end;
	dsc = [[{Яблоки со скидкой} (2 шт. за 7 руб.).^]];
};

butter = obj {
	nam = [[масло]];
	tak = function()
		if have(basket) then
			p [[Я взял масло.]];
			basket.price = basket.price + 25;
		else
			p [[Я не могу взять масло -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Масло} (Упаковка за 25 руб.).^]];
};

piece_butter = obj {
	nam = [[кусок масла]];
	inv = [[Кусок сливочного масла. Примерно на 85 грамм.]];
};

costume = obj {
	nam = [[костюм]];
	act = function()
		if tasks.VasyaOk and tasks.PetyaOk and tasks.MishaOk and tasks.pieOk then
			walk('epilog');
		else
			p [[Пока ещё рано одевать костюм. Сначала нужно испечь пирог и пригласить всех друзей.]];
		end;
	end;
	dsc = [[На дверке шкафа висит мой парадно-выходной {костюм}.]];
}: disable();

oven = obj {
	nam = [[духовка]];
	used = function (s, w)
		if w == little_dish and pie.mix then
			remove(little_dish, me());
			tasks.pieOk = true;
			p [[Поставим теперь всё это в духовку и, можно сказать, что пирог готов!]];
		end;
	end;
	act = [[Полезная штука. Особенно, если умеешь готовить.]];
	dsc = [[Ну и, конечно, {духовка} тоже здесь. Куда же без неё.]];
};

aquarium = obj {
	nam = [[аквариум]];
	act = function()
		if have(drill) then
			p [[Аквариум совершенно пуст. Абсолютно.]];
		else
			enable(drill);
			p [[В аквариуме нет воды. Зато там лежит дрель.]];
		end;
	end;
	dsc = [[В уголке красуется {аквариум}.]];
};

drill = obj {
	nam = [[дрель]];
	var {
		isUse = false;
	};
	inv = function(s)
		if s.isUse then
			p [[Я включил дрель. Та  сказала "Вжжж!". Я выключил дрель.]];
		else
			s.isUse = true;
			p [[Я переключил дрель на низкие обороты.]];
		end;
	end;
	tak = [[Я взял дрель.]];
	dsc = [[Внутри лежит {дрель}.]];
}: disable();

little_dish = obj {
	nam = [[маленькая миска]];
	var {
		isUse = false;
	};
	used = function (s, w)
		if w == butter_discount then
			p [[Этот кусок масла слишком большой.]];
		end;
		if w == piece_butter then
			remove(piece_butter, me());
			pie.piece_butter = true;
			p [[Я положил кусочек масла в миску.]];
		end;
		if w == sugar then
			remove(sugar, me());
			pie.sugar = true;
			p [[Я положил сахар в миску.]];
		end;
		if w == drill and drill.isUse then
			if pie.piece_butter and pie.sugar then
				remove(drill, me());
				pie.use_drill = true;
				p [[Я взбил дрелью масло с сахаром.]];
			else
				p [[А что, собственно, будет взбивать?]];
			end;
		end;
		if w == drill and not drill.isUse then
			p [[Дрель слишком мощная.]];
		end;
		if w == egg2 and pie.egg1 then
			remove(egg2, me());
			pie.egg2 = true;
			p [[Я хотел разбить яйцо в миску и сделал это.]];
		end;
		if w == egg and not pie.egg1 then
			remove(egg, me());
			pie.egg1 = true;
			p [[Я хотел разбить яйцо в миску, но оно выскользнуло у меня из рук, упало на пол  и разбилось.]];
		end;
		if w == milk and pie.egg2 then
			remove(milk, me());
			pie.milk = true;
			p [[Я добавил молоко в миску.]];
		end;
		if w == big_dish and pie.milk then
			remove(big_dish, me());
			pie.mix = true;
			p [[Я выкинул содержимое одной миски в другую.]];
		end;
		if w == piece_apples and pie.mix then
			pie.apples = true;
			remove(piece_apples, me());
			p [[Я красиво выложил яблоки.]];
		end;
	end;
	act = function(s)
		if pie.apples then
			take(little_dish);
			p [[Я взял миску.]];
		end;
		if s.isUse then
			p [[Миска как миска. Только маленькая.]];
		else
			s.isUse = true;
			p [[Я взял миску с полки и переставил её на стол.]];
		end;
	end;
	dsc = function(s)
		if s.isUse then
			p [[На столе стоит {маленькая миска}.]];
		else
			p [[На нижней полке лежит {маленькая миска}.]];
		end;
	end;
};

big_dish = obj {
	nam = [[большая миска]];
	var {
		isUse = false;
	};
	used = function (s, w)
		if w == flour then
			remove(flour, me());
			pie.flour = true;
			p [[Я высыпал муку в миску.]];
		end;
		if w == cinnamon then
			remove(cinnamon, me());
			pie.cinnamon = true;
			p [[Я высыпал корицу в миску.]];
		end;
		if w == baking_powder then
			remove(baking_powder, me());
			pie.baking_powder = true;
			p [[Я высыпал разрыхлитель в миску.]];
		end;
	end;
	act = function(s)
		if s.isUse then
			p [[Миска как миска. Только большая.]];
			if pie.flour and pie.cinnamon and pie.baking_powder then
				take(big_dish);
			end;
		else
			s.isUse = true;
			p [[Я взял миску с полки и переставил её на стол.]];
		end;
	end;
	dsc = function(s)
		if s.isUse then
			p [[На столе стоит {большая миска}.]];
		else
			p [[На верхней полке лежит {большая миска}.]];
		end;
	end;
};

butter_discount = obj {
	nam = [[масло со скидкой]];
	tak = function()
		if have(basket) then
			p [[Масло. Да еще и со скидкой. Конечно, берём!]];
			basket.price = basket.price + 15;
		else
			p [[Я не могу взять масло -- мне некуда его положить.]];
			return false;
		end;
	end;
	used = function (s, w)
		if w == roulette then
			remove(roulette, me());
			remove(butter_discount,me());
			take(piece_butter);
			p [[Я отмерил рулеткой половину сливочного масла. Теперь у меня есть кусочек как раз на 85 грамм.]];
		end;
	end;
	inv = [[Пачка сливочного масла. 170 грамм.]];
	dsc = [[{Масло со скидкой} (Упаковка за 15 руб.).^]];
};

egg = obj {
	nam = [[яйцо]];
	tak = function()
		if have(basket) then
			p [[Полезная штука.]];
			basket.price = basket.price + 6;
		else
			p [[Я не могу взять яйцо -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Яйцо} (1 шт. за 6 руб.).^]];
};

egg2 = obj {
	nam = [[яйцо]];
	tak = function()
		if have(basket) then
			p [[Полезная штука.]];
			basket.price = basket.price + 6;
		else
			p [[Я не могу взять яйцо -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Яйцо} (1 шт. за 6 руб.).^]];
}: disable();

milk = obj {
	nam = [[молоко]];
	tak = function()
		if have(basket) then
			p [[Пейте, дети, молоко!]];
			basket.price = basket.price + 10;
		else
			p [[Я не могу взять молоко -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Молоко} (ёмкость за 10 руб.).^]];
};


sugar = obj {
	nam = [[сахар]];
	tak = function()
		if have(basket) then
			p [[Сахарку надо бы взять.]];
			basket.price = basket.price + 20;
		else
			p [[Я не могу взять сахар -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Сахар} (кулёк за 20 руб.).^]];
};

cinnamon = obj {
	nam = [[корица]];
	tak = function()
		if have(basket) then
			p [[Прихватим.]];
			basket.price = basket.price + 2;
		else
			p [[Я не могу взять корицу -- мне некуда ее положить.]];
			return false;
		end;
	end;
	dsc = [[{Корица} (пачка за 2 руб.).^]];
};

baking_powder = obj {
	nam = [[разрыхлитель]];
	tak = function()
		if have(basket) then
			p [[Возьму.]];
			basket.price = basket.price + 2;
		else
			p [[Я не могу взять разрыхлитель -- мне некуда его положить.]];
			return false;
		end;
	end;
	dsc = [[{Разрыхлитель} (пачка за 2 руб.).^]];
};

flour = obj {
	nam = [[мука]];
	tak = function()
		if have(basket) then
			p [[Мука точно пригодится.]];
			basket.price = basket.price + 30;
		else
			p [[Я не могу взять муку -- мне некуда ее положить.]];
			return false;
		end;
	end;
	dsc = [[{Мука} (180 г. за 30 руб.).^]];
};

baskets = obj {
	nam = [[корзинки]];
	act = function()
		if not have(basket) then
			take(basket);
			p [[Я взял одну.]];
		else
			p [[У меня уже есть корзинка. Зачем мне еще?]];
		end;
	end;
	dsc = [[У входа навалены {корзинки} для продуктов.^^]];
};

basket = obj {
	nam = [[корзина]];
	var {
		price = 0;		-- Цена продуктов в корзине.
	};
	inv = [[Железная корзинка для продуктов.]];
};

chair = obj {
	nam = [[стул]];
	var {
		isUse = true;		-- Можно ли использовать и переносить стул. Да/Нет. true/false.
	};
	tak = function(s)
		if s.isUse then
			p [[Я взял стул. Вещь хорошая -- в хозяйстве пригодится.]];
		else
			p [[Этот стул, конечно, хороший, но пока он мне не нужен.]];
			return false;
		end;
	end;
	dsc = [[Тут же стоит добротный деревянный {стул}.]];
};

cupboard = obj {
	nam = [[шкаф]];
	act = function()
		if disabled(phone) then
			p [[Я открыл дверцы шкафа. Сколько же тут всякого полезного добра!]];
			enable(phone);
			enable(book);
			enable(instruments);
			enable(costume);
		else
			p [[В этом шкафу, наверное, поместилось бы человек 5. Еще и место бы осталось.]];
		end;
	end;
	dsc = [[Огромный {шкаф} занимает полкомнаты.]];
};

bed = obj {
	nam = [[кровать]];
	act = function()
		if have(money) then
			p [[Надо будет к вечеру прибраться тут.]];
		else
			take(money);
			p [[Порывшись в залежах подушек, я нашел деньги.]];
		end;
	end;
	dsc = [[Посередине -- вечно незаправленная {кровать}.]];
};

bike = obj {
	nam = [[велосипед]];
	var {
		isOk = false;		-- Починен ли велосипед? Да/Нет. true/false.
	};
	act = function(s)
		if s.isOk then
			p [[Отличный транспорт! Дёшево и сердито. Да и для здоровья полезно. Особенно полезно каждый раз таскать его домой на пятый этаж.]];
		else
			p [[В этой конструкции явно чего-то не хватает. Как минимум, переднего колеса.]];
		end;
	end;
	used = function (s, w)
		if w == wheel and have(instruments) then
			p [[Я прикрутил колесо к велосипеду.]];
			remove(wheel, me());
			s.isOk = true;
		elseif w == wheel then
			p [[Это колесо от велосипеда, но как же его вернуть на место?]];
		end;
	end;
	dsc = [[К стене прислонен {велосипед}.]];
};

instruments = obj {
	nam = [[инструменты]];
	inv = [[Ключи, отвертки и прочий металлолом.]];
	tak = [[Возьму, пожалуй.]];
	dsc = [[Рядом с телефоном лежат разные {инструменты}.]];
}: disable();

wheel = obj {
	nam = [[колесо от велосипеда]];
	inv = [[Отличное такое колесо. И зачем я его снял?]];
};

knife = obj {
	nam = [[нож]];
	inv = [[Большой такой ножичек.]];
};

darts = obj {
	nam = [[дротики]];
	inv = [[Маленькие и острые.]];
	used = function (s, w)
		if w == instruments then
			take(darts);
			p [[Я нашёл в инструментах маленький карманный гвоздодёр и вытащил им дротики из доски.]];
		end;
	end;
	act = [[Дротики застряли в доске основательно. Голыми руками их не вытащить.]];
	dsc = [[Несколько {дротиков} воткнуты в неё.]];
}: disable();

dart_board = obj {
	nam = [[доска для дротиков]];
	tak = function()
		if have(darts) then
			p [[Я снял доску со стены. Да это же моя кухонная разделочная доска! А я её искал.]];
		else
			if disabled(darts) then
				enable(darts);
				p [[В доске торчат дротики.]];
				return false;
			else
				p [[Надо как-то вытащить дротики.]];
				return false;
			end;
		end;
	end;
	dsc = [[На стене у двери висит {доска для дротиков}.]];
};

fridge = obj {
	nam = [[холодильник]];
	act = function()
		if not bike.isOk and not have(wheel) then
			take(wheel);
			p [[Порывшись в закромах Родины за холодильником, я обнаружил колесо от велосипеда.]];
		else
			if pie.milk and not have(knife) then
				take(knife);
				p [[Я достал из холодильника нож.]];
			end;
			if pie.milk and have(knife) then
				p [[Хороший холодильник. Морозит как зверь!]];
			end;
			if not pie.milk then
				p [[В холодильнике, как ни странно, лежит нож, но он мне пока не нужен.]];
			end;
		end;
	end;
	dsc = [[Мерно гудит {холодильник}.]];
};

money = obj {
	nam = [[деньги]];
	var {
		count = 100;
	};
	inv = function(s)
		p ('Помятые бумажки. Всего на ' .. s.count .. ' рублей.');
	end;
};

paper = obj {
	nam = [[бумажка с письменами]];
	inv = [[На этой бумажке нарисованы номера телефонов моих друзей. Фух. Ну и подчерк у меня -- хоть во врачи иди.]];
};

airplane = obj {
	nam = [[бумажный самолетик]];
	tak = function()
		if have(chair) then
			p [[Я встал на стул и взял с люстры самолетик.]];
			drop(chair);
			chair.isUse = false;
		else
			p [[Люстра слишком высоко -- я, пожалуй, не допрыгну.]];
			return false;
		end;
	end;
	inv = function()
		remove(airplane, me());
		take(paper);
		p [[Скрепя сердце, я развернул самолетик. Теперь вместо превосходного летательного аппарата осталась только бумажка с какими-то письменами.]];
	end;
	dsc = [[В люстре застрял {бумажный самолетик}.]];
}: disable();

chandelier = obj {
	nam = [[люстра]];
	act = function()
		if disabled(airplane) then
			p [[Внимательно осмотрев люстру, я обнаружил застрявший в ней бумажный самолетик.]];
			enable(airplane);
		else
			p [[Несмотря на то, что люстра расчитана аж на шесть лампочек, горит только одна из них. Видимо, тут есть какая-то хитрая философия.]];
		end;
	end;
	dsc = [[На потолке -- {люстра} в стиле "китайский арт-хаус".]];
};

phone = obj {
	nam = [[телефон]];
	act = [[Обычный домашний телефон. С его помощью можно позвонить друзьям.]];
	dsc = [[На нижней полке шкафа вольготно устроился {телефон}.]];
	used = function (s, w)
		if w == paper then
			walk('phoneDlg');
		end;
	end;
}: disable();

book = obj {
	nam = [[книга]];
	act = [[Это книга с рецептами. Интересно, откуда она у меня?^
		Посмотрим... для пирога нам понадобятся: мука 180 г., разрыхлитель 1,5 ч.л., корица - 1/2 ч.л., сливочное масло - 85 г., сахар - 175 г., яйцо - 1 шт., молоко - 120 г., яблоки - 2 шт.^^
		Что надо делать... Хм... Так... В одной чашке соедините муку (180 г), корицу (1/2 ч.л.) и разрыхлитель (1,5 ч.л.). Всё это нужно хорошо перемешать... Ну допустим. В другой чашке смешиваем сливочное масло (85 г) и сахар (175 г). Так... Хорошо взбиваем миксером на высокой скорости... Ага. Где ж я вам миксер-то возьму, интересно? Добавляем одно яйцо и ещё немного взбиваем массу, следом молоко (120 г). Потом все это смешиваем... Угу. ...самое время нарезать яблоки. Ага. ...и в духовку. Ну вроде ничего сложного.]];
	dsc = [[На верхней полке пылится увесистая {книга}.]];
}: disable();

microwave = obj {
	nam = [[микроволновка]];
	act = function()
		if have(roulette) then
			p [[Микроволновая печь. Одна штука.]];
		else
			p [[Я открыл дверку микроволновки и, с удивлением, обнаружил там рулетку.]];
			enable(roulette);
		end;
	end;
	dsc = [[На подоконнике скромно стоит {микроволновка}.]];
};


-------------
-- Диалоги --
-------------

phoneDlg = dlg {
	nam = 'телефон';
	hideinv = true;
	phr = {
		{'Позвонить Васе.',
			[[-- Привет, Василий!^
			-- О. Здарова!^
			-- Слушай чего. Приходи сегодня вечером на пироги.^
			-- Ух ты. А что за повод?^
			-- Да в отпуск я собрался.^
			-- Ну это дело хорошее! Приду, конечно. Только я Машку захвачу, хорошо?^
			-- Конечно. Жду вас тогда вечерком.^
			-- Ага. Ну давай.
			]];
			code = [[tasks.VasyaOk = true;]];
		},
		{'Позвонить Пете.',
			[[-- Петр, ты что ли? Привет.^
			-- Я. Кто же еще?^
			-- Какие планы на вечер?^
			-- Пока никаких. А что? Есть предложения?^
			-- В отпуск я... Ну пироги там... И все такое.^
			-- А. Понял. Хорошо. Обязательно буду.^
			-- И супругу захвати.^
			-- Зачем? Ну, в смысле, ладно. Придем тогда. Жди.
			]];
			code = [[tasks.PetyaOk = true;]];
		},
		{always = true, tag = 'mih1', 'Позвонить Мише.',
			[[-- Мишань, привет!^
			-- Привет.^
			-- Зайдешь вечерком?^
			-- Угу. Есть повод? А, впрочем, давненько не виделись. Забегу.^
			-- Только все с подругами собираются...^
			-- Хм. С этим трудно -- нет у меня подруги-то.^
			-- Ну возьми кого-нибудь.^
			-- Говорю же -- нету никого.^
			-- Ну ладно. Ты подумай пока. Если что -- перезвоню.^
			-- Хорошо.
			]];
		},
		{false, tag = 'mih2', 'Позвонить Мише.',
			[[-- Мишань, привет!^
			-- Привет.^
			-- Я тебе девушку нашёл на вечер.^
			-- О как! Спасибо! Тогда вечером жди -- приду.
			]];
			code = [[tasks.MishaOk = true;]];
		},
		{always = true, 'Позвонить позже.',
			code = [[ 
				back();
			]];
		},
	};
};