-- MWS_Style : style "briques" des boutons et effets des menus, inspire du kit UIverse (style seul,
-- aucun de ses systemes). Habille l'interface existante sans changer son fonctionnement :
--   boutons du menu : face a plots avec degrade, contour noir, reflet tournant, grossit au survol,
--                     s'enfonce au clic et fait jaillir son icone
--   menus : contour noir, ouverture avec rebond, flou derriere, sons d'ouverture et de fermeture
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local STUDS = "rbxassetid://6927295847"
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local MENU = { "Pets", "Oeufs", "Combat", "Shop", "Mondes", "Quetes", "Renaissance" }
local SOUNDS = { open = 80984744279155, close = 138409154614452, press = 106984966606682 }

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("MWS_Gui")
while not gui:GetAttribute("MenuReady") do gui:GetAttributeChangedSignal("MenuReady"):Wait() end

local function new(class, props, parent)
	local item = Instance.new(class)
	for name, value in pairs(props) do item[name] = value end
	item.Parent = parent
	return item
end
local function tween(item, seconds, goal, style, direction)
	local t = TweenService:Create(item, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- sons courts, dans le groupe des bruitages (le volume suit les parametres)
local sfxGroup = SoundService:WaitForChild("MWS_Sfx", 5)
local function sound(key, volume, pitch)
	local s = new("Sound", { SoundId = "rbxassetid://" .. SOUNDS[key], Volume = volume, PlaybackSpeed = pitch or 1, SoundGroup = sfxGroup }, SoundService)
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	task.delay(4, function() if s.Parent then s:Destroy() end end)
end

-- calque des effets (icones qui jaillissent), au-dessus de tout
local fxGui = new("ScreenGui", { Name = "MWS_StyleFX", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 150 }, playerGui)

-- reflets tournants : un seul tour de boucle pour tous
local spinning = {}
RunService.RenderStepped:Connect(function(dt)
	for gradient in pairs(spinning) do
		if gradient.Parent then gradient.Rotation = (gradient.Rotation + dt * 70) % 360 else spinning[gradient] = nil end
	end
end)

-- ---------- boutons ----------
local function cornerOf(item)
	local c = item:FindFirstChildOfClass("UICorner")
	return c and c.CornerRadius or UDim.new(0, 8)
end

local function burst(button, text)
	local center = button.AbsolutePosition + button.AbsoluteSize / 2
	for i = 1, 8 do
		local angle = math.rad(-90 + ((i - 0.5) / 8 - 0.5) * 360 + math.random(-12, 12))
		local distance, size = math.random(55, 95), math.random(18, 26)
		local piece = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(center.X, center.Y), Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1, Text = text, TextScaled = true, Font = Enum.Font.FredokaOne, TextColor3 = WHITE,
		}, fxGui)
		local life = math.random(55, 80) / 100
		tween(piece, life, {
			Position = UDim2.fromOffset(center.X + math.cos(angle) * distance, center.Y + math.sin(angle) * distance),
			Rotation = math.random(-200, 200), Size = UDim2.fromOffset(size * 0.45, size * 0.45), TextTransparency = 1,
		})
		task.delay(life, function() piece:Destroy() end)
	end
end

local function styleButton(button)
	if button:GetAttribute("MWS_Styled") then return end
	button:SetAttribute("MWS_Styled", true)
	button.AutoButtonColor = false
	local radius = cornerOf(button)

	-- contour noir ; le texte du bouton est remplace par une etiquette posee sur la face
	new("UIStroke", { Color = BLACK, Thickness = 2.5, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
	local face = new("ImageLabel", {
		Name = "MWS_Face", Image = STUDS, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(26, 26), ImageTransparency = 0.55,
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -3), ZIndex = button.ZIndex,
	}, button)
	new("UICorner", { CornerRadius = radius }, face)
	local shade = new("UIGradient", { Rotation = 90 }, face)
	-- fin reflet blanc qui tourne juste a l'interieur du contour
	local ring = new("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -4, 1, -4), ZIndex = button.ZIndex,
	}, face)
	new("UICorner", { CornerRadius = UDim.new(radius.Scale, math.max(0, radius.Offset - 2)) }, ring)
	local ringStroke = new("UIStroke", { Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ring)
	local ringShade = new("UIGradient", { Rotation = math.random(0, 359) }, ringStroke)
	spinning[ringShade] = true
	-- bande de lumiere qui traverse la face au survol
	local shine = new("CanvasGroup", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = button.ZIndex }, face)
	new("UICorner", { CornerRadius = radius }, shine)
	local band = new("Frame", {
		BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.new(0, 14, 2, 0),
		Position = UDim2.new(-0.25, 0, -0.5, 0), Rotation = 20, Visible = false, ZIndex = button.ZIndex,
	}, shine)

	local label = new("TextLabel", {
		Name = "MWS_Label", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 1, -3), Position = UDim2.fromOffset(2, 0),
		ZIndex = button.ZIndex,
	}, button)
	new("UIStroke", { Color = BLACK, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Round }, label)
	local function copyText()
		label.Text, label.Font, label.TextSize = button.Text, button.Font, button.TextSize
		label.TextScaled, label.TextColor3 = button.TextScaled, button.TextColor3
	end
	copyText()
	for _, property in ipairs({ "Text", "Font", "TextSize", "TextScaled", "TextColor3" }) do
		button:GetPropertyChangedSignal(property):Connect(copyText)
	end
	-- le texte d'origine reste en dessous, invisible (son contour aussi)
	button.TextTransparency = 1
	local function hideTextStroke(child)
		if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual then child.Enabled = false end
	end
	for _, child in ipairs(button:GetChildren()) do hideTextStroke(child) end
	button.ChildAdded:Connect(hideTextStroke)

	-- couleurs : le jeu change parfois la couleur du bouton (Quetes quand il y a une recompense)
	local lip
	local function recolor()
		local base = button.BackgroundColor3
		if lip and base == lip then return end
		shade.Color = ColorSequence.new(base:Lerp(WHITE, 0.35), base:Lerp(BLACK, 0.2))
		ringShade.Color = ColorSequence.new(base:Lerp(WHITE, 0.55), WHITE)
		lip = base:Lerp(BLACK, 0.5)
		button.BackgroundColor3 = lip
	end
	recolor()
	button:GetPropertyChangedSignal("BackgroundColor3"):Connect(recolor)

	-- survol, appui, clic
	local press = new("UIScale", { Name = "MWS_Press" }, button)
	button.MouseEnter:Connect(function()
		tween(press, 0.18, { Scale = 1.07 })
		if not band.Visible then
			band.Visible = true
			band.Position = UDim2.new(-0.25, 0, -0.5, 0)
			tween(band, 0.45, { Position = UDim2.new(1.15, 0, -0.5, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				.Completed:Once(function() band.Visible = false end)
		end
	end)
	button.MouseLeave:Connect(function() tween(press, 0.18, { Scale = 1 }) end)
	button.MouseButton1Down:Connect(function()
		tween(press, 0.08, { Scale = 0.93 })
		sound("press", 0.3, 1 + (math.random() - 0.5) * 0.08)
	end)
	button.MouseButton1Up:Connect(function() tween(press, 0.12, { Scale = 1 }) end)
	button.Activated:Connect(function()
		local icon = label.Text:match("^[^%s!]+")
		if icon and icon ~= "" then burst(button, icon) end
	end)
end

for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("TextButton") and child.Visible then
		for _, name in ipairs(MENU) do
			if child.Text:find(name, 1, true) then styleButton(child) end
		end
	end
end
-- la roue dentee des parametres arrive un peu apres le menu
local function styleSettings(item)
	if item:IsA("TextButton") and item.Name == "SettingsButton" then
		item.BackgroundColor3 = Color3.fromRGB(150, 155, 170)
		styleButton(item)
	end
end
for _, item in ipairs(gui:GetDescendants()) do styleSettings(item) end
gui.DescendantAdded:Connect(styleSettings)

-- ---------- menus ----------
-- un menu : ni plein ecran (combat, oeuf), ni petite bulle (argent)
local function isPanel(frame)
	local size, area = frame.Size, frame.Parent.AbsoluteSize
	if size.X.Scale >= 1 and size.Y.Scale >= 1 then return false end
	local width = size.X.Scale * area.X + size.X.Offset
	local height = size.Y.Scale * area.Y + size.Y.Offset
	local limit = frame:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		width = math.min(width, limit.MaxSize.X)
		height = math.min(height, limit.MaxSize.Y)
	end
	return width >= 200 and height >= 200
end

local blur = Lighting:FindFirstChild("MWS_MenuBlur") or new("BlurEffect", { Name = "MWS_MenuBlur", Size = 0 }, Lighting)
local panels = {}
-- flou seulement si un vrai menu est ouvert et affiche (pas l'argent, le fondu de changement
-- de monde ni les ecrans plein ecran, qui laissaient le flou bloque)
local function updateBlur()
	local open = false
	for frame in pairs(panels) do
		local screen = frame:FindFirstAncestorWhichIsA("ScreenGui")
		if frame.Parent and frame.Visible and screen and screen.Enabled and isPanel(frame) then open = true break end
	end
	tween(blur, 0.25, { Size = open and 10 or 0 })
end

local function stylePanel(frame)
	if panels[frame] ~= nil or not frame:IsA("Frame") or frame.Name == "MWS_SideTabs" then return end
	panels[frame] = false
	local wasVisible = frame.Visible
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not isPanel(frame) then updateBlur() return end
		if not panels[frame] then
			-- habillage au premier affichage : contour noir epais (sauf si le menu a deja le sien)
			panels[frame] = true
			local hasBorder = false
			for _, child in ipairs(frame:GetChildren()) do
				if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then hasBorder = true end
			end
			if not hasBorder then
				new("UIStroke", { Color = BLACK, Thickness = 4, LineJoinMode = Enum.LineJoinMode.Round, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
			end
		end
		local nowVisible = frame.Visible
		if nowVisible and not wasVisible then
			sound("open", 0.25, 1.35)
			-- rebond : la taille finale est celle choisie par MWS_MobileHud sur telephone (meme UIScale)
			task.defer(function()
				local scale = frame:FindFirstChild("MWS_Fit") or new("UIScale", { Name = "MWS_Fit" }, frame)
				local target = scale.Scale
				scale.Scale = target * 0.6
				tween(scale, 0.3, { Scale = target }, Enum.EasingStyle.Back)
			end)
		elseif wasVisible and not nowVisible then
			sound("close", 0.3)
		end
		wasVisible = nowVisible
		updateBlur()
	end)
end

for _, child in ipairs(gui:GetChildren()) do stylePanel(child) end
gui.ChildAdded:Connect(stylePanel)
gui:GetPropertyChangedSignal("Enabled"):Connect(updateBlur)   -- interface cachee (animations) : pas de flou
local settingsGui = playerGui:WaitForChild("MWS_Settings", 10)
local settingsPanel = settingsGui and settingsGui:FindFirstChildOfClass("Frame")
if settingsPanel then stylePanel(settingsPanel) end
