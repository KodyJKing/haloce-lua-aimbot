local vector = {reloadonrun = true}

function vector.new(x, y, z)
    return {x = x, y = y, z = z}
end

function vector.read(basePtr, offset)
    return vector.new(readFloat(basePtr + offset), readFloat(basePtr + offset + 0x8), readFloat(basePtr + offset + 0x4))
end

function vector.scale(a, b)
    return {
        x = a.x * b,
        y = a.y * b,
        z = a.z * b
    }
end

function vector.add(a, b)
    return {
        x = a.x + b.x,
        y = a.y + b.y,
        z = a.z + b.z
    }
end

function vector.sub(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z
    }
end

function vector.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function vector.cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

function vector.lenSq(a)
    return a.x * a.x + a.y * a.y + a.z * a.z
end

function vector.normalized(a)
    local len = math.sqrt(vector.lenSq(a))
    return vector.scale(a, 1 / len)
end

function vector.toString(a)
    return "{ x = " .. a.x .. ", y = " .. a.y .. ", z = " .. a.z .. " }"
end

return vector
