local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Button = import("Elements/Button")

-- several buttons sharing one line; def: { { Title, Icon, Style, Confirm, Callback }, ... } or { Buttons = {...} }
local ButtonRow = Base.Class("ButtonRow")

function ButtonRow.new(container, def)
    local self = setmetatable({}, ButtonRow)
    local specs = def.Buttons or def
    Base.Init(self, container, { Title = def.Title or "Buttons", Visible = def.Visible, Locked = def.Locked })
    self.NoSave = true
    self.Buttons = {}
    for index, spec in specs do
        if type(spec) == "table" then
            self.Buttons[index] = { Spec = spec, Armed = false, Title = spec.Title, Locked = false }
        end
    end
    return self
end

function ButtonRow:Matches(query)
    for _, entry in self.Buttons do
        if tostring(entry.Title):lower():find(query, 1, true) then return true end
    end
    return false
end

function ButtonRow:Press(index)
    local entry = self.Buttons[index]
    if not entry or self.Locked or entry.Locked then return end
    if entry.Spec.Confirm and not entry.Armed then
        entry.Armed = true
        self.StateChanged:Fire("Armed")
        task.delay(2.5, function()
            if entry.Armed then
                entry.Armed = false
                self.StateChanged:Fire("Armed")
            end
        end)
        return
    end
    entry.Armed = false
    self.StateChanged:Fire("Armed")
    Util.Safe(entry.Spec.Callback)
end

function ButtonRow:SetButtonTitle(index, title)
    local entry = self.Buttons[index]
    if entry then
        entry.Title = title
        self.StateChanged:Fire("Title")
    end
end

function ButtonRow:SetButtonLocked(index, locked)
    local entry = self.Buttons[index]
    if entry then
        entry.Locked = locked
        self.StateChanged:Fire("Locked")
    end
end

function ButtonRow:Render(parent, maid)
    local holder = maid:Give(Util.New("Frame", {
        Name = "ButtonRow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = self.Visible,
        Parent = parent,
    }))
    Util.List(holder, 6, Enum.FillDirection.Horizontal)
    local painters = {}
    for index, entry in self.Buttons do
        local button, paint = Button.Draw(holder, entry.Spec, function()
            return { Armed = entry.Armed, Locked = self.Locked or entry.Locked, Title = entry.Title }
        end, function() self:Press(index) end)
        button.LayoutOrder = index
        button.Size = UDim2.new(0, 0, 0, 30)
        Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = button })
        table.insert(painters, paint)
        paint()
    end
    maid:Give(self.StateChanged:Connect(function(what)
        if what == "Visible" then holder.Visible = self.Visible end
        for _, paint in painters do paint() end
    end))
    return holder
end

return ButtonRow
