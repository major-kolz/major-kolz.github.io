--$Name: Инстедоз 4 комнаты$
--$Version: 0.2$
--$Author: Instead-сообщество$

instead_version '2.4.1'

require 'dash'
require 'theme'

default_theme = function()
   theme.win.geom(48, 8, 500, 568)
   theme.inv.geom(620, nil, nil, nil)
   theme.gfx.bg 'theme/bg0.png'
   theme.win.color('#000000', '#b02c00', '#606060')
end

main = room {
   nam = '',
   enter = function()
      theme.win.geom(250, 50, 520, 550)
      theme.inv.geom(800, nil, nil, nil)
      theme.gfx.bg 'theme/bg1.png'
      theme.win.color('#AAAAAA', '#FFFFFF', 'gold')
   end,
   act = function(s, w)
      print(w)
      if w == 'pie' then
	 default_theme()
	 gamefile('pie.lua', true)
      elseif w == 'alone' then
	 default_theme()
	 gamefile('alone_in_the_void.lua', true)
      elseif w == 'inspection' then
	 default_theme()
	 gamefile('inspection.lua', true)
      elseif w == 'feed_cat' then
	 default_theme()
	 gamefile('feed_cat.lua', true)
      elseif w == 'bonus' then
	 walk 'bonus'
      else
	 walk 'about'
      end
   end,
   obj = {
      vobj('feed_cat', '{' .. img('pictures/0.png') .. '}'),
      vobj('inspection', '{' .. img('pictures/1.png') .. '}^'),
      vobj('alone', '{' .. img('pictures/3.png') .. '}'),
      vobj('pie', '{' .. img('pictures/2.png') .. '}^'),
      vobj('bonus', '{Дополнительные материалы} | '),
      vobj('about', '{О сборнике}'),
   },
}

bonus = room {
   nam = 'Дополнительные материалы',
   act = function(s, w)
      if w == 'cascade' then
	 default_theme()
	 gamefile('cascade.lua', true)
      else
	 back()
      end
   end,
   obj = {
      vobj('cascade', '^{Каскад} // Николай Коновалов^^Игра пришла буквально в последние часы продлённого срока, но не вписалась в условие с запретом на xact. Тем не менее, исключать игру из сборника не хотелось и вот она здесь.^^'),
      vobj('back', '{Назад}'),
   },
}

about = room {
   nam = 'О сборнике',
   dsc = '^Инстедоз -- спонтанный геймджем ориентированный на написание игр на движке INSTEAD. Проводится разными людьми в разное время и отличительной чертой имеет ограничения (по времени, объёму, используемым сценам) и объединение результатов в такие вот сборники. Исключением являлся второй инстедоз, проводимый в формате полновесного конкурса.^^Этот сборник включает в себя игры, присланные на четвёртый инстедоз, на котором были следующие ограничения: не больше четырёх игровых локаций и запрещено использование ряда модулей.^^В сборник попали следуюшие игры:^^' .. txttab('5%') .. '• "Накорми котёнка" // Валерий Очинский;^' .. txttab('5%') .. '• "Осмотр" // Valey;^' .. txttab('5%') .. '• "Один в пустоте" // Андрей Лобанов;^' .. txttab('5%') .. '• "Пирог" // Ordos.^^Не прошла по условиям, но попала в сборник одна игра:^^' .. txttab('5%') .. '• "Каскад" // Николай Коновалов',
   act = function()
      back()
   end,
   obj = { vobj('back', '{Назад}') },
}
