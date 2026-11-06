-- MWS_Settings : bouton a droite de l'argent et panneau des parametres.
-- Chaque reglage vit dans un attribut du joueur ; le serveur le garde avec la sauvegarde.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local saveSetting = ReplicatedStorage:WaitForChild("MWS_Remotes"):WaitForChild("SaveSetting")

local SETTINGS = {
	{ key = "music", attribute = "MWS_SetMusic", label = "Musique", volume = true },
	{ key = "sfx", attribute = "MWS_SetSfx", label = "Bruitages", volume = true },
	{ key = "names", attribute = "MWS_SetNames", label = "Noms sur la carte" },
	{ key = "shake", attribute = "MWS_SetShake", label = "Secousses de l'écran" },
}
local VOLUME_STEP = 25
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(30, 30, 40)
local BUTTON = Color3.fromRGB(60, 60, 82)
local ON = Color3.fromRGB(60, 170, 90)

local function new(class, props, parent)
	local item = Instance.new(class)
	for name, value in pairs(props) do item[name] = value end
	item.Parent = parent
	return item
end
local function rounded(item, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, item)
	return item
end
local function makeButton(props, parent)
	props.Font = Enum.Font.GothamBold
	props.TextColor3 = WHITE
	props.BackgroundColor3 = props.BackgroundColor3 or BUTTON
	return rounded(new("TextButton", props, parent), 8)
end

local function valueOf(setting)
	local value = player:GetAttribute(setting.attribute)
	if value == nil then
		if setting.volume then return 100 end
		return true
	end
	return value
end
local function change(setting, value)
	player:SetAttribute(setting.attribute, value)
	saveSetting:FireServer(setting.key, value)
end

-- panneau
local screen = new("ScreenGui", { Name = "MWS_Settings", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20 }, playerGui)
local panel = rounded(new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(320, 254),
	BackgroundColor3 = DARK,
	Visible = false,
}, screen), 12)
new("TextLabel", {
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.new(1, -60, 0, 32),
	BackgroundTransparency = 1,
	Text = "Paramètres",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = WHITE,
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
}, panel)
local close = makeButton({
	Position = UDim2.new(1, -42, 0, 8),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = Color3.fromRGB(190, 60, 60),
	Text = "X",
	TextSize = 16,
}, panel)
close.Activated:Connect(function() panel.Visible = false end)

for index, setting in ipairs(SETTINGS) do
	local row = new("Frame", {
		Position = UDim2.fromOffset(16, 50 + (index - 1) * 48),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
	}, panel)
	new("TextLabel", {
		Size = UDim2.new(1, -124, 1, 0),
		BackgroundTransparency = 1,
		Text = setting.label,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, row)
	local refresh
	if setting.volume then
		local minus = makeButton({ Position = UDim2.new(1, -120, 0, 2), Size = UDim2.fromOffset(36, 36), Text = "\u{2212}", TextSize = 20 }, row)
		local plus = makeButton({ Position = UDim2.new(1, -36, 0, 2), Size = UDim2.fromOffset(36, 36), Text = "+", TextSize = 20 }, row)
		local amount = new("TextLabel", {
			Position = UDim2.new(1, -84, 0, 0),
			Size = UDim2.fromOffset(48, 40),
			BackgroundTransparency = 1,
			TextColor3 = WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
		}, row)
		minus.Activated:Connect(function() change(setting, math.max(0, valueOf(setting) - VOLUME_STEP)) end)
		plus.Activated:Connect(function() change(setting, math.min(100, valueOf(setting) + VOLUME_STEP)) end)
		refresh = function() amount.Text = valueOf(setting) .. "%" end
	else
		local toggle = makeButton({ Position = UDim2.new(1, -120, 0, 2), Size = UDim2.fromOffset(120, 36), TextSize = 14 }, row)
		toggle.Activated:Connect(function() change(setting, not valueOf(setting)) end)
		refresh = function()
			local enabled = valueOf(setting)
			toggle.Text = enabled and "Oui" or "Non"
			toggle.BackgroundColor3 = enabled and ON or BUTTON
		end
	end
	refresh()
	player:GetAttributeChangedSignal(setting.attribute):Connect(refresh)
end

-- bouton, juste a droite de l'argent
local gui = playerGui:WaitForChild("MWS_Gui")
while not gui:GetAttribute("MenuReady") do gui:GetAttributeChangedSignal("MenuReady"):Wait() end
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("Frame") and child.Visible then
		local button = rounded(new("TextButton", {
			Name = "SettingsButton",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, 4, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = Color3.fromRGB(235, 235, 245),   -- fond clair : la roue dentee est grise
			Text = "\u{2699}",
			TextColor3 = DARK,
			Font = Enum.Font.GothamBold,
			TextSize = 22,
		}, child), 10)
		button.Activated:Connect(function() panel.Visible = not panel.Visible end)
		break
	end
end

-- noms sur la carte : caches pour ce joueur seulement
local generated = workspace:WaitForChild("MWS_Generated", 20)
if generated then
	local function hideOrShow(item)
		if item:IsA("BillboardGui") then
			item.PlayerToHideFrom = if valueOf(SETTINGS[3]) then nil else player
		end
	end
	local function applyNames()
		for _, item in ipairs(generated:GetDescendants()) do hideOrShow(item) end
	end
	generated.DescendantAdded:Connect(hideOrShow)
	player:GetAttributeChangedSignal(SETTINGS[3].attribute):Connect(applyNames)
	applyNames()
end
