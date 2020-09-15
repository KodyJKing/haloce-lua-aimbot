if mytimer == nil then
    mytimer = createTimer(nil, false)
end

mytimer.OnTimer = function(timer)
    local value = readBytes("isReticleRed")
    if value == 1 then
        --print(value)
        mouse_event(MOUSEEVENTF_LEFTDOWN)
        Sleep(10)
        mouse_event(MOUSEEVENTF_LEFTUP)
    end
end

mytimer.Interval = 10

if myhotkey then
    myhotkey.Destroy()
end

myhotkey =
    createHotkey(
    function()
        mytimer.Enabled = not mytimer.Enabled
        if mytimer.Enabled then
            print("Bot enabled.")
            speak("Bot enabled.")
        else
            print("Bot disabled.")
            speak("Bot disabled.")
        end
    end,
    VK_F5
)

print("Trigger bot ready, hit F5 to toggle.")

if myhotkey2 then
    myhotkey2.Destroy()
end

myhotkey2 =
    createHotkey(
    function()
        mouse_event(MOUSEEVENTF_MOVE, 1000, 1000)
    end,
    VK_F4
)
