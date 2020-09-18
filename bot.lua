local vec = require("vector")

-- Start Trigger
if triggerTimer == nil then
    triggerTimer = createTimer(nil, false)
end

triggerTimer.OnTimer = function(timer)
    local value = readBytes("isReticleRed")
    if value == 1 then
        mouse_event(MOUSEEVENTF_LEFTDOWN)
        Sleep(10)
        mouse_event(MOUSEEVENTF_LEFTUP)
    end
end

triggerTimer.Interval = 10

if triggerKey then
    triggerKey.Destroy()
end

triggerKey =
    createHotkey(
    function()
        triggerTimer.Enabled = not triggerTimer.Enabled
        if triggerTimer.Enabled then
            message("Trigger bot enabled.")
        else
            message("Trigger bot disabled.")
        end
    end,
    VK_F5
)

print("Trigger bot ready, hit F5 to toggle.")
-- End Trigger

-- Start Aim
if aimTimer == nil then
    aimTimer = createTimer(nil, false)
end

aimTimer.OnTimer = function(timer)
    moveTowardsTarget()
end

aimTimer.Interval = 5

if aimKey then
    aimKey.Destroy()
end

aimKey =
    createHotkey(
    function()
        aimTimer.Enabled = not aimTimer.Enabled
        if aimTimer.Enabled then
            message("Aim bot enabled.")
        else
            message("Aim bot disabled.")
            errIntegral = 0
        end
    end,
    VK_F4
)

PID_P = 1
PID_I = 0.1
PID_D = 0.5
lastErr = nil
errIntegral = 0
function moveTowardsTarget()
    if not isKeyPressed(VK_SHIFT) then
        return
    end

    local _UP = vec.new(0, 1, 0)
    local forward = playerHeading()
    local right = vec.cross(forward, _UP)
    local up = vec.cross(right, forward)

    local desired = desiredHeading()
    local xDot = vec.dot(right, desired)
    local yDot = vec.dot(up, desired)
    --print(vString(forward) .. vString(right) .. vString(up))

    local err = math.acos(vec.dot(forward, desired))

    local pid = PID_P * err + PID_I * errIntegral
    if lastErr ~= nil then
        local errDiff = err - lastErr
        pid = pid + errDiff * PID_D
    end
    lastErr = err
    errIntegral = math.min(5, (errIntegral + err) * 0.9)

    local baseRate = baseMouseSpeed()
    local rate = math.min(baseRate, baseRate * math.abs(pid))
    local dx = -xDot
    local dy = -yDot
    local len = math.sqrt(dx * dx + dy * dy)
    dx = dx * rate / len
    dy = dy * rate / len
    mouse_event(MOUSEEVENTF_MOVE, dx, dy)
end

function baseMouseSpeed()
    local playerPtr = readInteger("playerPtr")
    local zoomState = readBytes(playerPtr + 0x320)
    if zoomState == 0xFF then
        return 100
    end
    if zoomState == 0x00 then
        return 200
    end
    if zoomState == 0x01 then
        return 600
    end
end

function playerHeading()
    return vec.read(readInteger("playerPtr"), 0x230)
end

function desiredHeading()
    local adr = 0x40106C90
    if bestEntity ~= nil then
        adr = bestEntity
    end
    return vec.normalized(vecToEntity(adr))
end

function vecToEntity(address)
    local playerPos = vec.read(readInteger("playerPtr"), 0xA0)
    local targetPos = vec.read(address, 0xA0)
    return vSub(targetPos, playerPos)
end

bestEntity = nil
function entityScore(address)
    local health = readFloat(address + 0xE0)
    if health <= 0 then
        return 0
    end
    local heading = playerHeading()
    local offset = vecToEntity(address)
    local len = math.sqrt(vLengthSq(offset))
    offset = vec.scale(offset, 1 / len)
    return vec.dot(offset, heading)
end

function addEntity(address)
    if bestEntity == nil then
        bestEntity = address
    end
    local newScore = entityScore(address)
    local oldScore = entityScore(bestEntity)
    if newScore > oldScore then
        bestEntity = address
    end
end

print("Aim bot ready, hit F4 to toggle.")
-- End Aim

function message(msg)
    print(msg)
    speak(msg)
end

function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end
