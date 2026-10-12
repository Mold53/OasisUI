local _ = ...

local cloneref = cloneref or function(instance) return instance end

local function service(name)
    return cloneref(game:GetService(name))
end

return {
    Players          = service("Players"),
    UserInputService = service("UserInputService"),
    RunService       = service("RunService"),
    TweenService     = service("TweenService"),
    HttpService      = service("HttpService"),
    TextService      = service("TextService"),
    CoreGui          = service("CoreGui"),
    GuiService       = service("GuiService"),
    Lighting         = service("Lighting"),
    Stats            = service("Stats"),
}
