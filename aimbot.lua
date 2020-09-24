local vec = require("vector")

local module = {reloadonrun = true}

local offsets = {
    yaw = 0x0C,
    pitch = 0x10,
    lookVector = 0x230,
    horizontalLookVector = 0x224,
    velocity = 0x68,
    torsoPos = 0x5C,
    eyePos = 0xA0,
    health = 0xE0
}

local entityTypes = {}
entityTypes[0xe6dd0569] = "player"
entityTypes[0xe1ed0079] = "marine"
entityTypes[0xe75d05e9] = "elite"
entityTypes[0xea4208ce] = "grunt"
entityTypes[0xeb810a0d] = "jackal1"
entityTypes[0xeb2609b2] = "jackal2"

local targetEntity = nil

-- Main function
function module.update()
    if not verifyTarget(targetEntity) then
        targetEntity = nil
    end
    if not isKeyPressed(VK_SHIFT) or targetEntity == nil then
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

-- Replaces the current target if the ticked target is closer to the reticle.
function module.tickEntity(address)
    if not verifyTarget(address) then
        return
    end
    if targetEntity == nil then
        targetEntity = address
    end
    local newScore = entityScore(address)
    local oldScore = entityScore(targetEntity)
    if newScore > oldScore then
        targetEntity = address
    -- print("Targeting " .. entityTypeString(address))
    end
end

function setAngles(yaw, pitch)
    if (yaw == math.nan) or (pitch == math.nan) then
        return
    end
    local anglesPtr = readInteger("anglesPtr")
    local yawPtr = anglesPtr + offsets.yaw
    local pitchPtr = anglesPtr + offsets.pitch
    writeFloat(yawPtr, yaw)
    writeFloat(pitchPtr, pitch)
end

function playerHeading()
    return vec.read(readInteger("playerPtr"), offsets.lookVector)
end

function desiredHeading()
    if targetEntity == nil then
        return vec.new(0, 1, 0)
    end
    return vecToEntity(targetEntity)
end

function vecToEntity(address)
    local playerPos = vec.read(readInteger("playerPtr"), offsets.eyePos)
    local targetPos = targetHeadPos(address)
    local displacement = vec.sub(targetPos, playerPos)
    local velocity = vec.read(address, offsets.velocity)
    local leadTarget = vec.add(displacement, velocity)
    return vec.normalized(leadTarget)
end

function targetHeadPos(address)
    local eyePos = vec.read(address, offsets.eyePos)
    local headOffset = entityHeadOffset(address)
    return vec.add(eyePos, headOffset)
end

function entityHeadOffset(address)
    local type = entityTypeString(address)
    local headOffsets = {
        marine = {0.05, 0},
        grunt = {0.05, -0.1},
        jackal1 = {0.05, -0.05},
        jackal2 = {0.05, -0.05},
        elite = {0.1, 0.04}
    }
    local offset = headOffsets[type] or {0, 0}
    local fwd, up = unpack(offset)
    local result = vec.read(address, offsets.horizontalLookVector)
    result.x = result.x * fwd
    result.y = result.y * fwd + up
    result.z = result.z * fwd
    return result
end

function entityScore(address)
    local health = readFloat(address + offsets.health)
    if health <= 0 then
        return 0
    end
    return vec.dot(vecToEntity(address), playerHeading())
end

function entityTypeString(address)
    local type = readInteger(address)
    if entityTypes[type] ~= nil then
        return entityTypes[type]
    end
    if type ~= nil then
        return string.format("%x", type)
    end
    return "????"
end

function verifyTarget(address)
    if address == nil or entityTypeString(address) == "marine" then
        return false
    end
    local health = readFloat(address + offsets.health)
    if health <= 0 or health > 1 then
        return false
    end
    return true
end

return module
