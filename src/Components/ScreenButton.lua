local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Drag = import("Core/Drag")
local Layer = import("Components/Layer")

-- on-screen buttons for touch screens: a pill in the hud layer that stays while the menu is hidden;
-- menu hidden: a press runs Press, its end runs Release; menu open: dimmed, a drag moves it
-- def: Id (the saved position is keyed by this), Title, Icon, Active() -> bool (green while true),
--      Press(), Release(), Visible (default true), Position (UDim2, first placement)
local ScreenButton = {}
ScreenButton.__index = ScreenButton

local UIS = Services.UserInputService
local HEIGHT = 36

-- keeps the pill fully on screen (resolution changes, old saves)
local function clamp(frame)
    local bounds, size = Layer.Bounds(), frame.AbsoluteSize
    local position = frame.AbsolutePosition
    frame.Position = UDim2.fromOffset(
        math.clamp(position.X, 0, math.max(0, bounds.X - size.X)),
        math.clamp(position.Y, 0, math.max(0, bounds.Y - size.Y)))
end

function ScreenButton.new(window, def)
    local self = setmetatable({
        Window = window,
        Def = def,
        Id = def.Id or def.Title or "Button",
        Visible = def.Visible ~= false,
        Active = false,
        _held = nil,
    }, ScreenButton)
    local interface = window.Interface
    interface.Buttons = type(interface.Buttons) == "table" and interface.Buttons or {}

    local button = window.Maid:Give(Util.New("TextButton", {
        Name = "ScreenButton",
        Size = UDim2.fromOffset(0, HEIGHT),
        AutomaticSize = Enum.AutomaticSize.X,
        Visible = false,
        Theme = {
            BackgroundColor3 = "Surface",
            BackgroundTransparency = function()
                local base = (tonumber(interface.ButtonTransparency) or 15) / 100
                return window.Visible and math.max(base, 0.45) or base
            end,
        },
        Parent = Layer.Hud,
    }))
    Util.Corner(UDim.new(1, 0), button)
    Util.Padding(button, 0, 14, 0, def.Icon and 10 or 14)
    Util.List(button, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    self.Stroke = Util.Stroke(button, function(t) return self.Active and t.Success or t.Stroke end, function(t)
        return self.Active and 0.1 or t.StrokeTransparency
    end, 1.5)
    if def.Icon then
        self.IconLabel = Util.Icon(def.Icon, {
            Size = UDim2.fromOffset(15, 15),
            LayoutOrder = 1,
            Theme = { ImageColor3 = function(t) return self.Active and t.Success or t.TextDim end },
            Parent = button,
        })
    end
    self.Label = Util.Label({
        Text = def.Title or "",
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 2,
        Theme = {
            TextColor3 = function(t) return self.Active and t.Success or t.Text end,
            TextTransparency = function() return window.Visible and 0.4 or 0 end,
        },
        Parent = button,
    })
    self.Scale = Util.New("UIScale", { Parent = button })
    self.Frame = button

    local saved = interface.Buttons[self.Id]
    if type(saved) == "table" then
        button.Position = UDim2.fromOffset(tonumber(saved[1]) or 0, tonumber(saved[2]) or 0)
    else
        button.Position = def.Position or UDim2.new(1, -140, 0.25, #window.ScreenButtons * (HEIGHT + 8))
    end
    window.Maid:Give(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(function() if button.Parent then clamp(button) end end)
    end))

    -- menu open: a drag moves it; menu hidden: a press presses
    window.Maid:Give(Drag.Attach(button, button, {
        Enabled = function() return window.Visible end,
        OnEnd = function(moved)
            if not moved then return end
            clamp(button)
            interface.Buttons[self.Id] = { math.floor(button.AbsolutePosition.X), math.floor(button.AbsolutePosition.Y) }
            button.Position = UDim2.fromOffset(button.AbsolutePosition.X, button.AbsolutePosition.Y)
            window:SaveState()
        end,
    }))
    window.Maid:Give(button.InputBegan:Connect(function(input)
        if window.Visible or self._held or not Util.IsPress(input) then return end
        self._held = input
        -- a cancelled touch fires no InputEnded
        local watch
        watch = input.Changed:Connect(function(property)
            if property ~= "UserInputState" then return end
            local state = input.UserInputState
            if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                watch:Disconnect()
                if self._held == input then self:_release() end
            end
        end)
        Util.Safe(def.Press)
        self:Refresh()
    end))
    window.Maid:Give(UIS.InputEnded:Connect(function(input)
        if input == self._held then self:_release() end
    end))
    self:ApplyStyle()
    self:SetVisible(self.Visible)
    return self
end

function ScreenButton:_release()
    if not self._held then return end
    self._held = nil
    Util.Safe(self.Def.Release)
    self:Refresh()
end

-- repaints the active state; the window polls every shown button
function ScreenButton:Refresh()
    local active = false
    if self.Def.Active then
        local ok, value = pcall(self.Def.Active)
        active = ok and value and true or false
    end
    self.Active = active
    for _, inst in { self.Frame, self.Stroke, self.Label, self.IconLabel } do Theme.Refresh(inst, 0.12) end
end

function ScreenButton:ApplyStyle()
    self.Scale.Scale = (tonumber(self.Window.Interface.ButtonScale) or 100) / 100
    self:Refresh()
end

function ScreenButton:SetVisible(visible)
    self.Visible = visible and true or false
    if not self.Visible then self:_release() end
    self.Frame.Visible = self.Visible
    if self.Visible then
        self:Refresh()
        task.defer(function() if self.Frame.Parent then clamp(self.Frame) end end)
    end
end

function ScreenButton:SetTitle(text)
    self.Label.Text = text
end

function ScreenButton:Destroy()
    self:_release()
    self.Frame:Destroy()
    local list = self.Window.ScreenButtons
    local index = table.find(list, self)
    if index then table.remove(list, index) end
end

return ScreenButton
