-- MWS_Settings : bouton a droite de l'argent et panneau des parametres.
-- Chaque reglage vit dans un attribut du joueur ; le serveur le garde avec la sauvegarde.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local saveSetting = ReplicatedStorage:WaitForChild("MWS_Remotes"):WaitForChild("SaveSetting")

local SETTINGS = {
	{ key = "music", attribute = "MWS_SetMusic", label = "Musique", hint = "Musique de fond !", volume = true },
	{ key = "sfx", attribute = "MWS_SetSfx", label = "Effets sonores", hint = "Volume des effets sonores !", volume = true },
	{ key = "otherPets", attribute = "MWS_SetOtherPets", label = "Voir les autres animaux de compagnie" },
	{ key = "myPets", attribute = "MWS_SetMyPets", label = "Voir mes animaux de compagnie" },
	{ key = "eggs", attribute = "MWS_SetEggs", label = "Voir mes œufs" },
	{ key = "names", attribute = "MWS_SetNames", label = "Noms sur la carte" },
	{ key = "shake", attribute = "MWS_SetShake", label = "Secousses de l'écran" },
}
local byKey = {}
for _, setting in ipairs(SETTINGS) do byKey[setting.key] = setting end

local VOLUME_STEP = 5
local FONT = Enum.Font.FredokaOne
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(24, 28, 36)
local ROW = Color3.fromRGB(44, 44, 46)
local ROW_EDGE = Color3.fromRGB(125, 128, 132)
local YELLOW = Color3.fromRGB(255, 205, 0)
local GREEN = Color3.fromRGB(125, 225, 60)
local OFF = Color3.fromRGB(150, 150, 155)

local function new(class, props, parent)
	local item = Instance.new(class)
	for name, value in pairs(props) do item[name] = value end
	item.Parent = parent
	return item
end
local function corner(item, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, item)
	return item
end
local function outline(item, color, thickness)
	new("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, item)
	return item
end
-- texte blanc epais, contour sombre
local function title(props, parent)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextColor3 = WHITE
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.TextScaled = true   -- reste dans sa case, meme si le telephone grossit les textes
	local label = new("TextLabel", props, parent)
	new("UITextSizeConstraint", { MaxTextSize = props.TextSize }, label)
	new("UIStroke", { Color = INK, Thickness = props.TextSize >= 24 and 3 or 2 }, label)
	return label
end

local function valueOf(setting)
	local value = player:GetAttribute(setting.attribute)
	if value == nil then
		if setting.volume then return 100 end
		return true
	end
	return value
end

-- panneau
local screen = new("ScreenGui", { Name = "MWS_Settings", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20 }, playerGui)
local panel = outline(corner(new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(26, 28, 32),
	BackgroundTransparency = 0.2,
	Visible = false,
}, screen), 4), INK, 3)

local header = corner(new("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = WHITE }, panel), 4)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(176, 176, 214)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 238, 244)),
	}),
}, header)
title({ Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -90, 1, 0), Text = "Paramètres", TextSize = 40 }, header)
local close = outline(corner(new("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(50, 50),
	BackgroundColor3 = Color3.fromRGB(225, 12, 12),
	Text = "",
}, header), 4), INK, 3)
title({ Size = UDim2.fromScale(1, 1), Text = "X", TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center }, close)
close.Activated:Connect(function() panel.Visible = false end)

local list = new("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 74),
	Size = UDim2.new(1, -16, 1, -82),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(200, 200, 205),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, panel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local function makeRow(index, height)
	return outline(corner(new("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, -10, 0, height),
		BackgroundColor3 = ROW,
		BackgroundTransparency = 0.25,
	}, list), 3), ROW_EDGE, 1)
end

-- curseur de volume : le son change pendant le glissement, la sauvegarde part au relachement
local function addSlider(index, setting)
	local row = makeRow(index, 72)
	title({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.44, 0, 0, 32), Text = setting.label, TextSize = 24 }, row)
	title({ Position = UDim2.fromOffset(14, 42), Size = UDim2.new(0.44, 0, 0, 20), Text = setting.hint, TextSize = 13 }, row)
	local hit = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Active = true,
	}, row)
	local track = corner(new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = Color3.fromRGB(26, 28, 28),
	}, hit), 5)
	local fill = corner(new("Frame", { BackgroundColor3 = YELLOW, BorderSizePixel = 0 }, track), 5)
	local handle = outline(corner(new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = YELLOW,
	}, track), 5), INK, 3)

	local function refresh()
		local share = valueOf(setting) / 100
		fill.Size = UDim2.fromScale(share, 1)
		handle.Position = UDim2.fromScale(share, 0.5)
	end
	local function followPointer(x)
		local share = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = math.round(share * 100 / VOLUME_STEP) * VOLUME_STEP
		if value ~= valueOf(setting) then player:SetAttribute(setting.attribute, value) end
	end
	hit.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
		list.ScrollingEnabled = false
		followPointer(input.Position.X)
		local moved = UserInputService.InputChanged:Connect(function(other)
			if other.UserInputType == Enum.UserInputType.MouseMovement or other == input then
				followPointer(other.Position.X)
			end
		end)
		local released
		released = UserInputService.InputEnded:Connect(function(other)
			if other.UserInputType ~= kind then return end
			moved:Disconnect()
			released:Disconnect()
			list.ScrollingEnabled = true
			saveSetting:FireServer(setting.key, valueOf(setting))
		end)
	end)
	refresh()
	player:GetAttributeChangedSignal(setting.attribute):Connect(refresh)
end

local function addToggle(index, setting)
	local row = makeRow(index, 58)
	title({
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -206, 1, 0),
		Text = setting.label,
		TextSize = 16,
		TextWrapped = true,
	}, row)
	local state = title({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -92, 0.5, 0),
		Size = UDim2.fromOffset(100, 30),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local switch = outline(corner(new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(68, 38),
		BackgroundColor3 = Color3.fromRGB(26, 28, 28),
		AutoButtonColor = false,
		Text = "",
	}, row), 6), INK, 2)
	local knob = outline(corner(new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
	}, switch), 3), INK, 2)
	switch.Activated:Connect(function()
		local value = not valueOf(setting)
		player:SetAttribute(setting.attribute, value)
		saveSetting:FireServer(setting.key, value)
	end)
	local function refresh()
		local enabled = valueOf(setting)
		state.Text = enabled and "ACTIVÉ" or "DÉSACTIVÉ"
		knob.BackgroundColor3 = enabled and GREEN or OFF
		knob.Position = UDim2.new(enabled and 1 or 0, enabled and -19 or 19, 0.5, 0)
	end
	refresh()
	player:GetAttributeChangedSignal(setting.attribute):Connect(refresh)
end

for index, setting in ipairs(SETTINGS) do
	if setting.volume then addSlider(index, setting) else addToggle(index, setting) end
end

-- bouton, juste a droite de l'argent
local gui = playerGui:WaitForChild("MWS_Gui")
while not gui:GetAttribute("MenuReady") do gui:GetAttributeChangedSignal("MenuReady"):Wait() end
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("Frame") and child.Visible then
		local button = corner(new("TextButton", {
			Name = "SettingsButton",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, 4, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = Color3.fromRGB(235, 235, 245),   -- fond clair : la roue dentee est grise
			Text = "\u{2699}",
			TextColor3 = Color3.fromRGB(30, 30, 40),
			Font = Enum.Font.GothamBold,
			TextSize = 22,
		}, child), 10)
		button.Activated:Connect(function()
			-- aussi haut que possible sans depasser d'un ecran de telephone
			local height = workspace.CurrentCamera.ViewportSize.Y - 30
			panel.Size = UDim2.fromOffset(470, math.clamp(height, 240, 440))
			panel.Visible = not panel.Visible
		end)
		break
	end
end

-- noms et pets sur la carte : caches pour ce joueur seulement
local generated = workspace:WaitForChild("MWS_Generated", 20)
if generated then
	local pets = generated:WaitForChild("Pets", 20)
	local wasEnabled = setmetatable({}, { __mode = "k" })

	-- le modele de pet qui contient cet objet, s'il y en a un
	local function petOf(item)
		if not pets or not item:IsDescendantOf(pets) then return nil end
		while item.Parent ~= pets do item = item.Parent end
		return item
	end
	local function isHidden(pet)
		local setting = pet:GetAttribute("MWS_Owner") == player.UserId and byKey.myPets or byKey.otherPets
		return not valueOf(setting)
	end

	local function refreshItem(item)
		local pet = petOf(item)
		local hidden = pet ~= nil and isHidden(pet)
		if item:IsA("BillboardGui") then
			item.PlayerToHideFrom = if hidden or not valueOf(byKey.names) then player else nil
		elseif not pet then
			return
		elseif item:IsA("BasePart") or item:IsA("Decal") then
			item.LocalTransparencyModifier = hidden and 1 or 0
		elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Light") then
			if hidden then
				if wasEnabled[item] == nil then wasEnabled[item] = item.Enabled end
				item.Enabled = false
			elseif wasEnabled[item] ~= nil then
				item.Enabled = wasEnabled[item]
				wasEnabled[item] = nil
			end
		end
	end
	local function refreshAll()
		for _, item in ipairs(generated:GetDescendants()) do refreshItem(item) end
	end
	generated.DescendantAdded:Connect(refreshItem)
	for _, key in ipairs({ "names", "otherPets", "myPets" }) do
		player:GetAttributeChangedSignal(byKey[key].attribute):Connect(refreshAll)
	end
	refreshAll()
end
