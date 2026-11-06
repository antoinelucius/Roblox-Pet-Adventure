-- MWS_EggModels : oeufs en briques lego, un style par oeuf (socles + animation d'eclosion).
-- build(style, opts) -> model, root, info
--   opts.k : echelle (1 = oeuf de 5 studs de haut) ; root = Part invisible au centre de l'oeuf,
--   toutes les briques y sont soudees (deplacer root deplace l'oeuf).
--   info.shell = briques de coquille, info.glow = briques qui peuvent s'illuminer (fissures), info.top = Attachment au sommet
local Eggs = {}
local V3 = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- couleurs de chaque style : coquille, coquille sombre, eclat (fissures/effets), accent
Eggs.STYLES = {
	base       = { shell = rgb(232, 222, 250), dark = rgb(200, 185, 235), glow = rgb(190, 140, 255), accent = rgb(160, 110, 240) },
	dore       = { shell = rgb(242, 192, 60),  dark = rgb(205, 150, 35),  glow = rgb(255, 235, 140), accent = rgb(255, 250, 235) },
	mythique   = { shell = rgb(200, 60, 175),  dark = rgb(140, 35, 125),  glow = rgb(255, 120, 230), accent = rgb(90, 230, 255) },
	lave       = { shell = rgb(48, 22, 28),    dark = rgb(95, 24, 20),    glow = rgb(255, 110, 25),  accent = rgb(255, 210, 60) },
	celeste    = { shell = rgb(40, 52, 140),   dark = rgb(25, 30, 90),    glow = rgb(160, 210, 255), accent = rgb(255, 235, 140) },
	primordial = { shell = rgb(60, 26, 92),    dark = rgb(35, 14, 55),    glow = rgb(205, 110, 255), accent = rgb(120, 255, 220) },
	fusion     = { shell = rgb(210, 215, 230), dark = rgb(150, 155, 175), glow = rgb(190, 120, 255), accent = rgb(120, 220, 255) },
}

-- profil : demi-largeur de chaque couche (de bas en haut), couches de 0.5 de haut
local PROFILE = { 0.85, 1.2, 1.42, 1.52, 1.55, 1.5, 1.4, 1.22, 0.98, 0.65 }
local LH = 0.5
Eggs.HEIGHT = #PROFILE * LH

local function newPart(size, color, neon)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = neon and Enum.Material.Neon or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	return p
end

function Eggs.build(style, opts)
	opts = opts or {}
	local st = Eggs.STYLES[style] or Eggs.STYLES.base
	local k = opts.k or 1
	local model = Instance.new("Model")
	model.Name = "Egg_" .. tostring(style)
	local root = newPart(V3(0.2, 0.2, 0.2), st.shell)
	root.Name = "EggRoot"
	root.Transparency = 1
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root
	local info = { shell = {}, glow = {}, style = style, colors = st }
	local half = Eggs.HEIGHT / 2

	-- brique soudee a root ; (x, y, z) en unites de conception, y = 0 au bas de l'oeuf
	local function box(x, y, z, sx, sy, sz, col, neon, rot)
		local p = newPart(V3(sx, sy, sz) * k, col, neon)
		local off = CFrame.new(V3(x, y - half, z) * k) * (rot or CFrame.new())
		p.CFrame = root.CFrame * off
		local w = Instance.new("Weld")
		w.Part0 = root
		w.Part1 = p
		w.C0 = off
		w.Parent = p
		p.Parent = model
		return p
	end

	-- coquille : chaque couche = deux briques en croix (coins arrondis facon lego)
	for i, w in ipairs(PROFILE) do
		local y = (i - 0.5) * LH
		local col = st.shell
		if style == "lave" and i <= 4 then col = st.dark end
		if style == "primordial" and i % 3 == 0 then col = st.dark end
		if style == "celeste" and i >= 8 then col = st.dark end
		table.insert(info.shell, box(0, y, 0, w * 2, LH, w * 1.45, col))
		table.insert(info.shell, box(0, y, 0, w * 1.45, LH, w * 2, col))
	end

	-- position sur la surface : angle a (radians), couche i
	local function surf(a, i, inset)
		local w = PROFILE[i] * 0.98 - (inset or 0)
		return math.cos(a) * w, (i - 0.5) * LH, math.sin(a) * w
	end
	local function faceRot(a) return CFrame.Angles(0, -a + math.pi / 2, 0) end

	if style == "base" then
		for n = 0, 7 do
			local a = n * math.pi / 4 + 0.3
			local i = (n % 2 == 0) and 4 or 7
			local x, y, z = surf(a, i)
			box(x, y, z, 0.55, 0.45, 0.2, (n % 2 == 0) and st.accent or st.glow, false, faceRot(a))
		end
	elseif style == "dore" then
		for _, i in ipairs({ 3, 7 }) do
			local w = PROFILE[i]
			box(0, (i - 0.5) * LH, 0, w * 2 + 0.12, LH * 0.5, w * 1.45 + 0.12, st.accent)
			box(0, (i - 0.5) * LH, 0, w * 1.45 + 0.12, LH * 0.5, w * 2 + 0.12, st.accent)
		end
		for n = 0, 3 do
			local a = n * math.pi / 2 + math.pi / 4
			local x, y, z = surf(a, 5)
			table.insert(info.glow, box(x, y, z, 0.35, 0.35, 0.35, st.glow, true, faceRot(a) * CFrame.Angles(0, 0, math.rad(45))))
		end
		box(0, Eggs.HEIGHT + 0.15, 0, 0.5, 0.3, 0.5, st.glow, true)
	elseif style == "mythique" then
		for n = 0, 5 do
			local a = n * math.pi / 3
			local x, y, z = surf(a, 5)
			table.insert(info.glow, box(x, y, z, 0.18, 0.7, 0.12, st.glow, true, faceRot(a)))
			table.insert(info.glow, box(x, y + 0.2, z, 0.5, 0.15, 0.12, st.glow, true, faceRot(a)))
		end
		box(0, Eggs.HEIGHT + 0.25, 0, 0.6, 0.6, 0.6, st.accent, true, CFrame.Angles(math.rad(45), 0, math.rad(45)))
	elseif style == "lave" then
		-- fissures de magma en zigzag
		for n = 0, 4 do
			local a = n * math.pi * 2 / 5 + 0.2
			for i = 2, 8 do
				local x, y, z = surf(a + ((i % 2 == 0) and 0.08 or -0.08), i)
				table.insert(info.glow, box(x, y, z, 0.16, LH * 1.05, 0.12, st.glow, true, faceRot(a) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 18 or -18))))
			end
		end
		-- petites cornes recourbees
		for _, s in ipairs({ -1, 1 }) do
			box(s * 0.55, Eggs.HEIGHT - 0.2, 0, 0.32, 0.6, 0.32, st.dark, false, CFrame.Angles(0, 0, math.rad(-s * 25)))
			box(s * 0.78, Eggs.HEIGHT + 0.25, 0, 0.26, 0.45, 0.26, st.dark, false, CFrame.Angles(0, 0, math.rad(-s * 45)))
			table.insert(info.glow, box(s * 0.98, Eggs.HEIGHT + 0.5, 0, 0.2, 0.25, 0.2, st.glow, true))
		end
	elseif style == "celeste" then
		for n = 0, 9 do
			local a = n * 2.4
			local i = 2 + (n * 3) % 7
			local x, y, z = surf(a, i)
			table.insert(info.glow, box(x, y, z, 0.22, 0.22, 0.1, (n % 3 == 0) and st.accent or st.glow, true, faceRot(a)))
		end
		-- aureole
		for n = 0, 11 do
			local a = n * math.pi / 6
			box(math.cos(a) * 1.1, Eggs.HEIGHT + 0.6, math.sin(a) * 1.1, 0.6, 0.12, 0.2, st.accent, true, CFrame.Angles(0, -a, 0))
		end
		-- petites ailes en plumes
		for _, s in ipairs({ -1, 1 }) do
			for f = 0, 2 do
				box(s * (1.7 + f * 0.35), 2.9 - f * 0.25, 0.2, 0.45, 0.9 - f * 0.15, 0.15, rgb(240, 245, 255), false, CFrame.Angles(0, 0, math.rad(s * (20 + f * 15))))
			end
		end
	elseif style == "primordial" then
		-- cristaux qui sortent de la coquille
		for n = 0, 6 do
			local a = n * math.pi * 2 / 7
			local i = 3 + (n % 3) * 2
			local x, y, z = surf(a, i, 0.1)
			local tilt = CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-55))
			table.insert(info.glow, box(x * 1.15, y, z * 1.15, 0.35, 0.9 + (n % 2) * 0.4, 0.35, (n % 2 == 0) and st.glow or st.accent, true, tilt))
		end
		table.insert(info.glow, box(0, Eggs.HEIGHT + 0.35, 0, 0.45, 1.0, 0.45, st.glow, true))
	elseif style == "fusion" then
		for _, i in ipairs({ 3, 5, 7 }) do
			local w = PROFILE[i]
			local c = (i == 5) and st.accent or st.glow
			table.insert(info.glow, box(0, (i - 0.5) * LH, 0, w * 2 + 0.1, LH * 0.35, w * 1.45 + 0.1, c, true))
			table.insert(info.glow, box(0, (i - 0.5) * LH, 0, w * 1.45 + 0.1, LH * 0.35, w * 2 + 0.1, c, true))
		end
	end

	local top = Instance.new("Attachment")
	top.Name = "Top"
	top.Position = V3(0, half * k, 0)
	top.Parent = root
	info.top = top
	info.size = V3(PROFILE[5] * 2, Eggs.HEIGHT, PROFILE[5] * 2) * k

	-- l'oeuf de lave fume et crache des flammes
	if style == "lave" then
		local fl = Instance.new("ParticleEmitter")
		fl.Name = "EggFlames"
		fl.Texture = "rbxasset://textures/particles/fire_main.dds"
		fl.Color = ColorSequence.new(rgb(255, 200, 80), rgb(255, 60, 10))
		fl.LightEmission = 0.8
		fl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9 * k), NumberSequenceKeypoint.new(1, 0) })
		fl.Lifetime = NumberRange.new(0.4, 0.7)
		fl.Rate = 25
		fl.Speed = NumberRange.new(1.5, 3)
		fl.SpreadAngle = Vector2.new(20, 20)
		fl.Parent = top
	end
	return model, root, info
end

return Eggs
