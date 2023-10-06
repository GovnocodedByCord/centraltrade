local fa_check, fa = pcall(require, "fAwesome6")
local mimgui_check, imgui = pcall(require, "mimgui")
local sampev = require("samp.events")
local cjson = require("cjson")
local inicfg = require("inicfg")
local ffi = require("ffi")
local effil = require("effil")
local lfs = require("lfs")
local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.UTF8 

local items_buy = u8"moonloader/config/CentralTrade/data-buy.json"
local items_sell = u8"moonloader/config/CentralTrade/data-sell.json"
local islauncher = false
local clear_stream = false
local eat_perc = 110
local stime = 0
local num_of_page = 4
local current_version = '1.0.0'
local new = imgui.new
local window = new.bool()
local search, search_sell, search_cfg_buy, search_cfg_sell, price_inp, count_inp = new.char[256](), new.char[256](), new.char[256](), new.char[256](), new.char[256](), new.char[256]()
local price_sell, count_sell = new.char[256](), new.char[256]()
local scan, scan_sell = false, false
local hovered_color = {gotobuy = imgui.ImVec4(0.1, 0.1, 0.1, 1.00), gotosell = imgui.ImVec4(0.1, 0.1, 0.1, 1.00), gotocfg_menu = imgui.ImVec4(0.1, 0.1, 0.1, 1.00), gotosettings_menu = imgui.ImVec4(0.1, 0.1, 0.1, 1.00),gotoinfo_menu = imgui.ImVec4(0.1, 0.1, 0.1, 1.00), gotochangelog_menu = imgui.ImVec4(0.1, 0.1, 0.1, 1.00)} -- не придумал лучше
local hook_sell = {nick = '', item = '', count = '', money = ''}
local hook_buy = {nick = '', item = '', count = '', money = ''}
local current_cfg = {buy = '', sell = ''}
local font, items, item_list, sell_list, item_tab = {}, {}, {}, {}, {}
local tosave = {buy = '', sell = ''}
local pos = {buy = 999, cfgmenu = 999, sell = 990, settings_menu = 999, info_menu = 999, changelog_menu = 999}
local item_v = {price = 10, count = 1}
local item_sell = {price = 10, count = 1}
local display = {buy = false, sell = false, score = 0, score_from = 0}
local buttons = {{name = 'Скупка', change_number_to = 0}, {name = 'Продажа', change_number_to = 1}, {name = 'Конфиги', change_number_to = 2}, {name = 'Настройки', change_number_to = 3}, {name = 'Changelog', change_number_to = 4}}

local color_list = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16'}
local color_selector = imgui.new['const char*'][#color_list](color_list)

local food_list = {'meat', 'fish', 'cheeps', 'meatbag'}
local food_list_command = {'/jmeat', '/jfish', '/cheeps', '/meatbag'}
local food_items = imgui.new['const char*'][#food_list](food_list)

local directIni = u8'CentralTrade/CentralTradeSettings.ini'
local ini = inicfg.load({
    cfg = {
        telegram_notification = false,
        tg_notf_market = true,
        tg_notf_kick = true,
        tg_notf_damage = true,
        telegram_chatid = '',
        telegram_token = '',
        dialog_wait = 350,
        dialog_list_wait_bool = false,
        dialog_wait_list = 150,
        auto_eat = false,
        auto_eat_percent = 25,
        auto_eat_foodid = 0,
        color_select = 0,
        auto_catcher = false,
        auto_name = 'cordgotyou',
        delete_players = false,
        clear_chat = false,
    }
}, directIni)
if not doesFileExist(u8'moonloader/config/CentralTrade/CentralTradeSettings.ini') then inicfg.save(ini, directIni) end
--
local telegram_notification_bool = new.bool(ini.cfg.telegram_notification)
local tg_notf_market_bool = new.bool(ini.cfg.tg_notf_market)
local tg_notf_kick_bool = new.bool(ini.cfg.tg_notf_kick)
local tg_notf_damage_bool = new.bool(ini.cfg.tg_notf_damage)
local telegram_chatid_bool = new.char[256](''..ini.cfg.telegram_chatid)
local telegram_token_bool = new.char[256](''..ini.cfg.telegram_token)
local dialog_wait = new.int(ini.cfg.dialog_wait)
local dialog_wait_list = new.int(ini.cfg.dialog_wait_list)
local dialog_list_wait_bool = new.bool(ini.cfg.dialog_list_wait_bool)
local auto_eat_bool = new.bool(ini.cfg.auto_eat)
local auto_eat_percent_bool = new.int(ini.cfg.auto_eat_percent)
local auto_eat_foodid = new.int(ini.cfg.auto_eat_foodid)
local color_select = new.int(ini.cfg.color_select)
local auto_catcher_bool = new.bool(ini.cfg.auto_catcher)
local auto_catcher_bool = new.bool(ini.cfg.auto_catcher)
local auto_name = new.char[256](''..ini.cfg.auto_name)
local delete_players_bool = new.bool(ini.cfg.delete_players)
local clear_chat_bool = new.bool(ini.cfg.clear_chat)
--

function main()
    while not isSampAvailable() do wait(0) end
    if not doesFileExist(u8'moonloader/config/CentralTrade') then lfs.mkdir(u8(getWorkingDirectory()..'/config/CentralTrade')) end
    if not doesFileExist(u8'moonloader/config/CentralTrade/sell-cfg') then lfs.mkdir(u8(getWorkingDirectory()..'/config/CentralTrade/sell-cfg')) end
    if not doesFileExist(u8'moonloader/config/CentralTrade/buy-cfg') then lfs.mkdir(u8(getWorkingDirectory()..'/config/CentralTrade/buy-cfg')) end
    checkUpdate()
    sampRegisterChatCommand('ctr', function()
        if fa_check and mimgui_check then
            window[0] = not window[0]
        else
            msg('{ff3535}[Error]:{ffffff} Во избежание вылетов, скрипт был выгружен, установите все зависимости.')
            thisScript():unload()
        end
    end)
    sampRegisterChatCommand('cc', function()
        if ini.cfg.clear_chat then
            local memory = require "memory"
            memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
            memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
            memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
        end
    end)
    sampRegisterChatCommand('cs', function()
        if ini.cfg.delete_players then
            clear_stream = not clear_stream
            msg(clear_stream and 'Удаление игроков в зоне стрима..' or 'Удаление игроков в зоне стрима {505050}выключено{ffffff}.')
        end
    end)
    while true do
    wait(0)
        if ini.cfg.auto_eat and sampIsLocalPlayerSpawned() then
            if not islauncher then
                _, _, eat, _ = sampTextdrawGetBoxEnabledColorAndSize(2061)
                eat = (eat - imgui.ImVec2(sampTextdrawGetPos(2061)).x) * 1.835
                if math.floor(eat) < ini.cfg.auto_eat_percent then
                    for k, v in pairs(food_list) do
                        if food_list[k] == food_list[auto_eat_foodid[0] + 1] then
                            sampSendChat(food_list_command[k])
                        end
                    end
                end
            else
                if math.floor(eat_perc) < ini.cfg.auto_eat_percent then
                    for k, v in pairs(food_list) do
                        if food_list[k] == food_list[auto_eat_foodid[0] + 1] then
                            sampSendChat(food_list_command[k])
                        end
                    end
                end
            end
        end
        if clear_stream then
            for k, v in ipairs(getAllChars()) do        
                local result, idfuckplayer = sampGetPlayerIdByCharHandle(v)        
                if result and (v ~= PLAYER_PED) then
                    local bs = raknetNewBitStream()
                    raknetBitStreamWriteInt16(bs, idfuckplayer)
                    raknetEmulRpcReceiveBitStream(163, bs)
                    raknetDeleteBitStream(bs)
                end
            end
        end
    end
end

imgui.OnFrame(function() return window[0] and not isGamePaused() end,
    function(player)
        resolutionX, resolutionY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resolutionX / 2, resolutionY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(1200, 600), imgui.Cond.Always) 
        imgui.Begin('main', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
        name()
        imgui.PushFont(font[17])
        for k, v in ipairs(buttons) do
            if imgui.Button(u8(v.name), imgui.ImVec2(234, 30)) then
                num_of_page = v.change_number_to
            end
            if k ~= 5 then
                imgui.SameLine()
            end
        end
        imgui.PopFont()
        imgui.Separator()
        if num_of_page == 0 then
            buy()
        elseif num_of_page == 1 then
            sell()
        elseif num_of_page == 2 then
            cfg_menu()
        elseif num_of_page == 3 then
            settings_menu()
        elseif num_of_page == 4 then
            changelog_menu()
        end
        imgui.End()
    end
)

function name()
    imgui.PushFont(font[17])
    imgui.CenterText("CentralTrade "..fa('STORE'))
    imgui.Separator()
    imgui.PopFont()
end

function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then os.execute("explorer " .. link) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end

function addToTable(text, arr)
    local iscopy = false
  
    for _, value in ipairs(arr) do
      if value == text then
        iscopy = true
        break
      end
    end
  
    if not iscopy then
        table.insert(arr, text)
    end
end

function addToData(text, arr)
    table.insert(arr, text)
    return true
end

function helpWithScan(pos)
    imgui.PushFont(font[20])
    imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y))
    imgui.Text(u8'Кажется, у тебя нет списка предметов.\nНажми на кнопку сканирования, оболтус.')
    imgui.PopFont()
end

function msg(text)
    sampAddChatMessage('{505050}[CentralTrade]: {ffffff}'..text, -1)
end

function writeJsonFile(data, path)
    local file = io.open(path, "w")
    if file then
        local jsonStr = cjson.encode(data)
        file:write(jsonStr)
        file:close()
        return true
    else
        return false
    end
end

function readJsonFile(path)
    local file = io.open(path, "r")
    
    if file then
        local json_str = file:read("*a")
        file:close()
        
        local data = cjson.decode(json_str)
        return data
    else
        return nil
    end
end

function removeTrash(str)
    if str:gsub('%D', '') ~= '' then
        return str:gsub('%D', '')
    else
        return '0'
    end
end

function changeExtraSim(input, max_len)
    local max_length = max_len
    if #input > max_length then
        return string.sub(input, 1, max_length - 3) .. "..."
    else
        return input
    end
end

function moneySeparator(number)
    local numberString = tostring(number)
    local length = #numberString

    if length <= 3 then
        return numberString
    end

    local result = ""
    local separator = "."
    
    for i = 1, length do
        result = result .. string.sub(numberString, i, i)
        if (length - i) % 3 == 0 and i < length then
            result = result .. separator
        end
    end

    return result
end

function checkUpdate()
    msg(getPartOfDay()..', {606060}'..sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(1)))..'{ffffff}. Скрипт загружен.')
    asyncHttpRequest('GET', 'https://raw.githubusercontent.com/GovnocodedByCord/centraltrade/main/info', nil, function(response)
        local githubInfo = decodeJson(response.text)
        if current_version == githubInfo.version then
            msg('Текущая версия - {59ff5f}'..current_version..' {ffffff}| У вас актуальная версия!')
        elseif current_version < githubInfo.version then
            msg('Текущая версия - {ffa724}'..current_version..' {ffffff}| Актуальная версия - {59ff5f}'..githubInfo.version..' {ffffff}| Обновите скрипт.')
        end
    end)
end

function getPartOfDay()
    local current_time = os.date("*t")
    local hours = current_time.hour
    if hours < 6 then
        return 'Доброй ночи'
    elseif hours < 12 then
        return 'Доброе утро'
    elseif hours < 17 then
        return 'Добрый день'
    elseif hours < 24 then
        return 'Добрый вечер'
    end
end

function string.nlower(s)
	local line_lower = string.lower(s)
	for line in s:gmatch('.') do
		if (string.byte(line) >= 192 and string.byte(line) <= 223) or string.byte(line) == 168 then
			line_lower = string.gsub(line_lower, line, string.char(string.byte(line) == 168 and string.byte(line) + 16 or string.byte(line) + 32), 1)
		end
	end
	return line_lower
end

function sampev.onServerMessage(color, text)
    if text:find('Вы купили (.+) %((%d+) шт%.%)% у игрока (.+) за %$(.+)') and (color == -1347440641) then
        hook_buy.item, hook_buy.count, hook_buy.nick, hook_buy.money = text:match('Вы купили (.+) %((%d+) шт%.%)% у игрока (.+) за %$(.+)')
        for k, v in pairs(item_list) do
            if v.name:sub(-1) == " " then
                v.name = v.name:sub(1, -2)
            end
            if v.name == hook_buy.item then
                if v.count == tonumber(hook_buy.count) then
                    item_list[k] = nil
                    if doesFileExist(current_cfg.buy..'.json') then
                        table.remove(item_list, k)
                        writeJsonFile(item_list, current_cfg.buy..'.json')
                    end
                else
                    v.count = v.count - tonumber(hook_buy.count)
                    item_list[k]['count'] = v.count
                    if doesFileExist(current_cfg.buy..'.json') then
                        writeJsonFile(item_list, current_cfg.buy..'.json')
                    end
                end
            end
        end
        if ini.cfg.telegram_notification and ini.cfg.tg_notf_market then
            sendTelegram('Тип: Покупка\n\nПредмет: '..hook_buy.item..'\nКоличество: '..hook_buy.count..'\nДеньги: '..tostring(moneySeparator(getPlayerMoney()))..'$ (-'..moneySeparator(hook_buy.money)..'$)')
        end
    end
    if text:find('(.-) купил у вас (.+) %((%d+) шт%.%)%, вы получили %$(.+) от продажи') and (color == -1347440641) then
        hook_sell.nick, hook_sell.item, hook_sell.count, hook_sell.money = text:match('(.+) купил у вас (.+) %((%d+) шт%.%)%, вы получили %$(.+) от продажи')
        local data = readJsonFile(items_sell)
        for k, v in pairs(data) do
            if v.item == hook_sell.item then
                if v.count > tonumber(hook_sell.count) then
                    v.count = v.count - tonumber(hook_sell.count)
                    data[k]['count'] = v.count
                    writeJsonFile(data, items_sell)
                elseif v.count <= tonumber(hook_sell.count) then
                    table.remove(data, k)
                    writeJsonFile(data, items_sell)
                end
                if ini.cfg.telegram_notification and ini.cfg.tg_notf_market then
                    sendTelegram('Тип: Продажа\n\nПредмет: '..hook_sell.item..'\nКоличество: '..hook_sell.count'\nДеньги: '..tostring(moneySeparator(getPlayerMoney()))..'$ (%2B'..moneySeparator(hook_sell.money)..'$)')
                end
            end
        end
        for k, v in pairs(sell_list) do
            if v.name == hook_sell.item then
                if tonumber(v.count) > tonumber(hook_sell.count) then
                    v.count = v.count - tonumber(hook_sell.count)
                    sell_list[k]['count'] = v.count
                    addToData(v[k], sell_list)
                    if doesFileExist(current_cfg.sell..'.json') then
                        writeJsonFile(sell_list, current_cfg.sell..'.json')
                    end
                elseif tonumber(v.count) <= tonumber(hook_sell.count) then
                    sell_list[k] = nil
                    if doesFileExist(current_cfg.sell..'.json') then
                        writeJsonFile(sell_list, current_cfg.sell..'.json')
                    end
                end
            end
        end
    end
    
    if text:find('Предметов не найдено!') and (display.buy or display.sell) then
        msg('{ff3535}[Error]: Произошла ошибка. Обратитесь к автору.')
        display = {buy = false, sell = false, score = 1, score_from = 1}
    end
end

local hp_before = 0
function sampev.onSetPlayerHealth(hp)
	if hp ~= hp_before and ini.cfg.tg_notf_damage and ini.cfg.telegram_notification then
		sendTelegram('Изменилось здоровье.\nТекущее значение: '..hp)
	end
	hp_before = hp
end

function onReceivePacket(id, bs)
    if id == 220 and ini.cfg.auto_eat then
        raknetBitStreamReadInt8(bs)
        if raknetBitStreamReadInt8(bs) == 17 then
            raknetBitStreamReadInt32(bs)
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs));
            local event, data = text:match('window%.executeEvent%(\'([%w.]+)\',%s*\'(.+)\'%)');
            if event == 'event.arizonahud.playerSatiety' then
                islauncher = true
                data = data:match('%[(%d+)%]')
                eat_perc = data
            end
        end
    end

    local packet_list = {
        {id = 32, desc = 'Сервер закрыл соединение.'},
        {id = 33, desc = 'Соединение потеряно.'}
    }

    if ini.cfg.tg_notf_kick and ini.cfg.telegram_notification then
        for k, v in pairs(packet_list) do
            if id == v.id then
                sendTelegram(v.desc)
            end
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if scan then
        sampSendDialogResponse(3040, 1, 2, '')
    elseif scan_sell then
        sampSendDialogResponse(3040, 1, 0, '')
    elseif (display.buy and (display.score <= display.score_from)) then
        sampSendDialogResponse(3040, 1, 3)
    elseif display.sell and (display.score <= display.score_from) then
        sampSendDialogResponse(3040, 1, 0)
    end

    if dialogId == 3040 then
        if (display.score > display.score_from) and display.sell then
            msg('Выставление товаров завершено.')
            sampSendDialogResponse(3040, 0, 0)
            lua_thread.create(function() wait(100) sampCloseCurrentDialogWithButton(0) end)
            display = {sell = false, score = 1, score_from = 1}
        elseif (display.score > display.score_from) and display.buy then
            msg('Выставление товаров завершено.')
            sampSendDialogResponse(3040, 0, 0)
            lua_thread.create(function() wait(100) sampCloseCurrentDialogWithButton(0) end)
            display = {buy = false, score = 1, score_from = 1}
        end
    end

    if dialogId == 3050 and display.sell and (display.score <= display.score_from) then
        local page1, page2 = title:match("(%d+)/(%d+)")
        local i = -1
        for n in text:gmatch('[^\r\n]+') do
            if n:find(sell_list[display.score].name:match("(%S+)"), 1, true) then
                sampSendDialogResponse(3050, 1, i)
            elseif n:find(">>>") then sampSendDialogResponse(3050, 1, i) end
            i = i + 1
        end
    end

    if (dialogId == 25672) and display.buy and (display.score <= display.score_from) then
        lua_thread.create(function()
            wait(ini.cfg.dialog_wait) 
            sampSendDialogResponse(25672, 1, 0, (item_list[display.score].name):gsub("%s*$", ""))
        end)
    end

    if (dialogId == 25673) and display.buy and (display.score <= display.score_from) then
        local i = 0
        lua_thread.create(function()
            for n in text:gmatch('[^\r\n]+') do
                if n:match("%S+%s*{.-}(.+)") == (item_list[display.score].name):gsub("%s*$", "") then
                    sampSendDialogResponse(25673, 1, i)
                elseif n:find(">>>") then sampSendDialogResponse(25673, 1, i) end
                i = i + 1
            end
        end)
    end

    if (dialogId == 3060) then
        lua_thread.create(function() wait(ini.cfg.dialog_wait)
            if display.buy and (display.score <= display.score_from) then
                if text:find("Пример") then
                    sampSendDialogResponse(3060, 1, 0, item_list[display.score].count..','..item_list[display.score].price)
                else
                    sampSendDialogResponse(3060, 1, 0, item_list[display.score].price)
                end
                display.score = display.score + 1
            end
            if display.sell and (display.score <= display.score_from) then
                if text:find("Пример") then
                    sampSendDialogResponse(3060, 1, 0, sell_list[display.score].count..','..sell_list[display.score].price)
                else
                    sampSendDialogResponse(3060, 1, 0, sell_list[display.score].price)
                end
                display.score = display.score + 1
            end
        end)
    end

    if dialogId == 3050 and scan then
        local i = 0
        local page1, page2 = title:match("(%d+)/(%d+)")
        for n in text:gmatch('[^\r\n]+') do
            lua_thread.create(function()
                if not n:find("Название") and not n:find("<<<") and not n:find(">>>") then
                    n = n:gsub("{.-}", "")
                    n = n:gsub("\t\t", '')
                    n = n:gsub("\t \t", "")
                    if n:find("%$") then
                        n = n:match("^(.-)%d*%$?$")
                    end
                    table.insert(items, n)
                end
            
                if n:find(">>>") then
                    wait(ini.cfg.dialog_list_wait_bool and ini.cfg.dialog_wait_list or 150)
                    sampSendDialogResponse(3050, 1, i-1)
                end
                i = i + 1
            end)
        end
        if page1 == page2 then
            writeJsonFile(items, items_buy)
            scan = false
            window[0] = true
            msg('Сканирование {505050}предметов {ffffff}завершено.')
            sampSendDialogResponse(3050, 0, 0)
            lua_thread.create(function() wait(100) sampCloseCurrentDialogWithButton(0) end)
        end
    elseif dialogId == 3050 and scan_sell then
        local i = 0
        for n in text:gmatch('[^\r\n]+') do
            lua_thread.create(function()
                if not n:find(">>>") and not n:find("<<<") then
                    local item, ic = n:match("%{777777%}(.+)%s%{777777%}(.+)%s%{B6B425%}")
                    if item ~= "Название" and item ~= nil and ic ~= ' ' and ic ~= '1 шт.' then
                        itemc = ic:match('(%d+)%sшт.')
                        data = {item = item, count = tonumber(itemc)}
                    elseif item ~= "Название" and item ~= nil and (ic == ' ' or ic == '1 шт.') then
                        data = {item = item, count = 1}
                    end
                    table.insert(item_tab, data)                
                end
                if n:find(">>>") then
                    wait(ini.cfg.dialog_list_wait_bool and ini.cfg.dialog_wait_list or 150)
                    sampSendDialogResponse(3050, 1, i-1)
                end
                i = i + 1
            end)
        end
        local page1, page2 = title:match("(%d+)/(%d+)")
        if page1 == page2 then
            scan_sell = false
            window[0] = true
            msg("Сканирование {505050}инвентаря {ffffff}завершено.")
            sampSendDialogResponse(3050, 0, 0)
            lua_thread.create(function() wait(100) sampCloseCurrentDialogWithButton(0) end)
            writeJsonFile(item_tab, items_sell)
        end
    end
    if ini.cfg.auto_catcher then
        if dialogId == 3021 then
            sampSendDialogResponse(3021, 1, 0, '')
        elseif dialogId == 3020 then
            sampSendDialogResponse(3020, 1, 0, ini.cfg.auto_name or 'cordgotyou')
        elseif dialogId == 3030 then
            sampSendDialogResponse(3030, 1, ini.cfg.color_select, '')
        end
    end
end

function buy()
    imgui.BeginChild('buy_menu_page', imgui.ImVec2(-1, -1), false, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    imgui.PushFont(font[17])
    imgui.PushItemWidth(395)
    imgui.InputTextWithHint('##Search', u8'Поиск', search, 256)
    imgui.SameLine()
    if imgui.Button(fa('trash')..'##1') then 
        imgui.StrCopy(search,'')
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    if imgui.Button(scan and u8'Отменить' or u8'Сканировать предметы', imgui.ImVec2(190, 27)) then
        scan = not scan
        if scan then
            window[0] = false
            msg('Откройте меню лавки и скрипт {505050}автоматически {ffffff}начнет сканирование')
        else
            msg('Сканирование было {505050}отменено{ffffff}.')
        end
    end
    imgui.SameLine()
    imgui.PushItemWidth(142)
        if imgui.InputTextWithHint('##1.2.11', u8'Кол-во шт.', count_inp, ffi.sizeof(count_inp)) then
            item_v.count = u8:decode(ffi.string(count_inp))
            item_v.count = removeTrash(item_v.count)
            if tonumber(item_v.count) <= 0 then
                item_v.count = 1
            end
        end
        imgui.SameLine()
        if imgui.Button(fa('trash')..'##2') then
            imgui.StrCopy(count_inp,'')
            item_v.count = "1"
        end
        imgui.SameLine()
        if imgui.InputTextWithHint('##1.2.2', u8'Цена за шт.', price_inp, ffi.sizeof(price_inp)) then
            item_v.price = u8:decode(ffi.string(price_inp))
            item_v.price = removeTrash(item_v.price)
            if tonumber(item_v.price) < 10 then
                item_v.price = 10
            end
        end
        imgui.SameLine()
        if imgui.Button(fa('trash')..'##3') then 
            imgui.StrCopy(price_inp, '')
            item_v.price = "10"
        end
    imgui.PopItemWidth()
    imgui.SameLine()
    if imgui.Button(u8'Выставить на скуп', imgui.ImVec2(-1, 27)) then
        if next(item_list) ~= nil then
            display = {sell = false, buy = true, score = 1, score_from = 1}
            window[0] = false
            msg('Откройте меню лавки и скрипт {505050}автоматически {ffffff}начнет выставление товаров.')
            for k, v in pairs(item_list) do
                display.score_from = k
            end
        else
            msg('{ffa238}[Warning]: {ffffff}Нет предметов на скуп.')
        end
    end
    imgui.Separator()
    imgui.BeginChild('##add_to_buy', imgui.ImVec2(530, -1))
    if readJsonFile(items_buy) ~= nil then
        for k, v in pairs(readJsonFile(items_buy)) do
            if u8:decode(ffi.string(v)) ~= 0 and string.find(string.nlower(v), string.nlower(u8:decode(ffi.string(search))), nil, true) then
                imgui.Separator()
                if imgui.IsItemVisible() then
                    imgui.PushFont(font[22])
                    imgui.Text(u8(changeExtraSim(k..'. '..v, 48)))
                    if #(k..'. '..v) > 48 then
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.PushFont(font[17])
                            imgui.Text(u8(v))
                            imgui.PopFont()
                            imgui.EndTooltip()
                        end
                    end
                    imgui.PopFont()
                    imgui.SameLine()
                    imgui.SetCursorPosX(480)
                    imgui.PushFont(font[17])
                    if imgui.Button(fa('FOLDER_PLUS')..'##'..k) then
                        local data = {name = v, price = item_v.price, count = item_v.count}
                        addToData(data, item_list)
                    end
                    imgui.PopFont()
                else
                    imgui.Text('')
                end
            end
        end
    end
    imgui.EndChild()
    imgui.SetCursorPos(imgui.ImVec2(535, 38))
    imgui.BeginChild('##buy_list', imgui.ImVec2(-1, -1))
        for key, item in pairs(item_list) do
            imgui.PushFont(font[20])
            imgui.Text(u8(changeExtraSim(key .. ". " .. item.name, 45)))
            if #(key .. ". " .. item.name) > 45 then
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.PushFont(font[17])
                    imgui.Text(u8(item.name))
                    imgui.PopFont()
                    imgui.EndTooltip()
                end
            end
            imgui.PopFont()
            imgui.SameLine()
            imgui.SetCursorPosX(410)
            imgui.PushFont(font[20])
            imgui.TextColoredRGB('{ffffff}'..moneySeparator(item.count)..'{606060}/{4aff47d2}'..moneySeparator(item.price))
            imgui.PopFont()
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.PushFont(font[17])
                imgui.Text(u8('Кол-во шт./$ за шт.'))
                imgui.PopFont()
                imgui.EndTooltip()
            end
            imgui.SameLine()
            imgui.SetCursorPosX(610)
            if imgui.Button(fa('trash').."##"..key) then
                item_list[key] = nil
                addToData(data, item_list)
            end
            imgui.Separator()
        end
        imgui.EndChild()
        imgui.PopFont()
        if (readJsonFile(items_buy) == nil) then
            helpWithScan({x = 450, y = 150})
        end
    imgui.EndChild()
end

function sell()
    imgui.BeginChild('sellpage', imgui.ImVec2(-1, -1), false, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    imgui.PushFont(font[17])
    imgui.PushItemWidth(395)
    imgui.InputTextWithHint('##search_sell',u8'Поиск', search_sell, 256)
    imgui.SameLine()
    if imgui.Button(fa("TRASH")) then
        imgui.StrCopy(search_sell,'')
    end
    imgui.SameLine()
    if imgui.Button(scan_sell and u8'Отменить' or u8'Сканировать инвентарь', imgui.ImVec2(190, 27)) then
        scan_sell = not scan_sell
        if scan_sell then
            window[0] = false
            msg('Откройте меню лавки и скрипт {505050}автоматически {ffffff}начнет сканирование.')
        else
            msg('Сканирование было {505050}отменено{ffffff}.')
        end
    end
    imgui.SameLine()
    imgui.PushItemWidth(142)
        if imgui.InputTextWithHint('##1.2.11', u8'Кол-во шт.', count_sell, ffi.sizeof(count_sell)) then
            item_sell.count = u8:decode(ffi.string(count_sell))
            item_sell.count = removeTrash(item_sell.count)
            if tonumber(item_sell.count) <= 0 then
                item_sell.count = '1'
            end
        end
        imgui.SameLine()
        if imgui.Button(fa('trash')..'##2222') then
            imgui.StrCopy(count_sell,'')
            item_sell.count = '1'
        end
        imgui.SameLine()
        if imgui.InputTextWithHint('##sellllll', u8'Цена за шт.', price_sell, ffi.sizeof(price_sell)) then
            item_sell.price = u8:decode(ffi.string(price_sell))
            item_sell.price = removeTrash(item_sell.price)
            if tonumber(item_sell.price) < 10 then
                item_sell.price = '10'
            end
        end
        imgui.SameLine()
        if imgui.Button(fa('TRASH')..'##123') then
            imgui.StrCopy(price_sell, '')
            item_sell.price = '10'
        end
    imgui.PopItemWidth()
    imgui.SameLine()
    if imgui.Button(u8'Выставить на продажу', imgui.ImVec2(-1, 27)) then
        if next(sell_list) ~= nil then
            display = {sell = true, buy = false, score = 1, score_from = 1}
            for k, v in pairs(sell_list) do
                display.score_from = k
            end
            window[0] = false
        else
            msg('{ffa238}[Warning]: {ffffff}Нет предметов на продажу.')
        end
    end
    imgui.Separator()
    imgui.BeginChild('sell_list', imgui.ImVec2(530, -1), false)
    if readJsonFile(items_sell) ~= nil then
        for k, data in pairs(readJsonFile(items_sell)) do
            if u8:decode(ffi.string(data.item)) ~= 0 and string.find(string.nlower(data.item), string.nlower(u8:decode(ffi.string(search_sell))), nil, true) then
                imgui.Separator()
                if imgui.IsItemVisible() then
                    imgui.PushFont(font[22])
                    imgui.Text(u8(changeExtraSim(k..'. '..data.item..' - '.. data.count..' шт.', 48)))
                    if #(k..'. '..data.item..' - '.. data.count..' шт.') > 48 then
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.PushFont(font[17])
                            imgui.Text(u8(k..'. '..data.item..' - '.. data.count..' шт.'))
                            imgui.PopFont()
                            imgui.EndTooltip()
                        end
                    end
                    imgui.PopFont()
                    imgui.SameLine()
                    imgui.SetCursorPosX(480)
                    if imgui.Button(fa('FOLDER_PLUS')..'##1'..k) then
                        if tonumber(item_sell.count) <= tonumber(data.count) then 
                            local data = {name = data.item, price = item_sell.price, count = item_sell.count}
                            addToData(data, sell_list)
                        else
                            local data = {name = data.item, price = item_sell.price, count = data.count}
                            addToData(data, sell_list)
                        end
                    end
                else
                    imgui.Text('')
                end
            end
        end
    end
    imgui.EndChild()
    imgui.SetCursorPos(imgui.ImVec2(535, 38))
    imgui.BeginChild('##1.3', imgui.ImVec2(-1, -1))
        for key, item in pairs(sell_list) do
           imgui.PushFont(font[20])
            imgui.Text(u8(changeExtraSim(key .. ". " .. item.name, 45)))
            if #(key .. ". " .. item.name) > 45 then
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.PushFont(font[17])
                    imgui.Text(u8(item.name))
                    imgui.PopFont()
                    imgui.EndTooltip()
                end
            end
            
            imgui.PopFont()
            imgui.SameLine()
            imgui.SetCursorPosX(410)
            imgui.PushFont(font[20])
            imgui.TextColoredRGB('{ffffff}'..moneySeparator(item.count)..'{606060}/{4aff47d2}'..moneySeparator(item.price))
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.PushFont(font[17])
                imgui.Text(u8('Кол-во шт./$ за шт.'))
                imgui.PopFont()
                imgui.EndTooltip()
            end
            imgui.PopFont()
            imgui.SameLine()
            imgui.SetCursorPosX(610)
            if imgui.Button(fa('trash').."##1"..key) then
                sell_list[key] = nil
                addToData(data, sell_list)
            end
            imgui.Separator()
        end
        imgui.EndChild()
        imgui.PopFont()
        if (readJsonFile(items_sell) == nil) then
            helpWithScan({x = 450, y = 150})
        end
    imgui.EndChild()
end

function cfg_menu()
    imgui.SetCursorPos(imgui.ImVec2(50, 100))
    imgui.BeginChild('cfg_menu_skup', imgui.ImVec2(500, -1), false, imgui.WindowFlags.NoScrollbar)
        imgui.PushFont(font[25])
        imgui.CenterText(u8'Скупка')
        imgui.PopFont()
        imgui.BeginChild('cfg_list_buy_menu', imgui.ImVec2(500, 250), true)
        for line in lfs.dir(getWorkingDirectory()..'\\config\\CentralTrade\\buy-cfg') do
            if line == nil then
            elseif line:match(".+%.json") then
                imgui.PushFont(font[20])
                local cfg_name = u8'{ffffff}'..line:match("(.+)%.json")
                imgui.TextColoredRGB(tostring(changeExtraSim(cfg_name, 50)))
                if #cfg_name > 50 then
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.TextColoredRGB(cfg_name)
                        imgui.EndTooltip()
                    end
                end
                imgui.PopFont()
                imgui.SameLine()
                imgui.PushFont(font[17])
                imgui.SetCursorPosX(435)
                if imgui.Button(fa('PLAY')..'##'..line:match(".+%.json"), imgui.ImVec2(22, 27)) then
                    current_cfg.buy = 'moonloader/config/CentralTrade/buy-cfg/'..line:match("(.+)%.json")
                    item_list = loadConfig('moonloader/config/CentralTrade/buy-cfg/'..line:match("(.+)%.json"))
                    msg('Конфиг {505050}'..line:match("(.+)%.json")..'{ffffff} успешно загружен.', sell_list)
                end
                imgui.SameLine()
                if imgui.Button(fa('trash')..'##'..line:match("(.+)%.json")) then
                    local success, errorMessage = os.remove('moonloader/config/CentralTrade/buy-cfg/'..line:match("(.+)%.json")..'.json')
                    if success then
                        msg('Конфиг {505050}'..line:match("(.+)%.json")..' {ffffff}удален.')
                    else
                        print(errorMessage)
                    end
                end
                imgui.PopFont()
                imgui.Separator()
            end
        end
        imgui.EndChild()
        imgui.PushItemWidth(465)
        imgui.PushFont(font[20])
        imgui.InputTextWithHint('##search_cfg_buy', u8'Название конфига', search_cfg_buy, ffi.sizeof(search_cfg_buy))
        imgui.SameLine()
        imgui.PushFont(font[17])
        if imgui.Button(fa('trash')..'##0.29919293', imgui.ImVec2(30, 30)) then 
            imgui.StrCopy(search_cfg_buy, '')
        end
        imgui.PopFont()
        imgui.PopItemWidth()
        if imgui.Button(u8'Создать', imgui.ImVec2(500, 50)) then
            tosave.buy = u8:decode(ffi.string(search_cfg_buy))
            if (tosave.buy == '') or (tosave.buy == nil) or (tosave.buy:match("^%s*$") ~= nil) then
                msg("{ff3535}[Error]:{ffffff} Вы не можете создать {505050}безымянный {ffffff}конфиг.")
            else
                createConfig('buy-cfg/'..tosave.buy, item_list)
                msg("Конфиг {505050}"..tostring(tosave.buy)..'{ffffff} создан.')
            end
        end
        imgui.PopFont()
    imgui.EndChild()
    imgui.SameLine()
    imgui.SetCursorPosX(650)
    imgui.BeginChild('cfg_menu_prodaja', imgui.ImVec2(500, -1), false, imgui.WindowFlags.NoScrollbar)
        imgui.PushFont(font[25])
        imgui.CenterText(u8'Продажа')
        imgui.PopFont()
        imgui.BeginChild('cfg_list_sell_menu', imgui.ImVec2(500, 250), true)
        for line in lfs.dir(getWorkingDirectory()..'\\config\\CentralTrade\\sell-cfg') do
            if line == nil then
            elseif line:match(".+%.json") then
                imgui.PushFont(font[20])
                local cfg_name = u8'{ffffff}'..line:match("(.+)%.json")
                imgui.TextColoredRGB(tostring(changeExtraSim(cfg_name, 50)))
                if #cfg_name > 50 then
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.TextColoredRGB(cfg_name)
                        imgui.EndTooltip()
                    end
                end
                imgui.PopFont()
                imgui.SameLine()
                imgui.PushFont(font[17])
                imgui.SetCursorPosX(435)
                if imgui.Button(fa('PLAY')..'##'..line:match(".+%.json"), imgui.ImVec2(22, 27)) then
                    current_cfg.sell = ('moonloader/config/CentralTrade/sell-cfg/'..line:match("(.+)%.json"))
                    sell_list = loadConfig('moonloader/config/CentralTrade/sell-cfg/'..line:match("(.+)%.json"))
                    msg('Конфиг {505050}'..line:match("(.+)%.json")..'{ffffff} успешно загружен.', sell_list)
                end
                imgui.SameLine()
                if imgui.Button(fa('trash')..'##'..line..line:match("(.+)%.json")) then
                    local success, errorMessage = os.remove('moonloader/config/CentralTrade/sell-cfg/'..line:match("(.+)%.json")..'.json')
                    if success then
                        msg('Конфиг {505050}'..line:match("(.+)%.json")..' {ffffff}удален.')
                    else
                        print(errorMessage)
                    end
                end
                imgui.PopFont()
                imgui.Separator()
            end
        end
        imgui.EndChild()
        imgui.PushItemWidth(465)
        imgui.PushFont(font[20])
        imgui.InputTextWithHint('##search_cfg_sell', u8'Название конфига', search_cfg_sell, ffi.sizeof(search_cfg_sell))
        imgui.SameLine()
        imgui.PushFont(font[17])
        if imgui.Button(fa('trash')..'##0.2123123', imgui.ImVec2(30, 30)) then 
            imgui.StrCopy(search_cfg_sell, '')
        end
        imgui.PopFont()
        imgui.PopItemWidth()
        if imgui.Button(u8'Создать', imgui.ImVec2(500, 50)) then
            tosave.sell =  u8:decode(ffi.string(search_cfg_sell))
            if (tosave.sell == '') or (tosave.sell == nil) or (tosave.sell:match("^%s*$") ~= nil) then
                msg("{ff3535}[Error]:{ffffff} Вы не можете создать {505050}безымянный {ffffff}конфиг.")
            else 
                createConfig('sell-cfg/'..tosave.sell, sell_list)
                msg("Конфиг {505050}"..tostring(tosave.sell)..'{ffffff} создан.')
            end
        end
        imgui.PopFont()
    imgui.EndChild()
end

function settings_menu()
    imgui.BeginChild('settings_menu')
        imgui.PushFont(font[17])
        imgui.BeginChild('first_settings_block', imgui.ImVec2(700, -1), true)
        if imgui.ToggleButton(u8"Уведомления в телеграм", u8"Уведомления в телеграм", telegram_notification_bool) then
            if (ini.cfg.telegram_token:match("^%s*$") ~= nil or ini.cfg.telegram_token == nil) or ((tostring(ini.cfg.telegram_chatid)):match("^%s*$") ~= nil or ini.cfg.telegram_chatid == nil) then
                telegram_notification_bool[0] = false
                msg('{ff3535}[Error]: {ffffff}Уведомления не будут отправляться без {505050}token {ffffff}и {505050}chatid{ffffff}.')
            else
                ini.cfg.telegram_notification = not ini.cfg.telegram_notification 
                save() 
            end
        end
        if ini.cfg.telegram_notification then
            if imgui.CollapsingHeader(u8'Виды уведомлений') then
                if imgui.ToggleButton(u8'Уведомления о продаже/покупке', u8'Уведомления о продаже/покупке', tg_notf_market_bool) then
                    ini.cfg.tg_notf_market = not ini.cfg.tg_notf_market
                    save()
                end
                if imgui.ToggleButton(u8'Уведомления о кике', u8'Уведомления о кике', tg_notf_kick_bool) then
                    ini.cfg.tg_notf_kick = not ini.cfg.tg_notf_kick
                    save()
                end
                if imgui.ToggleButton(u8'Уведомления об уроне', u8'Уведомления об уроне', tg_notf_damage_bool) then
                    ini.cfg.tg_notf_damage = not ini.cfg.tg_notf_damage
                    save()
                end
                imgui.Separator()
            end
        end
        if imgui.ToggleButton(u8"АвтоЕда", u8"АвтоЕда", auto_eat_bool) then
            ini.cfg.auto_eat = not ini.cfg.auto_eat
            save()
        end
        if ini.cfg.auto_eat then
            if imgui.CollapsingHeader(u8'Настройки для АвтоЕды') then
                imgui.SetCursorPosX(150)
                imgui.Text(u8'АвтоЕда при '..ini.cfg.auto_eat_percent..'%%')
                imgui.SameLine()
                imgui.SetCursorPosX(410)
                imgui.Text(u8'Выберите еду')
                imgui.PushItemWidth(400)
                if imgui.SliderInt('##NIGGER_CHILL', auto_eat_percent_bool, 0, 100) then
                    if auto_eat_percent_bool[0] < 0 then
                        auto_eat_percent_bool[0] = 0
                    elseif auto_eat_percent_bool[0] > 100 then
                        auto_eat_percent_bool[0] = 100
                    end
                    ini.cfg.auto_eat_percent = auto_eat_percent_bool[0]
                    save()
                end
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(100)
                imgui.Combo('##set_eat', auto_eat_foodid, food_items, #food_list)
                ini.cfg.auto_eat_foodid = auto_eat_foodid[0]
                save()
                imgui.PopItemWidth()
                imgui.Separator()
            end
        end
        if imgui.ToggleButton(u8'Настройка лавки', u8'Настройка лавки', auto_catcher_bool) then
            ini.cfg.auto_catcher = not ini.cfg.auto_catcher
            save()
        end
        if ini.cfg.auto_catcher then
            if imgui.CollapsingHeader(u8'Настройки') then
                imgui.PushItemWidth(205)
                imgui.Text(u8'Введите название для лавки')
                imgui.SameLine()
                imgui.SetCursorPosX(237)
                imgui.Text(u8'Выберите номер цвета')
                if imgui.InputTextWithHint('##set_name_shp', 'name of shop', auto_name, 256) then
                    ini.cfg.auto_name = ffi.string(auto_name)
                    save()
                end
                imgui.SameLine()
                imgui.Combo('##set_color_shop', color_select, color_selector, #color_list)
                ini.cfg.color_select = color_select[0]
                save()
                imgui.PopItemWidth()
                imgui.Separator()
            end
        end
        if imgui.ToggleButton(u8'Кастом задержка', u8'Кастом задержка', dialog_list_wait_bool) then
            ini.cfg.dialog_list_wait_bool = not ini.cfg.dialog_list_wait_bool
            save()
        end
        if ini.cfg.dialog_list_wait_bool then
            if imgui.CollapsingHeader(u8'Задержка между диалогами') then
                imgui.SetCursorPosX(115)
                imgui.Text(u8'При сканировании')
                imgui.SameLine()
                imgui.SetCursorPosX(430)
                imgui.Text(u8'При выставлении товаров')
                imgui.PushItemWidth(343)
                if imgui.SliderInt('##NIGGER_NEVER_CHILL', dialog_wait_list, 0, 1000) then
                    if dialog_wait_list[0] < 0 then
                        dialog_wait_list[0] = 0
                    elseif dialog_wait_list[0] > 1000 then
                        dialog_wait_list[0] = 1000
                    end
                    ini.cfg.dialog_wait_list = dialog_wait_list[0]
                    save()
                end
                if imgui.IsItemHovered() and not imgui.IsItemActive() then
                    imgui.BeginTooltip()
                    imgui.Text(u8'Чем ниже задержка, тем выше вероятность кика.\nРекоменд. значение - 150')
                    imgui.EndTooltip()
                end
                imgui.SameLine()
                if imgui.SliderInt('##NIGGER_WORK', dialog_wait, 325, 1000) then
                    if dialog_wait[0] < 325 then
                        dialog_wait[0] = 325
                    elseif dialog_wait[0] > 1000 then
                        dialog_wait[0] = 1000
                    end
                    ini.cfg.dialog_wait = dialog_wait[0]
                    save()
                end
                imgui.PopItemWidth()
                imgui.Separator()
            end
        end

        if imgui.ToggleButton(u8'Удаление игроков в зоне стрима', u8'Удаление игроков в зоне стрима [/cs]', delete_players_bool) then
            ini.cfg.delete_players = not ini.cfg.delete_players
            save()
        end

        if imgui.ToggleButton(u8'Очистка чата', u8'Очистка чата [/cc]', clear_chat_bool) then
            ini.cfg.clear_chat = not ini.cfg.clear_chat
            save()
        end


        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('second_settings_block', imgui.ImVec2(-1, 125), true)
        imgui.PushFont(font[21])
        imgui.PushItemWidth(imgui.GetWindowWidth() - 9.05)
        if imgui.InputTextWithHint('##set_chatid', u8'Введите chatid', telegram_chatid_bool, ffi.sizeof(telegram_chatid_bool), imgui.InputTextFlags.Password) then
            ini.cfg.telegram_chatid = u8:decode(ffi.string(telegram_chatid_bool))
            save()
        end
        if imgui.InputTextWithHint('##set_token', u8'Введите token', telegram_token_bool, ffi.sizeof(telegram_token_bool), imgui.InputTextFlags.Password) then
            ini.cfg.telegram_token = u8:decode(ffi.string(telegram_token_bool))
            save()
        end
        imgui.PopItemWidth()
        if imgui.Button(u8'Отправить уведомление', imgui.ImVec2(-1, 40)) then
            if ini.cfg.telegram_notification then
                if (tostring(ini.cfg.telegram_token):match("^%s*$") ~= nil or tostring(ini.cfg.telegram_token) == nil) or ((tostring(ini.cfg.telegram_chatid)):match("^%s*$") ~= nil or ini.cfg.telegram_chatid == nil) then
                    msg('{ff3535}[Error]: {ffffff}Уведомления не будут отправляться без {505050}token {ffffff}и {505050}chatid{ffffff}.')
                else
                    sendTelegram("Это тестовое уведомление!")
                end
            else
                msg('{ff3535}[Error]: {ffffff}Выключена функция отправки уведомлений.')
            end
        end
        imgui.PopFont()
        imgui.EndChild()
        imgui.SetCursorPos(imgui.ImVec2(705, 130))
        imgui.BeginChild('third_settings_block', imgui.ImVec2(-1, -1), true)
        imgui.PushFont(font[21])
        imgui.Text(u8'Author: cord\nVersion: '..current_version..'\nBuild: 06.10.23')
        imgui.TextColoredRGB('{ffffff}Контакты {707070}(все ссылки кликабельны){ffffff}:')
        imgui.PopFont()
        imgui.PushFont(font[18])
        imgui.Text('Telegram -') imgui.SameLine() imgui.Link("https://t.me/cordhere", "@cordhere") imgui.SameLine() imgui.PushFont(font[17]) imgui.Text(fa('stars')) if imgui.IsItemHovered() then imgui.BeginTooltip() imgui.Text(u8'Отвечаю быстрее всего') imgui.EndTooltip() end imgui.PopFont()
        imgui.Text('Discord -') imgui.SameLine() imgui.Link('https://discordapp.com/users/1014430120754282548/', '@cordhere')
        imgui.TextColoredRGB('{ffffff}Телеграм-канал {707070}(feedback, updates) {ffffff}-') imgui.SameLine() imgui.Link('https://t.me/arzcentraltrade', '@arzcentraltrade')
        imgui.PopFont()
        imgui.PopFont()
        imgui.EndChild()
    imgui.EndChild()
end

function changelog_menu()
    imgui.BeginChild('main_changelog_block')
        imgui.BeginChild('##changelog_v1.0', imgui.ImVec2(-1, 250), true)
        imgui.PushFont(font[25])
            imgui.CenterText(u8'Версия 1.0')
            imgui.Separator()
        imgui.PopFont()
        imgui.PushFont(font[18])
            imgui.TextColoredRGB('{909090}- Релиз')
        imgui.PopFont()
        imgui.EndChild()
    imgui.EndChild()
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 then
        if (wparam == 27 and window[0]) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                window[0] = false
            end
        end
    end
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4
    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end
    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

function loadConfig(path)
    return readJsonFile(path..'.json')
end

function createConfig(name, data)
    local config_path = ('moonloader/config/CentralTrade/'..name..'.json')
    writeJsonFile(data, config_path)
end

function save()
    inicfg.save(ini, directIni)
end

imgui.OnInitialize(function()
    theme()
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local path = getFolderPath(0x14) .. '\\trebucbd.ttf'
    imgui.GetIO().Fonts:Clear() -- Удаляем стандартный шрифт на 14
    imgui.GetIO().Fonts:AddFontFromFileTTF(path, 17.0, nil, glyph_ranges) -- этот шрифт на 15 будет стандартным
    
    -- дополнительные шрифты:
    font[110] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 110.0, nil, glyph_ranges)
    font[70] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 70.0, nil, glyph_ranges)
    font[50] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 50.0, nil, glyph_ranges)
    font[35] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 35.0, nil, glyph_ranges)
    font[25] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 25.0, nil, glyph_ranges)
    font[24] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 24.0, nil, glyph_ranges)
    font[23] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 23.0, nil, glyph_ranges)
    font[22] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 22.0, nil, glyph_ranges)
    font[21] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 21.0, nil, glyph_ranges)
    font[20] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 20.0, nil, glyph_ranges)
    font[19] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 19.0, nil, glyph_ranges)
    font[18] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 18.0, nil, glyph_ranges)
    font[17] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 17.0, nil, glyph_ranges)
    -- fawesome 6
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('regular'), 16, config, iconRanges)
    --
end)

function theme()
    imgui.SwitchContext()
    --==[ STYLE ]==--
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 11
    imgui.GetStyle().GrabMinSize = 10

    --==[ BORDER ]==--
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1

    --==[ ROUNDING ]==--
    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 2
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5

    --==[ ALIGN ]==--
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    
    --==[ COLORS ]==--
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.1, 0.1, 0.1, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.1, 0.1, 0.1, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.1, 0.1, 0.1, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.25, 0.5)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 0.3)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0, 0, 0, 0.5)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0, 0, 0, 0.2)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(1, 1, 1, 0.05)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 0.7)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.2, 0.2, 0.2, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 1.00, 1.00, 0.1)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function imgui.ToggleButton(label, label_true, bool, a_speed)
    local p  = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()
 
    local bebrochka = false

    local label      = label or ""                          -- Текст false
    local label_true = label_true or ""                     -- Текст true
    local h          = imgui.GetTextLineHeightWithSpacing() -- Высота кнопки
    local w          = h * 1.7                              -- Ширина кнопки
    local r          = h / 2                                -- Радиус кружка
    local s          = a_speed or 0.2                       -- Скорость анимации
 
    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
 
    local x_begin = bool[0] and 1.0 or 0.0
    local t_begin = bool[0] and 0.0 or 1.0
 
    if LastTime == nil then
        LastTime = {}
    end
    if LastActive == nil then
        LastActive = {}
    end
 
    if imgui.InvisibleButton(label, imgui.ImVec2(w, h)) then
        bool[0] = not bool[0]
        LastTime[label] = os.clock()
        LastActive[label] = true
        bebrochka = true
    end

    if LastActive[label] then
        local time = os.clock() - LastTime[label]
        if time <= s then
            local anim = ImSaturate(time / s)
            x_begin = bool[0] and anim or 1.0 - anim
            t_begin = bool[0] and 1.0 - anim or anim
        else
            LastActive[label] = false
        end
    end
 
    local bg_color = imgui.ImVec4(x_begin * 0.13, x_begin * 0.9, x_begin * 0.13, imgui.IsItemHovered(0) and 0.7 or 0.9) -- Цвет прямоугольника
    local t_color  = imgui.ImVec4(1, 1, 1, x_begin) -- Цвет текста при false
    local t2_color = imgui.ImVec4(1, 1, 1, t_begin) -- Цвет текста при true
 
    dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + w, p.y + h), imgui.GetColorU32Vec4(bg_color), r)
    dl:AddCircleFilled(imgui.ImVec2(p.x + r + x_begin * (w - r * 2), p.y + r), t_begin < 0.5 and x_begin * r or t_begin * r, imgui.GetColorU32Vec4(imgui.ImVec4(0.9, 0.9, 0.9, 1.0)), r + 5)
    dl:AddText(imgui.ImVec2(p.x + w + r, p.y + r - (r / 2) - (imgui.CalcTextSize(label).y / 4)), imgui.GetColorU32Vec4(t_color), label_true)
    dl:AddText(imgui.ImVec2(p.x + w + r, p.y + r - (r / 2) - (imgui.CalcTextSize(label).y / 4)), imgui.GetColorU32Vec4(t2_color), label)
    return bebrochka
end

function url_encode(text)
	local text = string.gsub(text, "([^%w-_ %.~=])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	local text = string.gsub(text, " ", "+")
	return text
end

function sendTelegram(text)
	local url = ('https://api.telegram.org/bot' .. ini.cfg.telegram_token .. '/sendMessage?chat_id=' .. ini.cfg.telegram_chatid .. '&text=' .. url_encode(u8(text):gsub('{......}', '')))
	asyncHttpRequest('POST', url, nil, function(resolve)
	end, function(err)
		msg('Ошибка при отправке сообщения в Telegram!')
	end)
end

function asyncHttpRequest(method, url, args, resolve, reject)
	local request_thread = effil.thread(function (method, url, args)
	   local requests = require 'requests'
	   local result, response = pcall(requests.request, method, url, args)
	   if result then
		  response.json, response.xml = nil, nil
		  return true, response
	   else
		  return false, response
	   end
	end)(method, url, args)
	-- Если запрос без функций обработки ответа и ошибок.
	if not resolve then resolve = function() end end
	if not reject then reject = function() end end
	-- Проверка выполнения потока
	lua_thread.create(function()
	   local runner = request_thread
	   while true do
		  local status, err = runner:status()
		  if not err then
			 if status == 'completed' then
				local result, response = runner:get()
				if result then
				   resolve(response)
				else
				   reject(response)
				end
				return
			 elseif status == 'canceled' then
				return reject(status)
			 end
		  else
			 return reject(err)
		  end
		  wait(0)
	   end
	end)
end
