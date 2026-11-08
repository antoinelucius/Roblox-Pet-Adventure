-- MWS_Mastery (client) : bouton "Maitrise" et son menu.
-- Grille des maitrises (anneau de progression, niveau) ; un clic montre le detail :
-- niveau, barre d'XP, comment en gagner et les 5 avantages (debloques en vert, sinon cadenas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mastery = require(ReplicatedStorage:WaitForChild("MWS_Mastery"))
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MWS_Gui")
local remotes = ReplicatedStorage:WaitForChild("MWS_Remotes")
while not gui:GetAttribute("MenuReady") do gui:GetAttributeChangedSignal("MenuReady"):Wait() end

local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(24, 8, 40)
local TITLE_FONT = Enum.Font.FredokaOne
local function rgb(t) return Color3.fromRGB(t[1], t[2], t[3]) end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end
local function corner(parent, r) return new("UICorner", { CornerRadius = r or UDim.new(1, 0) }, parent) end
local function stroke(parent, thickness, color)
	return new("UIStroke", { Thickness = thickness, Color = color or INK, LineJoinMode = Enum.LineJoinMode.Round }, parent)
end
-- texte gros et lisible : police des titres, contour sombre
local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or TITLE_FONT
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextScaled = true
	props.ZIndex = props.ZIndex or 8
	local l = new("TextLabel", props, parent)
	stroke(l, props.Font == TITLE_FONT and 2 or 1.5)
	return l
end

-- ---------- bouton du menu de gauche (a cote de Renaissance) ----------
local button = new("TextButton", {
	Name = "MWS_MasteryButton", Text = "\u{2B50} Maîtrise", BackgroundColor3 = Color3.fromRGB(170, 70, 230),
	TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16,
	Size = UDim2.new(0, 120, 0, 36), Position = UDim2.new(0, 141, 0, 276),
}, gui)
corner(button, UDim.new(0, 10))
task.spawn(function()
	-- la taille de l'ecran n'est connue qu'une fois la vue affichee
	local camera = workspace.CurrentCamera
	while camera.ViewportSize.X <= 1 do task.wait() end
	if math.min(camera.ViewportSize.X, camera.ViewportSize.Y) < 500 then   -- meme seuil que MWS_MobileHud
		-- telephone : icone seule, 8e case de la grille de MWS_MobileHud (a droite de Renaissance)
		button.Text = "\u{2B50}"
		button.TextSize = 20
		button.Size = UDim2.fromOffset(38, 38)
		button.Position = UDim2.fromOffset(4 + 42, 58 + 3 * 42)
	end
end)

-- ---------- panneau ----------
local panel = new("Frame", {
	Name = "MWS_MasteryPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.85), BackgroundColor3 = Color3.fromRGB(110, 36, 180), Visible = false, ZIndex = 5,
}, gui)
new("UISizeConstraint", { MaxSize = Vector2.new(680, 470) }, panel)
corner(panel, UDim.new(0, 14))
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 60, 225), Color3.fromRGB(80, 22, 140)) }, panel)
new("UIStroke", { Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = WHITE, ZIndex = 6 }, panel)
corner(header, UDim.new(0, 14))
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 50, 230), Color3.fromRGB(235, 80, 215)) }, header)
new("Frame", { Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 7 }, header)
label(header, { Text = "\u{2B50} Maîtrise", Position = UDim2.new(0, 16, 0, 6), Size = UDim2.new(0.6, 0, 0, 48), TextXAlignment = Enum.TextXAlignment.Left })
local close = new("TextButton", {
	Text = "X", Font = TITLE_FONT, TextScaled = true, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(215, 40, 40),
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 7), Size = UDim2.fromOffset(46, 46), ZIndex = 9,
}, header)
corner(close, UDim.new(0, 8))
new("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, close)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, close)

local body = new("Frame", { Position = UDim2.new(0, 14, 0, 72), Size = UDim2.new(1, -28, 1, -84), BackgroundTransparency = 1, ZIndex = 6 }, panel)

-- cercle avec l'icone et un anneau de petits plots qui se remplit avec l'XP du niveau
local DOTS = 30
local function ring(parent, props, m)
	local circle = new("Frame", props, parent)
	circle.BackgroundColor3 = Color3.fromRGB(48, 12, 80)
	circle.ZIndex = 7
	corner(circle)
	new("UIAspectRatioConstraint", {}, circle)
	stroke(circle, 3)
	local disk = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.74, 0.74),
		BackgroundColor3 = WHITE, ZIndex = 7,
	}, circle)
	corner(disk)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(240, 200, 255), rgb(m.color):Lerp(Color3.fromRGB(170, 90, 240), 0.5)) }, disk)
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.72, 0.72),
		BackgroundTransparency = 1, Text = m.icon, TextScaled = true, ZIndex = 8,
	}, disk)
	local dots = {}
	for i = 1, DOTS do
		local a = -math.pi / 2 + (i - 1) / DOTS * math.pi * 2
		local d = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.075, 0.075),
			Position = UDim2.fromScale(0.5 + 0.435 * math.cos(a), 0.5 + 0.435 * math.sin(a)), ZIndex = 8,
		}, circle)
		corner(d)
		dots[i] = d
	end
	return function(fraction)
		local lit = math.floor(fraction * DOTS + 0.5)
		for i, d in ipairs(dots) do
			d.BackgroundColor3 = (i <= lit) and rgb(m.color):Lerp(WHITE, 0.25) or Color3.fromRGB(80, 30, 120)
		end
	end
end

local totals = {}
local function info(m)
	local lvl, xp, need = Mastery.levelOf(totals[m.key])
	return lvl, xp, need, (need > 0) and xp / need or 1
end

-- ---------- vue 1 : grille ----------
local grid = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, body)
new("UIGridLayout", {
	CellSize = UDim2.new(1 / 3, -10, 0.5, -6), CellPadding = UDim2.fromOffset(14, 12),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)
local cards = {}
local showDetail
for i, m in ipairs(Mastery.LIST) do
	local card = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 7 }, grid)
	label(card, { Text = m.name, Size = UDim2.fromScale(1, 0.17) })
	local setRing = ring(card, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.17), Size = UDim2.fromScale(1, 0.62) }, m)
	local lvlLabel = label(card, { Text = "0", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.7, 0.36), ZIndex = 9 })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 140, 30)) }, lvlLabel)
	label(card, { Text = "NIVEAU", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.6, 0.14), ZIndex = 9 })
	card.MouseButton1Click:Connect(function() showDetail(m) end)
	cards[m.key] = { setRing = setRing, level = lvlLabel }
end

-- ---------- vue 2 : detail d'une maitrise ----------
local detail = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, body)
local left = new("Frame", { Size = UDim2.fromScale(0.4, 1), BackgroundTransparency = 1, ZIndex = 6 }, detail)
local dTitle = label(left, { Size = UDim2.fromScale(1, 0.09) })
local ringHolder = new("Frame", { Position = UDim2.fromScale(0, 0.11), Size = UDim2.fromScale(1, 0.4), BackgroundTransparency = 1, ZIndex = 6 }, left)
local dLevel = label(left, { Position = UDim2.fromScale(0, 0.53), Size = UDim2.fromScale(1, 0.08), TextColor3 = Color3.fromRGB(110, 225, 255) })
local bar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.63), Size = UDim2.fromScale(0.85, 0.055),
	BackgroundColor3 = Color3.fromRGB(28, 16, 40), ZIndex = 7,
}, left)
corner(bar)
stroke(bar, 2)
local fill = new("Frame", { Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = WHITE, ZIndex = 8 }, bar)
corner(fill)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(170, 240, 255), Color3.fromRGB(40, 170, 240)) }, fill)
local dXp = label(left, { Position = UDim2.fromScale(0, 0.7), Size = UDim2.fromScale(1, 0.065) })
local dHow = label(left, {
	Position = UDim2.fromScale(0.03, 0.775), Size = UDim2.fromScale(0.94, 0.085), Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(235, 210, 255), TextWrapped = true,
})
local back = new("TextButton", {
	Text = "RETOUR", Font = TITLE_FONT, TextScaled = true, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(220, 50, 40),
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.875), Size = UDim2.fromScale(0.75, 0.12), ZIndex = 8,
}, left)
corner(back, UDim.new(0, 6))
new("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, back)
stroke(back, 2)
new("UIPadding", { PaddingTop = UDim.new(0.14, 0), PaddingBottom = UDim.new(0.14, 0) }, back)

local right = new("Frame", { Position = UDim2.fromScale(0.43, 0), Size = UDim2.fromScale(0.57, 1), BackgroundTransparency = 1, ZIndex = 6 }, detail)
local dCount = label(right, { Size = UDim2.fromScale(1, 0.08) })
local TIER_COLORS = { { 140, 255, 140 }, { 110, 200, 255 }, { 200, 150, 255 }, { 255, 210, 90 }, { 110, 255, 230 } }
local rows = {}
for i = 1, 5 do
	local row = new("Frame", {
		Position = UDim2.fromScale(0, 0.1 + (i - 1) * 0.18), Size = UDim2.fromScale(1, 0.16), BackgroundColor3 = WHITE, ZIndex = 7,
	}, right)
	corner(row, UDim.new(0, 6))
	new("UIStroke", { Thickness = 3, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, row)
	local grad = new("UIGradient", { Rotation = 90 }, row)
	local name = label(row, { Position = UDim2.fromScale(0.02, 0.04), Size = UDim2.fromScale(0.66, 0.4), TextXAlignment = Enum.TextXAlignment.Left })
	local need = label(row, { Position = UDim2.fromScale(0.68, 0.04), Size = UDim2.fromScale(0.3, 0.4), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = rgb(TIER_COLORS[i]) })
	local lock = new("TextLabel", {
		Position = UDim2.fromScale(0.015, 0.42), Size = UDim2.fromScale(0.09, 0.54), BackgroundTransparency = 1,
		Text = "\u{1F512}", TextScaled = true, ZIndex = 8,
	}, row)
	local desc = label(row, { Position = UDim2.fromScale(0.12, 0.48), Size = UDim2.fromScale(0.86, 0.42), Font = Enum.Font.GothamBold })
	rows[i] = { grad = grad, name = name, need = need, lock = lock, desc = desc }
end

local current = nil   -- maitrise affichee en detail (nil = grille)
local setDetailRing = nil

local function refresh()
	for _, m in ipairs(Mastery.LIST) do
		local lvl, _, _, frac = info(m)
		local c = cards[m.key]
		c.level.Text = tostring(lvl)
		c.setRing(frac)
	end
	if current then
		local m = current
		local lvl, xp, need, frac = info(m)
		dTitle.Text = "Maîtrise : " .. m.name
		dLevel.Text = (lvl >= Mastery.MAX_LEVEL) and "Niveau MAX" or ("Niveau " .. lvl)
		fill.Size = UDim2.fromScale(math.max(frac, 0.03), 1)
		dXp.Text = (need > 0) and (xp .. " / " .. need .. " XP") or "Maîtrise complète !"
		dHow.Text = m.how
		local unlocked = Mastery.perksAt(lvl)
		dCount.Text = "Avantages de maîtrise  " .. unlocked .. "/5"
		for i, r in ipairs(rows) do
			local on = i <= unlocked
			r.grad.Color = on and ColorSequence.new(Color3.fromRGB(110, 210, 80), Color3.fromRGB(50, 150, 45))
				or ColorSequence.new(Color3.fromRGB(80, 80, 92), Color3.fromRGB(50, 50, 60))
			r.name.Text = Mastery.perkName(m, i)
			r.need.Text = "Niveau " .. Mastery.PERK_LEVELS[i]
			r.lock.Visible = not on
			r.desc.Text = Mastery.perkText(m, i)
		end
		if setDetailRing then setDetailRing(frac) end
	end
end

showDetail = function(m)
	current = m
	ringHolder:ClearAllChildren()
	setDetailRing = ring(ringHolder, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 1) }, m)
	grid.Visible = false
	detail.Visible = true
	refresh()
end
local function showGrid()
	current = nil
	detail.Visible = false
	grid.Visible = true
	refresh()
end
back.MouseButton1Click:Connect(showGrid)
close.MouseButton1Click:Connect(function() panel.Visible = false end)

-- un seul menu ouvert a la fois : ouvrir la maitrise ferme les autres, et inversement
local function isMenu(frame)
	return frame ~= panel and frame:IsA("Frame") and frame.Name ~= "MWS_SideTabs"
		and frame.AbsoluteSize.X >= 200 and frame.AbsoluteSize.Y >= 200
		and (frame.Size.X.Scale < 1 or frame.Size.Y.Scale < 1)
end
local function watch(frame)
	if not frame:IsA("Frame") or frame == panel then return end
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible and panel.Visible and isMenu(frame) then panel.Visible = false end
	end)
end
for _, child in ipairs(gui:GetChildren()) do watch(child) end
gui.ChildAdded:Connect(watch)

button.MouseButton1Click:Connect(function()
	if panel.Visible then
		panel.Visible = false
		return
	end
	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("Frame") and child.Visible and isMenu(child) then child.Visible = false end
	end
	showGrid()
	panel.Visible = true
end)

-- l'XP de maitrise arrive avec l'etat du joueur (envoye par le serveur a chaque changement)
remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state)
	if type(state) == "table" and type(state.mastery) == "table" then
		totals = state.mastery
		if panel.Visible then refresh() end
	end
end)
refresh()
