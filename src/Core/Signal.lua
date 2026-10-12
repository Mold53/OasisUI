local _ = ...

-- synchronous signal; handlers run in connect order
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
    local handler = { fn = fn, live = true }
    table.insert(self._handlers, handler)
    local handlers = self._handlers
    local connection = { Connected = true }
    function connection:Disconnect()
        if not handler.live then return end
        handler.live = false
        self.Connected = false
        local index = table.find(handlers, handler)
        if index then table.remove(handlers, index) end
    end
    return connection
end

function Signal:Once(fn)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        fn(...)
    end)
    return connection
end

function Signal:Fire(...)
    for _, handler in table.clone(self._handlers) do
        if handler.live then handler.fn(...) end
    end
end

function Signal:Destroy()
    for _, handler in self._handlers do handler.live = false end
    table.clear(self._handlers)
end

return Signal
