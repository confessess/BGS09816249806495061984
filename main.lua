-- Bubble Gum Simulator - AIRFLOW Farm Tab
-- This loads the AIRFLOW library automatically from the official repo.

local AirFlowURL = "https://raw.githubusercontent.com/confessess/AIRFLOW0978109571095710975/e855b319992e144672643529696317e9aae2fdb4/source.lua"
local AirFlow = getgenv().AirFlow or getgenv().AIRFLOW or getgenv().Library

local function TryLoadAirFlow()
    if AirFlow and (type(AirFlow.CreateWindow) == "function" or type(AirFlow.Window) == "function") then
        return true
    end

    local candidates = {
        function()
            return loadstring(game:HttpGet(AirFlowURL))()
        end,
        function()
            return loadstring(game:HttpGet(AirFlowURL, true))()
        end,
    }

    for _, loader in ipairs(candidates) do
        local ok, lib = pcall(loader)
        if ok and type(lib) == "table" then
            AirFlow = lib
            getgenv().AirFlow = AirFlow
            getgenv().AIRFLOW = AirFlow
            getgenv().Library = AirFlow
            return true
        end
    end

    return false
end

local AirFlowLoaded = TryLoadAirFlow()

local function CreateFallbackUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BubbleGumFallback"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 120)
    frame.Position = UDim2.new(0.5, -140, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Bubble Gum Simulator"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 40)
    status.Position = UDim2.new(0, 10, 0, 42)
    status.BackgroundTransparency = 1
    status.Text = "AIRFLOW failed to load.\nUsing fallback UI."
    status.TextColor3 = Color3.fromRGB(255, 220, 100)
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextWrapped = true
    status.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 32)
    button.Position = UDim2.new(0, 10, 1, -42)
    button.Text = "Close"
    button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    return screenGui
end

if not AirFlowLoaded then
    warn("[Bubble Gum Simulator] AIRFLOW failed to load. Falling back to a visible emergency UI so the script still does something.")
    CreateFallbackUI()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if not AirFlowLoaded then
    return
end

local blowRemote = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("Remote")
    :WaitForChild("RemoteEvent")

local GumShopRemote = blowRemote

local MakeWindow = AirFlow.CreateWindow or AirFlow.Window
local Window = MakeWindow({
    Name = "Bubble Gum Simulator",
    LoadingSubtitle = "Loading...",
    Keybind = "RightControl",
    Size = UDim2.fromOffset(640, 480),
})

local FarmTab = Window:Tab({
    Name = "Farm",
    Icon = "sprout",
})

local function ParseNumber(text)
    if not text then return nil end

    local stripped = text:gsub("<[^>]+>", "")
    local clean = stripped:gsub("[%[%],%s]", "")

    local multiplier = 1
    local lower = clean:lower()

    if lower:find("k") then
        multiplier = 1000
        clean = clean:gsub("[Kk]", "")
    elseif lower:find("m") then
        multiplier = 1000000
        clean = clean:gsub("[Mm]", "")
    elseif lower:find("b") then
        multiplier = 1000000000
        clean = clean:gsub("[Bb]", "")
    elseif lower:find("t") then
        multiplier = 1000000000000
        clean = clean:gsub("[Tt]", "")
    end

    local num = clean:match("[%d%.]+")
    if num then
        return tonumber(num) * multiplier
    end

    return nil
end

local function GetCurrency(currencyName)
    local success, result = pcall(function()
        local currencyFrame = LocalPlayer
            :FindFirstChild("PlayerGui")
            :FindFirstChild("ScreenGui")
            :FindFirstChild("HUD")
            :FindFirstChild("Left")
            :FindFirstChild("Currency")
            :FindFirstChild(currencyName)

        if not currencyFrame then return nil end

        for _, child in ipairs(currencyFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.Text
                if not text:match("x%d") then
                    local parsed = ParseNumber(text)
                    if parsed then
                        return parsed
                    end
                end
            end
        end

        return nil
    end)

    return success and result or nil
end

local function GetCoins()
    return GetCurrency("Coins")
end

local function GetLeaves()
    return GetCurrency("Leaves26")
end

local function GetGems()
    return GetCurrency("Gems")
end

local autoblowEnabled = false
local autoblowLoop = nil

local function stopAutoblow()
    autoblowEnabled = false

    if autoblowLoop then
        task.cancel(autoblowLoop)
        autoblowLoop = nil
    end
end

FarmTab:Toggle({
    Name = "Autoblow",
    Default = false,
    Callback = function(enabled)
        autoblowEnabled = enabled

        if enabled then
            if autoblowLoop then
                return
            end

            autoblowLoop = task.spawn(function()
                while autoblowEnabled do
                    local position = Mouse.Hit and Mouse.Hit.Position or Vector3.new(0, 0, 0)
                    blowRemote:FireServer("BlowBubble", position)
                    task.wait(0.1)
                end

                autoblowLoop = nil
            end)
        else
            stopAutoblow()
        end
    end,
})

local ISLAND_COORDS = {
    Vector3.new(-12.945718765258789, 423.1529846191406, 131.2776641845703),
    Vector3.new(56.348236083984375, 2665.562744140625, -4.17958402633667),
    Vector3.new(-77.47685241699219, 6862.57861328125, 88.32815551757812),
    Vector3.new(16.435264587402344, 10146.095703125, 151.71536254882812),
    Vector3.new(36.75679397583008, 15971.8212890625, 41.872100830078125),
}

local function UnlockAllIslands()
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoidRootPart then
        print("[Bubble Gum Simulator] No HumanoidRootPart available to unlock islands.")
        return
    end

    local originalPosition = humanoidRootPart.CFrame

    for _, islandPosition in ipairs(ISLAND_COORDS) do
        humanoidRootPart.CFrame = CFrame.new(islandPosition)
        task.wait(0.5)
    end

    humanoidRootPart.CFrame = originalPosition
    print("[Bubble Gum Simulator] Finished island teleport sequence and restored original position.")
end

FarmTab:Button({
    Name = "Unlock All Islands",
    Callback = function()
        UnlockAllIslands()
    end,
})

local GEM_CORNER_1 = Vector3.new(2250.30859375, 3158.66943359375, 893.2330932617188)
local GEM_CORNER_2 = Vector3.new(2232.48046875, 3159.3681640625, 813.1329345703125)
local GEM_CORNER_3 = Vector3.new(2305.43359375, 3162.09130859375, 782.5587768554688)
local GEM_CORNER_4 = Vector3.new(2342.519287109375, 3160.68115234375, 848.6522827148438)
local GEM_GRID_SIZE = 20
local GEM_TELEPORT_DELAY = 0.1
local autoCollectGemsEnabled = false
local autoCollectGemsLoop = nil

local function ShuffleGemGrid(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function GetGemGridPositions()
    local positions = {}

    local minX = math.min(GEM_CORNER_1.X, GEM_CORNER_2.X, GEM_CORNER_3.X, GEM_CORNER_4.X)
    local maxX = math.max(GEM_CORNER_1.X, GEM_CORNER_2.X, GEM_CORNER_3.X, GEM_CORNER_4.X)
    local minZ = math.min(GEM_CORNER_1.Z, GEM_CORNER_2.Z, GEM_CORNER_3.Z, GEM_CORNER_4.Z)
    local maxZ = math.max(GEM_CORNER_1.Z, GEM_CORNER_2.Z, GEM_CORNER_3.Z, GEM_CORNER_4.Z)
    local avgY = (GEM_CORNER_1.Y + GEM_CORNER_2.Y + GEM_CORNER_3.Y + GEM_CORNER_4.Y) / 4

    for i = 0, GEM_GRID_SIZE - 1 do
        for j = 0, GEM_GRID_SIZE - 1 do
            local x = minX + (maxX - minX) * (i / (GEM_GRID_SIZE - 1))
            local z = minZ + (maxZ - minZ) * (j / (GEM_GRID_SIZE - 1))
            table.insert(positions, Vector3.new(x, avgY, z))
        end
    end

    return positions
end

FarmTab:Toggle({
    Name = "Auto Collect Gems",
    Default = false,
    Callback = function(enabled)
        autoCollectGemsEnabled = enabled

        if enabled then
            if autoCollectGemsLoop then
                return
            end

            autoCollectGemsLoop = task.spawn(function()
                while autoCollectGemsEnabled do
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                    if rootPart then
                        local positions = GetGemGridPositions()
                        ShuffleGemGrid(positions)

                        for _, pos in ipairs(positions) do
                            if not autoCollectGemsEnabled then
                                break
                            end

                            rootPart.CFrame = CFrame.new(pos)
                            task.wait(GEM_TELEPORT_DELAY)
                        end
                    end

                    task.wait(0.2)
                end

                autoCollectGemsLoop = nil
            end)
        else
            autoCollectGemsEnabled = false
            if autoCollectGemsLoop then
                task.cancel(autoCollectGemsLoop)
                autoCollectGemsLoop = nil
            end
        end
    end,
})

local AUTUMN_LEAVES_CORNER_1 = Vector3.new(222.37908935546875, 8.696333885192871, 125.83876037597656)
local AUTUMN_LEAVES_CORNER_2 = Vector3.new(187.0504608154297, 8.696332931518555, 183.437255859375)
local AUTUMN_LEAVES_CORNER_3 = Vector3.new(245.67454528808594, 9.143986701965332, 224.35597229003906)
local AUTUMN_LEAVES_CORNER_4 = Vector3.new(289.1279602050781, 9.289803504943848, 176.83973693847656)
local AUTUMN_LEAVES_GRID_SIZE = 20
local AUTUMN_LEAVES_TELEPORT_DELAY = 0.1
local autofarmLeavesEnabled = false
local autofarmLeavesLoop = nil

local function ShuffleAutumnLeavesGrid(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function GetAutumnLeavesGridPositions()
    local positions = {}

    local minX = math.min(AUTUMN_LEAVES_CORNER_1.X, AUTUMN_LEAVES_CORNER_2.X, AUTUMN_LEAVES_CORNER_3.X, AUTUMN_LEAVES_CORNER_4.X)
    local maxX = math.max(AUTUMN_LEAVES_CORNER_1.X, AUTUMN_LEAVES_CORNER_2.X, AUTUMN_LEAVES_CORNER_3.X, AUTUMN_LEAVES_CORNER_4.X)
    local minZ = math.min(AUTUMN_LEAVES_CORNER_1.Z, AUTUMN_LEAVES_CORNER_2.Z, AUTUMN_LEAVES_CORNER_3.Z, AUTUMN_LEAVES_CORNER_4.Z)
    local maxZ = math.max(AUTUMN_LEAVES_CORNER_1.Z, AUTUMN_LEAVES_CORNER_2.Z, AUTUMN_LEAVES_CORNER_3.Z, AUTUMN_LEAVES_CORNER_4.Z)
    local avgY = (AUTUMN_LEAVES_CORNER_1.Y + AUTUMN_LEAVES_CORNER_2.Y + AUTUMN_LEAVES_CORNER_3.Y + AUTUMN_LEAVES_CORNER_4.Y) / 4

    for i = 0, AUTUMN_LEAVES_GRID_SIZE - 1 do
        for j = 0, AUTUMN_LEAVES_GRID_SIZE - 1 do
            local x = minX + (maxX - minX) * (i / (AUTUMN_LEAVES_GRID_SIZE - 1))
            local z = minZ + (maxZ - minZ) * (j / (AUTUMN_LEAVES_GRID_SIZE - 1))
            table.insert(positions, Vector3.new(x, avgY, z))
        end
    end

    return positions
end

FarmTab:Toggle({
    Name = "Autofarm Leaves",
    Default = false,
    Callback = function(enabled)
        autofarmLeavesEnabled = enabled

        if enabled then
            if autofarmLeavesLoop then
                return
            end

            autofarmLeavesLoop = task.spawn(function()
                while autofarmLeavesEnabled do
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                    if rootPart then
                        local positions = GetAutumnLeavesGridPositions()
                        ShuffleAutumnLeavesGrid(positions)

                        for _, pos in ipairs(positions) do
                            if not autofarmLeavesEnabled then
                                break
                            end

                            rootPart.CFrame = CFrame.new(pos)
                            task.wait(AUTUMN_LEAVES_TELEPORT_DELAY)
                        end
                    end

                    task.wait(0.2)
                end

                autofarmLeavesLoop = nil
            end)
        else
            autofarmLeavesEnabled = false
            if autofarmLeavesLoop then
                task.cancel(autofarmLeavesLoop)
                autofarmLeavesLoop = nil
            end
        end
    end,
})

local HATCH_EGGS = {
    { Name = "Common Egg", Price = 10, Currency = "Coins", Position = Vector3.new(-83.77912902832031, 10.212990760803223, 1.4048134088516235) },
    { Name = "Spotted Egg", Price = 110, Currency = "Coins", Position = Vector3.new(-94.12103271484375, 10.212990760803223, 7.265876293182373) },
    { Name = "Iceshard Egg", Price = 450, Currency = "Coins", Position = Vector3.new(-117.36851501464844, 10.212989807128906, 8.800444602966309) },
    { Name = "Spikey Egg", Price = 5000, Currency = "Coins", Position = Vector3.new(-125.74794006347656, 10.212989807128906, 5.219719886779785) },
    { Name = "Magma Egg", Price = 15000, Currency = "Coins", Position = Vector3.new(-133.52877807617188, 10.212849617004395, -0.12242648750543594) },
    { Name = "Crystal Egg", Price = 75000, Currency = "Coins", Position = Vector3.new(-140.38662719726562, 10.212990760803223, -7.039910316467285) },
    { Name = "Lunar Egg", Price = 100000, Currency = "Coins", Position = Vector3.new(-143.5778045654297, 10.212990760803223, -17.30269432067871) },
    { Name = "Void Egg", Price = 175000, Currency = "Coins", Position = Vector3.new(-146.21742248535156, 10.21294116973877, -26.524805068969727) },
    { Name = "Hell Egg", Price = 300000, Currency = "Coins", Position = Vector3.new(-146.39942932128906, 10.212990760803223, -36.5159797668457) },
    { Name = "Nightmare Egg", Price = 900000, Currency = "Coins", Position = Vector3.new(-141.3435516357422, 10.212990760803223, -45.250553131103516) },
    { Name = "Rainbow Egg", Price = 1500000, Currency = "Coins", Position = Vector3.new(-135.94467163085938, 10.21269702911377, -53.06460189819336) },
    { Name = "Neon Pumpkin Egg", Price = 2500, Currency = "Leaves", Position = Vector3.new(286.5538330078125, 9.651476860046387, 206.7620849609375) },
    { Name = "Harvest Egg", Price = 500, Currency = "Leaves", Position = Vector3.new(292.7622985839844, 9.651476860046387, 197.60501098632812) },
    { Name = "Spirit Egg", Price = 5000, Currency = "Leaves", Position = Vector3.new(280.9252624511719, 9.651476860046387, 215.06297302246094) },
    { Name = "Ultra Fall Egg", Price = 10000, Currency = "Leaves", Position = Vector3.new(239.85446166992188, 9.49633502960205, 176.42636108398438) },
}

local function FormatCoins(value)
    if type(value) ~= "number" then
        return tostring(value)
    end

    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end

    return tostring(value)
end

local selectedEggs = { "Common Egg" }
local autoHatchEggsEnabled = false
local autoHatchEggsLoop = nil
local autoEquipBestPetsEnabled = false
local autoEquipBestPetsLoop = nil

local function GetEggByName(name)
    for _, egg in ipairs(HATCH_EGGS) do
        if egg.Name == name then
            return egg
        end
    end
    return nil
end

local function GetNextEggToHatch()
    if #selectedEggs == 0 then
        return nil
    end

    return selectedEggs[1]
end

local function HatchSelectedEgg(eggName)
    local egg = GetEggByName(eggName)
    if not egg then
        return false
    end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    rootPart.CFrame = CFrame.new(egg.Position)
    task.wait(0.3)
    GumShopRemote:FireServer("HatchEgg", egg.Name, 1)
    return true
end

local function CanAffordEgg(egg)
    if not egg or not egg.Price then
        return false
    end

    local currencyName = egg.Currency or "Coins"
    local walletValue

    if currencyName == "Leaves" then
        walletValue = GetLeaves()
    elseif currencyName == "Gems" then
        walletValue = GetGems()
    else
        walletValue = GetCoins()
    end

    if not walletValue then
        return false
    end

    return walletValue >= egg.Price
end

FarmTab:Dropdown({
    Title = "Eggs to Hatch",
    Default = "Common Egg",
    Options = (function()
        local names = {}
        for _, egg in ipairs(HATCH_EGGS) do
            table.insert(names, egg.Name)
        end
        return names
    end)(),
    Callback = function(value)
        if not value then
            return
        end

        selectedEggs = { value }
    end,
})

FarmTab:Toggle({
    Name = "Auto Hatch Eggs",
    Default = false,
    Callback = function(enabled)
        autoHatchEggsEnabled = enabled

        if enabled then
            if autoHatchEggsLoop then
                return
            end

            autoHatchEggsLoop = task.spawn(function()
                while autoHatchEggsEnabled do
                    if #selectedEggs > 0 then
                        local eggName = GetNextEggToHatch()
                        if eggName then
                            local egg = GetEggByName(eggName)
                            if egg then
                                if CanAffordEgg(egg) then
                                    HatchSelectedEgg(eggName)
                                    task.wait(0.5)
                                else
                                    local walletKey = egg.Currency or "Coins"
                                    local walletLabel = (walletKey == "Leaves" and "leaves") or (walletKey == "Gems" and "gems") or "coins"
                                    local balance = (walletKey == "Leaves" and GetLeaves()) or (walletKey == "Gems" and GetGems()) or GetCoins()
                                    print("[Auto Hatch Eggs] waiting for enough " .. walletLabel .. " for " .. egg.Name .. " (" .. tostring(balance or 0) .. "/" .. tostring(egg.Price) .. ")")
                                    task.wait(1)
                                end
                            end
                        end
                    else
                        task.wait(1)
                    end
                end

                autoHatchEggsLoop = nil
            end)
        else
            autoHatchEggsEnabled = false
            if autoHatchEggsLoop then
                task.cancel(autoHatchEggsLoop)
                autoHatchEggsLoop = nil
            end
        end
    end,
})

FarmTab:Toggle({
    Name = "Auto Equip Best Pets",
    Default = false,
    Callback = function(enabled)
        autoEquipBestPetsEnabled = enabled

        if enabled then
            if autoEquipBestPetsLoop then
                return
            end

            autoEquipBestPetsLoop = task.spawn(function()
                while autoEquipBestPetsEnabled do
                    GumShopRemote:FireServer("EquipBestPets")
                    task.wait(5)
                end

                autoEquipBestPetsLoop = nil
            end)
        else
            autoEquipBestPetsEnabled = false
            if autoEquipBestPetsLoop then
                task.cancel(autoEquipBestPetsLoop)
                autoEquipBestPetsLoop = nil
            end
        end
    end,
})

local AUTO_SELL_LOCATIONS = {
    Ground = Vector3.new(77.39828491210938, 9.260798454284668, -112.7100830078125),
    Twilight = Vector3.new(-70.3258285522461, 6862.57861328125, 116.25569915771484),
}
local GUM_SHOP_POSITION = Vector3.new(34.85653305053711, 9.260798454284668, -113.89456176757812)
local SELL_DROP_OFFSET = Vector3.new(0, 1, 0)
local autoSellEnabled = false
local autoSellLoop = nil
local autoSellTeleporting = false
local lastAutoSellTime = 0
local autoSellLocation = "Ground"
local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or nil

local function RefreshRootPart()
    rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or nil
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local newRoot = character:WaitForChild("HumanoidRootPart")
    rootPart = newRoot
end)

local function GetBagCount()
    local success, current, max = pcall(function()
        local bubble = LocalPlayer
            :FindFirstChild("PlayerGui")
            :FindFirstChild("ScreenGui")
            :FindFirstChild("HUD")
            :FindFirstChild("Left")
            :FindFirstChild("Currency")
            :FindFirstChild("Bubble")

        if not bubble then
            return nil, nil
        end

        for _, child in ipairs(bubble:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.Text
                if type(text) == "string" then
                    local stripped = text:gsub("<[^>]+>", "")
                    stripped = stripped:gsub(",", "")
                    stripped = stripped:gsub("%s+", "")

                    local curr, mx = stripped:match("(%d+)%/*(%d+)")
                    if curr and mx then
                        return tonumber(curr), tonumber(mx)
                    end

                    local curr2, mx2 = stripped:match("(%d+)%/(%d+)")
                    if curr2 and mx2 then
                        return tonumber(curr2), tonumber(mx2)
                    end
                end
            end
        end

        return nil, nil
    end)

    if success then
        return current, max
    end

    return nil, nil
end

local function IsBagFull()
    local current, max = GetBagCount()
    if not current or not max then
        return false
    end
    return current >= max
end

local function TeleportToSell()
    RefreshRootPart()
    if autoSellTeleporting or not rootPart then
        return
    end

    local targetSellPosition = AUTO_SELL_LOCATIONS[autoSellLocation] or AUTO_SELL_LOCATIONS.Ground
    autoSellTeleporting = true
    local originalPosition = rootPart.Position
    local sellAbovePosition = targetSellPosition + SELL_DROP_OFFSET

    rootPart.CFrame = CFrame.new(sellAbovePosition)
    task.wait(0.12)

    local current, max = GetBagCount()
    while current and current > 0 do
        rootPart.CFrame = CFrame.new(sellAbovePosition)
        task.wait(0.1)
        current, max = GetBagCount()
    end

    task.wait(0.15)
    RefreshRootPart()
    if rootPart and originalPosition then
        rootPart.CFrame = CFrame.new(originalPosition)
    end
    autoSellTeleporting = false
end

FarmTab:Dropdown({
    Title = "Auto Sell Location",
    Default = "Ground",
    Options = {"Ground", "Twilight"},
    Callback = function(value)
        autoSellLocation = value or "Ground"
    end,
})

FarmTab:Toggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(enabled)
        autoSellEnabled = enabled

        if enabled then
            if autoSellLoop then
                return
            end

            autoSellLoop = task.spawn(function()
                while autoSellEnabled do
                    RefreshRootPart()
                    if IsBagFull() and not autoSellTeleporting then
                        local elapsed = os.clock() - lastAutoSellTime
                        if elapsed >= 2 then
                            lastAutoSellTime = os.clock()
                            TeleportToSell()
                        end
                    end
                    task.wait(0.2)
                end

                autoSellLoop = nil
            end)
        else
            autoSellEnabled = false
            lastAutoSellTime = 0

            if autoSellLoop then
                task.cancel(autoSellLoop)
                autoSellLoop = nil
            end
        end
    end,
})

local PROGRESSION = {
    { 25, "Blueberry" },
    { 500, "Cherry" },
    { 1500, "Pizza" },
    { 3500, "Watermelon" },
    { 10000, "Chocolate" },
    { 35000, "Contrast" },
    { 100000, "Gold" },
    { 450000, "Lemon" },
    { 1500000, "Donut" },
    { 30000000, "Swirl" },
    { 350000000, "Molten" },
    { 500000000, "Classic" },
    { 900000000, "Abstract" },
    { 1000000000, "Dark Matter" },
}

local STORAGE_TYPES = {
    { Name = "Basic Gum", Price = 0 },
    { Name = "Stretchy Gum", Price = 25 },
    { Name = "Chewy Gum", Price = 250 },
    { Name = "Epic Gum", Price = 1500 },
    { Name = "Ultra Gum", Price = 5000 },
    { Name = "Omega Gum", Price = 12000 },
    { Name = "Unreal Gum", Price = 45000 },
    { Name = "Cosmic Gum", Price = 125000 },
    { Name = "XL Gum", Price = 650000 },
    { Name = "Mega Gum", Price = 1500000 },
    { Name = "Quantum Gum", Price = 5000000 },
    { Name = "Alien Gum", Price = 35000000 },
    { Name = "Experiment #52", Price = 52000000 },
    { Name = "Radioactive Gum", Price = 150000000 },
    { Name = "Retro Gum", Price = 1500000000 },
    { Name = "Dark Matter Gum", Price = 2500000000 },
    { Name = "Robogum", Price = 5000000000 },
    { Name = "Void Gum", Price = 95000000000 },
}

local AUTO_PROGRESS_LIST = {}
for _, item in ipairs(PROGRESSION) do
    local threshold, flavorName = item[1], item[2]
    table.insert(AUTO_PROGRESS_LIST, {
        Name = flavorName,
        MinCoins = threshold,
    })
end

local STORAGE_PROGRESS_LIST = {}
for _, item in ipairs(STORAGE_TYPES) do
    table.insert(STORAGE_PROGRESS_LIST, {
        Name = item.Name,
        MinCoins = item.Price,
    })
end

local autoprogressEnabled = false
local autoprogressLoop = nil
local autoprogressIndex = 1
local autoprogressStorageIndex = 1
local autoprogressBuying = false
local AUTOPROGRESS_MEMORY_PATH = "BubbleGumSimulator/AutoprogressMemory.json"
local autoprogressLastFlavor = getgenv().BubbleGumAutoprogressLastFlavor or nil
local autoprogressLastStorage = getgenv().BubbleGumAutoprogressLastStorage or nil

local function LoadAutoprogressMemory()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
        return nil
    end

    if not isfile(AUTOPROGRESS_MEMORY_PATH) then
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(AUTOPROGRESS_MEMORY_PATH))
    end)

    if ok and type(data) == "table" then
        return data
    end

    return nil
end

local function SaveAutoprogressMemory()
    if typeof(writefile) ~= "function" or typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
        return
    end

    pcall(function()
        if not isfolder("BubbleGumSimulator") then
            makefolder("BubbleGumSimulator")
        end
    end)

    pcall(function()
        writefile(AUTOPROGRESS_MEMORY_PATH, HttpService:JSONEncode({
            lastFlavor = autoprogressLastFlavor or "",
            lastStorage = autoprogressLastStorage or "",
        }))
    end)
end

local function GetTargetByName(name)
    for _, flavorInfo in ipairs(AUTO_PROGRESS_LIST) do
        if flavorInfo.Name == name then
            return flavorInfo
        end
    end
    return nil
end

local function GetStorageByName(name)
    for _, storageInfo in ipairs(STORAGE_TYPES) do
        if storageInfo.Name == name then
            return storageInfo
        end
    end
    return nil
end

local function GetFlavorIndexByName(name)
    for index, flavorInfo in ipairs(AUTO_PROGRESS_LIST) do
        if flavorInfo.Name == name then
            return index
        end
    end
    return nil
end

local function GetStorageIndexByName(name)
    for index, storageInfo in ipairs(STORAGE_PROGRESS_LIST) do
        if storageInfo.Name == name then
            return index
        end
    end
    return nil
end

local function IsItemOwned(itemName)
    if not itemName then
        return false
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end

    local lookedFor = string.lower(itemName)
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local text = descendant.Text
            if type(text) == "string" then
                local lowerText = string.lower(text)
                if lowerText:find(lookedFor, 1, true) then
                    if lowerText:find("owned", 1, true)
                        or lowerText:find("equipped", 1, true)
                        or lowerText:find("equipping", 1, true)
                        or lowerText:find("selected", 1, true)
                        or lowerText:find("current", 1, true)
                    then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function TryServerCalls(actionNames, argument)
    for _, actionName in ipairs(actionNames) do
        local ok = pcall(function()
            if argument ~= nil then
                GumShopRemote:FireServer(actionName, argument)
            else
                GumShopRemote:FireServer(actionName)
            end
        end)

        if ok then
            return true, actionName
        end
    end

    return false, nil
end

local function SetLastFlavor(name)
    if not name then
        return
    end

    autoprogressLastFlavor = name
    getgenv().BubbleGumAutoprogressLastFlavor = name
    SaveAutoprogressMemory()
end

local function SetLastStorage(name)
    if not name then
        return
    end

    autoprogressLastStorage = name
    getgenv().BubbleGumAutoprogressLastStorage = name
    SaveAutoprogressMemory()
end

local function InitAutoprogressMemory()
    local stored = LoadAutoprogressMemory()
    if stored then
        if type(stored.lastFlavor) == "string" and stored.lastFlavor ~= "" then
            autoprogressLastFlavor = stored.lastFlavor
            getgenv().BubbleGumAutoprogressLastFlavor = stored.lastFlavor
        end

        if type(stored.lastStorage) == "string" and stored.lastStorage ~= "" then
            autoprogressLastStorage = stored.lastStorage
            getgenv().BubbleGumAutoprogressLastStorage = stored.lastStorage
        end
    end
end

local function ResolveStartIndex()
    if autoprogressLastFlavor then
        for index, flavorInfo in ipairs(AUTO_PROGRESS_LIST) do
            if flavorInfo.Name == autoprogressLastFlavor then
                return math.min(index + 1, #AUTO_PROGRESS_LIST)
            end
        end
    end

    return 1
end

local function ResolveStorageStartIndex()
    if autoprogressLastStorage then
        for index, storageInfo in ipairs(STORAGE_TYPES) do
            if storageInfo.Name == autoprogressLastStorage then
                return math.min(index + 1, #STORAGE_TYPES)
            end
        end
    end

    return 1
end

InitAutoprogressMemory()

local function AttemptProgressFlavor(flavorName)
    if not flavorName then
        return false
    end

    local target = GetTargetByName(flavorName)
    if not target then
        return false
    end

    local coins = GetCoins()
    if not coins then
        print("[Autoprogress] no coin value available for " .. flavorName)
        return false
    end

    if coins < target.MinCoins then
        print("[Autoprogress] waiting for enough coins for " .. flavorName .. " (" .. tostring(coins) .. "/" .. tostring(target.MinCoins) .. ")")
        return false
    end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local originalPosition = rootPart and rootPart.Position or nil
    local beforeCoins = coins

    if IsItemOwned(flavorName) then
        print("[Autoprogress] already owns flavor -> " .. flavorName)
        SetLastFlavor(flavorName)
        return true
    end

    print("[Autoprogress] Flavor target -> " .. flavorName)

    if rootPart then
        rootPart.CFrame = CFrame.new(GUM_SHOP_POSITION)
        task.wait(0.35)
    end

    local previousFlavorIndex = GetFlavorIndexByName(flavorName)
    local previousFlavorName = previousFlavorIndex and previousFlavorIndex > 1 and AUTO_PROGRESS_LIST[previousFlavorIndex - 1].Name or nil
    if previousFlavorName then
        local equipSucceeded, equipName = TryServerCalls({"UpdateFlavor", "EquipFlavor", "SetFlavor"}, previousFlavorName)
        if equipSucceeded then
            print("[Autoprogress] equipped previous flavor before purchase -> " .. previousFlavorName .. " via " .. tostring(equipName))
            task.wait(0.35)
        end
    end

    local purchaseNames = {"GumShopPurchase", "BuyFlavor", "PurchaseFlavor", "BuyGum", "PurchaseGum"}
    local purchaseSucceeded, purchaseName = TryServerCalls(purchaseNames, flavorName)

    if purchaseSucceeded then
        print("[Autoprogress] PURCHASE SUCCESS -> " .. flavorName .. " via " .. tostring(purchaseName))
        SetLastFlavor(flavorName)
        task.wait(0.75)
        if rootPart and originalPosition then
            rootPart.CFrame = CFrame.new(originalPosition)
        end
        return true
    end

    local updateNames = {"UpdateFlavor", "EquipFlavor", "SetFlavor"}
    local updateSucceeded, updateName = TryServerCalls(updateNames, flavorName)
    if updateSucceeded then
        print("[Autoprogress] UPDATE SUCCESS -> " .. flavorName .. " via " .. tostring(updateName))
        SetLastFlavor(flavorName)
        task.wait(0.75)
        if rootPart and originalPosition then
            rootPart.CFrame = CFrame.new(originalPosition)
        end
        return true
    end

    if rootPart and originalPosition then
        rootPart.CFrame = CFrame.new(originalPosition)
    end

    print("[Autoprogress] Unable to update or purchase flavor -> " .. flavorName .. ". Waiting for enough coins.")
    return false
end

local function AttemptProgressStorage(storageName)
    if not storageName then
        return false
    end

    local storageInfo = GetStorageByName(storageName)
    if not storageInfo then
        return false
    end

    local coins = GetCoins()
    if not coins then
        print("[Autoprogress] no coin value available for storage " .. storageName)
        return false
    end

    if coins < storageInfo.Price then
        print("[Autoprogress] waiting for enough coins for storage " .. storageName .. " (" .. tostring(coins) .. "/" .. tostring(storageInfo.Price) .. ")")
        return false
    end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local originalPosition = rootPart and rootPart.Position or nil
    local beforeCoins = coins

    if IsItemOwned(storageName) then
        print("[Autoprogress] already owns storage -> " .. storageName)
        SetLastStorage(storageName)
        return true
    end

    print("[Autoprogress] Storage target -> " .. storageName)

    if rootPart then
        rootPart.CFrame = CFrame.new(GUM_SHOP_POSITION)
        task.wait(0.35)
    end

    local previousStorageIndex = GetStorageIndexByName(storageName)
    local previousStorageName = previousStorageIndex and previousStorageIndex > 1 and STORAGE_PROGRESS_LIST[previousStorageIndex - 1].Name or nil
    if previousStorageName then
        local equipSucceeded, equipName = TryServerCalls({"UpdateStorage", "EquipStorage", "SetStorage"}, previousStorageName)
        if equipSucceeded then
            print("[Autoprogress] equipped previous storage before purchase -> " .. previousStorageName .. " via " .. tostring(equipName))
            task.wait(0.35)
        end
    end

    local purchaseNames = {"GumShopPurchase", "BuyStorage", "PurchaseStorage", "BuyGum", "PurchaseGum"}
    local purchaseSucceeded, purchaseName = TryServerCalls(purchaseNames, storageName)

    if purchaseSucceeded then
        print("[Autoprogress] STORAGE PURCHASE SUCCESS -> " .. storageName .. " via " .. tostring(purchaseName))
        SetLastStorage(storageName)
        task.wait(0.75)
        if rootPart and originalPosition then
            rootPart.CFrame = CFrame.new(originalPosition)
        end
        return true
    end

    local updateNames = {"UpdateStorage", "EquipStorage", "SetStorage"}
    local updateSucceeded, updateName = TryServerCalls(updateNames, storageName)
    if updateSucceeded then
        print("[Autoprogress] STORAGE UPDATE SUCCESS -> " .. storageName .. " via " .. tostring(updateName))
        SetLastStorage(storageName)
        task.wait(0.75)
        if rootPart and originalPosition then
            rootPart.CFrame = CFrame.new(originalPosition)
        end
        return true
    end

    if rootPart and originalPosition then
        rootPart.CFrame = CFrame.new(originalPosition)
    end

    print("[Autoprogress] Unable to update or purchase storage -> " .. storageName .. ". Waiting for enough coins.")
    return false
end

local function FindAffordableFlavor(startIndex, coins)
    if not coins then
        return nil, nil
    end

    local start = math.max(1, startIndex or 1)
    if start > #AUTO_PROGRESS_LIST then
        return nil, nil
    end

    local targetFlavor = AUTO_PROGRESS_LIST[start]
    if targetFlavor and coins >= targetFlavor.MinCoins then
        return start, targetFlavor
    end

    return nil, nil
end

local function FindAffordableStorage(startIndex, coins)
    if not coins then
        return nil, nil
    end

    local start = math.max(1, startIndex or 1)
    if start > #STORAGE_PROGRESS_LIST then
        return nil, nil
    end

    local targetStorage = STORAGE_PROGRESS_LIST[start]
    if targetStorage and coins >= targetStorage.MinCoins then
        return start, targetStorage
    end

    return nil, nil
end

FarmTab:Toggle({
    Name = "Autoprogress",
    Default = false,
    Callback = function(enabled)
        autoprogressEnabled = enabled

        if enabled then
            autoprogressIndex = ResolveStartIndex()
            autoprogressStorageIndex = ResolveStorageStartIndex()
            autoprogressBuying = false

            if autoprogressLoop then
                return
            end

            autoprogressLoop = task.spawn(function()
                while autoprogressEnabled do
                    local coins = GetCoins()
                    if not coins then
                        print("[Autoprogress] unable to read coin value; waiting")
                        task.wait(1)
                    else
                        local didProgress = false

                        local storageIndex, storageTarget = FindAffordableStorage(autoprogressStorageIndex, coins)
                        local flavorIndex, flavorTarget = FindAffordableFlavor(autoprogressIndex, coins)

                        if storageTarget and flavorTarget then
                            autoprogressBuying = true
                            local success = AttemptProgressStorage(storageTarget.Name)
                            autoprogressBuying = false
                            if success then
                                autoprogressStorageIndex = math.max(storageIndex + 1, autoprogressStorageIndex)
                                didProgress = true
                                print("[Autoprogress] advanced storage target to " .. storageTarget.Name)
                                coins = GetCoins()
                                local nextFlavorIndex, nextFlavorTarget = FindAffordableFlavor(autoprogressIndex, coins or 0)
                                if coins and nextFlavorTarget then
                                    autoprogressBuying = true
                                    local flavorSuccess = AttemptProgressFlavor(nextFlavorTarget.Name)
                                    autoprogressBuying = false
                                    if flavorSuccess then
                                        autoprogressIndex = math.max(nextFlavorIndex + 1, autoprogressIndex)
                                        didProgress = true
                                        print("[Autoprogress] advanced flavor target to " .. nextFlavorTarget.Name)
                                    else
                                        print("[Autoprogress] still blocked on flavor " .. nextFlavorTarget.Name .. "; retrying when coins are available")
                                    end
                                end
                            else
                                print("[Autoprogress] still blocked on storage " .. storageTarget.Name .. "; retrying when coins are available")
                            end
                        elseif storageTarget then
                            autoprogressBuying = true
                            local success = AttemptProgressStorage(storageTarget.Name)
                            autoprogressBuying = false
                            if success then
                                autoprogressStorageIndex = math.max(storageIndex + 1, autoprogressStorageIndex)
                                didProgress = true
                                print("[Autoprogress] advanced storage target to " .. storageTarget.Name)
                            else
                                print("[Autoprogress] still blocked on storage " .. storageTarget.Name .. "; retrying when coins are available")
                            end
                        elseif flavorTarget then
                            autoprogressBuying = true
                            local success = AttemptProgressFlavor(flavorTarget.Name)
                            autoprogressBuying = false
                            if success then
                                autoprogressIndex = math.max(flavorIndex + 1, autoprogressIndex)
                                didProgress = true
                                print("[Autoprogress] advanced flavor target to " .. flavorTarget.Name)
                            else
                                print("[Autoprogress] still blocked on flavor " .. flavorTarget.Name .. "; retrying when coins are available")
                            end
                        end

                        if not didProgress then
                           
                            task.wait(1)
                        else
                            task.wait(0.5)
                        end
                    end
                end

                autoprogressLoop = nil
            end)
        else
            autoprogressEnabled = false
            autoprogressIndex = ResolveStartIndex()
            autoprogressStorageIndex = ResolveStorageStartIndex()
            autoprogressBuying = false

            if autoprogressLoop then
                task.cancel(autoprogressLoop)
                autoprogressLoop = nil
            end
        end
    end,
})



