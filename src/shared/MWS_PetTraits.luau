-- Tailles et mutations des pets (tirees a l'eclosion).
-- Partage serveur / client : stats, nom affiche et apparence.
local T = {}

-- du plus rare au plus commun (le tirage teste dans cet ordre)
T.SIZES = {
	{ key = "Titan", label = "Titan", chance = 0.3, scale = 2.1,  mult = 8 },
	{ key = "Geant", label = "Géant", chance = 2,   scale = 1.6,  mult = 3 },
	{ key = "Grand", label = "Grand", chance = 8,   scale = 1.25, mult = 1.5 },
}
T.MUTATIONS = {
	{ key = "ArcEnCiel", label = "Arc-en-ciel", chance = 0.4, mult = 6, color = Color3.fromRGB(255, 120, 220) },
	{ key = "Ombre",     label = "Ombre",       chance = 1.2, mult = 4, color = Color3.fromRGB(160, 80, 240) },
	{ key = "Cristal",   label = "Cristal",     chance = 2,   mult = 3, color = Color3.fromRGB(140, 220, 255) },
	{ key = "Dore",      label = "Doré",        chance = 4,   mult = 2, color = Color3.fromRGB(255, 200, 60) },
}
T.SIZE, T.MUTATION = {}, {}
for _, s in ipairs(T.SIZES) do T.SIZE[s.key] = s end
for _, m in ipairs(T.MUTATIONS) do T.MUTATION[m.key] = m end

local function pick(list, luck)
	for _, e in ipairs(list) do
		if math.random() * 100 < e.chance * luck then return e.key end
	end
	return nil
end

-- renvoie size, mutation (nil = normal). luck >= 1 augmente les chances.
function T.roll(luck)
	luck = math.max(1, luck or 1)
	return pick(T.SIZES, luck), pick(T.MUTATIONS, luck)
end

function T.mult(pet)
	local s = pet and T.SIZE[pet.size or ""]
	local m = pet and T.MUTATION[pet.mutation or ""]
	return (s and s.mult or 1) * (m and m.mult or 1)
end

function T.scale(pet)
	local s = pet and T.SIZE[pet.size or ""]
	return s and s.scale or 1
end

-- "Titan Dragon de lave+ Doré"
function T.fullName(pet)
	local s = T.SIZE[pet.size or ""]
	local m = T.MUTATION[pet.mutation or ""]
	return (s and (s.label .. " ") or "") .. pet.name .. string.rep("+", pet.tier or 0) .. (m and (" " .. m.label) or "")
end

-- "Titan · Doré" (vide si normal)
function T.tag(pet)
	local s = T.SIZE[pet.size or ""]
	local m = T.MUTATION[pet.mutation or ""]
	local parts = {}
	if s then table.insert(parts, s.label) end
	if m then table.insert(parts, m.label) end
	return table.concat(parts, " · ")
end

-- couleur d'accent (mutation sinon taille), nil si normal
function T.accent(pet)
	local m = T.MUTATION[pet.mutation or ""]
	if m then return m.color end
	if T.SIZE[pet.size or ""] then return Color3.fromRGB(255, 235, 150) end
	return nil
end

-- repeint les briques du modele selon la mutation (les yeux restent des yeux)
function T.paint(model, mutation)
	local m = T.MUTATION[mutation or ""]
	if not m or not model then return end
	local parts = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.95 then table.insert(parts, p) end
	end
	-- arc-en-ciel : la teinte suit la position de la brique le long du corps
	local bcf, bsize = model:GetBoundingBox()
	local long = (bsize.Z >= bsize.X) and "Z" or "X"
	for i, p in ipairs(parts) do
		local _, _, v = p.Color:ToHSV()
		if p.Name == "Eye" then
			if mutation == "Ombre" then
				p.Color = Color3.fromRGB(200, 120, 255)
				p.Material = Enum.Material.Neon
			end
		elseif mutation == "Dore" then
			p.Color = Color3.fromHSV(0.12, 0.72, math.clamp(0.5 + v * 0.55, 0, 1))
			p.Material = Enum.Material.Metal
			p.Reflectance = 0.2
		elseif mutation == "Cristal" then
			p.Color = Color3.fromHSV(0.54, 0.35, math.clamp(0.7 + v * 0.35, 0, 1))
			p.Material = Enum.Material.Glass
			p.Transparency = math.max(p.Transparency, 0.25)
			p.Reflectance = 0.15
		elseif mutation == "Ombre" then
			p.Color = Color3.fromHSV(0.76, 0.45, math.clamp(0.06 + v * 0.16, 0, 1))
			p.Material = Enum.Material.SmoothPlastic
		elseif mutation == "ArcEnCiel" then
			local rel = bcf:PointToObjectSpace(p.Position)
			local a = (rel[long] / math.max(bsize[long], 0.1)) * 1.6 + (rel.Y / math.max(bsize.Y, 0.1)) * 0.5
			p.Color = Color3.fromHSV(a % 1, 0.75, math.clamp(0.8 + v * 0.2, 0, 1))
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end

-- particules autour du pet (paillettes dorees, givre, fumee d'ombre, arc-en-ciel)
function T.decorate(root, mutation, radius)
	local m = T.MUTATION[mutation or ""]
	if not m or not root then return end
	radius = radius or 2
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Mutation"
	pe.Shape = Enum.ParticleEmitterShape.Sphere
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.LightInfluence = 0
	pe.Speed = NumberRange.new(0.3, 1)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-60, 60)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.LightEmission = 1
	pe.Rate = 10
	if mutation == "Dore" then
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 180, 40))
	elseif mutation == "Cristal" then
		pe.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 220, 255))
		pe.Acceleration = Vector3.new(0, -2, 0)
	elseif mutation == "Ombre" then
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(90, 30, 140), Color3.fromRGB(20, 0, 35))
		pe.LightEmission = 0.2
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pe.Acceleration = Vector3.new(0, 1.5, 0)
		pe.Rate = 8
	elseif mutation == "ArcEnCiel" then
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 90, 255)),
		})
		pe.Rate = 16
	end
	local att = Instance.new("Attachment")
	att.Name = "MutationFx"
	att.Parent = root
	pe.Parent = att
	-- volume de la sphere = taille de l'attachment : on passe par un emetteur sur une boite invisible
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Speed = NumberRange.new(radius * 0.6, radius)
	pe.Drag = 3
	return pe
end

return T
