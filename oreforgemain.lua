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
local FallbackRocks = {} -- rocks flagged as fallback

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
        "Iceite"
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

    -- MOB COMBAT
    MobDetectionRange = CustomSettings.MobScanRange or 30,
    MobCombatMode = CustomSettings.CombatMode or "Kill", -- "Kill" or "Spam"
    CombatUnderOffset = CustomSettings.CombatUnderOffset or 8,
    CombatEnabled = CustomSettings.CombatEnabled or false, -- master toggle

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
    PriorityVolcanic = CustomSettings.PriorityVolcanic or false, -- no button now, but still usable via _G
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

local Colors = {
    Bg = Color3.fromRGB(30, 30, 30), Header = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255), On = Color3.fromRGB(0, 255, 100),
    Off = Color3.fromRGB(255, 50, 50), Btn = Color3.fromRGB(60, 60, 60),
    Lava = Color3.fromRGB(255, 100, 0), Gold = Color3.fromRGB(255, 200, 0),
    Debug = Color3.fromRGB(255, 0, 255), Combat = Color3.fromRGB(255, 100, 150)
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
            -- skip root
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
    if absPos and absSize then
        local centerX = absPos.X + (absSize.X / 2)
        local centerY = absPos.Y + (absSize.Y / 2)
        if mouse1click and MouseService then
            mouse1click()
            MouseService:SetMouseLocation(centerX, centerY)
            return true
        end
    end
    return false
end

-- ============================================================================
-- 3. MOBS & COMBAT
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

    local Closest = nil
    local MinDist = 999999

    for _, Mob in ipairs(LivingFolder:GetChildren()) do
        if Players:FindFirstChild(Mob.Name) then
            -- skip players
        else
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
    end

    return Closest
end

local function EquipTool(ToolName, SlotKeycode)
    local Char = LocalPlayer.Character
    if not Char then return false end

    if Char:FindFirstChild(ToolName) then return true end

    local Backpack = LocalPlayer.Backpack
    if Backpack and Backpack:FindFirstChild(ToolName) then
        if keypress and SlotKeycode then
            keypress(SlotKeycode)
            keyrelease(SlotKeycode)
            return true
        end
    end
    return false
end

local function SpamWeaponSwitch()
    if os.clock() - LastWeaponSwitch < 0.1 then return end

    if keypress then
        local slot = (os.clock() % 0.4 < 0.2) and 49 or 50 -- '1' or '2'
        keypress(slot)
        keyrelease(slot)
    end

    LastWeaponSwitch = os.clock()
end

-- ============================================================================
-- 4. ORE LOGIC & FILTERS
-- ============================================================================

local function GetRevealedOreType(Rock)
    if not IsValid(Rock) then return nil end

    local Attr = SafeGetAttribute(Rock, "Ore")
    if Attr and Attr ~= "" then return tostring(Attr) end

    local Success, Children = pcall(function() return Rock:GetChildren() end)
    if Success and Children then
        for _, Child in ipairs(Children) do
            if Child and Child.Name == "Ore" then
                local ChildAttr = SafeGetAttribute(Child, "Ore")
                if ChildAttr and ChildAttr ~= "" then
                    return tostring(ChildAttr)
                end
            end
        end
    end

    return nil
end

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
                    local AlreadyHave = false
                    for _, ExistingOre in ipairs(AllOres) do
                        if ExistingOre == OreStr then
                            AlreadyHave = true
                            break
                        end
                    end
                    if not AlreadyHave then
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

    if Config.FilterWhitelist[CurrentOre] then
        return true
    end

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

    if SavedMiningTarget then
        if not IsValid(SavedMiningTarget) or GetRockHealth(SavedMiningTarget) <= 0 then
            SavedMiningTarget = nil
        end
    end

    if CurrentMobTarget then
        if not IsAlive(CurrentMobTarget) then
            CurrentMobTarget = nil
            InCombat = false
        end
    end
end

-- ============================================================================
-- 5. MOVEMENT & INPUT
-- ============================================================================

local function IsMouseInRect(MousePos, RectX, RectY, RectW, RectH)
    return MousePos.X >= RectX and MousePos.X <= RectX + RectW and
           MousePos.Y >= RectY and MousePos.Y <= RectY + RectH
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
    local Closest = nil
    local MinDist = 999999

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

-- ============================================================================
-- 6. AUTO SELL SYSTEM (UI-BASED, WITH TIMEOUT)
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

        local Path_DialogueBtn   = "game.Players." .. pName .. ".PlayerGui.DialogueUI.ResponseBillboard.Response.Button"
        local Path_SellUI        = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell"
        local Path_SelectAll     = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.SelectAll"
        local Path_SelectTitle   = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.SelectAll.Frame.Title"
        local Path_Accept        = "game.Players." .. pName .. ".PlayerGui.Sell.MiscSell.Frame.Accept"

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

        timeout = 0
        while timeout < 20 do
            if CheckTimeout() then return end
            local bb3 = GetObject(Path_Billboard)
            if not bb3 or not bb3.Visible then break end
            local diagBtn = GetObject(Path_DialogueBtn)
            if diagBtn then ClickObject(diagBtn) end
            task.wait(0.5)
            timeout = timeout + 1
        end

        IsSelling = false
    end
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
        if Obj.ClassName == "Model" then
            if IsValid(Obj) then
                local H = Obj:GetAttribute("Health")
                if H and tonumber(H) > 0 then
                    table.insert(FoundInstances, Obj)
                    local N = Obj.Name
                    if not RockNamesSet[N] then
                        RockNamesSet[N] = true
                        table.insert(RockList, N)
                        table.sort(RockList)
                        if EnabledRocks[N] == nil then EnabledRocks[N] = false end
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
-- 8. TARGET SELECTION WITH FALLBACK
-- ============================================================================

local function RockPassesFilter(Rock)
    if not Config.FilterEnabled then return true end

    local RevealedOre = GetRevealedOreType(Rock)
    if not RevealedOre then return true end

    local ApplyFilter = true

    if Config.FilterVolcanicOnly and not IsVolcanic(Rock) then
        ApplyFilter = false
    end

    if not ApplyFilter then
        return true
    end

    if not IsOreWanted(RevealedOre) then
        return false
    end

    return true
end

local function FindNearestRock()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local MyPos = Root.Position

    if Config.PriorityVolcanic then
        local Volcanic = FindVolcanicRock()
        if Volcanic then return Volcanic end
    end

    -- PRIMARY: enabled rocks that are not marked as fallback
    local ClosestPrimary = nil
    local MinPrimary = 999999

    for _, Rock in ipairs(ActiveRocks) do
        if IsValid(Rock) then
            local RName = SafeGetName(Rock)
            if RName and EnabledRocks[RName] and not FallbackRocks[RName] then
                local HP = GetRockHealth(Rock)
                local MaxHP = GetRockMaxHealth(Rock)
                local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)
                if IsFresh and RockPassesFilter(Rock) then
                    local Pos = GetPosition(Rock)
                    if Pos then
                        local Dist = vector.magnitude(Pos - MyPos)
                        if Dist < MinPrimary then
                            MinPrimary = Dist
                            ClosestPrimary = Rock
                        end
                    end
                end
            end
        end
    end

    if ClosestPrimary or not Config.FallbackEnabled then
        return ClosestPrimary
    end

    -- FALLBACK: any rocks explicitly checked in the fallback menu,
    -- regardless of whether they are enabled in the main list.
    local ClosestFallback = nil
    local MinFallback = 999999

    for _, Rock in ipairs(ActiveRocks) do
        if IsValid(Rock) then
            local RName = SafeGetName(Rock)
            if RName and FallbackRocks[RName] then
                local HP = GetRockHealth(Rock)
                local MaxHP = GetRockMaxHealth(Rock)
                local IsFresh = (MaxHP > 0 and HP >= MaxHP) or (MaxHP == 0 and HP > 0)
                if IsFresh and RockPassesFilter(Rock) then
                    local Pos = GetPosition(Rock)
                    if Pos then
                        local Dist = vector.magnitude(Pos - MyPos)
                        if Dist < MinFallback then
                            MinFallback = Dist
                            ClosestFallback = Rock
                        end
                    end
                end
            end
        end
    end

    return ClosestFallback
end

-- ============================================================================
-- 9. RENDER LOOP
-- ============================================================================

local function UpdateLoop()
    GarbageCollect()
    local DeltaTime = 0.03

    local MousePos = MouseService and MouseService:GetMouseLocation() or Vector2.new(0, 0)
    local Clicked = CheckClick()
    local IsLeftDown = false
    if isleftpressed then IsLeftDown = isleftpressed() end

    -- DRAG LOGIC
    if IsLeftDown then
        if not MainUI.Dragging and not FilterUI.Dragging and not FallbackUI.Dragging then
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
    else
        MainUI.Dragging = false
        FilterUI.Dragging = false
        FallbackUI.Dragging = false
    end

    -- TOGGLE BUTTON (small button on screen)
    DrawingImmediate.FilledRectangle(
        vector.create(MainUI.ToggleBtn.X, MainUI.ToggleBtn.Y, 0),
        vector.create(MainUI.ToggleBtn.W, MainUI.ToggleBtn.H, 0),
        MainUI.Visible and Colors.On or Colors.Off, 1
    )
    DrawingImmediate.Text(
        vector.create(MainUI.ToggleBtn.X + 20, MainUI.ToggleBtn.Y + 12, 0),
        14, Color3.new(0, 0, 0), 1, "Ore", true, nil
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
        local function MainBtn(Txt, Col, Act)
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 25, 0),
                Col, 1
            )
            DrawingImmediate.Text(
                vector.create(MainUI.X + 20, MainUI.Y + Y + 5, 0),
                16, Colors.Text, 1, Txt, false, nil
            )
            if Clicked and IsMouseInRect(MousePos, MainUI.X + 10, MainUI.Y + Y, MainUI.Width - 20, 25) then
                Act()
            end
            Y = Y + 30
        end

        MainBtn(Config.MainEnabled and "FARMING: ON" or "FARMING: OFF",
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

        local LavaTxt = Config.OnlyLava and "ONLY LAVA: ON" or "ONLY LAVA: OFF"
        MainBtn(LavaTxt, Config.OnlyLava and Colors.On or Colors.Off, function()
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
        end)

        -- Fallback Menu button
        local FallbackMenuTxt = FallbackUI.Visible and "Close Fallback Menu" or "Open Fallback Menu"
        MainBtn(FallbackMenuTxt, Colors.Gold, function()
            FallbackUI.Visible = not FallbackUI.Visible
        end)

        -- Combat toggle
        local CombatToggleTxt = "Combat : " .. (Config.CombatEnabled and "ON" or "OFF")
        MainBtn(CombatToggleTxt, Config.CombatEnabled and Colors.On or Colors.Off, function()
            Config.CombatEnabled = not Config.CombatEnabled
            if not Config.CombatEnabled then
                InCombat = false
                CurrentMobTarget = nil
                SavedMiningTarget = nil
            end
        end)

        -- Combat mode
        local ModeTxt = "Mode : " .. (Config.MobCombatMode == "Kill" and "Kill" or "Spam")
        MainBtn(ModeTxt, Colors.Combat, function()
            Config.MobCombatMode = (Config.MobCombatMode == "Kill") and "Spam" or "Kill"
        end)

        local PosTxt = "MINE POS: " .. (Config.MiningPosition == "Under" and "UNDER" or "ABOVE")
        MainBtn(PosTxt, Colors.Btn, function()
            Config.MiningPosition = (Config.MiningPosition == "Under") and "Above" or "Under"
            CurrentTarget = nil
        end)

        local SellTxt = Config.AutoSell and "AUTO SELL: ON" or "AUTO SELL: OFF"
        MainBtn(SellTxt, Config.AutoSell and Colors.On or Colors.Off, function()
            Config.AutoSell = not Config.AutoSell
        end)

        MainBtn(Config.EspEnabled and "ORE ESP: ON" or "ORE ESP: OFF",
            Config.EspEnabled and Colors.On or Colors.Off,
            function()
                Config.EspEnabled = not Config.EspEnabled
            end
        )

        MainBtn(Config.AutoEquip and "Auto Pickaxe: ON" or "Auto Pickaxe: OFF",
            Config.AutoEquip and Colors.On or Colors.Off,
            function()
                Config.AutoEquip = not Config.AutoEquip
            end
        )

        MainBtn(FilterUI.Visible and "Close Filter Menu" or "Open Filter Menu",
            Colors.Gold,
            function()
                FilterUI.Visible = not FilterUI.Visible
            end
        )

        Y = Y + 10
        DrawingImmediate.OutlinedText(
            vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
            14, Colors.Text, 1, "Select Rocks to Farm:", false, nil
        )
        Y = Y + 20

        for _, Name in ipairs(RockList) do
            local IsOn = EnabledRocks[Name]
            DrawingImmediate.FilledRectangle(
                vector.create(MainUI.X + 10, MainUI.Y + Y, 0),
                vector.create(MainUI.Width - 20, 20, 0),
                IsOn and Colors.On or Colors.Off, 1
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
        end
        FY = FY + 30

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
        end
        FY = FY + 35

        local Cats = {"Stonewake", "Forgotten", "Goblin", "Frozen"}
        local btnW = (FilterUI.Width - 40) / #Cats

        for i, Cat in ipairs(Cats) do
            local bx = FilterUI.X + 10 + ((i - 1) * (btnW + 5))
            local isSel = FilterUI.CurrentCategory == Cat
            DrawingImmediate.FilledRectangle(
                vector.create(bx, FilterUI.Y + FY, 0),
                vector.create(btnW, 25, 0),
                isSel and Colors.Gold or Colors.Btn, 1
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
                IsWhitelisted and Colors.On or Colors.Off, 1
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

    -- FALLBACK WINDOW
    if FallbackUI.Visible then
        -- now show ALL discovered rocks (RockList), not just ones enabled
        local FallbackNames = {}
        for _, Name in ipairs(RockList) do
            table.insert(FallbackNames, Name)
        end

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
                IsFB and Colors.On or Colors.Off, 1
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

    -- ORE ESP
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

    -- STASH CAPACITY DISPLAY
    local pName = LocalPlayer and LocalPlayer.Name or ""
    if pName ~= "" then
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
    end

    -- COMBAT STATUS TEXT
    if InCombat and Config.CombatEnabled then
        DrawingImmediate.OutlinedText(
            vector.create(Camera.ViewportSize.X - 150, 40, 0),
            18, Colors.Combat, 1, "COMBAT MODE", false, nil
        )
    end

    if IsSelling then return end

    local Char = LocalPlayer.Character
    if Char then CheckAutoEquip(Char) end

    if Char and Char:FindFirstChild("HumanoidRootPart") then
        local MyRoot = Char.HumanoidRootPart
        if Config.MainEnabled then
            local NearbyMob = nil
            if Config.CombatEnabled then
                NearbyMob = FindNearestMob(MyRoot.Position)
            end

            if NearbyMob and Config.CombatEnabled then
                InCombat = true

                if Config.MobCombatMode == "Kill" then
                    if CurrentTarget and not SavedMiningTarget then
                        SavedMiningTarget = CurrentTarget
                    end

                    CurrentMobTarget = NearbyMob
                    CurrentTarget = nil
                    TargetLocked = false

                    local MobRoot = NearbyMob:FindFirstChild("HumanoidRootPart")
                    local Hum = NearbyMob:FindFirstChild("Humanoid")

                    if not MobRoot or not Hum or Hum.Health <= 0 then
                        InCombat = false
                        CurrentMobTarget = nil
                    else
                        local MobPos = MobRoot.Position
                        local GoalPos = vector.create(MobPos.X, MobPos.Y - Config.CombatUnderOffset, MobPos.Z)
                        local Diff = MyRoot.Position - GoalPos
                        local Dist = vector.magnitude(Diff)

                        if Dist > Config.MineDistance then
                            SkyHopMove(MyRoot, GoalPos, DeltaTime)
                        else
                            EquipTool(Config.WeaponName, 50)
                            local LookAt = Vector3.new(MobPos.X, MobPos.Y, MobPos.Z)
                            local Pos = Vector3.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
                            MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
                            MyRoot.Velocity = vector.zero
                            if mouse1click then mouse1click() end
                        end
                    end
                elseif Config.MobCombatMode == "Spam" then
                    SpamWeaponSwitch()
                    -- still mine below
                end
            else
                -- NO MOBS or combat disabled
                if InCombat and not NearbyMob then
                    InCombat = false
                    CurrentMobTarget = nil
                end

                if SavedMiningTarget and not CurrentTarget then
                    if IsValid(SavedMiningTarget) and GetRockHealth(SavedMiningTarget) > 0 then
                        CurrentTarget = SavedMiningTarget
                        TargetLocked = true
                    end
                    SavedMiningTarget = nil
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

                    local Y_Offset = (Config.MiningPosition == "Under") and -Config.UnderOffset or Config.AboveOffset
                    local GoalPos = vector.create(OrePos.X, OrePos.Y + Y_Offset, OrePos.Z)

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
                        local ScreenPos, Visible = Camera:WorldToScreenPoint(OrePos)
                        if Visible then
                            local OreListText = "Ores: "
                            for i, ore in ipairs(AllOres) do
                                OreListText = OreListText .. ore
                                if i < #AllOres then OreListText = OreListText .. ", " end
                            end

                            DrawingImmediate.OutlinedText(
                                vector.create(ScreenPos.X, ScreenPos.Y - 30, 0),
                                14,
                                Color3.fromRGB(255, 255, 0),
                                1,
                                OreListText,
                                true,
                                nil
                            )
                        end

                        if Config.FilterEnabled then
                            local ApplyFilter = true
                            if Config.FilterVolcanicOnly and not IsVolcanic(CurrentTarget) then
                                ApplyFilter = false
                            end

                            if ApplyFilter then
                                local ScreenPos2, Visible2 = Camera:WorldToScreenPoint(OrePos)
                                if Visible2 then
                                    local StatusColor = HasWanted and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                                    local StatusText = HasWanted and "KEEPING" or "SKIPPING"
                                    DrawingImmediate.OutlinedText(
                                        vector.create(ScreenPos2.X, ScreenPos2.Y - 45, 0),
                                        14, StatusColor, 1, StatusText, true, nil
                                    )
                                end

                                if not HasWanted then
                                    CurrentTarget = nil
                                    TargetLocked = false
                                    return
                                end
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

                        local LookAt = Vector3.new(OrePos.X, OrePos.Y, OrePos.Z)
                        local Pos = Vector3.new(GoalPos.X, GoalPos.Y, GoalPos.Z)
                        MyRoot.CFrame = CFrame.lookAt(Pos, LookAt)
                        MyRoot.Velocity = vector.zero

                        if os.clock() - LastMineClick > Config.ClickDelay then
                            if mouse1click then mouse1click() end
                            LastMineClick = os.clock()
                        end
                    end
                else
                    CurrentTarget = FindNearestRock()
                    TargetLocked = false
                end
            end
        end
    end
end

RunService.Render:Connect(UpdateLoop)

