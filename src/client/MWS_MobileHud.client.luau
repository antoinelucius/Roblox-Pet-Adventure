-- MWS_MobileHud : sur petit ecran, le menu devient une grille d'icones collee a gauche,
-- et l'argent passe en haut au centre pour ne plus etre sous les boutons de Roblox.
-- Cette disposition suppose un ecran couche : StarterGui.ScreenOrientation = LandscapeSensor.
local Players = game:GetService("Players")

local SMALL_SCREEN = 500   -- plus petit cote de l'ecran en dessous duquel on compacte
local BUTTON, GAP = 38, 4
local LEFT, TOP = 4, 58    -- TOP : juste sous les boutons de Roblox
local MENU = { "Pets", "Oeufs", "Combat", "Shop", "Mondes", "Quetes", "Renaissance" }

local camera = workspace.CurrentCamera
while camera.ViewportSize.X <= 1 do task.wait() end
local viewport = camera.ViewportSize
if math.min(viewport.X, viewport.Y) >= SMALL_SCREEN then return end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("MWS_Gui")
while not gui:GetAttribute("MenuReady") do gui:GetAttributeChangedSignal("MenuReady"):Wait() end

-- garde l'icone du bouton, et le "!" quand il y a quelque chose a voir
local function iconOnly(button)
	local function shrink()
		local icon = button.Text:match("^[^%s!]+") or ""
		local short = icon .. (button.Text:find("!", 1, true) and "!" or "")
		if button.Text ~= short then button.Text = short end
	end
	shrink()
	button:GetPropertyChangedSignal("Text"):Connect(shrink)
end

local function place(button, index)
	local column, row = (index - 1) % 2, (index - 1) // 2
	button.Size = UDim2.fromOffset(BUTTON, BUTTON)
	button.Position = UDim2.fromOffset(LEFT + column * (BUTTON + GAP), TOP + row * (BUTTON + GAP))
	button.TextScaled = false
	button.TextSize = 20
	iconOnly(button)
end

local buttons = {}
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("TextButton") and child.Visible then
		for index, name in ipairs(MENU) do
			if child.Text:find(name, 1, true) then buttons[index] = child end
		end
	end
end
for index in ipairs(MENU) do
	if buttons[index] then place(buttons[index], index) end
end
-- sans son texte, l'icone de patte se perd sur le fond sombre
if buttons[1] then buttons[1].BackgroundColor3 = Color3.fromRGB(120, 100, 190) end

-- argent et renaissance : en haut au centre, plus petits
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("Frame") and child.Visible then
		local coin, income, icon
		for _, label in ipairs(child:GetChildren()) do
			if label:IsA("TextLabel") then
				if label.Text:find("Coin", 1, true) then coin = label
				elseif label.Text:find("/sec", 1, true) then income = label
				else icon = label end
			end
		end
		if coin and income and icon then
			child.AnchorPoint = Vector2.new(0.5, 0)
			child.Position = UDim2.new(0.5, -50, 0, 6)
			child.Size = UDim2.fromOffset(170, 40)
			icon.Position = UDim2.fromOffset(4, 7)
			icon.Size = UDim2.fromOffset(26, 26)
			coin.Position = UDim2.fromOffset(34, 3)
			coin.Size = UDim2.new(1, -38, 0, 20)
			coin.TextScaled = true
			local limit = Instance.new("UITextSizeConstraint")
			limit.MaxTextSize = 14
			limit.Parent = coin
			income.Position = UDim2.fromOffset(34, 22)
			income.Size = UDim2.new(1, -38, 0, 15)
			income.TextScaled = true   -- reste dans sa case meme si le telephone grossit les textes
			local incomeLimit = Instance.new("UITextSizeConstraint")
			incomeLimit.MaxTextSize = 11
			incomeLimit.Parent = income
		end
	elseif child:IsA("TextLabel") and child.Text:find("Renaissance", 1, true) then
		child.AnchorPoint = Vector2.new(0.5, 0)
		child.Position = UDim2.new(0.5, 130, 0, 15)
		child.Size = UDim2.fromOffset(100, 22)
		child.TextScaled = true
		local rebirthLimit = Instance.new("UITextSizeConstraint")
		rebirthLimit.MaxTextSize = 11
		rebirthLimit.Parent = child
	end
end

-- etiquettes des boss : le nom seul, plus petit, et seulement quand on est pres d'eux
local function shrinkBossLabel(board)
	board.Size = UDim2.fromOffset(140, 20)
	board.MaxDistance = 70
	local function adapt(label)
		if not label:IsA("TextLabel") then return end
		if label.Position.Y.Offset > 0 then
			label.Visible = false   -- la ligne "monstres - coins"
		else
			label.Size = UDim2.fromScale(1, 1)
			label.TextSize = 12
		end
	end
	for _, label in ipairs(board:GetChildren()) do adapt(label) end
	board.ChildAdded:Connect(adapt)
end

local function isBossLabel(item)
	local head = item.Parent
	local model = head and head.Parent
	return item:IsA("BillboardGui") and head.Name == "Head" and model ~= nil and model.Name:match("^NPC_") ~= nil
end

local generated = workspace:WaitForChild("MWS_Generated", 20)
if generated then
	for _, item in ipairs(generated:GetDescendants()) do
		if isBossLabel(item) then shrinkBossLabel(item) end
	end
	generated.DescendantAdded:Connect(function(item)
		if isBossLabel(item) then shrinkBossLabel(item) end
	end)
end

-- panneaux : chaque panneau ouvert est reduit pour tenir a cote du menu, sans passer sous
-- les boutons de Roblox. On garde la zone ou il peut etre le plus grand.
local MARGIN = 8
local GRID_RIGHT = LEFT + 2 * (BUTTON + GAP) + MARGIN
local ROBLOX_RIGHT = 168   -- fin des boutons de Roblox, en haut a gauche
local TABS_WIDTH, TABS_GAP = 120, 10
local ZONES = { { left = GRID_RIGHT, top = TOP }, { left = ROBLOX_RIGHT, top = MARGIN } }

-- taille du panneau avant reduction
local function naturalSize(frame, area)
	local size = frame.Size
	local width = size.X.Scale * area.X + size.X.Offset
	local height = size.Y.Scale * area.Y + size.Y.Offset
	local limit = frame:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		width = math.clamp(width, limit.MinSize.X, limit.MaxSize.X)
		height = math.clamp(height, limit.MinSize.Y, limit.MaxSize.Y)
	end
	return width, height
end

local function fitScale(frame)
	local fitter = frame:FindFirstChild("MWS_Fit")
	if not fitter then
		fitter = Instance.new("UIScale")
		fitter.Name = "MWS_Fit"
		fitter.Parent = frame
	end
	return fitter
end

local function fit(frame)
	local area = frame.Parent.AbsoluteSize
	local width, height = naturalSize(frame, area)
	local paired = frame.Name == "MWS_EggPanel" or frame.Name == "MWS_TraitPanel"
	local tabs = paired and gui:FindFirstChild("MWS_SideTabs")
	local groupWidth = width + (tabs and TABS_WIDTH + TABS_GAP or 0)
	local best, zoneWidth, zoneHeight, zone
	for _, candidate in ipairs(ZONES) do
		local w, h = area.X - MARGIN - candidate.left, area.Y - MARGIN - candidate.top
		local k = math.min(1, w / groupWidth, h / height)
		if not best or k > best then best, zoneWidth, zoneHeight, zone = k, w, h, candidate end
	end
	fitScale(frame).Scale = best
	local groupLeft = zone.left + (zoneWidth - groupWidth * best) / 2
	local centerY = zone.top + zoneHeight / 2
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(groupLeft + (groupWidth - width / 2) * best, centerY)
	if tabs then
		fitScale(tabs).Scale = best
		tabs.AnchorPoint = Vector2.new(0.5, 0.5)
		tabs.Position = UDim2.fromOffset(groupLeft + TABS_WIDTH * best / 2, centerY)
	end
end

local watched = {}
local function watch(frame)
	if watched[frame] or not frame:IsA("Frame") or frame.Name == "MWS_SideTabs" then return end
	local size = frame.Size
	if size.X.Scale >= 1 and size.Y.Scale >= 1 then return end   -- plein ecran (combat, oeuf)
	local width, height = naturalSize(frame, frame.Parent.AbsoluteSize)
	if width < 200 or height < 200 then return end               -- argent, petites bulles
	watched[frame] = true
	local function update()
		if frame.Visible then fit(frame) end
	end
	frame:GetPropertyChangedSignal("Visible"):Connect(update)
	frame:GetPropertyChangedSignal("Size"):Connect(update)
	update()
end

for _, child in ipairs(gui:GetChildren()) do watch(child) end
gui.ChildAdded:Connect(watch)
local settingsGui = playerGui:WaitForChild("MWS_Settings", 10)
local settingsPanel = settingsGui and settingsGui:FindFirstChildOfClass("Frame")
if settingsPanel then watch(settingsPanel) end
