-- ModernLib.lua
-- Linoria reskin: same API/logic, modern visual layer
-- Changes: rounded corners, soft shadows, accent glow, no harsh gradients, softer palette

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

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};

    -- === MODERN THEME (your palette) ===
    FontColor      = Color3.fromRGB(255, 255, 255);
    MainColor      = Color3.fromRGB(28,  28,  28);
    BackgroundColor= Color3.fromRGB(20,  20,  20);
    AccentColor    = Color3.fromRGB(187, 156, 184);   -- #bb9cb8
    OutlineColor   = Color3.fromRGB(50,  50,  50);    -- #323232
    RiskColor      = Color3.fromRGB(255, 80,  80);

    Black = Color3.new(0, 0, 0);
    Font  = Enum.Font.GothamSemibold,   -- swap from Code → Gotham for modern feel

    OpenedFrames    = {};
    DependencyBoxes = {};
    Signals         = {};
    ScreenGui       = ScreenGui;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400);
        if Hue > 1 then Hue = 0; end;
        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do PlayerList[i] = PlayerList[i].Name; end;
    table.sort(PlayerList, function(a, b) return a < b end);
    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do TeamList[i] = TeamList[i].Name; end;
    table.sort(TeamList, function(a, b) return a < b end);
    return TeamList;
end;

-- ============================================================
--  VISUAL HELPERS (new for reskin)
-- ============================================================

function Library:AddCorner(Parent, Radius)
    return Library:Create('UICorner', {
        CornerRadius = UDim.new(0, Radius or 6),
        Parent = Parent,
    })
end

-- Soft drop-shadow using the standard blurred-square asset
function Library:MakeShadow(Parent, ExtraSize, Transparency, OffsetY)
    return Library:Create('ImageLabel', {
        AnchorPoint       = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position          = UDim2.new(0.5, 0, 0.5, OffsetY or 3),
        Size              = UDim2.new(1, ExtraSize or 18, 1, ExtraSize or 18),
        ZIndex            = math.max(0, (Parent.ZIndex or 1) - 1),
        Image             = 'rbxassetid://6014261993',
        ImageColor3       = Color3.new(0, 0, 0),
        ImageTransparency = Transparency or 0.55,
        ScaleType         = Enum.ScaleType.Slice,
        SliceCenter       = Rect.new(49, 49, 450, 450),
        Parent            = Parent,
    })
end

-- Soft accent glow behind an element (bloom substitute)
function Library:MakeGlow(Parent, ExtraSize, Transparency)
    local G = Library:Create('ImageLabel', {
        AnchorPoint       = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position          = UDim2.new(0.5, 0, 0.5, 0),
        Size              = UDim2.new(1, ExtraSize or 12, 1, ExtraSize or 12),
        ZIndex            = math.max(0, (Parent.ZIndex or 1) - 1),
        Image             = 'rbxassetid://6014261993',
        ImageColor3       = Library.AccentColor,
        ImageTransparency = Transparency or 0.72,
        ScaleType         = Enum.ScaleType.Slice,
        SliceCenter       = Rect.new(49, 49, 450, 450),
        Visible           = false,
        Parent            = Parent,
    })
    Library:AddToRegistry(G, {
        ImageColor3 = 'AccentColor',
    })
    return G
end

-- ============================================================
--  CORE LIBRARY METHODS (unchanged logic)
-- ============================================================

function Library:SafeCallback(f, ...)
    if (not f) then return; end;
    if not Library.NotifyOnError then return f(...); end;
    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then return Library:Notify(event); end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save(); end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then _Instance = Instance.new(Class); end;
    for Property, Value in next, Properties do _Instance[Property] = Value; end;
    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;
    Library:Create('UIStroke', {
        Color         = Color3.new(0, 0, 0);
        Thickness     = 1;
        LineJoinMode  = Enum.LineJoinMode.Miter;
        Parent        = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font                   = Library.Font;
        TextColor3             = Library.FontColor;
        TextSize               = 14;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);
    Library:AddToRegistry(_Instance, { TextColor3 = 'FontColor'; }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );
            if ObjPos.Y > (Cutoff or 40) then return; end;
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );
                RenderStepped:Wait();
            end;
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 13);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Size             = UDim2.fromOffset(X + 10, Y + 6),
        ZIndex           = 100,
        Parent           = Library.ScreenGui,
        Visible          = false,
    })
    Library:AddCorner(Tooltip, 5)
    Library:MakeShadow(Tooltip, 10, 0.65)

    local Label = Library:CreateLabel({
        Position         = UDim2.fromOffset(5, 3),
        Size             = UDim2.fromOffset(X, Y);
        TextSize         = 13;
        Text             = InfoStr,
        TextColor3       = Library.FontColor,
        TextXAlignment   = Enum.TextXAlignment.Left;
        ZIndex           = Tooltip.ZIndex + 1,
        Parent           = Tooltip;
    });

    Library:AddToRegistry(Tooltip, { BackgroundColor3 = 'MainColor'; });
    Library:AddToRegistry(Label,   { TextColor3       = 'FontColor';  });

    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx; end;
        end;
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx; end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do Depbox:Update(); end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx  = #Library.Registry + 1;
    local Data = { Instance = Instance; Properties = Properties; Idx = Idx; };
    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;
    if IsHud then table.insert(Library.HudRegistry, Data); end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx); end;
        end;
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx); end;
        end;
        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then Library:RemoveFromRegistry(Instance); end;
end))

-- ============================================================
--  BASE ADDONS  (ColorPicker + KeyPicker)
-- ============================================================

local BaseAddons = {};

do
    local Funcs = {};

    -- ── ColorPicker ─────────────────────────────────────────
    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value        = Info.Default;
            Transparency = Info.Transparency or 0;
            Type         = 'ColorPicker';
            Title        = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback     = Info.Callback or function() end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H; ColorPicker.Sat = S; ColorPicker.Vib = V;
        end;
        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        -- Small color swatch next to the label (rounded)
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderSizePixel  = 0;
            Size             = UDim2.new(0, 28, 0, 14);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        });
        Library:AddCorner(DisplayFrame, 4)

        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size            = UDim2.new(0, 27, 0, 13);
            ZIndex          = 5;
            Image           = 'http://www.roblox.com/asset/?id=12977615774';
            Visible         = not not Info.Transparency;
            Parent          = DisplayFrame;
        });

        -- Picker popup
        local PickerFrameOuter = Library:Create('Frame', {
            Name             = 'Color';
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel  = 0;
            Position         = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size             = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible          = false;
            ZIndex           = 15;
            Parent           = ScreenGui,
        });
        Library:MakeShadow(PickerFrameOuter, 20, 0.5, 5)

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 16;
            Parent           = PickerFrameOuter;
        });
        Library:AddCorner(PickerFrameInner, 8)

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 0, 2);
            ZIndex           = 17;
            Parent           = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            BackgroundColor3 = Color3.new(0,0,0);
            Position        = UDim2.new(0, 4, 0, 25);
            Size            = UDim2.new(0, 200, 0, 200);
            ZIndex          = 17;
            Parent          = PickerFrameInner;
        });
        Library:AddCorner(SatVibMapOuter, 5)

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 18;
            Parent           = SatVibMapOuter;
        });
        Library:AddCorner(SatVibMapInner, 5)

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size            = UDim2.new(1, 0, 1, 0);
            ZIndex          = 18;
            Image           = 'rbxassetid://4155801252';
            Parent          = SatVibMapInner;
        });
        Library:AddCorner(SatVibMap, 5)

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint          = Vector2.new(0.5, 0.5);
            Size                 = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image                = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3          = Color3.new(0, 0, 0);
            ZIndex               = 19;
            Parent               = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size                 = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position             = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image                = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex               = 20;
            Parent               = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderSizePixel  = 0;
            Position         = UDim2.new(0, 208, 0, 25);
            Size             = UDim2.new(0, 15, 0, 200);
            ZIndex           = 17;
            Parent           = PickerFrameInner;
        });
        Library:AddCorner(HueSelectorOuter, 4)

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 18;
            Parent           = HueSelectorOuter;
        });
        Library:AddCorner(HueSelectorInner, 4)

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint      = Vector2.new(0, 0.5);
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 0, 2);
            ZIndex           = 18;
            Parent           = HueSelectorInner;
        });

        -- Hex input box (rounded)
        local HueBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderSizePixel  = 0;
            Position         = UDim2.fromOffset(4, 228),
            Size             = UDim2.new(0.5, -6, 0, 20),
            ZIndex           = 18,
            Parent           = PickerFrameInner;
        });
        Library:AddCorner(HueBoxOuter, 4)

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 18,
            Parent           = HueBoxOuter;
        });
        Library:AddCorner(HueBoxInner, 4)

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position             = UDim2.new(0, 5, 0, 0);
            Size                 = UDim2.new(1, -5, 1, 0);
            Font                 = Library.Font;
            PlaceholderColor3    = Color3.fromRGB(120, 120, 120);
            PlaceholderText      = 'Hex color',
            Text                 = '#FFFFFF',
            TextColor3           = Library.FontColor;
            TextSize             = 13;
            TextStrokeTransparency = 0;
            TextXAlignment       = Enum.TextXAlignment.Left;
            ZIndex               = 20,
            Parent               = HueBoxInner;
        });
        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size     = UDim2.new(0.5, -6, 0, 20),
            Parent   = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox') or RgbBoxBase:FindFirstChildOfClass('TextBox') or HueBox:Clone(), {
            Text            = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3      = Library.FontColor
        });
        if not RgbBox.Parent then RgbBox.Parent = RgbBoxBase end

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0,0,0);
                BorderSizePixel  = 0;
                Position         = UDim2.fromOffset(4, 251);
                Size             = UDim2.new(1, -8, 0, 15);
                ZIndex           = 19;
                Parent           = PickerFrameInner;
            });
            Library:AddCorner(TransparencyBoxOuter, 4)
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 1, 0);
                ZIndex           = 19;
                Parent           = TransparencyBoxOuter;
            });
            Library:AddCorner(TransparencyBoxInner, 4)
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });
            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size   = UDim2.new(1, 0, 1, 0);
                Image  = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint      = Vector2.new(0.5, 0);
                BorderSizePixel  = 0;
                Size             = UDim2.new(0, 2, 1, 0);
                ZIndex           = 21;
                Parent           = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size           = UDim2.new(1, 0, 0, 14);
            Position       = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize       = 13;
            Text           = ColorPicker.Title;
            TextWrapped    = false;
            ZIndex         = 16;
            Parent         = PickerFrameInner;
        });

        -- Context menu
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderSizePixel = 0;
                BackgroundColor3 = Color3.new(0,0,0);
                ZIndex  = 14,
                Visible = false,
                Parent  = ScreenGui
            })
            Library:MakeShadow(ContextMenu.Container, 12, 0.6)
            Library:AddCorner(ContextMenu.Container, 6)

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel  = 0;
                Size             = UDim2.fromScale(1, 1);
                ZIndex           = 15;
                Parent           = ContextMenu.Container;
            });
            Library:AddCorner(ContextMenu.Inner, 6)

            Library:Create('UIListLayout', {
                Name          = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder     = Enum.SortOrder.LayoutOrder;
                Parent        = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name        = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent      = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end
            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end
            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, { BackgroundColor3 = 'BackgroundColor'; });

            function ContextMenu:Show()  self.Container.Visible = true  end
            function ContextMenu:Hide()  self.Container.Visible = false end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then Callback = function() end end
                local Button = Library:CreateLabel({
                    Active         = false;
                    Size           = UDim2.new(1, 0, 0, 15);
                    TextSize       = 13;
                    Text           = Str;
                    ZIndex         = 16;
                    Parent         = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor'   }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)
            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('No color copied!', 2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex!', 2)
            end)
            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({
                    math.floor(ColorPicker.Value.R * 255),
                    math.floor(ColorPicker.Value.G * 255),
                    math.floor(ColorPicker.Value.B * 255)
                }, ', '))
                Library:Notify('Copied RGB!', 2)
            end)
        end

        Library:AddToRegistry(PickerFrameInner,  { BackgroundColor3 = 'BackgroundColor'; });
        Library:AddToRegistry(Highlight,         { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner,    { BackgroundColor3 = 'BackgroundColor'; });
        Library:AddToRegistry(HueBoxInner,       { BackgroundColor3 = 'MainColor'; });
        Library:AddToRegistry(HueBox,            { TextColor3 = 'FontColor'; });

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;
        Library:Create('UIGradient', {
            Color    = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent   = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);
            Library:Create(DisplayFrame, {
                BackgroundColor3     = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
            });
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position   = UDim2.new(0, 0, ColorPicker.Hue, 0);
            HueBox.Text  = '#' .. ColorPicker.Value:ToHex()
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed,  ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;
            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX, MaxX = SatVibMap.AbsolutePosition.X, SatVibMap.AbsolutePosition.X + SatVibMap.AbsoluteSize.X;
                    local MinY, MaxY = SatVibMap.AbsolutePosition.Y, SatVibMap.AbsolutePosition.Y + SatVibMap.AbsoluteSize.Y;
                    ColorPicker.Sat = (math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY, MaxY = HueSelectorInner.AbsolutePosition.Y, HueSelectorInner.AbsolutePosition.Y + HueSelectorInner.AbsoluteSize.Y;
                    ColorPicker.Hue = (math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY);
                    ColorPicker:Display();
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then ColorPicker:Hide()
                else ContextMenu:Hide(); ColorPicker:Show() end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show(); ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX, MaxX = TransparencyBoxInner.AbsolutePosition.X, TransparencyBoxInner.AbsolutePosition.X + TransparencyBoxInner.AbsoluteSize.X;
                        ColorPicker.Transparency = 1 - ((math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
                        RenderStepped:Wait();
                    end;
                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    ColorPicker:Hide();
                end;
                if not Library:IsMouseOverFrame(ContextMenu.Container) then ContextMenu:Hide() end
            end;
            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame;
        Options[Idx] = ColorPicker;
        return self;
    end;

    -- ── KeyPicker ────────────────────────────────────────────
    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj   = self;
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value             = Info.Default;
            Toggled           = false;
            Mode              = Info.Mode or 'Toggle';
            Type              = 'KeyPicker';
            Callback          = Info.Callback or function() end;
            ChangedCallback   = Info.ChangedCallback or function() end;
            SyncToggleState   = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then Info.Modes = { 'Toggle' }; Info.Mode = 'Toggle' end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel  = 0;
            Size             = UDim2.new(0, 28, 0, 15);
            ZIndex           = 6;
            Parent           = ToggleLabel;
        });
        Library:AddCorner(PickOuter, 4)

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 7;
            Parent           = PickOuter;
        });
        Library:AddCorner(PickInner, 4)
        Library:AddToRegistry(PickInner, { BackgroundColor3 = 'BackgroundColor'; });

        local DisplayLabel = Library:CreateLabel({
            Size        = UDim2.new(1, 0, 1, 0);
            TextSize    = 12;
            Text        = Info.Default;
            TextWrapped = true;
            ZIndex      = 8;
            Parent      = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0);
            BorderSizePixel  = 0;
            Position         = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size             = UDim2.new(0, 65, 0, 49);
            Visible          = false;
            ZIndex           = 14;
            Parent           = ScreenGui;
        });
        Library:AddCorner(ModeSelectOuter, 6)
        Library:MakeShadow(ModeSelectOuter, 12, 0.6)

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 15;
            Parent           = ModeSelectOuter;
        });
        Library:AddCorner(ModeSelectInner, 6)
        Library:AddToRegistry(ModeSelectInner, { BackgroundColor3 = 'BackgroundColor'; });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder     = Enum.SortOrder.LayoutOrder;
            Parent        = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size           = UDim2.new(1, 0, 0, 18);
            TextSize       = 13;
            Visible        = false;
            ZIndex         = 110;
            Parent         = Library.KeybindContainer;
        }, true);

        local Modes      = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Label = Library:CreateLabel({
                Active   = false;
                Size     = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text     = Mode;
                ZIndex   = 16;
                Parent   = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do Button:Deselect(); end;
                KeyPicker.Mode = Mode;
                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';
                ModeSelectOuter.Visible = false;
            end;
            function ModeButton:Deselect()
                KeyPicker.Mode = nil;
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;
            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select(); Library:AttemptSave();
                end;
            end);
            if Mode == KeyPicker.Mode then ModeButton:Select(); end;
            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then return; end;
            local State = KeyPicker:GetState();
            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);
            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';
            local YSize, XSize = 0, 0
            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18;
                    if Label.TextBounds.X > XSize then XSize = Label.TextBounds.X end
                end;
            end;
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then return false end
                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]); end;
            else return KeyPicker.Toggled; end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key; KeyPicker.Value = Key;
            ModeButtons[Mode]:Select(); KeyPicker:Update();
        end;
        function KeyPicker:OnClick(Callback)    KeyPicker.Clicked = Callback end
        function KeyPicker:OnChanged(Callback)  KeyPicker.Changed = Callback; Callback(KeyPicker.Value) end

        if ParentObj.Addons then table.insert(ParentObj.Addons, KeyPicker) end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked,  KeyPicker.Toggled)
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;
                DisplayLabel.Text = '';
                local Break, Text = false, '';
                task.spawn(function()
                    while not Break do
                        if Text == '...' then Text = '' end
                        Text = Text .. '.'; DisplayLabel.Text = Text;
                        wait(0.4);
                    end;
                end);
                wait(0.2);
                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;
                    if     Input.UserInputType == Enum.UserInputType.Keyboard    then Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then Key = 'MB2'; end;
                    Break = true; Picking = false;
                    DisplayLabel.Text = Key; KeyPicker.Value = Key;
                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed,         Input.KeyCode or Input.UserInputType)
                    Library:AttemptSave();
                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;
                    if Key == 'MB1' or Key == 'MB2' then
                        if (Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1)
                        or (Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                            KeyPicker.Toggled = not KeyPicker.Toggled; KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled; KeyPicker:DoClick()
                        end;
                    end;
                end;
                KeyPicker:Update();
            end;
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if not Picking then KeyPicker:Update(); end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;
        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...) return Funcs[Key](...); end;
end;

-- ============================================================
--  BASE GROUPBOX
-- ============================================================

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size   = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = self.Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label     = {};
        local Groupbox  = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size           = UDim2.new(1, -4, 0, 15);
            TextSize       = 13;
            Text           = Text;
            TextWrapped    = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding              = UDim.new(0, 4);
                FillDirection        = Enum.FillDirection.Horizontal;
                HorizontalAlignment  = Enum.HorizontalAlignment.Right;
                SortOrder            = Enum.SortOrder.LayoutOrder;
                Parent               = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            Groupbox:Resize();
        end

        if not DoesWrap then setmetatable(Label, BaseAddons); end

        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Label;
    end;

    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text; Obj.Func = Props.Func;
                Obj.DoubleClick = Props.DoubleClick; Obj.Tooltip = Props.Tooltip;
            else
                Obj.Text = select(1, ...); Obj.Func = select(2, ...);
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end
        ProcessButtonParams('Button', Button, ...)

        local Groupbox  = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            -- Modern: single rounded frame, no harsh black outer
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, -4, 0, 22);
                ZIndex           = 5;
            });
            Library:AddCorner(Outer, 5)

            -- subtle UIStroke for border
            local Stroke = Library:Create('UIStroke', {
                Color     = Library.OutlineColor;
                Thickness = 1;
                Parent    = Outer;
            });

            local Label = Library:CreateLabel({
                Size     = UDim2.new(1, 0, 1, 0);
                TextSize = 13;
                Text     = Button.Text;
                ZIndex   = 6;
                Parent   = Outer;
            });

            Library:AddToRegistry(Outer,   { BackgroundColor3 = 'MainColor'; });
            Library:AddToRegistry(Stroke,  { Color = 'OutlineColor'; });

            -- hover: accent stroke
            Outer.MouseEnter:Connect(function()
                TweenService:Create(Stroke, TweenInfo.new(0.15), { Color = Library.AccentColor }):Play()
            end)
            Outer.MouseLeave:Connect(function()
                TweenService:Create(Stroke, TweenInfo.new(0.15), { Color = Library.OutlineColor }):Play()
            end)

            return Outer, Outer, Label   -- return Outer twice so existing Inner refs work
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable  = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then bindable:Fire(true)
                    else bindable:Fire(false) end
                end)
                task.delay(timeout, function() connection:disconnect(); bindable:Fire(false) end)
                return bindable.Event:Wait()
            end
            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then return false end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return false end
                return true
            end
            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end
                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })
                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true
                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)
                    if clicked then Library:SafeCallback(Button.Func) end
                    return
                end
                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 22)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer
            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
                return SubButton
            end
            if type(SubButton.Tooltip) == 'string' then SubButton:AddTooltip(SubButton.Tooltip) end
            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then Button:AddTooltip(Button.Tooltip) end

        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container;
        Groupbox:AddBlank(2);
        local Div = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, -4, 0, 1);
            ZIndex           = 5;
            Parent           = Container;
        });
        Library:AddToRegistry(Div, { BackgroundColor3 = 'OutlineColor' });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value   = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type    = 'Input';
            Callback = Info.Callback or function() end;
        };

        local Groupbox  = self;
        local Container = Groupbox.Container;

        Library:CreateLabel({
            Size           = UDim2.new(1, 0, 0, 15);
            TextSize       = 13;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = Container;
        });

        Groupbox:AddBlank(1);

        -- Modern input box: single rounded frame
        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, -4, 0, 22);
            ZIndex           = 5;
            Parent           = Container;
        });
        Library:AddCorner(TextBoxOuter, 5)

        local Stroke = Library:Create('UIStroke', {
            Color     = Library.OutlineColor;
            Thickness = 1;
            Parent    = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxOuter, { BackgroundColor3 = 'MainColor'; });
        Library:AddToRegistry(Stroke,       { Color = 'OutlineColor'; });

        TextBoxOuter.MouseEnter:Connect(function()
            TweenService:Create(Stroke, TweenInfo.new(0.15), { Color = Library.AccentColor }):Play()
        end)
        TextBoxOuter.MouseLeave:Connect(function()
            TweenService:Create(Stroke, TweenInfo.new(0.15), { Color = Library.OutlineColor }):Play()
        end)

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, TextBoxOuter) end

        local ClipContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants       = true;
            Position               = UDim2.new(0, 6, 0, 0);
            Size                   = UDim2.new(1, -6, 1, 0);
            ZIndex                 = 7;
            Parent                 = TextBoxOuter;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position               = UDim2.fromOffset(0, 0),
            Size                   = UDim2.fromScale(5, 1),
            Font                   = Library.Font;
            PlaceholderColor3      = Color3.fromRGB(90, 90, 90);
            PlaceholderText        = Info.Placeholder or '';
            Text                   = Info.Default or '';
            TextColor3             = Library.FontColor;
            TextSize               = 13;
            TextStrokeTransparency = 0;
            TextXAlignment         = Enum.TextXAlignment.Left;
            ZIndex                 = 7;
            Parent                 = ClipContainer;
        });
        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength); end;
            if Textbox.Numeric then
                if not tonumber(Text) and Text:len() > 0 then Text = Textbox.Value end
            end
            Textbox.Value = Text; Box.Text = Text;
            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed,  Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text); Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text); Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal  = ClipContainer.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor - 1)
                    local width   = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
                    local currentCursorPos = Box.Position.X.Offset + width
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING - width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal - width - PADDING - 1, 0)
                    end
                end
            end
        end

        task.spawn(Update)
        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, { TextColor3 = 'FontColor'; });

        function Textbox:OnChanged(Func) Textbox.Changed = Func; Func(Textbox.Value); end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();
        Options[Idx] = Textbox;
        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value    = Info.Default or false;
            Type     = 'Toggle';
            Callback = Info.Callback or function() end;
            Addons   = {};
            Risky    = Info.Risky;
        };

        local Groupbox  = self;
        local Container = Groupbox.Container;

        -- Modern toggle: rounded square checkbox
        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(0, 14, 0, 14);
            ZIndex           = 5;
            Parent           = Container;
        });
        Library:AddCorner(ToggleOuter, 4)

        local ToggleStroke = Library:Create('UIStroke', {
            Color     = Library.OutlineColor;
            Thickness = 1;
            Parent    = ToggleOuter;
        });

        -- Accent glow behind checkbox (shown when active)
        local ToggleGlow = Library:MakeGlow(ToggleOuter, 10, 0.75)

        Library:AddToRegistry(ToggleOuter,   { BackgroundColor3 = 'MainColor'; });
        Library:AddToRegistry(ToggleStroke,  { Color = 'OutlineColor'; });

        local ToggleLabel = Library:CreateLabel({
            Size           = UDim2.new(0, 216, 1, 0);
            Position       = UDim2.new(1, 6, 0, 0);
            TextSize       = 13;
            Text           = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 6;
            Parent         = ToggleOuter;
        });

        Library:Create('UIListLayout', {
            Padding             = UDim.new(0, 4);
            FillDirection       = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder           = Enum.SortOrder.LayoutOrder;
            Parent              = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size   = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        ToggleRegion.MouseEnter:Connect(function()
            TweenService:Create(ToggleStroke, TweenInfo.new(0.12), { Color = Library.AccentColor }):Play()
        end)
        ToggleRegion.MouseLeave:Connect(function()
            if not Toggle.Value then
                TweenService:Create(ToggleStroke, TweenInfo.new(0.12), { Color = Library.OutlineColor }):Play()
            end
        end)

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, ToggleRegion) end

        function Toggle:UpdateColors() Toggle:Display(); end;

        function Toggle:Display()
            local active = Toggle.Value
            TweenService:Create(ToggleOuter, TweenInfo.new(0.15), {
                BackgroundColor3 = active and Library.AccentColor or Library.MainColor
            }):Play()
            TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {
                Color = active and Library.AccentColorDark or Library.OutlineColor
            }):Play()

            ToggleGlow.ImageColor3 = Library.AccentColor
            ToggleGlow.Visible     = active

            Library.RegistryMap[ToggleOuter].Properties.BackgroundColor3 = active and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleStroke].Properties.Color            = active and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func) Toggle.Changed = Func; Func(Toggle.Value); end;

        function Toggle:SetValue(Bool)
            Bool = not not Bool;
            Toggle.Value = Bool;
            Toggle:Display();
            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool; Addon:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed,  Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value);
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 7);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);
        Toggles[Idx] = Toggle;
        Library:UpdateDependencyBoxes();
        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default,  'AddSlider: Missing default value.');
        assert(Info.Text,     'AddSlider: Missing slider text.');
        assert(Info.Min,      'AddSlider: Missing minimum value.');
        assert(Info.Max,      'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value   = Info.Default;
            Min     = Info.Min;
            Max     = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type    = 'Slider';
            Callback = Info.Callback or function() end;
        };

        local Groupbox  = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size           = UDim2.new(1, 0, 0, 10);
                TextSize       = 13;
                Text           = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex         = 5;
                Parent         = Container;
            });
            Groupbox:AddBlank(3);
        end

        -- Modern slider: rounded track
        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, -4, 0, 14);
            ZIndex           = 5;
            Parent           = Container;
        });
        Library:AddCorner(SliderOuter, 5)

        local SliderStroke = Library:Create('UIStroke', {
            Color     = Library.OutlineColor;
            Thickness = 1;
            Parent    = SliderOuter;
        });

        Library:AddToRegistry(SliderOuter,  { BackgroundColor3 = 'MainColor'; });
        Library:AddToRegistry(SliderStroke, { Color = 'OutlineColor'; });

        -- Filled portion
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(0, 0, 1, 0);
            ZIndex           = 7;
            Parent           = SliderOuter;
        });
        Library:AddCorner(Fill, 5)
        Library:AddToRegistry(Fill, { BackgroundColor3 = 'AccentColor'; });

        -- Glow on fill
        local FillGlow = Library:MakeGlow(Fill, 8, 0.78)

        local DisplayLabel = Library:CreateLabel({
            Size     = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text     = '';
            ZIndex   = 9;
            Parent   = SliderOuter;
        });

        SliderOuter.MouseEnter:Connect(function()
            TweenService:Create(SliderStroke, TweenInfo.new(0.15), { Color = Library.AccentColor }):Play()
        end)
        SliderOuter.MouseLeave:Connect(function()
            TweenService:Create(SliderStroke, TweenInfo.new(0.15), { Color = Library.OutlineColor }):Play()
        end)

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, SliderOuter) end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            FillGlow.ImageColor3  = Library.AccentColor;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end
            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);
            -- glow only when there's fill
            FillGlow.Visible = X > 2
        end;

        function Slider:OnChanged(Func) Slider.Changed = Func; Func(Slider.Value); end;

        local function Round(Value)
            if Slider.Rounding == 0 then return math.floor(Value); end;
            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if not Num then return; end;
            Num = math.clamp(Num, Slider.Min, Slider.Max);
            Slider.Value = Num; Slider:Display();
            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed,  Slider.Value);
        end;

        SliderOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos  = Mouse.X;
                local gPos  = Fill.Size.X.Offset;
                local Diff  = mPos - (Fill.AbsolutePosition.X + gPos);
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nX       = math.clamp(gPos + (Mouse.X - mPos) + Diff, 0, Slider.MaxSize);
                    local nValue   = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value   = nValue;
                    Slider:Display();
                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed,  Slider.Value);
                    end;
                    RenderStepped:Wait();
                end;
                Library:AttemptSave();
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();
        Options[Idx] = Slider;
        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then Info.Values = GetPlayersString(); Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then Info.Values = GetTeamsString(); Info.AllowNull = true; end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value.')

        if not Info.Text then Info.Compact = true; end;

        local Dropdown = {
            Values      = Info.Values;
            Value       = Info.Multi and {};
            Multi       = Info.Multi;
            Type        = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback    = Info.Callback or function() end;
        };

        local Groupbox  = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size           = UDim2.new(1, 0, 0, 10);
                TextSize       = 13;
                Text           = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex         = 5;
                Parent         = Container;
            });
            Groupbox:AddBlank(3);
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, -4, 0, 22);
            ZIndex           = 5;
            Parent           = Container;
        });
        Library:AddCorner(DropdownOuter, 5)

        local DropStroke = Library:Create('UIStroke', {
            Color     = Library.OutlineColor;
            Thickness = 1;
            Parent    = DropdownOuter;
        });

        Library:AddToRegistry(DropdownOuter, { BackgroundColor3 = 'MainColor'; });
        Library:AddToRegistry(DropStroke,    { Color = 'OutlineColor'; });

        DropdownOuter.MouseEnter:Connect(function()
            TweenService:Create(DropStroke, TweenInfo.new(0.15), { Color = Library.AccentColor }):Play()
        end)
        DropdownOuter.MouseLeave:Connect(function()
            TweenService:Create(DropStroke, TweenInfo.new(0.15), { Color = Library.OutlineColor }):Play()
        end)

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint          = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position             = UDim2.new(1, -17, 0.5, 0);
            Size                 = UDim2.new(0, 12, 0, 12);
            Image                = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex               = 8;
            Parent               = DropdownOuter;
        });

        local ItemList = Library:CreateLabel({
            Position       = UDim2.new(0, 6, 0, 0);
            Size           = UDim2.new(1, -20, 1, 0);
            TextSize       = 13;
            Text           = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped    = true;
            ZIndex         = 7;
            Parent         = DropdownOuter;
        });

        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, DropdownOuter) end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel  = 0;
            ZIndex           = 20;
            Visible          = false;
            Parent           = ScreenGui;
        });
        Library:AddCorner(ListOuter, 6)
        Library:MakeShadow(ListOuter, 14, 0.55, 4)

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 3);
        end;
        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;

        RecalculateListPosition();
        RecalculateListSize();
        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 21;
            Parent           = ListOuter;
        });
        Library:AddCorner(ListInner, 6)
        Library:AddToRegistry(ListInner, { BackgroundColor3 = 'BackgroundColor'; });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            CanvasSize             = UDim2.new(0, 0, 0, 0);
            Size                   = UDim2.new(1, 0, 1, 0);
            ZIndex                 = 21;
            Parent                 = ListInner;
            TopImage               = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage            = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = 'AccentColor' })
        Library:Create('UIListLayout', { Padding = UDim.new(0, 0); FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = Scrolling; });

        function Dropdown:Display()
            local Str = '';
            if Info.Multi then
                for _, Value in next, Dropdown.Values do
                    if Dropdown.Value[Value] then Str = Str .. Value .. ', '; end;
                end;
                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;
            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do table.insert(T, Value); end;
                return T;
            else return Dropdown.Value and 1 or 0; end;
        end;

        function Dropdown:BuildDropdownList()
            local Values  = Dropdown.Values;
            local Buttons = {};
            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then Element:Destroy(); end;
            end;
            local Count = 0;
            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel  = 0;
                    Size             = UDim2.new(1, 0, 0, 22);
                    ZIndex           = 23;
                    Active           = true,
                    Parent           = Scrolling;
                });
                Library:AddToRegistry(Button, { BackgroundColor3 = 'MainColor'; });

                local ButtonLabel = Library:CreateLabel({
                    Active         = false;
                    Size           = UDim2.new(1, -8, 1, 0);
                    Position       = UDim2.new(0, 8, 0, 0);
                    TextSize       = 13;
                    Text           = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex         = 25;
                    Parent         = Button;
                });

                Button.MouseEnter:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                end)
                Button.MouseLeave:Connect(function()
                    Button.BackgroundColor3 = Library.MainColor
                end)

                local Selected;
                if Info.Multi then Selected = Dropdown.Value[Value];
                else Selected = Dropdown.Value == Value; end;

                function Table:UpdateButton()
                    if Info.Multi then Selected = Dropdown.Value[Value];
                    else Selected = Dropdown.Value == Value; end;
                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;
                        if Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull then
                        else
                            if Info.Multi then
                                Selected = Try;
                                if Selected then Dropdown.Value[Value] = true;
                                else Dropdown.Value[Value] = nil; end;
                            else
                                Selected = Try;
                                if Selected then Dropdown.Value = Value;
                                else Dropdown.Value = nil; end;
                                for _, OtherButton in next, Buttons do OtherButton:UpdateButton(); end;
                            end;
                            Table:UpdateButton(); Dropdown:Display();
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed,  Dropdown.Value);
                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton(); Dropdown:Display();
                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, Count * 22 + 1);
            local Y = math.clamp(Count * 22, 0, MAX_DROPDOWN_ITEMS * 22) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then Dropdown.Values = NewValues; end;
            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func) Dropdown.Changed = Func; Func(Dropdown.Value); end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then nTable[Value] = true end;
                end;
                Dropdown.Value = nTable;
            else
                if not Val then Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then Dropdown.Value = Val; end;
            end;
            Dropdown:BuildDropdownList();
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed,  Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown();
                else Dropdown:OpenDropdown(); end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}
        if type(Info.Default) == 'string' then
            local i = table.find(Dropdown.Values, Info.Default)
            if i then table.insert(Defaults, i) end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local i = table.find(Dropdown.Values, Value)
                if i then table.insert(Defaults, i) end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then Dropdown.Value[Dropdown.Values[Index]] = true;
                else Dropdown.Value = Dropdown.Values[Index]; end;
                if not Info.Multi then break end
            end
            Dropdown:BuildDropdownList(); Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();
        Options[Idx] = Dropdown;
        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox   = { Dependencies = {}; };
        local Groupbox  = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size    = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent  = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size   = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder     = Enum.SortOrder.LayoutOrder;
            Parent        = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize(); end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize(); end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem, Value = Dependency[1], Dependency[2];
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false; Depbox:Resize(); return;
                end;
            end;
            Holder.Visible = true; Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: not table');
                assert(Dependency[1], 'SetupDependencies: missing element');
                assert(Dependency[2] ~= nil, 'SetupDependencies: missing value');
            end;
            Depbox.Dependencies = Dependencies; Depbox:Update();
        end;

        Depbox.Container = Frame;
        setmetatable(Depbox, BaseGroupbox);
        table.insert(Library.DependencyBoxes, Depbox);
        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...) return Funcs[Key](...); end;
end;

-- ============================================================
--  OTHER UI ELEMENTS  (notifications, watermark, keybinds)
-- ============================================================

do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size     = UDim2.new(0, 300, 0, 200);
        ZIndex   = 100;
        Parent   = ScreenGui;
    });
    Library:Create('UIListLayout', {
        Padding       = UDim.new(0, 6);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = Library.NotificationArea;
    });

    -- ── Watermark ──────────────────────────────────────────
    local WatermarkOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 100, 0, -30);
        Size             = UDim2.new(0, 213, 0, 22);
        ZIndex           = 200;
        Visible          = false;
        Parent           = ScreenGui;
    });
    Library:AddCorner(WatermarkOuter, 6)
    Library:MakeShadow(WatermarkOuter, 14, 0.6)

    local WatermarkAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1, 0, 0, 2);
        ZIndex           = 201;
        Parent           = WatermarkOuter;
    });
    Library:AddCorner(WatermarkAccent, 2)
    Library:AddToRegistry(WatermarkAccent, { BackgroundColor3 = 'AccentColor' });
    Library:AddToRegistry(WatermarkOuter,  { BackgroundColor3 = 'MainColor'   });

    local WatermarkLabel = Library:CreateLabel({
        Position       = UDim2.new(0, 7, 0, 0);
        Size           = UDim2.new(1, -4, 1, 0);
        TextSize       = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 202;
        Parent         = WatermarkOuter;
    });

    Library.Watermark     = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    -- ── Keybind Display ────────────────────────────────────
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint      = Vector2.new(0, 0.5);
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 10, 0.5, 0);
        Size             = UDim2.new(0, 210, 0, 22);
        Visible          = false;
        ZIndex           = 100;
        Parent           = ScreenGui;
    });
    Library:AddCorner(KeybindOuter, 7)
    Library:MakeShadow(KeybindOuter, 14, 0.6)
    Library:AddToRegistry(KeybindOuter, { BackgroundColor3 = 'MainColor'; }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1, 0, 0, 2);
        ZIndex           = 102;
        Parent           = KeybindOuter;
    });
    Library:AddCorner(ColorFrame, 2)
    Library:AddToRegistry(ColorFrame, { BackgroundColor3 = 'AccentColor'; }, true);

    local KeybindLabel = Library:CreateLabel({
        Size           = UDim2.new(1, 0, 0, 22);
        Position       = UDim2.fromOffset(7, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize       = 13;
        Text           = 'Keybinds';
        ZIndex         = 104;
        Parent         = KeybindOuter;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size     = UDim2.new(1, 0, 1, -22);
        Position = UDim2.new(0, 0, 0, 22);
        ZIndex   = 1;
        Parent   = KeybindOuter;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = KeybindContainer;
    });
    Library:Create('UIPadding', { PaddingLeft = UDim.new(0, 7), Parent = KeybindContainer });

    Library.KeybindFrame     = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible = Bool; end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 13);
    Library.Watermark.Size = UDim2.new(0, X + 18, 0, (Y * 1.5) + 4);
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 13);
    YSize = YSize + 8

    local NotifyOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex           = 100;
        Parent           = Library.NotificationArea;
    });
    Library:AddCorner(NotifyOuter, 6)
    Library:MakeShadow(NotifyOuter, 12, 0.6)
    Library:AddToRegistry(NotifyOuter, { BackgroundColor3 = 'MainColor'; }, true);

    -- Accent left bar
    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 0, 0, 0);
        Size             = UDim2.new(0, 3, 1, 0);
        ZIndex           = 104;
        Parent           = NotifyOuter;
    });
    Library:AddToRegistry(LeftColor, { BackgroundColor3 = 'AccentColor'; }, true);

    local NotifyLabel = Library:CreateLabel({
        Position       = UDim2.new(0, 8, 0, 0);
        Size           = UDim2.new(1, -8, 1, 0);
        Text           = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize       = 13;
        ZIndex         = 103;
        Parent         = NotifyOuter;
    });

    -- Subtle accent glow
    Library:MakeGlow(NotifyOuter, 10, 0.82).Visible = true

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 14, 0, YSize), 'Out', 'Quad', 0.35, true);

    task.spawn(function()
        wait(Time or 5);
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.35, true);
        wait(0.35);
        NotifyOuter:Destroy();
    end);
end;

-- ============================================================
--  WINDOW
-- ============================================================

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config    = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then Config = ...;
    else Config.Title = Arguments[1]; Config.AutoShow = Arguments[2] or false; end

    if type(Config.Title)       ~= 'string'  then Config.Title       = 'No title' end
    if type(Config.TabPadding)  ~= 'number'  then Config.TabPadding  = 0          end
    if type(Config.MenuFadeTime)~= 'number'  then Config.MenuFadeTime = 0.2       end
    if typeof(Config.Position)  ~= 'UDim2'  then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size)      ~= 'UDim2'  then Config.Size     = UDim2.fromOffset(550, 600) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position    = UDim2.fromScale(0.5, 0.5)
    end

    local Window = { Tabs = {}; };

    -- Modern window: rounded, soft shadow
    local Outer = Library:Create('Frame', {
        AnchorPoint      = Config.AnchorPoint,
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel  = 0;
        Position         = Config.Position,
        Size             = Config.Size,
        Visible          = false;
        ZIndex           = 1;
        Parent           = ScreenGui;
    });
    Library:AddCorner(Outer, 10)
    Library:MakeShadow(Outer, 28, 0.45, 6)

    Library:MakeDraggable(Outer, 28);

    -- Accent border via UIStroke
    local WindowStroke = Library:Create('UIStroke', {
        Color     = Library.AccentColor;
        Thickness = 1.5;
        Parent    = Outer;
    });
    Library:AddToRegistry(WindowStroke, { Color = 'AccentColor'; });

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 1, 0, 1);
        Size             = UDim2.new(1, -2, 1, -2);
        ZIndex           = 1;
        Parent           = Outer;
    });
    Library:AddCorner(Inner, 9)
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; });

    -- Title
    local WindowLabel = Library:CreateLabel({
        Position       = UDim2.new(0, 10, 0, 0);
        Size           = UDim2.new(0, 0, 0, 28);
        Text           = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize       = 15;
        ZIndex         = 1;
        Parent         = Inner;
    });

    -- Thin accent line below title
    local TitleLine = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 8, 0, 27);
        Size             = UDim2.new(1, -16, 0, 1);
        ZIndex           = 2;
        Parent           = Inner;
    });
    Library:AddToRegistry(TitleLine, { BackgroundColor3 = 'AccentColor'; });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 8, 0, 29);
        Size             = UDim2.new(1, -16, 1, -37);
        ZIndex           = 1;
        Parent           = Inner;
    });
    Library:AddCorner(MainSectionOuter, 7)
    Library:AddToRegistry(MainSectionOuter, { BackgroundColor3 = 'BackgroundColor'; });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 0, 0, 0);
        Size             = UDim2.new(1, 0, 1, 0);
        ZIndex           = 1;
        Parent           = MainSectionOuter;
    });
    Library:AddCorner(MainSectionInner, 7)
    Library:AddToRegistry(MainSectionInner, { BackgroundColor3 = 'BackgroundColor'; });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size     = UDim2.new(1, -16, 0, 22);
        ZIndex   = 1;
        Parent   = MainSectionInner;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding       = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder     = Enum.SortOrder.LayoutOrder;
        Parent        = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 8, 0, 32);
        Size             = UDim2.new(1, -16, 1, -40);
        ZIndex           = 2;
        Parent           = MainSectionInner;
    });
    Library:AddCorner(TabContainer, 6)
    Library:AddToRegistry(TabContainer, { BackgroundColor3 = 'MainColor'; });

    function Window:SetWindowTitle(Title) WindowLabel.Text = Title; end;

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}; Tabboxes = {}; };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 14);

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(0, TabButtonWidth + 14, 1, 0);
            ZIndex           = 1;
            Parent           = TabArea;
        });
        Library:AddCorner(TabButton, 5)
        Library:AddToRegistry(TabButton, { BackgroundColor3 = 'BackgroundColor'; });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size     = UDim2.new(1, 0, 1, -1);
            Text     = Name;
            TextSize = 13;
            ZIndex   = 1;
            Parent   = TabButton;
        });

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Position         = UDim2.new(0, 0, 1, 0);
            Size             = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex           = 3;
            Parent           = TabButton;
        });
        Library:AddToRegistry(Blocker, { BackgroundColor3 = 'MainColor'; });

        local TabFrame = Library:Create('Frame', {
            Name             = 'TabFrame',
            BackgroundTransparency = 1;
            Position         = UDim2.new(0, 0, 0, 0);
            Size             = UDim2.new(1, 0, 1, 0);
            Visible          = false;
            ZIndex           = 2;
            Parent           = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            Position               = UDim2.new(0, 7, 0, 7);
            Size                   = UDim2.new(0.5, -11, 0, 509);
            CanvasSize             = UDim2.new(0, 0, 0, 0);
            BottomImage            = '';
            TopImage               = '';
            ScrollBarThickness     = 0;
            ZIndex                 = 2;
            Parent                 = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel        = 0;
            Position               = UDim2.new(0.5, 4, 0, 7);
            Size                   = UDim2.new(0.5, -11, 0, 509);
            CanvasSize             = UDim2.new(0, 0, 0, 0);
            BottomImage            = '';
            TopImage               = '';
            ScrollBarThickness     = 0;
            ZIndex                 = 2;
            Parent                 = TabFrame;
        });

        for _, Side in next, { LeftSide, RightSide } do
            Library:Create('UIListLayout', {
                Padding             = UDim.new(0, 8);
                FillDirection       = Enum.FillDirection.Vertical;
                SortOrder           = Enum.SortOrder.LayoutOrder;
                HorizontalAlignment = Enum.HorizontalAlignment.Center;
                Parent              = Side;
            });
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, T in next, Window.Tabs do T:HideTab(); end;
            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 0, 509);
                ZIndex           = 2;
                Parent           = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddCorner(BoxOuter, 7)
            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = 'BackgroundColor'; });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, -2, 1, -2);
                Position         = UDim2.new(0, 1, 0, 1);
                ZIndex           = 4;
                Parent           = BoxOuter;
            });
            Library:AddCorner(BoxInner, 7)
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor'; });

            -- Rounded accent highlight at top
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 0, 3);
                ZIndex           = 5;
                Parent           = BoxInner;
            });
            Library:AddCorner(Highlight, 3)
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });

            -- Subtle glow on the highlight
            Library:MakeGlow(Highlight, 8, 0.8).Visible = true

            local GroupboxLabel = Library:CreateLabel({
                Size           = UDim2.new(1, 0, 0, 18);
                Position       = UDim2.new(0, 6, 0, 4);
                TextSize       = 13;
                Text           = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex         = 5;
                Parent         = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 22);
                Size     = UDim2.new(1, -4, 1, -22);
                ZIndex   = 1;
                Parent   = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder     = Enum.SortOrder.LayoutOrder;
                Parent        = Container;
            });

            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;
                BoxOuter.Size = UDim2.new(1, 0, 0, 22 + Size + 4);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();
            Tab.Groupboxes[Info.Name] = Groupbox;
            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)  return Tab:AddGroupbox({ Side = 1; Name = Name; }); end;
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2; Name = Name; }); end;

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {}; };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 0, 0);
                ZIndex           = 2;
                Parent           = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddCorner(BoxOuter, 7)
            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = 'BackgroundColor'; });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, -2, 1, -2);
                Position         = UDim2.new(0, 1, 0, 1);
                ZIndex           = 4;
                Parent           = BoxOuter;
            });
            Library:AddCorner(BoxInner, 7)
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor'; });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 0, 3);
                ZIndex           = 10;
                Parent           = BoxInner;
            });
            Library:AddCorner(Highlight, 3)
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 2);
                Size     = UDim2.new(1, 0, 0, 20);
                ZIndex   = 5;
                Parent   = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection       = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder           = Enum.SortOrder.LayoutOrder;
                Parent              = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel  = 0;
                    Size             = UDim2.new(0.5, 0, 1, 0);
                    ZIndex           = 6;
                    Parent           = TabboxButtons;
                });
                Library:AddToRegistry(Button, { BackgroundColor3 = 'MainColor'; });

                local ButtonLabel = Library:CreateLabel({
                    Size           = UDim2.new(1, 0, 1, 0);
                    TextSize       = 13;
                    Text           = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex         = 7;
                    Parent         = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel  = 0;
                    Position         = UDim2.new(0, 0, 1, 0);
                    Size             = UDim2.new(1, 0, 0, 1);
                    Visible          = false;
                    ZIndex           = 9;
                    Parent           = Button;
                });
                Library:AddToRegistry(Block, { BackgroundColor3 = 'BackgroundColor'; });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 22);
                    Size     = UDim2.new(1, -4, 1, -22);
                    ZIndex   = 1;
                    Visible  = false;
                    Parent   = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder     = Enum.SortOrder.LayoutOrder;
                    Parent        = Container;
                });

                function Tab:Show()
                    for _, T in next, Tabbox.Tabs do T:Hide(); end;
                    Container.Visible = true; Block.Visible = true;
                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false; Block.Visible = false;
                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;
                    for _ in next, Tabbox.Tabs do TabCount = TabCount + 1; end;
                    for _, Btn in next, TabboxButtons:GetChildren() do
                        if not Btn:IsA('UIListLayout') then
                            Btn.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;
                    if not Container.Visible then return; end;
                    local Size = 0;
                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;
                    BoxOuter.Size = UDim2.new(1, 0, 0, 22 + Size + 4);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show(); Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;
                setmetatable(Tab, BaseGroupbox);
                Tab:AddBlank(3);
                Tab:Resize();
                if #TabboxButtons:GetChildren() == 2 then Tab:Show(); end;
                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;
            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)  return Tab:AddTabbox({ Name = Name, Side = 1; }); end;
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2; }); end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab(); end;
        end);

        if #TabContainer:GetChildren() == 1 then Tab:ShowTab(); end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    -- Toggle / Fade logic (unchanged)
    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1; Size = UDim2.new(0,0,0,0); Visible = true; Text = ''; Modal = false; Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;
    local Fading  = false;

    function Library:Toggle()
        if Fading then return; end;
        local FadeTime = Config.MenuFadeTime;
        Fading  = true;
        Toggled = not Toggled;
        ModalElement.Modal = Toggled;

        if Toggled then
            Outer.Visible = true;
            task.spawn(function()
                local State = InputService.MouseIconEnabled;
                local Cursor        = Drawing.new('Triangle');
                Cursor.Thickness    = 1; Cursor.Filled = true; Cursor.Visible = true;
                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1; CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0,0,0); CursorOutline.Visible = true;

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;
                    local mPos = InputService:GetMouseLocation();
                    Cursor.Color  = Library.AccentColor;
                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6,  mPos.Y + 16);
                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;
                    RenderStepped:Wait();
                end;
                InputService.MouseIconEnabled = State;
                Cursor:Remove(); CursorOutline:Remove();
            end);
        end;

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {};
            if     Desc:IsA('ImageLabel')                          then table.insert(Properties, 'ImageTransparency'); table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox')    then table.insert(Properties, 'TextTransparency');
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('UIStroke')                            then table.insert(Properties, 'Transparency'); end;

            local Cache = TransparencyCache[Desc];
            if not Cache then Cache = {}; TransparencyCache[Desc] = Cache; end;

            for _, Prop in next, Properties do
                if not Cache[Prop] then Cache[Prop] = Desc[Prop]; end;
                if Cache[Prop] == 1 then continue; end;
                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
            end;
        end;

        task.wait(FadeTime);
        Outer.Visible = Toggled;
        Fading = false;
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;
    return Window;
end;

-- Player/Team list refresh (unchanged)
local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;
Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

getgenv().Library = Library
return Library
