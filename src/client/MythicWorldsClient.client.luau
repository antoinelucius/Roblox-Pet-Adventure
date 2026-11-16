-- MYTHIC WORLDS SIMULATOR - CLIENT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("MWS_Remotes")
local StateUpdate = remotes:WaitForChild("StateUpdate")
local BuyEgg = remotes:WaitForChild("BuyEgg")
local EquipPet = remotes:WaitForChild("EquipPet")
local EggInfo = remotes:WaitForChild("EggInfo")
local BattleStart = remotes:WaitForChild("BattleStart")
local BattleAction = remotes:WaitForChild("BattleAction")
local BattleUpdate = remotes:WaitForChild("BattleUpdate")
local RebirthRemote = remotes:WaitForChild("RebirthRemote")
local NPCInfo = remotes:WaitForChild("NPCInfo")
local BattleRequest = remotes:WaitForChild("BattleRequest")
local WorldInfoRemote = remotes:WaitForChild("WorldInfo")
local WorldTeleport = remotes:WaitForChild("WorldTeleport")
local BuySpeed = remotes:WaitForChild("BuySpeed")
local EquipBest = remotes:WaitForChild("EquipBest")

local state = { coins = 0, pets = {}, equipped = {}, defeatedNPCs = {}, rebirthLevel = 0 }
local incomePerSec = 0
local eggData = {}
local npcData = {}
local totalNPCs = 0
local rebirthInfo = { needed = 0, done = 0, cost = 0 }
local onRebirthInfo = nil -- rafraichit le bouton et le panneau Renaissance (defini plus bas)
-- ============================================================
-- HELPERS
-- ============================================================

-- Icones 3D des animaux : le modele en briques (MWS_PetBricks) affiche dans un ViewportFrame
local PetBricks = require(ReplicatedStorage:WaitForChild("MWS_PetBricks"))
local Traits = require(game:GetService("ReplicatedStorage"):WaitForChild("MWS_PetTraits"))
local petTemplates = {}
-- meme eclat que sur le serveur : les pets rares ont des couleurs plus vives
local RARITY_GLOW = { Epique = 0.1, Legendaire = 0.25, Mythique = 0.35, Divin = 0.45, Secret = 0.55 }

local function getPetTemplate(name, rarity, mutation)
    local key = name .. "|" .. tostring(rarity) .. "|" .. tostring(mutation)
    local cached = petTemplates[key]
    if cached ~= nil then return cached or nil end
    if not PetBricks.has(name) then petTemplates[key] = false return nil end
    local model = Instance.new("Model")
    local ok, _, info = pcall(PetBricks.assemble, name, { model = model, static = true, k = 1, bright = RARITY_GLOW[rarity] or 0 })
    if not ok or not info then petTemplates[key] = false return nil end
    Traits.paint(model, mutation)
    petTemplates[key] = model
    return model
end

local function newPetViewport(parent, z)
    local vp = Instance.new("ViewportFrame")
    vp.Size = UDim2.new(1, 0, 1, 0)
    vp.BackgroundTransparency = 1
    vp.Ambient = Color3.fromRGB(190, 190, 190)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(0.6, -1, 0.8)
    if z then vp.ZIndex = z end
    vp.Parent = parent
    return vp
end

-- Met l'animal 'name' dans le ViewportFrame. Renvoie false si l'animal n'a pas de modele.
local function setPetViewport(vp, name, rarity, mutation)
    local key = name and (name .. "|" .. tostring(rarity) .. "|" .. tostring(mutation))
    if key and vp:GetAttribute("Pet") == key and vp:FindFirstChildOfClass("Model") then
        vp.Visible = true
        return true
    end
    vp:ClearAllChildren()
    vp:SetAttribute("Pet", nil)
    local tpl = name and getPetTemplate(name, rarity, mutation)
    if not tpl then vp.Visible = false return false end
    local m = tpl:Clone()
    m.Parent = vp
    local cf, size = m:GetBoundingBox()
    local r = size.Magnitude / 2
    local cam = Instance.new("Camera")
    cam.FieldOfView = 35
    local dir = Vector3.new(-0.6, 0.35, -1).Unit -- vue de 3/4 avant (l'avant regarde vers -Z)
    local dist = r / math.sin(math.rad(cam.FieldOfView / 2)) * 0.82
    cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
    cam.Parent = vp
    vp.CurrentCamera = cam
    vp:SetAttribute("Pet", key)
    vp.Visible = true
    return true
end

local RARITY_COLORS = {
    Secret = Color3.fromRGB(255, 60, 200),
    Commun = Color3.fromRGB(180, 180, 180),
    Rare = Color3.fromRGB(80, 150, 255),
    Epique = Color3.fromRGB(170, 80, 255),
    Legendaire = Color3.fromRGB(255, 200, 50),
    Mythique = Color3.fromRGB(255, 80, 80),
    Divin = Color3.fromRGB(255, 50, 200)
}

local function colorFromData(c)
    if typeof(c) == "Color3" then return c end
    if typeof(c) == "table" then return Color3.fromRGB(c[1] or 255, c[2] or 255, c[3] or 255) end
    return Color3.fromRGB(150, 150, 150)
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- ============================================================
-- GUI
-- ============================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MWS_Gui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Barre coins + revenu
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 55)
topBar.Position = UDim2.new(0, 15, 0, 15)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
topBar.BackgroundTransparency = 0.15
makeCorner(topBar, 12)
topBar.Parent = gui

local coinIcon = Instance.new("TextLabel")
coinIcon.Size = UDim2.new(0, 40, 0, 40)
coinIcon.Position = UDim2.new(0, 5, 0, 8)
coinIcon.BackgroundTransparency = 1
coinIcon.Text = "\u{1F4B0}"
coinIcon.TextColor3 = Color3.fromRGB(255, 200, 50)
coinIcon.TextScaled = true
coinIcon.Font = Enum.Font.GothamBold
coinIcon.Parent = topBar

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -55, 0, 28)
coinLabel.Position = UDim2.new(0, 50, 0, 3)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "0 Coins"
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 18
coinLabel.Parent = topBar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Size = UDim2.new(1, -55, 0, 20)
incomeLabel.Position = UDim2.new(0, 50, 0, 31)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+0 /sec"
incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextSize = 14
incomeLabel.Parent = topBar

-- Rebirth label
local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Size = UDim2.new(0, 130, 0, 25)
rebirthLabel.Position = UDim2.new(0, 321, 0, 20)
rebirthLabel.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
rebirthLabel.BackgroundTransparency = 0.2
rebirthLabel.Text = "Renaissance: 0"
rebirthLabel.TextColor3 = Color3.fromRGB(255, 200, 255)
rebirthLabel.Font = Enum.Font.GothamBold
rebirthLabel.TextSize = 14
makeCorner(rebirthLabel, 8)
rebirthLabel.Parent = gui

-- Bouton Pets
local invButton = Instance.new("TextButton")
invButton.Size = UDim2.new(0, 120, 0, 45)
invButton.Position = UDim2.new(0, 15, 0, 80)
invButton.BackgroundColor3 = Color3.fromRGB(60, 50, 100)
invButton.Text = "\xF0\x9F\x90\xBE Pets"
invButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invButton.Font = Enum.Font.GothamBold
invButton.TextSize = 18
makeCorner(invButton, 10)
invButton.Parent = gui

-- Bouton Oeufs
local eggButton = Instance.new("TextButton")
eggButton.Size = UDim2.new(0, 120, 0, 45)
eggButton.Position = UDim2.new(0, 15, 0, 135)
eggButton.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
eggButton.Text = "\xF0\x9F\xA5\x9A Oeufs"
eggButton.TextColor3 = Color3.fromRGB(255, 255, 255)
eggButton.Font = Enum.Font.GothamBold
eggButton.TextSize = 18
makeCorner(eggButton, 10)
eggButton.Parent = gui

-- Bouton Combat
local combatButton = Instance.new("TextButton")
combatButton.Size = UDim2.new(0, 120, 0, 45)
combatButton.Position = UDim2.new(0, 15, 0, 190)
combatButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
combatButton.Text = "\xE2\x9A\x94 Combat"
combatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
combatButton.Font = Enum.Font.GothamBold
combatButton.TextSize = 18
makeCorner(combatButton, 10)
combatButton.Parent = gui

-- Bouton Renaissance
local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.new(0, 120, 0, 45)
rebirthButton.Position = UDim2.new(0, 15, 0, 245)
rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 40, 160)
rebirthButton.Text = "\xF0\x9F\x94\x84 Renaissance"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextSize = 16
makeCorner(rebirthButton, 10)
rebirthButton.Parent = gui

-- ============================================================
-- PET PANEL
-- ============================================================

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 420, 0, 380)
panel.Position = UDim2.new(0.5, -210, 0.5, -190)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.Visible = false
makeCorner(panel, 15)
panel.Parent = gui

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(0, 100, 0, 40)
panelTitle.Position = UDim2.new(0, 15, 0, 0)
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "Mes Pets"
panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 22
panelTitle.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -40, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
makeCorner(closeButton, 8)
closeButton.Parent = panel

-- bouton "Meilleurs" directement dans le menu des pets
local bestPetsBtn = Instance.new("TextButton")
bestPetsBtn.Size = UDim2.new(0, 130, 0, 35)
bestPetsBtn.Position = UDim2.new(1, -178, 0, 5)
bestPetsBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
bestPetsBtn.Text = "\u{2B50} Meilleurs"
bestPetsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bestPetsBtn.Font = Enum.Font.GothamBold
bestPetsBtn.TextSize = 15
makeCorner(bestPetsBtn, 8)
bestPetsBtn.Parent = panel
bestPetsBtn.MouseButton1Click:Connect(function() EquipBest:FireServer() end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -55)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 120, 0, 145)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
-- une grille par monde : voir refreshPanel
scrollFrame:SetAttribute("CellSize", grid.CellSize)
scrollFrame:SetAttribute("CellPadding", grid.CellPadding)
do
    local petSections = Instance.new("UIListLayout")
    petSections.Padding = UDim.new(0, 8)
    petSections.SortOrder = Enum.SortOrder.LayoutOrder
    petSections.Parent = scrollFrame
end
scrollFrame.Parent = panel

-- ============================================================
-- EGG PANEL
-- ============================================================

local eggPanel = Instance.new("Frame")
eggPanel.Size = UDim2.new(0, 600, 0, 480)
eggPanel.Position = UDim2.new(0.5, -300, 0.5, -240)
eggPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
eggPanel.Visible = false
makeCorner(eggPanel, 15)
eggPanel.Parent = gui

local eggPanelTitle = Instance.new("TextLabel")
eggPanelTitle.Size = UDim2.new(1, 0, 0, 40)
eggPanelTitle.BackgroundTransparency = 1
eggPanelTitle.Text = "\xF0\x9F\xA5\x9A Oeufs"
eggPanelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
eggPanelTitle.Font = Enum.Font.GothamBold
eggPanelTitle.TextSize = 22
eggPanelTitle.Parent = eggPanel

local eggCloseBtn = Instance.new("TextButton")
eggCloseBtn.Size = UDim2.new(0, 35, 0, 35)
eggCloseBtn.Position = UDim2.new(1, -40, 0, 5)
eggCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
eggCloseBtn.Text = "X"
eggCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eggCloseBtn.Font = Enum.Font.GothamBold
eggCloseBtn.TextSize = 18
makeCorner(eggCloseBtn, 8)
eggCloseBtn.Parent = eggPanel

local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Size = UDim2.new(1, -20, 1, -55)
eggScroll.Position = UDim2.new(0, 10, 0, 45)
eggScroll.BackgroundTransparency = 1
eggScroll.ScrollBarThickness = 6
eggScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
eggScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local eggList = Instance.new("UIListLayout")
eggList.Padding = UDim.new(0, 12)
eggList.Parent = eggScroll
eggScroll.Parent = eggPanel

-- ============================================================
-- COMBAT PANEL (NPC Progress)
-- ============================================================

local combatPanel = Instance.new("Frame")
combatPanel.Size = UDim2.new(0, 500, 0, 420)
combatPanel.Position = UDim2.new(0.5, -250, 0.5, -210)
combatPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
combatPanel.Visible = false
makeCorner(combatPanel, 15)
combatPanel.Parent = gui

local combatTitle = Instance.new("TextLabel")
combatTitle.Size = UDim2.new(1, 0, 0, 40)
combatTitle.BackgroundTransparency = 1
combatTitle.Text = "\xE2\x9A\x94 Combats"
combatTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
combatTitle.Font = Enum.Font.GothamBold
combatTitle.TextSize = 22
combatTitle.Parent = combatPanel

local combatCloseBtn = Instance.new("TextButton")
combatCloseBtn.Size = UDim2.new(0, 35, 0, 35)
combatCloseBtn.Position = UDim2.new(1, -40, 0, 5)
combatCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
combatCloseBtn.Text = "X"
combatCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
combatCloseBtn.Font = Enum.Font.GothamBold
combatCloseBtn.TextSize = 18
makeCorner(combatCloseBtn, 8)
combatCloseBtn.Parent = combatPanel

local combatScroll = Instance.new("ScrollingFrame")
combatScroll.Size = UDim2.new(1, -20, 1, -55)
combatScroll.Position = UDim2.new(0, 10, 0, 45)
combatScroll.BackgroundTransparency = 1
combatScroll.ScrollBarThickness = 6
combatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
combatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local combatListLayout = Instance.new("UIListLayout")
combatListLayout.Padding = UDim.new(0, 10)
combatListLayout.Parent = combatScroll
combatScroll.Parent = combatPanel

-- ============================================================
-- BATTLE UI
-- ============================================================

local battleFrame = Instance.new("Frame")
battleFrame.Size = UDim2.new(1, 0, 1, 0)
battleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
battleFrame.BackgroundTransparency = 0.3
battleFrame.Visible = false
battleFrame.ZIndex = 20
battleFrame.Parent = gui

local battlePanel = Instance.new("Frame")
battlePanel.Size = UDim2.new(0, 600, 0, 400)
battlePanel.Position = UDim2.new(0.5, -300, 0.5, -200)
battlePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
battlePanel.ZIndex = 21
makeCorner(battlePanel, 15)
battlePanel.Parent = battleFrame

-- Player pet display (left)
local playerPetFrame = Instance.new("Frame")
playerPetFrame.Size = UDim2.new(0, 260, 0, 140)
playerPetFrame.Position = UDim2.new(0, 15, 0, 15)
playerPetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
playerPetFrame.ZIndex = 22
makeCorner(playerPetFrame, 10)
playerPetFrame.Parent = battlePanel

local playerPetIcon = Instance.new("Frame")
playerPetIcon.Size = UDim2.new(0, 50, 0, 50)
playerPetIcon.Position = UDim2.new(0, 10, 0, 10)
playerPetIcon.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
playerPetIcon.ZIndex = 23
makeCorner(playerPetIcon, 6)
playerPetIcon.Parent = playerPetFrame

local playerPetImg = newPetViewport(playerPetIcon, 24)
playerPetImg.Visible = false

local playerPetName = Instance.new("TextLabel")
playerPetName.Size = UDim2.new(1, -70, 0, 25)
playerPetName.Position = UDim2.new(0, 65, 0, 10)
playerPetName.BackgroundTransparency = 1
playerPetName.Text = ""
playerPetName.TextColor3 = Color3.fromRGB(255, 255, 255)
playerPetName.Font = Enum.Font.GothamBold
playerPetName.TextSize = 16
playerPetName.TextXAlignment = Enum.TextXAlignment.Left
playerPetName.ZIndex = 23
playerPetName.Parent = playerPetFrame

local playerHpBarBg = Instance.new("Frame")
playerHpBarBg.Size = UDim2.new(1, -70, 0, 20)
playerHpBarBg.Position = UDim2.new(0, 65, 0, 40)
playerHpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerHpBarBg.ZIndex = 23
makeCorner(playerHpBarBg, 4)
playerHpBarBg.Parent = playerPetFrame

local playerHpBar = Instance.new("Frame")
playerHpBar.Size = UDim2.new(1, 0, 1, 0)
playerHpBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
playerHpBar.ZIndex = 24
makeCorner(playerHpBar, 4)
playerHpBar.Parent = playerHpBarBg

local playerHpText = Instance.new("TextLabel")
playerHpText.Size = UDim2.new(1, 0, 0, 20)
playerHpText.Position = UDim2.new(0, 65, 0, 65)
playerHpText.BackgroundTransparency = 1
playerHpText.Text = ""
playerHpText.TextColor3 = Color3.fromRGB(200, 255, 200)
playerHpText.Font = Enum.Font.GothamBold
playerHpText.TextSize = 14
playerHpText.TextXAlignment = Enum.TextXAlignment.Left
playerHpText.ZIndex = 23
playerHpText.Parent = playerPetFrame

local playerPetCount = Instance.new("TextLabel")
playerPetCount.Size = UDim2.new(1, -20, 0, 25)
playerPetCount.Position = UDim2.new(0, 10, 0, 100)
playerPetCount.BackgroundTransparency = 1
playerPetCount.Text = ""
playerPetCount.TextColor3 = Color3.fromRGB(180, 180, 180)
playerPetCount.Font = Enum.Font.GothamBold
playerPetCount.TextSize = 13
playerPetCount.ZIndex = 23
playerPetCount.Parent = playerPetFrame

-- NPC pet display (right)
local npcPetFrame = Instance.new("Frame")
npcPetFrame.Size = UDim2.new(0, 260, 0, 140)
npcPetFrame.Position = UDim2.new(1, -275, 0, 15)
npcPetFrame.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
npcPetFrame.ZIndex = 22
makeCorner(npcPetFrame, 10)
npcPetFrame.Parent = battlePanel

local npcPetIcon = Instance.new("Frame")
npcPetIcon.Size = UDim2.new(0, 50, 0, 50)
npcPetIcon.Position = UDim2.new(0, 10, 0, 10)
npcPetIcon.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
npcPetIcon.ZIndex = 23
makeCorner(npcPetIcon, 6)
npcPetIcon.Parent = npcPetFrame

local npcPetImg = newPetViewport(npcPetIcon, 24)
npcPetImg.Visible = false

local npcPetName = Instance.new("TextLabel")
npcPetName.Size = UDim2.new(1, -70, 0, 25)
npcPetName.Position = UDim2.new(0, 65, 0, 10)
npcPetName.BackgroundTransparency = 1
npcPetName.Text = ""
npcPetName.TextColor3 = Color3.fromRGB(255, 255, 255)
npcPetName.Font = Enum.Font.GothamBold
npcPetName.TextSize = 16
npcPetName.TextXAlignment = Enum.TextXAlignment.Left
npcPetName.ZIndex = 23
npcPetName.Parent = npcPetFrame

local npcHpBarBg = Instance.new("Frame")
npcHpBarBg.Size = UDim2.new(1, -70, 0, 20)
npcHpBarBg.Position = UDim2.new(0, 65, 0, 40)
npcHpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
npcHpBarBg.ZIndex = 23
makeCorner(npcHpBarBg, 4)
npcHpBarBg.Parent = npcPetFrame

local npcHpBar = Instance.new("Frame")
npcHpBar.Size = UDim2.new(1, 0, 1, 0)
npcHpBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
npcHpBar.ZIndex = 24
makeCorner(npcHpBar, 4)
npcHpBar.Parent = npcHpBarBg

local npcHpText = Instance.new("TextLabel")
npcHpText.Size = UDim2.new(1, 0, 0, 20)
npcHpText.Position = UDim2.new(0, 65, 0, 65)
npcHpText.BackgroundTransparency = 1
npcHpText.Text = ""
npcHpText.TextColor3 = Color3.fromRGB(255, 200, 200)
npcHpText.Font = Enum.Font.GothamBold
npcHpText.TextSize = 14
npcHpText.TextXAlignment = Enum.TextXAlignment.Left
npcHpText.ZIndex = 23
npcHpText.Parent = npcPetFrame

local npcPetCount = Instance.new("TextLabel")
npcPetCount.Size = UDim2.new(1, -20, 0, 25)
npcPetCount.Position = UDim2.new(0, 10, 0, 100)
npcPetCount.BackgroundTransparency = 1
npcPetCount.Text = ""
npcPetCount.TextColor3 = Color3.fromRGB(180, 180, 180)
npcPetCount.Font = Enum.Font.GothamBold
npcPetCount.TextSize = 13
npcPetCount.ZIndex = 23
npcPetCount.Parent = npcPetFrame

-- Battle log
local battleLog = Instance.new("TextLabel")
battleLog.Size = UDim2.new(1, -30, 0, 80)
battleLog.Position = UDim2.new(0, 15, 0, 170)
battleLog.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
battleLog.Text = ""
battleLog.TextColor3 = Color3.fromRGB(255, 255, 255)
battleLog.Font = Enum.Font.GothamBold
battleLog.TextSize = 16
battleLog.TextWrapped = true
battleLog.ZIndex = 22
makeCorner(battleLog, 8)
battleLog.Parent = battlePanel

-- Charge bar
local chargeBarBg = Instance.new("Frame")
chargeBarBg.Size = UDim2.new(0, 360, 0, 22)
chargeBarBg.Position = UDim2.new(0.5, -180, 0, 260)
chargeBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
chargeBarBg.ZIndex = 22
makeCorner(chargeBarBg, 6)
chargeBarBg.Parent = battlePanel

local chargeBar = Instance.new("Frame")
chargeBar.Size = UDim2.new(0, 0, 1, 0)
chargeBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
chargeBar.ZIndex = 23
makeCorner(chargeBar, 6)
chargeBar.Parent = chargeBarBg

local chargeText = Instance.new("TextLabel")
chargeText.Size = UDim2.new(1, 0, 1, 0)
chargeText.BackgroundTransparency = 1
chargeText.Text = "Charge: 0%"
chargeText.TextColor3 = Color3.fromRGB(255, 255, 255)
chargeText.Font = Enum.Font.GothamBold
chargeText.TextSize = 14
chargeText.ZIndex = 24
chargeText.Parent = chargeBarBg

-- Bouton Attaque de base
local attackBtn = Instance.new("TextButton")
attackBtn.Size = UDim2.new(0, 110, 0, 50)
attackBtn.Position = UDim2.new(0.5, -245, 0, 290)
attackBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
attackBtn.Text = "\xE2\x9A\x94 Attaquer"
attackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
attackBtn.Font = Enum.Font.GothamBold
attackBtn.TextSize = 15
attackBtn.ZIndex = 22
makeCorner(attackBtn, 10)
attackBtn.Parent = battlePanel

-- Bouton Special 1: Lame de Feu (50% charge, x2 dmg)
local special1Btn = Instance.new("TextButton")
special1Btn.Size = UDim2.new(0, 110, 0, 50)
special1Btn.Position = UDim2.new(0.5, -130, 0, 290)
special1Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
special1Btn.Text = "\xF0\x9F\x94\xA5 Lame de Feu"
special1Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
special1Btn.Font = Enum.Font.GothamBold
special1Btn.TextSize = 13
special1Btn.ZIndex = 22
makeCorner(special1Btn, 10)
special1Btn.Parent = battlePanel

-- Bouton Special 2: Tempete Glace (75% charge, x3 dmg)
local special2Btn = Instance.new("TextButton")
special2Btn.Size = UDim2.new(0, 110, 0, 50)
special2Btn.Position = UDim2.new(0.5, -15, 0, 290)
special2Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
special2Btn.Text = "\xE2\x9D\x84\xEF\xB8\x8F Tempete Glace"
special2Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
special2Btn.Font = Enum.Font.GothamBold
special2Btn.TextSize = 13
special2Btn.ZIndex = 22
makeCorner(special2Btn, 10)
special2Btn.Parent = battlePanel

-- Bouton Special 3: Frappe Divine (100% charge, x5 dmg)
local special3Btn = Instance.new("TextButton")
special3Btn.Size = UDim2.new(0, 110, 0, 50)
special3Btn.Position = UDim2.new(0.5, 100, 0, 290)
special3Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
special3Btn.Text = "\xE2\x9C\xA8 Frappe Divine"
special3Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
special3Btn.Font = Enum.Font.GothamBold
special3Btn.TextSize = 13
special3Btn.ZIndex = 22
makeCorner(special3Btn, 10)
special3Btn.Parent = battlePanel

-- Bouton Changer de pet
local switchBtn = Instance.new("TextButton")
switchBtn.Size = UDim2.new(0, 110, 0, 50)
switchBtn.Position = UDim2.new(0.5, 215, 0, 290)
switchBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
switchBtn.Text = "\xF0\x9F\x94\x84 Changer"
switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
switchBtn.Font = Enum.Font.GothamBold
switchBtn.TextSize = 15
switchBtn.ZIndex = 22
makeCorner(switchBtn, 10)
switchBtn.Parent = battlePanel

-- Bouton Super (ancien, garde pour compat)
local superBtn = Instance.new("TextButton")
superBtn.Size = UDim2.new(0, 0, 0, 0)
superBtn.Visible = false
superBtn.ZIndex = 22
superBtn.Parent = battlePanel

-- Bouton Fuir
local fleeBtn = Instance.new("TextButton")
fleeBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
fleeBtn.Text = "\xF0\x9F\x8F\x83 Fuir"
fleeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fleeBtn.Font = Enum.Font.GothamBold
fleeBtn.TextSize = 15
fleeBtn.ZIndex = 22
makeCorner(fleeBtn, 10)
fleeBtn.Parent = battlePanel


-- Battle result label
local battleResult = Instance.new("TextLabel")
battleResult.Size = UDim2.new(1, 0, 0, 60)
battleResult.Position = UDim2.new(0, 0, 0, 330)
battleResult.BackgroundTransparency = 1
battleResult.Text = ""
battleResult.TextColor3 = Color3.fromRGB(255, 255, 255)
battleResult.Font = Enum.Font.GothamBlack
battleResult.TextSize = 26
battleResult.ZIndex = 25
battleResult.Parent = battlePanel

-- Disposition epuree : plus de grand cadre, on voit le combat 3D.
-- Deux petites cartes en haut (pet du joueur / pet adverse), message et boutons en bas.
battleFrame.BackgroundTransparency = 1
battlePanel.BackgroundTransparency = 1
battlePanel.Size = UDim2.new(1, 0, 1, 0)
battlePanel.Position = UDim2.new(0, 0, 0, 0)
for _, f in ipairs({ playerPetFrame, npcPetFrame }) do
    f.Size = UDim2.new(0, 250, 0, 72)
    f.BackgroundTransparency = 0.35
end
playerPetFrame.Position = UDim2.new(0.5, -260, 0, 60)
npcPetFrame.Position = UDim2.new(0.5, 10, 0, 60)
for _, ic in ipairs({ playerPetIcon, npcPetIcon }) do ic.Position = UDim2.new(0, 8, 0, 11) end
for _, l in ipairs({ playerPetName, npcPetName }) do
    l.Position = UDim2.new(0, 66, 0, 4)
    l.Size = UDim2.new(1, -74, 0, 22)
    l.TextSize = 15
end
for _, bgb in ipairs({ playerHpBarBg, npcHpBarBg }) do
    bgb.Position = UDim2.new(0, 66, 0, 28)
    bgb.Size = UDim2.new(1, -76, 0, 14)
end
for _, t in ipairs({ playerHpText, npcHpText }) do
    t.Position = UDim2.new(0, 66, 0, 46)
    t.Size = UDim2.new(0.5, -30, 0, 18)
    t.TextSize = 12
end
for _, c in ipairs({ playerPetCount, npcPetCount }) do
    c.Position = UDim2.new(1, -90, 0, 46)
    c.Size = UDim2.new(0, 82, 0, 18)
    c.TextSize = 12
    c.TextXAlignment = Enum.TextXAlignment.Right
end
battleLog.BackgroundTransparency = 1
battleLog.Size = UDim2.new(0, 640, 0, 36)
battleLog.Position = UDim2.new(0.5, -320, 1, -128)
battleLog.TextSize = 15
battleLog.TextStrokeTransparency = 0.35
chargeBarBg.Size = UDim2.new(0, 360, 0, 14)
chargeBarBg.Position = UDim2.new(0.5, -180, 1, -88)
chargeText.TextSize = 11
-- Proteger : encaisse moins sur la prochaine attaque ennemie
local guardBtn = Instance.new("TextButton")
guardBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 200)
guardBtn.Text = "\u{1F6E1} Protéger"
guardBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
guardBtn.Font = Enum.Font.GothamBold
guardBtn.TextSize = 13
guardBtn.ZIndex = 22
guardBtn.Visible = false
makeCorner(guardBtn, 10)
guardBtn.Parent = battlePanel
-- ce que le joueur doit surveiller : super attaque, bouclier, surchauffe
local battleStatus = Instance.new("TextLabel")
battleStatus.BackgroundTransparency = 1
battleStatus.Size = UDim2.new(0, 640, 0, 26)
battleStatus.Position = UDim2.new(0.5, -320, 1, -162)
battleStatus.Font = Enum.Font.GothamBlack
battleStatus.TextSize = 17
battleStatus.TextColor3 = Color3.fromRGB(255, 210, 90)
battleStatus.TextStrokeTransparency = 0.3
battleStatus.Text = ""
battleStatus.ZIndex = 22
battleStatus.Parent = battlePanel
for i, btn in ipairs({ attackBtn, guardBtn, special1Btn, special2Btn, special3Btn, switchBtn, fleeBtn }) do
    btn.Size = UDim2.new(0, 92, 0, 44)
    btn.Position = UDim2.new(0.5, -340 + (i - 1) * 98, 1, -64)
end
special1Btn.Text = "\u{1F4A5} Coup charge"
special2Btn.Text = "\u{26A1} Assaut"
special3Btn.Text = "\u{1F31F} Ultime"
battleResult.Position = UDim2.new(0, 0, 0.3, 0)
battleResult.TextStrokeTransparency = 0.3

-- ============================================================
-- HATCH FRAME
-- ============================================================

local hatchFrame = Instance.new("Frame")
hatchFrame.Size = UDim2.new(1, 0, 1, 0)
hatchFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hatchFrame.BackgroundTransparency = 1
hatchFrame.Visible = false
hatchFrame.ZIndex = 10
hatchFrame.Parent = gui

local hatchLabel = Instance.new("TextLabel")
hatchLabel.Size = UDim2.new(0, 500, 0, 100)
hatchLabel.Position = UDim2.new(0.5, -250, 0.5, -100)
hatchLabel.BackgroundTransparency = 1
hatchLabel.Text = ""
hatchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hatchLabel.Font = Enum.Font.GothamBlack
hatchLabel.TextSize = 30
hatchLabel.ZIndex = 11
hatchLabel.Parent = hatchFrame

local hatchBox = Instance.new("Frame")
hatchBox.Size = UDim2.new(0, 220, 0, 160)
hatchBox.Position = UDim2.new(0.5, -110, 0.5, -270)
hatchBox.BackgroundTransparency = 1
hatchBox.ZIndex = 11
hatchBox.Parent = hatchFrame
local hatchImage = newPetViewport(hatchBox, 11)
hatchImage.Visible = false

-- ============================================================
-- PET PANEL LOGIC
-- ============================================================

local function refreshPanel()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end

    -- classement : monde d'origine (premier oeuf qui donne ce pet), puis rarete, du plus rare au moins rare
    local petWorld = {}
    for _, egg in ipairs(eggData) do
        for _, entry in ipairs(egg.pool or {}) do
            petWorld[entry.name] = math.min(petWorld[entry.name] or 99, egg.world or 99)
        end
    end
    local rarityRank = { Commun = 1, Rare = 2, Epique = 3, Legendaire = 4, Mythique = 5, Divin = 6, Secret = 7 }
    local sortedPets = table.clone(state.pets)
    table.sort(sortedPets, function(a, b)
        local wa, wb = petWorld[a.name] or 99, petWorld[b.name] or 99
        if wa ~= wb then return wa < wb end
        local ra, rb = rarityRank[a.rarity] or 0, rarityRank[b.rarity] or 0
        if ra ~= rb then return ra > rb end
        if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) > (b.tier or 0) end
        if (a.income or 0) ~= (b.income or 0) then return (a.income or 0) > (b.income or 0) end
        return (a.id or 0) < (b.id or 0)
    end)

    local sectionWorld, sectionGroup, sectionCount = nil, nil, 0
    for cardIndex, pet in ipairs(sortedPets) do
        local world = petWorld[pet.name] or 99
        if world ~= sectionWorld then
            sectionWorld = world
            sectionCount = sectionCount + 1
            local header = Instance.new("TextLabel")
            header.LayoutOrder = sectionCount * 2
            header.Size = UDim2.new(1, -10, 0, 30)
            header.BackgroundTransparency = 1
            header.Text = (world == 99) and "— AUTRES PETS —" or ("— MONDE " .. world .. " —")
            header.TextColor3 = Color3.fromRGB(255, 225, 120)
            header.Font = Enum.Font.FredokaOne
            header.TextSize = 22
            header.TextStrokeTransparency = 0.5
            header.Parent = scrollFrame
            sectionGroup = Instance.new("Frame")
            sectionGroup.LayoutOrder = sectionCount * 2 + 1
            sectionGroup.Size = UDim2.new(1, -10, 0, 0)
            sectionGroup.AutomaticSize = Enum.AutomaticSize.Y
            sectionGroup.BackgroundTransparency = 1
            sectionGroup.Parent = scrollFrame
            local sectionGrid = Instance.new("UIGridLayout")
            sectionGrid.CellSize = scrollFrame:GetAttribute("CellSize")
            sectionGrid.CellPadding = scrollFrame:GetAttribute("CellPadding")
            sectionGrid.SortOrder = Enum.SortOrder.LayoutOrder
            sectionGrid.Parent = sectionGroup
        end
        local card = Instance.new("Frame")
        card.LayoutOrder = cardIndex
        card.Name = "PetCard" .. tostring(pet.id)
        -- carte sombre : la rarete est le contour de l'image, la fusion la couleur du nom
        local rarityColor = RARITY_COLORS[pet.rarity] or Color3.fromRGB(100, 100, 100)
        card.BackgroundColor3 = Color3.fromRGB(38, 38, 54)
        makeCorner(card, 8)
        if Traits.accent(pet) then
            -- taille ou mutation : fin contour de la carte, de la couleur de la mutation
            local ms = Instance.new("UIStroke")
            ms.Color = Traits.accent(pet)
            ms.Thickness = 2
            ms.Parent = card
        end

        local petIcon = Instance.new("Frame")
        petIcon.Size = UDim2.new(1, -12, 0, 53)
        petIcon.Position = UDim2.new(0, 6, 0, 6)
        petIcon.BackgroundColor3 = colorFromData(pet.color)
        makeCorner(petIcon, 6)
        petIcon.Parent = card
        local rarityStroke = Instance.new("UIStroke")
        rarityStroke.Color = rarityColor
        rarityStroke.Thickness = 3
        rarityStroke.Parent = petIcon
        setPetViewport(newPetViewport(petIcon), pet.name, pet.rarity, pet.mutation)

        -- nom court : seulement le nom du pet ; une couleur par niveau de fusion
        local petName = Instance.new("TextLabel")
        petName.Size = UDim2.new(1, -8, 0, 20)
        petName.Position = UDim2.new(0, 4, 0, 62)
        petName.BackgroundTransparency = 1
        petName.Text = pet.name
        petName.TextScaled = true
        petName.TextColor3 = Traits.fusionColor(pet) or Color3.fromRGB(255, 255, 255)
        petName.Font = Enum.Font.GothamBold
        petName.TextSize = 14
        petName.Parent = card
        local nameLimit = Instance.new("UITextSizeConstraint")
        nameLimit.MaxTextSize = 14
        nameLimit.Parent = petName

        -- taille ou mutation si le pet en a, sinon le nom de la rarete
        local petInfo = Instance.new("TextLabel")
        petInfo.Size = UDim2.new(1, -8, 0, 14)
        petInfo.Position = UDim2.new(0, 4, 0, 80)
        petInfo.BackgroundTransparency = 1
        petInfo.Text = Traits.tag(pet) ~= "" and Traits.tag(pet) or pet.rarity
        petInfo.TextColor3 = Traits.accent(pet) or rarityColor
        petInfo.TextScaled = true
        petInfo.Font = Enum.Font.Gotham
        petInfo.TextSize = 11
        petInfo.Parent = card
        local infoLimit = Instance.new("UITextSizeConstraint")
        infoLimit.MaxTextSize = 11
        infoLimit.Parent = petInfo

        local incomeText = Instance.new("TextLabel")
        incomeText.Size = UDim2.new(1, 0, 0, 16)
        incomeText.Position = UDim2.new(0, 0, 0, 94)
        incomeText.BackgroundTransparency = 1
        incomeText.Text = ((pet.lvl or 0) > 0 and ("Nv" .. pet.lvl .. "  ") or "") .. "+" .. tostring(math.floor((pet.income or 0) * (1 + 0.1 * (pet.lvl or 0)))) .. "/s"
        incomeText.TextColor3 = Color3.fromRGB(100, 255, 100)
        incomeText.Font = Enum.Font.GothamBold
        incomeText.TextSize = 12
        incomeText.Parent = card

        local equipBtn = Instance.new("TextButton")
        equipBtn.Size = UDim2.new(1, -10, 0, 25)
        equipBtn.Position = UDim2.new(0, 5, 1, -30)
        equipBtn.Font = Enum.Font.GothamBold
        equipBtn.TextSize = 13
        equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        makeCorner(equipBtn, 6)
        equipBtn.Parent = card

        local isEquipped = false
        for _, id in ipairs(state.equipped) do
            if id == pet.id then isEquipped = true break end
        end

        if isEquipped then
            equipBtn.Text = "Retirer"
            equipBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        else
            equipBtn.Text = "Equiper"
            equipBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
        end

        equipBtn.MouseButton1Click:Connect(function()
            EquipPet:FireServer(pet.id)
        end)

        card.Parent = sectionGroup
    end
end

-- ============================================================
-- EGG PANEL LOGIC
-- ============================================================

local function refreshEggPanel()
    for _, child in ipairs(eggScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, egg in ipairs(eggData) do
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, 0, 0, 210)
        section.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        section.AutomaticSize = Enum.AutomaticSize.Y
        makeCorner(section, 12)
        section.Parent = eggScroll

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 50)
        header.BackgroundColor3 = colorFromData(egg.color)
        header.BackgroundTransparency = 0.2
        makeCorner(header, 10)
        header.Parent = section

        local eggTitle = Instance.new("TextLabel")
        eggTitle.Size = UDim2.new(1, -20, 1, 0)
        eggTitle.Position = UDim2.new(0, 10, 0, 0)
        eggTitle.BackgroundTransparency = 1
        eggTitle.Text = egg.name .. "  -  " .. egg.price .. " Coins"
        eggTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        eggTitle.Font = Enum.Font.GothamBold
        eggTitle.TextSize = 18
        eggTitle.TextXAlignment = Enum.TextXAlignment.Left
        eggTitle.Parent = header

        local petList = Instance.new("Frame")
        petList.Size = UDim2.new(1, 0, 0, 0)
        petList.Position = UDim2.new(0, 0, 0, 58)
        petList.BackgroundTransparency = 1
        petList.AutomaticSize = Enum.AutomaticSize.Y
        local petGrid = Instance.new("UIGridLayout")
        petGrid.CellSize = UDim2.new(0.333, -8, 0, 168)
        petGrid.CellPadding = UDim2.new(0, 8, 0, 8)
        petGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        petGrid.SortOrder = Enum.SortOrder.LayoutOrder
        petGrid.Parent = petList
        local petPad = Instance.new("UIPadding")
        petPad.PaddingBottom = UDim.new(0, 10)
        petPad.PaddingLeft = UDim.new(0, 6)
        petPad.PaddingRight = UDim.new(0, 6)
        petPad.Parent = petList
        petList.Parent = section

        for idx, petInfo in ipairs(egg.pool) do
            -- possede deja cet animal ?
            local owned = false
            for _, ownedPet in ipairs(state.pets) do
                if ownedPet.name == petInfo.name then owned = true break end
            end

            local rc = RARITY_COLORS[petInfo.rarity] or Color3.fromRGB(255, 255, 255)
            local card = Instance.new("Frame")
            card.LayoutOrder = idx
            card.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
            makeCorner(card, 10)
            local stroke = Instance.new("UIStroke")
            stroke.Color = rc
            stroke.Thickness = 1.5
            stroke.Transparency = owned and 0.1 or 0.55
            stroke.Parent = card
            card.Parent = petList

            local imgFrame = Instance.new("Frame")
            imgFrame.Size = UDim2.new(1, -12, 0, 92)
            imgFrame.Position = UDim2.new(0, 6, 0, 6)
            imgFrame.BackgroundColor3 = colorFromData(petInfo.color):Lerp(Color3.new(0, 0, 0), 0.55)
            makeCorner(imgFrame, 8)
            imgFrame.Parent = card

            local petImage = newPetViewport(imgFrame)
            petImage.Name = "PetImage"
            petImage.Size = UDim2.new(1, -8, 1, -8)
            petImage.Position = UDim2.new(0, 4, 0, 4)
            if not setPetViewport(petImage, petInfo.name, petInfo.rarity) then
                petImage.Visible = true
                petImage.BackgroundTransparency = 0
                petImage.BackgroundColor3 = colorFromData(petInfo.color)
                makeCorner(petImage, 8)
                if not owned then petImage.BackgroundColor3 = petImage.BackgroundColor3:Lerp(Color3.new(0, 0, 0), 0.7) end
            end

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -8, 0, 32)
            nameLabel.Position = UDim2.new(0, 4, 0, 100)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petInfo.name
            nameLabel.TextColor3 = rc
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.TextWrapped = true
            nameLabel.Parent = card

            local statLbl = Instance.new("TextLabel")
            statLbl.Size = UDim2.new(1, -8, 0, 16)
            statLbl.Position = UDim2.new(0, 4, 0, 132)
            statLbl.BackgroundTransparency = 1
            statLbl.Text = "+" .. tostring(petInfo.income) .. "/s"
            statLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            statLbl.Font = Enum.Font.GothamBold
            statLbl.TextSize = 12
            statLbl.Parent = card

            local chanceLbl = Instance.new("TextLabel")
            chanceLbl.Size = UDim2.new(1, -8, 0, 16)
            chanceLbl.Position = UDim2.new(0, 4, 0, 148)
            chanceLbl.BackgroundTransparency = 1
            chanceLbl.Text = tostring(petInfo.chance) .. "%"
            chanceLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
            chanceLbl.Font = Enum.Font.GothamBold
            chanceLbl.TextSize = 12
            chanceLbl.Parent = card
        end
    end
end

-- ============================================================
-- ONGLETS TAILLES / MUTATIONS (a gauche du menu Oeufs)
-- Chaque onglet ouvre un menu avec tous les pets dans cette version.
-- ============================================================

local traitPanel = Instance.new("Frame")
traitPanel.Size = eggPanel.Size
traitPanel.Position = eggPanel.Position
traitPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
traitPanel.Visible = false
makeCorner(traitPanel, 15)
traitPanel.Parent = gui

local traitTitle = Instance.new("TextLabel")
traitTitle.Size = UDim2.new(1, -100, 0, 40)
traitTitle.Position = UDim2.new(0, 50, 0, 0)
traitTitle.BackgroundTransparency = 1
traitTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
traitTitle.Font = Enum.Font.GothamBold
traitTitle.TextSize = 22
traitTitle.Parent = traitPanel

local traitSub = Instance.new("TextLabel")
traitSub.Size = UDim2.new(1, -20, 0, 18)
traitSub.Position = UDim2.new(0, 10, 0, 38)
traitSub.BackgroundTransparency = 1
traitSub.TextColor3 = Color3.fromRGB(200, 200, 215)
traitSub.Font = Enum.Font.Gotham
traitSub.TextSize = 13
traitSub.Parent = traitPanel

local traitClose = Instance.new("TextButton")
traitClose.Size = UDim2.new(0, 35, 0, 35)
traitClose.Position = UDim2.new(1, -40, 0, 5)
traitClose.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
traitClose.Text = "X"
traitClose.TextColor3 = Color3.fromRGB(255, 255, 255)
traitClose.Font = Enum.Font.GothamBold
traitClose.TextSize = 18
makeCorner(traitClose, 8)
traitClose.Parent = traitPanel

local traitScroll = Instance.new("ScrollingFrame")
traitScroll.Size = UDim2.new(1, -20, 1, -70)
traitScroll.Position = UDim2.new(0, 10, 0, 62)
traitScroll.BackgroundTransparency = 1
traitScroll.ScrollBarThickness = 6
traitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
traitScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local traitGrid = Instance.new("UIGridLayout")
traitGrid.CellSize = UDim2.new(0.333, -8, 0, 172)
traitGrid.CellPadding = UDim2.new(0, 8, 0, 8)
traitGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
traitGrid.SortOrder = Enum.SortOrder.LayoutOrder
traitGrid.Parent = traitScroll
traitScroll.Parent = traitPanel

-- colonne d'onglets
local traitTabs = Instance.new("Frame")
traitTabs.Size = UDim2.new(0, 120, 0, 480)
traitTabs.Position = UDim2.new(0.5, -430, 0.5, -240)
traitTabs.BackgroundTransparency = 1
traitTabs.Visible = false
traitTabs.Parent = gui
-- noms lus par MWS_MobileHud : les panneaux d'oeufs et leur colonne d'onglets vont ensemble
eggPanel.Name = "MWS_EggPanel"
traitPanel.Name = "MWS_TraitPanel"
traitTabs.Name = "MWS_SideTabs"
local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 6)
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Parent = traitTabs

local function fmtBig(n)
    n = math.floor(n or 0)
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e4 then return string.format("%.1fK", n / 1e3) end
    return tostring(n)
end

local currentTrait = nil -- { kind = "size"|"mutation", def = ... }
local tabButtons = {}

local function refreshTraitPanel()
    for _, c in ipairs(traitScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    if not currentTrait then return end
    local def, kind = currentTrait.def, currentTrait.kind
    local accent = def.color or Color3.fromRGB(255, 235, 150)
    traitTitle.Text = def.label
    traitTitle.TextColor3 = Color3.new(1, 1, 1):Lerp(accent, 0.5)
    traitSub.Text = def.chance .. "% de chance  ·  gains x" .. def.mult .. (kind == "size" and ("  ·  taille x" .. def.scale) or "")
    -- pets uniques de tous les oeufs, dans l'ordre des oeufs
    local seen, order = {}, 0
    for _, egg in ipairs(eggData or {}) do
        for _, petInfo in ipairs(egg.pool or {}) do
            if not seen[petInfo.name] then
                seen[petInfo.name] = true
                order += 1
                local fake = { name = petInfo.name, tier = 0 }
                if kind == "size" then fake.size = def.key else fake.mutation = def.key end
                local owned = 0
                for _, p in ipairs(state.pets or {}) do
                    if p.name == petInfo.name and ((kind == "size" and p.size == def.key) or (kind == "mutation" and p.mutation == def.key)) then
                        owned += 1
                    end
                end
                local rc = RARITY_COLORS[petInfo.rarity] or Color3.fromRGB(255, 255, 255)
                local card = Instance.new("Frame")
                card.LayoutOrder = order
                card.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
                makeCorner(card, 10)
                local st = Instance.new("UIStroke")
                st.Color = accent
                st.Thickness = owned > 0 and 2.5 or 1.2
                st.Transparency = owned > 0 and 0 or 0.5
                st.Parent = card
                card.Parent = traitScroll

                local imgFrame = Instance.new("Frame")
                imgFrame.Size = UDim2.new(1, -12, 0, 92)
                imgFrame.Position = UDim2.new(0, 6, 0, 6)
                imgFrame.BackgroundColor3 = accent:Lerp(Color3.new(0, 0, 0), 0.7)
                makeCorner(imgFrame, 8)
                imgFrame.Parent = card
                local vp = newPetViewport(imgFrame)
                vp.Size = UDim2.new(1, -8, 1, -8)
                vp.Position = UDim2.new(0, 4, 0, 4)
                setPetViewport(vp, petInfo.name, petInfo.rarity, fake.mutation)

                local function lbl(y, h, text, col, size)
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, -8, 0, h)
                    l.Position = UDim2.new(0, 4, 0, y)
                    l.BackgroundTransparency = 1
                    l.Text = text
                    l.TextColor3 = col
                    l.Font = Enum.Font.GothamBold
                    l.TextSize = size
                    l.TextWrapped = true
                    l.Parent = card
                    return l
                end
                lbl(100, 30, Traits.fullName(fake), rc, 13)
                lbl(130, 14, "+" .. fmtBig((petInfo.income or 0) * def.mult) .. "/s", Color3.fromRGB(100, 255, 100), 12)
                local ch = (petInfo.chance or 0) * def.chance / 100
                lbl(144, 13, egg.name .. " : " .. (ch >= 1 and string.format("%.1f", ch) or (ch >= 0.01 and string.format("%.2f", ch) or string.format("%.3f", ch))) .. "%", Color3.fromRGB(255, 220, 100), 11)
                lbl(157, 13, owned > 0 and ("Possede x" .. owned) or "Pas encore", owned > 0 and accent or Color3.fromRGB(150, 150, 165), 11)
            end
        end
    end
end

local function selectTab(entry)
    for _, b in pairs(tabButtons) do
        b.btn.BackgroundTransparency = (b == entry) and 0 or 0.1
        b.stroke.Thickness = (b == entry) and 2.5 or 0
    end
    if entry.kind == "eggs" then
        currentTrait = nil
        traitPanel.Visible = false
        eggPanel.Visible = true
        refreshEggPanel()
    else
        currentTrait = { kind = entry.kind, def = entry.def }
        eggPanel.Visible = false
        traitPanel.Visible = true
        refreshTraitPanel()
    end
end

local function addTab(order, text, color, kind, def)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 52)
    b.BackgroundColor3 = color:Lerp(Color3.fromRGB(25, 25, 35), 0.45)
    b.BackgroundTransparency = 0.1
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.TextWrapped = true
    makeCorner(b, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = b
    b.Parent = traitTabs
    local entry = { btn = b, stroke = stroke, kind = kind, def = def }
    table.insert(tabButtons, entry)
    b.MouseButton1Click:Connect(function() selectTab(entry) end)
    return entry
end

local eggsTab = addTab(0, "Oeufs", Color3.fromRGB(180, 120, 255), "eggs")
local sizeOrder = { "Grand", "Geant", "Titan" }
for k, key in ipairs(sizeOrder) do
    local d = Traits.SIZE[key]
    addTab(k, d.label, Color3.fromRGB(255, 225, 140), "size", d)
end
local mutOrder = { "Dore", "Cristal", "Ombre", "ArcEnCiel" }
for k, key in ipairs(mutOrder) do
    local d = Traits.MUTATION[key]
    addTab(10 + k, d.label, d.color, "mutation", d)
end

local function syncTabs()
    traitTabs.Visible = eggPanel.Visible or traitPanel.Visible
    if eggPanel.Visible and not traitPanel.Visible then
        for _, b in pairs(tabButtons) do
            b.btn.BackgroundTransparency = (b == eggsTab) and 0 or 0.1
            b.stroke.Thickness = (b == eggsTab) and 2.5 or 0
        end
    end
end
eggPanel:GetPropertyChangedSignal("Visible"):Connect(syncTabs)
traitPanel:GetPropertyChangedSignal("Visible"):Connect(syncTabs)
traitClose.MouseButton1Click:Connect(function() traitPanel.Visible = false end)
-- le bouton Oeufs ferme le menu des mutations ; un autre menu qui s'ouvre aussi
eggButton.MouseButton1Click:Connect(function()
    if traitPanel.Visible then
        traitPanel.Visible = false
        eggPanel.Visible = false
    end
end)
for _, f in ipairs(gui:GetChildren()) do
    if f:IsA("Frame") and f ~= eggPanel and f ~= traitPanel and f ~= traitTabs and f.Size.X.Offset >= 300 then
        f:GetPropertyChangedSignal("Visible"):Connect(function()
            if f.Visible then traitPanel.Visible = false end
        end)
    end
end

-- ============================================================
-- COMBAT PANEL LOGIC
-- ============================================================

-- Dialogue du boss avant le combat : question, reponse du joueur, derniere replique, combat
local showBossDialog
do
    local frame = Instance.new("Frame")
    frame.Name = "BossDialog"
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.new(0.5, 0, 1, -30)
    frame.Size = UDim2.new(0.92, 0, 0, 170)
    frame.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
    frame.BackgroundTransparency = 0.05
    frame.ZIndex = 40
    frame.Visible = false
    makeCorner(frame, 14)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(620, 170)
    limit.Parent = frame
    local border = Instance.new("UIStroke")
    border.Thickness = 3
    border.Parent = frame
    frame.Parent = gui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 18, 0, 10)
    nameLabel.Size = UDim2.new(1, -36, 0, 26)
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 20
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 41
    nameLabel.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 18, 0, 40)
    textLabel.Size = UDim2.new(1, -36, 0, 66)
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 18
    textLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.ZIndex = 41
    textLabel.Parent = frame

    local function makeButton(text, color, xScale, xOffset)
        local button = Instance.new("TextButton")
        button.AnchorPoint = Vector2.new(xScale, 1)
        button.Position = UDim2.new(xScale, xOffset, 1, -12)
        button.Size = UDim2.new(0.5, -24, 0, 40)
        button.BackgroundColor3 = color
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 15
        button.ZIndex = 41
        makeCorner(button, 10)
        button.Parent = frame
        return button
    end
    local yesButton = makeButton("Oui, je te défie !", Color3.fromRGB(205, 55, 60), 0, 18)
    local noButton = makeButton("Non, pas maintenant", Color3.fromRGB(70, 70, 90), 1, -18)

    local serial = 0
    local current
    local function say(text)
        serial = serial + 1
        local mine = serial
        textLabel.Text = text
        textLabel.MaxVisibleGraphemes = 0
        for i = 1, utf8.len(text) or #text do
            if serial ~= mine then return end
            textLabel.MaxVisibleGraphemes = i
            task.wait(0.02)
        end
        textLabel.MaxVisibleGraphemes = -1
    end

    showBossDialog = function(index)
        local npc = npcData[index]
        if not npc or not npc.lines then
            BattleRequest:FireServer(index)
            return
        end
        if frame.Visible then return end
        current = index
        local c = npc.color or { 255, 255, 255 }
        local color = Color3.fromRGB(c[1], c[2], c[3])
        nameLabel.Text = npc.name
        nameLabel.TextColor3 = color
        border.Color = color
        yesButton.Visible = true
        noButton.Visible = true
        frame.Visible = true
        task.spawn(say, npc.lines[1])
    end

    yesButton.Activated:Connect(function()
        local index = current
        local npc = index and npcData[index]
        if not npc then return end
        current = nil
        yesButton.Visible = false
        noButton.Visible = false
        say(npc.lines[2])
        task.wait(1.2)
        frame.Visible = false
        BattleRequest:FireServer(index)
    end)
    noButton.Activated:Connect(function()
        current = nil
        serial = serial + 1
        frame.Visible = false
    end)
    remotes:WaitForChild("BossDialog").OnClientEvent:Connect(showBossDialog)
end

local function refreshCombatPanel()
    for _, child in ipairs(combatScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, npc in ipairs(npcData) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 55)
        row.BackgroundColor3 = npc.defeated and Color3.fromRGB(20, 50, 30) or Color3.fromRGB(50, 30, 30)
        makeCorner(row, 8)
        row.Parent = combatScroll

        local colorDot = Instance.new("Frame")
        colorDot.Size = UDim2.new(0, 40, 0, 40)
        colorDot.Position = UDim2.new(0, 8, 0, 8)
        colorDot.BackgroundColor3 = colorFromData(npc.color)
        makeCorner(colorDot, 6)
        colorDot.Parent = row

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0, 200, 0, 25)
        nameLbl.Position = UDim2.new(0, 55, 0, 5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = npc.name
        nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 16
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        local infoLbl = Instance.new("TextLabel")
        infoLbl.Size = UDim2.new(0, 250, 0, 20)
        infoLbl.Position = UDim2.new(0, 55, 0, 30)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = npc.petCount .. " pets  ·  " .. npc.reward .. " coins" .. (npc.bonus and ("  ·  " .. npc.bonus) or "")
        infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLbl.Font = Enum.Font.Gotham
        infoLbl.TextSize = 13
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.Parent = row

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(0, 100, 0, 30)
        statusLbl.Position = UDim2.new(1, -110, 0, 13)
        statusLbl.BackgroundTransparency = 1
        if npc.defeated then
            statusLbl.Text = "Vaincu"
            statusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            statusLbl.Text = "A battre"
            statusLbl.TextColor3 = Color3.fromRGB(255, 150, 150)
        end
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 15
        statusLbl.Position = UDim2.new(1, -215, 0, 13)
        statusLbl.Parent = row

        local fightBtn = Instance.new("TextButton")
        fightBtn.Size = UDim2.new(0, 100, 0, 35)
        fightBtn.Position = UDim2.new(1, -110, 0, 10)
        fightBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        fightBtn.Text = "\xE2\x9A\x94 Combattre"
        fightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        fightBtn.Font = Enum.Font.GothamBold
        fightBtn.TextSize = 13
        makeCorner(fightBtn, 8)
        fightBtn.Parent = row
        fightBtn.MouseButton1Click:Connect(function()
            combatPanel.Visible = false
            showBossDialog(i)
        end)
    end

end

-- ============================================================
-- BATTLE UI LOGIC
-- ============================================================

local battleData = nil
local battleSerial = 0

-- tremblement de camera (grosses attaques, explosions d'oeufs)
local RunService = game:GetService("RunService")
local shakeUntil, shakeAmp, shakeLen = 0, 0, 1
local shakeLast = CFrame.new()
RunService:BindToRenderStep("MWS_CamShake", Enum.RenderPriority.Camera.Value + 2, function()
    local cam = workspace.CurrentCamera
    -- camera pilotee par script : on retire le decalage de l'image precedente (sinon elle derive)
    if cam.CameraType == Enum.CameraType.Scriptable then cam.CFrame = cam.CFrame * shakeLast:Inverse() end
    shakeLast = CFrame.new()
    local now = os.clock()
    if now < shakeUntil then
        local k = shakeAmp * (shakeUntil - now) / shakeLen
        shakeLast = CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
        cam.CFrame = cam.CFrame * shakeLast
    end
end)
local function shakeCamera(amp, duration, delay)
    if game:GetService("Players").LocalPlayer:GetAttribute("MWS_SetShake") == false then return end
    task.delay(delay or 0, function()
        shakeAmp, shakeLen = amp, math.max(duration, 0.05)
        shakeUntil = os.clock() + shakeLen
    end)
end
local lastFxId = nil

-- attaque la plus forte : la camera quitte le joueur, filme le pet qui charge puis tire,
-- et montre l'impact sur le pet adverse (synchronise avec les effets du serveur : impact a 1.75 s)
local cineRunning = false
local function playAttackCine(from, to)
    if cineRunning then return end
    cineRunning = true
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    local side = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
    if side.Magnitude < 0.1 then side = Vector3.new(1, 0, 0) end
    side = side.Unit
    local perp = side:Cross(Vector3.yAxis).Unit
    local up = Vector3.new(0, 1, 0)
    local ease = Enum.EasingStyle.Sine
    -- 1) gros plan sur le pet qui charge son attaque
    cam.CFrame = CFrame.lookAt(from + perp * 16 - side * 7 + up * 4, from + up)
    TweenService:Create(cam, TweenInfo.new(1.2, ease), { CFrame = CFrame.lookAt(from + perp * 10 - side * 3.5 + up * 3, from + up * 1.2) }):Play()
    task.wait(1.2)
    -- 2) plan large : le tir traverse l'arene
    local mid = (from + to) / 2
    TweenService:Create(cam, TweenInfo.new(0.5, ease), { CFrame = CFrame.lookAt(mid + perp * 34 + up * 10, mid) }):Play()
    task.wait(0.5)
    -- 3) l'impact sur le pet adverse (explosion, pics de glace... selon le pet)
    cam.CFrame = CFrame.lookAt(to + perp * 20 + side * 5 + up * 6, to + up)
    TweenService:Create(cam, TweenInfo.new(1.6, ease), { CFrame = CFrame.lookAt(to + perp * 15 + side * 3 + up * 4, to + up) }):Play()
    task.wait(1.7)
    cam.CameraType = Enum.CameraType.Custom
    cineRunning = false
end

local function updateBattleUI(data)
    battleData = data
    if not data then return end
    -- la camera tremble au moment de l'impact, plus fort pour les attaques puissantes
    if data.fxId and data.fxId ~= lastFxId then
        lastFxId = data.fxId
        local p = data.fxPower or 1
        if p >= 4 and data.fxFrom and data.fxTo then
            task.spawn(playAttackCine, data.fxFrom, data.fxTo)
            shakeCamera(0.25 * p, 0.6, 1.75)
        elseif p >= 2 then
            shakeCamera(0.15 * p, 0.25 + 0.1 * p, (p >= 3) and 0.85 or 0.5)
        end
    end

    local myPet = data.playerPets[data.playerCurrent]
    local enemyPet = data.npcPets[data.npcCurrent]

    if myPet then
        playerPetName.Text = myPet.name
        playerPetIcon.BackgroundColor3 = colorFromData(myPet.color)
        setPetViewport(playerPetImg, myPet.name, myPet.rarity)
        local hpPct = myPet.hp / myPet.maxHp
        TweenService:Create(playerHpBar, TweenInfo.new(0.25), { Size = UDim2.new(hpPct, 0, 1, 0) }):Play()
        playerHpBar.BackgroundColor3 = Color3.fromRGB(
            math.floor(50 + (1 - hpPct) * 150),
            math.floor(200 * hpPct),
            50
        )
        playerHpText.Text = myPet.hp .. " / " .. myPet.maxHp .. " HP"
        playerPetCount.Text = "Pet " .. data.playerCurrent .. " / " .. #data.playerPets
    end

    if enemyPet then
        npcPetName.Text = enemyPet.name
        npcPetIcon.BackgroundColor3 = colorFromData(enemyPet.color)
        setPetViewport(npcPetImg, enemyPet.name, enemyPet.rarity)
        local hpPct = enemyPet.hp / enemyPet.maxHp
        TweenService:Create(npcHpBar, TweenInfo.new(0.25), { Size = UDim2.new(hpPct, 0, 1, 0) }):Play()
        npcHpBar.BackgroundColor3 = Color3.fromRGB(
            math.floor(200 * hpPct + 50),
            math.floor(80 * (1 - hpPct)),
            math.floor(50 * (1 - hpPct))
        )
        npcHpText.Text = enemyPet.hp .. " / " .. enemyPet.maxHp .. " HP"
        npcPetCount.Text = enemyPet.isBoss and "BOSS" or ("Pet " .. data.npcCurrent .. " / " .. #data.npcPets)

        -- jauge de l'attaque speciale du boss (chaleur, bouclier, charge...) : texte et couleur du serveur
        local gauge = npcPetFrame:FindFirstChild("HeatGauge")
        if not gauge then
            gauge = Instance.new("Frame")
            gauge.Name = "HeatGauge"
            gauge.Size = UDim2.new(1, -75, 0, 14)
            gauge.Position = UDim2.new(0, 65, 0, 86)
            gauge.BackgroundColor3 = Color3.fromRGB(40, 30, 30)
            gauge.ZIndex = 23
            makeCorner(gauge, 4)
            gauge.Parent = npcPetFrame
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.ZIndex = 24
            makeCorner(fill, 4)
            fill.Parent = gauge
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Font = Enum.Font.GothamBlack
            label.TextScaled = true
            label.ZIndex = 25
            label.Parent = gauge
        end
        local mech = data.mechGauge
        gauge.Visible = mech ~= nil
        if mech then
            gauge.Fill.Size = UDim2.fromScale(mech.fill, 1)
            gauge.Fill.BackgroundColor3 = Color3.fromRGB(mech.color[1], mech.color[2], mech.color[3])
            gauge.Label.Text = mech.text
        end
    end

    battleLog.Text = data.log or ""
    fleeBtn.Visible = (data.active == true)

    -- Calculer la charge POURTOUR d'abord
    local charge = data.playerCharge or 0
    local maxCharge = data.playerMaxCharge or 100
    local chargePct = maxCharge > 0 and (charge / maxCharge) or 0

    chargeBar.Size = UDim2.new(chargePct, 0, 1, 0)
    if chargePct >= 1 then
        chargeBar.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
        chargeText.Text = "CHARGE MAX !"
        chargeText.TextColor3 = Color3.fromRGB(50, 50, 0)
    else
        chargeBar.BackgroundColor3 = Color3.fromRGB(255, math.floor(180 - 120 * chargePct), 50)
        chargeText.Text = "Charge: " .. math.floor(chargePct * 100) .. "%"
        chargeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    guardBtn.Visible = data.active == true and data.turn == "player"
    -- coup dangereux annonce par le boss : le bouton Proteger devient rouge
    local danger = data.danger == true
    guardBtn.BackgroundColor3 = danger and Color3.fromRGB(220, 50, 40) or Color3.fromRGB(50, 110, 200)
    guardBtn.Text = danger and "\u{1F6E1} PROTÈGE-TOI !" or "\u{1F6E1} Protéger"
    battleStatus.Text = data.status or ""
    if data.active then
        if data.turn == "player" then
            attackBtn.Visible = true
            switchBtn.Visible = #data.playerPets > 1

            -- Special 1: Lame de Feu (50% charge)
            local canS1 = chargePct >= 0.5
            if canS1 then
                special1Btn.Visible = true
                special1Btn.BackgroundColor3 = Color3.fromRGB(255, 100, 30)
                special1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                special1Btn.Visible = true
                special1Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                special1Btn.TextColor3 = Color3.fromRGB(120, 120, 120)
            end

            -- Special 2: Tempete Glace (75% charge)
            local canS2 = chargePct >= 0.75
            if canS2 then
                special2Btn.Visible = true
                special2Btn.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
                special2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                special2Btn.Visible = true
                special2Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                special2Btn.TextColor3 = Color3.fromRGB(120, 120, 120)
            end

            -- Special 3: Frappe Divine (100% charge)
            local canS3 = chargePct >= 1.0
            if canS3 then
                special3Btn.Visible = true
                special3Btn.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
                special3Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                special3Btn.Visible = true
                special3Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                special3Btn.TextColor3 = Color3.fromRGB(120, 120, 120)
            end

            superBtn.Visible = false
            battleResult.Text = ""
        else
            attackBtn.Visible = false
            switchBtn.Visible = false
            special1Btn.Visible = false
            special2Btn.Visible = false
            special3Btn.Visible = false
            superBtn.Visible = false
            battleResult.Text = "Tour de l'adversaire..."
        end
    else
        attackBtn.Visible = false
        switchBtn.Visible = false
        special1Btn.Visible = false
        special2Btn.Visible = false
        special3Btn.Visible = false
        superBtn.Visible = false
        if string.find(data.log or "", "VICTOIRE") then
            battleResult.Text = "VICTOIRE !"
            battleResult.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif string.find(data.log or "", "Defaite") then
            battleResult.Text = "DEFAITE"
            battleResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        local serial = battleSerial
        task.delay(3, function()
            if serial ~= battleSerial then return end
            battleFrame.Visible = false
        end)
    end
end

attackBtn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("attack")
end)

guardBtn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("guard")
end)

switchBtn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("switch")
end)

special1Btn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("special1")
end)

special2Btn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("special2")
end)

special3Btn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("special3")
end)

superBtn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("super")
end)

-- ============================================================
-- TOGGLES
-- ============================================================

fleeBtn.MouseButton1Click:Connect(function()
    BattleAction:FireServer("flee")
end)

invButton.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then
        eggPanel.Visible = false
        combatPanel.Visible = false
        refreshPanel()
    end
end)

closeButton.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

eggButton.MouseButton1Click:Connect(function()
    eggPanel.Visible = not eggPanel.Visible
    if eggPanel.Visible then
        panel.Visible = false
        combatPanel.Visible = false
        refreshEggPanel()
    end
end)

eggCloseBtn.MouseButton1Click:Connect(function()
    eggPanel.Visible = false
end)

combatButton.MouseButton1Click:Connect(function()
    combatPanel.Visible = not combatPanel.Visible
    if combatPanel.Visible then
        panel.Visible = false
        eggPanel.Visible = false
        refreshCombatPanel()
    end
end)

combatCloseBtn.MouseButton1Click:Connect(function()
    combatPanel.Visible = false
end)


-- ============================================================
-- STATE UPDATE
-- ============================================================

StateUpdate.OnClientEvent:Connect(function(newState, income)
    state = newState
    incomePerSec = income or 0
    coinLabel.Text = ((tostring(math.floor(state.coins or 0)):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^%s+", ""))) .. " Coins"
    incomeLabel.Text = "+" .. incomePerSec .. " /sec"
    rebirthLabel.Text = "Renaissance: " .. tostring(state.rebirthLevel or 0)
    if onRebirthInfo then onRebirthInfo() end
    if panel.Visible then refreshPanel() end
    if eggPanel.Visible then refreshEggPanel() end
    if combatPanel.Visible then refreshCombatPanel() end
end)

-- ============================================================
-- EGG INFO
-- ============================================================

EggInfo.OnClientEvent:Connect(function(data)
    eggData = data
    if eggPanel.Visible then refreshEggPanel() end
end)

-- ============================================================
-- NPC INFO
-- ============================================================

NPCInfo.OnClientEvent:Connect(function(data, total, rb)
    npcData = data
    totalNPCs = total or 0
    -- le serveur dit si la renaissance est possible (dresseurs des mondes debloques battus)
    if type(rb) == "table" then rebirthInfo = rb end
    if combatPanel.Visible then refreshCombatPanel() end
    if onRebirthInfo then onRebirthInfo() end
end)

-- ============================================================
-- BATTLE EVENTS
-- ============================================================

BattleStart.OnClientEvent:Connect(function(data)
    if data.success then
        battleSerial = battleSerial + 1
        battleFrame.Visible = true
        battleResult.Text = ""
        updateBattleUI(data)
    else
        hatchFrame.Visible = true
        hatchFrame.BackgroundTransparency = 0.5
        hatchLabel.Text = data.message or "Erreur"
        hatchLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        hatchLabel.TextSize = 24
        task.wait(2)
        hatchFrame.Visible = false
    end
end)

BattleUpdate.OnClientEvent:Connect(function(data)
    updateBattleUI(data)
end)

RebirthRemote.OnClientEvent:Connect(function(data)
    if data.success then
        hatchFrame.Visible = true
        hatchFrame.BackgroundTransparency = 0.3
        hatchLabel.Text = "RENAISSANCE !\nNiveau " .. data.rebirthLevel .. "  ·  gains x" .. (1 + data.rebirthLevel * 0.5)
        hatchLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
        hatchLabel.TextSize = 28
        task.wait(3)
        hatchFrame.Visible = false
    else
        hatchFrame.Visible = true
        hatchFrame.BackgroundTransparency = 0.5
        hatchLabel.Text = data.message or "Erreur"
        hatchLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        hatchLabel.TextSize = 22
        task.wait(2.5)
        hatchFrame.Visible = false
    end
end)
	
-- ============================================================
-- HATCH ANIMATION
-- ============================================================

-- Cinematique d'eclosion, jouee devant la camera (visible seulement par le joueur).
-- Plus le pet obtenu est rare, plus l'animation est grande, longue et belle :
--   Commun : secousses + pop. Rare : eclats qui tournent, fissures lumineuses.
--   Epique : + anneau au sol, nom de la rarete. Legendaire : la nuit tombe, colonne de lumiere,
--   aureole, braises, l'oeuf s'envole. Mythique : + cercle de feu, demons ou cristaux, eclairs.
--   Divin / Secret : 3 colonnes, double aureole (arc-en-ciel pour Secret), battements de coeur.
-- Chaque oeuf a en plus son animation a lui, dans le theme de son monde (MWS_EggThemes).
-- tout ce qui sert aux animations d'oeuf reste dans ce bloc : le script est pres de la limite
-- de 200 variables locales de Luau, et rien d'ici n'est utilise plus bas
do
local EggModels = require(ReplicatedStorage:WaitForChild("MWS_EggModels"))
local Lighting = game:GetService("Lighting")
local HATCH_LEVEL = { Commun = 1, Rare = 2, Epique = 3, Legendaire = 4, Mythique = 5, Divin = 6, Secret = 7 }
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"

local function cinePart(folder, size, color, shape)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Size = size
    if shape then p.Shape = shape end
    p.Parent = folder
    return p
end

local function cineEmitter(parent, tex, c1, c2, size, rate, speed, life)
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = tex
    pe.Color = ColorSequence.new(c1, c2 or c1)
    pe.LightEmission = 0.8
    pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
    pe.Lifetime = NumberRange.new(life * 0.6, life)
    pe.Rate = rate
    pe.Speed = NumberRange.new(speed * 0.5, speed)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Parent = parent
    return pe
end

-- petit demon : corps rond, cornes, yeux jaunes, ailes qui battent, queue
local function makeImp(folder, sc)
    local V = Vector3.new
    local body = cinePart(folder, V(0.8, 0.8, 0.7) * sc, Color3.fromRGB(170, 30, 35))
    body.Material = Enum.Material.Plastic
    local pieces = {}
    local function piece(size, col, off, neon)
        local p = cinePart(folder, size * sc, col)
        if not neon then p.Material = Enum.Material.Plastic end
        table.insert(pieces, { p = p, off = CFrame.new(off * sc) })
    end
    piece(V(0.15, 0.35, 0.15), Color3.fromRGB(40, 20, 20), V(-0.25, 0.5, 0))
    piece(V(0.15, 0.35, 0.15), Color3.fromRGB(40, 20, 20), V(0.25, 0.5, 0))
    piece(V(0.16, 0.12, 0.05), Color3.fromRGB(255, 230, 60), V(-0.17, 0.1, -0.36), true)
    piece(V(0.16, 0.12, 0.05), Color3.fromRGB(255, 230, 60), V(0.17, 0.1, -0.36), true)
    piece(V(0.1, 0.1, 0.6), Color3.fromRGB(120, 20, 25), V(0, -0.2, 0.6))
    local wings = {}
    for _, sd in ipairs({ -1, 1 }) do
        local w = cinePart(folder, V(0.75, 0.06, 0.5) * sc, Color3.fromRGB(90, 15, 20))
        w.Material = Enum.Material.Plastic
        table.insert(wings, { p = w, side = sd })
    end
    local all = { body }
    for _, pc in ipairs(pieces) do table.insert(all, pc.p) end
    for _, w in ipairs(wings) do table.insert(all, w.p) end
    return {
        parts = all,
        set = function(cf, t)
            body.CFrame = cf
            for _, pc in ipairs(pieces) do pc.p.CFrame = cf * pc.off end
            local flap = math.sin(t * 22) * 0.7
            for _, w in ipairs(wings) do
                w.p.CFrame = cf * CFrame.new(w.side * 0.35 * sc, 0.15 * sc, 0.1 * sc) * CFrame.Angles(0, 0, w.side * flap) * CFrame.new(w.side * 0.38 * sc, 0, 0)
            end
        end,
    }
end

-- flash plein ecran dans son propre ScreenGui (l'interface principale est cachee pendant les cinematiques)
local flashGui = Instance.new("ScreenGui")
flashGui.Name = "MWS_FlashGui"
flashGui.ResetOnSpawn = false
flashGui.IgnoreGuiInset = true
flashGui.DisplayOrder = 100
flashGui.Parent = player:WaitForChild("PlayerGui")
local function screenFlash(color, from, dur)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = color
    f.BackgroundTransparency = from
    f.BorderSizePixel = 0
    f.ZIndex = 60
    f.Parent = flashGui
    TweenService:Create(f, TweenInfo.new(dur), { BackgroundTransparency = 1 }):Play()
    task.delay(dur + 0.05, function() f:Destroy() end)
end

-- l'oeuf du socle est cache (pour ce joueur seulement) pendant son animation
local function hideStandEgg(eggIndex, hide)
    if not eggIndex then return end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "EggDeco_" .. eggIndex then
            for _, p in ipairs(d:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = hide and 1 or 0 end
            end
        end
        -- pendant l'animation : plus de nom, de prix ni d'invite d'achat au-dessus des oeufs
        if d:IsA("BillboardGui") and d.Parent and d.Parent.Parent and d.Parent.Parent.Name:match("^EggDeco_") then
            d.Enabled = not hide
        elseif d:IsA("ProximityPrompt") and d.Name:match("^BuyEggPrompt_") then
            d.Enabled = not hide
        end
    end
    -- ton personnage et les pets qui suivent sont caches aussi (ils se mettaient devant l'oeuf) ;
    -- on note leur etat d'avant pour le remettre a la fin (reglages "voir les pets" respectes)
    local holders = {}
    if player.Character then table.insert(holders, player.Character) end
    local generated = workspace:FindFirstChild("MWS_Generated")
    if generated and generated:FindFirstChild("Pets") then table.insert(holders, generated.Pets) end
    for _, holder in ipairs(holders) do
        for _, p in ipairs(holder:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                if hide then
                    if p:GetAttribute("MWS_HatchLTM") == nil then p:SetAttribute("MWS_HatchLTM", p.LocalTransparencyModifier) end
                    p.LocalTransparencyModifier = 1
                elseif p:GetAttribute("MWS_HatchLTM") ~= nil then
                    p.LocalTransparencyModifier = p:GetAttribute("MWS_HatchLTM")
                    p:SetAttribute("MWS_HatchLTM", nil)
                end
            elseif p:IsA("BillboardGui") or p:IsA("ParticleEmitter") then
                if hide then
                    if p:GetAttribute("MWS_HatchOn") == nil then p:SetAttribute("MWS_HatchOn", p.Enabled) end
                    p.Enabled = false
                elseif p:GetAttribute("MWS_HatchOn") ~= nil then
                    p.Enabled = p:GetAttribute("MWS_HatchOn")
                    p:SetAttribute("MWS_HatchOn", nil)
                end
            end
        end
    end
end

-- le pet sort de l'oeuf, tourne sur lui-meme, avec son nom au-dessus (sans cadre)
local function revealPet(folder, center, away, pet, height, hold)
    local info = PetBricks.measure(pet.name)
    if not info then return end
    local m = Instance.new("Model")
    local k = (height or 4.5) * math.min(Traits.scale(pet), 1.7) / math.max(info.Hd, info.W * 0.8, info.L * 0.6)
    PetBricks.assemble(pet.name, { model = m, static = true, k = k, origin = CFrame.new(), bright = RARITY_GLOW[pet.rarity] or 0 })
    Traits.paint(m, pet.mutation)
    local ts = math.min(Traits.scale(pet), 1.7)
    m.WorldPivot = CFrame.new()
    m.Parent = folder
    local fp = m:FindFirstChildWhichIsA("BasePart", true)
    if fp and pet.mutation then
        local pe = Traits.decorate(fp, pet.mutation, (height or 4.5) * ts * 0.6)
        if pe then pe.Rate = pe.Rate * 3 end
    end
    local tag = cinePart(folder, Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1))
    tag.Transparency = 1
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 260, 0, 70)
    bb.Adornee = tag
    bb.Parent = tag
    local rc = (RARITY_COLORS[pet.rarity] or Color3.new(1, 1, 1)):Lerp(Color3.new(1, 1, 1), 0.25)
    local function line(y, h, text, size, col)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, h)
        l.Position = UDim2.new(0, 0, 0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextSize = size
        l.Font = Enum.Font.GothamBold
        l.TextColor3 = col
        l.TextStrokeTransparency = 0.45
        l.Parent = bb
        return l
    end
    local labels = {
        line(0, 28, Traits.fullName(pet), 22, Traits.accent(pet) and Color3.new(1, 1, 1):Lerp(Traits.accent(pet), 0.5) or Color3.new(1, 1, 1)),
        line(28, 20, pet.rarity .. (Traits.tag(pet) ~= "" and ("  ·  " .. Traits.tag(pet) .. " !") or ""), 16, rc),
        line(48, 18, "+" .. tostring(pet.income or 0) .. " coins/sec", 14, Color3.fromRGB(215, 215, 225)),
    }
    for _, l in ipairs(labels) do l.TextTransparency = 1 l.TextStrokeTransparency = 1 end
    local face = CFrame.lookAt(center, center + away)
    local t0 = os.clock()
    local conn = RunService.RenderStepped:Connect(function()
        local t = os.clock() - t0
        local e = math.clamp(t / 0.6, 0, 1)
        e = 1 - (1 - e) * (1 - e)
        m:PivotTo(face * CFrame.new(0, -1 + 2.6 * e, 0) * CFrame.Angles(0, math.sin(t * 1.5) * 0.6, 0))
        tag.CFrame = CFrame.new(center + Vector3.new(0, (height or 4.5) * ts * 0.95 + 2.6 * e, 0))
    end)
    task.wait(0.45)
    for _, l in ipairs(labels) do
        TweenService:Create(l, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.45 }):Play()
    end
    task.wait(hold or 2.3)
    conn:Disconnect()
end

-- center = position de l'oeuf sur le socle ; la camera se tourne vers lui pendant l'animation.
-- level = taille de l'animation, donnee par la rarete du pet obtenu (1 Commun ... 7 Secret)
local function playEggCinematic(style, level, center, eggIndex, pet)
    local cam = workspace.CurrentCamera
    local st = EggModels.STYLES[style] or EggModels.STYLES.base
    local WHITE = Color3.new(1, 1, 1)
    local rc = RARITY_COLORS[pet and pet.rarity] or st.glow
    local SoundService = game:GetService("SoundService")
    -- sons de l'animation (joues par MWS_Sounds) : craquements, grondement, explosion
    local function sfx(name) SoundService:SetAttribute("MWS_EggSfx", name .. "|" .. os.clock()) end
    local folder = Instance.new("Folder")
    folder.Name = "MWS_HatchFX"
    folder.Parent = workspace
    local K = 1.15
    local SC = K / 0.42 -- distances et tailles des effets, a l'echelle de l'oeuf
    local model, root, info = EggModels.build(style, { k = K })
    model.Parent = folder
    hideStandEgg(eggIndex, true)

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local away = (hrp and hrp.Position or cam.CFrame.Position) - center
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
    away = away.Unit
    local right = away:Cross(Vector3.yAxis).Unit
    cam.CameraType = Enum.CameraType.Scriptable
    TweenService:Create(cam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { CFrame = CFrame.lookAt(center + away * ((level >= 4) and 19 or 15) + Vector3.new(0, 4, 0), center + Vector3.new(0, 0.8, 0)) }):Play()

    local S = { y = 0, yc = 0, tilt = 0, spin = 0, boom = nil, reveal = nil, rise = 0 }
    local orbit, imps, rings, pillars = {}, {}, {}, {}
    local banner, rainbow
    -- animation propre a cet oeuf, dans le theme de son monde (voir MWS_EggThemes)
    local theme = require(ReplicatedStorage:WaitForChild("MWS_EggThemes"))[style] or {}
    local ctx = { folder = folder, center = center, c = center, away = away, right = right, root = root, SC = SC,
        level = level, st = st, S = S, imps = imps, makeImp = makeImp, updaters = {} }
    local baseSfx = sfx
    sfx = function(name)
        baseSfx(name)
        if name == "egg" and theme.beat then theme.beat(ctx) end   -- a chaque craquement
    end
    local t0 = os.clock()
    local conn = RunService.RenderStepped:Connect(function(dt)
        local t = os.clock() - t0
        S.yc = S.yc + (S.y - S.yc) * math.min(1, dt * 3)
        if S.reveal then
            local e = math.clamp((os.clock() - S.reveal) / 0.6, 0, 1)
            S.rise = 0.4 * (1 - (1 - e) * (1 - e))
        end
        local c = center + Vector3.new(0, S.yc, 0)
        -- mouvement propre a l'oeuf (sautille, tourne comme une piece, flotte, tremble...)
        local mdy, mspin, mtilt = 0, 0, 0
        if theme.motion and not S.boom then mdy, mspin, mtilt = theme.motion(ctx, t, dt) end
        c = c + Vector3.new(0, mdy, 0)
        ctx.c = c
        root.CFrame = CFrame.new(c) * CFrame.fromAxisAngle(away, S.tilt + mtilt) * CFrame.Angles(0, S.spin + mspin, 0)
        for _, update in ipairs(ctx.updaters) do update(t, dt) end
        local spread = S.boom and (os.clock() - S.boom) * 30 or 0
        for i, o in ipairs(orbit) do
            local a = t * o.speed + o.phase
            local pos = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (o.r + spread) + Vector3.new(0, o.h + math.sin(t * 3 + i) * 0.5, 0)
            o.p.CFrame = CFrame.new(pos) * CFrame.Angles(t * 2, t * 3, 0)
        end
        for i, imp in ipairs(imps) do
            local a = t * 2.2 + i * (math.pi * 2 / #imps)
            local pos = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (imp.r + spread) + Vector3.new(0, imp.h + math.sin(t * 4 + i) * 0.8, 0)
            local ahead = pos + Vector3.new(-math.sin(a), 0, math.cos(a))
            imp.obj.set(CFrame.lookAt(pos, ahead), t)
        end
        -- anneaux de lumiere : au sol, ou en aureole face a la camera (autour de l'oeuf, puis du pet)
        for _, rg in ipairs(rings) do
            local g = math.clamp((os.clock() - rg.born) / 0.7, 0, 1)
            g = 1 - (1 - g) * (1 - g) * (1 - g)
            local r = rg.r * g + (rg.halo and S.rise * 2 or spread)
            local ctr = rg.halo and (c + Vector3.new(0, S.rise, 0) - away * 0.6) or (center + Vector3.new(0, rg.h, 0))
            local n = #rg.parts
            for j, p in ipairs(rg.parts) do
                local a = t * rg.speed + j / n * math.pi * 2
                local pos, tang
                if rg.halo then
                    pos = ctr + right * (math.cos(a) * r) + Vector3.yAxis * (math.sin(a) * r)
                    tang = Vector3.yAxis * math.cos(a) - right * math.sin(a)
                else
                    pos = ctr + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
                    tang = Vector3.new(-math.sin(a), 0, math.cos(a))
                end
                p.CFrame = CFrame.lookAt(pos, pos + tang)
                if rg.rainbow then p.Color = Color3.fromHSV((j / n + t * 0.35) % 1, 0.6, 1) end
            end
        end
        if not S.boom then
            for _, pl in ipairs(pillars) do pl.p.Transparency = 0.35 + 0.15 * math.sin(t * 9 + pl.phase) end
        end
        if rainbow then rainbow.Rotation = (t * 140) % 360 end
    end)

    local function wobble(n, amp, dur)
        for i = 1, n do
            S.tilt = ((i % 2 == 0) and 1 or -1) * math.rad(amp * (0.6 + 0.4 * i / n))
            task.wait(dur)
        end
        S.tilt = 0
    end
    -- fissures lumineuses sur la coquille (une brique sur "every")
    local function crack(every, col)
        for i, p in ipairs(info.shell) do
            if i % every == 0 then p.Material = Enum.Material.Neon; p.Color = col end
        end
    end
    -- anneau fait de petits segments lumineux
    local function ring(r, n, col, thick, opts)
        local rg = { parts = {}, r = r, born = os.clock(), speed = opts.speed or 1, h = opts.h or 0, halo = opts.halo, rainbow = opts.rainbow }
        local len = 2 * math.pi * r / n * 1.15
        for _ = 1, n do
            local p = cinePart(folder, Vector3.new(thick, thick, len), col)
            p.CFrame = CFrame.new(center)
            table.insert(rg.parts, p)
        end
        table.insert(rings, rg)
    end
    -- colonne de lumiere qui monte jusqu'au ciel
    local function pillar(offset, w, col)
        local cf = CFrame.new(center + offset + Vector3.new(0, 36, 0)) * CFrame.Angles(0, 0, math.rad(90))
        local outer = cinePart(folder, Vector3.new(80, 0.1, 0.1), col, Enum.PartType.Cylinder)
        outer.CFrame = cf
        outer.Transparency = 0.35
        local core = cinePart(folder, Vector3.new(80, 0.1, 0.1), WHITE, Enum.PartType.Cylinder)
        core.CFrame = cf
        core.Transparency = 0.15
        local ti = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(outer, ti, { Size = Vector3.new(80, w, w) }):Play()
        TweenService:Create(core, ti, { Size = Vector3.new(80, w * 0.35, w * 0.35) }):Play()
        table.insert(pillars, { p = outer, core = core, w = w, phase = #pillars * 1.7 })
    end
    -- nom de la rarete en grand en haut de l'ecran, au moment ou l'oeuf eclate
    local function showBanner()
        local NAMES = { Epique = "ÉPIQUE", Legendaire = "LÉGENDAIRE", Mythique = "MYTHIQUE", Divin = "DIVIN", Secret = "SECRET" }
        banner = Instance.new("TextLabel")
        banner.Name = "MWS_HatchBanner"
        banner.AnchorPoint = Vector2.new(0.5, 0.5)
        banner.Position = UDim2.fromScale(0.5, 0.17)
        banner.Size = UDim2.fromScale(0.7, (level >= 6) and 0.15 or 0.11)
        banner.BackgroundTransparency = 1
        banner.Font = Enum.Font.FredokaOne
        banner.TextScaled = true
        banner.Text = (NAMES[pet.rarity] or string.upper(tostring(pet.rarity))) .. " !"
        banner.TextColor3 = WHITE
        banner.TextTransparency = 1
        banner.ZIndex = 61
        local stroke = Instance.new("UIStroke")
        stroke.Color = rc:Lerp(Color3.new(0, 0, 0), 0.45)
        stroke.Thickness = 3
        stroke.Transparency = 1
        stroke.Parent = banner
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        if level >= 7 then
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 110)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 90)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 255, 170)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(110, 170, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 110, 255)),
            })
            rainbow = g
        else
            g.Color = ColorSequence.new(WHITE, rc:Lerp(WHITE, 0.2))
        end
        g.Parent = banner
        local sc = Instance.new("UIScale")
        sc.Scale = 2.4
        sc.Parent = banner
        banner.Parent = flashGui
        TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        TweenService:Create(banner, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
        -- il s'efface ensuite pour laisser lire le nom du pet
        task.delay(1.8, function()
            if banner and banner.Parent then
                TweenService:Create(banner, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
            end
        end)
    end
    task.wait(0.5)

    -- 2+ (Rare) : lumiere, etincelles et eclats qui tournent autour de l'oeuf
    if level >= 2 then
        local pl = Instance.new("PointLight")
        pl.Color = rc
        pl.Range = 14 + level * 3
        pl.Brightness = 1.5 + level * 0.4
        pl.Parent = root
        cineEmitter(root, SPARK_TEX, st.glow, rc, 0.35 * SC, 8 + level * 4, 2 * SC, 0.8)
        for i = 1, math.min(4 + level * 2, 14) do
            local p = cinePart(folder, Vector3.new(0.25, 0.25, 0.25) * SC, (i % 2 == 0) and rc or st.glow)
            table.insert(orbit, { p = p, r = (1.5 + (i % 3) * 0.2) * SC, h = (i % 3 - 1) * 0.5 * SC, speed = 2 + (i % 2), phase = i * 0.9 })
        end
    end
    -- 3+ (Epique) : anneau lumineux au sol
    if level >= 3 then
        ring(2.2 * SC, 28, rc, 0.35, { h = -2.7, speed = 0.8 })
    end
    -- 4+ (Legendaire) : la nuit tombe, colonne de lumiere, aureole, braises qui montent, l'oeuf s'envole
    local cc
    if level >= 4 then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "MWS_HatchCC"
        cc.Parent = Lighting
        TweenService:Create(cc, TweenInfo.new(0.8), { Brightness = (level >= 6) and -0.36 or -0.24, Contrast = 0.18, Saturation = 0.15, TintColor = WHITE:Lerp(rc, 0.3) }):Play()
        S.y = 1.2
        local floor = cinePart(folder, Vector3.new(26, 0.2, 26), rc)
        floor.Transparency = 1
        floor.CFrame = CFrame.new(center - Vector3.new(0, 2.8, 0))
        local embers = cineEmitter(floor, SPARK_TEX, rc:Lerp(WHITE, 0.4), rc, 0.35, (level >= 6) and 70 or 35, 5, 3)
        embers.EmissionDirection = Enum.NormalId.Top
        embers.SpreadAngle = Vector2.new(12, 12)
        embers.LightEmission = 1
        pillar(-away * 4, (level >= 5) and 3.2 or 2.4, rc)
        ring(5.2, 40, rc:Lerp(WHITE, 0.2), 0.5, { halo = true, speed = 0.6, rainbow = level >= 7 })
        -- la camera s'approche doucement pendant toute la montee
        TweenService:Create(cam, TweenInfo.new(({ 0, 0, 0, 2.8, 3.9, 5.7, 6.1 })[level], Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { CFrame = CFrame.lookAt(center + away * 12 + right * 2 + Vector3.new(0, 3, 0), center + Vector3.new(0, 1.6, 0)) }):Play()
    end
    -- le theme de l'oeuf (prairie, tresor, orage, eruption, constellation, trou noir) ; il grandit avec la rarete
    if theme.setup then theme.setup(ctx) end
    -- 6+ (Divin, Secret) : deux colonnes de plus sur les cotes et une deuxieme aureole
    if level >= 6 then
        pillar(right * 9, 1.6, rc:Lerp(WHITE, 0.3))
        pillar(-right * 9, 1.6, rc:Lerp(WHITE, 0.3))
        ring(6.6, 48, st.glow:Lerp(WHITE, 0.2), 0.42, { halo = true, speed = -0.9, rainbow = level >= 7 })
    end

    if level == 1 then
        sfx("egg")
        wobble(4, 14, 0.12)
        task.wait(0.12)
        sfx("egg")
        wobble(4, 18, 0.09)
    elseif level <= 3 then
        for _ = 1, 8 do S.spin = S.spin + 0.35; task.wait(0.04) end
        sfx("egg")
        wobble(6, 16, 0.1)
        crack(3, rc)
        shakeCamera(0.2, 0.5)
        sfx("egg")
        wobble(8, 22, 0.06)
        if level == 3 then
            crack(2, rc)
            shakeCamera(0.3, 0.5)
            sfx("egg")
            wobble(8, 26, 0.055)
        end
    else
        -- l'oeuf s'eleve en tournant de plus en plus vite pendant que la colonne se forme
        sfx("charge")
        for i = 1, 25 do S.spin = S.spin + 0.12 + i * 0.012; task.wait(0.04) end
        shakeCamera(0.15, 1.2)
        wobble(6, 12, 0.13)
        sfx("egg")
        crack(3, rc)
        wobble(8, 18, 0.08)
        if level >= 5 then
            crack(2, rc)
            shakeCamera(0.4, 1.0)
            sfx("egg")
            wobble(10, 20, 0.07)
            for _ = 1, 6 do
                local a = math.random() * math.pi * 2
                local bolt = cinePart(folder, Vector3.new(0.3, 0.3, 6), (math.random() < 0.5) and rc or st.accent)
                local c = center + Vector3.new(0, S.yc, 0)
                bolt.CFrame = CFrame.lookAt(c + Vector3.new(math.cos(a), math.sin(a) * 0.8, math.sin(a)) * 4.5, c)
                task.delay(0.08, function() bolt:Destroy() end)
                S.tilt = math.rad(math.random(-8, 8))
                task.wait(0.07)
            end
            S.tilt = 0
        end
        if level >= 6 then
            -- battements de coeur : l'ecran pulse de la couleur de la rarete, de plus en plus vite
            for i = 1, (level >= 7) and 4 or 3 do
                screenFlash(rc, 0.72, 0.3)
                shakeCamera(0.25 + i * 0.08, 0.25)
                sfx("egg")
                S.tilt = math.rad(((i % 2 == 0) and 1 or -1) * 14)
                task.wait(0.5 - i * 0.06)
                S.tilt = 0
                task.wait(0.12)
            end
        end
        -- silence : l'oeuf devient tout lumineux et s'immobilise, juste avant d'eclater
        S.tilt = 0
        for _, p in ipairs(info.shell) do
            p.Material = Enum.Material.Neon
            TweenService:Create(p, TweenInfo.new(0.35), { Color = rc:Lerp(WHITE, 0.6) }):Play()
        end
        task.wait((level >= 6) and 0.6 or 0.35)
    end

    -- explosion
    SoundService:SetAttribute("MWS_EggBurst", os.clock()) -- son de l'oeuf qui eclate
    if level >= 4 then sfx("boom") end
    local big = (4 + level * 1.5) * SC * 0.8
    local c = ctx.c
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then d.Transparency = 1 elseif d:IsA("ParticleEmitter") then d.Enabled = false end
    end
    local core = cinePart(folder, Vector3.new(1, 1, 1), (level >= 2) and rc:Lerp(WHITE, 0.3) or st.glow, Enum.PartType.Ball)
    core.CFrame = CFrame.new(c)
    TweenService:Create(core, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(big, big, big), Transparency = 1 }):Play()
    local burstCol = (style == "lave") and Color3.fromRGB(255, 120, 30) or rc
    cineEmitter(core, (style == "lave") and FIRE_TEX or SPARK_TEX, st.accent, burstCol, (0.5 + level * 0.15) * SC * 0.7, 0, (6 + level * 2) * SC * 0.6, 0.9):Emit(20 * level)
    for i = 1, 6 + level * 3 do
        local shard = cinePart(folder, Vector3.new(0.3, 0.2, 0.4) * SC, (i % 2 == 0) and st.shell or rc)
        shard.CFrame = CFrame.new(c)
        local dir = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit
        TweenService:Create(shard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = CFrame.new(c + dir * (2 + level) * SC * 0.6) * CFrame.Angles(math.random() * 6, math.random() * 6, 0),
            Transparency = 1,
        }):Play()
    end
    S.boom = os.clock()
    if theme.burst then theme.burst(ctx, c) end   -- explosion propre a l'oeuf (fleurs, pieces, lave, etoiles...)
    if level >= 3 then
        local wave = cinePart(folder, Vector3.new(0.3, 1, 1), rc, Enum.PartType.Cylinder)
        wave.CFrame = CFrame.new(center - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
        local w = 10 + level * 5
        TweenService:Create(wave, TweenInfo.new(0.7), { Size = Vector3.new(0.3, w, w), Transparency = 1 }):Play()
        showBanner()
    end
    if level >= 4 then
        for _, imp in ipairs(imps) do
            for _, p in ipairs(imp.obj.parts) do TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play() end
        end
        -- les colonnes s'elargissent d'un coup puis s'effacent
        for _, pl in ipairs(pillars) do
            TweenService:Create(pl.p, TweenInfo.new(1.4), { Size = Vector3.new(80, pl.w * 2.4, pl.w * 2.4), Transparency = 1 }):Play()
            TweenService:Create(pl.core, TweenInfo.new(1.4), { Size = Vector3.new(80, pl.w, pl.w), Transparency = 1 }):Play()
        end
        screenFlash(WHITE, 0.05, 0.5 + (level - 4) * 0.2)
        shakeCamera(0.5 + level * 0.1, 0.5 + level * 0.08)
        TweenService:Create(cc, TweenInfo.new(1.2), { Brightness = -0.12, Contrast = 0.1 }):Play()
    else
        screenFlash(WHITE, (level == 1) and 0.7 or 0.45, 0.35)
        if level >= 2 then shakeCamera(0.35, 0.35) end
    end
    task.wait(0.35)
    -- le pet apparait (l'animation est finie : c'est seulement maintenant qu'on voit ce qu'on a eu)
    S.reveal = os.clock()
    -- plus le pet est rare, plus il apparait grand et longtemps
    if pet then revealPet(folder, center, away, pet, (level >= 6) and 7.5 or ((level >= 4) and 6 or nil), (level >= 6) and 3.4 or ((level >= 4) and 2.9 or 2.3)) end
    conn:Disconnect()
    if banner then
        local b = banner
        TweenService:Create(b, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(b.UIStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
        task.delay(0.35, function() b:Destroy() end)
    end
    if cc then
        TweenService:Create(cc, TweenInfo.new(0.5), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE }):Play()
        task.delay(0.6, function() cc:Destroy() end)
    end
    folder:Destroy()
    hideStandEgg(eggIndex, false)
    cam.CameraType = Enum.CameraType.Custom
end

-- Fusion : les 3 pets apparaissent dans les tubes de la machine, les tubes se remplissent
-- de lumiere (on ne voit plus les pets), l'energie monte vers l'orbe, puis le pet evolue apparait.
local function playFusionCinematic(pet)
    local cam = workspace.CurrentCamera
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local machine, best = nil, math.huge
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "FusionMachine" and d:FindFirstChild("FusionBase") then
            local dist = (d.FusionBase.Position - hrp.Position).Magnitude
            if dist < best then machine, best = d, dist end
        end
    end
    if not machine then return end
    local base = machine.FusionBase.Position
    local orbPos = machine:FindFirstChild("FusionOrb") and machine.FusionOrb.Position or base + Vector3.new(0, 12, 0)
    local glow = Color3.fromRGB(200, 140, 255)
    local folder = Instance.new("Folder")
    folder.Name = "MWS_FusionFX"
    folder.Parent = workspace

    -- camera reculee, face a la machine (cote joueur)
    local away = Vector3.new(hrp.Position.X - base.X, 0, hrp.Position.Z - base.Z)
    if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
    away = away.Unit
    cam.CameraType = Enum.CameraType.Scriptable
    TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { CFrame = CFrame.lookAt(base + away * 34 + Vector3.new(0, 15, 0), base + Vector3.new(0, 6, 0)) }):Play()

    -- les 3 pets identiques, chacun dans son tube
    local info = PetBricks.measure(pet.name)
    local pods = {}
    for i = 1, 3 do
        local glass = machine:FindFirstChild("PodGlass" .. i)
        if glass then
            local m
            if info then
                m = Instance.new("Model")
                local k = math.min(2.8 / info.Hd, 2.6 / info.W, 2.6 / info.L)
                PetBricks.assemble(pet.name, { model = m, static = true, k = k, origin = CFrame.new() })
                m.WorldPivot = CFrame.new()
                m.Parent = folder
            end
            table.insert(pods, { glass = glass, model = m, pos = glass.Position })
        end
    end
    local t0 = os.clock()
    local conn = RunService.RenderStepped:Connect(function()
        local t = os.clock() - t0
        for i, pd in ipairs(pods) do
            if pd.model then
                pd.model:PivotTo(CFrame.lookAt(pd.pos, pd.pos + away) * CFrame.Angles(0, t * 1.5 + i, 0))
            end
        end
    end)
    task.wait(1.1)

    -- les tubes se remplissent de lumiere, les pets disparaissent dedans
    for _, pd in ipairs(pods) do
        local h = pd.glass.Size.X
        local r = math.min(pd.glass.Size.Y, pd.glass.Size.Z) * 0.92
        local bottom = pd.pos - Vector3.new(0, h / 2, 0)
        local fill = cinePart(folder, Vector3.new(0.05, r, r), glow, Enum.PartType.Cylinder)
        fill.Transparency = 0.15
        fill.CFrame = CFrame.new(bottom) * CFrame.Angles(0, 0, math.rad(90))
        TweenService:Create(fill, TweenInfo.new(1.3, Enum.EasingStyle.Sine), {
            Size = Vector3.new(h, r, r), CFrame = CFrame.new(pd.pos) * CFrame.Angles(0, 0, math.rad(90)),
        }):Play()
        cineEmitter(fill, SPARK_TEX, Color3.new(1, 1, 1), glow, 0.4, 25, 2, 0.8)
        if pd.model then
            for _, p in ipairs(pd.model:GetDescendants()) do
                if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(1.1), { Transparency = 1 }):Play() end
            end
        end
        pd.fill = fill
    end
    shakeCamera(0.15, 1.3)
    task.wait(1.4)

    -- l'energie monte des tubes vers l'orbe qui grossit
    local orb = cinePart(folder, Vector3.new(2, 2, 2), glow, Enum.PartType.Ball)
    orb.CFrame = CFrame.new(orbPos)
    orb.Transparency = 0.2
    TweenService:Create(orb, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(7, 7, 7) }):Play()
    for _, pd in ipairs(pods) do
        local a0 = Instance.new("Attachment")
        a0.Parent = pd.fill
        local a1 = Instance.new("Attachment")
        a1.Parent = orb
        local beam = Instance.new("Beam")
        beam.Attachment0, beam.Attachment1 = a0, a1
        beam.Color = ColorSequence.new(Color3.new(1, 1, 1), glow)
        beam.LightEmission = 1
        beam.FaceCamera = true
        beam.Width0, beam.Width1 = 0.6, 1.2
        beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        beam.TextureSpeed = 3
        beam.Parent = orb
        TweenService:Create(pd.fill, TweenInfo.new(1), { Transparency = 1 }):Play()
    end
    shakeCamera(0.35, 1)
    task.wait(1)

    -- explosion de lumiere, puis le pet evolue apparait au centre de la machine
    for _, d in ipairs(orb:GetChildren()) do if d:IsA("Beam") then d:Destroy() end end
    TweenService:Create(orb, TweenInfo.new(0.4), { Size = Vector3.new(16, 16, 16), Transparency = 1 }):Play()
    cineEmitter(orb, SPARK_TEX, Color3.new(1, 1, 1), glow, 1.2, 0, 22, 1):Emit(120)
    screenFlash(Color3.new(1, 1, 1), 0.1, 0.6)
    shakeCamera(0.8, 0.5)
    task.wait(0.3)
    conn:Disconnect()
    -- le pet evolue apparait devant la machine (bien visible), en plus grand
    revealPet(folder, base + away * 11 + Vector3.new(0, 3.5, 0), away, pet, 6.5)
    folder:Destroy()
    cam.CameraType = Enum.CameraType.Custom
end

BuyEgg.OnClientEvent:Connect(function(data)
    if data.success and data.fusion then
        gui.Enabled = false
        local ok, err = pcall(playFusionCinematic, data.pet)
        if not ok then warn("[MWS] Animation de fusion : " .. tostring(err)) end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        gui.Enabled = true
        return
    end
    if data.success then
        local pet = data.pet
        if player:GetAttribute("MWS_SetEggs") == false then
            -- parametre "Voir mes oeufs" coupe : le resultat seul, sans l'animation
            hatchFrame.Visible = true
            hatchFrame.BackgroundTransparency = 0.7
            hatchLabel.Text = pet.name .. " !"
            hatchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            hatchLabel.TextSize = 26
            task.wait(1.2)
            hatchFrame.Visible = false
            return
        end
        local style = data.fusion and "fusion" or (data.style or "base")
        local tier = HATCH_LEVEL[pet.rarity] or 1 -- l'animation depend de la rarete du pet obtenu
        local center = data.eggPos
        if not center then
            -- fusion (pas de socle) : l'oeuf apparait devant le joueur
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local cf = hrp and hrp.CFrame or workspace.CurrentCamera.CFrame
            center = cf.Position + cf.LookVector * 10 + Vector3.new(0, 1.5, 0)
        end
        gui.Enabled = false
        local ok, err = pcall(playEggCinematic, style, tier, center, data.eggIndex, pet)
        gui.Enabled = true
        if not ok then
            warn("[MWS] Animation d'oeuf : " .. tostring(err))
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            hideStandEgg(data.eggIndex, false)
            -- on enleve ce que l'animation a laisse (assombrissement, effets, nom de rarete)
            for _, holder in ipairs({ Lighting, workspace, flashGui }) do
                for _, d in ipairs(holder:GetChildren()) do
                    if d.Name:match("^MWS_Hatch") then d:Destroy() end
                end
            end
        end
    else
        hatchFrame.Visible = true
        hatchFrame.BackgroundTransparency = 0.5
        hatchLabel.Text = data.message or "Erreur"
        hatchLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        hatchLabel.TextSize = 26
        task.wait(1.5)
        hatchFrame.Visible = false
    end
end)
end -- fin du bloc des animations d'oeuf

-- ============================================================
-- BOUTIQUE ROBUX + MONDES + RACCOURCIS (boutons colonne de droite)
-- ============================================================
do
    local WHITE = Color3.new(1, 1, 1)
    local ShopBuy = remotes:WaitForChild("ShopBuy")
    local ShopInfo = remotes:WaitForChild("ShopInfo")

    local shopItems, shopMeta, clockOffset = {}, {}, 0
    local worldList = {}

    local function fmtTime(sec)
        sec = math.max(0, math.floor(sec))
        return string.format("%d:%02d", sec // 60, sec % 60)
    end

    local function fmtNum(n)
        return ((tostring(math.floor(n or 0)):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^%s+", "")))
    end

    local function makeBtn(text, x, y, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 120, 0, 45)
        b.Position = UDim2.new(0, x, 0, y)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = WHITE
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        makeCorner(b, 10)
        b.Parent = gui
        return b
    end

    -- cree un panneau centre, adapte aux petits ecrans ; renvoie (cadre, zone defilante, texte d'en-tete)
    local function makePanel(title, maxW, maxH)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.Size = UDim2.new(0.92, 0, 0.85, 0)
        f.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        f.Visible = false
        f.ZIndex = 5
        makeCorner(f, 15)
        local limit = Instance.new("UISizeConstraint")
        limit.MaxSize = Vector2.new(maxW, maxH)
        limit.Parent = f
        f.Parent = gui

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -60, 0, 40)
        t.Position = UDim2.new(0, 15, 0, 0)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = WHITE
        t.Font = Enum.Font.GothamBold
        t.TextSize = 22
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 6
        t.Parent = f

        local x = Instance.new("TextButton")
        x.Size = UDim2.new(0, 35, 0, 35)
        x.Position = UDim2.new(1, -40, 0, 5)
        x.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        x.Text = "X"
        x.TextColor3 = WHITE
        x.Font = Enum.Font.GothamBold
        x.TextSize = 18
        x.ZIndex = 6
        makeCorner(x, 8)
        x.Parent = f
        x.MouseButton1Click:Connect(function() f.Visible = false end)

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -30, 0, 28)
        status.Position = UDim2.new(0, 15, 0, 40)
        status.BackgroundTransparency = 1
        status.Text = ""
        status.TextColor3 = Color3.fromRGB(120, 220, 255)
        status.Font = Enum.Font.GothamBold
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.ZIndex = 6
        status.Parent = f

        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.new(1, -20, 1, -80)
        sc.Position = UDim2.new(0, 10, 0, 72)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 6
        sc.CanvasSize = UDim2.new(0, 0, 0, 0)
        sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sc.ZIndex = 6
        sc.Parent = f
        return f, sc, status
    end

    local shopPanel, shopScroll, shopStatus = makePanel("\u{1F6D2} Boutique", 860, 560)
    shopScroll.Size = UDim2.new(1, -126, 1, -80)
    local shopList = Instance.new("UIListLayout")
    shopList.Padding = UDim.new(0, 10)
    shopList.SortOrder = Enum.SortOrder.LayoutOrder
    shopList.Parent = shopScroll
    -- parties de la boutique + menu de droite qui fait defiler jusqu'a chacune
    local shopUI = {
        headers = {},
        sections = {
            { key = "coins",  title = "PIÈCES",   icon = "\u{1F4B0}", color = Color3.fromRGB(60, 190, 90),  columns = 3 },
            { key = "boosts", title = "POTIONS",  icon = "\u{1F9EA}", color = Color3.fromRGB(150, 90, 240), columns = 3 },
            { key = "trails", title = "TRAÎNÉES", icon = "\u{2728}",  color = Color3.fromRGB(230, 90, 190), columns = 3 },
            { key = "passes", title = "PASSES",   icon = "\u{1F451}", color = Color3.fromRGB(240, 190, 50), columns = 2 },
        },
    }
    local shopNav = Instance.new("Frame")
    shopNav.Name = "ShopNav"
    shopNav.Position = UDim2.new(1, -108, 0, 72)
    shopNav.Size = UDim2.new(0, 98, 1, -80)
    shopNav.BackgroundTransparency = 1
    shopNav.ZIndex = 6
    shopNav.Parent = shopPanel
    local shopNavList = Instance.new("UIListLayout")
    shopNavList.Padding = UDim.new(0, 8)
    shopNavList.SortOrder = Enum.SortOrder.LayoutOrder
    shopNavList.Parent = shopNav
    for i, section in ipairs(shopUI.sections) do
        local nav = Instance.new("TextButton")
        nav.LayoutOrder = i
        nav.Size = UDim2.new(1, 0, 0, 72)
        nav.BackgroundColor3 = section.color:Lerp(Color3.new(0, 0, 0), 0.45)
        nav.Text = ""
        nav.ZIndex = 7
        makeCorner(nav, 10)
        nav.Parent = shopNav
        local navIcon = Instance.new("TextLabel")
        navIcon.Size = UDim2.new(1, 0, 0, 40)
        navIcon.Position = UDim2.new(0, 0, 0, 6)
        navIcon.BackgroundTransparency = 1
        navIcon.Text = section.icon
        navIcon.TextSize = 28
        navIcon.Font = Enum.Font.GothamBold
        navIcon.ZIndex = 8
        navIcon.Parent = nav
        local navText = Instance.new("TextLabel")
        navText.Size = UDim2.new(1, 0, 0, 20)
        navText.Position = UDim2.new(0, 0, 0, 46)
        navText.BackgroundTransparency = 1
        navText.Text = section.title
        navText.TextColor3 = Color3.fromRGB(255, 255, 255)
        navText.Font = Enum.Font.GothamBlack
        navText.TextSize = 12
        navText.ZIndex = 8
        navText.Parent = nav
        nav.MouseButton1Click:Connect(function()
            local header = shopUI.headers[section.key]
            if not header then return end
            local y = header.AbsolutePosition.Y - shopScroll.AbsolutePosition.Y + shopScroll.CanvasPosition.Y
            TweenService:Create(shopScroll, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CanvasPosition = Vector2.new(0, y) }):Play()
        end)
    end

    local worldPanel, worldScroll = makePanel("\u{1F30D} Mondes", 520, 420)
    local worldLayout = Instance.new("UIListLayout")
    worldLayout.Padding = UDim.new(0, 10)
    worldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    worldLayout.Parent = worldScroll

    -- ---------- fusion ----------
    local FusionInfo = remotes:WaitForChild("FusionInfo")
    local FusionDo = remotes:WaitForChild("FusionDo")
    local fusionList = {}
    local fusionPanel, fusionScroll, fusionStatus = makePanel("Machine de fusion", 560, 460)
    local fusionLayout = Instance.new("UIListLayout")
    fusionLayout.Padding = UDim.new(0, 8)
    fusionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fusionLayout.Parent = fusionScroll

    local extraPanels = {}
    local function closeOthers(except)
        for _, p in ipairs({ panel, eggPanel, combatPanel, shopPanel, worldPanel, fusionPanel }) do
            if p ~= except then p.Visible = false end
        end
        for _, p in ipairs(extraPanels) do
            if p ~= except then p.Visible = false end
        end
    end

    -- ---------- renaissance : menu "Renaissance du Phenix" ----------
    -- disposition du modele fourni : grand titre, phrase d'accroche, 3 cases a gauche
    -- (gain, ce que tu as, prix), le Phenix et sa phrase a droite, gros bouton en bas a droite.
    -- Le nombre de variables locales reste le meme qu'avant (le script est pres de la limite de 200).
    local rbPanel, rbScroll, rbStatus = makePanel("\u{1F504} Renaissance", 640, 400)
    table.insert(extraPanels, rbPanel)
    local rbUI = {}   -- elements du menu, construits une seule fois
    local rbSig, rbCoinsLine = nil, nil

    local function rebirthChecks()
        local okNpc = (rebirthInfo.needed or 0) > 0 and (rebirthInfo.done or 0) >= (rebirthInfo.needed or 0)
        local okCoins = (state.coins or 0) >= (rebirthInfo.cost or 0)
        return okNpc, okCoins
    end

    local function buildRb()
        local INK = Color3.fromRGB(16, 8, 28)
        rbScroll.Visible = false
        rbStatus.Visible = false
        rbPanel.BackgroundColor3 = Color3.fromRGB(20, 12, 34)
        for _, child in ipairs(rbPanel:GetChildren()) do
            if child:IsA("TextLabel") then
                child.Visible = false   -- ancien petit titre
            elseif child:IsA("TextButton") then
                -- croix rouge posee sur le coin du cadre
                child.AnchorPoint = Vector2.new(0.5, 0.5)
                child.Position = UDim2.new(1, -8, 0, 8)
                child.Size = UDim2.new(0, 46, 0, 46)
                child.BackgroundColor3 = Color3.fromRGB(225, 25, 25)
                child.TextSize = 26
                child.ZIndex = 10
                local cs = Instance.new("UIStroke")
                cs.Color = INK
                cs.Thickness = 2
                cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                cs.Parent = child
            end
        end
        -- cadre violet epais avec une rangee de plots dores en haut et en bas
        local frameStroke = Instance.new("UIStroke")
        frameStroke.Color = Color3.fromRGB(150, 60, 220)
        frameStroke.Thickness = 8
        frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border   -- MWS_Style n'ajoute pas son contour noir
        frameStroke.Parent = rbPanel
        for _, top in ipairs({ true, false }) do
            local row = Instance.new("Frame")
            row.Position = top and UDim2.new(0, 20, 0, -8) or UDim2.new(0, 20, 1, 0)
            row.Size = UDim2.new(1, -40, 0, 8)
            row.BackgroundTransparency = 1
            row.ZIndex = 8
            row.Parent = rbPanel
            local rl = Instance.new("UIListLayout")
            rl.FillDirection = Enum.FillDirection.Horizontal
            rl.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly
            rl.VerticalAlignment = Enum.VerticalAlignment.Center
            rl.Parent = row
            for _ = 1, 20 do
                local stud = Instance.new("Frame")
                stud.Size = UDim2.new(0, 8, 0, 8)
                stud.BackgroundColor3 = Color3.fromRGB(255, 205, 110)
                stud.ZIndex = 8
                makeCorner(stud, 4)
                stud.Parent = row
            end
        end

        -- texte : police des titres, contour sombre
        local function text(props, outline)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.FredokaOne
            l.TextScaled = true
            l.TextColor3 = WHITE
            l.ZIndex = 7
            for k, v in pairs(props) do l[k] = v end
            local ls = Instance.new("UIStroke")
            ls.Color = INK
            ls.Thickness = outline or 2
            ls.Parent = l
            l.Parent = rbPanel
            return l
        end
        local function gradient(parent, a, b)
            local g = Instance.new("UIGradient")
            g.Rotation = 90
            g.Color = ColorSequence.new(a, b)
            g.Parent = parent
            return g
        end

        -- titre et phrase d'accroche
        local title = text({ Text = "RENAISSANCE DU PHÉNIX", Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.58, 0.11) }, 3)
        gradient(title, Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 140, 40))
        text({
            Text = "Le Phénix rend tes pets plus forts à chaque renaissance (bien sûr, tu repars de zéro).",
            Position = UDim2.fromScale(0.07, 0.165), Size = UDim2.fromScale(0.52, 0.1),
            Font = Enum.Font.GothamBold, TextWrapped = true, TextColor3 = Color3.fromRGB(255, 215, 150),
        }, 1)

        -- les 3 cases de gauche : legende, case sombre, grande valeur, petite ligne
        local function box(y, caption, narrow)
            text({ Text = caption, Position = UDim2.fromScale(0.05, y), Size = UDim2.fromScale(0.42, 0.075) }, 2)
            local b = Instance.new("Frame")
            b.Position = UDim2.fromScale(0.05, y + 0.08)
            b.Size = UDim2.fromScale(0.42, 0.15)
            b.BackgroundColor3 = Color3.fromRGB(48, 30, 74)
            b.ZIndex = 6
            makeCorner(b, 14)
            b.Parent = rbPanel
            -- narrow : texte plus etroit pour laisser la place a la pastille
            local w = narrow and 0.31 or 0.38
            local value = text({ Position = UDim2.fromScale(0.07, y + 0.085), Size = UDim2.fromScale(w, 0.095), TextColor3 = Color3.fromRGB(255, 170, 60) }, 2)
            local sub = text({ Position = UDim2.fromScale(0.07, y + 0.177), Size = UDim2.fromScale(w, 0.045), Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 205, 130) }, 1)
            return value, sub
        end
        rbUI.gain, rbUI.gainSub = box(0.28, "Chaque renaissance donne...", true)
        rbUI.have, rbUI.haveSub = box(0.51, "Tu as...")
        rbUI.cost, rbUI.costSub = box(0.74, "Pour renaître, il faut...")

        -- pastille doree a droite de la 1re case : tes gains apres la renaissance
        local badge = Instance.new("Frame")
        badge.AnchorPoint = Vector2.new(0.5, 0.5)
        badge.Position = UDim2.fromScale(0.455, 0.425)
        badge.Size = UDim2.fromScale(0.14, 0.14)
        badge.BackgroundColor3 = WHITE
        badge.ZIndex = 8
        makeCorner(badge, 12)
        badge.Parent = rbPanel
        local ar = Instance.new("UIAspectRatioConstraint")
        ar.AspectRatio = 1.3
        ar.Parent = badge
        gradient(badge, Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30))
        local bs = Instance.new("UIStroke")
        bs.Color = INK
        bs.Thickness = 3
        bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        bs.Parent = badge
        rbUI.badge = text({ Size = UDim2.fromScale(0.86, 0.8), Position = UDim2.fromScale(0.07, 0.1), ZIndex = 9 }, 2)
        rbUI.badge.Parent = badge
        text({ Text = "après", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.455, 0.5), Size = UDim2.fromScale(0.1, 0.04), Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(200, 180, 220) }, 1)

        -- le Phenix (pet du jeu) dans un halo de feu, avec sa phrase
        local halo = Instance.new("Frame")
        halo.AnchorPoint = Vector2.new(0.5, 0.5)
        halo.Position = UDim2.fromScale(0.83, 0.33)
        halo.Size = UDim2.fromScale(0.42, 0.42)
        halo.BackgroundColor3 = Color3.fromRGB(255, 120, 40)
        halo.BackgroundTransparency = 0.7
        halo.ZIndex = 6
        makeCorner(halo, 999)
        halo.Parent = rbPanel
        local har = Instance.new("UIAspectRatioConstraint")
        har.Parent = halo
        local holder = Instance.new("Frame")
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(0.83, 0.33)
        holder.Size = UDim2.fromScale(0.34, 0.6)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 7
        holder.Parent = rbPanel
        setPetViewport(newPetViewport(holder, 7), "Phenix", "Divin")
        for i, pos in ipairs({ { 0.66, 0.1 }, { 0.95, 0.14 }, { 0.93, 0.5 }, { 0.68, 0.52 }, { 0.97, 0.32 } }) do
            text({ Text = "\u{2726}", Position = UDim2.fromScale(pos[1], pos[2]), Size = UDim2.fromScale(0.035, 0.06), TextColor3 = (i % 2 == 0) and WHITE or Color3.fromRGB(255, 220, 120) }, 1)
        end
        text({
            Text = "\"RENAIS DE TES CENDRES !\"", Position = UDim2.fromScale(0.53, 0.37), Size = UDim2.fromScale(0.17, 0.12),
            Rotation = -4, TextWrapped = true, TextColor3 = Color3.fromRGB(255, 215, 90),
        }, 2)

        -- gros bouton arrondi
        local go = Instance.new("TextButton")
        go.Position = UDim2.fromScale(0.56, 0.68)
        go.Size = UDim2.fromScale(0.4, 0.21)
        go.Text = ""
        go.AutoButtonColor = false
        go.BackgroundColor3 = WHITE
        go.ZIndex = 7
        makeCorner(go, 999)
        go.Parent = rbPanel
        local gs = Instance.new("UIStroke")
        gs.Color = INK
        gs.Thickness = 4
        gs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        gs.Parent = go
        rbUI.goGrad = gradient(go, WHITE, WHITE)
        rbUI.goText = text({ Position = UDim2.fromScale(0.08, 0.2), Size = UDim2.fromScale(0.84, 0.6), ZIndex = 8 }, 3)
        rbUI.goText.Parent = go
        rbUI.go = go
        go.MouseButton1Click:Connect(function()
            local okNpc, okCoins = rebirthChecks()
            if not (okNpc and okCoins) then return end
            rbPanel.Visible = false
            RebirthRemote:FireServer()
        end)
    end
    buildRb()   -- tout de suite : le cadre est en place avant la premiere ouverture

    local function coinsText()
        return fmtNum(rebirthInfo.cost or 0) .. " coins"
    end

    local function refreshRebirth()
        if not rbUI.go then buildRb() end
        local lvl = state.rebirthLevel or 0
        local okNpc, okCoins = rebirthChecks()
        local ready = okNpc and okCoins
        local GREEN, RED = Color3.fromRGB(120, 255, 140), Color3.fromRGB(255, 110, 110)
        rbSig = table.concat({ lvl, rebirthInfo.done or 0, rebirthInfo.needed or 0, rebirthInfo.cost or 0, tostring(okCoins) }, "|")
        rbUI.gain.Text = "+50 % de coins"
        rbUI.gainSub.Text = "et +1 pet équipé toutes les 2 renaissances"
        rbUI.badge.Text = "x" .. (1 + (lvl + 1) * 0.5)
        rbUI.have.Text = lvl .. ((lvl > 1) and " renaissances" or " renaissance")
        rbUI.haveSub.Text = "tes gains actuels : x" .. (1 + lvl * 0.5)
        rbCoinsLine = rbUI.cost
        rbUI.cost.Text = coinsText()
        rbUI.cost.TextColor3 = okCoins and GREEN or RED
        rbUI.costSub.Text = (okNpc and "\u{2705}" or "\u{274C}") .. " et battre tes dresseurs (" .. (rebirthInfo.done or 0) .. "/" .. (rebirthInfo.needed or 0) .. ")"
        rbUI.costSub.TextColor3 = okNpc and GREEN or RED
        rbUI.goGrad.Color = ready and ColorSequence.new(Color3.fromRGB(255, 235, 110), Color3.fromRGB(255, 130, 40))
            or ColorSequence.new(Color3.fromRGB(120, 115, 135), Color3.fromRGB(70, 65, 85))
        rbUI.goText.Text = ready and "RENAISSANCE" or "PAS ENCORE PRÊT"
    end

    onRebirthInfo = function()
        local okNpc, okCoins = rebirthChecks()
        local ready = okNpc and okCoins
        -- le bouton s'allume quand la renaissance est possible
        rebirthButton.Text = ready and "\u{1F504} Renaissance !" or "\u{1F504} Renaissance"
        rebirthButton.BackgroundColor3 = ready and Color3.fromRGB(200, 80, 240) or Color3.fromRGB(120, 40, 160)
        if rbPanel.Visible then
            local sig = table.concat({ state.rebirthLevel or 0, rebirthInfo.done or 0, rebirthInfo.needed or 0, rebirthInfo.cost or 0, tostring(okCoins) }, "|")
            if sig ~= rbSig then
                refreshRebirth()
            elseif rbCoinsLine then
                rbCoinsLine.Text = coinsText(okCoins)
            end
        end
    end

    rebirthButton.MouseButton1Click:Connect(function()
        local show = not rbPanel.Visible
        closeOthers(show and rbPanel or nil)
        rbPanel.Visible = show
        if show then refreshRebirth() end
    end)
    onRebirthInfo()

    -- ---------- couleur de l'aura des pets fusionnes ----------
    local SetAuraColor = remotes:WaitForChild("SetAuraColor")
    local AURA_CHOICES = {
        { key = "auto", name = "Auto", color = Color3.fromRGB(80, 80, 100) },
        { key = "violet", name = "Violet", color = Color3.fromRGB(150, 60, 255) },
        { key = "bleu", name = "Bleu", color = Color3.fromRGB(40, 130, 255) },
        { key = "cyan", name = "Cyan", color = Color3.fromRGB(40, 220, 255) },
        { key = "vert", name = "Vert", color = Color3.fromRGB(50, 220, 90) },
        { key = "dore", name = "Dore", color = Color3.fromRGB(255, 190, 40) },
        { key = "rouge", name = "Rouge", color = Color3.fromRGB(255, 50, 50) },
        { key = "rose", name = "Rose", color = Color3.fromRGB(255, 80, 200) },
        { key = "blanc", name = "Blanc", color = Color3.fromRGB(235, 240, 255) },
    }
    local auraPanel, auraScroll, auraStatus = makePanel("\u{1F3A8} Couleur de l'aura", 420, 340)
    table.insert(extraPanels, auraPanel)
    local auraGrid = Instance.new("UIGridLayout")
    auraGrid.CellSize = UDim2.new(0, 110, 0, 56)
    auraGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    auraGrid.SortOrder = Enum.SortOrder.LayoutOrder
    auraGrid.Parent = auraScroll

    local function refreshAura()
        for _, c in ipairs(auraScroll:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        auraStatus.Text = "Pour tes pets fusionnés"
        local cur = state.auraColor or "auto"
        for i, c in ipairs(AURA_CHOICES) do
            local b = Instance.new("TextButton")
            b.LayoutOrder = i
            b.BackgroundColor3 = c.color
            b.Text = c.name
            b.TextColor3 = (c.key == "blanc" or c.key == "cyan") and Color3.fromRGB(30, 30, 40) or WHITE
            b.Font = Enum.Font.GothamBold
            b.TextSize = 15
            b.ZIndex = 6
            makeCorner(b, 10)
            if c.key == "auto" then
                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 200, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
                })
                grad.Parent = b
            end
            if cur == c.key then
                local st = Instance.new("UIStroke")
                st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                st.Color = WHITE
                st.Thickness = 3
                st.Parent = b
            end
            b.Parent = auraScroll
            b.MouseButton1Click:Connect(function()
                state.auraColor = c.key
                SetAuraColor:FireServer(c.key)
                refreshAura()
            end)
        end
    end

    local auraBtn = Instance.new("TextButton")
    auraBtn.Size = UDim2.new(0, 110, 0, 35)
    auraBtn.Position = UDim2.new(1, -295, 0, 5)
    auraBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
    auraBtn.Text = "\u{1F3A8} Aura"
    auraBtn.TextColor3 = WHITE
    auraBtn.Font = Enum.Font.GothamBold
    auraBtn.TextSize = 15
    makeCorner(auraBtn, 8)
    auraBtn.Parent = panel
    auraBtn.MouseButton1Click:Connect(function()
        closeOthers(auraPanel)
        auraPanel.Visible = true
        refreshAura()
    end)

    -- ---------- boutique ----------
    local function refreshShop()
        local keepY = shopScroll.CanvasPosition.Y
        -- petit ecran : menu plus etroit et cartes en une colonne, pour garder les textes lisibles
        -- taille avant la reduction de MWS_MobileHud (UIScale "MWS_Fit") sur telephone
        local fitScale = shopScroll.Parent:FindFirstChild("MWS_Fit")
        local shrink = fitScale and fitScale.Scale or 1
        local panelWidth = shopScroll.Parent.AbsoluteSize.X / shrink
        local panelHeight = shopScroll.Parent.AbsoluteSize.Y / shrink
        local narrow = panelWidth < 520
        local nav = shopScroll.Parent:FindFirstChild("ShopNav")
        local navWidth = narrow and 70 or 98
        nav.Size = UDim2.new(0, navWidth, 1, -80)
        nav.Position = UDim2.new(1, -navWidth - 8, 0, 72)
        shopScroll.Size = UDim2.new(1, -navWidth - 26, 1, -80)
        -- les onglets se partagent la hauteur disponible, sans depasser du panneau
        local tabCount = #shopUI.sections
        local tabHeight = math.min(narrow and 62 or 72, math.floor((panelHeight - 80 - 8 * (tabCount - 1)) / tabCount))
        for _, navButton in ipairs(nav:GetChildren()) do
            if navButton:IsA("TextButton") then
                navButton.Size = UDim2.new(1, 0, 0, tabHeight)
                for _, navLabel in ipairs(navButton:GetChildren()) do
                    if navLabel:IsA("TextLabel") then
                        -- icone en haut, titre en bas ; les tailles suivent la hauteur de l'onglet
                        local limit = navLabel:FindFirstChildOfClass("UITextSizeConstraint")
                        if not limit then
                            navLabel:SetAttribute("IsIcon", navLabel.TextSize >= 20)
                            limit = Instance.new("UITextSizeConstraint")
                            limit.MaxTextSize = navLabel.TextSize
                            limit.Parent = navLabel
                            navLabel.TextScaled = true
                        end
                        if navLabel:GetAttribute("IsIcon") then
                            navLabel.Position = UDim2.new(0, 0, 0.06, 0)
                            navLabel.Size = UDim2.new(1, 0, 0.52, 0)
                        else
                            limit.MaxTextSize = narrow and 10 or 12
                            navLabel.Position = UDim2.new(0, 0, 0.62, 0)
                            navLabel.Size = UDim2.new(1, 0, 0.28, 0)
                        end
                    end
                end
            end
        end
        for _, child in ipairs(shopScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        shopUI.headers = {}
        for sectionIndex, section in ipairs(shopUI.sections) do
            local items = {}
            for _, item in ipairs(shopItems) do
                if (item.section or "boosts") == section.key then table.insert(items, item) end
            end
            if section.key == "boosts" then
                -- les potions du joueur passent avant les lots a acheter
                for i, potion in ipairs(shopMeta.potions or {}) do
                    table.insert(items, i, {
                        inventory = true, key = potion.key, model = potion.model, name = potion.name, icon = potion.icon,
                        desc = potion.effect .. "\nTu en as " .. potion.count, count = potion.count,
                    })
                end
            end
            if #items > 0 then
                local header = Instance.new("TextLabel")
                header.LayoutOrder = sectionIndex * 2
                header.Size = UDim2.new(1, -10, 0, 34)
                header.BackgroundTransparency = 1
                header.Text = "— " .. section.title .. " —"
                header.TextColor3 = section.color:Lerp(WHITE, 0.25)
                header.Font = Enum.Font.FredokaOne
                header.TextSize = 24
                header.TextStrokeTransparency = 0.5
                header.ZIndex = 7
                header.Parent = shopScroll
                shopUI.headers[section.key] = header

                local group = Instance.new("Frame")
                group.LayoutOrder = sectionIndex * 2 + 1
                group.Size = UDim2.new(1, -10, 0, 0)
                group.AutomaticSize = Enum.AutomaticSize.Y
                group.BackgroundTransparency = 1
                group.ZIndex = 6
                group.Parent = shopScroll
                local grid = Instance.new("UIGridLayout")
                local columns = section.columns
                if narrow then columns = 1 elseif panelWidth < 720 then columns = 2 end
                grid.CellSize = UDim2.new(1 / columns, -8, 0, 226)
                grid.CellPadding = UDim2.new(0, 8, 0, 8)
                grid.SortOrder = Enum.SortOrder.LayoutOrder
                grid.Parent = group

                for i, item in ipairs(items) do
                    -- carte construite par MWS_ShopCards : objet 3D en briques toujours entier et centre
                    require(ReplicatedStorage:WaitForChild("MWS_ShopCards")).card(group, item, section, i, function(clicked)
                        if clicked.inventory then
                            if clicked.count > 0 then remotes:WaitForChild("UsePotion"):FireServer(clicked.key) end
                        elseif clicked.owned and clicked.trail then
                            remotes:WaitForChild("SetTrail"):FireServer(clicked.equipped and "" or clicked.key)
                        elseif not clicked.owned then
                            ShopBuy:FireServer(clicked.key)
                        end
                    end)
                end
            end
        end
        shopScroll.CanvasPosition = Vector2.new(0, keepY)
    end

    shopScroll.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if shopScroll.Parent.Visible then refreshShop() end
    end)

    ShopInfo.OnClientEvent:Connect(function(list, meta)
        shopItems = list or {}
        shopMeta = meta or {}
        if shopMeta.now then clockOffset = shopMeta.now - os.time() end
        if shopPanel.Visible then refreshShop() end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if shopPanel.Visible then
                local now = os.time() + clockOffset
                local parts = {}
                if (shopMeta.speedUntil or 0) > now then
                    table.insert(parts, "\u{26A1} Vitesse " .. fmtTime(shopMeta.speedUntil - now))
                end
                if (shopMeta.luckUntil or 0) > now then
                    table.insert(parts, "\u{1F340} Chance " .. fmtTime(shopMeta.luckUntil - now))
                end
                shopStatus.Text = (#parts > 0) and ("Bonus actifs : " .. table.concat(parts, "   |   ")) or "Aucun bonus actif"
            end
        end
    end)

    local function refreshFusion()
        for _, c in ipairs(fusionScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        fusionStatus.Text = "3 pets pareils = 1 pet x4  (3 fusions max)"
        for i, g in ipairs(fusionList) do
            local row = Instance.new("Frame")
            row.LayoutOrder = i
            row.Size = UDim2.new(1, -8, 0, 76)
            row.BackgroundColor3 = (g.count >= 3 and not g.maxed) and Color3.fromRGB(45, 55, 80) or Color3.fromRGB(38, 38, 50)
            row.ZIndex = 6
            makeCorner(row, 10)
            row.Parent = fusionScroll

            local ic = Instance.new("Frame")
            ic.Size = UDim2.new(0, 56, 0, 56)
            ic.Position = UDim2.new(0, 10, 0, 10)
            ic.BackgroundColor3 = colorFromData(g.color)
            ic.ZIndex = 7
            makeCorner(ic, 8)
            ic.Parent = row
            setPetViewport(newPetViewport(ic, 8), g.name, g.rarity)

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -230, 0, 24)
            nameL.Position = UDim2.new(0, 76, 0, 10)
            nameL.BackgroundTransparency = 1
            nameL.Text = g.name .. string.rep("+", g.tier) .. "   x" .. g.count
            nameL.TextColor3 = RARITY_COLORS[g.rarity] or WHITE
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 16
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.ZIndex = 7
            nameL.Parent = row

            local infoL = Instance.new("TextLabel")
            infoL.Size = UDim2.new(1, -230, 0, 34)
            infoL.Position = UDim2.new(0, 76, 0, 36)
            infoL.BackgroundTransparency = 1
            infoL.TextWrapped = true
            infoL.TextXAlignment = Enum.TextXAlignment.Left
            infoL.TextYAlignment = Enum.TextYAlignment.Top
            infoL.Font = Enum.Font.Gotham
            infoL.TextSize = 13
            infoL.ZIndex = 7
            if g.maxed then
                infoL.Text = "Niveau maximum (+" .. fmtNum(g.income) .. "/s)"
                infoL.TextColor3 = Color3.fromRGB(255, 215, 100)
            else
                infoL.Text = "+" .. fmtNum(g.income) .. "/s  ->  +" .. fmtNum(g.nextIncome) .. "/s"
                infoL.TextColor3 = Color3.fromRGB(120, 255, 160)
            end
            infoL.Parent = row

            local go = Instance.new("TextButton")
            go.Size = UDim2.new(0, 120, 0, 40)
            go.Position = UDim2.new(1, -132, 0.5, -20)
            go.Font = Enum.Font.GothamBold
            go.TextSize = 15
            go.TextColor3 = WHITE
            go.ZIndex = 7
            makeCorner(go, 8)
            local can = g.count >= 3 and not g.maxed
            go.Text = g.maxed and "Max" or (can and "Fusionner" or (g.count .. "/3"))
            go.BackgroundColor3 = can and Color3.fromRGB(150, 90, 220) or Color3.fromRGB(80, 80, 95)
            go.Parent = row
            go.MouseButton1Click:Connect(function()
                if can then FusionDo:FireServer(g.name, g.tier) end
            end)
        end
        if #fusionList == 0 then
            fusionStatus.Text = "Aucun pet : achète des oeufs !"
        end
    end

    FusionInfo.OnClientEvent:Connect(function(list, open)
        fusionList = list or {}
        if open then
            closeOthers(fusionPanel)
            fusionPanel.Visible = true
        end
        if fusionPanel.Visible then refreshFusion() end
    end)

    -- ---------- mondes ----------
    local function refreshWorlds()
        for _, c in ipairs(worldScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, w in ipairs(worldList) do
            local row = Instance.new("Frame")
            row.LayoutOrder = i
            row.Size = UDim2.new(1, -8, 0, 80)
            row.BackgroundColor3 = w.unlocked and Color3.fromRGB(35, 55, 45) or Color3.fromRGB(55, 40, 40)
            row.ZIndex = 6
            makeCorner(row, 12)
            row.Parent = worldScroll

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -150, 0, 30)
            nameL.Position = UDim2.new(0, 14, 0, 10)
            nameL.BackgroundTransparency = 1
            nameL.Text = "Monde " .. i .. " - " .. (w.name or "")
            nameL.TextColor3 = WHITE
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 17
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.ZIndex = 7
            nameL.Parent = row

            local infoL = Instance.new("TextLabel")
            infoL.Size = UDim2.new(1, -150, 0, 32)
            infoL.Position = UDim2.new(0, 14, 0, 42)
            infoL.BackgroundTransparency = 1
            local needRb = w.rebirth or 0
            local myRb = state.rebirthLevel or 0
            local infoText = "Debloque"
            if not w.unlocked then
                infoText = "Prix : " .. fmtNum(w.unlock) .. " coins (une fois)"
                if needRb > 0 then
                    infoText = infoText .. "  +  " .. needRb .. " renaissance(s) (tu en as " .. myRb .. ")"
                end
            end
            infoL.Text = infoText
            infoL.TextColor3 = w.unlocked and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 200, 120)
            infoL.Font = Enum.Font.Gotham
            infoL.TextSize = 12
            infoL.TextWrapped = true
            infoL.TextYAlignment = Enum.TextYAlignment.Top
            infoL.TextXAlignment = Enum.TextXAlignment.Left
            infoL.ZIndex = 7
            infoL.Parent = row

            local go = Instance.new("TextButton")
            go.Size = UDim2.new(0, 120, 0, 40)
            go.Position = UDim2.new(1, -132, 0.5, -20)
            go.BackgroundColor3 = w.unlocked and Color3.fromRGB(50, 150, 90) or Color3.fromRGB(200, 140, 40)
            go.Text = w.unlocked and "Y aller" or "Debloquer"
            go.TextColor3 = WHITE
            go.Font = Enum.Font.GothamBold
            go.TextSize = 15
            go.ZIndex = 7
            makeCorner(go, 8)
            go.Parent = row
            go.MouseButton1Click:Connect(function()
                WorldTeleport:FireServer(i)
                worldPanel.Visible = false
            end)
        end
    end

    WorldInfoRemote.OnClientEvent:Connect(function(list)
        worldList = list or {}
        if worldPanel.Visible then refreshWorlds() end
    end)

    -- ---------- progression : tutoriel, pokedex, quetes, classement ----------
    local MetaInfo = remotes:WaitForChild("MetaInfo")
    local MetaAction = remotes:WaitForChild("MetaAction")
    local BoardInfo = remotes:WaitForChild("BoardInfo")
    local GOLDC = Color3.fromRGB(255, 220, 100)
    local meta, metaAt = {}, os.clock()
    local boardData

    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end

    local function clearFrames(sc)
        for _, c in ipairs(sc:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function fmtShort(n)
        n = n or 0
        if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
        if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
        if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
        return tostring(math.floor(n))
    end

    local function fmtClock(sec)
        sec = math.max(0, math.floor(sec))
        return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
    end

    local function listLayout(parent, pad)
        return new("UIListLayout", { Padding = UDim.new(0, pad), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
    end

    local questPanel, questScroll, questStatus = makePanel("Quêtes", 520, 540)
    listLayout(questScroll, 10)
    do
        -- style du menu Quetes : fond noir, bord bleu a plots de briques, grand titre degrade
        questPanel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
        new("UIStroke", { Color = Color3.fromRGB(40, 140, 235), Thickness = 6 }, questPanel)
        for _, child in ipairs(questPanel:GetChildren()) do
            if child:IsA("TextLabel") then
                child.Visible = false   -- ancien petit titre et sous-titre
            elseif child:IsA("TextButton") then
                -- croix rouge sur le coin, comme une etiquette
                child.Position = UDim2.new(1, -30, 0, -16)
                child.Size = UDim2.new(0, 46, 0, 46)
                child.BackgroundColor3 = Color3.fromRGB(225, 20, 20)
                child.TextSize = 26
                child.ZIndex = 9
                new("UIStroke", { Color = Color3.fromRGB(10, 14, 24), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, child)
            end
        end
        for _, y in ipairs({ -6, 0 }) do
            local studs = new("Frame", {
                Position = (y < 0) and UDim2.new(0, 14, 0, -7) or UDim2.new(0, 14, 1, -1),
                Size = UDim2.new(1, -28, 0, 8), BackgroundTransparency = 1, ZIndex = 8,
            }, questPanel)
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }, studs)
            for _ = 1, 18 do
                makeCorner(new("Frame", { Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.fromRGB(16, 70, 150), ZIndex = 8 }, studs), 4)
            end
        end
        local bigTitle = new("TextLabel", {
            Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1,
            Text = "Quêtes", TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 48, ZIndex = 7,
        }, questPanel)
        new("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(110, 205, 255), Color3.fromRGB(25, 110, 225)),
        }, bigTitle)
        new("UIStroke", { Color = Color3.fromRGB(8, 28, 70), Thickness = 3 }, bigTitle)
        questScroll.Position = UDim2.new(0, 14, 0, 76)
        questScroll.Size = UDim2.new(1, -28, 1, -90)
        questScroll.ScrollBarThickness = 4
    end
    local boardPanel, boardScroll, boardStatus = makePanel("Classement du serveur", 480, 460)
    listLayout(boardScroll, 8)
    table.insert(extraPanels, questPanel)
    table.insert(extraPanels, boardPanel)

    -- ----- quetes + recompense quotidienne -----
    local dailyBtn
    local function refreshQuests()
        clearFrames(questScroll)
        dailyBtn = nil
        if not meta.daily then questStatus.Text = "Chargement..." return end
        local d = meta.daily
        local left = (meta.secondsLeft or 0) - (os.clock() - metaAt)
        local GREEN, GOLD = Color3.fromRGB(70, 230, 90), Color3.fromRGB(255, 200, 40)
        local INK = Color3.fromRGB(10, 14, 24)
        local order = 0
        local function place(height, props)
            order = order + 1
            props.LayoutOrder = order
            props.Size = UDim2.new(1, -8, 0, height)
            props.ZIndex = 6
            return new("Frame", props, questScroll)
        end
        local function inked(label, thickness)
            new("UIStroke", { Color = INK, Thickness = thickness or 2 }, label)
            return label
        end
        local function timerText(seconds)
            local s = math.max(0, math.floor(seconds))
            if s >= 86400 then
                return string.format("%dj %dh %dm", s // 86400, (s % 86400) // 3600, (s % 3600) // 60)
            end
            return string.format("%dh %dm %ds", s // 3600, (s % 3600) // 60, s % 60)
        end
        -- titre de partie en grosses lettres, minuteur a droite (mis a jour plus bas)
        local function section(title, color, timerName, seconds)
            local head = place(46, { BackgroundTransparency = 1 })
            local titleLabel = inked(new("TextLabel", {
                Size = UDim2.new(0.66, 0, 1, 0), BackgroundTransparency = 1, Text = title, TextColor3 = color,
                Font = Enum.Font.FredokaOne, TextSize = 32, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
            }, head), 3)
            new("UITextSizeConstraint", { MaxTextSize = 32 }, titleLabel)
            inked(new("TextLabel", {
                Name = timerName or "QuestTimer", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.34, 0, 1, 0), BackgroundTransparency = 1, Text = timerText(seconds or left), TextColor3 = color,
                Font = Enum.Font.FredokaOne, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
            }, head))
        end
        local function note(text)
            local f = place(36, { BackgroundTransparency = 1 })
            new("TextLabel", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(120, 122, 138),
                Font = Enum.Font.FredokaOne, TextSize = 17, TextWrapped = true, ZIndex = 7,
            }, f)
        end
        local function card(height)
            local f = place(height, { BackgroundColor3 = Color3.fromRGB(30, 32, 44) })
            makeCorner(f, 14)
            return f
        end
        local function claimButton(parent, text, onClick)
            local b = new("TextButton", {
                AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.new(0, 150, 0, 34),
                BackgroundColor3 = Color3.fromRGB(0, 190, 90), Text = text, TextColor3 = WHITE,
                Font = Enum.Font.FredokaOne, TextSize = 18, ZIndex = 8,
            }, parent)
            makeCorner(b, 10)
            new("UIStroke", { Color = INK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
            inked(b)
            b.MouseButton1Click:Connect(onClick)
            return b
        end

        -- ----- cadeau du jour : 7 jours d'affilee -----
        section("CADEAU DU JOUR", GREEN)
        local gift = card(d.claimed and 84 or 132)
        local row = new("Frame", { Size = UDim2.new(1, -20, 0, 62), Position = UDim2.new(0, 10, 0, 11), BackgroundTransparency = 1, ZIndex = 7 }, gift)
        for i = 1, 7 do
            local taken = i < d.index or (i == d.index and d.claimed)
            local today = i == d.index and not d.claimed
            local box = new("Frame", {
                Size = UDim2.new(1 / 7, -6, 1, 0), Position = UDim2.new((i - 1) / 7, 3, 0, 0),
                BackgroundColor3 = today and Color3.fromRGB(230, 165, 30) or (taken and Color3.fromRGB(35, 120, 60) or Color3.fromRGB(46, 48, 64)),
                ZIndex = 8,
            }, row)
            makeCorner(box, 8)
            if today then new("UIStroke", { Color = Color3.fromRGB(255, 235, 140), Thickness = 2 }, box) end
            inked(new("TextLabel", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 5), BackgroundTransparency = 1, Text = "J" .. i, TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 15, ZIndex = 9 }, box))
            inked(new("TextLabel", {
                Size = UDim2.new(1, -4, 0, 22), Position = UDim2.new(0, 2, 0, 32), BackgroundTransparency = 1,
                Text = taken and "\u{2714}" or fmtShort(d.rewards[i]), TextColor3 = taken and WHITE or Color3.fromRGB(140, 255, 160),
                Font = Enum.Font.FredokaOne, TextSize = 14, TextScaled = true, ZIndex = 9,
            }, box))
        end
        if not d.claimed then
            dailyBtn = claimButton(gift, "Récupérer +" .. fmtShort(d.rewards[d.index]), function() MetaAction:FireServer("daily") end)
            dailyBtn.AnchorPoint = Vector2.new(0.5, 1)
            dailyBtn.Position = UDim2.new(0.5, 0, 1, -10)
            dailyBtn.Size = UDim2.new(1, -20, 0, 40)
        end

        -- ----- quetes du jour -----
        section("QUÊTES DU JOUR", GOLD)
        local remaining = 0
        for _, q in ipairs(meta.quests or {}) do
            if not q.claimed then
                remaining = remaining + 1
                local done = q.prog >= q.need
                local c = card(112)
                inked(new("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 14, 0, 8), BackgroundTransparency = 1,
                    Text = q.text, TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 19,
                    TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, ZIndex = 7,
                }, c))
                local bar = new("Frame", { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 14, 0, 40), BackgroundColor3 = Color3.fromRGB(52, 54, 70), ZIndex = 7 }, c)
                makeCorner(bar, 8)
                local fill = new("Frame", {
                    Size = UDim2.new(math.clamp(q.prog / q.need, 0, 1), 0, 1, 0),
                    BackgroundColor3 = done and GOLD or Color3.fromRGB(80, 200, 110), ZIndex = 8,
                }, bar)
                makeCorner(fill, 8)
                inked(new("TextLabel", {
                    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = math.min(q.prog, q.need) .. " / " .. q.need,
                    TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 16, ZIndex = 9,
                }, bar))
                -- recompense : pastille verte
                local pill = new("Frame", {
                    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.new(0, 150, 0, 34),
                    BackgroundColor3 = Color3.fromRGB(40, 175, 70), ZIndex = 7,
                }, c)
                makeCorner(pill, 10)
                new("UIStroke", { Color = Color3.fromRGB(150, 255, 120), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill)
                inked(new("TextLabel", {
                    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "\u{1F4B0} +" .. fmtShort(q.reward),
                    TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 17, ZIndex = 8,
                }, pill))
                if done then
                    claimButton(c, "Récupérer !", function() MetaAction:FireServer("quest", q.id) end)
                end
            end
        end
        if remaining == 0 then note("Toutes les quêtes du jour sont terminées !") end

        -- ----- quetes de la semaine : plus longues, coins + 1 potion -----
        local PURPLE = Color3.fromRGB(190, 120, 255)
        section("QUÊTES DE LA SEMAINE", PURPLE, "WeekTimer", (meta.weekSecondsLeft or 0) - (os.clock() - metaAt))
        local weekLeft = 0
        for _, q in ipairs(meta.weekly or {}) do
            if not q.claimed then
                weekLeft = weekLeft + 1
                local done = q.prog >= q.need
                local c = card(112)
                inked(new("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 14, 0, 8), BackgroundTransparency = 1,
                    Text = q.text, TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 19,
                    TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, ZIndex = 7,
                }, c))
                local bar = new("Frame", { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 14, 0, 40), BackgroundColor3 = Color3.fromRGB(52, 54, 70), ZIndex = 7 }, c)
                makeCorner(bar, 8)
                local fill = new("Frame", {
                    Size = UDim2.new(math.clamp(q.prog / q.need, 0, 1), 0, 1, 0),
                    BackgroundColor3 = done and GOLD or PURPLE, ZIndex = 8,
                }, bar)
                makeCorner(fill, 8)
                inked(new("TextLabel", {
                    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = math.min(q.prog, q.need) .. " / " .. q.need,
                    TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 16, ZIndex = 9,
                }, bar))
                -- deux recompenses : les coins (vert) et une potion (violet)
                for k, reward in ipairs({
                    { text = "\u{1F4B0} +" .. fmtShort(q.reward), color = Color3.fromRGB(40, 175, 70), edge = Color3.fromRGB(150, 255, 120) },
                    { text = "\u{1F9EA} +1 potion", color = Color3.fromRGB(130, 70, 210), edge = Color3.fromRGB(215, 170, 255) },
                }) do
                    local pill = new("Frame", {
                        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14 + (k - 1) * 128, 1, -10), Size = UDim2.new(0, 120, 0, 34),
                        BackgroundColor3 = reward.color, ZIndex = 7,
                    }, c)
                    makeCorner(pill, 10)
                    new("UIStroke", { Color = reward.edge, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill)
                    inked(new("TextLabel", {
                        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = reward.text,
                        TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 16, ZIndex = 8,
                    }, pill))
                end
                if done then
                    local b = claimButton(c, "Récupérer !", function() MetaAction:FireServer("weekly", q.id) end)
                    b.Size = UDim2.new(0, 120, 0, 34)
                end
            end
        end
        if weekLeft == 0 then note("Toutes les quêtes de la semaine sont terminées !") end
    end

    -- ----- classement -----
    local function refreshBoard()
        clearFrames(boardScroll)
        if not boardData then boardStatus.Text = "Chargement..." return end
        boardStatus.Text = "Classé par revenu/s"
        for i, p in ipairs(boardData) do
            local r = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = (i == 1) and Color3.fromRGB(70, 60, 30) or Color3.fromRGB(40, 40, 58), ZIndex = 6 }, boardScroll)
            makeCorner(r, 10)
            new("TextLabel", { Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "#" .. i, TextColor3 = GOLDC, Font = Enum.Font.GothamBlack, TextSize = 18, ZIndex = 7 }, r)
            new("TextLabel", { Size = UDim2.new(1, -230, 0, 24), Position = UDim2.new(0, 52, 0, 6), BackgroundTransparency = 1, Text = p.name, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 7 }, r)
            new("TextLabel", { Size = UDim2.new(1, -230, 0, 16), Position = UDim2.new(0, 52, 0, 30), BackgroundTransparency = 1, Text = p.pets .. " pets  |  renaissance " .. p.rebirth, TextColor3 = Color3.fromRGB(180, 180, 200), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }, r)
            new("TextLabel", { Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(1, -168, 0, 0), BackgroundTransparency = 1, Text = "+" .. fmtShort(p.income) .. "/s", TextColor3 = Color3.fromRGB(100, 255, 100), Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7 }, r)
        end
    end

    BoardInfo.OnClientEvent:Connect(function(rows)
        boardData = rows
        if boardPanel.Visible then refreshBoard() end
    end)

    -- ----- objectif guide (en haut a droite) + fleche dans le monde -----
    local tracker = new("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 72), Size = UDim2.new(0, 270, 0, 74),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), BackgroundTransparency = 0.1, Visible = false, ZIndex = 4,
    }, gui)
    makeCorner(tracker, 10)
    new("UIStroke", { Color = GOLDC, Thickness = 1.5 }, tracker)
    local trkTitle = new("TextLabel", { Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 4), BackgroundTransparency = 1, Text = "", TextColor3 = GOLDC, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, tracker)
    local trkText = new("TextLabel", { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 0, 22), BackgroundTransparency = 1, Text = "", TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5 }, tracker)
    local trkBar = new("Frame", { Size = UDim2.new(1, -16, 0, 6), Position = UDim2.new(0, 8, 1, -12), BackgroundColor3 = Color3.fromRGB(55, 55, 75), ZIndex = 5 }, tracker)
    makeCorner(trkBar, 3)
    local trkFill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 200, 120), ZIndex = 6 }, trkBar)
    makeCorner(trkFill, 3)

    local marker = new("Part", {
        Name = "MWS_GuideMarker", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
        Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Material = Enum.Material.Neon, Color = GOLDC, Transparency = 0.15,
    })
    local markBB = new("BillboardGui", { Size = UDim2.new(0, 140, 0, 36), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, MaxDistance = 1000, Adornee = marker }, marker)
    local markLbl = new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", TextColor3 = GOLDC, Font = Enum.Font.GothamBlack, TextSize = 16, TextStrokeTransparency = 0.3 }, markBB)

    local questBtn
    local function hasClaim()
        if meta.daily and not meta.daily.claimed then return true end
        for _, q in ipairs(meta.quests or {}) do
            if not q.claimed and q.prog >= q.need then return true end
        end
        for _, q in ipairs(meta.weekly or {}) do
            if not q.claimed and q.prog >= q.need then return true end
        end
        return false
    end

    local function updateTracker()
        local t = meta.tut
        if t then
            tracker.Visible = true
            trkTitle.Text = "Tutoriel  " .. t.step .. "/" .. t.total .. "   +" .. fmtNum(t.reward) .. " coins"
            trkText.Text = t.text .. ((t.need > 1) and ("  (" .. t.prog .. "/" .. t.need .. ")") or "")
            trkFill.Size = UDim2.new(math.clamp(t.prog / t.need, 0, 1), 0, 1, 0)
        else
            tracker.Visible = false
        end
        if questBtn then
            local c = hasClaim()
            questBtn.Text = c and "\u{1F4C5} Quetes !" or "\u{1F4C5} Quetes"
            questBtn.BackgroundColor3 = c and Color3.fromRGB(220, 150, 30) or Color3.fromRGB(150, 90, 200)
        end
    end

    MetaInfo.OnClientEvent:Connect(function(data)
        meta = data or {}
        metaAt = os.clock()
        updateTracker()
        if questPanel.Visible then refreshQuests() end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)
            local t = meta.tut
            local target = t and t.target
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            marker.Parent = nil -- remplace par le guide en pointilles (plus bas)
            if questPanel.Visible then
                -- minuteurs des parties du menu Quetes
                local s = math.max(0, math.floor((meta.secondsLeft or 0) - (os.clock() - metaAt)))
                local text = string.format("%dh %dm %ds", s // 3600, (s % 3600) // 60, s % 60)
                local w = math.max(0, math.floor((meta.weekSecondsLeft or 0) - (os.clock() - metaAt)))
                local weekText = string.format("%dj %dh %dm", w // 86400, (w % 86400) // 3600, (w % 3600) // 60)
                for _, item in ipairs(questScroll:GetDescendants()) do
                    if item.Name == "QuestTimer" then item.Text = text
                    elseif item.Name == "WeekTimer" then item.Text = weekText end
                end
            end
        end
    end)

    -- ----- boutons du menu de droite -----
    questBtn = makeBtn("\u{1F4C5} Quetes", 145, 300, Color3.fromRGB(150, 90, 200))
    local boardBtn = makeBtn("\u{1F3C6} Top", 145, 355, Color3.fromRGB(190, 140, 40))

    questBtn.MouseButton1Click:Connect(function()
        local show = not questPanel.Visible
        closeOthers(show and questPanel or nil)
        questPanel.Visible = show
        if show then
            refreshQuests()
            MetaAction:FireServer("meta")
        end
    end)
    boardBtn.MouseButton1Click:Connect(function()
        local show = not boardPanel.Visible
        closeOthers(show and boardPanel or nil)
        boardPanel.Visible = show
        if show then
            refreshBoard()
            MetaAction:FireServer("board")
        end
    end)
    MetaAction:FireServer("meta")

    -- ---------- boutons ----------
    local shopBtn = makeBtn("\u{1F6D2} Shop", 145, 80, Color3.fromRGB(0, 150, 90))
    local worldsBtn = makeBtn("\u{1F30D} Mondes", 145, 135, Color3.fromRGB(50, 130, 200))
    local boostBtn = makeBtn("\u{26A1} Boost 500", 145, 190, Color3.fromRGB(60, 160, 200))

    -- ---------- tutoriel guide : fleches en pointilles + menu verrouille ----------
    -- Monde : une ligne de tirets au sol du joueur jusqu'a la cible ; les tirets apparaissent
    -- un par un, restent, puis s'effacent et recommencent. 3 chevrons tombent sur la cible.
    -- Menu : une fleche en pointilles montre le bouton a utiliser ; les autres sont verrouilles.
    local GUIDE = Color3.fromRGB(255, 215, 70)
    local guideFolder = Instance.new("Folder")
    guideFolder.Name = "MWS_TutGuide"
    local function guidePart(size)
        return new("Part", {
            Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
            Material = Enum.Material.Neon, Color = GUIDE, Size = size, Transparency = 1,
        }, guideFolder)
    end
    local DASHES = 26
    local dashes = {}
    for k = 1, DASHES do dashes[k] = guidePart(Vector3.new(0.6, 0.12, 1.3)) end
    local chevrons = {}
    for k = 1, 3 do chevrons[k] = { guidePart(Vector3.new(0.5, 0.5, 2.4)), guidePart(Vector3.new(0.5, 0.5, 2.4)) } end
    local tagPart = guidePart(Vector3.new(0.2, 0.2, 0.2))
    local tagBB = new("BillboardGui", { Size = UDim2.new(0, 170, 0, 34), AlwaysOnTop = true, MaxDistance = 1000, Adornee = tagPart }, tagPart)
    local tagLbl = new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", TextColor3 = GUIDE, Font = Enum.Font.GothamBlack, TextSize = 17, TextStrokeTransparency = 0.3 }, tagBB)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    -- fleche du menu : pointe de fleche + 5 pointilles qui clignotent vers le bouton
    local uiGuide = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 160, 0, 30), ZIndex = 40, Visible = false }, gui)
    local uiHead = new("Frame", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 6, 0.5, -10), Rotation = 45, BackgroundColor3 = GUIDE, BorderSizePixel = 0, ZIndex = 41 }, uiGuide)
    new("UIStroke", { Color = Color3.fromRGB(90, 60, 0), Thickness = 1.5 }, uiHead)
    local uiDots = {}
    for k = 1, 5 do
        uiDots[k] = new("Frame", { Size = UDim2.new(0, 14, 0, 7), Position = UDim2.new(0, 22 + k * 20, 0.5, -3), BackgroundColor3 = GUIDE, BorderSizePixel = 0, ZIndex = 41 }, uiGuide)
        makeCorner(uiDots[k], 4)
    end
    local uiHint = new("TextLabel", { Size = UDim2.new(0, 96, 0, 20), Position = UDim2.new(0, 30, 1, 2), BackgroundColor3 = Color3.fromRGB(25, 25, 35), BackgroundTransparency = 0.15, Text = "Clique ici !", TextColor3 = GUIDE, Font = Enum.Font.GothamBlack, TextSize = 14, TextStrokeTransparency = 0.3, ZIndex = 41 }, uiGuide)
    makeCorner(uiHint, 6)
    local glowTarget, glowStroke

    local function findButton(root, pred)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextButton") and d.Visible and pred(d) then return d end
        end
        return nil
    end
    local function uiTarget(kind)
        if kind == "pets" then
            if panel.Visible then
                return findButton(panel, function(b) return b.Text == "Equiper" end) or bestPetsBtn
            end
            return invButton
        elseif kind == "combat" then
            if combatPanel.Visible then
                return findButton(combatPanel, function(b) return b.Text:find("Combattre") ~= nil end) or combatButton
            end
            return combatButton
        end
        return nil
    end

    -- boutons verrouilles pendant le tutoriel
    local lockable = { invButton, eggButton, combatButton, rebirthButton, shopBtn, worldsBtn, questBtn }
    local locks = {}
    local lockToast = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.new(0, 420, 0, 34),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), BackgroundTransparency = 0.1, Text = "", TextColor3 = GUIDE,
        Font = Enum.Font.GothamBold, TextSize = 15, Visible = false, ZIndex = 45,
    }, gui)
    makeCorner(lockToast, 8)
    local toastAt = 0
    local function setLocked(btn, on)
        local l = locks[btn]
        if on and not l then
            l = new("TextButton", {
                Name = "TutLock", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
                Text = "\u{1F512}", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
                AutoButtonColor = false, ZIndex = btn.ZIndex + 2,
            }, btn)
            makeCorner(l, 10)
            l.MouseButton1Click:Connect(function()
                lockToast.Text = "\u{1F512} Termine d'abord le tutoriel !"
                lockToast.Visible = true
                toastAt = os.clock()
            end)
            locks[btn] = l
        elseif not on and l then
            l:Destroy()
            locks[btn] = nil
        end
    end

    guideFolder.Parent = workspace
    RunService.RenderStepped:Connect(function()
        local t = os.clock()
        local tut = meta.tut
        local cam = workspace.CurrentCamera
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local active = tut ~= nil and gui.Enabled and cam.CameraType ~= Enum.CameraType.Scriptable
        if lockToast.Visible and t - toastAt > 2 then lockToast.Visible = false end

        -- verrous
        for _, b in ipairs(lockable) do
            local allowed = (not tut) or (tut.ui == "pets" and b == invButton) or (tut.ui == "combat" and b == combatButton)
            setLocked(b, not allowed)
        end

        -- cycle des pointilles : apparition un par un (0-0.9 s), pause, effacement (1.2-1.6 s)
        local C = 1.6
        local tc = t % C
        local function dashAlpha(frac)
            if tc < 0.9 then return (frac <= tc / 0.9) and 0.12 or 1 end
            if tc < 1.2 then return 0.12 end
            return 0.12 + 0.88 * ((tc - 1.2) / 0.4)
        end

        -- fleche dans le monde
        local target = active and tut.target
        if target and hrp then
            rayParams.FilterDescendantsInstances = { guideFolder, char }
            local from = hrp.Position - Vector3.new(0, 2.6, 0)
            local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
            local dist = flat.Magnitude
            local dir = dist > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
            local count = math.clamp(math.floor((dist - 4) / 2.4), 0, DASHES)
            for k = 1, DASHES do
                local d = dashes[k]
                if k <= count then
                    local p = from + dir * (2 + (k - 1) * 2.4)
                    local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
                    local y = hit and (hit.Position.Y + 0.1) or (from.Y - 0.3)
                    p = Vector3.new(p.X, y, p.Z)
                    d.CFrame = CFrame.lookAt(p, p + dir)
                    d.Transparency = dashAlpha(k / math.max(count, 1))
                else
                    d.Transparency = 1
                end
            end
            -- chevrons qui tombent sur la cible, tournes vers la camera
            local right = cam.CFrame.RightVector
            right = Vector3.new(right.X, 0, right.Z)
            right = right.Magnitude > 0.01 and right.Unit or Vector3.new(1, 0, 0)
            local up = Vector3.new(0, 1, 0)
            local bob = math.sin(t * 3) * 0.4
            for k = 1, 3 do
                local tip = target + Vector3.new(0, 4 + (3 - k) * 1.6 + bob, 0)
                local ax1, ax2 = (up - right).Unit, (up + right).Unit
                local a, b = chevrons[k][1], chevrons[k][2]
                a.CFrame = CFrame.lookAt(tip + ax1 * 1.1, tip + ax1 * 2.2)
                b.CFrame = CFrame.lookAt(tip + ax2 * 1.1, tip + ax2 * 2.2)
                local ph = (t * 1.4 - k * 0.22) % 1
                local tr = ph < 0.55 and 0.05 or 1
                a.Transparency, b.Transparency = tr, tr
            end
            tagPart.CFrame = CFrame.new(target + Vector3.new(0, 10.5 + bob, 0))
            tagLbl.Text = "ICI  -  " .. math.floor((hrp.Position - target).Magnitude) .. " m"
            tagBB.Enabled = true
        else
            for _, d in ipairs(dashes) do d.Transparency = 1 end
            for _, c in ipairs(chevrons) do c[1].Transparency, c[2].Transparency = 1, 1 end
            tagBB.Enabled = false
        end

        -- fleche du menu
        local ui = active and tut.ui and uiTarget(tut.ui)
        if ui and ui.Visible and ui.AbsoluteSize.X > 0 then
            local ap, as = ui.AbsolutePosition, ui.AbsoluteSize
            local bounce = math.abs(math.sin(t * 4)) * 8
            -- AbsolutePosition ne compte pas la barre du haut quand le ScreenGui l'ignore
            local inset = gui.IgnoreGuiInset and game:GetService("GuiService"):GetGuiInset() or Vector2.zero
            uiGuide.Position = UDim2.new(0, ap.X + inset.X + as.X + 4 + bounce, 0, ap.Y + inset.Y + as.Y / 2 - 15)
            uiGuide.Visible = true
            for k = 1, 5 do
                -- les pointilles s'allument du plus loin vers la fleche
                uiDots[k].BackgroundTransparency = dashAlpha((6 - k) / 5)
            end
            uiHint.TextTransparency = 0.1 + 0.4 * (0.5 + 0.5 * math.sin(t * 5))
            if glowTarget ~= ui then
                if glowStroke then glowStroke:Destroy() end
                glowTarget = ui
                glowStroke = new("UIStroke", { Color = GUIDE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ui)
            end
            glowStroke.Thickness = 2 + 2 * (0.5 + 0.5 * math.sin(t * 6))
        else
            uiGuide.Visible = false
            if glowStroke then glowStroke:Destroy() glowStroke = nil glowTarget = nil end
        end
    end)

    shopBtn.MouseButton1Click:Connect(function()
        local show = not shopPanel.Visible
        closeOthers(show and shopPanel or nil)
        shopPanel.Visible = show
        if show then
            refreshShop()
            ShopBuy:FireServer("__info")
        end
    end)
    worldsBtn.MouseButton1Click:Connect(function()
        local show = not worldPanel.Visible
        closeOthers(show and worldPanel or nil)
        worldPanel.Visible = show
        if show then
            refreshWorlds()
            ShopBuy:FireServer("__info")
        end
    end)
    boostBtn.MouseButton1Click:Connect(function() BuySpeed:FireServer() end)

    -- menu compact : 2 colonnes, plus bas (sous l'argent). Plus de bouton Boost (tout le monde
    -- court plus vite) ni Top (Roblox a deja son classement).
    boostBtn.Visible = false
    boardBtn.Visible = false
    for _, c in ipairs({
        { invButton, 15, 150 },    { eggButton, 141, 150 },
        { combatButton, 15, 192 }, { shopBtn, 141, 192 },
        { worldsBtn, 15, 234 },    { questBtn, 141, 234 },
        { rebirthButton, 15, 276 },
    }) do
        local b = c[1]
        b.Size = UDim2.new(0, 120, 0, 36)
        b.Position = UDim2.new(0, c[2], 0, c[3])
        b.TextSize = 14
        b.TextScaled = false
    end
    gui:SetAttribute("MenuReady", true)   -- MWS_MobileHud attend ce signal

    -- les anciens boutons ferment aussi les nouveaux panneaux
    for _, b in ipairs({ invButton, eggButton, combatButton }) do
        b.MouseButton1Click:Connect(function()
            shopPanel.Visible = false
            worldPanel.Visible = false
            fusionPanel.Visible = false
            for _, p in ipairs(extraPanels) do p.Visible = false end
        end)
    end
end

print("[MWS] Client initialise (avec combat + renaissance) !")