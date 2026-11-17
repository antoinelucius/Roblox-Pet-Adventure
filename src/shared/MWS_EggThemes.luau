-- MWS_EggThemes : l'animation propre a chaque oeuf (client), dans le theme de son monde.
-- La rarete du pet regle la taille de l'animation (niveau 1 a 7, voir playEggCinematic) ;
-- le theme ajoute ce qui rend chaque oeuf unique :
--   base       (Prairie)  : la prairie fleurit, petales et papillons, l'oeuf sautille
--   dore       (Prairie)  : tresor, fontaine de pieces et rayons de soleil, l'oeuf tourne comme une piece
--   mythique   (Volcan)   : orage volcanique, nuage de cendres, meteores et eclairs roses, l'oeuf flotte
--   lave       (Volcan)   : eruption, fissures et geysers de lave (+ petits demons), l'oeuf tremble
--   celeste    (Mythique) : constellation qui se dessine, cometes, l'oeuf s'eleve en tournant
--   primordial (Mythique) : trou noir, spirale, debris aspires et runes, l'oeuf s'enfonce dans le neant
-- Chaque theme : setup(ctx) au debut, motion(ctx, t, dt) -> dy, spin, tilt (mouvement de l'oeuf),
-- beat(ctx) a chaque craquement, burst(ctx, pos) quand l'oeuf eclate.
local TweenService = game:GetService("TweenService")

local T = {}
local V3 = Vector3.new
local WHITE = Color3.new(1, 1, 1)
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local GROUND = -2.7   -- hauteur du sol par rapport au centre de l'oeuf

local function rand(a, b) return a + math.random() * (b - a) end

local function part(ctx, size, color, shape, neon)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = (neon == false) and Enum.Material.SmoothPlastic or Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then p.Shape = shape end
	p.Parent = ctx.folder
	return p
end

local function emitter(parent, tex, c1, c2, size, rate, speed, life)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = tex
	pe.Color = ColorSequence.new(c1, c2 or c1)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(life * 0.6, life)
	pe.Rate = rate
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = parent
	return pe
end

local function tween(obj, time, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- fonction appelee a chaque image (t = temps depuis le debut, dt = duree de l'image)
local function onFrame(ctx, fn) table.insert(ctx.updaters, fn) end

-- fn est appelee toutes les "period" secondes, tant que l'oeuf n'a pas eclate
local function every(ctx, period, fn)
	local acc = 0
	onFrame(ctx, function(t, dt)
		if ctx.S.boom then return end
		acc = acc + dt
		if acc >= period then
			acc = acc - period
			fn(t)
		end
	end)
end

-- objets lances (pieces, petales, lave...) : gravite, rebond au sol, disparition en fondu
local function throw(ctx, p, v, life, opts)
	opts = opts or {}
	if not ctx.bodies then
		ctx.bodies = {}
		onFrame(ctx, function(_, dt)
			for i = #ctx.bodies, 1, -1 do
				local b = ctx.bodies[i]
				b.age = b.age + dt
				if b.age > b.life or not b.p.Parent then
					b.p:Destroy()
					table.remove(ctx.bodies, i)
				else
					b.v = b.v - V3(0, b.g * dt, 0)
					local pos = b.p.Position + b.v * dt
					if b.floor and pos.Y < b.floor then
						pos = V3(pos.X, b.floor, pos.Z)
						b.v = V3(b.v.X * 0.5, -b.v.Y * 0.3, b.v.Z * 0.5)
					end
					b.p.CFrame = CFrame.new(pos) * b.p.CFrame.Rotation * CFrame.Angles(b.spin.X * dt, b.spin.Y * dt, b.spin.Z * dt)
					if b.age > b.life - 0.5 then b.p.Transparency = math.min(1, b.p.Transparency + dt * 2) end
				end
			end
		end)
	end
	table.insert(ctx.bodies, {
		p = p, v = v, age = 0, life = life, g = opts.g or 40, floor = opts.floor,
		spin = opts.spin or V3(rand(-6, 6), rand(-6, 6), rand(-6, 6)),
	})
end

-- point au hasard sur un cercle autour de l'oeuf, au sol
local function around(ctx, r)
	local a = math.random() * math.pi * 2
	return ctx.center + V3(math.cos(a) * r, GROUND, math.sin(a) * r)
end

local function randomDir(up)
	return V3(rand(-1, 1), rand(up or 0.3, 1), rand(-1, 1)).Unit
end

-- ============================================================
-- MONDE 1 : PRAIRIE ENCHANTEE
-- ============================================================
local FLOWERS = { Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 230, 90), Color3.fromRGB(200, 150, 255) }

local function petal(ctx, pos, v)
	local p = part(ctx, V3(0.85, 0.08, 0.6), FLOWERS[math.random(#FLOWERS)], nil, false)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(rand(0, 6), rand(0, 6), 0)
	throw(ctx, p, v, 2.4, { g = 14, floor = ctx.center.Y + GROUND + 0.05 })
end

T.base = {
	setup = function(ctx)
		local L = ctx.level
		-- l'herbe pousse autour de l'oeuf
		for _ = 1, 10 + L * 4 do
			local pos = around(ctx, rand(2.8, 6.5)) + V3(0, -0.05, 0)
			local h = rand(1.2, 2.6)
			local g = part(ctx, V3(0.3, 0.05, 0.5), Color3.fromRGB(80, math.random(180, 230), 60), nil, false)
			local cf = CFrame.new(pos) * CFrame.Angles(0, rand(0, 6), math.rad(rand(-15, 15)))
			g.CFrame = cf
			tween(g, rand(0.6, 1.4), { Size = V3(0.3, h, 0.5), CFrame = cf * CFrame.new(0, h / 2, 0) }, Enum.EasingStyle.Back)
		end
		-- des petales tournent autour de l'oeuf
		local petals = {}
		for i = 1, 6 + L * 2 do
			petals[i] = {
				p = part(ctx, V3(0.85, 0.08, 0.6), FLOWERS[i % #FLOWERS + 1], nil, false),
				r = rand(3.2, 5), h = rand(-1.5, 2), sp = rand(1.2, 2.2) * ((i % 2 == 0) and 1 or -1), ph = rand(0, 6),
			}
		end
		onFrame(ctx, function(t)
			local c = ctx.c
			for _, q in ipairs(petals) do
				local a = t * q.sp + q.ph
				q.p.CFrame = CFrame.new(c + V3(math.cos(a) * q.r, q.h + math.sin(t * 3 + q.ph) * 0.6, math.sin(a) * q.r))
					* CFrame.Angles(math.sin(t * 5 + q.ph), a, math.cos(t * 4 + q.ph))
			end
		end)
		-- papillons (Legendaire et plus)
		if L >= 4 then
			local flies = {}
			for i = 1, (L >= 6) and 5 or 3 do
				local col = FLOWERS[i % #FLOWERS + 1]
				flies[i] = { a = part(ctx, V3(0.6, 0.05, 0.45), col), b = part(ctx, V3(0.6, 0.05, 0.45), col), ph = i * 1.3 }
			end
			onFrame(ctx, function(t)
				for _, f in ipairs(flies) do
					local a = t * 1.3 + f.ph
					local pos = ctx.c + V3(math.cos(a) * 4.5, 1.5 + math.sin(a * 2) * 1.2, math.sin(a) * 4.5)
					local base = CFrame.lookAt(pos, pos + V3(-math.sin(a), 0, math.cos(a)))
					local flap = math.sin(t * 25) * 0.9
					f.a.CFrame = base * CFrame.Angles(0, 0, flap) * CFrame.new(-0.3, 0, 0)
					f.b.CFrame = base * CFrame.Angles(0, 0, -flap) * CFrame.new(0.3, 0, 0)
				end
			end)
		end
		-- feuilles et pollen qui tombent (Epique et plus)
		if L >= 3 then
			local sky = part(ctx, V3(14, 0.2, 14), WHITE)
			sky.Transparency = 1
			sky.CFrame = CFrame.new(ctx.center + V3(0, 7, 0))
			local e = emitter(sky, SPARK, Color3.fromRGB(150, 230, 90), Color3.fromRGB(255, 170, 210), 0.35, 4 + L * 2, 1.5, 3.5)
			e.EmissionDirection = Enum.NormalId.Bottom
			e.SpreadAngle = Vector2.new(20, 20)
		end
	end,
	-- petits bonds de plus en plus hauts
	motion = function(ctx, t)
		return math.abs(math.sin(t * 7)) * (0.25 + ctx.level * 0.06), 0, 0
	end,
	beat = function(ctx)
		for _ = 1, 6 do petal(ctx, ctx.c + V3(0, 1.5, 0), randomDir(0.6) * rand(8, 13)) end
	end,
	-- l'oeuf explose en fleurs
	burst = function(ctx, c)
		for _ = 1, 14 + ctx.level * 5 do petal(ctx, c, randomDir(0.4) * rand(12, 22)) end
	end,
}

-- piece d'or lancee (oeuf dore)
local function coin(ctx, pos, v)
	local p = part(ctx, V3(0.15, 1.15, 1.15), Color3.fromRGB(255, 195, 45), Enum.PartType.Cylinder)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, rand(0, 6), rand(0, 6))
	throw(ctx, p, v, 2.2, { g = 35, floor = ctx.center.Y + GROUND + 0.1, spin = V3(rand(5, 12), 0, rand(-4, 4)) })
end

T.dore = {
	setup = function(ctx)
		local L = ctx.level
		local GOLD = Color3.fromRGB(255, 210, 70)
		-- rayons de soleil qui tournent derriere l'oeuf
		local rays = {}
		local n = 6 + L
		for i = 1, n do
			local r = part(ctx, V3(0.3, 0.3, 8 + L), Color3.fromRGB(255, 240, 160))
			r.Transparency = 0.6
			rays[i] = { p = r, a = i / n * math.pi * 2 }
		end
		onFrame(ctx, function(t)
			local back = ctx.c - ctx.away * 1.5
			for _, ray in ipairs(rays) do
				local a = ray.a + t * 0.4
				local dir = ctx.right * math.cos(a) + Vector3.yAxis * math.sin(a)
				local len = ray.p.Size.Z
				ray.p.CFrame = CFrame.lookAt(back + dir * (len / 2 + 1.5), back + dir * (len + 5), ctx.away)
				ray.p.Transparency = ctx.S.boom and 1 or (0.55 + 0.25 * math.sin(t * 4 + ray.a * 3))
			end
		end)
		-- fontaine de pieces d'or
		every(ctx, math.max(0.08, 0.35 - L * 0.04), function()
			coin(ctx, ctx.c + V3(0, 1.5, 0), V3(rand(-0.4, 0.4), 1, rand(-0.4, 0.4)).Unit * rand(14, 20))
		end)
		emitter(ctx.root, SPARK, GOLD, WHITE, 0.4, 10 + L * 3, 3, 1)
	end,
	-- l'oeuf tourne comme une piece, de plus en plus vite
	motion = function(ctx, t, dt)
		ctx.coinSpin = (ctx.coinSpin or 0) + dt * (2 + ctx.level)
		return 0.2 * math.abs(math.sin(t * 3)), ctx.coinSpin, 0
	end,
	beat = function(ctx)
		for _ = 1, 6 do coin(ctx, ctx.c + V3(0, 1.5, 0), randomDir(0.7) * rand(12, 18)) end
	end,
	-- explosion de pieces
	burst = function(ctx, c)
		for _ = 1, 25 + ctx.level * 8 do coin(ctx, c, randomDir(0.3) * rand(15, 30)) end
	end,
}

-- ============================================================
-- MONDE 2 : ROYAUME VOLCANIQUE
-- ============================================================
-- eclair en zigzag qui frappe l'oeuf
local function bolt(ctx, color)
	local top = ctx.c + V3(rand(-3, 3), 14, rand(-3, 3))
	local bottom = ctx.c + V3(0, 1, 0)
	local prev = top
	for i = 1, 4 do
		local nxt = (i == 4) and bottom or (top:Lerp(bottom, i / 4) + V3(rand(-1.2, 1.2), 0, rand(-1.2, 1.2)))
		local seg = part(ctx, V3(0.4, 0.4, (nxt - prev).Magnitude), color)
		seg.CFrame = CFrame.lookAt((prev + nxt) / 2, nxt, ctx.away)
		task.delay(0.2, function() seg:Destroy() end)
		prev = nxt
	end
end

-- rocher en feu qui tombe du ciel et s'ecrase pres de l'oeuf
local function meteor(ctx)
	local target = around(ctx, rand(4, 9))
	local rock = part(ctx, V3(1.6, 1.6, 1.6), Color3.fromRGB(70, 35, 30), nil, false)
	rock.CFrame = CFrame.new(target + V3(rand(-6, 6), 22, rand(-6, 6)))
	local fire = emitter(rock, FIRE, Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 60, 20), 2.6, 50, 1, 0.5)
	tween(rock, 0.7, { CFrame = CFrame.new(target) * CFrame.Angles(3, 2, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
		if not rock.Parent then return end
		fire.Enabled = false
		emitter(rock, FIRE, Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 60, 20), 1, 0, 8, 0.5):Emit(15)
		local flash = part(ctx, V3(0.3, 1, 1), Color3.fromRGB(255, 120, 40), Enum.PartType.Cylinder)
		flash.CFrame = CFrame.new(target) * CFrame.Angles(0, 0, math.rad(90))
		tween(flash, 0.4, { Size = V3(0.3, 5, 5), Transparency = 1 })
		task.delay(0.6, function() rock:Destroy() end)
	end)
end

T.mythique = {
	setup = function(ctx)
		local L = ctx.level
		-- nuage de cendres au-dessus de l'oeuf
		local cloud = part(ctx, V3(12, 1, 12), Color3.fromRGB(60, 50, 60))
		cloud.Transparency = 1
		cloud.CFrame = CFrame.new(ctx.center + V3(0, 9, 0))
		local smoke = emitter(cloud, SMOKE, Color3.fromRGB(80, 65, 80), Color3.fromRGB(40, 35, 45), 4, 8 + L * 2, 0.5, 4)
		smoke.LightEmission = 0
		smoke.Transparency = NumberSequence.new(0.4, 1)
		-- meteores autour de l'oeuf
		every(ctx, math.max(0.25, 1.1 - L * 0.12), function() meteor(ctx) end)
		-- eclairs roses et turquoise (Epique et plus)
		if L >= 3 then
			every(ctx, math.max(0.35, 1.4 - L * 0.15), function()
				bolt(ctx, (math.random() < 0.5) and ctx.st.glow or ctx.st.accent)
			end)
		end
		emitter(ctx.root, SPARK, ctx.st.glow, ctx.st.accent, 0.35, 8 + L * 2, 2, 0.8)
	end,
	-- l'oeuf flotte et se balance dans l'orage
	motion = function(_, t)
		return 0.5 + math.sin(t * 2) * 0.35, 0, math.sin(t * 3) * 0.12
	end,
	beat = function(ctx)
		bolt(ctx, ctx.st.glow)
		bolt(ctx, ctx.st.accent)
	end,
	-- eclats de roche volcanique et d'energie rose
	burst = function(ctx, c)
		for i = 1, 14 + ctx.level * 4 do
			local s = rand(0.4, 0.9)
			local rock = part(ctx, V3(s, s, s), (i % 3 == 0) and ctx.st.glow or Color3.fromRGB(55, 40, 45), nil, i % 3 == 0)
			rock.CFrame = CFrame.new(c)
			throw(ctx, rock, randomDir(0.3) * rand(14, 26), 2.4, { g = 35, floor = ctx.center.Y + GROUND + s / 2 })
		end
	end,
}

-- geyser de lave qui jaillit du sol
local function geyser(ctx)
	local base = around(ctx, rand(4, 8)) + V3(0, -0.1, 0)
	local h = rand(5, 9) + ctx.level * 0.4
	local up = CFrame.Angles(0, 0, math.rad(90))
	local col = part(ctx, V3(0.1, 1.4, 1.4), Color3.fromRGB(255, 120, 20), Enum.PartType.Cylinder)
	col.CFrame = CFrame.new(base) * up
	tween(col, 0.35, { Size = V3(h, 1.4, 1.4), CFrame = CFrame.new(base + V3(0, h / 2, 0)) * up })
	local spray = emitter(col, FIRE, Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 60, 10), 1.2, 0, 8, 0.7)
	spray.EmissionDirection = Enum.NormalId.Right
	spray.SpreadAngle = Vector2.new(25, 25)
	task.delay(0.35, function()
		if not col.Parent then return end
		spray:Emit(18)
		for _ = 1, 3 do
			local blob = part(ctx, V3(0.5, 0.5, 0.5), Color3.fromRGB(255, 140, 30), Enum.PartType.Ball)
			blob.CFrame = CFrame.new(base + V3(0, h, 0))
			throw(ctx, blob, V3(rand(-1, 1), 1.5, rand(-1, 1)).Unit * rand(8, 12), 1.6, { g = 40, floor = ctx.center.Y + GROUND + 0.25 })
		end
		tween(col, 0.5, { Size = V3(0.1, 0.6, 0.6), CFrame = CFrame.new(base) * up, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end

T.lave = {
	setup = function(ctx)
		local L = ctx.level
		-- fissures de lave qui s'ouvrent dans le sol
		local n = 6 + L
		for i = 1, n do
			local a = i / n * math.pi * 2 + rand(-0.2, 0.2)
			local dir = V3(math.cos(a), 0, math.sin(a))
			local len = rand(3, 5 + L * 0.6)
			local start = ctx.center + V3(0, GROUND - 0.02, 0) + dir * 1.8
			local crack = part(ctx, V3(0.3, 0.08, 0.1), Color3.fromRGB(255, 110, 20))
			crack.CFrame = CFrame.lookAt(start, start + dir)
			tween(crack, 0.8, { Size = V3(0.3, 0.08, len), CFrame = CFrame.lookAt(start + dir * len / 2, start + dir * len) })
		end
		-- geysers de lave
		every(ctx, math.max(0.2, 0.8 - L * 0.08), function() geyser(ctx) end)
		emitter(ctx.root, FIRE, Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 50, 10), 1.2, 6 + L * 4, 4, 0.6)
		-- petits demons qui tournent autour (Mythique et plus)
		if L >= 5 and ctx.makeImp then
			for i = 1, 5 do
				table.insert(ctx.imps, { obj = ctx.makeImp(ctx.folder, 1.4), r = 2.1 * ctx.SC, h = (0.2 + (i % 2) * 0.5) * ctx.SC })
			end
		end
	end,
	-- l'oeuf tremble comme un volcan pret a exploser
	motion = function(ctx)
		local k = 0.03 + ctx.level * 0.012
		return rand(-0.05, 0.12) * ctx.level * 0.3, 0, rand(-k, k)
	end,
	beat = function(ctx)
		geyser(ctx)
		geyser(ctx)
	end,
	-- l'oeuf explose en gerbes de lave
	burst = function(ctx, c)
		for _ = 1, 12 + ctx.level * 4 do
			local s = rand(0.4, 0.9)
			local blob = part(ctx, V3(s, s, s), Color3.fromRGB(255, math.random(90, 160), 20), Enum.PartType.Ball)
			blob.CFrame = CFrame.new(c)
			throw(ctx, blob, randomDir(0.5) * rand(14, 24), 2.4, { g = 35, floor = ctx.center.Y + GROUND + s / 2 })
		end
	end,
}

-- ============================================================
-- MONDE 3 : DIMENSION MYTHIQUE
-- ============================================================
-- comete qui traverse le ciel derriere l'oeuf
local function comet(ctx)
	local c = ctx.c - ctx.away * 6
	local from = c + ctx.right * rand(-15, -9) + V3(0, rand(6, 11), 0)
	local to = c + ctx.right * rand(9, 15) + V3(0, rand(-2, 3), 0)
	if math.random() < 0.5 then
		from, to = to + V3(0, 6, 0), from - V3(0, 6, 0)
	end
	local head = part(ctx, V3(0.6, 0.6, 0.6), WHITE, Enum.PartType.Ball)
	head.CFrame = CFrame.new(from)
	local a0 = Instance.new("Attachment")
	a0.Position = V3(0, 0.25, 0)
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Position = V3(0, -0.25, 0)
	a1.Parent = head
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.5
	trail.Color = ColorSequence.new(WHITE, ctx.st.glow)
	trail.LightEmission = 1
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.FaceCamera = true
	trail.Parent = head
	tween(head, 0.9, { CFrame = CFrame.new(to) }, Enum.EasingStyle.Linear).Completed:Connect(function()
		task.delay(0.5, function() head:Destroy() end)
	end)
end

T.celeste = {
	setup = function(ctx)
		local L = ctx.level
		local STAR = Color3.fromRGB(255, 245, 200)
		-- une constellation se dessine etoile apres etoile autour de l'oeuf
		local stars = {}
		local n = 5 + L
		for i = 1, n do
			local s = part(ctx, V3(0.5, 0.5, 0.5), (i % 3 == 0) and ctx.st.glow or STAR, Enum.PartType.Ball)
			s.Transparency = 1
			local att = Instance.new("Attachment")
			att.Parent = s
			stars[i] = { p = s, a = i / n * math.pi * 2, h = rand(-1, 3), r = rand(4, 6), att = att }
			task.delay(i * 0.18, function()
				if s.Parent then tween(s, 0.3, { Transparency = 0 }) end
			end)
			if i > 1 then
				task.delay(i * 0.18 + 0.2, function()
					if not s.Parent then return end
					local beam = Instance.new("Beam")
					beam.Attachment0, beam.Attachment1 = stars[i - 1].att, att
					beam.Width0, beam.Width1 = 0.25, 0.25
					beam.Color = ColorSequence.new(ctx.st.glow)
					beam.LightEmission = 1
					beam.FaceCamera = true
					beam.Transparency = NumberSequence.new(0.2)
					beam.Parent = s
				end)
			end
		end
		onFrame(ctx, function(t)
			for _, s in ipairs(stars) do
				local a = s.a + t * 0.35
				s.p.CFrame = CFrame.new(ctx.c + V3(math.cos(a) * s.r, s.h, math.sin(a) * s.r))
				local size = 0.8 + 0.25 * math.sin(t * 6 + s.a * 4)
				s.p.Size = V3(size, size, size)
			end
		end)
		-- cometes
		every(ctx, math.max(0.3, 1.2 - L * 0.12), function() comet(ctx) end)
		emitter(ctx.root, SPARK, ctx.st.glow, STAR, 0.35, 8 + L * 2, 2, 1)
	end,
	-- l'oeuf s'eleve lentement en tournant
	motion = function(ctx, t)
		return math.min(1.5, t * 0.25) * (0.5 + ctx.level * 0.08), t * 0.6, 0
	end,
	beat = function(ctx)
		comet(ctx)
		comet(ctx)
	end,
	-- explosion d'etoiles : rayons de lumiere et etoiles qui s'envolent
	burst = function(ctx, c)
		for _ = 1, 16 + ctx.level * 4 do
			local dir = randomDir(-1)
			local ray = part(ctx, V3(0.15, 0.15, 1), (math.random() < 0.5) and WHITE or ctx.st.glow)
			ray.CFrame = CFrame.lookAt(c + dir, c + dir * 2)
			local len = rand(5, 9 + ctx.level)
			tween(ray, 0.6, { Size = V3(0.15, 0.15, len), CFrame = CFrame.lookAt(c + dir * (1 + len / 2), c + dir * (2 + len)), Transparency = 1 })
			task.delay(0.65, function() ray:Destroy() end)
		end
		for _ = 1, 8 + ctx.level * 2 do
			local s = part(ctx, V3(0.4, 0.4, 0.4), Color3.fromRGB(255, 245, 200), Enum.PartType.Ball)
			s.CFrame = CFrame.new(c)
			throw(ctx, s, randomDir(-1) * rand(6, 12), 2.5, { g = 0 })
		end
	end,
}

T.primordial = {
	setup = function(ctx)
		local L = ctx.level
		local P, A = ctx.st.glow, ctx.st.accent
		local floor = ctx.center + V3(0, GROUND, 0)
		-- un trou noir s'ouvre sous l'oeuf, avec des bras de spirale
		local hole = part(ctx, V3(0.2, 1, 1), Color3.new(0, 0, 0), Enum.PartType.Cylinder, false)
		hole.CFrame = CFrame.new(floor) * CFrame.Angles(0, 0, math.rad(90))
		tween(hole, 1, { Size = V3(0.2, 7, 7) })
		local arms = {}
		for arm = 1, 3 do
			for j = 1, 10 do
				table.insert(arms, { p = part(ctx, V3(0.8, 0.1, 0.8), (j % 2 == 0) and P or A), arm = arm, j = j })
			end
		end
		-- runes qui tournent autour de l'oeuf
		local runes = {}
		local n = 6 + L
		for i = 1, n do
			runes[i] = { p = part(ctx, V3(0.3, 1.1, 0.12), (i % 2 == 0) and P or A), a = i / n * math.pi * 2 }
		end
		onFrame(ctx, function(t)
			local spin = t * (1.5 + L * 0.2)
			for _, s in ipairs(arms) do
				local frac = s.j / 10
				local a = spin + s.arm / 3 * math.pi * 2 + frac * 2.6
				local r = 3.4 + frac * 6
				s.p.CFrame = CFrame.new(floor + V3(math.cos(a) * r, 0.03, math.sin(a) * r)) * CFrame.Angles(0, -a, 0)
				s.p.Transparency = frac * 0.6
			end
			for _, r in ipairs(runes) do
				local a = r.a - t * 1.2
				local pos = ctx.c + V3(math.cos(a) * 4.2, math.sin(t * 2 + r.a) * 0.5, math.sin(a) * 4.2)
				r.p.CFrame = CFrame.lookAt(pos, ctx.c)
			end
		end)
		-- des debris sont aspires en spirale vers l'oeuf
		local debris = {}
		every(ctx, math.max(0.06, 0.3 - L * 0.03), function()
			local s = rand(0.25, 0.55)
			table.insert(debris, {
				p = part(ctx, V3(s, s, s), (math.random() < 0.6) and Color3.fromRGB(30, 20, 40) or P, nil, math.random() < 0.4),
				a = rand(0, 6.28), r0 = rand(8, 11), h0 = rand(-2, 4), age = 0, dur = rand(1, 1.6),
			})
		end)
		onFrame(ctx, function(_, dt)
			for i = #debris, 1, -1 do
				local d = debris[i]
				d.age = d.age + dt
				local k = d.age / d.dur
				if k >= 1 or not d.p.Parent then
					d.p:Destroy()
					table.remove(debris, i)
				else
					local r = d.r0 * (1 - k)
					d.a = d.a + dt * (2 + 4 * k)
					d.p.CFrame = CFrame.new(ctx.c + V3(math.cos(d.a) * r, d.h0 * (1 - k), math.sin(d.a) * r)) * CFrame.Angles(d.a, d.a * 2, 0)
				end
			end
		end)
	end,
	-- l'oeuf s'enfonce et pulse en tournant a l'envers
	motion = function(ctx, t)
		return -0.4 + math.sin(t * 5) * 0.12, -t * (1 + ctx.level * 0.3), 0
	end,
	-- implosion : une sphere du neant se referme sur l'oeuf
	beat = function(ctx)
		local s = part(ctx, V3(14, 14, 14), ctx.st.glow, Enum.PartType.Ball)
		s.Transparency = 0.75
		s.CFrame = CFrame.new(ctx.c)
		tween(s, 0.3, { Size = V3(1, 1, 1), Transparency = 0.2 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.32, function() s:Destroy() end)
	end,
	-- l'oeuf est aspire puis tout est rejete : eclats du neant qui flottent
	burst = function(ctx, c)
		local void = part(ctx, V3(1, 1, 1), Color3.new(0, 0, 0), Enum.PartType.Ball, false)
		void.CFrame = CFrame.new(c)
		tween(void, 0.6, { Size = V3(12, 12, 12), Transparency = 1 })
		for i = 1, 14 + ctx.level * 4 do
			local s = rand(0.3, 0.7)
			local shard = part(ctx, V3(s, s * 2, s), (i % 2 == 0) and ctx.st.glow or ctx.st.accent)
			shard.CFrame = CFrame.new(c)
			throw(ctx, shard, randomDir(-1) * rand(8, 16), 2.5, { g = 0 })
		end
	end,
}

return T
