function reloadmodules()
    for k, v in pairs(package.loaded) do
        if type(v) == "table" and v.reloadonrun == true then
            package.loaded[k] = nil
        end
    end
end

function message(msg)
    print(msg)
    speak(msg)
end

function gameRunningAndFocused()
    local running = readBytes("halo.exe+286A98") == 1
    local focused = readInteger(0x0008CA98) ~= 0
    return running and focused
end

timers = {}
hotkeys = {}
function createBotTimer(name, hotkey, interval, onTimer)
    timers[name] = createTimer(nil, false)
    timers[name].OnTimer = function()
        if gameRunningAndFocused() then
            onTimer()
        end
    end
    timers[name].Interval = interval
    hotkeys[name] =
        createHotkey(
        function()
            timers[name].Enabled = not timers[name].Enabled
            if timers[name].Enabled then
                message(name .. " enabled.")
            else
                message(name .. " disabled.")
            end
        end,
        hotkey
    )
    print(name .. " ready, hit F5 to toggle.")
end

function onReload()
    for k, v in pairs(timers) do
        v.Destroy()
    end
    for k, v in pairs(hotkeys) do
        v.Destroy()
    end
end

--------------------------------

reloadmodules()
local aimbot = require("aimbot")

createBotTimer(
    "Trigger bot",
    VK_F5,
    10,
    function()
        local value = readBytes("isReticleRed")
        if value == 1 then
            mouse_event(MOUSEEVENTF_LEFTDOWN)
            Sleep(10)
            mouse_event(MOUSEEVENTF_LEFTUP)
        end
    end
)
createBotTimer("Aim bot", VK_F4, 5, aimbot.update)

tickEntity = aimbot.tickEntity

return onReload
