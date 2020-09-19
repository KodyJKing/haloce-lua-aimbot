local vec = require("vector")

local module = {reloadonrun = true}

PID_P = 1
PID_I = 0.1
PID_D = 0.5
lastErr = nil
errIntegral = 0
function module.update()
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
    return vec.sub(targetPos, playerPos)
end

bestEntity = nil
function entityScore(address)
    local health = readFloat(address + 0xE0)
    if health <= 0 then
        return 0
    end
    local heading = playerHeading()
    local offset = vecToEntity(address)
    local len = math.sqrt(vec.lenSq(offset))
    offset = vec.scale(offset, 1 / len)
    return vec.dot(offset, heading)
end

function module.addEntity(address)
    if bestEntity == nil then
        bestEntity = address
    end
    local newScore = entityScore(address)
    local oldScore = entityScore(bestEntity)
    if newScore > oldScore then
        bestEntity = address
    end
end

return module
