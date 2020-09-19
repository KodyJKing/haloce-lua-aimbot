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

timers = {}
hotkeys = {}
function createBotTimer(name, hotkey, interval, onTimer)
    if timers[name] == nil then
        timers[name] = createTimer(nil, false)
    end

    timers[name].OnTimer = onTimer
    timers[name].Interval = interval

    if hotkeys[name] then
        hotkeys[name].Destroy()
    end

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

addEntity = aimbot.addEntity
