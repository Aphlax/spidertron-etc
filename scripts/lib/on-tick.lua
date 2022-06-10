require("utils")
local PriorityQueue = require("priority_queue")

local on_tick_events = PriorityQueue()

local function on_tick(event)
    while not on_tick_events:empty() and on_tick_events:peek() <= event.tick do
        local fn = on_tick_events:pop()
        fn(event.tick)
    end
end
script.on_event(defines.events.on_tick, on_tick)

function onTick(time, fn)
    on_tick_events:put(fn, time)
end

local function repeating_task_handler(interval, fn)
    return function(tick)
        fn(tick)
        onTick(tick + interval, repeating_task_handler(interval, fn))
    end
end

function repeatingTask(interval, fn)
    onTick(0, function(tick) onTick(tick + interval, repeating_task_handler(interval, fn)) end)
end
