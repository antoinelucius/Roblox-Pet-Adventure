-- MWS_PetBricks : animaux en briques lego (Plastic + peau Inlet), construits par code.
-- Convention : l'avant regarde vers -Z, Y vers le haut, les pieds sont a y = 0 (unites de conception ~ 1 stud).
-- Les modeles sont dans les sous-modules (Farm, Cold, Wild, Dragons) : chacun renvoie function(DEFS, H).
local Bricks = {}
local V3 = Vector3.new

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local C = {
	white = rgb(242, 243, 243), cream = rgb(238, 222, 180), tan = rgb(212, 190, 140), black = rgb(34, 34, 40),
	grey = rgb(163, 162, 165), lgrey = rgb(205, 205, 210), dgrey = rgb(99, 95, 98),
	red = rgb(196, 40, 28), dred = rgb(122, 28, 28), orange = rgb(226, 135, 45), yellow = rgb(245, 205, 48),
	lime = rgb(164, 189, 71), green = rgb(75, 151, 75), dgreen = rgb(40, 110, 60),
	blue = rgb(13, 105, 172), lblue = rgb(116, 184, 222), dblue = rgb(32, 58, 134), cyan = rgb(98, 219, 224),
	purple = rgb(123, 70, 160), lpurple = rgb(185, 140, 225), dpurple = rgb(60, 30, 90), pink = rgb(255, 152, 200),
	brown = rgb(105, 64, 40), lbrown = rgb(160, 110, 70), gold = rgb(239, 184, 56),
	ice = rgb(190, 235, 250), navy = rgb(25, 30, 70), magma = rgb(255, 110, 20),
}

local DEFS = {}
local Builder = {}
Builder.__index = Builder

local function newBuilder()
	return setmetatable({ list = {}, groups = {}, flyer = false, hops = false, hmul = 1 }, Builder)
end

-- brique : centre (x,y,z), taille (sx,sy,sz), couleur, groupe optionnel, rotation optionnelle en degres
function Builder:box(x, y, z, sx, sy, sz, col, grp, rx, ry, rz)
	local e = { p = V3(x, y, z), s = V3(sx, sy, sz), c = col or C.white, g = grp }
	if rx or ry or rz then
		e.r = CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	end
	self.list[#self.list + 1] = e
	return e
end

-- brique + son symetrique (x -> -x)
function Builder:mir(x, y, z, sx, sy, sz, col, gl, gr, rx, ry, rz)
	local a = self:box(x, y, z, sx, sy, sz, col, gl, rx, ry, rz)
	local c = self:box(-x, y, z, sx, sy, sz, col, gr or gl, rx, ry and -ry, rz and -rz)
	-- le resultat applique ses champs (neon, trans) aux deux briques
	return setmetatable({}, { __newindex = function(_, k, v) a[k] = v; c[k] = v end })
end

-- paire d'yeux lego (carre + reflet) a x = +-x
function Builder:eye(x, y, z, s, col, grp)
	s = s or 0.5
	for _, sg in ipairs({ -1, 1 }) do
		self:box(sg * x, y, z, s, s * 1.2, 0.2, col or C.black, grp).eye = true
		self:box(sg * x + sg * s * 0.12, y + s * 0.3, z - 0.12, s * 0.4, s * 0.4, 0.1, C.white, grp)
	end
end

-- groupe articule : charniere en (px,py,pz), rotation ax/ay/az * sin(t*speed+phase) * amp
function Builder:group(name, px, py, pz, ax, ay, az, amp, speed, phase)
	self.groups[name] = { pivot = V3(px, py, pz), ax = ax or 0, ay = ay or 0, az = az or 0,
		amp = amp or 0.3, speed = speed or 4, phase = phase or 0 }
end

-- ---------------------------------------------------------------
-- Aides de construction partagees
-- ---------------------------------------------------------------
local H = { C = C }

-- 4 pattes qui oscillent (diagonales en opposition)
function H.legs4(b, x, z, lh, lw, col, footCol, amp, speed)
	local i = 0
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			i += 1
			local gn = "leg" .. i
			b:group(gn, sx * x, lh, sz * z, 1, 0, 0, amp or 0.3, speed or 6, (sx * sz > 0) and 0 or math.pi)
			b:box(sx * x, lh / 2, sz * z, lw, lh, lw, col, gn)
			if footCol then b:box(sx * x, 0.2, sz * z - lw * 0.12, lw + 0.1, 0.4, lw + 0.3, footCol, gn) end
		end
	end
end

-- 2 pattes (oiseaux, bipedes)
function H.legs2(b, x, z, lh, lw, col, footCol, amp, speed)
	for i, sx in ipairs({ -1, 1 }) do
		local gn = "leg" .. i
		b:group(gn, sx * x, lh, z, 1, 0, 0, amp or 0.35, speed or 6, (i == 1) and 0 or math.pi)
		b:box(sx * x, lh / 2, z, lw, lh, lw, col, gn)
		if footCol then b:box(sx * x, 0.2, z - lw * 0.5, lw + 0.5, 0.4, lw + 1.2, footCol, gn) end
	end
end

-- aile a plumes (oiseaux) : charniere a l'epaule, battement autour de Z
function H.wing(b, side, px, py, pz, o)
	o = o or {}
	local gn = (o.gname or "wing") .. (side < 0 and "L" or "R")
	b:group(gn, side * px, py, pz, 0, 0, side, o.amp or 0.55, o.speed or 8, o.phase or 0)
	local n, seg, chord = o.n or 3, o.seg or 2, o.chord or 3
	for i = 1, n do
		local lead = pz - 0.7 + 0.28 * (i - 1)
		local ch = chord * (1 - 0.17 * (i - 1))
		local xc = side * (px + seg * (i - 0.5))
		local col = (i == n) and (o.tip or o.col) or o.col
		b:box(xc, py, lead + ch / 2, seg, (i == 1) and 0.5 or 0.38, ch, col, gn)
		if i >= 2 then
			b:box(xc, py - 0.05, lead + ch + 0.4, seg - 0.25, 0.3, 0.9, o.tip or o.col, gn)
		end
	end
end

-- aile de chauve-souris (dragons, pterodactyle) : os + membrane
function H.batwing(b, side, px, py, pz, o)
	o = o or {}
	local gn = (o.gname or "wing") .. (side < 0 and "L" or "R")
	b:group(gn, side * px, py, pz, 0, 0, side, o.amp or 0.5, o.speed or 7, o.phase or 0)
	local span = o.span or 6
	local chord = o.chord or 3.6
	local bone = o.bone or o.col
	b:box(side * (px + span / 2), py + 0.15, pz - 0.2, span, 0.5, 0.6, bone, gn)
	local n = o.n or 3
	local sw = span / n
	for i = 1, n do
		local ch = chord * (1 - 0.28 * (i - 1))
		local xc = side * (px + sw * (i - 0.5))
		b:box(xc, py - 0.1, pz + ch / 2 - 0.1, sw, 0.22, ch, o.mem or o.col, gn)
		if i < n then
			b:box(side * (px + sw * i), py - 0.05, pz + ch * 0.55, 0.35, 0.35, ch * 1.05, bone, gn)
		end
	end
	b:box(side * (px + span + 0.2), py + 0.55, pz - 0.2, 0.5, 1.0, 0.5, o.claw or bone, gn)
end

-- ---------------------------------------------------------------
-- Mesure + assemblage
-- ---------------------------------------------------------------
local measureCache = {}

function Bricks.has(name)
	return DEFS[name] ~= nil
end

function Bricks.names()
	local t = {}
	for n in pairs(DEFS) do t[#t + 1] = n end
	table.sort(t)
	return t
end

function Bricks.measure(name)
	local c = measureCache[name]
	if c then return c end
	local def = DEFS[name]
	if not def then return nil end
	local b = newBuilder()
	def(b)
	local mn = V3(math.huge, math.huge, math.huge)
	local mx = V3(-math.huge, -math.huge, -math.huge)
	for _, e in ipairs(b.list) do
		local h = e.s / 2
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local off = V3(sx * h.X, sy * h.Y, sz * h.Z)
					if e.r then off = e.r * off end
					local p = e.p + off
					mn = V3(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
					mx = V3(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
				end
			end
		end
	end
	c = { minY = mn.Y, Hd = mx.Y - mn.Y, W = mx.X - mn.X, L = mx.Z - mn.Z, count = #b.list,
		flyer = b.flyer, hops = b.hops, hmul = b.hmul }
	measureCache[name] = c
	return c
end

local function setupPart(part, static)
	part.Anchored = static and true or false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end

-- opts : model (obligatoire), k (echelle), root (Part racine, pour pets animes), static (icones), origin,
-- bright (0..1 : couleurs plus vives pour les pets rares)
-- Renvoie la liste d'animations (format animateList), les infos de mesure, et le "rig" :
-- rig.head = animation de la tete (ou nil), rig.part + rig.mouth = position de la bouche (pour les attaques).
function Bricks.assemble(name, opts)
	local def = DEFS[name]
	if not def then return nil end
	local info = Bricks.measure(name)
	local b = newBuilder()
	def(b)
	local k = opts.k or 1
	local bright = opts.bright or 0
	local model, root, static = opts.model, opts.root, opts.static
	local origin = opts.origin or CFrame.new()
	local center = V3(0, info.Hd / 2, 0)
	local shiftY = -info.minY
	local function rel(p) return V3(p.X, p.Y + shiftY, p.Z) - center end

	local anims, hinges = {}, {}
	local function getHinge(gname)
		local h = hinges[gname]
		if h then return h end
		local g = b.groups[gname]
		if not g then return nil end
		local part = Instance.new("Part")
		part.Name = "Hinge"
		part.Size = V3(0.2, 0.2, 0.2)
		part.Transparency = 1
		setupPart(part, false)
		local pr = rel(g.pivot) * k
		local w = Instance.new("Weld")
		w.Part0 = root
		w.Part1 = part
		w.C0 = CFrame.new(pr)
		w.Parent = part
		part.Parent = model
		h = { part = part, pr = pr }
		hinges[gname] = h
		local entry = { weld = w, base = w.C0, part = part, ax = g.ax, ay = g.ay, az = g.az,
			amp = g.amp, speed = g.speed, phase = g.phase, name = gname }
		anims[#anims + 1] = entry
		h.anim = entry
		return h
	end

	-- bouche = brique la plus en avant de la tete (ou du corps si le pet n'a pas de tete articulee)
	local headName = b.groups.head and "head" or (b.groups.neck and "neck" or nil)
	local mouthZ, mouthOff, mouthHinge = math.huge, nil, nil
	local frontZ, frontOff = math.huge, Vector3.zero

	for _, e in ipairs(b.list) do
		local part = Instance.new("Part")
		part.Name = "Brick"
		part.Size = V3(math.max(e.s.X * k, 0.05), math.max(e.s.Y * k, 0.05), math.max(e.s.Z * k, 0.05))
		local col = e.c
		if bright > 0 and not e.eye then
			local h, s, v = col:ToHSV()
			col = Color3.fromHSV(h, math.min(1, s * (1 + bright * 0.3)), math.min(1, v + bright * 0.35))
		end
		part.Color = col
		if e.eye then part.Name = "Eye" end
		part.Material = e.neon and Enum.Material.Neon or Enum.Material.Plastic
		-- peau en briques "Inlet" (MaterialService), la meme que sur les arbres
		part.MaterialVariant = e.neon and "" or "Inlet"
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if e.trans then part.Transparency = e.trans end
		part.CastShadow = math.max(part.Size.X, part.Size.Y, part.Size.Z) >= 1.4
		setupPart(part, static)
		local rot = e.r or CFrame.new()
		if static then
			part.CFrame = origin * CFrame.new(rel(e.p) * k) * rot
		else
			local h = e.g and getHinge(e.g)
			local rp = rel(e.p) * k
			local fz = rp.Z - part.Size.Z / 2
			if fz < frontZ then frontZ, frontOff = fz, rp + V3(0, 0, -part.Size.Z / 2) end
			if h and e.g == headName and fz < mouthZ then
				mouthZ, mouthOff, mouthHinge = fz, rp - h.pr + V3(0, 0, -part.Size.Z / 2), h
			end
			local w = Instance.new("Weld")
			if h then
				w.Part0 = h.part
				w.C0 = CFrame.new(rel(e.p) * k - h.pr) * rot
			else
				w.Part0 = root
				w.C0 = CFrame.new(rel(e.p) * k) * rot
			end
			w.Part1 = part
			w.Parent = part
		end
		part.Parent = model
	end
	local rig = nil
	if not static then
		rig = {
			head = headName and hinges[headName] and hinges[headName].anim or nil,
			part = mouthHinge and mouthHinge.part or root,
			mouth = mouthOff or frontOff,
		}
	end
	return anims, info, rig
end

-- ---------------------------------------------------------------
-- Chargement des sous-modules de modeles
-- ---------------------------------------------------------------
for _, nm in ipairs({ "Farm", "Cold", "Wild", "Wild2", "Dragons" }) do
	local child = script:WaitForChild(nm, 10)
	if child then
		local ok, fn = pcall(require, child)
		if ok and type(fn) == "function" then
			local ok2, err = pcall(fn, DEFS, H)
			if not ok2 then warn("[PetBricks] " .. nm .. " : " .. tostring(err)) end
		else
			warn("[PetBricks] " .. nm .. " : " .. tostring(fn))
		end
	end
end

return Bricks
