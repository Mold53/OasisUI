local import = ...
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Page = import("Components/Page")
local Module = import("Components/Module")

-- a sidebar entry with its own page of modules, optionally split into sub-tabs
-- def: Title, Icon, Columns (1 | 2), Id, Draggable, Empty
local Tab = {}
Tab.__index = Tab

local BAR = 30

function Tab.new(window, def, parent)
    local self = setmetatable({
        Window = window,
        Def = def,
        Title = def.Title or def.Name or "Tab",
        Icon = def.Icon,
        Modules = {},
        Parent = parent,
    }, Tab)
    self.Id = parent and (parent.Id .. "/" .. (def.Id or self.Title)) or (def.Id or self.Title)
    self.Path = parent and (parent.Title .. " › " .. self.Title) or self.Title
    self.Page = Page.new(window, {
        Id = "tab:" .. self.Id,
        Columns = def.Columns or 2,
        Draggable = def.Draggable ~= false,
        Empty = def.Empty or "Nothing here yet.",
        Parent = parent and parent.SubArea,
    })
    self.Frame = self.Page.Frame
    return self
end

-- def: see Components/Module
function Tab:Module(def)
    def = def or {}
    local module = Module.new(self, def)
    table.insert(self.Modules, module)
    self.Page:Add(module, def.Side)
    if module.Favorite then self.Window:_addFavoriteView(module) end
    return module
end
Tab.AddModule = Tab.Module
Tab.Feature = Tab.Module

-- a card without switch or key, open by default
function Tab:Section(def)
    if type(def) == "string" then def = { Title = def } end
    def = def or {}
    def.Toggle = false
    return self:Module(def)
end
Tab.AddSection = Tab.Section

function Tab:Select()
    self.Window:SelectTab(self)
end

function Tab:SetTitle(text)
    self.Title = text
    if self.Entry then self.Entry.Label.Text = text end
    if self.Chip then self.Chip.Label.Text = text end
end

-- hides the sidebar entry (or the sub-tab chip) without removing anything
function Tab:SetVisible(visible)
    self.Visible = visible ~= false
    local button = (self.Entry and self.Entry.Button) or (self.Chip and self.Chip.Button)
    if button then button.Visible = self.Visible end
end

function Tab:ResetLayout()
    self.Page:ResetLayout()
    for _, sub in self.SubTabs or {} do
        if sub ~= self.Shared then sub.Page:ResetLayout() end
    end
end

-- sub-tabs ----------------------------------------------------------------------

function Tab:_enableSubTabs()
    if self.SubTabs then return end
    local window = self.Window
    self.SubTabs = {}
    local holder = Util.New("Frame", {
        Name = "SubTabs",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = self.Page.Frame.Visible,
        Parent = window.Content,
    })
    local bar = Util.New("ScrollingFrame", {
        Name = "Bar",
        Size = UDim2.new(1, 0, 0, BAR),
        ScrollingDirection = Enum.ScrollingDirection.X,
        Parent = holder,
    })
    Util.AutoCanvas(bar, Util.List(bar, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center), true)
    self.SubArea = Util.New("Frame", {
        Name = "Area",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, BAR + 8),
        Size = UDim2.new(1, 0, 1, -BAR - 8),
        Parent = holder,
    })
    self.SubBar, self.SubFrame = bar, holder
    self.Frame = holder

    -- modules added straight to the tab become its first sub-tab
    if #self.Modules > 0 then
        local shared = setmetatable({
            Window = window,
            Def = { Title = self.Def.MainTitle or "General" },
            Title = self.Def.MainTitle or "General",
            Modules = self.Modules,
            Parent = self,
            Page = self.Page,
            Frame = self.Page.Frame,
        }, Tab)
        shared.Id, shared.Path = self.Id, self.Title
        self.Page.Frame.Parent = self.SubArea
        self.Shared = shared
        self:_chip(shared)
    end
end

function Tab:_chip(sub)
    local state = { Selected = false, Hover = false }
    local button = Util.New("TextButton", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 26),
        LayoutOrder = #self.SubTabs + 1,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t)
                if state.Selected then return t.ElevatedTransparency end
                return state.Hover and math.min(t.ElevatedTransparency + 0.45, 0.85) or 1
            end,
        },
        Parent = self.SubBar,
    })
    Util.Corner(6, button)
    Util.Padding(button, 0, 11, 0, sub.Icon and 9 or 11)
    Util.List(button, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local stroke = Util.Stroke(button, function(t) return state.Selected and t.Accent or t.Stroke end, function(t)
        return state.Selected and 0.55 or 1
    end)
    local icon
    if sub.Icon then
        icon = Util.Icon(sub.Icon, {
            Size = UDim2.fromOffset(13, 13),
            LayoutOrder = 1,
            Theme = { ImageColor3 = function(t) return state.Selected and t.Accent or t.TextMuted end },
            Parent = button,
        })
    end
    local label = Util.Label({
        Text = sub.Title,
        TextSize = 12,
        Weight = Enum.FontWeight.Medium,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 2,
        Theme = { TextColor3 = function(t) return state.Selected and t.Text or (state.Hover and t.TextDim or t.TextMuted) end },
        Parent = button,
    })
    local function paint()
        for _, inst in { button, stroke, label, icon } do Theme.Refresh(inst, 0.15) end
    end
    sub.Chip = { Button = button, Label = label, State = state, Paint = paint }
    button.MouseEnter:Connect(function() state.Hover = true; paint() end)
    button.MouseLeave:Connect(function() state.Hover = false; paint() end)
    button.MouseButton1Click:Connect(function() self.Window:SelectTab(sub) end)
    table.insert(self.SubTabs, sub)
    if not self.ActiveSub then self:_showSub(sub, true) end
end

-- def: Title, Icon, Columns, Id, Draggable, Empty
function Tab:SubTab(def)
    if type(def) == "string" then def = { Title = def } end
    def = def or {}
    self:_enableSubTabs()
    local sub = Tab.new(self.Window, def, self)
    self:_chip(sub)
    local saved = self.Window.Interface.SubTabs[self.Id]
    if saved == sub.Id then self:_showSub(sub, true) end
    return sub
end
Tab.AddSubTab = Tab.SubTab

function Tab:_showSub(sub, silent)
    self.ActiveSub = sub
    for _, other in self.SubTabs do
        local selected = other == sub
        other.Page.Frame.Visible = selected
        if other.Chip.State.Selected ~= selected then
            other.Chip.State.Selected = selected
            other.Chip.Paint()
        end
    end
    if not silent then
        self.Window.Interface.SubTabs[self.Id] = sub.Id
        self.Window:SaveState()
    end
end

-- the page that holds a module of this tab
function Tab:PageOf(module)
    if self.Page:Find(module) then return self.Page end
    for _, sub in self.SubTabs or {} do
        if sub.Page:Find(module) then return sub.Page end
    end
    return nil
end

return Tab
