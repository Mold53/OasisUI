local import = ...
local Signal = import("Core/Signal")
local Maid = import("Core/Maid")
local Util = import("Core/Util")

-- element model: holds the value; any number of views (tab, favorites, search) render it
local Base = {}
Base.__index = Base

function Base.Class(kind)
    local class = setmetatable({ Kind = kind }, { __index = Base })
    class.__index = class
    return class
end

function Base.Init(self, container, def)
    self.Def = def
    self.Container = container
    self.Window = container.Window
    self.Module = container.Module or container
    self.Title = def.Title or def.Name or def.Text or self.Kind
    self.Description = def.Description or def.Desc
    self.Tooltip = def.Tooltip
    self.Flag = def.Flag
    self.Changed = Signal.new()
    self.StateChanged = Signal.new()
    self.Locked = def.Locked == true
    self.LockReason = def.LockedReason or def.LockReason
    self.Visible = def.Visible ~= false
    self.NoSave = def.NoSave == true or def.Flag == nil
    self._listeners = {}
    self._mounts = {}
    if self.Flag then
        self.Window.Config:Register(self.Flag, self)
        self.Window.Library.Flags[self.Flag] = self
    end
    return self
end

-- stores the value, repaints views, runs callbacks unless silent
function Base:_commit(value, silent)
    self.Value = value
    self.Changed:Fire(value)
    if not silent then self:_notify() end
    self.Window:_touch()
end

-- callback arguments; kinds with several values override this
function Base:_args()
    return self.Value
end

function Base:_notify()
    Util.Safe(self.Def.Callback, self:_args())
    for _, fn in self._listeners do Util.Safe(fn, self:_args()) end
end

function Base:Get()
    return self.Value
end

function Base:Set(value, silent)
    self:_commit(value, silent)
end

function Base:Reset()
    if self.Default ~= nil then self:Set(self.Default) end
end

function Base:OnChanged(fn)
    table.insert(self._listeners, fn)
    return self
end

function Base:SetTitle(text)
    self.Title = text
    self.StateChanged:Fire("Title")
end

function Base:SetDescription(text)
    self.Description = text
    self.StateChanged:Fire("Description")
end

function Base:SetLocked(locked, reason)
    self.Locked = locked and true or false
    self.LockReason = reason or self.LockReason
    self.StateChanged:Fire("Locked")
end

function Base:Lock(reason) self:SetLocked(true, reason) end
function Base:Unlock() self:SetLocked(false) end

function Base:SetVisible(visible)
    self.Visible = visible and true or false
    self.StateChanged:Fire("Visible")
end

-- keeps this element locked (or hidden) while predicate(source value) is false
function Base:DependsOn(source, predicate, mode)
    predicate = predicate or function(value) return value and true or false end
    local function update()
        local ok = predicate(source:Get())
        if mode == "Hide" then
            self:SetVisible(ok)
        else
            self:SetLocked(not ok, self.Def.LockedReason or ("Requires " .. tostring(source.Title)))
        end
    end
    source.Changed:Connect(update)
    if source.StateChanged then source.StateChanged:Connect(update) end
    update()
    return self
end

function Base:Matches(query)
    local text = (tostring(self.Title) .. " " .. tostring(self.Description or "")):lower()
    return text:find(query, 1, true) ~= nil
end

function Base:Save()
    return self.Value
end

function Base:Load(value)
    self:Set(value)
end

-- called by containers for every view; Render is implemented per kind
function Base:Mount(parent, maid, order)
    local mount = Maid.new()
    maid:Give(mount)
    table.insert(self._mounts, mount)
    mount:Give(function()
        local index = table.find(self._mounts, mount)
        if index then table.remove(self._mounts, index) end
    end)
    local frame = self:Render(parent, mount)
    if frame then frame.LayoutOrder = order or 0 end
    return frame
end

function Base:Destroy()
    for _, mount in table.clone(self._mounts) do mount:Clean() end
    if self.Flag then
        self.Window.Config:Unregister(self.Flag, self)
        if self.Window.Library.Flags[self.Flag] == self then self.Window.Library.Flags[self.Flag] = nil end
    end
    if self.Binding then self.Binding:Destroy() end
    local children = self.Container.Children
    local index = table.find(children, self)
    if index then table.remove(children, index) end
    self.Changed:Destroy()
    self.StateChanged:Destroy()
end

return Base
