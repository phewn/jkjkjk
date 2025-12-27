--!optimize 2
loadstring(game:HttpGet("https://raw.githubusercontent.com/Sploiter13/severefuncs/refs/heads/main/merge.lua"))();

-- SEVERE EXTERNAL VERSION - ORE FARM + MOB COMBAT + FALLBACK

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
local ActiveOres  = {}
local EnabledRocks = {}
local RockNamesSet = {}
local RockList = {}

-- Fallback system
local FallbackUI = {
    X = 400, Y = 420, Width = 260, BaseHeight = 200, Visible = false,
    Dragging = false, DragOffset = {x = 0, y = 0},
}
local FallbackRocks = {}   -- rockName -> bool (if true, allowed as fallback)

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
        "Tungsten", "Sulfur", "Pumice", "Graphite", "Aetherit", "Scheelite", "Larimar",
        "Neurotite", "Frost Fossil", "Tide Carve", "Velchire", "Sanctis",
        "Snowite", "Iceite",
        -- new Frozen ores
        "Mistvein", "Lgarite", "Voidfractal", "Moltenfrost", "Crimsonite",
        "Malachite", "Aqujade", "Cryptex", "Galestor", "Voidstar", "Etherealite",
        "Suryafal", "Heavenite", "Gargantuan"
    },
}

local Config = {
    DebugMode = CustomSettings.DebugMode or false,

    FolderName = "Rocks",
    LavaFolder = CustomSettings.LavaFolder or "Island2VolcanicDepths",
    ToolName   = CustomSettings.PickaxeName or "Pickaxe",
    WeaponName = CustomSettings.WeaponName or "Weapon",

    -- MINING
    MineDistance   = CustomSettings.MineDistance or 10,
    UnderOffset    = CustomSettings.UnderOffset or 7,
    AboveOffset    = CustomSettings.AboveOffset or 7,
    MiningPosition = CustomSettings.MiningPosition or "Under",
    ClickDelay     = CustomSettings.ClickDelay or 0.25,

    -- MOB COMBAT
    MobDetectionRange = CustomSettings.MobScanRange or 30,
    CombatMode        = CustomSettings.CombatMode or "Kill", -- "Kill" or "Spam"
    CombatUnderOffset = CustomSettings.CombatUnderOffset or 8,
    CombatEnabled     = CustomSettings.CombatEnabled or false,

    -- FILTER
    FilterEnabled      = CustomSettings.FilterEnabled or false,
    FilterVolcanicOnly = CustomSettings.FilterVolcanicOnly or false,
    FilterWhitelist    = CustomSettings.FilterWhitelist or {},

    -- SYSTEM
    AutoScanRate   = CustomSettings.AutoScanRate or 1,
    SkyHeight      = CustomSettings.SkyHeight or 500,
    MainEnabled    = false,
    EspEnabled     = CustomSettings.EspEnabled or false,
    OnlyLava       = CustomSettings.OnlyLava or false,
    PriorityVolcanic = CustomSettings.PriorityVolcanic or false,
    TravelSpeed    = CustomSettings.TravelSpeed or 300,
    InstantTP_Range = CustomSettings.InstantTP_Range or 60,
    AutoEquip      = CustomSettings.AutoEquip or false,

    -- AUTO SELL
    AutoSell = CustomSettings.AutoSell or false,
    MerchantPos = Vector3.new(
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.X or -132.07,
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.Y or 21.61,
        CustomSettings.MerchantPos and CustomSettings.MerchantPos.Z or -20.92
    ),
    SellTimeout = CustomSettings.SellTimeout or 60,

    -- FALLBACK
    FallbackEnabled = CustomSettings.FallbackEnabled or false,

    EspTextColor = Color3.fromRGB(
        CustomSettings.EspColor and CustomSettings.EspColor.R or 100,
        CustomSettings.EspColor and CustomSettings.EspColor.G or 255,
        CustomSettings.EspColor and CustomSettings.EspColor.B or 100
    ),
    EspTextSize = CustomSettings.EspTextSize or 16,
}

-- Apply pre-enabled rocks if provided
if CustomSettings.EnabledRocks then
    for rockName, enabled in pairs(CustomSettings.EnabledRocks) do
        EnabledRocks[rockName] = enabled
    end
end

local MainUI = {
    X = 100, Y = 100, Width = 280, BaseHeight = 420, Visible = true,
    Dragging = false, DragOffset = {x = 0, y = 0},
    ToggleBtn = { X = 20, Y = 20, W = 80, H = 25 }
}

local FilterUI = {
    X = 420, Y = 100, Width = 260, BaseHeight = 260, Visible = false,
    Dragging = false, DragOffset = {x = 0, y = 0},
    CurrentCategory = "Stonewake",
}

-- Colors (updated per your request)
local Colors = {
    Bg     = Color3.fromRGB(10, 18, 40),   -- dark blue background
    Header = Color3.fromRGB(18, 30, 60),
    Text   = Color3.fromRGB(255, 255, 255),

    On    = Color3.fromRGB(0, 120, 60),    -- emerald-ish green for ON
    Off   = Color3.fromRGB(230, 150, 30),  -- orange for OFF
    Btn   = Color3.fromRGB(40, 60, 100),

    Lava   = Color3.fromRGB(255, 120, 60),
    Gold   = Color3.fromRGB(255, 210, 80),
    Debug  = Color3.fromRGB(255, 0, 255),
    Combat = Color3.fromRGB(255, 120, 160),

    MenuPurple = Color3.fromRGB(150, 80, 200), -- Filter / Fallback buttons
}

local LocalPlayer = Players.LocalPlayer
local CurrentTarget = nil
local CurrentMobTarget = nil
local SavedMiningTarget = nil
local MouseState = { WasPressed = false }
local EquipDebounce = 0
local LastMineClick = 0
local TargetLocked = false
local LastWeaponSwitch = 0
local InCombat = false
local IsSelling = false

-- ============================================================================
-- 2. SAFETY & HELPERS
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
        for _, child in ipairs(kids) do
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

-- UI path helpers
local function GetObject(pathStr)
    local segments = pathStr:split(".")
    local current = game
    for i, name in ipairs(segments) do
        if i == 1 and name == "game" then
        elseif current == game and name == "Players" then
            current = Players
        elseif current == Players and name ~= "LocalPlayer" then
            current = current.LocalPlayer
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
    if absPos and absSize then
        local centerX = absPos.X + (absSize.X / 2)
        local centerY = absPos.Y + (absSize.Y / 2)
        if mouse1click and MouseService then
            MouseService:SetMouseLocation(vector.create(centerX, centerY, 0))
            task.wait(0.05)
            mouse1click()
            return true
        end
    end
    return false
end

-- ============================================================================
-- 3. MOB DETECTION & COMBAT
-- ============================================================================

local function IsAlive(Model)
    if not Model then return false end
    local Humanoid = Model:FindFirstChild("Humanoid")
    local RootPart = Model:FindFirstChild("HumanoidRootPart")
    if Humanoid and RootPart and Humanoid.Health > 0 then return true end
    return false
end

local function FindNearestMob(MyPosition)
    local LivingFolder = Workspace:FindFirstChild("Living")
    if not LivingFolder then return nil end

    local Closest, MinDist = nil, 999999
    for _, Mob in ipairs(LivingFolder:GetChildren()) do
        if Players:FindFirstChild(Mob.Name) then continue end
        if Mob.ClassName == "Model" and IsAlive(Mob) then
            local MobRoot = Mob:FindFirstChild("HumanoidRootPart")
            if MobRoot then
                local Dist = vector.magnitude(MobRoot.Position - MyPosition)
                if Dist < MinDist and Dist <= Config.MobDetectionRange then
                    MinDist = Dist
                    Closest = Mob
                end
            end
        end
    end
    return Closest
end

local function EquipTool(ToolName, SlotKey)
    local Char = LocalPlayer.Character
    if not Char then return false end

    if Char:FindFirstChild(ToolName) then return true end

    local Backpack = LocalPlayer.Backpack
    if Backpack and Backpack:FindFirstChild(ToolName) then
        if keypress and SlotKey then
            keypress(SlotKey)
            keyrelease(SlotKey)
            return true
        else
            -- fallback using KeyCodes 1/2 if needed
            if ToolName == Config.ToolName then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            elseif ToolName == Config.WeaponName then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
            end
            return true
        end
    end
    return false
end

local function SpamWeaponSwitch()
    if os.clock() - LastWeaponSwitch < 0.1 then return end
    if keypress then
        local slot = (os.clock() % 0.4 < 0.2) and 49 or 50  -- '1' or '2'
        keypress(slot)
        keyrelease(slot)
    end
    LastWeaponSwitch = os.clock()
end

-- ============================================================================
-- 4. ORE DETECTION & FILTER
-- ============================================================================

local function GetAllRevealedOres(Rock)
    if not IsValid(Rock) then return {} end
    local AllOres = {}

    local Attr = SafeGetAttribute(Rock, "Ore")
    if Attr and Attr ~= "" then
        table.insert(AllOres, tostring(Attr))
    end

    local Success, Children = pcall(function() return Rock:GetChildren() end)
    if Success and Children then
        for _, Child in ipairs(Children) do
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
        if not IsValid(ActiveRocks[i]) then table.remove(ActiveRocks, i) end
    end
    for i = #ActiveOres, 1, -1 do
        if not IsValid(ActiveOres[i]) then table.remove(ActiveOres, i) end
    end
    if CurrentTarget then
        if not IsValid(CurrentTarget) or GetRockHealth(CurrentTarget) <= 0 then
            CurrentTarget = nil
            TargetLocked = false
        end
    end
    if SavedMiningTarget then
        if not IsValid(SavedMiningTarget) or GetRockHealth(SavedMiningTarget) <= 0 then
            SavedMiningTarget = nil
        end
    end
    if CurrentMobTarget then
        if not IsAlive(CurrentMobTarget) then
            CurrentMobTarget = nil
            InCombat = false
            -- re-equip pickaxe when combat ends
            if Config.AutoEquip then
                EquipTool(Config.ToolName, 49)
            end
        end
    end
end

-- ============================================================================
-- 5. INTERACTION & MOVEMENT
-- ============================================================================

local function IsMouseInRect(MousePos, x, y, w, h)
    return MousePos.x >= x and MousePos.x <= x + w and
           MousePos.y >= y and MousePos.y <= y + h
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

local function FindVolcanicRock()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local MyPos = Root.Position
    local Closest, MinDist = nil, 999999

    for _, Rock in ipairs(ActiveRocks) do
        if IsVolcanic(Rock) then
            local HP = GetRockHealth(Rock)
            local MaxHP = GetRockMaxHealth(Rock)
            local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)
            if IsFresh then
                local Pos = GetPosition(Rock)
                if Pos then
                    local Dist = vector.magnitude(Pos - MyPos)
                    if Dist < MinDist then
                        MinDist = Dist
                        Closest = Rock
                    end
                end
            end
        end
    end

    return Closest
end

local function FindNearestRock()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local MyPos = Root.Position
    local Closest, MinDist = nil, 999999

    if Config.PriorityVolcanic then
        local Volcanic = FindVolcanicRock()
        if Volcanic then return Volcanic end
    end

    for _, Rock in ipairs(ActiveRocks) do
        if not IsValid(Rock) then continue end

        local RName = SafeGetName(Rock)
        if RName and EnabledRocks[RName] == true then
            local HP = GetRockHealth(Rock)
            local MaxHP = GetRockMaxHealth(Rock)
            local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)

            if IsFresh then
                -- filter by ores if enabled
                if Config.FilterEnabled then
                    local HasWanted, _ = HasAnyWantedOre(Rock)
                    if not HasWanted then
                        -- if VolcanicOnly and not volcanic, or just not wanted -> skip
                        goto CONTINUE_ROCK
                    end
                    if Config.FilterVolcanicOnly and not IsVolcanic(Rock) then
                        goto CONTINUE_ROCK
                    end
                end

                local Pos = GetPosition(Rock)
                if Pos then
                    local Dist = vector.magnitude(Pos - MyPos)
                    if Dist < MinDist then
                        MinDist = Dist
                        Closest = Rock
                    end
                end
            end
        end
        ::CONTINUE_ROCK::
    end

    return Closest
end

local function FindFallbackRock()
    if not Config.FallbackEnabled then return nil end
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local MyPos = Root.Position
    local Closest, MinDist = nil, 999999

    for _, Rock in ipairs(ActiveRocks) do
        if not IsValid(Rock) then continue end
        local RName = SafeGetName(Rock)
        if RName and FallbackRocks[RName] then
            local HP = GetRockHealth(Rock)
            local MaxHP = GetRockMaxHealth(Rock)
            local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)
            if IsFresh then
                local Pos = GetPosition(Rock)
                if Pos then
                    local Dist = vector.magnitude(Pos - MyPos)
                    if Dist < MinDist then
                        MinDist = Dist
                        Closest = Rock
                    end
                end
            end
        end
    end

    return Closest
end

local function CheckAutoEquip(Character)
    if not Config.AutoEquip then return end
    if os.clock() - EquipDebounce < 1 then return end
    local Tool = Character:FindFirstChild(Config.ToolName)
    if not Tool then
        local Backpack = LocalPlayer.Backpack
        if Backpack and Backpack:FindFirstChild(Config.ToolName) then
            if keypress then
                keypress(49)
                keyrelease(49)
            else
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            end
            EquipDebounce = os.clock()
        end
    end
end

local function SkyHopMove(RootPart, GoalPos, DeltaTime)
    local CurrentPos = RootPart.Position
    local Diff = GoalPos - CurrentPos
    local Dist = vector.magnitude(Diff)

    if Dist <= Config.InstantTP_Range then
        RootPart.CFrame = CFrame.new(GoalPos.x, GoalPos.y, GoalPos.z)
        return true
    end

    if CurrentPos.y < Config.SkyHeight - 10 then
        RootPart.CFrame = CFrame.new(CurrentPos.x, Config.SkyHeight, CurrentPos.z)
        RootPart.Velocity = vector.zero
        return false
    end

    local FlatDiff = vector.create(GoalPos.x - CurrentPos.x, 0, GoalPos.z - CurrentPos.z)
    local FlatDist = vector.magnitude(FlatDiff)

    if FlatDist < 15 then
        RootPart.CFrame = CFrame.new(GoalPos.x, GoalPos.y, GoalPos.z)
        RootPart.Velocity = vector.zero
        return false
    end

    local Step = Config.TravelSpeed * DeltaTime
    local Direction = vector.normalize(FlatDiff)
    local MoveVec = Direction * Step
    local NewPos = CurrentPos + MoveVec

    RootPart.CFrame = CFrame.new(NewPos.x, Config.SkyHeight, NewPos.z)
    RootPart.Velocity = vector.zero
    return false
end

-- ============================================================================
-- 6. AUTO SELL SYSTEM (UPDATED)
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
    local Path_Capacity = "game.Players."..pName..".PlayerGui.Menu.Frame.Frame.Menus.Stash.Capacity.Text"

    local capObj = GetObject(Path_Capacity)
    if not capObj then return end

    local text = GetTextMemory(capObj)
    local current, max = text:match("(%d+)/(%d+)")
    if current and max and tonumber(current) >= tonumber(max) then
        IsSelling = true
        CurrentTarget = nil
        CurrentMobTarget = nil
        SavedMiningTarget = nil
        TargetLocked = false
        InCombat = false

        local StartTime = os.clock()
        local function CheckTimeout()
            if os.clock() - StartTime > Config.SellTimeout then
                warn(">> AUTO SELL STUCK! Timeout reached.")
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

        local Path_Billboard     = "game.Players."..pName..".PlayerGui.DialogueUI.ResponseBillboard"
        local Path_DialogueBtn   = "game.Players."..pName..".PlayerGui.DialogueUI.ResponseBillboard.Response.Button"
        local Path_SellUI        = "game.Players."..pName..".PlayerGui.Sell.MiscSell"
        local Path_SelectAll     = "game.Players."..pName..".PlayerGui.Sell.MiscSell.Frame.SelectAll"
        local Path_SelectTitle   = "game.Players."..pName..".PlayerGui.Sell.MiscSell.Frame.SelectAll.Frame.Title"
        local Path_Accept        = "game.Players."..pName..".PlayerGui.Sell.MiscSell.Frame.Accept"

        local bb = GetObject(Path_Billboard)
        local startInteract = os.clock()
        while (not bb or not bb.Visible) and (os.clock() - startInteract < 10) do
            if CheckTimeout() then return end
            PressE()
            task.wait(0.5)
            bb = GetObject(Path_Billboard)
        end
        task.wait(0.5)

        local timeout = 0
        while timeout < 20 do
            if CheckTimeout() then return end
            local sellUI = GetObject(Path_SellUI)
            if sellUI and sellUI.Visible then break end
            local diagBtn = GetObject(Path_DialogueBtn)
            if diagBtn then ClickObject(diagBtn) end
            task.wait(0.5)
            timeout += 1
        end

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
            timeout += 1
        end

        timeout = 0
        while timeout < 20 do
            if CheckTimeout() then return end
            local bb2 = GetObject(Path_Billboard)
            if bb2 and bb2.Visible then break end
            local accBtn = GetObject(Path_Accept)
            if accBtn then ClickObject(accBtn) end
            task.wait(0.5)
            timeout += 1
        end

        timeout = 0
        while timeout < 20 do
            if CheckTimeout() then return end
            local bb3 = GetObject(Path_Billboard)
            if not bb3 or not bb3.Visible then break end
            local diagBtn = GetObject(Path_DialogueBtn)
            if diagBtn then ClickObject(diagBtn) end
            task.wait(0.5)
            timeout += 1
        end

        IsSelling = false
    end
end

-- ============================================================================
-- 7. SCANNER THREAD
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
                    if EnabledRocks[N] == nil then EnabledRocks[N] = false end
                    if FallbackRocks[N] == nil then FallbackRocks[N] = false end
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
    local MousePos = MouseService:GetMouseLocation()
    local Clicked = CheckClick()
    local IsLeftDown = false
    if isleftpressed then IsLeftDown = isleftpressed() end

    -- DRAGGING
    if IsLeftDown then
        if not MainUI.Dragging and not FilterUI.Dragging and not FallbackUI.Dragging then
            if MainUI.Visible and IsMouseInRect(MousePos, MainUI.X, MainUI.Y, MainUI.Width, 30) then
                MainUI.Dragging = true
                MainUI.DragOffset.x = MousePos.x - MainUI.X
                MainUI.DragOffset.y = MousePos.y - MainUI.Y
            elseif FilterUI.Visible and IsMouseInRect(MousePos, FilterUI.X, FilterUI.Y, FilterUI.Width, 30) then
                FilterUI.Dragging = true
                FilterUI.DragOffset.x = MousePos.x - FilterUI.X
                FilterUI.DragOffset.y = MousePos.y - FilterUI.Y
            elseif FallbackUI.Visible and IsMouseInRect(MousePos, FallbackUI.X, FallbackUI.Y, FallbackUI.Width, 30) then
                FallbackUI.Dragging = true
                FallbackUI.DragOffset.x = MousePos.x - FallbackUI.X
                FallbackUI.DragOffset.y = MousePos.y - FallbackUI.Y
            end
        end
        if MainUI.Dragging then
            MainUI.X = MousePos.x - MainUI.DragOffset.x
            MainUI.Y = MousePos.y - MainUI.DragOffset.y
        end
        if FilterUI.Dragging then
            FilterUI.X = MousePos.x - FilterUI.DragOffset.x
            FilterUI.Y = MousePos.y - FilterUI.DragOffset.y
        end
        if FallbackUI.Dragging then
            FallbackUI.X = MousePos.x - FallbackUI.DragOffset.x
            FallbackUI.Y = MousePos.y - FallbackUI.DragOffset.y
        end
    else
        MainUI.Dragging = false
        FilterUI.Dragging = false
        FallbackUI.Dragging = false
    end

    -- MAIN TOGGLE BUTTON (top-left)
    local btnCol = MainUI.Visible and Colors.On or Colors.Off
    DrawingImmediate.FilledRectangle(
        vector.create(MainUI.ToggleBtn.X, MainUI.ToggleBtn.Y, 0),
        vector.create(MainUI.ToggleBtn.W, MainUI.ToggleBtn.H, 0),
        btnCol,
        1
    )
    DrawingImmediate.Text(
        vector.create(MainUI.ToggleBtn.X + MainUI.ToggleBtn.W/2, MainUI.ToggleBtn.Y + 6, 0),
        14,
        Colors.Text,
        1,
        "Ore",
        true,
        nil
    )
    if Clicked and IsMouseInRect(MousePos, MainUI.ToggleBtn.X, MainUI.ToggleBtn.Y, MainUI.ToggleBtn.W, MainUI.ToggleBtn.H) then
        MainUI.Visible = not MainUI.Visible
    end

    -- MAIN WINDOW
    if MainUI.Visible then
        local ItemCount = math.max(1, #RockList)
        local TotalHeight = MainUI.BaseHeight + (ItemCount * 22) + 20

        DrawingImmediate.FilledRectangle(
            vector.create(MainUI.X, MainUI.Y, 0),
            vector.create(MainUI.Width, TotalHeight, 0),
            Colors.Bg,
            0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(MainUI.X, MainUI.Y, 0),
            vector.create(MainUI.Width, 30, 0),
            Colors.Header,
            1
        )
        DrawingImmediate.OutlinedText(
            vector.create(MainUI.X + 10, MainUI.Y + 8, 0),
            16,
            Colors.Text,
            1,
            "Ore Farm",
            false,
            nil
        )

        local Y = 35
        local function MainBtn(Txt, Col, Act)
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 25, 0),
                Col,
                1
            )
            DrawingImmediate.Text(
                vector.create(MainUI.X + MainUI.Width/2, MainUI.Y + Y + 5, 0),
                16,
                Colors.Text,
                1,
                Txt,
                true,
                nil
            )
            if Clicked and IsMouseInRect(MousePos, MainUI.X + 10, MainUI.Y + Y, MainUI.Width - 20, 25) then
                Act()
            end
            Y = Y + 30
        end

        -- Main farming toggle
        MainBtn(
            Config.MainEnabled and "FARMING: ON" or "FARMING: OFF",
            Config.MainEnabled and Colors.On or Colors.Off,
            function()
                Config.MainEnabled = not Config.MainEnabled
                CurrentTarget = nil
                CurrentMobTarget = nil
                SavedMiningTarget = nil
                TargetLocked = false
                InCombat = false
            end
        )

        -- Only Lava
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
                CurrentMobTarget = nil
                SavedMiningTarget = nil
                TargetLocked = false
                InCombat = false
            end
        )

        -- Combat enable toggle
        MainBtn(
            Config.CombatEnabled and "COMBAT: ON" or "COMBAT: OFF",
            Config.CombatEnabled and Colors.On or Colors.Off,
            function()
                Config.CombatEnabled = not Config.CombatEnabled
                InCombat = false
                CurrentMobTarget = nil
            end
        )

        -- Combat mode toggle
        MainBtn(
            "MODE: " .. (Config.CombatMode == "Kill" and "KILL" or "SPAM"),
            Colors.Combat,
            function()
                Config.CombatMode = (Config.CombatMode == "Kill") and "Spam" or "Kill"
            end
        )

        -- Mine position
        MainBtn(
            "MINE POS: " .. (Config.MiningPosition == "Under" and "UNDER" or "ABOVE"),
            Colors.Btn,
            function()
                Config.MiningPosition = (Config.MiningPosition == "Under") and "Above" or "Under"
                CurrentTarget = nil
                TargetLocked = false
            end
        )

        -- Auto Sell
        MainBtn(
            Config.AutoSell and "AUTO SELL: ON" or "AUTO SELL: OFF",
            Config.AutoSell and Colors.On or Colors.Off,
            function()
                Config.AutoSell = not Config.AutoSell
            end
        )

        -- Ore ESP
        MainBtn(
            Config.EspEnabled and "ORE ESP: ON" or "ORE ESP: OFF",
            Config.EspEnabled and Colors.On or Colors.Off,
            function()
                Config.EspEnabled = not Config.EspEnabled
            end
        )

        -- Auto Equip
        MainBtn(
            Config.AutoEquip and "Auto Pickaxe: ON" or "Auto Pickaxe: OFF",
            Config.AutoEquip and Colors.On or Colors.Off,
            function()
                Config.AutoEquip = not Config.AutoEquip
            end
        )

        -- Filter menu (purple)
        MainBtn(
            FilterUI.Visible and "Close Filter Menu" or "Open Filter Menu",
            Colors.MenuPurple,
            function()
                FilterUI.Visible = not FilterUI.Visible
            end
        )

        -- Fallback toggle
        MainBtn(
            Config.FallbackEnabled and "FALLBACK: ON" or "FALLBACK: OFF",
            Config.FallbackEnabled and Colors.On or Colors.Off,
            function()
                Config.FallbackEnabled = not Config.FallbackEnabled
            end
        )

        -- Fallback menu (purple)
        MainBtn(
            FallbackUI.Visible and "Close Fallback Menu" or "Open Fallback Menu",
            Colors.MenuPurple,
            function()
                FallbackUI.Visible = not FallbackUI.Visible
            end
        )

        Y = Y + 10
        DrawingImmediate.OutlinedText(
            vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
            14,
            Colors.Text,
            1,
            "Select Rocks to Farm:",
            false,
            nil
        )
        Y = Y + 20

        for _, Name in ipairs(RockList) do
            local IsOn = EnabledRocks[Name]
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 20, 0),
                IsOn and Colors.On or Colors.Off,
                1
            )
            DrawingImmediate.Text(
                vector.create(MainUI.X + 20, MainUI.Y + Y + 2, 0),
                14,
                Colors.Text,
                1,
                Name,
                false,
                nil
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
            Colors.Bg,
            0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X, FilterUI.Y, 0),
            vector.create(FilterUI.Width, 30, 0),
            Colors.Header,
            1
        )
        DrawingImmediate.OutlinedText(
            vector.create(FilterUI.X + 10, FilterUI.Y + 8, 0),
            16,
            Colors.Text,
            1,
            "Ore Filter",
            false,
            nil
        )

        local FY = 35

        -- Filter enabled toggle
        local F_Txt = Config.FilterEnabled and "FILTER: ACTIVE" or "FILTER: DISABLED"
        local F_Col = Config.FilterEnabled and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            vector.create(FilterUI.Width - 20, 25, 0),
            F_Col,
            1
        )
        DrawingImmediate.Text(
            vector.create(FilterUI.X + FilterUI.Width/2, FilterUI.Y + FY + 5, 0),
            16,
            Colors.Text,
            1,
            F_Txt,
            true,
            nil
        )
        if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 25) then
            Config.FilterEnabled = not Config.FilterEnabled
        end
        FY = FY + 30

        -- Volcanic-only toggle
        local V_Txt = Config.FilterVolcanicOnly and "VOLCANIC ONLY: ON" or "VOLCANIC ONLY: OFF"
        local V_Col = Config.FilterVolcanicOnly and Colors.On or Colors.Off
        DrawingImmediate.FilledRectangle(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            vector.create(FilterUI.Width - 20, 25, 0),
            V_Col,
            1
        )
        DrawingImmediate.Text(
            vector.create(FilterUI.X + FilterUI.Width/2, FilterUI.Y + FY + 5, 0),
            16,
            Colors.Text,
            1,
            V_Txt,
            true,
            nil
        )
        if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 25) then
            Config.FilterVolcanicOnly = not Config.FilterVolcanicOnly
        end
        FY = FY + 35

        -- Categories
        local btnW = (FilterUI.Width - 30) / 4
        local Cats = {"Stonewake", "Forgotten", "Goblin", "Frozen"}
        for i, Cat in ipairs(Cats) do
            local bx = FilterUI.X + 10 + ((i - 1) * (btnW + 2))
            local isSel = FilterUI.CurrentCategory == Cat
            DrawingImmediate.FilledRectangle(
                vector.create(bx, FilterUI.Y + FY, 0),
                vector.create(btnW, 25, 0),
                isSel and Colors.MenuPurple or Colors.Btn,
                1
            )
            DrawingImmediate.Text(
                vector.create(bx + btnW/2, FilterUI.Y + FY + 5, 0),
                13,
                Colors.Text,
                1,
                Cat,
                true,
                nil
            )
            if Clicked and IsMouseInRect(MousePos, bx, FilterUI.Y + FY, btnW, 25) then
                FilterUI.CurrentCategory = Cat
            end
        end
        FY = FY + 35

        DrawingImmediate.OutlinedText(
            vector.create(FilterUI.X + 10, FilterUI.Y + FY, 0),
            14,
            Colors.Text,
            1,
            "Keep these ores:",
            false,
            nil
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
                14,
                Colors.Text,
                1,
                OreName,
                false,
                nil
            )
            if Clicked and IsMouseInRect(MousePos, FilterUI.X + 10, FilterUI.Y + FY, FilterUI.Width - 20, 20) then
                Config.FilterWhitelist[OreName] = not Config.FilterWhitelist[OreName]
                CurrentTarget = nil
                TargetLocked = false
            end
            FY = FY + 22
        end
    end

    -- FALLBACK WINDOW
    if FallbackUI.Visible then
        local FListCount = math.max(1, #RockList)
        local F_TotalHeight = FallbackUI.BaseHeight + (FListCount * 22)

        DrawingImmediate.FilledRectangle(
            vector.create(FallbackUI.X, FallbackUI.Y, 0),
            vector.create(FallbackUI.Width, F_TotalHeight, 0),
            Colors.Bg,
            0.95
        )
        DrawingImmediate.FilledRectangle(
            vector.create(FallbackUI.X, FallbackUI.Y, 0),
            vector.create(FallbackUI.Width, 30, 0),
            Colors.Header,
            1
        )
        DrawingImmediate.OutlinedText(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + 8, 0),
            16,
            Colors.Text,
            1,
            "Fallback Rocks",
            false,
            nil
        )

        local FY = 35
        DrawingImmediate.OutlinedText(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
            14,
            Colors.Text,
            1,
            "Use these when main ores",
            false,
            nil
        )
        FY = FY + 16
        DrawingImmediate.OutlinedText(
            vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
            14,
            Colors.Text,
            1,
            "are missing:",
            false,
            nil
        )
        FY = FY + 22

        for _, Name in ipairs(RockList) do
            local IsOn = FallbackRocks[Name]
            DrawingImmediate.FilledRectangle(
                vector.create(FallbackUI.X + 10, FallbackUI.Y + FY, 0),
                vector.create(FallbackUI.Width - 20, 20, 0),
                IsOn and Colors.On or Colors.Off,
                1
            )
            DrawingImmediate.Text(
                vector.create(FallbackUI.X + 20, FallbackUI.Y + FY + 2, 0),
                14,
                Colors.Text,
                1,
                Name,
                false,
                nil
            )
            if Clicked and IsMouseInRect(MousePos, FallbackUI.X + 10, FallbackUI.Y + FY, FallbackUI.Width - 20, 20) then
                FallbackRocks[Name] = not FallbackRocks[Name]
            end
            FY = FY + 22
        end
    end

    -- ESP DRAW
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

    -- Stash capacity HUD
    local pName = LocalPlayer.Name
    local Path_Capacity = "game.Players."..pName..".PlayerGui.Menu.Frame.Frame.Menus.Stash.Capacity.Text"
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
                vector.create(Camera.ViewportSize.X - 170, 10, 0),
                18,
                capColor,
                1,
                capText,
                false,
                nil
            )
        end
    end

    if InCombat then
        DrawingImmediate.OutlinedText(
            vector.create(Camera.ViewportSize.X - 170, 35, 0),
            16,
            Colors.Combat,
            1,
            "COMBAT MODE",
            false,
            nil
        )
    end

    if IsSelling then return end

    local Char = LocalPlayer.Character
    if Char then CheckAutoEquip(Char) end

    if Char and Char:FindFirstChild("HumanoidRootPart") then
        local MyRoot = Char.HumanoidRootPart

        if Config.MainEnabled then
            -- MOB COMBAT FIRST
            if Config.CombatEnabled then
                local NearbyMob = FindNearestMob(MyRoot.Position)
                if NearbyMob then
                    InCombat = true
                    if Config.CombatMode == "Kill" then
                        if CurrentTarget and not SavedMiningTarget then
                            SavedMiningTarget = CurrentTarget
                        end
                        CurrentMobTarget = NearbyMob
                        CurrentTarget = nil
                        TargetLocked = false

                        local MobRoot = NearbyMob:FindFirstChild("HumanoidRootPart")
                        if MobRoot then
                            local MobPos = MobRoot.Position
                            local GoalPos = vector.create(MobPos.x, MobPos.y - Config.CombatUnderOffset, MobPos.z)
                            local Diff = MyRoot.Position - GoalPos
                            local Dist = vector.magnitude(Diff)

                            if Dist > Config.MineDistance then
                                SkyHopMove(MyRoot, GoalPos, DeltaTime)
                            else
                                EquipTool(Config.WeaponName, 50)
                                local LookAt = Vector3.new(MobPos.x, MobPos.y, MobPos.z)
                                local Pos = Vector3.new(GoalPos.x, GoalPos.y, GoalPos.z)
                                MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
                                MyRoot.Velocity = vector.zero
                                if mouse1click then mouse1click() end
                            end
                        end
                        return  -- skip mining while actively in kill combat
                    else
                        -- Spam mode: just spam weapon switch while mining continues
                        SpamWeaponSwitch()
                    end
                else
                    -- no mobs nearby
                    if InCombat then
                        InCombat = false
                        CurrentMobTarget = nil
                        if SavedMiningTarget and IsValid(SavedMiningTarget) and GetRockHealth(SavedMiningTarget) > 0 then
                            CurrentTarget = SavedMiningTarget
                            TargetLocked = true
                        end
                        SavedMiningTarget = nil
                        if Config.AutoEquip then
                            EquipTool(Config.ToolName, 49)
                        end
                    end
                end
            end

            -- MINING LOGIC
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

                local Y_Offset = (Config.MiningPosition == "Under") and -Config.UnderOffset or Config.AboveOffset
                local GoalPos = vector.create(OrePos.x, OrePos.y + Y_Offset, OrePos.z)

                local DistToRock = vector.magnitude(MyRoot.Position - OrePos)
                if DistToRock > 15 and MaxHP > 0 and HP < MaxHP and not TargetLocked then
                    CurrentTarget = nil
                    return
                end

                if Config.PriorityVolcanic and not IsVolcanic(CurrentTarget) then
                    local PriorityRock = FindVolcanicRock()
                    if PriorityRock then
                        CurrentTarget = PriorityRock
                        TargetLocked = false
                        return
                    end
                end

                local HasWanted, AllOres = HasAnyWantedOre(CurrentTarget)
                if AllOres and #AllOres > 0 then
                    if Config.FilterEnabled then
                        local ApplyFilter = true
                        if Config.FilterVolcanicOnly and not IsVolcanic(CurrentTarget) then
                            ApplyFilter = false
                        end
                        if ApplyFilter and not HasWanted then
                            CurrentTarget = nil
                            TargetLocked = false
                            return
                        end
                    end
                end

                local Diff = MyRoot.Position - GoalPos
                local Dist = vector.magnitude(Diff)

                if Dist > Config.MineDistance then
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

                    local LookAt = Vector3.new(OrePos.x, OrePos.y, OrePos.z)
                    local Pos = Vector3.new(GoalPos.x, GoalPos.y, GoalPos.z)
                    MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
                    MyRoot.Velocity = vector.zero

                    if os.clock() - LastMineClick > Config.ClickDelay then
                        if mouse1click then mouse1click() end
                        LastMineClick = os.clock()
                    end
                end
            else
                -- pick a new target: primary rocks first, then fallback
                local primary = FindNearestRock()
                if primary then
                    CurrentTarget = primary
                    TargetLocked = false
                elseif Config.FallbackEnabled then
                    local fb = FindFallbackRock()
                    if fb then
                        CurrentTarget = fb
                        TargetLocked = false
                    end
                end
            end
        end
    end
end

local Connected = false
pcall(function()
    RunService.RenderStepped:Connect(UpdateLoop)
    Connected = true
end)
if not Connected then
    pcall(function()
        RunService.Heartbeat:Connect(UpdateLoop)
        Connected = true
    end)
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
