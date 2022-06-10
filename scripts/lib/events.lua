
local Events = { listeners = {} }

Events.addListener = function(event, fn)
  if not Events.listeners[event] then
    Events.listeners[event] = { fns = {} }
    Events.listeners[event].run = function (args)
      for _, fn in pairs(Events.listeners[event].fns) do fn(args) end
    end
    script.on_event(event, Events.listeners[event].run)
  end
  table.insert(Events.listeners[event].fns, fn)
end

return Events