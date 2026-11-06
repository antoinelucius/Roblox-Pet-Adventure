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
			income.TextSize = 11
		end
	elseif child:IsA("TextLabel") and child.Text:find("Renaissance", 1, true) then
		child.AnchorPoint = Vector2.new(0.5, 0)
		child.Position = UDim2.new(0.5, 130, 0, 15)
		child.Size = UDim2.fromOffset(100, 22)
		child.TextSize = 11
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
