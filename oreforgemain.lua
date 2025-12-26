--!optimize 2
loadstring(game:HttpGet("https://raw.githubusercontent.com/Sploiter13/severefuncs/refs/heads/main/merge.lua"))();

-- // SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local MouseService = game:GetService("MouseService")

-- Safe Service Get
local UserInputService = nil
pcall(function() UserInputService = game:GetService("UserInputService") end)

-- ============================================================================
-- 1. DATA & CONFIGURATION
-- ============================================================================

local CustomSettings = _G.OreUnicornCustomSettings or {}

local ActiveRocks = {}
local ActiveOres = {}
local EnabledRocks = {}
local RockNamesSet = {}
local RockList = {}
local FallbackRocks = {}

-- NEW: Mob farm data
local MobList = {}
local EnabledMobs = {}
local MobCurrentTarget = nil

local OreDatabase = {
    ["Stonewake"] = {
        "Stone", "Sand Stone", "Copper", "Iron", "Tin", "Silver", "Gold",
        "Mushroomite", "Platinum", "Bananite", "Cardboardite", "Aite", "Poopite"
    },
    ["Forgotten"] = {
        "Cobalt", "Titanium", "Lapis Lazuli", "Volcanic Rock", "Quartz", "Amethyst",
        "Topaz", "Diamond", "Sapphire", "Boneite", "Slimite", "Dark Boneite",
        "Cuprite", "Obsidian", "Emerald", "Ruby", "Rivalite", "Uranium", "Mythril",
        "Eye Ore", "Fireite", "Magmaite", "Lightite", "Demonite", "Darkryte"
    },
    ["Goblin"] = {
        "Blue Crystal", "Orange Crystal", "Green Crystal", "Purple Crystal",
        "Crimson Crystal", "Rainbow Crystal", "Arcane Crystal"
    },
    ["Frozen"] = {
        -- original Frozen ores
        "Tungsten",
        "Sulfur",
        "Pumice",
        "Graphite",
        "Aetherit",
        "Scheelite",
        "Larimar",
        "Neurotite",
        "Frost Fossil",
        "Tide Carve",
        "Velchire",
        "Sanctis",
        "Snowite",
        "Iceite",

        -- new Frozen ores
        "Mistvein",
        "Lgarite",
        "Voidfractal",
        "Moltenfrost",
        "Crimsonite",
        "Malachite",
        "Aqujade",
        "Cryptex",
        "Galestor",
        "Voidstar",
        "Etherealite",
        "Suryafal",
        "Heavenite",
        "Gargantuan"
    }
}

local Config = {
    DebugMode = CustomSettings.DebugMode or false,
    FolderName = "Rocks",
    LavaFolder = CustomSettings.LavaFolder or "Island2VolcanicDepths",
    ToolName = CustomSettings.PickaxeName or "Pickaxe",
    WeaponName = CustomSettings.WeaponName or "Weapon",

    -- MINING
    MineDistance = CustomSettings.MineDistance or 10,
    UnderOffset = CustomSettings.UnderOffset or 7,
    AboveOffset = CustomSettings.AboveOffset or 7,
    MiningPosition = CustomSettings.MiningPosition or "Under",
    ClickDelay = CustomSettings.ClickDelay or 0.25,

    -- FILTER
    FilterEnabled = CustomSettings.FilterEnabled or false,
    FilterVolcanicOnly = CustomSettings.FilterVolcanicOnly or false,
    FilterWhitelist = CustomSettings.FilterWhitelist or {},

    -- SYSTEM
    AutoScanRate = CustomSettings.AutoScanRate or 1,
    SkyHeight = CustomSettings.SkyHeight or 500,

    MainEnabled = false,
    EspEnabled = CustomSettings.EspEnabled or false,
    OnlyLava = CustomSettings.OnlyLava or false,
    TravelSpeed = CustomSettings.TravelSpeed or 300,
    InstantTP_Range = CustomSettings.InstantTP_Range or 60,
    AutoEquip = CustomSettings.AutoEquip or false,

    -- FALLBACK
    FallbackEnabled = CustomSettings.FallbackEnabled or false,

    -- AUTO SELL
    AutoSell = CustomSettings.AutoSell or false,
    MerchantPos = Vector3.new(
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.X or -132.07,
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.Y or 21.61,
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.Z or -20.92
    ),
    SellTimeout = CustomSettings.SellTimeout or 60,

    EspTextColor = Color3.fromRGB(
        CustomSettings.EspColor and CustomSettings.EspColor.R or 100,
        CustomSettings.EspColor and CustomSettings.EspColor.G or 255,
        CustomSettings.EspColor and CustomSettings.EspColor.B or 100
    ),
    EspTextSize = CustomSettings.EspTextSize or 16,
}

-- NEW: Mob farm config
local MobConfig = {
    Enabled = false,
    UnderOffset = 8,
    AttackDistance = 8,
}

if CustomSettings.EnabledRocks then
    for rockName, enabled in pairs(CustomSettings.EnabledRocks) do
        EnabledRocks[rockName] = enabled
    end
end

local MainUI = {
    X = 100, Y = 100, Width = 310, BaseHeight = 380, Visible = true,
    Dragging = false, DragOffset = {x = 0, y = 0},
    ToggleBtn = { X = 0, Y = 500, W = 40, H = 40 }
}

local FilterUI = {
    X = 450, Y = 100, Width = 310, BaseHeight = 262, Visible = false,
    Dragging = false, DragOffset = {x = 0, y = 0},
    CurrentCategory = "Stonewake"
}

local FallbackUI = {
    X = 800, Y = 100, Width = 260, BaseHeight = 200, Visible = false,
    Dragging = false, DragOffset = {x = 0, y = 0},
}

-- NEW: Mob farm UI
local MobUI = {
    X = 100, Y = 450, Width = 260, BaseHeight = 160, Visible = false,
    Dragging = false, DragOffset = {x = 0, y = 0},
}

-- COLORS (updated theme)
local Colors = {
    Bg = Color3.fromRGB(10, 20, 45),              -- dark blue background
    Header = Color3.fromRGB(20, 35, 80),
    Text = Color3.fromRGB(255, 255, 255),
    On = Color3.fromRGB(0, 128, 70),              -- emerald green
    Off = Color3.fromRGB(255, 140, 0),            -- orange
    Btn = Color3.fromRGB(40, 60, 100),            -- neutral button
    Menu = Color3.fromRGB(140, 70, 200),          -- purple (menus)
    Lava = Color3.fromRGB(255, 100, 0),
    Gold = Color3.fromRGB(255, 200, 0),
    Debug = Color3.fromRGB(255, 0, 255),
}

local LocalPlayer = Players.LocalPlayer
local CurrentTarget = nil
local MouseState = { WasPressed = false }
local EquipDebounce = 0
local LastMineClick = 0
local TargetLocked = false
local IsSelling = false

-- ============================================================================
-- 2. SAFETY & UI HELPERS
-- ============================================================================

local function IsValid(Obj)
    return Obj and Obj.Parent
end

local function SafeGetAttribute(Obj, Attr)
    if not IsValid(Obj) then return nil end
    return Obj:GetAttribute(Attr)
end

local function SafeGetName(Obj)
    if not IsValid(Obj) then return nil end
    return Obj.Name
end

local function GetRockHealth(Rock)
    local H = SafeGetAttribute(Rock, "Health")
    return (H and tonumber(H)) or 0
end

local function GetRockMaxHealth(Rock)
    local H = SafeGetAttribute(Rock, "MaxHealth")
    return (H and tonumber(H)) or 0
end

local function GetPosition(Obj)
    if not IsValid(Obj) then return nil end
    if Obj.ClassName == "Model" then
        if Obj.PrimaryPart then return Obj.PrimaryPart.Position end
        local kids = Obj:GetChildren()
        for i = 1, #kids do
            local child = kids[i]
            if child.ClassName == "Part" or child.ClassName == "MeshPart" then
                return child.Position
            end
        end
    elseif string.find(Obj.ClassName, "Part") then
        return Obj.Position
    end
    return nil
end

local function IsVolcanic(Rock)
    if not IsValid(Rock) then return false end
    local N = SafeGetName(Rock)
    if N == "Volcanic Rock" then return true end
    local Attr = SafeGetAttribute(Rock, "Ore")
    if Attr and tostring(Attr) == "Volcanic Rock" then return true end
    if Rock:FindFirstChild("Volcanic Rock") then return true end
    return false
end

-- UI path helpers (for autosell)
local function GetObject(pathStr)
    local segments = string.split(pathStr, ".")
    local current = game
    for i, name in ipairs(segments) do
        if i == 1 and name == "game" then
            -- root
        elseif current == game and name == "Players" then
            current = Players
        elseif current == Players and name == "LocalPlayer" then
            current = Players.LocalPlayer
        else
            local nextObj = current:FindFirstChild(name)
            if not nextObj then return nil end
            current = nextObj
        end
    end
    return current
end

local function GetTextMemory(obj)
    if not obj then return "" end
    if memory and memory.readstring then
        return memory.readstring(obj, 3648) or ""
    else
        return obj.Text
    end
end

local function ClickObject(obj)
    if not obj then return false end
    local absPos = obj.AbsolutePosition
    local absSize = obj.AbsoluteSize
    if absPos and absSize and MouseService and mouse1click then
        local centerX = absPos.X + (absSize.X / 2)
        local centerY = absPos.Y + (absSize.Y / 2)
        MouseService:SetMouseLocation(centerX, centerY)
        task.wait(0.05)
        mouse1click()
        return true
    end
    return false
end

-- ============================================================================
-- 3. MOB HELPERS (for Mob Farm)
-- ============================================================================

local function IsAlive(Model)
    if not Model then return false end
    local Humanoid = Model:FindFirstChild("Humanoid")
    local RootPart = Model:FindFirstChild("HumanoidRootPart")
    return Humanoid and RootPart and Humanoid.Health > 0
end

local function GetBaseName(Name)
    local Base = string.match(Name, "^(.-)%d*$")
    return (Base and Base ~= "") and Base or Name
end

local function RefreshMobList()
    local Folder = Workspace:FindFirstChild("Living")
    if not Folder then MobList = {} return end

    local Unique = {}
    local NewList = {}

    for _, Child in ipairs(Folder:GetChildren()) do
        if Players:FindFirstChild(Child.Name) then
            continue
        end
        if Child.ClassName == "Model" and Child:FindFirstChild("Humanoid") then
            local BaseName = GetBaseName(Child.Name)
            if not Unique[BaseName] then
                Unique[BaseName] = true
                table.insert(NewList, BaseName)
                if EnabledMobs[BaseName] == nil then
                    EnabledMobs[BaseName] = false
                end
            end
        end
    end

    table.sort(NewList)
    MobList = NewList
end

local function FindEnabledMobTarget(myPos)
    local Folder = Workspace:FindFirstChild("Living")
    if not Folder then return nil end

    local closest
    local bestDist = math.huge

    for _, Mob in ipairs(Folder:GetChildren()) do
        if Players:FindFirstChild(Mob.Name) then
            continue
        end
        if Mob.ClassName == "Model" and IsAlive(Mob) then
            local baseName = GetBaseName(Mob.Name)
            if EnabledMobs[baseName] then
                local root = Mob:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = vector.magnitude(root.Position - myPos)
                    if dist < bestDist then
                        bestDist = dist
                        closest = Mob
                    end
                end
            end
        end
    end

    return closest
end

-- ============================================================================
-- 4. ORE DETECTION & FILTERING
-- ============================================================================

local function GetAllRevealedOres(Rock)
    if not IsValid(Rock) then return {} end

    local AllOres = {}

    local Attr = SafeGetAttribute(Rock, "Ore")
    if Attr and Attr ~= "" then
        table.insert(AllOres, tostring(Attr))
    end

    local ok, children = pcall(function()
        return Rock:GetChildren()
    end)
    if ok and children then
        for _, Child in ipairs(children) do
            if Child and Child.Name == "Ore" then
                local ChildAttr = SafeGetAttribute(Child, "Ore")
                if ChildAttr and ChildAttr ~= "" then
                    local OreStr = tostring(ChildAttr)
                    local already = false
                    for _, existing in ipairs(AllOres) do
                        if existing == OreStr then
                            already = true
                            break
                        end
                    end
                    if not already then
                        table.insert(AllOres, OreStr)
                    end
                end
            end
        end
    end

    return AllOres
end

local function IsOreWanted(CurrentOre)
    if not CurrentOre then return false end
    CurrentOre = tostring(CurrentOre)

    if Config.FilterWhitelist[CurrentOre] then return true end

    local NoSpace = string.gsub(CurrentOre, " ", "")
    local Lower = string.lower(CurrentOre)
    local LowerNoSpace = string.lower(NoSpace)

    for whitelistedOre, enabled in pairs(Config.FilterWhitelist) do
        if enabled then
            if whitelistedOre == CurrentOre then return true end

            if string.lower(whitelistedOre) == Lower then return true end

            local CleanWL = string.gsub(whitelistedOre, " ", "")
            if CleanWL == NoSpace then return true end

            if string.lower(CleanWL) == LowerNoSpace then return true end
        end
    end

    return false
end

local function HasAnyWantedOre(Rock)
    local AllOres = GetAllRevealedOres(Rock)

    if #AllOres == 0 then
        return false, nil
    end

    for _, OreName in ipairs(AllOres) do
        if IsOreWanted(OreName) then
            return true, AllOres
        end
    end

    return false, AllOres
end

local function GarbageCollect()
    for i = #ActiveRocks, 1, -1 do
        if not IsValid(ActiveRocks[i]) then
            table.remove(ActiveRocks, i)
        end
    end
    for i = #ActiveOres, 1, -1 do
        if not IsValid(ActiveOres[i]) then
            table.remove(ActiveOres, i)
        end
    end
    if CurrentTarget then
        if not IsValid(CurrentTarget) or GetRockHealth(CurrentTarget) <= 0 then
            CurrentTarget = nil
            TargetLocked = false
        end
    end
    if MobCurrentTarget and not IsAlive(MobCurrentTarget) then
        MobCurrentTarget = nil
    end
end

-- ============================================================================
-- 5. INTERACTION & MOVEMENT
-- ============================================================================

local function IsMouseInRect(MousePos, RectX, RectY, RectW, RectH)
    return MousePos.X >= RectX and MousePos.X <= RectX + RectW
        and MousePos.Y >= RectY and MousePos.Y <= RectY + RectH
end

local function CheckClick()
    local IsPressed = false
    if isleftpressed then
        IsPressed = isleftpressed()
    elseif UserInputService then
        pcall(function()
            IsPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end)
    end

    if IsPressed and not MouseState.WasPressed then
        MouseState.WasPressed = true
        return true
    end

    MouseState.WasPressed = IsPressed
    return false
end

local function EquipTool(ToolName, SlotKeyCode)
    local Char = LocalPlayer.Character
    if not Char then return false end

    if Char:FindFirstChild(ToolName) then
        return true
    end

    local Backpack = LocalPlayer.Backpack
    if Backpack and Backpack:FindFirstChild(ToolName) then
        if keypress and SlotKeyCode then
            keypress(SlotKeyCode)
            keyrelease(SlotKeyCode)
        else
            if SlotKeyCode == 49 then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            elseif SlotKeyCode == 50 then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
            end
        end
        return true
    end
    return false
end

local function CheckAutoEquip(Character)
    if not Config.AutoEquip then return end
    if os.clock() - EquipDebounce < 1 then return end

    local Tool = Character:FindFirstChild(Config.ToolName)
    if not Tool then
        local Backpack = LocalPlayer.Backpack
        if Backpack and Backpack:FindFirstChild(Config.ToolName) then
            EquipTool(Config.ToolName, 49)
            EquipDebounce = os.clock()
        end
    end
end

local function SkyHopMove(RootPart, GoalPos, DeltaTime)
    local CurrentPos = RootPart.Position
    local Diff = GoalPos - CurrentPos
    local Dist = vector.magnitude(Diff)

    if Dist <= Config.InstantTP_Range then
        RootPart.CFrame = CFrame.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
        return true
    end

    if CurrentPos.Y < Config.SkyHeight - 10 then
        RootPart.CFrame = CFrame.new(CurrentPos.X, Config.SkyHeight, CurrentPos.Z)
        RootPart.Velocity = vector.zero
        return false
    end

    local FlatDiff = vector.create(GoalPos.X - CurrentPos.X, 0, GoalPos.Z - CurrentPos.Z)
    local FlatDist = vector.magnitude(FlatDiff)

    if FlatDist < 15 then
        RootPart.CFrame = CFrame.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
        RootPart.Velocity = vector.zero
        return false
    end

    local Step = Config.TravelSpeed * DeltaTime
    local Direction = vector.normalize(FlatDiff)
    local MoveVec = Direction * Step
    local NewPos = CurrentPos + MoveVec

    RootPart.CFrame = CFrame.new(NewPos.X, Config.SkyHeight, NewPos.Z)
    RootPart.Velocity = vector.zero
    return false
end

local function FindNearestRock()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local MyPos = Root.Position

    local primary = {}
    local fallback = {}

    for _, Rock in ipairs(ActiveRocks) do
        if not IsValid(Rock) then
            continue
        end

        local RName = SafeGetName(Rock)
        if not RName then
            continue
        end

        local HP = GetRockHealth(Rock)
        if HP <= 0 then
            continue
        end

        local MaxHP = GetRockMaxHealth(Rock)
        local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)
        if not IsFresh then
            continue
        end

        local Pos = GetPosition(Rock)
        if not Pos then
            continue
        end

        local useRock = true
        if Config.FilterEnabled then
            local HasWanted, _ = HasAnyWantedOre(Rock)
            local ApplyFilter = true

            if Config.FilterVolcanicOnly and not IsVolcanic(Rock) then
                ApplyFilter = false
            end

            if ApplyFilter and not HasWanted then
                useRock = false
            end
        end

        if not useRock then
            continue
        end

        local Dist = vector.magnitude(Pos - MyPos)

        if EnabledRocks[RName] then
            table.insert(primary, { rock = Rock, dist = Dist })
        end

        if Config.FallbackEnabled and FallbackRocks[RName] then
            table.insert(fallback, { rock = Rock, dist = Dist })
        end
    end

    local function pickNearest(list)
        local best, bestDist
        for _, item in ipairs(list) do
            if not best or item.dist < bestDist then
                best = item.rock
                bestDist = item.dist
            end
        end
        return best
    end

    local chosen = pickNearest(primary)
    if chosen then return chosen end

    if Config.FallbackEnabled then
        chosen = pickNearest(fallback)
        if chosen then return chosen end
    end

    return nil
end

-- ============================================================================
-- 6. AUTO SELL SYSTEM (fixed logic)
-- ============================================================================

local function PressE()
    if keypress then
        keypress(0x45)
        task.wait(0.05)
        keyrelease(0x45)
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end

local function PerformAutoSell()
    if IsSelling then return end
    if not Config.AutoSell then return end

    local pName = LocalPlayer.Name
    local Path_Capacity = "game.Players." .. pName .. ".PlayerGui.Menu.Frame.Frame.Menus.Stash.Capacity.Text"

    local capObj = GetObject(Path_Capacity)
    if not capObj then return end

    local text = GetTextMemory(capObj)
    local current, max = text:match("(%d+)/(%d+)")
    if not (current and max) then return end

    if tonumber(current) < tonumber(max) then
        return
    end

    IsSelling = true
    CurrentTarget = nil
    MobCurrentTarget = nil
    TargetLocked = false

    local StartTime = os.clock()
    local function CheckTimeout()
        if os.clock() - StartTime > Config.SellTimeout then
            warn(">> AUTO SELL STUCK! Restarting process...")
            IsSelling = false
            return true
        end
        return false
    end

    local Char = LocalPlayer.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if Root then
        local arrived = false
        while not arrived and Config.AutoSell and Root.Parent do
            if CheckTimeout() then return end
            arrived = SkyHopMove(Root, Config.MerchantPos, 0.03)
            task.wait(0.03)
        end
    end

    local Path_Billboard = "game.Players." .. pName .. ".PlayerGui.DialogueUI.ResponseBillboard"
    local bb = GetObject(Path_Billboard)
    local startInteract = os.clock()

    while (not bb or not bb.Visible) and (os.clock() - startInteract < 10) do
        if CheckTimeout() then return end
        PressE()
        task.wait(0.5)
        bb = GetObject(Path_Billboard)
    end
    task.wait(0.5)

    local Path_DialogueBtn = "game.Players." .. pName .. ".PlayerGui.DialogueUI.ResponseBillboard.Response.Button"
    local Path_SellUI = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell"
    local Path_SelectAll = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.SelectAll"
    local Path_SelectTitle = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.SelectAll.Frame.Title"
    local Path_Accept = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.Accept"

    -- Step 1: open sell UI
    local timeout = 0
    while timeout < 20 do
        if CheckTimeout() then return end
        local sellUI = GetObject(Path_SellUI)
        if sellUI and sellUI.Visible then break end
        local diagBtn = GetObject(Path_DialogueBtn)
        if diagBtn then ClickObject(diagBtn) end
        task.wait(0.5)
        timeout = timeout + 1
    end

    -- Step 2: Select All
    timeout = 0
    while timeout < 20 do
        if CheckTimeout() then return end
        local titleObj = GetObject(Path_SelectTitle)
        local selectBtn = GetObject(Path_SelectAll)
        if titleObj then
            local txt = GetTextMemory(titleObj)
            if txt == "Unselect All" then break end
            if selectBtn then ClickObject(selectBtn) end
        end
        task.wait(0.5)
        timeout = timeout + 1
    end

    -- Step 3: Accept sell
    timeout = 0
    while timeout < 20 do
        if CheckTimeout() then return end
        local bb2 = GetObject(Path_Billboard)
        if bb2 and bb2.Visible then break end
        local accBtn = GetObject(Path_Accept)
        if accBtn then ClickObject(accBtn) end
        task.wait(0.5)
        timeout = timeout + 1
    end

    -- Step 4: Close dialogue
    timeout = 0
    while timeout < 20 do
        if CheckTimeout() then return end
        local bb3 = GetObject(Path_Billboard)
        if not bb3 or not bb3.Visible then break end
        local diagBtn2 = GetObject(Path_DialogueBtn)
        if diagBtn2 then ClickObject(diagBtn2) end
        task.wait(0.5)
        timeout = timeout + 1
    end

    IsSelling = false
end

-- ============================================================================
-- 7. SCANNERS
-- ============================================================================

local function PerformScan()
    local MainFolder = Workspace:FindFirstChild(Config.FolderName)
    if not MainFolder then return end

    local ScanTarget = MainFolder
    if Config.OnlyLava then
        local Lava = MainFolder:FindFirstChild(Config.LavaFolder)
        if Lava then
            ScanTarget = Lava
        else
            ActiveRocks = {}
            return
        end
    end

    local FoundInstances = {}
    local Descendants = ScanTarget:GetDescendants()

    for _, Obj in ipairs(Descendants) do
        if Obj.ClassName == "Model" and IsValid(Obj) then
            local H = Obj:GetAttribute("Health")
            if H and tonumber(H) > 0 then
                table.insert(FoundInstances, Obj)
                local N = Obj.Name
                if not RockNamesSet[N] then
                    RockNamesSet[N] = true
                    table.insert(RockList, N)
                    table.sort(RockList)
                    if EnabledRocks[N] == nil then
                        EnabledRocks[N] = false
                    end
                    if FallbackRocks[N] == nil then
                        FallbackRocks[N] = false
                    end
                end
            end
        end
    end

    ActiveRocks = FoundInstances
end

task.spawn(function()
    while true do
        PerformScan()
        task.spawn(PerformAutoSell)

        if Config.EspEnabled then
            local FoundOres = {}
            local Target = Workspace:FindFirstChild(Config.FolderName)
            if Config.OnlyLava and Target then
                Target = Target:FindFirstChild(Config.LavaFolder)
            end

            if Target then
                local Descendants = Target:GetDescendants()
                for _, Obj in ipairs(Descendants) do
                    if Obj.Name == "Ore" then
                        table.insert(FoundOres, Obj)
                    end
                end
                ActiveOres = FoundOres
            end
        else
            ActiveOres = {}
        end

        task.wait(Config.AutoScanRate)
    end
end)

-- ============================================================================
-- 8. RENDER LOOP
-- ============================================================================

local function UpdateLoop()
    GarbageCollect()

    local DeltaTime = 0.03
    local MousePos = MouseService and MouseService:GetMouseLocation() or Vector2.new(0, 0)
    local Clicked = CheckClick()
    local IsLeftDown = false
    if isleftpressed then
        IsLeftDown = isleftpressed()
    end

    -- DRAGGING
    if IsLeftDown then
        if not MainUI.Dragging and not FilterUI.Dragging and not FallbackUI.Dragging and not MobUI.Dragging then
            if MainUI.Visible and IsMouseInRect(MousePos, MainUI.X, MainUI.Y, MainUI.Width, 30) then
                MainUI.Dragging = true
                MainUI.DragOffset.x = MousePos.X - MainUI.X
                MainUI.DragOffset.y = MousePos.Y - MainUI.Y
            elseif FilterUI.Visible and IsMouseInRect(MousePos, FilterUI.X, FilterUI.Y, FilterUI.Width, 30) then
                FilterUI.Dragging = true
                FilterUI.DragOffset.x = MousePos.X - FilterUI.X
                FilterUI.DragOffset.y = MousePos.Y - FilterUI.Y
            elseif FallbackUI.Visible and IsMouseInRect(MousePos, FallbackUI.X, FallbackUI.Y, FallbackUI.Width, 30) then
                FallbackUI.Dragging = true
                FallbackUI.DragOffset.x = MousePos.X - FallbackUI.X
                FallbackUI.DragOffset.y = MousePos.Y - FallbackUI.Y
            elseif MobUI.Visible and IsMouseInRect(MousePos, MobUI.X, MobUI.Y, MobUI.Width, 30) then
                MobUI.Dragging = true
                MobUI.DragOffset.x = MousePos.X - MobUI.X
                MobUI.DragOffset.y = MousePos.Y - MobUI.Y
            end
        end

        if MainUI.Dragging then
            MainUI.X = MousePos.X - MainUI.DragOffset.x
            MainUI.Y = MousePos.Y - MainUI.DragOffset.y
        end
        if FilterUI.Dragging then
            FilterUI.X = MousePos.X - FilterUI.DragOffset.x
            FilterUI.Y = MousePos.Y - FilterUI.DragOffset.y
        end
        if FallbackUI.Dragging then
            FallbackUI.X = MousePos.X - FallbackUI.DragOffset.x
            FallbackUI.Y = MousePos.Y - FallbackUI.DragOffset.y
        end
        if MobUI.Dragging then
            MobUI.X = MousePos.X - MobUI.DragOffset.x
            MobUI.Y = MousePos.Y - MobUI.DragOffset.y
        end
    else
        MainUI.Dragging = false
        FilterUI.Dragging = false
        FallbackUI.Dragging = false
        MobUI.Dragging = false
    end

    -- TOGGLE BUTTON (small button for main menu)
    DrawingImmediate.FilledRectangle(
        vector.create(MainUI.ToggleBtn.X, MainUI.ToggleBtn.Y, 0),
        vector.create(MainUI.ToggleBtn.W, MainUI.ToggleBtn.H, 0),
        MainUI.Visible and Colors.On or Colors.Off,
        1
    )
    DrawingImmediate.Text(
        vector.create(MainUI.ToggleBtn.X + 20, MainUI.ToggleBtn.Y + 12, 0),
        14, Color3.new(0, 0, 0), 1, "Ore", true, nil
    )
    if Clicked and IsMouseInRect(MousePos, MainUI.ToggleBtn.X, MainUI.ToggleBtn.Y, MainUI.ToggleBtn.W, MainUI.ToggleBtn.H) then
        MainUI.Visible = not MainUI.Visible
    end

    -- MAIN ORE WINDOW
    if MainUI.Visible then
        local ItemCount = math.max(1, #RockList)
        local TotalHeight = MainUI.BaseHeight + (ItemCount * 22) + 20

        DrawingImmediate.FilledRectangle(
            vector.create(MainUI.X, MainUI.Y, 0),
            vector.create(MainUI.Width, TotalHeight, 0),
            Colors.Bg, 0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(MainUI.X, MainUI.Y, 0),
            vector.create(MainUI.Width, 30, 0),
            Colors.Header, 1
        )
        DrawingImmediate.OutlinedText(
            vector.create(MainUI.X + 10, MainUI.Y + 8, 0),
            16, Colors.Text, 1, "Ore Farm", false, nil
        )

        local Y = 35
        local function MainBtn(txt, col, callback)
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 25, 0),
                col, 1
            )
            DrawingImmediate.Text(
                vector.create(MainUI.X + 20, MainUI.Y + Y + 5, 0),
                16, Colors.Text, 1, txt, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, MainUI.X + 10, MainUI.Y + Y, MainUI.Width - 20, 25) then
                callback()
            end
            Y = Y + 30
        end

        -- FARMING
        MainBtn(
            Config.MainEnabled and "FARMING: ON" or "FARMING: OFF",
            Config.MainEnabled and Colors.On or Colors.Off,
            function()
                Config.MainEnabled = not Config.MainEnabled
                CurrentTarget = nil
                TargetLocked = false
            end
        )

        -- ONLY LAVA
        MainBtn(
            Config.OnlyLava and "ONLY LAVA: ON" or "ONLY LAVA: OFF",
            Config.OnlyLava and Colors.On or Colors.Off,
            function()
                Config.OnlyLava = not Config.OnlyLava
                ActiveRocks = {}
                ActiveOres = {}
                RockNamesSet = {}
                RockList = {}
                CurrentTarget = nil
                TargetLocked = false
            end
        )

        -- MINE POSITION
        MainBtn(
            "MINE POS: " .. (Config.MiningPosition == "Under" and "UNDER" or "ABOVE"),
            Colors.Btn,
            function()
                Config.MiningPosition = (Config.MiningPosition == "Under") and "Above" or "Under"
                CurrentTarget = nil
                TargetLocked = false
            end
        )

        -- AUTO SELL
        MainBtn(
            Config.AutoSell and "AUTO SELL: ON" or "AUTO SELL: OFF",
            Config.AutoSell and Colors.On or Colors.Off,
            function()
                Config.AutoSell = not Config.AutoSell
            end
        )

        -- ESP
        MainBtn(
            Config.EspEnabled and "ORE ESP: ON" or "ORE ESP: OFF",
            Config.EspEnabled and Colors.On or Colors.Off,
            function()
                Config.EspEnabled = not Config.EspEnabled
            end
        )

        -- AUTO EQUIP
        MainBtn(
            Config.AutoEquip and "Auto Pickaxe: ON" or "Auto Pickaxe: OFF",
            Config.AutoEquip and Colors.On or Colors.Off,
            function()
                Config.AutoEquip = not Config.AutoEquip
            end
        )

        -- FILTER MENU BUTTON (purple)
        MainBtn(
            FilterUI.Visible and "Close Filter Menu" or "Open Filter Menu",
            Colors.Menu,
            function()
                FilterUI.Visible = not FilterUI.Visible
            end
        )

        -- FALLBACK MENU BUTTON (purple)
        MainBtn(
            FallbackUI.Visible and "Close Fallback Menu" or "Open Fallback Menu",
            Colors.Menu,
            function()
                FallbackUI.Visible = not FallbackUI.Visible
            end
        )

        -- NEW: MOB FARM MENU BUTTON (purple)
        MainBtn(
            MobUI.Visible and "Close Mob Farm" or "Open Mob Farm",
            Colors.Menu,
            function()
                MobUI.Visible = not MobUI.Visible
            end
        )

        Y = Y + 10
        DrawingImmediate.OutlinedText(
            vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
            14, Colors.Text, 1, "Select Rocks to Farm:", false, nil
        )
        Y = Y + 20

        for _, Name in ipairs(RockList) do
            local isOn = EnabledRocks[Name]
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 20, 0),
                isOn and Colors.On or Colors.Off,
                1
            )
            DrawingImmediate.Text(
                vector.create(MainUI.X + 20, MainUI.Y + Y + 2, 0),
                14, Colors.Text, 1, Name, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, MainUI.X + 10, MainUI.Y + Y, MainUI.Width - 20, 20) then
                EnabledRocks[Name] = not EnabledRocks[Name]
                CurrentTarget = nil
                TargetLocked = false
            end
            Y = Y + 22
        end
    end

    -- FILTER WINDOW
    if FilterUI.Visible then
        local CatList = OreDatabase[FilterUI.CurrentCategory] or {}
        local F_TotalHeight = FilterUI.BaseHeight + (#CatList * 22)

        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X, FilterUI.Y, 0),
            vector.create(FilterUI.Width, F_TotalHeight, 0),
            Colors.Bg, 0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X, FilterUI.Y, 0),
            vector.create(FilterUI.Width, 30, 0),
            Colors.Header, 1
        )
        DrawingImmediate.OutlinedText(
            vector.create(FilterUI.X + 10, FilterUI.Y + 8, 0),
            16, Colors.Text, 1, "Ore Filter", false, nil
        )

        local FY = 35

        -- Filter Enabled Toggle
        local F_Txt = Config.FilterEnabled and "FILTER: ACTIVE" or "FILTER: DISABLED"
        local F_Col = Config.FilterEnabled and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            vector.create(FilterUI.Width - 20, 25, 0),
            F_Col, 1
        )
        DrawingImmediate.Text(
            vector.create(FilterUI.X + 60, FilterUI.Y + FY + 5, 0),
            16, Colors.Text, 1, F_Txt, false, nil
        )
        if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 25) then
            Config.FilterEnabled = not Config.FilterEnabled
            CurrentTarget = nil
            TargetLocked = false
        end
        FY = FY + 30

        -- Volcanic only toggle
        local V_Txt = Config.FilterVolcanicOnly and "VOLCANIC ONLY: ON" or "VOLCANIC ONLY: OFF"
        local V_Col = Config.FilterVolcanicOnly and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            vector.create(FilterUI.Width - 20, 25, 0),
            V_Col, 1
        )
        DrawingImmediate.Text(
            vector.create(FilterUI.X + 60, FilterUI.Y + FY + 5, 0),
            16, Colors.Text, 1, V_Txt, false, nil
        )
        if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 25) then
            Config.FilterVolcanicOnly = not Config.FilterVolcanicOnly
            CurrentTarget = nil
            TargetLocked = false
        end
        FY = FY + 35

        -- Categories (Stonewake, Forgotten, Goblin, Frozen)
        local Cats = { "Stonewake", "Forgotten", "Goblin", "Frozen" }
        local btnW = (FilterUI.Width - 40) / #Cats
        for i, Cat in ipairs(Cats) do
            local bx = FilterUI.X + 10 + (i - 1) * (btnW + 5)
            local isSel = FilterUI.CurrentCategory == Cat
            DrawingImmediate.FilledRectangle(
                vector.create(bx, FilterUI.Y + FY, 0),
                vector.create(btnW, 25, 0),
                isSel and Colors.Gold or Colors.Btn,
                1
            )
            DrawingImmediate.Text(
                vector.create(bx + 5, FilterUI.Y + FY + 5, 0),
                14, Colors.Text, 1, Cat, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, bx, FilterUI.Y + FY, btnW, 25) then
                FilterUI.CurrentCategory = Cat
            end
        end
        FY = FY + 35

        DrawingImmediate.OutlinedText(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            14, Colors.Text, 1, "Keep these ores:", false, nil
        )
        FY = FY + 20

        for _, OreName in ipairs(CatList) do
            local IsWhitelisted = Config.FilterWhitelist[OreName]
            DrawingImmediate.FilledRectangle(
                vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
                vector.create(FilterUI.Width - 20, 20, 0),
                IsWhitelisted and Colors.On or Colors.Off,
                1
            )
            DrawingImmediate.Text(
                vector.create(FilterUI.X + 20, FilterUI.Y + FY + 2, 0),
                14, Colors.Text, 1, OreName, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 20) then
                Config.FilterWhitelist[OreName] = not Config.FilterWhitelist[OreName]
                CurrentTarget = nil
                TargetLocked = false
            end
            FY = FY + 22
        end
    end

    -- FALLBACK WINDOW (uses same RockList as main bottom)
    if FallbackUI.Visible then
        local FallbackNames = RockList
        local F_TotalHeight = FallbackUI.BaseHeight + (#FallbackNames * 22)

        DrawingImmediate.FilledRectangle(
            vector.create(FallbackUI.X, FallbackUI.Y, 0),
            vector.create(FallbackUI.Width, F_TotalHeight, 0),
            Colors.Bg, 0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(FallbackUI.X, FallbackUI.Y, 0),
            vector.create(FallbackUI.Width, 30, 0),
            Colors.Header, 1
        )
        DrawingImmediate.OutlinedText(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + 8, 0),
            16, Colors.Text, 1, "Fallback Rocks", false, nil
        )

        local FY = 35

        local FB_Txt = Config.FallbackEnabled and "FALLBACK: ACTIVE" or "FALLBACK: DISABLED"
        local FB_Col = Config.FallbackEnabled and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
            vector.create(FallbackUI.Width - 20, 25, 0),
            FB_Col, 1
        )
        DrawingImmediate.Text(
            vector.create(FallbackUI.X + 20, FallbackUI.Y + FY + 5, 0),
            16, Colors.Text, 1, FB_Txt, false, nil
        )
        if Clicked and IsMouseInRect(MousePos, FallbackUI.X + 10, FallbackUI.Y + FY, FallbackUI.Width - 20, 25) then
            Config.FallbackEnabled = not Config.FallbackEnabled
            CurrentTarget = nil
            TargetLocked = false
        end
        FY = FY + 35

        DrawingImmediate.OutlinedText(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
            14, Colors.Text, 1, "Use these when main rocks are gone:", false, nil
        )
        FY = FY + 20

        for _, Name in ipairs(FallbackNames) do
            local IsFB = FallbackRocks[Name] == true
            DrawingImmediate.FilledRectangle(
                vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
                vector.create(FallbackUI.Width - 20, 20, 0),
                IsFB and Colors.On or Colors.Off,
                1
            )
            DrawingImmediate.Text(
                vector.create(FallbackUI.X + 20, FallbackUI.Y + FY + 2, 0),
                14, Colors.Text, 1, Name, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, FallbackUI.X + 10, FallbackUI.Y + FY, FallbackUI.Width - 20, 20) then
                FallbackRocks[Name] = not FallbackRocks[Name]
                CurrentTarget = nil
                TargetLocked = false
            end
            FY = FY + 22
        end
    end

    -- NEW: MOB FARM WINDOW
    if MobUI.Visible then
        local ItemCount = math.max(1, #MobList)
        local TotalHeight = MobUI.BaseHeight + (ItemCount * 22) + 40

        DrawingImmediate.FilledRectangle(
            vector.create(MobUI.X, MobUI.Y, 0),
            vector.create(MobUI.Width, TotalHeight, 0),
            Colors.Bg, 0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(MobUI.X, MobUI.Y, 0),
            vector.create(MobUI.Width, 30, 0),
            Colors.Header, 1
        )
        DrawingImmediate.OutlinedText(
            vector.create(MobUI.X + 10, MobUI.Y + 8, 0),
            16, Colors.Text, 1, "Mob Farm", false, nil
        )

        local FY = 35

        -- Mob Farm master toggle
        local MobTxt = MobConfig.Enabled and "Mob Farming: ON" or "Mob Farming: OFF"
        local MobCol = MobConfig.Enabled and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(MobUI.X + 10, MobUI.Y + FY, 0),
            vector.create(MobUI.Width - 20, 25, 0),
            MobCol, 1
        )
        DrawingImmediate.Text(
            vector.create(MobUI.X + 20, MobUI.Y + FY + 5, 0),
            16, Colors.Text, 1, MobTxt, false, nil
        )
        if Clicked and IsMouseInRect(MousePos, MobUI.X + 10, MobUI.Y + FY, MobUI.Width - 20, 25) then
            MobConfig.Enabled = not MobConfig.Enabled
            MobCurrentTarget = nil
        end
        FY = FY + 35

        -- Refresh mob list
        DrawingImmediate.FilledRectangle(
            vector.create(MobUI.X + 10, MobUI.Y + FY, 0),
            vector.create(MobUI.Width - 20, 20, 0),
            Colors.Btn, 1
        )
        DrawingImmediate.Text(
            vector.create(MobUI.X + 20, MobUI.Y + FY + 2, 0),
            14, Colors.Text, 1, "Refresh Mob List", false, nil
        )
        if Clicked and IsMouseInRect(MousePos, MobUI.X + 10, MobUI.Y + FY, MobUI.Width - 20, 20) then
            RefreshMobList()
        end
        FY = FY + 25

        DrawingImmediate.OutlinedText(
            vector.create(MobUI.X + 10, MobUI.Y + FY, 0),
            14, Colors.Text, 1, "Click mob to toggle:", false, nil
        )
        FY = FY + 20

        if #MobList == 0 then
            DrawingImmediate.OutlinedText(
                vector.create(MobUI.X + 10, MobUI.Y + FY, 0),
                14, Colors.Text, 1, "(No mobs detected yet)", false, nil
            )
        else
            for _, MobName in ipairs(MobList) do
                local isOn = EnabledMobs[MobName] == true
                DrawingImmediate.FilledRectangle(
                    vector.create(MobUI.X + 10, MobUI.Y + FY, 0),
                    vector.create(MobUI.Width - 20, 20, 0),
                    isOn and Colors.On or Colors.Off,
                    1
                )
                DrawingImmediate.Text(
                    vector.create(MobUI.X + 20, MobUI.Y + FY + 2, 0),
                    14, Colors.Text, 1, MobName, false, nil
                )
                if Clicked and IsMouseInRect(MousePos, MobUI.X + 10, MobUI.Y + FY, MobUI.Width - 20, 20) then
                    EnabledMobs[MobName] = not EnabledMobs[MobName]
                    MobCurrentTarget = nil
                end
                FY = FY + 22
            end
        end
    end

    -- ESP (ore)
    if Config.EspEnabled then
        for _, OreObj in ipairs(ActiveOres) do
            if IsValid(OreObj) then
                local OreName = SafeGetAttribute(OreObj, "Ore")
                if OreName then
                    local Pos = GetPosition(OreObj)
                    if Pos then
                        local ScreenPos, Visible = Camera:WorldToScreenPoint(Pos)
                        if Visible then
                            DrawingImmediate.OutlinedText(
                                vector.create(ScreenPos.X, ScreenPos.Y, 0),
                                Config.EspTextSize,
                                Config.EspTextColor,
                                1,
                                "[" .. tostring(OreName) .. "]",
                                true,
                                nil
                            )
                        end
                    end
                end
            end
        end
    end

    -- Stash capacity display
    local pName = LocalPlayer.Name
    local Path_Capacity = "game.Players." .. pName .. ".PlayerGui.Menu.Frame.Frame.Menus.Stash.Capacity.Text"
    local capObj = GetObject(Path_Capacity)
    if capObj then
        local text = GetTextMemory(capObj)
        local current, max = text:match("(%d+)/(%d+)")
        if current and max then
            local capText = "Stash: " .. current .. "/" .. max
            local capColor = Colors.Text
            local percent = tonumber(current) / tonumber(max)
            if percent >= 0.9 then
                capColor = Colors.Off
            elseif percent >= 0.7 then
                capColor = Colors.Gold
            end
            DrawingImmediate.OutlinedText(
                vector.create(Camera.ViewportSize.X - 150, 10, 0),
                18, capColor, 1, capText, false, nil
            )
        end
    end

    if IsSelling then return end

    local Char = LocalPlayer.Character
    if Char and not MobConfig.Enabled then
        -- only auto-equip pickaxe when NOT doing mob farm
        CheckAutoEquip(Char)
    end

    if not (Char and Char:FindFirstChild("HumanoidRootPart")) then
        return
    end

    local MyRoot = Char.HumanoidRootPart

    ------------------------------------------------------------------------
    -- MOB FARM LOGIC (runs instead of ore farm when enabled)
    ------------------------------------------------------------------------
    if MobConfig.Enabled then
        if not MobCurrentTarget or not IsAlive(MobCurrentTarget) then
            MobCurrentTarget = FindEnabledMobTarget(MyRoot.Position)
            if not MobCurrentTarget then
                return
            end
        end

        local MobRoot = MobCurrentTarget:FindFirstChild("HumanoidRootPart")
        if not MobRoot then
            MobCurrentTarget = nil
            return
        end

        local MobPos = MobRoot.Position
        local GoalPos = vector.create(MobPos.X, MobPos.Y - MobConfig.UnderOffset, MobPos.Z)
        local Diff = MyRoot.Position - GoalPos
        local Dist = vector.magnitude(Diff)

        if Dist > MobConfig.AttackDistance then
            SkyHopMove(MyRoot, GoalPos, DeltaTime)
        else
            EquipTool(Config.WeaponName, 50)
            local LookAt = Vector3.new(MobPos.X, MobPos.Y, MobPos.Z)
            local Pos = Vector3.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
            MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
            MyRoot.Velocity = vector.zero
            if mouse1click then
                mouse1click()
            end
        end

        return
    end

    ------------------------------------------------------------------------
    -- ORE FARM LOGIC
    ------------------------------------------------------------------------
    if not Config.MainEnabled then
        return
    end

    if CurrentTarget then
        if not IsValid(CurrentTarget) then
            CurrentTarget = nil
            TargetLocked = false
            return
        end

        local HP = GetRockHealth(CurrentTarget)
        if HP <= 0 then
            CurrentTarget = nil
            TargetLocked = false
            return
        end

        local MaxHP = GetRockMaxHealth(CurrentTarget)
        local OrePos = GetPosition(CurrentTarget)
        if not OrePos then
            CurrentTarget = nil
            TargetLocked = false
            return
        end

        if Config.FilterEnabled then
            local HasWanted, AllOres = HasAnyWantedOre(CurrentTarget)

            if AllOres and #AllOres > 0 then
                local applyFilter = true
                if Config.FilterVolcanicOnly and not IsVolcanic(CurrentTarget) then
                    applyFilter = false
                end

                if applyFilter and not HasWanted then
                    CurrentTarget = nil
                    TargetLocked = false
                    return
                end
            end
        end

        local Y_Offset = (Config.MiningPosition == "Under") and -Config.UnderOffset or Config.AboveOffset
        local GoalPos = vector.create(OrePos.X, OrePos.Y + Y_Offset, OrePos.Z)

        local Diff2 = MyRoot.Position - GoalPos
        local Dist2 = vector.magnitude(Diff2)

        if Dist2 > Config.MineDistance then
            SkyHopMove(MyRoot, GoalPos, DeltaTime)
        else
            local CurrentHP = GetRockHealth(CurrentTarget)
            local MaxHP_Real = GetRockMaxHealth(CurrentTarget)

            if CurrentHP <= 0 then
                CurrentTarget = nil
                TargetLocked = false
                return
            end

            if not TargetLocked then
                if MaxHP_Real > 0 and CurrentHP < MaxHP_Real then
                    CurrentTarget = nil
                    return
                else
                    TargetLocked = true
                end
            end

            if Config.AutoEquip then
                EquipTool(Config.ToolName, 49)
            end

            local LookAt = Vector3.new(OrePos.X, OrePos.Y, OrePos.Z)
            local Pos = Vector3.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
            MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
            MyRoot.Velocity = vector.zero

            if os.clock() - LastMineClick > Config.ClickDelay then
                if mouse1click then
                    mouse1click()
                end
                LastMineClick = os.clock()
            end
        end
    else
        CurrentTarget = FindNearestRock()
        TargetLocked = false
    end
end

local Connected = false
if RunService then
    pcall(function()
        RunService.Heartbeat:Connect(UpdateLoop)
        Connected = true
    end)
    if not Connected then
        pcall(function()
            RunService.RenderStepped:Connect(UpdateLoop)
            Connected = true
        end)
    end
    if not Connected then
        pcall(function()
            RunService.Render:Connect(UpdateLoop)
            Connected = true
        end)
    end
end

if not Connected then
    warn("Using Manual Loop")
    task.spawn(function()
        while true do
            UpdateLoop()
            task.wait(0.03)
        end
    end)
end
