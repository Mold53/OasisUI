local import = ...
local Page = import("Components/Page")
local Module = import("Components/Module")

-- a sidebar entry with its own page of modules
-- def: Title, Icon, Columns (1 | 2), Id
local Tab = {}
Tab.__index = Tab

function Tab.new(window, def)
    local self = setmetatable({
        Window = window,
        Def = def,
        Title = def.Title or def.Name or "Tab",
        Icon = def.Icon,
        Modules = {},
    }, Tab)
    self.Id = def.Id or self.Title
    self.Page = Page.new(window, {
        Id = "tab:" .. self.Id,
        Columns = def.Columns or 2,
        Draggable = def.Draggable ~= false,
        Empty = def.Empty or "Nothing here yet.",
    })
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
    if self.Button then self.Button.Label.Text = text end
end

function Tab:ResetLayout()
    self.Page:ResetLayout()
end

return Tab
