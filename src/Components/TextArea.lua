local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")

-- multiline text that scrolls. AutomaticSize cannot grow a box past the canvas of the scrolling frame
-- around it, so the box is sized from its measured text; while typing the view follows the caret
local TextArea = {}

local TextService = Services.TextService

-- props: Size, Position, LayoutOrder, ZIndex, Parent, Padding (inner, default 6), and Box = TextBox props
-- (Theme included); returns the scrolling frame, the box and refit() for a font or width change
function TextArea.new(props)
    local pad = props.Padding or 6
    local scroll = Util.New("ScrollingFrame", {
        Size = props.Size,
        Position = props.Position or UDim2.new(),
        LayoutOrder = props.LayoutOrder or 0,
        ZIndex = props.ZIndex or 1,
        ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Theme = { ScrollBarImageColor3 = "TextMuted" },
        Parent = props.Parent,
    })
    local boxProps = table.clone(props.Box or {})
    boxProps.Size = UDim2.new(1, -pad * 2, 0, 0)
    boxProps.Position = UDim2.fromOffset(pad, pad)
    boxProps.MultiLine = true
    boxProps.TextWrapped = true
    boxProps.TextXAlignment = Enum.TextXAlignment.Left
    boxProps.TextYAlignment = Enum.TextYAlignment.Top
    boxProps.ZIndex = (props.ZIndex or 1) + 1
    boxProps.Parent = scroll
    local box = Util.New("TextBox", boxProps)

    local function scale() return math.max(Util.ScaleOf(scroll), 0.01) end

    -- text height at the box width in offset units; nil when it cannot be measured now
    local function measure(text)
        local width = box.AbsoluteSize.X / scale()
        if width < 4 then return nil end
        local params = Instance.new("GetTextBoundsParams")
        params.Text = text ~= "" and text or " "
        params.Font = box.FontFace
        params.Size = box.TextSize
        params.Width = width
        local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
        if not ok then return nil end
        -- a trailing newline starts a line the measure leaves out
        local height = bounds.Y
        if text:sub(-1) == "\n" then height += box.TextSize * box.LineHeight end
        return height
    end

    -- the caret line inside the view, nothing scrolled otherwise
    local function follow(textHeight)
        if not box:IsFocused() then return end
        local caret = box.CursorPosition
        if caret < 1 then return end
        local view = scroll.AbsoluteSize.Y / scale()
        local line = box.TextSize * box.LineHeight
        local bottom
        if caret > #box.Text then
            bottom = textHeight
        else
            bottom = measure(box.Text:sub(1, caret - 1)) or textHeight
        end
        local top = bottom - line
        local at = scroll.CanvasPosition.Y
        if bottom + pad > at + view then
            scroll.CanvasPosition = Vector2.new(0, bottom + pad - view)
        elseif top < at then
            scroll.CanvasPosition = Vector2.new(0, math.max(top - pad, 0))
        end
    end

    local token = 0
    local function refit(followCaret)
        token += 1
        local mine = token
        task.spawn(function()
            local height = measure(box.Text)
            if mine ~= token or not height or not box.Parent then return end
            local view = scroll.AbsoluteSize.Y / scale()
            local total = math.max(math.ceil(height) + pad * 2, view)
            box.Size = UDim2.new(1, -pad * 2, 0, total - pad * 2)
            box.Position = UDim2.fromOffset(pad, pad)
            scroll.CanvasSize = UDim2.fromOffset(0, total)
            if followCaret then follow(height) end
        end)
    end

    box:GetPropertyChangedSignal("Text"):Connect(function() refit(true) end)
    box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
        if box:IsFocused() then refit(true) end
    end)
    box:GetPropertyChangedSignal("FontFace"):Connect(function() refit(false) end)
    scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() refit(false) end)
    task.defer(refit, false)
    return scroll, box, refit
end

return TextArea
