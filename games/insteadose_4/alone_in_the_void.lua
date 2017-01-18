--$Name: Один в пустоте$
--$Version: 0.9$
--$Author: Андрей Лобанов$

instead_version '2.4.0'

require 'hideinv'
require 'dash'
require 'para'
require 'quotes'
require 'nouse'

global {
   pass = false,
   remember = false,
}

main = room {
   nam = 'ОДИН В ПУСТОТЕ',
   dsc = 'Сначала вселенной не было. Во всяком случае для меня. Для объективной же действительности вселенная существовала уже не первую сотню миллиардов лет и никуда пропадать не собиралась. Спустя какое-то время на месте этой пустоты стали появляться цветные вспышки, но я никак не мог уловить их предназначение. Позже к ним добавился отвратительный звук, ввинчивающийся в мою голову с неотвратимостью дрели.^Осознание того факта, что у меня есть голова привело к целой лавине мыслей и воспоминаний, которые и вытянули меня из небытия в не самую приятную, но всё таки реальность.^Когда я открыл глаза, то обнаружил себя пристёгнутым к креслу пилота. Попытки вспомнить кто я такой и где нахожусь, как называется мой корабль и почему так надрывно воет сирена ни к чему не привели. Поэтому я решил действовать.',
   enter = function()
      set_music('music/lastfl.xm')
   end,
   act = function()
      walk 'control_room'
   end,
   obj = {
      vobj('start', '{Далее}'),
   },
}

control_room = room {
   var {
      wearing = true,
      try = false,
   },
   nam = 'кабина корабля',
   dsc = 'Я нахожусь в кабине космического корабля, но я совершенно не помню как он называется и куда летит. Часть светильников не горит и потому здесь царит полумрак.',
   exit = function(s, w)
      if s.wearing then
	 p 'Встать с кресла мне мешают ремни, которыми я крепко пристёгнут к креслу.'
	 return false
      elseif door.locked then
	 if not s.try then
	    p 'Дверь, ведущая наружу оказалась закрыта.'
	    s.try = true
	    panel.try = true
	    place(door, s)
	 else
	    p 'Дверь закрыта.'
	 end
	 return false
      end
   end,
   obj = {
      obj {
	 var {
	    seen = false,
	    cutted = false,
	 },
	 nam = 'кресло',
	 dsc = 'Я сижу в {кресле} пилота.',
	 act = function(s)
	    if not s.seen then
	       s.seen = true
	       place(armrest, s)
	       return 'В подлокотнике я заметил встроенный контейнер.'
	    else
	       return 'Стандартное кресло пилота, какое можно встретить почти на любом корабле.'
	    end
	 end,
	 used = function(s, w)
	    if w == plasma_cutter then
	       if not s.cutted then
		  s.cutted = true
		  plasma_cutter.energy = false
		  take(sharp_piece)
		  return 'Я отрезал от кресла кусок металла. В последний момент мне удалось его ухватить и не дать упасть за пределы досягаемости.'
	       end
	    end
	 end,
	 obj = {
	    obj {
	       nam = 'ремни',
	       dsc = 'В нём меня крепко удерживают {ремни} безопасности.',
	       act = 'Я подёргал застёжку, но она не поддаётся. Похоже, её заело.',
	       used = function(s, w)
		  if w == plasma_cutter and plasma_cutter.energy then
		     return 'Я наверняка прожгу вместе с ремнём и себя.'
		  elseif w == sharp_piece then
		     control_room.wearing = false
		     w:disable()
		     s:disable()
		     deck:enable()
		     return 'Не без усилий, но я смог перерезать крепкое полимерное полотно ремня.'
		  end
	       end,
	    },
	 },
      },
      'panel',
      obj {
	 var {
	    seen = false,
	    try = false,
	    view = false
	 },
	 nam = 'сенсор',
	 dsc = function(s)
	    if not s.seen then
	       s.seen = true
	       return 'Чуть выше неё я заметил {сенсор} бортового компьютера.'
	    else
	       return 'Чуть выше неё находится {сенсор} бортового компьютера.'
	    end
	 end,
	 act = function(s)
	    if not pass then
	       if not s.try then
		  s.try = true
		  return 'Я активировал сенсор, но компьютер запрашивает авторизацию. К сожалению, я не помню пароль.'
	       else
		  return 'Я не помню пароль доступа к бортовому компьютеру, так что сенсор для меня бесполезен.'
	       end
	    else
	       if door.locked then
		  door.locked = false
		  return 'Я смог авторизоваться в системе бортового компьютера и разблокировать дверь.'
	       else
		  return 'Я попробовал поискать какие-либо записи, которые помогли бы мне разобраться в ситуации, но по какой-то причине их не оказалось в компьютере.'
	       end
	    end
	 end,
      },
   },
   way = { 'deck' },
}

armrest = obj {
   var {
      seen = false,
   },
   nam = 'подлокотник',
   dsc = 'В подлокотнике кресла есть {крышка} встроенного контейнера.',
   act = function(s)
      if not s.seen then
	 s.seen = true
	 place(plasma_cutter, s)
	 return 'Я открыл крышку. Внутри обнаружился плазменный резак.'
      else
	 if where(plasma_cutter) == s then
	    return 'Небольшой контейнер.'
	 else
	    return 'Контейнер пуст.'
	 end
      end
   end,
}

plasma_cutter = obj {
   var {
      energy = true,
   },
   nam = 'резак',
   dsc = 'В нём лежит плазменный {резак}.',
   tak = 'Я взял резак.',
   inv = function(s)
      if s.energy then
	 return 'Уровень заряда почти на нуле.'
      else
	 return 'Резак полностью разряжен.'
      end
   end,
   use = function(s, w)
      if not s.energy and not nameof(name) == 'панель' then
	 return 'Резак разряжен и совершенно бесполезен.'
      end
   end,
   nouse = 'Стоит поберечь заряд в резаке.',
}

sharp_piece = obj {
   nam = 'острый обрезок',
   inv = 'Кусок металла срезанный с кресла пилота. Одна кромка получилась достаточно острой.',
   nouse = 'Не получается.',
}

panel = obj {
   var {
      try = false,
      radio_tryed = false,
      drive_tryed = false,
   },
   nam = 'панель управления',
   dsc = function(s)
      if not where(door) then
	 return 'Передо мной находится {панель управления}.'
      else
	 return 'Перед креслом находится {панель управления}.'
      end
   end,
   act = function(s)
      if door.locked then
	 if not s.try then
	    s.try = true
	    return 'Я силюсь вспомнить за что отвечают все эти многочисленные кнопки и рычажки, но в процессе голову мою пронзает острая боль. Так что я откладываю эти попытки до лучших времён.'
	 elseif door.seen then
	    return 'Судя по показаниям приборов, давление в ближайшей секции палубы в норме. А вот дальше явно нет атмосферы. Значит из комнаты управления я всё таки могу попытаться выбраться.'
	 else
	    return 'Можно попробовать нажать что-нибудь наугад, но мне совершенно не хочется наблюдать к каким последствиям это приведёт.'
	 end
      else
	 if not remember then
	    v = ''
	    if not s.view then
	       s.view = true
	       v = v .. 'Я включил обзорный экран и радар.^'
	    end
	    v = v .. 'На обзорном экране ничего толком не видно. Разве что в отдалении яркой искрой блестит станция. При увеличении видно, что она находится в плачевном состоянии -- её корпус практически расколот надвое, но детали рассмотреть не удаётся. Судя по показаниям радаров рядом находится ещё один корабль, но внешний сенсор по левому борту повреждён и увидеть его не удаётся.'
	    return v
	 else
	    if not s.radio_tryed then
	       s.radio_tryed = true
	       return "Как бы там ни было, а удар током пошёл мне на пользу. Не задумываясь, я нажал несколько клавиш на панели, ухватил манипулятор радиостанции и попытался связаться хоть с кем-нибудь. В эфире была тишина. Молчала станция сбора ресурсов, молчали мои коллеги-старатели, молчали вообще все. Я провёл перед радиостанцией около получаса, но на всех каналах ответом мне был только треск помех."
	    else
	       if not s.drive_tryed then
		  s.drive_tryed = true
		  return "Я попробовал запустить двигатели, но у меня ничего не получилось. Похоже, мой корабль не отделался небольшой пробоиной и повреждения носят более глобальный характер."
	       else
		  if not communications.fixed then
		     return "Рация молчит, двигатели не управляются. Панель полностью бесполезна."
		  else
		     if not engine_panel.on then
			return 'Не получится запустит двигатели пока линия управления отключена от общей цепи.'
		     else
			walk 'epilog'
		     end
		  end
	       end
	    end
	 end
      end
   end,
   obj = { 'notebook' },
}

notebook = obj {
   nam = 'блокнот',
   dsc = 'Под панелью {что-то} лежит.',
   tak = 'Это оказался блокнот.',
   inv = function(s)
      pass = true
      return 'Я пролистал блокнот. Помимо кучи малопонятных записей о некоем проекте "Ось", я обнаружил пароль к бортовому компьютеру.'
   end
}:disable()

door = obj {
   var {
      seen = false,
      locked = true,
   },
   nam = 'дверь',
   dsc = 'Напротив панели управления находится {дверь}.',
   act = function(s)
      v = ''
      if s.locked then
	 v = v .. 'Дверь заблокирована.'
      end
      if not s.seen then
	 s.seen = true
	 v = v .. ' Это означает либо что я её заблокировал самостоятельно до того как отключился, либо сработала автоматика и палуба разгерметизирована.^В смутной моей памяти чётко сформировалось знание о том, что на панели управления есть приборы, отображающие показания датчиков давления во всех отсеках корабля.'
      else
	 if s.locked then
	    v = v .. ' Для её разблокировки нужно авторизоваться в бортовом компьютере.'
	 else
	    v = v .. 'Стандартная автоматическая дверь.'
	 end
      end
      if notebook:disabled() then
	 notebook:enable()
	 v = v .. '^Я заметил, что под панелью управления что-то лежит.'
      end
      return v
   end,
}

deck = room {
   var {
      seen = true,
   },
   nam = 'палуба',
   obj = {
      obj {
	 var {
	    seen = false,
	 },
	 nam = 'перегородка',
	 dsc = 'Палуба перекрыта герметичной {перегородкой} почти у самого входа в комнату управления.',
	 act = function(s)
	    if not bay.opened then
	       v = 'Без скафандра идти дальше чистейшее самоубийство. Но взять его можно только возле шлюза.'
	       if not s.seen then
		  s.seen = true
		  v = v .. ' Остаётся загадкой, как такой нелепый проект корабля дошёл до стадии выпуска. Единственный путь к скафандрам лежит через единственный коридор, в котором нет атмосферы.'
	       end
	       return v
	    else
	       return 'Нет необходимости идти этим путём.'
	    end
	 end,
      },
      obj {
	 var {
	    seen = false,
	    opened = false,
	 },
	 nam = 'вентиляция',
	 dsc = function(s)
	    if not s.opened then
	       return 'В стене я вижу {решётку} вентиляции.'
	    else
	       return 'В стене я вижу вентиляционную {шахту}.'
	    end
	 end,
	 act = function(s)
	    if not s.seen then
	       s.seen = true
	       return 'Я прислушался, через решётку доносится звук вентилятора, гоняющего воздух по кораблю. Похоже, это шанс попасть в ещё какое-нибудь безопасное место на корабле.'
	    else
	       if not panel.drive_tryed then
		  return "Ничем не примечательная решётка, прикрывающая вентиляционную шахту."
	       else
		  if bolts:disabled() then
		     bolts:enable()
		     return 'Снять решётку не удастся -- она крепко прикручена к обшивке болтами.'
		  else
		     if not s.opened then
			if not bolts.cut_off then
			   return 'Решётка крепко прикручена к обшивке.'
			else
			   s.opened = true
			   return 'Я смог сдвинуть решётку в сторону.'
			end
		     else
			if path('шахта'):disabled() then
			   path('шахта'):enable()
			end
			return 'Пожалуй, я могу туда пролезть.'
		     end
		  end
	       end
	    end
	 end,
	 obj = { 'bolts' },
      },
      obj {
	 var {
	    opened = false,
	    charged = false,
	 },
	 nam = 'панель',
	 dsc = 'Напротив вентиляции находится распределительная {панель}.',
	 act = function(s)
	    if not s.opened then
	       s.opened = true
	       return 'Я открыл панель. Внутри проходят многочисленные кабели и провода. По ним в комнату управления подаётся энергия от реактора, передаются управляющие сигналы, разбегающиеся по всему кораблю, по тонким жгутам сбегается информация от разнообразных датчиков.'
	    else
	       s.opened = false
	       return 'Я закрыл панель.'
	    end
	 end,
	 used = function(s, w)
	    if w == plasma_cutter then
	       if not s.charged then
		  s.charged = true
		  plasma_cutter.energy = true
		  remember = true
		  return 'Сверившись со схемой, я выдернул пару проводов из контактных зажимов, которые находились под подходящем напряжением, я попытался зарядить резак. Без разъёма сделать это было крайне затруднительно, но я упорно продолжал попытки. В итоге я неловко взялся за оголённые части и меня, похоже, ударило током. "Похоже", потому что я на какое-то время отключился. Придя в себя я с удивлением обнаружил, что память ко мне вернулась. По крайней мере частично.^Меня зовут Борис Лощинин, несколько лет назад я закончил учёбу и устроился работать в самый масштабный и одновременно засекреченный проект "Ось". Я занимался всего лишь разработкой ресурсов в поясе астероидов. Эти ресурсы почти целиком шли на развитие этого проекта. Сейчас, глядя как будто со стороны, мне кажется странным, что цели такого колоссального проекта, давшего работу сотням тысяч людей, по сути остаются никому не известны. Конечно, болтают всякое и много, особенно какие-нибудь шахтёры в баре после смены, но я никогда не воспринимал их откровения всерьёз.^Помимо этих сумбурных мыслей, ко мне пришла и вполне конструктивная идея вернуться к панели управления и попытаться связаться со станцией. За одно проверить двигатели.'
	       else
		  return 'Пожалуй не стоит повторять свой неудачный опыт зарядки резака от чего попало.'
	       end
	    end
	 end,
      },
      'pipe',
   },
   way = { 'control_room', vroom('шахта', 'engine_bay'):disable() },
}:disable()

bolts = obj {
   var {
      cut_off = false,
   },
   nam = 'болты',
   dsc = function(s)
      if not s.cut_off then
	 return 'Её крепко держат два {болта}.'
      else
	 return 'Её держит только один {болт}.'
      end
   end,
   act = function(s)
      if not s.cut_off then
	 return 'Я не смогу их открутить голыми руками.'
      else
	 return 'У меня не хватает сил открутить его.'
      end
   end,
   used = function(s, w)
      if w == plasma_cutter and w.energy then
	 w.energy = false
	 s.cut_off = true
	 return 'Я смог срезать один болт. На второй мне не хватило заряда в резаке.'
      end
   end,
}:disable()

pipe = obj {
   nam = 'труба',
   dsc = 'Рядом с ней находятся трубы с кабелями. {Одна} из них лопнула по шву и порвала идущие по ней провода.',
   tak = function()
      if bay.try then
	 place(wire, deck)
	 return 'Я ухватился за свободный конец трубы и потянул её на себя...^Спустя некоторое время шатания трубы, второй шов, находящийся у пола, лопнул и в моих руках оказался кусок трубы длиной чуть больше метра.'
      else
	 p 'Судя по всему, повреждены кабели освещения. Это объясняет полумрак в комнате управления.'
	 return false
      end
   end,
   use = function(s, w)
      if w == bay then
	 if not w.opened then
	    w.opened = true
	    place(bay_door, engine_bay)
	    return 'Используя трубу как рычаг, я смог сдвинуть дверь достаточно, чтобы попасть в отсек со скафандрами.'
	 end
      end
   end,
   nouse = 'Труба здесь не поможет.',
}

wire = obj {
   nam = 'провода',
   dsc = 'На полу лежат {провода}, вырванные вместе с трубой.',
   tak = 'Я взял провода.',
   nouse = 'Бессмысленно.',
}

engine_bay = room {
   var {
      seen = false,
   },
   nam = 'Двигательный отсек',
   dsc = function(s)
      if from() == deck then
	 v = 'Кое как проползши по узкой вентиляционной шахте, я смог выбраться в двигательный отсек.'
	 if not s.seen then
	    s.seen = true
	    v = v .. ' Изнутри мне удалось выбить решётку ногой, хотя и пришлось возвращаться к развилке чтобы развернуться.'
	 end
	 return v
      else
	 return 'Я нахожусь в тесном помещении двигательного отсека.'
      end
   end,
   exit = function(s, w)
      if w == deck then
	 if space_suit.weared then
	    p 'В скафандре я не могу пролезть в вентиляционную шахту.'
	    return false
	 end
      end
   end,
   obj = { 'engine_panel', 'bay' },
   way = { vroom('шахта', 'deck'), 'vacuum_deck' },
}

engine_panel = obj {
   var {
      seen = false,
      on = true,
   },
   nam = 'панель контроля двигателей',
   dsc = '{Панель} контроля работы двигателей занимает добрую половину этого тесного помещения.',
   act = function(s)
      if not s.seen then
	 s.seen = true
	 return 'Судя по показаниям датчиков, двигатели не в лучшем состоянии, но худо-бедно на них летать можно. Но из комнаты управления я ими управлять не могу совсем. Значит повреждены коммуникации.'
      else
	 if s.on then
	    s.on = false
	    return 'Я отключил линию управления двигателями от общей цепи.'
	 else
	    s.on = true
	    return 'Я включил линию управления двигателями в общую цепь.'
	 end
      end
   end,
}

bay = obj {
   var {
      try = false,
      opened = false,
   },
   nam = 'отсек со скафандрами',
   dsc = 'Двигательный отсек находится возле самого шлюза и имеет свою {дверь} в отсек со скафандрами.',
   act = function(s)
      if not s.try then
	 s.try = true
	 place(space_suit, engine_bay)
	 return 'Дверь начала было открываться, но с жалобным скрипом застряла в пазах и остановилась. Через узкую щель, куда с трудом пролезла бы хотя бы моя рука, виднеются скафандры.'
      else
	 return 'Дверь приоткрыта ровно настолько, чтобы было видно содержимое соседнего отсека, но недостаточно, чтобы хотя бы просто протиснуться внутрь.'
      end
   end,
}

space_suit = obj {
   var {
      weared = false,
      checked = false,
   },
   nam = 'скафандр',
   disp = function(s)
      if s.weared then
	 return txtb('скафандр')
      else
	 return 'скафандр'
      end
   end,
   dsc = 'Через щель приоткрытой двери виден {скафандр}.',
   tak = function()
      if bay.opened then
	 return 'Я взял скафандр.'
      else
	 p 'Я не могу протащить объёмный пустолазный скафандр через узкую щель.'
	 return false
      end
   end,
   inv = function(s)
      if s.weared then
	 if vacuum_deck:disabled() then
	    if not s.checked then
	       s.checked = true
	       return 'Я проверил состояние атмосферы. Автоматика сработала отлично. Можно снимать скафандр.'
	    else
	       s.weared = false
	       s.checked = false
	       return 'Я снял скафандр.'
	    end
	 else
	    return 'Снимать скафандр сейчас было бы чистейшим безумием.'
	 end
      else
	 s.weared = true
	 return 'Я надел скафандр.'
      end
   end,
}

bay_door = obj {
   nam = 'дверь',
   dsc = 'В отсеке есть {дверь}, ведущая на палубу.',
   act = function()
      if not space_suit.weared then
	 return 'Насколько я помню показания приборов, на той части палубы нет атмосферы. Так что лучше туда не соваться.'
      else
	 if disabled(vacuum_deck) then
	    vacuum_deck:enable()
	    return 'Я открыл дверь. Воздух, выходящий из помещений корабля, подтолкнул меня к выходу. Надеюсь, автоматика сработает и подача воздуха прекратится.'
	 else
	    vacuum_deck:disable()
	    return 'Я закрыл дверь. По идее, автоматика сейчас должна диагностировать герметичность и нагнать воздух в помещения.'
	 end
      end
   end,
}

vacuum_deck = room {
   nam = 'палуба',
   dsc = 'Я вышел на разгермитезированную часть палубы.',
   obj = { 'grid', 'communications' },
   way = { 'engine_bay' },
}:disable()

grid = obj {
   var {
      opened = false,
   },
   nam = 'решётка',
   dsc = 'В полу видна {решётка}, закрывающая внутренние коммуникации корабля.',
   act = 'Решётка странным образом погнута. Похоже, та сила, которая смога так погнуть решётку, повредила кабели системы управления.',
   used = function(s, w)
      if w == pipe then
	 if not s.opened then
	    s.opened = true
	    place(communications, vacuum_deck)
	    return 'Используя обломок трубы как рычаг, я смог поднять решётку.'
	 else
	    return 'Решётка уже поднята.'
	 end
      end
   end,
}

communications = obj {
   var {
      fixed = false,
   },
   nam = 'коммуникации',
   dsc = function(s)
      if not s.fixed then
	 return 'Под решёткой находятся повреждённые {коммуникации} корабля.'
      else
	 return 'Под решёткой находятся внутренние {коммуникации} корабля.'
      end
   end,
   act = function(s)
      if not s.fixed then
	 return 'Повреждения выглядят очень странно. Это не похоже на микрометеорит или нечто подобное. Вообще не похоже ни на что, из того, что я знаю.'
      else
	 return 'Часть мне удалось подлатать банальной скруткой.'
      end
   end,
   used = function(s, w)
      if w == wire then
	 if not grid.opened then
	    return 'Я не могу починить линию через решётку.'
	 else
	    if engine_panel.on then
	       return 'Линия управления двигателями не отключена от общей цепи. Это может быть опасно.'
	    else
	       s.fixed = true
	       w:disable()
	       return 'Я починил линию управления двигателями с помощью обрывков провода. Получилось весьма плохо, но в данный момент важно хоть как-то запустить двигатели.'
	    end
	 end
      end
   end,
}

epilog = room {
   hideinv = true,
   nam = 'КОНЕЦ',
   dsc = 'Я включил двигатели. По кораблю пробежала небольшая вибрация, свидетельствующая о том, что мне удалось запустить двигатели. Со смутной надеждой на лучшее, я направил корабль в сторону станции сбора ресурсов.^Должны быть ещё выжившие...',
}
