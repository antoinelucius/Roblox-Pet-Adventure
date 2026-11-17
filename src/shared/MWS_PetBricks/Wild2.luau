-- Yeti, Kitsune, Roi serpent, Tyrannosaure, Tigre sabre, Cerbere
return function(DEFS, H)
	local C = H.C
	local function rgb(r, g, bl) return Color3.fromRGB(r, g, bl) end

	-- ===== YETI =====
DEFS["Yeti"] = function(b)
		local w, ic, bl = C.white, C.ice, rgb(110, 160, 205)
		for i, s in ipairs({ -1, 1 }) do
			local gn = "leg" .. i
			b:group(gn, s * 1.3, 3.4, 0, 1, 0, 0, 0.3, 5, (i == 1) and 0 or math.pi)
			b:box(s * 1.3, 1.7, 0, 2.0, 3.4, 2.2, w, gn)
			b:box(s * 1.3, 0.3, -0.5, 2.2, 0.6, 3.0, bl, gn)
			b:box(s * 1.3, 1.2, -1.15, 2.2, 0.8, 0.2, w, gn)
		end
		-- corps poilu, touffes sur le torse
		b:box(0, 5.8, 0, 4.8, 4.4, 3.4, w)
		b:box(0, 5.4, -1.78, 3.2, 2.8, 0.15, ic)
		for _, y in ipairs({ 4.4, 5.4, 6.4 }) do
			b:box(0, y, -1.9, 2.4, 0.3, 0.15, w)
		end
		b:mir(2.7, 7.8, 0, 1.6, 1.4, 2.6, ic)
		-- longs bras avec touffes aux coudes
		for i, s in ipairs({ -1, 1 }) do
			local gn = (s < 0) and "armL" or "armR"
			b:group(gn, s * 3.3, 7.6, 0, 1, 0, 0, 0.3, 5, (i == 1) and math.pi or 0)
			b:box(s * 3.5, 4.8, 0, 1.6, 5.6, 1.8, w, gn)
			b:box(s * 4.35, 5.4, 0, 0.5, 1.2, 1.2, w, gn)
			b:box(s * 3.5, 1.8, -0.1, 2.0, 1.2, 2.2, bl, gn)
			b:box(s * 3.5, 1.2, -1.0, 1.6, 0.5, 0.3, C.white, gn)
		end
		-- tete : grosse fourrure sur les sourcils, gueule ouverte, petites cornes
		b:group("head", 0, 8.0, -0.2, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 9.4, -0.5, 3.4, 2.6, 2.8, w, "head")
		b:box(0, 9.2, -1.95, 2.4, 1.8, 0.15, bl, "head")
		b:box(0, 10.2, -2.1, 2.8, 0.5, 0.3, w, "head")
		b:eye(0.7, 9.6, -2.1, 0.4, C.cyan, "head")
		b:box(0, 8.6, -2.05, 1.6, 0.7, 0.15, C.black, "head")
		b:mir(0.45, 8.75, -2.13, 0.25, 0.4, 0.1, C.white, "head", "head")
		b:mir(1.1, 10.9, -0.6, 0.5, 1.1, 0.5, ic, "head", "head", 0, 0, 15)
	end

	-- ===== KITSUNE =====
	DEFS["Kitsune"] = function(b)
		local w, rd, bl, gd = C.white, C.red, rgb(80, 170, 255), C.gold
		H.legs4(b, 0.9, 1.7, 2.1, 0.8, w, C.dgrey)
		b:box(0, 3.2, 0, 2.6, 2.2, 4.6, w)
		b:box(0, 4.3, -2.0, 2.8, 0.5, 0.8, rd)
		b:box(0, 3.4, -2.35, 1.8, 1.6, 0.3, w)
		b:box(0, 3.85, -2.45, 0.5, 0.5, 0.3, gd).neon = true
		b:group("head", 0, 4.0, -2.0, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 4.9, -3.0, 2.4, 2.0, 2.2, w, "head")
		b:box(0, 4.5, -4.5, 1.2, 0.9, 1.2, w, "head")
		b:box(0, 4.75, -5.15, 0.5, 0.4, 0.3, C.black, "head")
		b:mir(0.8, 6.5, -2.6, 0.7, 1.7, 0.6, w, "head", "head")
		b:mir(0.8, 6.3, -2.93, 0.4, 1.0, 0.15, rd, "head", "head")
		b:mir(0.8, 7.5, -2.6, 0.5, 0.4, 0.45, bl, "head", "head").neon = true
		b:mir(1.0, 4.7, -4.12, 0.5, 0.25, 0.1, rd, "head", "head")
		b:box(0, 5.55, -4.12, 0.4, 0.6, 0.1, rd, "head")
		b:box(0, 5.9, -4.14, 0.35, 0.35, 0.1, gd, "head").neon = true
		b:eye(0.6, 5.1, -4.12, 0.35, bl, "head")
		for i = -2, 2 do
			local gn = "tail" .. (i + 3)
			local a = i * 24
			local sn, cs = math.sin(math.rad(a)), math.cos(math.rad(a))
			local py, pz = 3.8, 2.3
			local lift = 0.35 * (2 - math.abs(i))
			b:group(gn, 0, py, pz, 0, 1, 0, 0.12, 3, i)
			b:box(sn * 1.7, py + 0.4 + lift, pz + cs * 1.7, 1.5, 1.5, 2.6, w, gn, 0, a, 0)
			b:box(sn * 3.6, py + 0.5 + lift, pz + cs * 3.6, 1.3, 1.3, 1.6, w, gn, 0, a, 0)
			b:box(sn * 4.9, py + 0.5 + lift, pz + cs * 4.9, 1.0, 1.0, 1.2, bl, gn, 0, a, 0).neon = true
		end
	end

	-- ===== ROI SERPENT =====
DEFS["Roi serpent"] = function(b)
		local k, pl, hd = rgb(45, 45, 35), rgb(225, 205, 120), rgb(70, 65, 45)
		-- corps enroule (2 anneaux)
		for layer, cfg in ipairs({ { r = 2.5, y = 0.75, s = 1.5, n = 12 }, { r = 1.7, y = 2.1, s = 1.3, n = 9 } }) do
			for j = 0, cfg.n - 1 do
				local th = j / cfg.n * math.pi * 2 + layer
				local seg = 2 * math.pi * cfg.r / cfg.n * 1.15
				local col = (j % 3 == 0) and pl or k
				b:box(cfg.r * math.sin(th), cfg.y, cfg.r * math.cos(th), cfg.s, cfg.s, seg, col, nil, 0, math.deg(th) + 90, 0)
			end
		end
		-- cou dresse + capuchon large
		b:group("neck", 0, 2.8, -0.6, 0, 1, 0, 0.25, 2, 0)
		b:box(0, 3.5, -0.7, 1.3, 1.6, 1.3, k, "neck")
		b:box(0, 4.9, -0.9, 1.2, 1.6, 1.2, pl, "neck")
		b:box(0, 6.3, -1.1, 1.2, 1.6, 1.2, k, "neck")
		b:box(0, 7.7, -0.4, 3.8, 3.4, 0.5, hd, "neck")
		b:box(0, 7.3, -0.68, 1.6, 2.2, 0.1, pl, "neck")
		b:mir(1.3, 7.9, -0.68, 0.6, 0.6, 0.1, k, "neck", "neck")
		-- tete
		b:box(0, 8.4, -1.6, 1.8, 1.1, 2.4, k, "neck")
		b:box(0, 8.25, -3.0, 1.3, 0.8, 0.8, k, "neck")
		b:mir(0.92, 8.6, -2.2, 0.1, 0.35, 0.4, C.yellow, "neck", "neck")
		b:box(0, 8.0, -3.6, 0.2, 0.08, 0.8, C.red, "neck")
		-- couronne du roi
		b:box(0, 9.1, -1.6, 1.4, 0.35, 1.4, C.gold, "neck").neon = true
		b:mir(0.5, 9.55, -1.6, 0.35, 0.6, 0.35, C.gold, "neck", "neck").neon = true
		b:box(0, 9.65, -1.6, 0.35, 0.8, 0.35, C.gold, "neck").neon = true
	end

	-- ===== TYRANNOSAURE =====
DEFS["Tyrannosaure"] = function(b)
		local g, dg, tn = rgb(70, 120, 75), rgb(40, 85, 55), rgb(215, 200, 150)
		-- grosses cuisses, pieds a 3 griffes
		for i, s in ipairs({ -1, 1 }) do
			local gn = "leg" .. i
			b:group(gn, s * 1.9, 6.2, 0.8, 1, 0, 0, 0.3, 5, (i == 1) and 0 or math.pi)
			b:box(s * 1.9, 5.0, 0.8, 2.0, 3.0, 2.6, g, gn)
			b:box(s * 1.9, 2.6, 1.2, 1.4, 2.6, 1.4, dg, gn)
			b:box(s * 1.9, 0.35, 0.2, 2.0, 0.7, 3.0, g, gn)
			b:box(s * 1.9, 0.25, -1.5, 1.6, 0.4, 0.5, C.white, gn)
		end
		-- corps horizontal, equilibre par la queue
		b:box(0, 6.8, 0.4, 3.6, 3.4, 5.0, g)
		b:box(0, 5.15, 0.2, 2.8, 0.3, 4.2, tn)
		b:box(0, 7.2, -2.4, 3.0, 3.0, 1.6, g)
		for z = -1.6, 2.4, 0.8 do
			b:box(0, 8.65, z, 0.4, 0.4, 0.6, dg)
		end
		b:box(0, 8.0, -3.6, 2.2, 2.4, 1.6, g, nil, -20)
		-- petits bras
		b:mir(1.5, 6.4, -2.9, 0.5, 1.2, 0.5, g)
		b:mir(1.5, 5.7, -3.3, 0.4, 0.4, 0.6, dg)
		-- enorme tete
		b:group("head", 0, 8.4, -4.0, 1, 0, 0, 0.05, 3, 0)
		b:box(0, 9.0, -5.2, 2.8, 2.4, 2.8, g, "head")
		b:box(0, 8.8, -7.2, 2.4, 1.6, 1.6, g, "head")
		b:box(0, 7.6, -6.4, 2.2, 0.7, 3.0, tn, "head")
		for _, z in ipairs({ -5.4, -6.4, -7.4 }) do
			b:mir(1.0, 8.05, z, 0.2, 0.4, 0.2, C.white, "head", "head")
		end
		b:mir(0.9, 10.3, -5.6, 0.7, 0.4, 1.0, dg, "head", "head")
		b:eye(1.0, 9.8, -6.62, 0.35, C.yellow, "head")
		b:mir(0.6, 9.4, -8.02, 0.25, 0.2, 0.1, C.black, "head", "head")
		-- queue longue et horizontale
		b:group("tail", 0, 7.0, 2.9, 0, 1, 0, 0.3, 4, 0)
		b:box(0, 7.0, 4.0, 2.8, 2.6, 2.4, g, "tail")
		b:box(0, 7.0, 6.2, 2.0, 1.9, 2.2, g, "tail")
		b:box(0, 7.0, 8.2, 1.3, 1.3, 2.0, g, "tail")
		b:box(0, 7.0, 9.8, 0.7, 0.7, 1.4, dg, "tail")
	end

	-- ===== TIGRE A DENTS DE SABRE =====
	DEFS["Tigre sabre"] = function(b)
		H.cat(b, { c = rgb(196, 165, 112), c2 = C.cream, st = rgb(92, 62, 42), eye = rgb(90, 200, 255), fang = 1.7 })
		b:box(0, 5.2, -2.1, 3.9, 2.4, 1.2, rgb(150, 112, 70))
	end

	-- ===== CERBERE =====
	DEFS["Cerbere"] = function(b)
		local c, dk, fl = rgb(48, 40, 48), rgb(26, 20, 26), C.magma
		H.legs4(b, 1.6, 2.0, 3.0, 1.4, c, dk)
		b:box(0, 4.9, 0, 4.4, 3.6, 6.0, c)
		b:box(0, 6.9, -2.3, 4.6, 1.8, 2.2, c)
		local function dhead(cx, y, z, gn, ph)
			b:group(gn, cx, 6.6, -2.4, 1, 0, 0, 0.08, 3, ph)
			b:box(cx, y, z, 2.2, 2.2, 2.2, c, gn)
			b:box(cx, y - 0.4, z - 1.7, 1.4, 1.1, 1.5, dk, gn)
			b:box(cx, y - 0.05, z - 2.5, 0.6, 0.5, 0.3, C.black, gn)
			b:box(cx - 0.6, y + 0.45, z - 1.14, 0.35, 0.42, 0.2, rgb(255, 70, 40), gn).neon = true
			b:box(cx + 0.6, y + 0.45, z - 1.14, 0.35, 0.42, 0.2, rgb(255, 70, 40), gn).neon = true
			b:box(cx - 0.8, y + 1.5, z + 0.1, 0.6, 0.9, 0.5, dk, gn)
			b:box(cx + 0.8, y + 1.5, z + 0.1, 0.6, 0.9, 0.5, dk, gn)
			b:box(cx - 0.4, y - 1.15, z - 2.1, 0.2, 0.4, 0.2, C.white, gn)
			b:box(cx + 0.4, y - 1.15, z - 2.1, 0.2, 0.4, 0.2, C.white, gn)
			b:box(cx, y + 1.45, z + 0.5, 0.7, 1.0, 0.7, fl, gn).neon = true
			b:box(cx, y - 1.1, z + 0.6, 2.4, 0.45, 1.2, rgb(110, 30, 30), gn)
			b:box(cx - 0.8, y - 1.1, z - 0.1, 0.25, 0.4, 0.25, C.lgrey, gn)
			b:box(cx + 0.8, y - 1.1, z - 0.1, 0.25, 0.4, 0.25, C.lgrey, gn)
		end
		dhead(0, 8.2, -3.4, "headC", 0)
		dhead(-2.4, 7.4, -2.9, "headL", 2)
		dhead(2.4, 7.4, -2.9, "headR", 4)
		b:group("tail", 0, 5.8, 2.9, 0, 0, 1, 0.35, 5, 0)
		b:box(0, 6.2, 4.0, 0.8, 0.8, 2.4, c, "tail", -25)
		b:box(0, 7.0, 5.4, 0.9, 1.0, 0.9, fl, "tail").neon = true
		b:box(0, 6.7, -0.6, 3.4, 0.3, 0.6, C.gold)
	end
end
