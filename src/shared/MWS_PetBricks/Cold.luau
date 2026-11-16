-- Tortue, Hibou des neiges, Panda roux, Pterodactyle, Pegase, Phenix
return function(DEFS, H)
	local C = H.C
	local function rgb(r, g, bl) return Color3.fromRGB(r, g, bl) end

	-- ===== TORTUE =====
DEFS["Tortue"] = function(b)
		b.hmul = 0.8
		local g, dg, sk, tn = C.green, C.dgreen, C.lime, C.tan
		for i, p in ipairs({ { -2.3, -2.0 }, { 2.3, -2.0 }, { -2.3, 2.0 }, { 2.3, 2.0 } }) do
			local gn = "leg" .. i
			b:group(gn, p[1], 1.5, p[2], 1, 0, 0, 0.3, 6, (i % 2 == 0) and 0 or math.pi)
			b:box(p[1], 0.8, p[2], 1.3, 1.6, 1.4, sk, gn)
			b:box(p[1], 0.1, p[2] - 0.5, 1.1, 0.2, 0.4, C.white, gn)
		end
		-- carapace en dome avec ecailles
		b:box(0, 1.9, 0, 5.4, 0.7, 6.0, tn)
		b:box(0, 2.45, 0, 5.8, 0.4, 6.4, dg)
		b:box(0, 3.2, 0, 5.2, 1.4, 5.8, g)
		b:box(0, 4.2, 0, 4.2, 0.9, 4.8, g)
		b:box(0, 4.9, 0, 2.8, 0.6, 3.4, g)
		b:box(0, 5.22, -0.8, 1.4, 0.1, 1.2, sk)
		b:box(0, 5.22, 0.8, 1.4, 0.1, 1.2, sk)
		b:mir(1.5, 4.66, -1.4, 1.0, 0.1, 1.2, sk)
		b:mir(1.5, 4.66, 1.2, 1.0, 0.1, 1.2, sk)
		for _, z in ipairs({ -2.0, 0, 2.0 }) do
			b:mir(2.25, 3.92, z, 0.7, 0.1, 1.2, dg)
		end
		-- tete avec bec
		b:group("head", 0, 2.8, -3.0, 1, 0, 0, 0.1, 2.5, 0)
		b:box(0, 2.7, -3.6, 1.2, 1.1, 1.4, sk, "head")
		b:box(0, 3.0, -4.6, 1.8, 1.6, 1.8, sk, "head")
		b:box(0, 2.6, -5.55, 1.2, 0.45, 0.2, rgb(190, 170, 70), "head")
		b:eye(0.55, 3.3, -5.52, 0.3, nil, "head")
		b:group("tail", 0, 2.1, 3.0, 0, 1, 0, 0.4, 5, 0)
		b:box(0, 2.1, 3.6, 0.7, 0.7, 1.2, sk, "tail")
	end

	-- ===== HIBOU DES NEIGES =====
DEFS["Hibou des neiges"] = function(b)
		b.flyer = true
		local w, gy, o, y = C.white, C.grey, C.orange, C.yellow
		b:mir(0.9, 0.8, -0.2, 0.7, 1.6, 0.7, w)
		b:mir(0.9, 0.2, -0.6, 1.1, 0.4, 1.5, C.dgrey)
		b:box(0, 3.8, 0, 3.6, 4.4, 3.2, w)
		-- mouchetures
		for _, p in ipairs({ { -0.8, 4.6 }, { 0.6, 4.0 }, { -0.4, 3.3 }, { 1.0, 2.8 }, { -1.0, 2.6 }, { 0.2, 5.2 } }) do
			b:box(p[1], p[2], -1.63, 0.5, 0.25, 0.1, gy)
		end
		b:group("head", 0, 6.0, 0, 1, 0, 0, 0.05, 3, 0)
		b:box(0, 7.1, -0.2, 3.6, 2.6, 3.0, w, "head")
		-- disque facial + gros yeux jaunes
		b:box(0, 7.1, -1.72, 3.0, 2.2, 0.1, rgb(250, 250, 245), "head")
		b:mir(0.8, 7.4, -1.8, 1.1, 1.1, 0.1, y, "head", "head")
		b:mir(0.8, 7.4, -1.86, 0.55, 0.65, 0.05, C.black, "head", "head")
		b:box(0, 6.75, -1.95, 0.5, 0.7, 0.4, C.dgrey, "head")
		b:mir(1.3, 8.6, -0.4, 0.6, 0.7, 0.6, gy, "head", "head")
		b:box(0, 2.4, 2.5, 1.8, 0.5, 2.6, w)
		b:box(0, 2.35, 4.0, 1.4, 0.4, 1.0, gy)
		H.wing(b, -1, 1.8, 5.4, 0.2, { n = 3, seg = 2.2, chord = 3.2, col = w, tip = gy, amp = 0.6 })
		H.wing(b, 1, 1.8, 5.4, 0.2, { n = 3, seg = 2.2, chord = 3.2, col = w, tip = gy, amp = 0.6 })
	end

	-- ===== PANDA ROUX =====
DEFS["Panda roux"] = function(b)
		local r, r2, w, dk = rgb(190, 85, 40), rgb(140, 60, 30), C.white, rgb(60, 35, 30)
		H.legs4(b, 1.0, 1.5, 2.0, 1.0, dk, dk)
		b:box(0, 3.2, 0, 3.0, 2.4, 4.2, r)
		b:box(0, 2.05, 0, 2.6, 0.2, 3.8, dk)
		b:group("head", 0, 4.2, -1.8, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 4.8, -2.6, 3.0, 2.2, 2.2, r, "head")
		-- masque blanc, sourcils, larmes sombres
		b:mir(0.9, 4.7, -3.72, 0.9, 1.4, 0.15, w, "head", "head")
		b:mir(0.75, 5.7, -3.74, 0.5, 0.25, 0.1, w, "head", "head")
		b:mir(0.9, 4.15, -3.82, 0.3, 0.8, 0.1, r2, "head", "head")
		b:mir(1.5, 4.4, -3.1, 0.3, 0.9, 1.0, w, "head", "head")
		b:box(0, 4.3, -3.9, 1.0, 0.8, 0.4, w, "head")
		b:box(0, 4.55, -4.15, 0.5, 0.4, 0.2, C.black, "head")
		b:eye(0.75, 5.1, -3.84, 0.35, nil, "head")
		b:mir(1.2, 6.2, -2.3, 0.9, 1.0, 0.6, r, "head", "head")
		b:mir(1.2, 6.2, -2.62, 0.5, 0.6, 0.15, w, "head", "head")
		-- longue queue touffue a anneaux
		b:group("tail", 0, 3.6, 2.1, 0, 1, 0, 0.35, 4, 0)
		for i = 0, 4 do
			local s = 1.7 - i * 0.08
			b:box(0, 3.8 + i * 0.1, 2.9 + i * 1.2, s, s, 1.2, (i % 2 == 0) and r or r2, "tail")
		end
		b:box(0, 4.3, 8.5, 1.3, 1.3, 0.8, dk, "tail")
	end

	-- ===== PTERODACTYLE =====
DEFS["Pterodactyle"] = function(b)
		b.flyer = true
		local c, lt, m, cr, bk = rgb(120, 95, 80), rgb(175, 145, 115), rgb(190, 120, 80), rgb(200, 60, 40), C.cream
		-- petites pattes arriere
		b:mir(0.6, 0.7, 0.8, 0.45, 1.4, 0.45, c)
		b:mir(0.6, 0.15, 0.4, 0.8, 0.3, 1.2, C.dgrey)
		-- corps fin + poitrail clair
		b:box(0, 2.6, 0.4, 2.0, 2.0, 3.2, c)
		b:box(0, 2.8, -1.1, 1.8, 1.8, 0.6, lt)
		b:box(0, 3.9, -1.6, 0.9, 1.8, 1.0, c, nil, -25)
		-- tete : long bec effile + crete osseuse vers l'arriere
		b:group("head", 0, 4.6, -1.9, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 5.1, -2.4, 1.3, 1.2, 1.6, c, "head")
		b:box(0, 4.95, -3.9, 0.9, 0.7, 1.6, bk, "head")
		b:box(0, 4.85, -5.3, 0.6, 0.5, 1.4, bk, "head")
		b:box(0, 4.8, -6.4, 0.35, 0.35, 1.0, bk, "head")
		b:box(0, 5.7, -1.4, 0.3, 0.7, 1.8, cr, "head", 15)
		b:box(0, 6.05, -0.2, 0.25, 0.5, 1.4, cr, "head", 22)
		b:eye(0.5, 5.35, -3.22, 0.28, nil, "head")
		b:box(0, 2.4, 2.5, 0.5, 0.5, 1.6, c)
		-- grandes ailes membraneuses
		H.batwing(b, -1, 0.9, 3.2, -0.4, { span = 9, chord = 4.6, col = c, mem = m, bone = c, claw = bk, n = 4, amp = 0.55 })
		H.batwing(b, 1, 0.9, 3.2, -0.4, { span = 9, chord = 4.6, col = c, mem = m, bone = c, claw = bk, n = 4, amp = 0.55 })
	end

	-- ===== PEGASE =====
DEFS["Pegase"] = function(b)
		b.flyer = true
		H.horse(b, { c = rgb(205, 228, 248), hoof = C.lgrey, muzzle = rgb(185, 210, 235),
			mane = { C.dblue, C.blue }, tailCols = { C.dblue, C.blue } })
		H.wing(b, -1, 1.4, 6.0, -0.6, { n = 4, seg = 2.3, chord = 3.6, col = C.white, tip = C.lblue, amp = 0.55 })
		H.wing(b, 1, 1.4, 6.0, -0.6, { n = 4, seg = 2.3, chord = 3.6, col = C.white, tip = C.lblue, amp = 0.55 })
	end

	-- ===== PHENIX =====
DEFS["Phenix"] = function(b)
		b.flyer = true
		local r, o, y, gd = C.red, C.orange, C.yellow, C.gold
		-- pattes d'oiseau + serres
		b:mir(0.6, 0.95, 0.1, 0.4, 1.9, 0.4, gd)
		b:mir(0.6, 0.15, -0.35, 0.9, 0.3, 1.2, gd)
		b:mir(0.6, 0.15, -1.05, 0.25, 0.25, 0.3, C.white)
		-- corps rond : dos rouge, poitrail orange, ventre jaune
		b:box(0, 3.4, 0.3, 3.0, 2.8, 4.0, r)
		b:box(0, 3.6, -1.6, 2.6, 2.6, 1.4, o)
		b:box(0, 3.1, -2.34, 1.8, 1.6, 0.1, y)
		b:box(0, 5.0, -1.4, 1.8, 1.4, 1.6, o)
		-- tete : bec crochu dore + crete de flammes
		b:group("head", 0, 5.4, -1.6, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 6.2, -2.0, 2.0, 1.8, 2.0, r, "head")
		b:box(0, 6.1, -3.4, 0.8, 0.6, 0.9, gd, "head")
		b:box(0, 5.75, -3.75, 0.5, 0.5, 0.3, gd, "head")
		b:eye(0.6, 6.5, -3.02, 0.32, nil, "head")
		b:box(0, 7.6, -1.7, 0.4, 1.4, 0.4, y, "head", -20).neon = true
		b:box(0, 7.8, -1.1, 0.4, 1.7, 0.4, o, "head", -38).neon = true
		b:box(0, 7.4, -0.5, 0.35, 1.4, 0.35, r, "head", -55).neon = true
		-- queue : 5 longues plumes en eventail
		b:group("tail", 0, 3.6, 2.2, 1, 0, 0, 0.15, 4, 0)
		for i, a in ipairs({ -28, -14, 0, 14, 28 }) do
			local len = (a == 0) and 5.0 or 4.0
			local sn, cs = math.sin(math.rad(a)), math.cos(math.rad(a))
			local d = 0.4 + len / 2
			local col = (i % 2 == 0) and o or r
			b:box(sn * d, 3.4 - len * 0.1, 2.2 + cs * d, 0.8, 0.35, len, col, "tail", 0, a, 0)
			local dt = 0.4 + len + 0.6
			b:box(sn * dt, 3.4 - len * 0.2, 2.2 + cs * dt, 0.7, 0.35, 1.3, y, "tail", 0, a, 0).neon = true
		end
		H.wing(b, -1, 1.4, 4.5, 0.1, { n = 5, seg = 2.0, chord = 3.6, col = o, tip = y, amp = 0.6 })
		H.wing(b, 1, 1.4, 4.5, 0.1, { n = 5, seg = 2.0, chord = 3.6, col = o, tip = y, amp = 0.6 })
	end
end
