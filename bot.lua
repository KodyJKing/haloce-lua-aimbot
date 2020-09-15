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
    local _UP = vec3(0, 1, 0)
    local forward = playerHeading()
    local right = vCross(forward, _UP)
    local up = vCross(right, forward)

    local desired = desiredHeading()
    local xDot = vDot(right, desired)
    local yDot = vDot(up, desired)
    --print(vString(forward) .. vString(right) .. vString(up))

    local err = math.acos(vDot(forward, desired))

    local pid = PID_P * err + PID_I * errIntegral
    if lastErr ~= nil then
        local errDiff = err - lastErr
        pid = pid + errDiff * PID_D
    end
    lastErr = err
    errIntegral = math.min(5, (errIntegral + err) * 0.9)

    local rate = math.min(100, 100 * math.abs(pid))
    local dx = -xDot
    local dy = -yDot
    local len = math.sqrt(dx * dx + dy * dy)
    dx = dx * rate / len
    dy = dy * rate / len
    mouse_event(MOUSEEVENTF_MOVE, dx, dy)
end

function playerHeading()
    return readVec(readInteger("playerPtr"), 0x230)
end

function desiredHeading()
    local adr = 0x40106C90
    if bestEntity ~= nil then
        adr = bestEntity
    end
    return vNormalized(vecToEntity(0x40106C90))
end

function vecToEntity(address)
    local playerPos = readVec(readInteger("playerPtr"), 0xA0)
    local targetPos = readVec(address, 0xA0)
    return vSub(targetPos, playerPos)
end

bestEntity = nil
function entityScore(address)
    local heading = playerHeading()
    local offset = vecToEntity(address)
    offset = vScale(offset, 1 / vLengthSq(offset))
    return vDot(offset, heading)
end

function addEntity(address)
    local newScore = entityScore(address)
    local oldScore = entityScore(bestEntity)
    if newScore > oldScore then
        bestEntity = address
    end
end

print("Aim bot ready, hit F4 to toggle.")
-- End Aim

-- Start Vector
function vec3(x, y, z)
    return {x = x, y = y, z = z}
end

function readVec(basePtr, offset)
    return vec3(readFloat(basePtr + offset), readFloat(basePtr + offset + 0x8), readFloat(basePtr + offset + 0x4))
end

function vScale(a, b)
    return {
        x = a.x * b,
        y = a.y * b,
        z = a.z * b
    }
end

function vAdd(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z
    }
end

function vSub(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z
    }
end

function vDot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function vCross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

function vLengthSq(a)
    return a.x * a.x + a.y * a.y + a.z * a.z
end

function vNormalized(a)
    local len = math.sqrt(vLengthSq(a))
    return vScale(a, 1 / len)
end

function vString(a)
    return "{ x = " .. a.x .. ", y = " .. a.y .. ", z = " .. a.z .. " }"
end
-- End Vector

function message(msg)
    print(msg)
    speak(msg)
end

function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end
