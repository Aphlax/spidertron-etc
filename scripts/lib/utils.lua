-- Lists

function map(t, fn)
    local result = {}
    for k, v in pairs(t) do
        result[k] = fn(v)
    end
    return result
end

function filter(t, fn)
    local result = {}
    for _, v in pairs(t) do
        if fn(v) then
            result[#result + 1] = v
        end
    end
    return result
end

function some(t, fn)
    for _, v in pairs(t) do
        if fn(v) then
            return true
        end
    end
    return false
end

function every(t, fn)
    for _, v in pairs(t) do
        if not fn(v) then
            return false
        end
    end
    return true
end

function flatten(lists)
    local result = {}
    for _, list in ipairs(lists) do
        for i = 1, #list do
            result[#result + 1] = list[i]
        end
    end
    return result
end

function concat(a, b, c, d, e, f, g, h)
    return flatten(filter({ a, b, c, d, e, f, g, h }, function(v) return v ~= nil end))
end

function range(n)
    local result = {}
    for i = 1, n do result[#result + 1] = i end
    return result
end

function replicate(t, n)
    local result = {}
    for _ = 1, n do result = concat(result, t) end
    return result
end

function foreach(t, fn)
    for _, v in pairs(t) do fn(v) end
end

function sortWith(t, fn)
    if type(fn) == nil then table.sort(t); return t end
    if type(fn) == "string" then local name = fn; fn = function (a) return a[name] end end
    table.sort(t, function(a, b) return fn(a) < fn(b) end)
    return t
end

function push(t, item)
    t[#t + 1] = item
end

function deepcopy(object)
    if type(object) == "table" then
        local result = {}
        for key, value in ipairs(object) do
            if type(value) == "table" then
                result[key] = deepcopy(value)
            else
                result[key] = value
            end
        end
        return result
    else
        return object
    end
end

-- Vectors

function translate(position, x, y)
    return { x = position.x + x, y = position.y + y }
end

function v_add(v1, v2)
    return { x = v1.x + v2.x, y = v1.y + v2.y }
end

function v_scale(v1, a)
    return { x = v1.x * a, y = v1.y * a }
end

function v_sub(v1, v2)
    return { x = v1.x - v2.x, y = v1.y - v2.y }
end

function v_length(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

function v_floor(v)
    return { x = math.floor(v.x), y = math.floor(v.y) }
end

function v_right(v)
    return { x = v.y, y = -v.x }
end

function v_left(v)
    return { x = -v.y, y = v.x }
end

function v_rotate(v, direction)
    if direction == defines.direction.north then return v end
    v = v_right(v)
    if direction == defines.direction.east then return v end
    v = v_right(v)
    if direction == defines.direction.south then return v end
    return v_right(v)
end

function is_overlapping(area1, area2)
    return (area1.left_top.x <= area2.right_bottom.x and area1.right_bottom.x >= area2.left_top.x) and
            (area1.left_top.y <= area2.right_bottom.y and area1.right_bottom.y >= area2.left_top.y)
end

function is_inside(point, area)
    return area.left_top.x <= point.x and point.x < area.right_bottom.x and
            area.left_top.y <= point.y and point.y < area.right_bottom.y
end

-- Direction

function direction_vector(direction)
    if direction == defines.direction.north then
        return { x = 0, y = -1 }
    elseif direction == defines.direction.east then
        return { x = 1, y = 0 }
    elseif direction == defines.direction.south then
        return { x = 0, y = 1 }
    elseif direction == defines.direction.west then
        return { x = -1, y = 0 }
    end
end

function vector_direction(v)
    if math.abs(v.x) <= math.abs(v.y) then
        return v.y <= 0 and defines.direction.north or defines.direction.south
    else
        return v.x <= 0 and defines.direction.west or defines.direction.east
    end
end

function right(direction)
    if direction == defines.direction.north then
        return defines.direction.east
    elseif direction == defines.direction.east then
        return defines.direction.south
    elseif direction == defines.direction.south then
        return defines.direction.west
    elseif direction == defines.direction.west then
        return defines.direction.north
    end
end

function left(direction)
    if direction == defines.direction.north then
        return defines.direction.west
    elseif direction == defines.direction.east then
        return defines.direction.north
    elseif direction == defines.direction.south then
        return defines.direction.east
    elseif direction == defines.direction.west then
        return defines.direction.south
    end
end

-- Strings

function str_ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end
