local PriorityQueue = require("priority_queue")

local Events = { listeners = {} }

function Events.addListener(event, fn)
  if not Events.listeners[event] then
    Events.listeners[event] = { fns = {} }
    Events.listeners[event].run = function (args)
      for _, f in pairs(Events.listeners[event].fns) do f(args) end
    end
    script.on_event(event, Events.listeners[event].run)
  end
  table.insert(Events.listeners[event].fns, fn)
end

Events.on_tick_events = PriorityQueue()
local function on_tick(event)
  while not Events.on_tick_events:empty() and Events.on_tick_events:peek() <= event.tick do
    local fn = Events.on_tick_events:pop()
    fn(event.tick)
  end
end
script.on_event(defines.events.on_tick, on_tick)

function Events.onTick(time, fn)
  Events.on_tick_events:put(fn, time)
end

local function repeating_task_handler(interval, fn)
  return function(tick)
    fn(tick)
    Events.onTick(tick + interval, repeating_task_handler(interval, fn))
  end
end

function Events.repeatingTask(interval, start_offset, fn)
  Events.onTick(0, function(start_tick)
    local next_tick_delta = interval - (start_tick % interval) + start_offset
    if next_tick_delta > interval then
      next_tick_delta = next_tick_delta - interval
    end
    Events.onTick(start_tick + next_tick_delta, repeating_task_handler(interval, fn))
  end)
end

return Events