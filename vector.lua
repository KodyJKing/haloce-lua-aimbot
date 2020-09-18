local module = {}

function module.new(x, y, z)
    return {x = x, y = y, z = z}
end

function module.read(basePtr, offset)
    return vec3(readFloat(basePtr + offset), readFloat(basePtr + offset + 0x8), readFloat(basePtr + offset + 0x4))
end

function module.scale(a, b)
    return {
        x = a.x * b,
        y = a.y * b,
        z = a.z * b
    }
end

function module.add(a, b)
    return {
        x = a.x + b.x,
        y = a.y + b.y,
        z = a.z + b.z
    }
end

function module.sub(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z
    }
end

function module.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function module.cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

function module.lenSq(a)
    return a.x * a.x + a.y * a.y + a.z * a.z
end

function module.normalized(a)
    local len = math.sqrt(vLengthSq(a))
    return vScale(a, 1 / len)
end

function module.toString(a)
    return "{ x = " .. a.x .. ", y = " .. a.y .. ", z = " .. a.z .. " }"
end
