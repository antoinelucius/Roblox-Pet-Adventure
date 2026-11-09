-- MWS_ShopCards (client) : les cartes de la boutique.
-- Chaque article est montre par un petit objet 3D en briques (billets, coffre, potions, trainees,
-- couronne) construit ici : il est toujours entier et la camera le cadre automatiquement au centre
-- de sa case, quelle que soit sa forme. Sinon (article inconnu), son icone est affichee.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("MWS_ShopConfig"))

local Cards = {}
local V3 = Vector3.new
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(16, 10, 26)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- ---------- petites briques ----------
local function brick(model, size, cf, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.material or Enum.Material.SmoothPlastic
	p.Shape = opts.shape or Enum.PartType.Block
	p.Transparency = opts.transparency or 0
	p.TopSurface = opts.studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- liasse de billets : plaques vertes, bande jaune
local function billStack(model, cf, layers)
	local GREEN, DARK, BAND = rgb(95, 190, 70), rgb(55, 140, 45), rgb(250, 205, 50)
	for i = 0, layers - 1 do
		brick(model, V3(2.2, 0.32, 1.1), cf * CFrame.new(0, i * 0.34, 0), (i % 2 == 0) and GREEN or DARK, { studs = i == layers - 1 })
	end
	brick(model, V3(0.42, layers * 0.34 + 0.06, 1.16), cf * CFrame.new(0, (layers - 1) * 0.17, 0), BAND)
end

local function potion(model, liquid)
	local glass = brick(model, V3(2, 2, 2), CFrame.new(), rgb(220, 240, 255), { shape = Enum.PartType.Ball, transparency = 0.55, material = Enum.Material.Glass })
	glass.CastShadow = false
	brick(model, V3(1.7, 1.7, 1.7), CFrame.new(0, -0.08, 0), liquid, { shape = Enum.PartType.Ball })   -- couleur franche (le neon blanchit l'orange)
	brick(model, V3(0.8, 0.5, 0.8), CFrame.new(0, 1.1, 0), rgb(220, 240, 255), { transparency = 0.35, material = Enum.Material.Glass })
	brick(model, V3(1.05, 0.4, 1.05), CFrame.new(0, 1.5, 0), rgb(245, 185, 40), { studs = true })
	-- noeud de ruban sur le col
	brick(model, V3(0.5, 0.25, 0.3), CFrame.new(0.55, 1.18, -0.3) * CFrame.Angles(0, 0, math.rad(25)), liquid:Lerp(WHITE, 0.2))
end

local BUILDERS = {
	Cash1 = function(m)
		billStack(m, CFrame.new(), 3)
	end,
	Cash2 = function(m)
		billStack(m, CFrame.new(-0.6, 0, 0.3), 4)
		billStack(m, CFrame.new(0.7, 0, -0.4) * CFrame.Angles(0, math.rad(25), 0), 3)
		billStack(m, CFrame.new(0, 1.45, 0) * CFrame.Angles(0, math.rad(-15), 0), 2)
	end,
	Cash3 = function(m)
		-- coffre-fort ouvert, plein de billets
		brick(m, V3(2.6, 2.2, 2.2), CFrame.new(0, 1.1, 0), rgb(60, 62, 72), { studs = true })
		brick(m, V3(2.1, 1.7, 0.1), CFrame.new(0, 1.1, -1.12), rgb(95, 98, 110))
		brick(m, V3(0.15, 0.7, 0.7), CFrame.new(0.4, 1.1, -1.2) * CFrame.Angles(0, math.rad(90), 0), rgb(245, 185, 40), { shape = Enum.PartType.Cylinder })
		brick(m, V3(0.2, 0.5, 0.2), CFrame.new(-0.75, 1.1, -1.2), rgb(245, 185, 40))
		billStack(m, CFrame.new(-0.5, 2.36, 0.1) * CFrame.Angles(0, math.rad(10), 0), 2)
		billStack(m, CFrame.new(0.6, 2.36, 0.3) * CFrame.Angles(0, math.rad(-20), math.rad(8)), 2)
	end,
	PotionLuck = function(m) potion(m, rgb(255, 140, 40)) end,
	PotionSpeed = function(m) potion(m, rgb(70, 170, 255)) end,
	Crown = function(m)
		local GOLD = rgb(250, 195, 45)
		brick(m, V3(2.6, 0.8, 2.6), CFrame.new(0, 0.4, 0), GOLD, { studs = true })
		for _, x in ipairs({ -1, 0, 1 }) do
			brick(m, V3(0.6, 0.9, 0.6), CFrame.new(x, 1.2, -1), GOLD)
			brick(m, V3(0.32, 0.32, 0.32), CFrame.new(x, 1.8, -1), rgb(240, 60, 70), { material = Enum.Material.Neon })
		end
		brick(m, V3(0.5, 0.5, 0.15), CFrame.new(0, 0.4, -1.32), rgb(80, 180, 255), { material = Enum.Material.Neon })
	end,
}

-- trainee : un ruban de briques en arc, aux deux couleurs de la trainee, et des etincelles
local function trailBuilder(colors)
	local a = rgb(colors[1][1], colors[1][2], colors[1][3])
	local b = rgb(colors[2][1], colors[2][2], colors[2][3])
	return function(m)
		for i = 0, 6 do
			local t = i / 6
			local angle = math.rad(-70 + 140 * t)
			brick(m, V3(0.55, 0.55 - t * 0.25, 0.55 - t * 0.25), CFrame.new(math.sin(angle) * 1.6, math.cos(angle) * 0.9 - t * 0.6, 0),
				b:Lerp(a, t), { material = Enum.Material.Neon })
		end
		for _, pos in ipairs({ V3(-1.3, 1.2, 0), V3(1.5, 1.1, 0), V3(0.2, 1.6, 0) }) do
			brick(m, V3(0.22, 0.22, 0.22), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(45)), WHITE, { material = Enum.Material.Neon })
		end
	end
end

local itemsByKey = {}
for _, it in ipairs(Config.Items) do itemsByKey[it.key] = it end

local function builderFor(item)
	if item.model and BUILDERS[item.model] then return BUILDERS[item.model] end
	local def = itemsByKey[item.key]
	local reward = def and def.reward
	if type(reward) == "table" and reward.type == "trail" and reward.colors then return trailBuilder(reward.colors) end
	if type(reward) == "table" and reward.type == "coinsmult" then return BUILDERS.Crown end
	return nil
end

-- objet 3D dans une case carree ; la camera le cadre au centre, entier
local function viewport(parent, build, z)
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Ambient = rgb(170, 170, 180)
	view.LightColor = WHITE
	view.LightDirection = V3(-0.6, -1, -0.8)
	view.ZIndex = z
	local model = Instance.new("Model")
	build(model)
	model.Parent = view
	local cf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local radius = size.Magnitude / 2
	local dir = V3(0.45, 0.4, -1).Unit
	camera.CFrame = CFrame.lookAt(cf.Position + dir * (radius / math.sin(math.rad(15)) * 0.95), cf.Position)
	camera.Parent = view
	view.CurrentCamera = camera
	view.Parent = parent
	return view
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = WHITE
	l.TextScaled = true
	for k, v in pairs(props) do l[k] = v end
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Thickness = 1.5
	stroke.Parent = l
	l.Parent = parent
	return l
end

-- etat du bouton d'achat : texte, couleur
local function buttonState(item)
	if item.inventory then
		return item.count > 0 and "Utiliser" or "Aucune", item.count > 0 and rgb(150, 90, 240) or rgb(80, 80, 95)
	elseif item.owned and item.trail then
		return item.equipped and "Retirer" or "Équiper", item.equipped and rgb(150, 70, 80) or rgb(50, 110, 200)
	elseif item.owned then
		return "\u{2714} Possédé", rgb(60, 120, 70)
	elseif not item.available then
		return item.unlock and ("\u{1F512} " .. item.unlock) or "Bientôt", rgb(80, 80, 95)
	end
	return "\u{E002} " .. tostring(item.price or "?"), rgb(95, 235, 30)
end

-- carte d'un article ; onClick(item) est appele au clic sur le bouton
-- Mise en page (hauteur 226) : objet 3D 6-110, nom 114-138, description 140-176, bouton 180-218
function Cards.card(parent, item, section, order, onClick)
	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.BackgroundColor3 = WHITE
	card.ZIndex = 7
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new(section.color, section.color:Lerp(Color3.new(0, 0, 0), 0.6))
	shade.Rotation = 90
	shade.Parent = card
	card.Parent = parent

	-- socle rond clair, puis l'objet 3D exactement au meme centre
	local disk = Instance.new("Frame")
	disk.AnchorPoint = Vector2.new(0.5, 0.5)
	disk.Position = UDim2.new(0.5, 0, 0, 58)
	disk.Size = UDim2.fromOffset(96, 96)
	disk.BackgroundColor3 = WHITE
	disk.BackgroundTransparency = 0.78
	disk.ZIndex = 7
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = disk
	disk.Parent = card
	local build = builderFor(item)
	if build then
		local view = viewport(card, build, 8)
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		view.Position = UDim2.new(0.5, 0, 0, 58)
		view.Size = UDim2.fromOffset(104, 104)
	else
		label(card, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(64, 64),
			Text = item.icon or "?", ZIndex = 8,
		})
	end

	local name = label(card, { Position = UDim2.new(0, 8, 0, 114), Size = UDim2.new(1, -16, 0, 24), Text = item.name or "", ZIndex = 8 })
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 18
	limit.Parent = name
	local desc = label(card, {
		Position = UDim2.new(0, 8, 0, 140), Size = UDim2.new(1, -16, 0, 36), Text = item.desc or "",
		Font = Enum.Font.GothamBold, TextWrapped = true, TextColor3 = rgb(235, 235, 240), ZIndex = 8,
	})
	local descLimit = Instance.new("UITextSizeConstraint")
	descLimit.MaxTextSize = 13
	descLimit.Parent = desc

	local text, color = buttonState(item)
	local buy = Instance.new("TextButton")
	buy.Position = UDim2.new(0, 10, 1, -46)
	buy.Size = UDim2.new(1, -20, 0, 38)
	buy.BackgroundColor3 = color
	buy.Text = text
	buy.Font = Enum.Font.FredokaOne
	buy.TextSize = 20
	buy.TextColor3 = WHITE
	buy.ZIndex = 8
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = buy
	buy.Parent = card
	buy.MouseButton1Click:Connect(function() onClick(item) end)
	return card
end

return Cards
