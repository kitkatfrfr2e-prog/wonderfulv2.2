local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

-- ── Радиусы скруглений ──────────────────────────────────────────────────
local R_WINDOW   = 8   -- окно, группбоксы, таббоксы
local R_ELEMENT  = 4   -- кнопки, слайдеры, дропдауны, инпуты
local R_SMALL    = 3   -- тоглы, кейпикеры, маленькие фреймы
local R_PICKER   = 6   -- колорпикер-попап
local R_NOTIFY   = 4   -- уведомления
local R_TOOLTIP  = 3   -- тултипы

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor       = Color3.fromRGB(255, 255, 255);
    MainColor       = Color3.fromRGB(28,  28,  28);
    BackgroundColor = Color3.fromRGB(20,  20,  20);
    AccentColor     = Color3.fromRGB(0,   85,  255);
    OutlineColor    = Color3.fromRGB(50,  50,  50);
    RiskColor       = Color3.fromRGB(255, 50,  50);

    Black  = Color3.new(0, 0, 0);
    Font   = Enum.Font.Code;

    OpenedFrames    = {};
    DependencyBoxes = {};

    Signals   = {};
    ScreenGui = ScreenGui;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400);
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue  = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do PlayerList[i] = PlayerList[i].Name end
    table.sort(PlayerList, function(a,b) return a < b end)
    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do TeamList[i] = TeamList[i].Name end
    table.sort(TeamList, function(a,b) return a < b end)
    return TeamList;
end;

-- ── Helpers ──────────────────────────────────────────────────────────────

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(":%d+: ")
        return Library:Notify(i and err:sub(i+1) or err, 3)
    end
end;

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end;

--- Создаёт инстанс или применяет свойства к существующему
function Library:Create(Class, Properties)
    local inst = type(Class) == 'string' and Instance.new(Class) or Class
    for k, v in next, Properties do inst[k] = v end
    return inst;
end;

--- Вспомогательный UICorner
local function AddCorner(parent, radius)
    Instance.new('UICorner').CornerRadius = UDim.new(0, radius or R_ELEMENT)
    Instance.new('UICorner').Parent = parent
    -- Правильный способ:
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, radius or R_ELEMENT)
    c.Parent = parent
    return c
end

-- Избавляемся от двойного создания в helper выше — переписываем чисто:
-- (функция выше имела баг — исправлено здесь, AddCorner ниже используется вместо той)
local function Corner(parent, radius)
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, radius or R_ELEMENT)
    c.Parent = parent
    return c
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;
    Library:Create('UIStroke', {
        Color             = Color3.new(0,0,0);
        Thickness         = 1;
        LineJoinMode      = Enum.LineJoinMode.Miter;
        Parent            = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local inst = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font                   = Library.Font;
        TextColor3             = Library.FontColor;
        TextSize               = 16;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(inst)
    Library:AddToRegistry(inst, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(inst, Properties);
end;

function Library:MakeDraggable(Frame, Cutoff)
    Frame.Active = true;
    Frame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Frame.AbsolutePosition.X,
                Mouse.Y - Frame.AbsolutePosition.Y
            )
            if ObjPos.Y > (Cutoff or 40) then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Frame.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Frame.Size.X.Offset * Frame.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Frame.Size.Y.Offset * Frame.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        Size             = UDim2.fromOffset(X + 10, Y + 6);
        ZIndex           = 100;
        Parent           = Library.ScreenGui;
        Visible          = false;
    })
    Corner(Tooltip, R_TOOLTIP)

    local Label = Library:CreateLabel({
        Position         = UDim2.fromOffset(5, 3);
        Size             = UDim2.fromOffset(X, Y);
        TextSize         = 14;
        Text             = InfoStr;
        TextColor3       = Library.FontColor;
        TextXAlignment   = Enum.TextXAlignment.Left;
        ZIndex           = Tooltip.ZIndex + 1;
        Parent           = Tooltip;
    })

    Library:AddToRegistry(Tooltip, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
    Library:AddToRegistry(Label,   { TextColor3 = 'FontColor' })

    local Hovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        Hovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible  = true
        while Hovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        Hovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HoverInst, Target, Props, Defaults)
    HoverInst.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Target]
        for Prop, ColorIdx in next, Props do
            Target[Prop] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Prop] then Reg.Properties[Prop] = ColorIdx end
        end
    end)
    HoverInst.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Target]
        for Prop, ColorIdx in next, Defaults do
            Target[Prop] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Prop] then Reg.Properties[Prop] = ColorIdx end
        end
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame in next, Library.OpenedFrames do
        local p, s = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= p.X and Mouse.X <= p.X + s.X
        and Mouse.Y >= p.Y and Mouse.Y <= p.Y + s.Y then
            return true
        end
    end
end;

function Library:IsMouseOverFrame(Frame)
    local p, s = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= p.X and Mouse.X <= p.X + s.X
       and Mouse.Y >= p.Y and Mouse.Y <= p.Y + s.Y
end;

function Library:UpdateDependencyBoxes()
    for _, db in next, Library.DependencyBoxes do db:Update() end
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value-MinA)/(MaxA-MinA)))*MinB + ((Value-MinA)/(MaxA-MinA))*MaxB
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local b = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920,1080))
    return b.X, b.Y
end;

function Library:GetDarkerColor(Color)
    local H,S,V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V/1.5)
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx  = #Library.Registry + 1
    local Data = { Instance = Instance; Properties = Properties; Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if not Data then return end
    for i = #Library.Registry, 1, -1 do
        if Library.Registry[i] == Data then table.remove(Library.Registry, i) end
    end
    for i = #Library.HudRegistry, 1, -1 do
        if Library.HudRegistry[i] == Data then table.remove(Library.HudRegistry, i) end
    end
    Library.RegistryMap[Instance] = nil
end;

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for i = #Library.Signals, 1, -1 do
        table.remove(Library.Signals, i):Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then Library:RemoveFromRegistry(inst) end
end))

-- ═══════════════════════════════════════════════════════════════════════
--  BASE ADDONS  (ColorPicker + KeyPicker)
-- ═══════════════════════════════════════════════════════════════════════

local BaseAddons = {}
do
    local Funcs = {}

    -- ── ColorPicker ─────────────────────────────────────────────────────
    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local ColorPicker = {
            Value        = Info.Default;
            Transparency = Info.Transparency or 0;
            Type         = 'ColorPicker';
            Title        = type(Info.Title) == 'string' and Info.Title or 'Color picker';
            Callback     = Info.Callback or function() end;
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H,S,V = Color3.toHSV(Color)
            self.Hue = H; self.Sat = S; self.Vib = V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        -- маленький превью-квадрат на метке
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3     = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(0, 28, 0, 14);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        })
        Corner(DisplayFrame, R_SMALL)

        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size            = UDim2.new(0,27,0,13);
            ZIndex          = 5;
            Image           = 'http://www.roblox.com/asset/?id=12977615774';
            Visible         = not not Info.Transparency;
            Parent          = DisplayFrame;
        })
        Corner(CheckerFrame, R_SMALL)

        -- ── Попап-фрейм колорпикера ──────────────────────────────────
        local PickerFrameOuter = Library:Create('Frame', {
            Name      = 'Color';
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Position  = UDim2.fromOffset(
                DisplayFrame.AbsolutePosition.X,
                DisplayFrame.AbsolutePosition.Y + 18
            );
            Size      = UDim2.fromOffset(230, Info.Transparency and 273 or 255);
            Visible   = false;
            ZIndex    = 15;
            Parent    = ScreenGui;
        })
        Corner(PickerFrameOuter, R_PICKER)

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(
                DisplayFrame.AbsolutePosition.X,
                DisplayFrame.AbsolutePosition.Y + 18
            )
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 16;
            Parent           = PickerFrameOuter;
        })
        Corner(PickerFrameInner, R_PICKER)

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1,0,0,2);
            ZIndex           = 17;
            Parent           = PickerFrameInner;
        })
        -- Верхнее скругление для акцент-полосы совпадает с R_PICKER

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position     = UDim2.new(0,4,0,25);
            Size         = UDim2.new(0,200,0,200);
            ZIndex       = 17;
            Parent       = PickerFrameInner;
        })
        Corner(SatVibMapOuter, R_SMALL)

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 18;
            Parent           = SatVibMapOuter;
        })
        Corner(SatVibMapInner, R_SMALL)

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size            = UDim2.new(1,0,1,0);
            ZIndex          = 18;
            Image           = 'rbxassetid://4155801252';
            Parent          = SatVibMapInner;
        })
        Corner(SatVibMap, R_SMALL)

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint        = Vector2.new(0.5,0.5);
            Size               = UDim2.new(0,6,0,6);
            BackgroundTransparency = 1;
            Image              = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3        = Color3.new(0,0,0);
            ZIndex             = 19;
            Parent             = SatVibMap;
        })
        local CursorInner = Library:Create('ImageLabel', {
            Size               = UDim2.new(0,4,0,4);
            Position           = UDim2.new(0,1,0,1);
            BackgroundTransparency = 1;
            Image              = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex             = 20;
            Parent             = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position     = UDim2.new(0,208,0,25);
            Size         = UDim2.new(0,15,0,200);
            ZIndex       = 17;
            Parent       = PickerFrameInner;
        })
        Corner(HueSelectorOuter, R_SMALL)

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1,1,1);
            BorderSizePixel  = 0;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 18;
            Parent           = HueSelectorOuter;
        })
        Corner(HueSelectorInner, R_SMALL)

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1,1,1);
            AnchorPoint      = Vector2.new(0,0.5);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(1,0,0,1);
            ZIndex           = 18;
            Parent           = HueSelectorInner;
        })

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position     = UDim2.fromOffset(4, 230);
            Size         = UDim2.new(0.5,-6,0,20);
            ZIndex       = 18;
            Parent       = PickerFrameInner;
        })
        Corner(HueBoxOuter, R_SMALL)

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 18;
            Parent           = HueBoxOuter;
        })
        Corner(HueBoxInner, R_SMALL)

        Library:Create('UIGradient', {
            Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212))
            });
            Rotation = 90;
            Parent   = HueBoxInner;
        })

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position               = UDim2.new(0,5,0,0);
            Size                   = UDim2.new(1,-5,1,0);
            Font                   = Library.Font;
            PlaceholderColor3      = Color3.fromRGB(190,190,190);
            PlaceholderText        = 'Hex color';
            Text                   = '#FFFFFF';
            TextColor3             = Library.FontColor;
            TextSize               = 14;
            TextStrokeTransparency = 0;
            TextXAlignment         = Enum.TextXAlignment.Left;
            ZIndex                 = 20;
            Parent                 = HueBoxInner;
        })
        Library:ApplyTextStroke(HueBox)

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5,2,0,230);
            Size     = UDim2.new(0.5,-6,0,20);
            Parent   = PickerFrameInner;
        })
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox') or RgbBoxBase:FindFirstChildWhichIsA('TextBox'), {
            Text            = '255, 255, 255';
            PlaceholderText = 'RGB color';
            TextColor3      = Library.FontColor;
        })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0,0,0);
                Position     = UDim2.fromOffset(4, 253);
                Size         = UDim2.new(1,-8,0,15);
                ZIndex       = 19;
                Parent       = PickerFrameInner;
            })
            Corner(TransparencyBoxOuter, R_SMALL)

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1,0,1,0);
                ZIndex           = 19;
                Parent           = TransparencyBoxOuter;
            })
            Corner(TransparencyBoxInner, R_SMALL)
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' })

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size                   = UDim2.new(1,0,1,0);
                Image                  = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex                 = 20;
                Parent                 = TransparencyBoxInner;
            })

            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1,1,1);
                AnchorPoint      = Vector2.new(0.5,0);
                BorderColor3     = Color3.new(0,0,0);
                Size             = UDim2.new(0,1,1,0);
                ZIndex           = 21;
                Parent           = TransparencyBoxInner;
            })
        end

        local DisplayLabel = Library:CreateLabel({
            Size           = UDim2.new(1,0,0,14);
            Position       = UDim2.fromOffset(5,5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize       = 14;
            Text           = ColorPicker.Title;
            TextWrapped    = false;
            ZIndex         = 16;
            Parent         = PickerFrameInner;
        })

        -- ── Контекстное меню ─────────────────────────────────────────
        local ContextMenu = { Options = {} }
        do
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new();
                ZIndex       = 14;
                Visible      = false;
                Parent       = ScreenGui;
            })
            Corner(ContextMenu.Container, R_SMALL)

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.fromScale(1,1);
                ZIndex           = 15;
                Parent           = ContextMenu.Container;
            })
            Corner(ContextMenu.Inner, R_SMALL)

            Library:Create('UIListLayout', {
                Name            = 'Layout';
                FillDirection   = Enum.FillDirection.Vertical;
                SortOrder       = Enum.SortOrder.LayoutOrder;
                Parent          = ContextMenu.Inner;
            })
            Library:Create('UIPadding', {
                Name        = 'Padding';
                PaddingLeft = UDim.new(0,4);
                Parent      = ContextMenu.Inner;
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end
            local function updateMenuSize()
                local w = 60
                for _, lbl in next, ContextMenu.Inner:GetChildren() do
                    if lbl:IsA('TextLabel') then w = math.max(w, lbl.TextBounds.X) end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(
                    w + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition); task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

            function ContextMenu:Show()  self.Container.Visible = true  end
            function ContextMenu:Hide()  self.Container.Visible = false end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then Callback = function() end end
                local Btn = Library:CreateLabel({
                    Active         = false;
                    Size           = UDim2.new(1,0,0,15);
                    TextSize       = 13;
                    Text           = Str;
                    ZIndex         = 16;
                    Parent         = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left;
                })
                Library:OnHighlight(Btn, Btn, { TextColor3='AccentColor' }, { TextColor3='FontColor' })
                Btn.InputBegan:Connect(function(I)
                    if I.UserInputType == Enum.UserInputType.MouseButton1 then Callback() end
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)
            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('You have not copied a color!', 2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)
            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({
                    math.floor(ColorPicker.Value.R*255),
                    math.floor(ColorPicker.Value.G*255),
                    math.floor(ColorPicker.Value.B*255)
                }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)
        end

        Library:AddToRegistry(PickerFrameInner,  { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
        Library:AddToRegistry(Highlight,         { BackgroundColor3='AccentColor' })
        Library:AddToRegistry(SatVibMapInner,    { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
        Library:AddToRegistry(HueBoxInner,       { BackgroundColor3='MainColor';       BorderColor3='OutlineColor' })
        Library:AddToRegistry(RgbBox,            { TextColor3='FontColor' })
        Library:AddToRegistry(HueBox,            { TextColor3='FontColor' })

        -- Hue gradient
        local seq = {}
        for h = 0, 1, 0.1 do table.insert(seq, ColorSequenceKeypoint.new(h, Color3.fromHSV(h,1,1))) end
        Library:Create('UIGradient', {
            Color    = ColorSequence.new(seq);
            Rotation = 90;
            Parent   = HueSelectorInner;
        })

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local ok, res = pcall(Color3.fromHex, HueBox.Text)
                if ok and typeof(res)=='Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(res)
                end
            end
            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r,g,b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r,g,b))
                end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            self.Value = Color3.fromHSV(self.Hue, self.Sat, self.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
            Library:Create(DisplayFrame, {
                BackgroundColor3    = self.Value;
                BackgroundTransparency = self.Transparency;
                BorderColor3        = Library:GetDarkerColor(self.Value);
            })
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = self.Value
                TransparencyCursor.Position = UDim2.new(1 - self.Transparency, 0, 0, 0)
            end
            CursorOuter.Position = UDim2.new(self.Sat, 0, 1 - self.Vib, 0)
            HueCursor.Position   = UDim2.new(0, 0, self.Hue, 0)
            HueBox.Text = '#' .. self.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(self.Value.R*255),
                math.floor(self.Value.G*255),
                math.floor(self.Value.B*255)
            }, ', ')
            Library:SafeCallback(self.Callback, self.Value)
            Library:SafeCallback(self.Changed,  self.Value)
        end

        function ColorPicker:OnChanged(Func) self.Changed = Func; Func(self.Value) end
        function ColorPicker:Show()
            for Frame in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then Frame.Visible = false; Library.OpenedFrames[Frame] = nil end
            end
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end
        function ColorPicker:SetValue(HSV, Trans)
            self.Transparency = Trans or 0
            self:SetHSVFromRGB(Color3.fromHSV(HSV[1],HSV[2],HSV[3]))
            self:Display()
        end
        function ColorPicker:SetValueRGB(Color, Trans)
            self.Transparency = Trans or 0
            self:SetHSVFromRGB(Color)
            self:Display()
        end

        -- Drag на SatVib
        SatVibMap.InputBegan:Connect(function(I)
            if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local minX = SatVibMap.AbsolutePosition.X
                local maxX = minX + SatVibMap.AbsoluteSize.X
                local minY = SatVibMap.AbsolutePosition.Y
                local maxY = minY + SatVibMap.AbsoluteSize.Y
                ColorPicker.Sat = (math.clamp(Mouse.X,minX,maxX)-minX)/(maxX-minX)
                ColorPicker.Vib = 1-((math.clamp(Mouse.Y,minY,maxY)-minY)/(maxY-minY))
                ColorPicker:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        -- Drag на Hue
        HueSelectorInner.InputBegan:Connect(function(I)
            if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local minY = HueSelectorInner.AbsolutePosition.Y
                local maxY = minY + HueSelectorInner.AbsoluteSize.Y
                ColorPicker.Hue = (math.clamp(Mouse.Y,minY,maxY)-minY)/(maxY-minY)
                ColorPicker:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        DisplayFrame.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then ColorPicker:Hide()
                else ContextMenu:Hide(); ColorPicker:Show() end
            elseif I.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show(); ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(I)
                if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local minX = TransparencyBoxInner.AbsolutePosition.X
                    local maxX = minX + TransparencyBoxInner.AbsoluteSize.X
                    ColorPicker.Transparency = 1-((math.clamp(Mouse.X,minX,maxX)-minX)/(maxX-minX))
                    ColorPicker:Display()
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 then
                local p,s = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                if Mouse.X < p.X or Mouse.X > p.X+s.X
                or Mouse.Y < (p.Y-20-1) or Mouse.Y > p.Y+s.Y then
                    ColorPicker:Hide()
                end
                if not Library:IsMouseOverFrame(ContextMenu.Container) then ContextMenu:Hide() end
            end
            if I.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker
        return self;
    end;

    -- ── KeyPicker ────────────────────────────────────────────────────────
    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj   = self
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local KeyPicker = {
            Value          = Info.Default;
            Toggled        = false;
            Mode           = Info.Mode or 'Toggle';
            Type           = 'KeyPicker';
            Callback       = Info.Callback or function() end;
            ChangedCallback = Info.ChangedCallback or function() end;
            SyncToggleState = Info.SyncToggleState or false;
        }
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }; Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(0,28,0,15);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        })
        Corner(PickOuter, R_SMALL)

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 7;
            Parent           = PickOuter;
        })
        Corner(PickInner, R_SMALL)
        Library:AddToRegistry(PickInner, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

        local DisplayLabel = Library:CreateLabel({
            Size        = UDim2.new(1,0,1,0);
            TextSize    = 13;
            Text        = Info.Default;
            TextWrapped = true;
            ZIndex      = 8;
            Parent      = PickInner;
        })

        -- Попап выбора режима — позиция привязана к AbsolutePosition метки
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position     = UDim2.fromOffset(
                ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
                ToggleLabel.AbsolutePosition.Y + 1
            );
            Size         = UDim2.new(0,60,0,47);
            Visible      = false;
            ZIndex       = 14;
            Parent       = ScreenGui;
        })
        Corner(ModeSelectOuter, R_SMALL)

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(
                ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
                ToggleLabel.AbsolutePosition.Y + 1
            )
        end)

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 15;
            Parent           = ModeSelectOuter;
        })
        Corner(ModeSelectInner, R_SMALL)
        Library:AddToRegistry(ModeSelectInner, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder     = Enum.SortOrder.LayoutOrder;
            Parent        = ModeSelectInner;
        })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size           = UDim2.new(1,0,0,18);
            TextSize       = 13;
            Visible        = false;
            ZIndex         = 110;
            Parent         = Library.KeybindContainer;
        }, true)

        local Modes      = Info.Modes or { 'Always','Toggle','Hold' }
        local ModeButtons = {}

        for _, Mode in next, Modes do
            local MB = {}
            local Lbl = Library:CreateLabel({
                Active   = false;
                Size     = UDim2.new(1,0,0,15);
                TextSize = 13;
                Text     = Mode;
                ZIndex   = 16;
                Parent   = ModeSelectInner;
            })
            function MB:Select()
                for _, b in next, ModeButtons do b:Deselect() end
                KeyPicker.Mode = Mode
                Lbl.TextColor3 = Library.AccentColor
                Library.RegistryMap[Lbl].Properties.TextColor3 = 'AccentColor'
                ModeSelectOuter.Visible = false
            end
            function MB:Deselect()
                KeyPicker.Mode = nil
                Lbl.TextColor3 = Library.FontColor
                Library.RegistryMap[Lbl].Properties.TextColor3 = 'FontColor'
            end
            Lbl.InputBegan:Connect(function(I)
                if I.UserInputType == Enum.UserInputType.MouseButton1 then
                    MB:Select(); Library:AttemptSave()
                end
            end)
            if Mode == KeyPicker.Mode then MB:Select() end
            ModeButtons[Mode] = MB
        end

        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = self:GetState()
            ContainerLabel.Text    = string.format('[%s] %s (%s)', self.Value, Info.Text, self.Mode)
            ContainerLabel.Visible = self.Value ~= 'None'
            ContainerLabel.TextColor3 = State
                and Library.AccentColor:Lerp(Color3.new(1,1,1), 0.20)
                or  Library.AccentColor:Lerp(Color3.new(0,0,0), 0.35)
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = function()
                return self:GetState()
                    and Library.AccentColor:Lerp(Color3.new(1,1,1),0.20)
                    or  Library.AccentColor:Lerp(Color3.new(0,0,0),0.35)
            end
            local Ysize, Xsize = 0, 0
            for _, lbl in next, Library.KeybindContainer:GetChildren() do
                if lbl:IsA('TextLabel') and lbl.Visible then
                    Ysize = Ysize + 18
                    if lbl.TextBounds.X > Xsize then Xsize = lbl.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(Xsize+10,210), 0, Ysize+23)
        end

        function KeyPicker:GetState()
            if self.Mode == 'Always' then return true end
            if self.Mode == 'Hold' then
                if self.Value == 'None' then return false end
                local k = self.Value
                if k=='MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                if k=='MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                return InputService:IsKeyDown(Enum.KeyCode[k])
            end
            return self.Toggled
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]
            DisplayLabel.Text = Key
            self.Value = Key
            ModeButtons[Mode]:Select()
            self:Update()
        end

        function KeyPicker:OnClick(cb)    self.Clicked  = cb end
        function KeyPicker:OnChanged(cb)  self.Changed  = cb; cb(self.Value) end

        if ParentObj.Addons then table.insert(ParentObj.Addons, KeyPicker) end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and self.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(self.Callback, self.Toggled)
            Library:SafeCallback(self.Clicked,  self.Toggled)
        end

        local Picking = false
        PickOuter.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true
                DisplayLabel.Text = ''
                local Break, Text = false, ''
                task.spawn(function()
                    while not Break do
                        if Text == '...' then Text = '' end
                        Text = Text .. '.'; DisplayLabel.Text = Text
                        wait(0.4)
                    end
                end)
                wait(0.2)
                local Ev
                Ev = InputService.InputBegan:Connect(function(I2)
                    local Key
                    if I2.UserInputType == Enum.UserInputType.Keyboard then Key = I2.KeyCode.Name
                    elseif I2.UserInputType == Enum.UserInputType.MouseButton1 then Key = 'MB1'
                    elseif I2.UserInputType == Enum.UserInputType.MouseButton2 then Key = 'MB2' end
                    Break = true; Picking = false
                    DisplayLabel.Text = Key; KeyPicker.Value = Key
                    Library:SafeCallback(KeyPicker.ChangedCallback, I2.KeyCode or I2.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed,         I2.KeyCode or I2.UserInputType)
                    Library:AttemptSave()
                    Ev:Disconnect()
                end)
            elseif I.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(I)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local k = KeyPicker.Value
                    if k=='MB1' or k=='MB2' then
                        if (k=='MB1' and I.UserInputType==Enum.UserInputType.MouseButton1)
                        or (k=='MB2' and I.UserInputType==Enum.UserInputType.MouseButton2) then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif I.UserInputType == Enum.UserInputType.Keyboard then
                        if I.KeyCode.Name == k then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    end
                end
                KeyPicker:Update()
            end
            if I.UserInputType == Enum.UserInputType.MouseButton1 then
                local p,s = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X<p.X or Mouse.X>p.X+s.X or Mouse.Y<(p.Y-20-1) or Mouse.Y>p.Y+s.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function()
            if not Picking then KeyPicker:Update() end
        end))

        KeyPicker:Update()
        Options[Idx] = KeyPicker
        return self;
    end;

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(T, K, ...) return Funcs[K](...) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  BASE GROUPBOX
-- ═══════════════════════════════════════════════════════════════════════

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size                   = UDim2.new(1,0,0,Size);
            ZIndex                 = 1;
            Parent                 = self.Container;
        })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local Container = self.Container

        local TextLabel = Library:CreateLabel({
            Size           = UDim2.new(1,-4,0,15);
            TextSize       = 14;
            Text           = Text;
            TextWrapped    = DoesWrap or false;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = Container;
        })

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1,-4,0,Y)
        else
            Library:Create('UIListLayout', {
                Padding              = UDim.new(0,4);
                FillDirection        = Enum.FillDirection.Horizontal;
                HorizontalAlignment  = Enum.HorizontalAlignment.Right;
                SortOrder            = Enum.SortOrder.LayoutOrder;
                Parent               = TextLabel;
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(T)
            TextLabel.Text = T
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(T, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1,-4,0,Y)
            end
            self:Resize()
        end

        if not DoesWrap then setmetatable(Label, BaseAddons) end

        self:AddBlank(5)
        self:Resize()
        return Label;
    end

    function Funcs:AddButton(...)
        local Button = {}

        local function ProcessParams(Obj, ...)
            local P = select(1,...)
            if type(P) == 'table' then
                Obj.Text = P.Text; Obj.Func = P.Func
                Obj.DoubleClick = P.DoubleClick; Obj.Tooltip = P.Tooltip
            else
                Obj.Text = select(1,...); Obj.Func = select(2,...)
            end
            assert(type(Obj.Func)=='function','AddButton: `Func` callback is missing.')
        end
        ProcessParams(Button, ...)

        local Container = self.Container

        local function CreateBaseButton(Btn)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0,0,0);
                BorderColor3     = Color3.new(0,0,0);
                Size             = UDim2.new(1,-4,0,20);
                ZIndex           = 5;
            })
            Corner(Outer, R_ELEMENT)

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1,0,1,0);
                ZIndex           = 6;
                Parent           = Outer;
            })
            Corner(Inner, R_ELEMENT)

            local Lbl = Library:CreateLabel({
                Size     = UDim2.new(1,0,1,0);
                TextSize = 14;
                Text     = Btn.Text;
                ZIndex   = 6;
                Parent   = Inner;
            })

            Library:Create('UIGradient', {
                Color    = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212))
                });
                Rotation = 90;
                Parent   = Inner;
            })

            Library:AddToRegistry(Outer, { BorderColor3='Black' })
            Library:AddToRegistry(Inner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
            Library:OnHighlight(Outer, Outer, { BorderColor3='AccentColor' }, { BorderColor3='Black' })

            return Outer, Inner, Lbl
        end

        local function InitEvents(Btn)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local conn = event:Once(function(...)
                    bindable:Fire(validator and validator(...) or true)
                end)
                task.delay(timeout, function() conn:Disconnect(); bindable:Fire(false) end)
                return bindable.Event:Wait()
            end
            local function ValidateClick(I)
                return not Library:MouseIsOverOpenedFrame()
                    and I.UserInputType == Enum.UserInputType.MouseButton1
            end
            Btn.Outer.InputBegan:Connect(function(I)
                if not ValidateClick(I) or Btn.Locked then return end
                if Btn.DoubleClick then
                    Library:RemoveFromRegistry(Btn.Label)
                    Library:AddToRegistry(Btn.Label, { TextColor3='AccentColor' })
                    Btn.Label.TextColor3 = Library.AccentColor
                    Btn.Label.Text = 'Are you sure?'
                    Btn.Locked = true
                    local clicked = WaitForEvent(Btn.Outer.InputBegan, 0.5, ValidateClick)
                    Library:RemoveFromRegistry(Btn.Label)
                    Library:AddToRegistry(Btn.Label, { TextColor3='FontColor' })
                    Btn.Label.TextColor3 = Library.FontColor
                    Btn.Label.Text = Btn.Text
                    task.defer(rawset, Btn, 'Locked', false)
                    if clicked then Library:SafeCallback(Btn.Func) end
                    return
                end
                Library:SafeCallback(Btn.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container
        InitEvents(Button)

        function Button:AddTooltip(tip)
            if type(tip)=='string' then Library:AddToolTip(tip, self.Outer) end
            return self
        end

        function Button:AddButton(...)
            local Sub = {}
            ProcessParams(Sub, ...)
            self.Outer.Size = UDim2.new(0.5,-2,0,20)
            Sub.Outer, Sub.Inner, Sub.Label = CreateBaseButton(Sub)
            Sub.Outer.Position = UDim2.new(1,3,0,0)
            Sub.Outer.Size     = UDim2.fromOffset(self.Outer.AbsoluteSize.X-2, self.Outer.AbsoluteSize.Y)
            Sub.Outer.Parent   = self.Outer
            function Sub:AddTooltip(tip)
                if type(tip)=='string' then Library:AddToolTip(tip, self.Outer) end
                return Sub
            end
            if type(Sub.Tooltip)=='string' then Sub:AddTooltip(Sub.Tooltip) end
            InitEvents(Sub)
            return Sub
        end

        if type(Button.Tooltip)=='string' then Button:AddTooltip(Button.Tooltip) end
        self:AddBlank(5); self:Resize()
        return Button;
    end

    function Funcs:AddDivider()
        self:AddBlank(2)
        local Outer = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(1,-4,0,5);
            ZIndex           = 5;
            Parent           = self.Container;
        })
        Corner(Outer, R_SMALL)
        local Inner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 6;
            Parent           = Outer;
        })
        Corner(Inner, R_SMALL)
        Library:AddToRegistry(Outer, { BorderColor3='Black' })
        Library:AddToRegistry(Inner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        self:AddBlank(9); self:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value   = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type    = 'Input';
            Callback = Info.Callback or function() end;
        }

        local Container = self.Container

        Library:CreateLabel({
            Size           = UDim2.new(1,0,0,15);
            TextSize       = 14;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = Container;
        })
        self:AddBlank(1)

        local TBOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(1,-4,0,20);
            ZIndex           = 5;
            Parent           = Container;
        })
        Corner(TBOuter, R_ELEMENT)

        local TBInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 6;
            Parent           = TBOuter;
        })
        Corner(TBInner, R_ELEMENT)
        Library:AddToRegistry(TBInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        Library:OnHighlight(TBOuter, TBOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, TBOuter) end

        Library:Create('UIGradient', {
            Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212))
            });
            Rotation = 90;
            Parent   = TBInner;
        })

        local ClipFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants       = true;
            Position               = UDim2.new(0,5,0,0);
            Size                   = UDim2.new(1,-5,1,0);
            ZIndex                 = 7;
            Parent                 = TBInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position               = UDim2.fromOffset(0,0);
            Size                   = UDim2.fromScale(5,1);
            Font                   = Library.Font;
            PlaceholderColor3      = Color3.fromRGB(190,190,190);
            PlaceholderText        = Info.Placeholder or '';
            Text                   = Info.Default or '';
            TextColor3             = Library.FontColor;
            TextSize               = 14;
            TextStrokeTransparency = 0;
            TextXAlignment         = Enum.TextXAlignment.Left;
            ZIndex                 = 7;
            Parent                 = ClipFrame;
        })
        Library:ApplyTextStroke(Box)

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1,Info.MaxLength) end
            if self.Numeric and not tonumber(Text) and #Text > 0 then Text = self.Value end
            self.Value = Text; Box.Text = Text
            Library:SafeCallback(self.Callback, self.Value)
            Library:SafeCallback(self.Changed,  self.Value)
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text); Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text); Library:AttemptSave()
            end)
        end

        -- Cursor follow logic
        local function Update()
            local PADDING = 2
            local reveal  = ClipFrame.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= reveal-2*PADDING then
                Box.Position = UDim2.new(0,PADDING,0,0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local sub   = string.sub(Box.Text,1,cursor-1)
                    local width = TextService:GetTextSize(sub, Box.TextSize, Box.Font, Vector2.new(math.huge,math.huge)).X
                    local cur   = Box.Position.X.Offset + width
                    if cur < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width,0)
                    elseif cur > reveal-PADDING-1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1,0)
                    end
                end
            end
        end
        task.spawn(Update)
        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update); Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, { TextColor3='FontColor' })

        function Textbox:OnChanged(Func) self.Changed = Func; Func(self.Value) end

        self:AddBlank(5); self:Resize()
        Options[Idx] = Textbox
        return Textbox;
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value    = Info.Default or false;
            Type     = 'Toggle';
            Callback = Info.Callback or function() end;
            Addons   = {};
            Risky    = Info.Risky;
        }

        local Container = self.Container

        local TOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(0,13,0,13);
            ZIndex           = 5;
            Parent           = Container;
        })
        Corner(TOuter, R_SMALL)
        Library:AddToRegistry(TOuter, { BorderColor3='Black' })

        local TInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 6;
            Parent           = TOuter;
        })
        Corner(TInner, R_SMALL)
        Library:AddToRegistry(TInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

        local TLabel = Library:CreateLabel({
            Size           = UDim2.new(0,216,1,0);
            Position       = UDim2.new(1,6,0,0);
            TextSize       = 14;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 6;
            Parent         = TInner;
        })
        Library:Create('UIListLayout', {
            Padding             = UDim.new(0,4);
            FillDirection       = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder           = Enum.SortOrder.LayoutOrder;
            Parent              = TLabel;
        })

        local TRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size                   = UDim2.new(0,170,1,0);
            ZIndex                 = 8;
            Parent                 = TOuter;
        })
        Library:OnHighlight(TRegion, TOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })

        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, TRegion) end

        function Toggle:UpdateColors() self:Display() end
        function Toggle:Display()
            TInner.BackgroundColor3 = self.Value and Library.AccentColor or Library.MainColor
            TInner.BorderColor3     = self.Value and Library.AccentColorDark or Library.OutlineColor
            Library.RegistryMap[TInner].Properties.BackgroundColor3 = self.Value and 'AccentColor' or 'MainColor'
            Library.RegistryMap[TInner].Properties.BorderColor3     = self.Value and 'AccentColorDark' or 'OutlineColor'
        end
        function Toggle:OnChanged(Func) self.Changed = Func; Func(self.Value) end
        function Toggle:SetValue(Bool)
            Bool = not not Bool
            self.Value = Bool; self:Display()
            for _, Addon in next, self.Addons do
                if Addon.Type=='KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool; Addon:Update()
                end
            end
            Library:SafeCallback(self.Callback, self.Value)
            Library:SafeCallback(self.Changed,  self.Value)
            Library:UpdateDependencyBoxes()
        end

        TRegion.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value); Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(TLabel)
            TLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(TLabel, { TextColor3='RiskColor' })
        end

        Toggle:Display()
        self:AddBlank(Info.BlankSize or 7)
        self:Resize()

        Toggle.TextLabel = TLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Idx] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle;
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default,  'AddSlider: Missing default value.')
        assert(Info.Text,     'AddSlider: Missing slider text.')
        assert(Info.Min,      'AddSlider: Missing minimum value.')
        assert(Info.Max,      'AddSlider: Missing maximum value.')
        assert(Info.Rounding, 'AddSlider: Missing rounding value.')

        local Slider = {
            Value   = Info.Default;
            Min     = Info.Min;
            Max     = Info.Max;
            Rounding = Info.Rounding;
            MaxSize  = 380;
            Type     = 'Slider';
            Callback = Info.Callback or function() end;
        }

        local Container = self.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size           = UDim2.new(1,0,0,10);
                TextSize       = 14;
                Text           = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex         = 5;
                Parent         = Container;
            })
            self:AddBlank(3)
        end

        local SOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(1,-4,0,13);
            ZIndex           = 5;
            Parent           = Container;
        })
        Corner(SOuter, R_ELEMENT)
        Library:AddToRegistry(SOuter, { BorderColor3='Black' })

        local SInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 6;
            Parent           = SOuter;
        })
        Corner(SInner, R_ELEMENT)
        Library:AddToRegistry(SInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3     = Library.AccentColorDark;
            Size             = UDim2.new(0,0,1,0);
            ZIndex           = 7;
            Parent           = SInner;
        })
        Corner(Fill, R_ELEMENT)
        Library:AddToRegistry(Fill, { BackgroundColor3='AccentColor'; BorderColor3='AccentColorDark' })

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Position         = UDim2.new(1,0,0,0);
            Size             = UDim2.new(0,1,1,0);
            ZIndex           = 8;
            Parent           = Fill;
        })
        Library:AddToRegistry(HideBorderRight, { BackgroundColor3='AccentColor' })

        local DisplayLabel = Library:CreateLabel({
            Size     = UDim2.new(1,0,1,0);
            TextSize = 14;
            Text     = '';
            ZIndex   = 9;
            Parent   = SInner;
        })

        Library:OnHighlight(SOuter, SOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, SOuter) end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor
            Fill.BorderColor3     = Library.AccentColorDark
        end

        function Slider:Display()
            local suf = Info.Suffix or ''
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. self.Value .. suf
            elseif Info.HideMax then
                DisplayLabel.Text = self.Value .. suf
            else
                DisplayLabel.Text = string.format('%s/%s', self.Value..suf, self.Max..suf)
            end
            local X = math.ceil(Library:MapValue(self.Value, self.Min, self.Max, 0, self.MaxSize))
            Fill.Size = UDim2.new(0, X, 1, 0)
            HideBorderRight.Visible = not (X == self.MaxSize or X == 0)
        end

        function Slider:OnChanged(Func) self.Changed = Func; Func(self.Value) end

        local function Round(V)
            if Slider.Rounding == 0 then return math.floor(V) end
            return tonumber(string.format('%.'..Slider.Rounding..'f', V))
        end

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, self.MaxSize, self.Min, self.Max))
        end

        function Slider:SetValue(Str)
            local Num = tonumber(Str)
            if not Num then return end
            Num = math.clamp(Num, self.Min, self.Max)
            self.Value = Num; self:Display()
            Library:SafeCallback(self.Callback, self.Value)
            Library:SafeCallback(self.Changed,  self.Value)
        end

        SInner.InputBegan:Connect(function(I)
            if I.UserInputType ~= Enum.UserInputType.MouseButton1 or Library:MouseIsOverOpenedFrame() then return end
            local mPos = Mouse.X
            local gPos = Fill.Size.X.Offset
            local Diff = mPos - (Fill.AbsolutePosition.X + gPos)
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nX  = math.clamp(gPos + (Mouse.X - mPos) + Diff, 0, Slider.MaxSize)
                local nVal = Slider:GetValueFromXOffset(nX)
                local old  = Slider.Value
                Slider.Value = nVal; Slider:Display()
                if nVal ~= old then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed,  Slider.Value)
                end
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        Slider:Display()
        self:AddBlank(Info.BlankSize or 6)
        self:Resize()
        Options[Idx] = Slider
        return Slider;
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString(); Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString(); Info.AllowNull = true
        end

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value.')
        if not Info.Text then Info.Compact = true end

        local Dropdown = {
            Values      = Info.Values;
            Value       = Info.Multi and {};
            Multi       = Info.Multi;
            Type        = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback    = Info.Callback or function() end;
        }

        local Container = self.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size           = UDim2.new(1,0,0,10);
                TextSize       = 14;
                Text           = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex         = 5;
                Parent         = Container;
            })
            self:AddBlank(3)
        end

        local DOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            Size             = UDim2.new(1,-4,0,20);
            ZIndex           = 5;
            Parent           = Container;
        })
        Corner(DOuter, R_ELEMENT)
        Library:AddToRegistry(DOuter, { BorderColor3='Black' })

        local DInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 6;
            Parent           = DOuter;
        })
        Corner(DInner, R_ELEMENT)
        Library:AddToRegistry(DInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

        Library:Create('UIGradient', {
            Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212))
            });
            Rotation = 90;
            Parent   = DInner;
        })

        Library:Create('ImageLabel', {
            AnchorPoint        = Vector2.new(0,0.5);
            BackgroundTransparency = 1;
            Position           = UDim2.new(1,-16,0.5,0);
            Size               = UDim2.new(0,12,0,12);
            Image              = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex             = 8;
            Parent             = DInner;
        })

        local ItemList = Library:CreateLabel({
            Position       = UDim2.new(0,5,0,0);
            Size           = UDim2.new(1,-5,1,0);
            TextSize       = 14;
            Text           = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped    = true;
            ZIndex         = 7;
            Parent         = DInner;
        })

        Library:OnHighlight(DOuter, DOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, DOuter) end

        local MAX_ITEMS = 8

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderColor3     = Color3.new(0,0,0);
            ZIndex           = 20;
            Visible          = false;
            Parent           = ScreenGui;
        })
        Corner(ListOuter, R_ELEMENT)

        local function RecalcPos()
            ListOuter.Position = UDim2.fromOffset(DOuter.AbsolutePosition.X, DOuter.AbsolutePosition.Y + DOuter.Size.Y.Offset + 1)
        end
        local function RecalcSize(Y)
            ListOuter.Size = UDim2.fromOffset(DOuter.AbsoluteSize.X, Y or (MAX_ITEMS*20+2))
        end
        RecalcPos(); RecalcSize()
        DOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalcPos)

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3     = Library.OutlineColor;
            BorderMode       = Enum.BorderMode.Inset;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1,0,1,0);
            ZIndex           = 21;
            Parent           = ListOuter;
        })
        Corner(ListInner, R_ELEMENT)
        Library:AddToRegistry(ListInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            CanvasSize             = UDim2.new(0,0,0,0);
            Size                   = UDim2.new(1,0,1,0);
            ZIndex                 = 21;
            Parent                 = ListInner;
            TopImage               = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage            = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness     = 3;
            ScrollBarImageColor3   = Library.AccentColor;
        })
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3='AccentColor' })
        Library:Create('UIListLayout', {
            Padding       = UDim.new(0,0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder     = Enum.SortOrder.LayoutOrder;
            Parent        = Scrolling;
        })

        function Dropdown:Display()
            local Str = ''
            if Info.Multi then
                for _, v in next, self.Values do
                    if self.Value[v] then Str = Str .. v .. ', ' end
                end
                Str = Str:sub(1, #Str-2)
            else
                Str = self.Value or ''
            end
            ItemList.Text = Str == '' and '--' or Str
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local n = 0; for _ in next, self.Value do n=n+1 end; return n
            else
                return self.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            for _, c in next, Scrolling:GetChildren() do
                if not c:IsA('UIListLayout') then c:Destroy() end
            end
            local Buttons = {}
            local Count   = 0

            for _, Value in next, self.Values do
                Count = Count + 1
                local T = {}

                local Btn = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3     = Library.OutlineColor;
                    BorderMode       = Enum.BorderMode.Middle;
                    Size             = UDim2.new(1,-1,0,20);
                    ZIndex           = 23;
                    Active           = true;
                    Parent           = Scrolling;
                })
                Corner(Btn, R_SMALL)
                Library:AddToRegistry(Btn, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

                local BtnLbl = Library:CreateLabel({
                    Active         = false;
                    Size           = UDim2.new(1,-6,1,0);
                    Position       = UDim2.new(0,6,0,0);
                    TextSize       = 14;
                    Text           = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex         = 25;
                    Parent         = Btn;
                })
                Library:OnHighlight(Btn, Btn,
                    { BorderColor3='AccentColor', ZIndex=24 },
                    { BorderColor3='OutlineColor', ZIndex=23 }
                )

                local Selected = Info.Multi and Dropdown.Value[Value] or Dropdown.Value == Value

                function T:UpdateButton()
                    Selected = Info.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
                    BtnLbl.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[BtnLbl].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor'
                end

                BtnLbl.InputBegan:Connect(function(I)
                    if I.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local Try = not Selected
                    if Dropdown:GetActiveValues()==1 and not Try and not Info.AllowNull then return end
                    if Info.Multi then
                        Selected = Try
                        Dropdown.Value[Value] = Try or nil
                    else
                        Selected = Try
                        Dropdown.Value = Try and Value or nil
                        for _, OB in next, Buttons do OB:UpdateButton() end
                    end
                    T:UpdateButton(); Dropdown:Display()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed,  Dropdown.Value)
                    Library:AttemptSave()
                end)

                T:UpdateButton(); Dropdown:Display()
                Buttons[Btn] = T
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, Count*20+1)
            RecalcSize(math.clamp(Count*20, 0, MAX_ITEMS*20)+1)
        end

        function Dropdown:SetValues(V)
            if V then self.Values = V end
            self:BuildDropdownList()
        end
        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
        end
        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
        end
        function Dropdown:OnChanged(Func) self.Changed = Func; Func(self.Value) end
        function Dropdown:SetValue(Val)
            if self.Multi then
                local nT = {}
                for V in next, Val do
                    if table.find(self.Values, V) then nT[V] = true end
                end
                self.Value = nT
            else
                self.Value = (not Val) and nil or (table.find(self.Values, Val) and Val or self.Value)
            end
            self:BuildDropdownList()
            Library:SafeCallback(self.Callback, self.Value)
            Library:SafeCallback(self.Changed,  self.Value)
        end

        DOuter.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown() else Dropdown:OpenDropdown() end
            end
        end)
        InputService.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 then
                local p,s = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X<p.X or Mouse.X>p.X+s.X or Mouse.Y<(p.Y-20-1) or Mouse.Y>p.Y+s.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList(); Dropdown:Display()

        -- Default values
        local Defaults = {}
        if type(Info.Default)=='string' then
            local i = table.find(Dropdown.Values, Info.Default)
            if i then table.insert(Defaults, i) end
        elseif type(Info.Default)=='table' then
            for _, V in next, Info.Default do
                local i = table.find(Dropdown.Values, V)
                if i then table.insert(Defaults, i) end
            end
        elseif type(Info.Default)=='number' and Dropdown.Values[Info.Default] then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for _, i in next, Defaults do
                if Info.Multi then Dropdown.Value[Dropdown.Values[i]] = true
                else Dropdown.Value = Dropdown.Values[i]; break end
            end
            Dropdown:BuildDropdownList(); Dropdown:Display()
        end

        self:AddBlank(Info.BlankSize or 5)
        self:Resize()
        Options[Idx] = Dropdown
        return Dropdown;
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local Container = self.Container

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size                   = UDim2.new(1,0,0,0);
            Visible                = false;
            Parent                 = Container;
        })
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size                   = UDim2.new(1,0,1,0);
            Parent                 = Holder;
        })
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder     = Enum.SortOrder.LayoutOrder;
            Parent        = Frame;
        })

        local Groupbox = self
        function Depbox:Resize()
            Holder.Size = UDim2.new(1,0,0,Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)

        function Depbox:Update()
            for _, Dep in next, self.Dependencies do
                local Elem, Val = Dep[1], Dep[2]
                if Elem.Type=='Toggle' and Elem.Value ~= Val then
                    Holder.Visible = false; self:Resize(); return
                end
            end
            Holder.Visible = true; self:Resize()
        end

        function Depbox:SetupDependencies(Deps)
            for _, D in next, Deps do
                assert(type(D)=='table', 'SetupDependencies: not a table')
                assert(D[1],            'SetupDependencies: missing element')
                assert(D[2]~=nil,       'SetupDependencies: missing value')
            end
            self.Dependencies = Deps; self:Update()
        end

        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox;
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(T,K,...) return Funcs[K](...) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  NOTIFICATIONS, WATERMARK, KEYBIND FRAME
-- ═══════════════════════════════════════════════════════════════════════
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position               = UDim2.new(0,0,0,40);
        Size                   = UDim2.new(0,300,0,200);
        ZIndex                 = 100;
        Parent                 = ScreenGui;
    })
    Library:Create('UIListLayout', {
        Padding       = UDim.new(0,4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = Library.NotificationArea;
    })

    -- Watermark
    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0,0,0);
        Position     = UDim2.new(0,100,0,-25);
        Size         = UDim2.new(0,213,0,20);
        ZIndex       = 200;
        Visible      = false;
        Parent       = ScreenGui;
    })
    Corner(WatermarkOuter, R_SMALL)

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.AccentColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 201;
        Parent           = WatermarkOuter;
    })
    Corner(WatermarkInner, R_SMALL)
    Library:AddToRegistry(WatermarkInner, { BorderColor3='AccentColor' })

    local WatermarkInnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1,1,1);
        BorderSizePixel  = 0;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 202;
        Parent           = WatermarkInner;
    })
    Corner(WatermarkInnerFrame, R_SMALL)

    local WatermarkGradient = Library:Create('UIGradient', {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent   = WatermarkInnerFrame;
    })
    Library:AddToRegistry(WatermarkGradient, { Color = function()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        })
    end })

    local WatermarkLabel = Library:CreateLabel({
        Position       = UDim2.new(0,5,0,0);
        Size           = UDim2.new(1,-4,1,0);
        TextSize       = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 253;
        Parent         = WatermarkInnerFrame;
    })

    Library.Watermark     = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    -- Keybind frame
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint  = Vector2.new(0,0.5);
        BorderColor3 = Color3.new(0,0,0);
        Position     = UDim2.new(0,10,0.5,0);
        Size         = UDim2.new(0,210,0,20);
        Visible      = false;
        ZIndex       = 100;
        Parent       = ScreenGui;
    })
    Corner(KeybindOuter, R_SMALL)

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 101;
        Parent           = KeybindOuter;
    })
    Corner(KeybindInner, R_SMALL)
    Library:AddToRegistry(KeybindInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' }, true)

    local KeybindColorBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1,0,0,2);
        ZIndex           = 102;
        Parent           = KeybindInner;
    })
    Library:AddToRegistry(KeybindColorBar, { BackgroundColor3='AccentColor' }, true)

    Library:CreateLabel({
        Size           = UDim2.new(1,0,0,20);
        Position       = UDim2.fromOffset(5,2);
        TextXAlignment = Enum.TextXAlignment.Left;
        Text           = 'Keybinds';
        ZIndex         = 104;
        Parent         = KeybindInner;
    })

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size                   = UDim2.new(1,0,1,-20);
        Position               = UDim2.new(0,0,0,20);
        ZIndex                 = 1;
        Parent                 = KeybindInner;
    })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = KeybindContainer;
    })
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0,5);
        Parent      = KeybindContainer;
    })

    Library.KeybindFrame     = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool
end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
    Library.Watermark.Size = UDim2.new(0, X+15, 0, (Y*1.5)+3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14)
    YSize = YSize + 7

    local NOut = Library:Create('Frame', {
        BorderColor3     = Color3.new(0,0,0);
        Position         = UDim2.new(0,100,0,10);
        Size             = UDim2.new(0,0,0,YSize);
        ClipsDescendants = true;
        ZIndex           = 100;
        Parent           = Library.NotificationArea;
    })
    Corner(NOut, R_NOTIFY)

    local NInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 101;
        Parent           = NOut;
    })
    Corner(NInner, R_NOTIFY)
    Library:AddToRegistry(NInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' }, true)

    local NInnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1,1,1);
        BorderSizePixel  = 0;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 102;
        Parent           = NInner;
    })
    Corner(NInnerFrame, R_NOTIFY)

    local NanGrad = Library:Create('UIGradient', {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent   = NInnerFrame;
    })
    Library:AddToRegistry(NanGrad, { Color = function()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        })
    end })

    Library:CreateLabel({
        Position       = UDim2.new(0,8,0,0);
        Size           = UDim2.new(1,-8,1,0);
        Text           = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize       = 14;
        ZIndex         = 103;
        Parent         = NInnerFrame;
    })

    Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0,-1,0,-1);
        Size             = UDim2.new(0,3,1,2);
        ZIndex           = 104;
        Parent           = NOut;
    })

    pcall(NOut.TweenSize, NOut, UDim2.new(0, XSize+8+4, 0, YSize), 'Out', 'Quad', 0.4, true)

    task.spawn(function()
        wait(Time or 5)
        pcall(NOut.TweenSize, NOut, UDim2.new(0,0,0,YSize), 'Out','Quad',0.4,true)
        wait(0.4)
        NOut:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
--  CreateWindow  (главное — динамичные размеры скроллов)
-- ═══════════════════════════════════════════════════════════════════════
function Library:CreateWindow(...)
    local Args   = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...
    else
        Config.Title    = Args[1]
        Config.AutoShow = Args[2] or false
    end

    if type(Config.Title)       ~= 'string' then Config.Title       = 'No title' end
    if type(Config.TabPadding)  ~= 'number' then Config.TabPadding  = 0 end
    if type(Config.MenuFadeTime)~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size)     ~= 'UDim2' then Config.Size     = UDim2.fromOffset(900, 540) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position    = UDim2.fromScale(0.5, 0.5)
    end

    local Window = { Tabs = {} }

    local Outer = Library:Create('Frame', {
        AnchorPoint      = Config.AnchorPoint;
        BackgroundColor3 = Color3.new(0,0,0);
        BorderSizePixel  = 0;
        Position         = Config.Position;
        Size             = Config.Size;
        Visible          = false;
        ZIndex           = 1;
        Parent           = ScreenGui;
    })
    Corner(Outer, R_WINDOW)
    Library:MakeDraggable(Outer, 25)

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.AccentColor;
        BorderMode       = Enum.BorderMode.Inset;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 1;
        Parent           = Outer;
    })
    Corner(Inner, R_WINDOW)
    Library:AddToRegistry(Inner, { BackgroundColor3='MainColor'; BorderColor3='AccentColor' })

    local WindowLabel = Library:CreateLabel({
        Position       = UDim2.new(0,7,0,0);
        Size           = UDim2.new(0,0,0,25);
        Text           = Config.Title;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 1;
        Parent         = Inner;
    })

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3     = Library.OutlineColor;
        Position         = UDim2.new(0,8,0,25);
        Size             = UDim2.new(1,-16,1,-33);
        ZIndex           = 1;
        Parent           = Inner;
    })
    Corner(MainSectionOuter, R_WINDOW)
    Library:AddToRegistry(MainSectionOuter, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3     = Color3.new(0,0,0);
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 1;
        Parent           = MainSectionOuter;
    })
    Corner(MainSectionInner, R_WINDOW)
    Library:AddToRegistry(MainSectionInner, { BackgroundColor3='BackgroundColor' })

    -- Tab area (горизонтальные кнопки вкладок)
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position               = UDim2.new(0,8,0,8);
        Size                   = UDim2.new(1,-16,0,21);
        ZIndex                 = 1;
        Parent                 = MainSectionInner;
    })
    local TabListLayout = Library:Create('UIListLayout', {
        Padding       = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = TabArea;
    })

    -- TabContainer — занимает всё пространство ниже TabArea
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        Position         = UDim2.new(0,8,0,30);
        Size             = UDim2.new(1,-16,1,-38);   -- динамично относительно окна
        ZIndex           = 2;
        Parent           = MainSectionInner;
    })
    Corner(TabContainer, R_ELEMENT)
    Library:AddToRegistry(TabContainer, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

    function Window:SetWindowTitle(Title) WindowLabel.Text = Title end

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}; Tabboxes = {} }

        local TBW = Library:GetTextBounds(Name, Library.Font, 16)

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3     = Library.OutlineColor;
            Size             = UDim2.new(0, TBW+12, 1, 0);
            ZIndex           = 1;
            Parent           = TabArea;
        })
        Corner(TabButton, R_SMALL)
        Library:AddToRegistry(TabButton, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

        Library:CreateLabel({
            Position = UDim2.new(0,0,0,0);
            Size     = UDim2.new(1,0,1,-1);
            Text     = Name;
            ZIndex   = 1;
            Parent   = TabButton;
        })

        local Blocker = Library:Create('Frame', {
            BackgroundColor3    = Library.MainColor;
            BorderSizePixel     = 0;
            Position            = UDim2.new(0,0,1,0);
            Size                = UDim2.new(1,0,0,1);
            BackgroundTransparency = 1;
            ZIndex              = 3;
            Parent              = TabButton;
        })
        Library:AddToRegistry(Blocker, { BackgroundColor3='MainColor' })

        local TabFrame = Library:Create('Frame', {
            Name                   = 'TabFrame';
            BackgroundTransparency = 1;
            Size                   = UDim2.new(1,0,1,0);
            Visible                = false;
            ZIndex                 = 2;
            Parent                 = TabContainer;
        })

        -- ── LeftSide / RightSide — ПОЛНОСТЬЮ динамичные размеры ───────
        -- Высота = TabContainer.Size.Y.Scale=1, не хардкодим пиксели!
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            Position               = UDim2.new(0, 7, 0, 7);
            Size                   = UDim2.new(0.5, -11, 1, -14);
            CanvasSize             = UDim2.new(0,0,0,0);
            BottomImage            = '';
            TopImage               = '';
            ScrollBarThickness     = 0;
            ZIndex                 = 2;
            Parent                 = TabFrame;
        })

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            Position               = UDim2.new(0.5, 4, 0, 7);
            Size                   = UDim2.new(0.5, -11, 1, -14);
            CanvasSize             = UDim2.new(0,0,0,0);
            BottomImage            = '';
            TopImage               = '';
            ScrollBarThickness     = 0;
            ZIndex                 = 2;
            Parent                 = TabFrame;
        })

        for _, Side in next, { LeftSide, RightSide } do
            Library:Create('UIListLayout', {
                Padding              = UDim.new(0,8);
                FillDirection        = Enum.FillDirection.Vertical;
                SortOrder            = Enum.SortOrder.LayoutOrder;
                HorizontalAlignment  = Enum.HorizontalAlignment.Center;
                Parent               = Side;
            })
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, T in next, Window.Tabs do T:HideTab() end
            Blocker.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Library.MainColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor'
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1
            TabButton.BackgroundColor3 = Library.BackgroundColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor'
            TabFrame.Visible = false
        end

        function Tab:SetLayoutOrder(Pos)
            TabButton.LayoutOrder = Pos
            TabListLayout:ApplyLayout()
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1,0,0,40);
                ZIndex           = 2;
                Parent           = Info.Side==1 and LeftSide or RightSide;
            })
            Corner(BoxOuter, R_WINDOW)
            Library:AddToRegistry(BoxOuter, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Color3.new(0,0,0);
                Size             = UDim2.new(1,-2,1,-2);
                Position         = UDim2.new(0,1,0,1);
                ZIndex           = 4;
                Parent           = BoxOuter;
            })
            Corner(BoxInner, R_WINDOW)
            Library:AddToRegistry(BoxInner, { BackgroundColor3='BackgroundColor' })

            local GbHighlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1,0,0,2);
                ZIndex           = 5;
                Parent           = BoxInner;
            })
            Library:AddToRegistry(GbHighlight, { BackgroundColor3='AccentColor' })

            Library:CreateLabel({
                Size           = UDim2.new(1,0,0,18);
                Position       = UDim2.new(0,4,0,2);
                TextSize       = 14;
                Text           = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex         = 5;
                Parent         = BoxInner;
            })

            local GbContainer = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position               = UDim2.new(0,4,0,20);
                Size                   = UDim2.new(1,-4,1,-20);
                ZIndex                 = 1;
                Parent                 = BoxInner;
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder     = Enum.SortOrder.LayoutOrder;
                Parent        = GbContainer;
            })

            function Groupbox:Resize()
                local Size = 0
                for _, El in next, self.Container:GetChildren() do
                    if not El:IsA('UIListLayout') and El.Visible then
                        Size = Size + El.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1,0,0,20+Size+4)
            end

            Groupbox.Container = GbContainer
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(3)
            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)  return Tab:AddGroupbox({ Side=1; Name=Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side=2; Name=Name }) end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }

            local TBoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1,0,0,0);
                ZIndex           = 2;
                Parent           = Info.Side==1 and LeftSide or RightSide;
            })
            Corner(TBoxOuter, R_WINDOW)
            Library:AddToRegistry(TBoxOuter, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })

            local TBoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Color3.new(0,0,0);
                Size             = UDim2.new(1,-2,1,-2);
                Position         = UDim2.new(0,1,0,1);
                ZIndex           = 4;
                Parent           = TBoxOuter;
            })
            Corner(TBoxInner, R_WINDOW)
            Library:AddToRegistry(TBoxInner, { BackgroundColor3='BackgroundColor' })

            local TBoxHL = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1,0,0,2);
                ZIndex           = 10;
                Parent           = TBoxInner;
            })
            Library:AddToRegistry(TBoxHL, { BackgroundColor3='AccentColor' })

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position               = UDim2.new(0,0,0,1);
                Size                   = UDim2.new(1,0,0,18);
                ZIndex                 = 5;
                Parent                 = TBoxInner;
            })
            Library:Create('UIListLayout', {
                FillDirection       = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder           = Enum.SortOrder.LayoutOrder;
                Parent              = TabboxButtons;
            })

            function Tabbox:AddTab(Name)
                local T = {}

                local Btn = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3     = Color3.new(0,0,0);
                    Size             = UDim2.new(0.5,0,1,0);
                    ZIndex           = 6;
                    Parent           = TabboxButtons;
                })
                Corner(Btn, R_SMALL)
                Library:AddToRegistry(Btn, { BackgroundColor3='MainColor' })

                Library:CreateLabel({
                    Size           = UDim2.new(1,0,1,0);
                    TextSize       = 14;
                    Text           = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex         = 7;
                    Parent         = Btn;
                })

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel  = 0;
                    Position         = UDim2.new(0,0,1,0);
                    Size             = UDim2.new(1,0,0,1);
                    Visible          = false;
                    ZIndex           = 9;
                    Parent           = Btn;
                })
                Library:AddToRegistry(Block, { BackgroundColor3='BackgroundColor' })

                local TContainer = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position               = UDim2.new(0,4,0,20);
                    Size                   = UDim2.new(1,-4,1,-20);
                    ZIndex                 = 1;
                    Visible                = false;
                    Parent                 = TBoxInner;
                })
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder     = Enum.SortOrder.LayoutOrder;
                    Parent        = TContainer;
                })

                function T:Show()
                    for _, tb in next, Tabbox.Tabs do tb:Hide() end
                    TContainer.Visible = true; Block.Visible = true
                    Btn.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Btn].Properties.BackgroundColor3 = 'BackgroundColor'
                    T:Resize()
                end
                function T:Hide()
                    TContainer.Visible = false; Block.Visible = false
                    Btn.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Btn].Properties.BackgroundColor3 = 'MainColor'
                end
                function T:Resize()
                    local cnt = 0
                    for _ in next, Tabbox.Tabs do cnt=cnt+1 end
                    for _, b in next, TabboxButtons:GetChildren() do
                        if not b:IsA('UIListLayout') then b.Size = UDim2.new(1/cnt,0,1,0) end
                    end
                    if not TContainer.Visible then return end
                    local Size = 0
                    for _, El in next, T.Container:GetChildren() do
                        if not El:IsA('UIListLayout') and El.Visible then
                            Size = Size + El.Size.Y.Offset
                        end
                    end
                    TBoxOuter.Size = UDim2.new(1,0,0,20+Size+4)
                end

                Btn.InputBegan:Connect(function(I)
                    if I.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        T:Show(); T:Resize()
                    end
                end)

                T.Container = TContainer
                Tabbox.Tabs[Name] = T
                setmetatable(T, BaseGroupbox)
                T:AddBlank(3); T:Resize()
                if #TabboxButtons:GetChildren() == 2 then T:Show() end
                return T
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)  return Tab:AddTabbox({ Name=Name, Side=1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name=Name, Side=2 }) end

        TabButton.InputBegan:Connect(function(I)
            if I.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)

        if #TabContainer:GetChildren() == 1 then Tab:ShowTab() end

        Window.Tabs[Name] = Tab
        return Tab
    end

    -- Modal + Toggle (fade)
    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size    = UDim2.new(0,0,0,0);
        Visible = true;
        Text    = '';
        Modal   = false;
        Parent  = ScreenGui;
    })

    local TransparencyCache = {}
    local Toggled = false
    local Fading  = false

    function Library:Toggle()
        if Fading then return end
        local FadeTime = Config.MenuFadeTime
        Fading  = true
        Toggled = not Toggled
        ModalElement.Modal = Toggled

        if Toggled then
            Outer.Visible = true
            task.spawn(function()
                local State = InputService.MouseIconEnabled

                local Cursor = Drawing.new('Triangle')
                Cursor.Thickness = 1; Cursor.Filled = true; Cursor.Visible = true

                local COut = Drawing.new('Triangle')
                COut.Thickness = 1; COut.Filled = false
                COut.Color = Color3.new(0,0,0); COut.Visible = true

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false
                    local mP = InputService:GetMouseLocation()
                    Cursor.Color  = Library.AccentColor
                    Cursor.PointA = Vector2.new(mP.X, mP.Y)
                    Cursor.PointB = Vector2.new(mP.X+16, mP.Y+6)
                    Cursor.PointC = Vector2.new(mP.X+6,  mP.Y+16)
                    COut.PointA = Cursor.PointA; COut.PointB = Cursor.PointB; COut.PointC = Cursor.PointC
                    RenderStepped:Wait()
                end

                InputService.MouseIconEnabled = State
                Cursor:Remove(); COut:Remove()
            end)
        end

        for _, Desc in next, Outer:GetDescendants() do
            local Props = {}
            if Desc:IsA('ImageLabel') then
                table.insert(Props,'ImageTransparency'); table.insert(Props,'BackgroundTransparency')
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Props,'TextTransparency')
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Props,'BackgroundTransparency')
            elseif Desc:IsA('UIStroke') then
                table.insert(Props,'Transparency')
            end

            local Cache = TransparencyCache[Desc]
            if not Cache then Cache = {}; TransparencyCache[Desc] = Cache end

            for _, Prop in next, Props do
                if not Cache[Prop] then Cache[Prop] = Desc[Prop] end
                if Cache[Prop] == 1 then continue end
                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear),
                    { [Prop] = Toggled and Cache[Prop] or 1 }):Play()
            end
        end

        task.wait(FadeTime)
        Outer.Visible = Toggled
        Fading = false
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(I, Processed)
        if type(Library.ToggleKeybind)=='table' and Library.ToggleKeybind.Type=='KeyPicker' then
            if I.UserInputType == Enum.UserInputType.Keyboard
            and I.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif I.KeyCode == Enum.KeyCode.RightControl
            or (I.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer
    return Window
end

-- ── Player/Team dropdown updates ────────────────────────────────────────
local function OnPlayerChange()
    local list = GetPlayersString()
    for _, V in next, Options do
        if V.Type=='Dropdown' and V.SpecialType=='Player' then V:SetValues(list) end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
