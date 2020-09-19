local vec = require("vector")

local module = {reloadonrun = true}

function module.update()
    if not isKeyPressed(VK_SHIFT) then
        return
    end
    local desired = desiredHeading()
    -- print(vec.toString(desired))
    local r = math.sqrt(desired.x * desired.x + desired.z * desired.z)
    local yaw = math.atan2(desired.z, desired.x)
    local pitch = math.atan2(desired.y, r)
    -- print(yaw .. ", " .. pitch)
    setAngles(yaw, pitch)
end

-- TAU = 2 * 3.14159
-- HALFPI = 3.14159 * 0.5
function setAngles(yaw, pitch)
    -- if yaw < 0 then
    --     yaw = yaw + TAU
    -- end
    -- if pitch < -HALFPI then
    --     pitch = pitch + TAU
    -- end
    local anglesPtr = readInteger("anglesPtr")
    local yawPtr = anglesPtr + 0x0C
    local pitchPtr = anglesPtr + 0x10
    writeFloat(yawPtr, yaw)
    writeFloat(pitchPtr, pitch)
end

function playerHeading()
    return vec.read(readInteger("playerPtr"), 0x230)
end

function desiredHeading()
    if bestEntity == nil then
        return vec.new(0, 1, 0)
    end
    return vecToEntity(bestEntity)
end

function vecToEntity(address)
    local playerPos = vec.read(readInteger("playerPtr"), 0xA0)
    local targetPos = targetHeadPos(address)
    return vec.normalized(vec.sub(targetPos, playerPos))
end

function targetHeadPos(address)
    local eyePos = vec.read(address, 0xA0)
    local headOffset = entityHeadOffset(address)
    return vec.add(eyePos, headOffset)
end

function entityHeadOffset(address)
    local type = entityTypeString(address)
    local offsets = {
        marine = {0.05, 0},
        grunt = {0.17, -0.1},
        jackal1 = {0.05, -0.05},
        jackal2 = {0.05, -0.05},
        elite = {0.1, 0.05}
    }
    local offset = offsets[type] or {0, 0}
    local fwd, up = unpack(offset)
    local result = vec.read(address, 0x230)
    result.x = result.x * fwd
    result.y = result.y * fwd + up
    result.z = result.z * fwd
    return result
end

bestEntity = nil
function entityScore(address)
    local health = readFloat(address + 0xE0)
    if health <= 0 then
        return 0
    end
    return vec.dot(vecToEntity(address), playerHeading())
end

entityTypes = {}
entityTypes[0xe6dd0569] = "player"
entityTypes[0xe1ed0079] = "marine"
entityTypes[0xe75d05e9] = "elite"
entityTypes[0xea4208ce] = "grunt"
entityTypes[0xeb810a0d] = "jackal1"
entityTypes[0xeb2609b2] = "jackal2"
function entityTypeString(address)
    local type = readInteger(address)
    if entityTypes[type] ~= nil then
        return entityTypes[type]
    end
    return string.format("%x", type)
end

function module.tickEntity(address)
    if bestEntity == nil then
        bestEntity = address
    end
    local newScore = entityScore(address)
    local oldScore = entityScore(bestEntity)
    if newScore > oldScore then
        bestEntity = address
        print("Targeting " .. entityTypeString(address))
    end
end

return module
