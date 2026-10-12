local import = ...
local Maid = import("Core/Maid")

-- mixin for anything that holds elements (modules, groups); adds Toggle/AddToggle/... methods
local Container = {}

local KINDS = {
    Toggle = { "Toggle" },
    Checkbox = { "Toggle", { Style = "Checkbox" } },
    Button = { "Button" },
    Buttons = { "ButtonRow" },
    ButtonRow = { "ButtonRow" },
    Slider = { "Slider" },
    Range = { "RangeSlider" },
    RangeSlider = { "RangeSlider" },
    Dropdown = { "Dropdown" },
    Input = { "Input" },
    Textbox = { "Input" },
    TextBox = { "Input" },
    Keybind = { "Keybind" },
    ColorPicker = { "ColorPicker" },
    Colorpicker = { "ColorPicker" },
    Label = { "Label" },
    Paragraph = { "Paragraph" },
    Divider = { "Divider" },
    Spacer = { "Spacer" },
    Space = { "Spacer" },
    ProgressBar = { "ProgressBar" },
    Progress = { "ProgressBar" },
    Segmented = { "Segmented" },
    Group = { "Group" },
    Image = { "Image" },
    Code = { "Code" },
}
Container.Kinds = KINDS

function Container.Setup(self)
    self.Children = {}
    self._views = {}
end

-- accepts (def), (flag, def) or (text) for labels / dividers
local function normalize(a, b)
    if type(a) == "string" then
        if type(b) == "table" then
            b.Flag = b.Flag or a
            return b
        end
        return { Title = a, Text = a }
    end
    return a or {}
end

function Container:_add(kind, a, b)
    local spec = KINDS[kind]
    local def = normalize(a, b)
    if spec[2] then
        for key, value in spec[2] do
            if def[key] == nil then def[key] = value end
        end
    end
    local class = import("Elements/" .. spec[1])
    local element = class.new(self, def)
    table.insert(self.Children, element)
    for _, view in self._views do
        element:Mount(view.Frame, view.Maid, #self.Children)
    end
    return element
end

for name in KINDS do
    Container[name] = function(self, a, b) return self:_add(name, a, b) end
    Container["Add" .. name] = Container[name]
end

-- renders every child into frame and keeps it in sync with later additions
function Container:_mountChildren(frame, maid)
    local view = { Frame = frame, Maid = maid }
    for index, child in self.Children do
        child:Mount(frame, maid, index)
    end
    table.insert(self._views, view)
    maid:Give(function()
        local index = table.find(self._views, view)
        if index then table.remove(self._views, index) end
    end)
    return view
end

function Container:_matchesChildren(query)
    for _, child in self.Children do
        if child:Matches(query) then return true end
    end
    return false
end

function Container:_eachElement(fn)
    for _, child in self.Children do
        fn(child)
        if child._eachElement then child:_eachElement(fn) end
    end
end

Container.Maid = Maid

function Container.Apply(target)
    for key, value in Container do
        if type(value) == "function" and key ~= "Apply" and key ~= "Setup" then
            target[key] = value
        end
    end
end

return Container
