-- Animaux de la prairie : Poulet, Chien, Renard, Ours, Cerf, Licorne (+ gabarit cheval H.horse)
return function(DEFS, H)
	local C, legs4, legs2 = H.C, H.legs4, H.legs2
	local function rgb(r, g, bl) return Color3.fromRGB(r, g, bl) end

	-- gabarit cheval : o.c robe, o.hoof sabots, o.muzzle museau, o.mane couleurs de criniere, o.tailCols queue
	function H.horse(b, o)
		local c = o.c
		local mane = o.mane or { c }
		local tc = o.tailCols or mane
		legs4(b, 1.0, 1.9, 3.6, 0.85, c, o.hoof)
		b:box(0, 4.9, -1.2, 2.9, 2.8, 2.8, c)
		b:box(0, 4.8, 1.4, 2.8, 2.6, 2.6, c)
		b:box(0, 3.55, 0, 2.4, 0.3, 4.6, o.belly or c)
		b:box(0, 6.7, -2.5, 1.5, 3.0, 1.6, c, nil, -25)
		b:group("head", 0, 7.8, -3.0, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 8.5, -3.6, 1.6, 1.6, 2.0, c, "head")
		b:box(0, 8.0, -5.1, 1.3, 1.1, 1.4, o.muzzle or c, "head")
		b:mir(0.35, 8.15, -5.82, 0.2, 0.25, 0.05, C.black, "head", "head")
		b:box(0, 7.6, -5.82, 0.7, 0.08, 0.05, C.black, "head")
		b:eye(0.55, 8.9, -4.62, 0.3, nil, "head")
		b:mir(0.5, 9.6, -3.0, 0.4, 0.8, 0.4, c, "head", "head")
		b:box(0, 9.35, -4.3, 0.6, 0.5, 0.7, mane[1], "head")
		-- criniere le long de l'encolure
		for i = 1, 4 do
			b:box(0, 9.4 - 0.85 * i, -2.8 + 0.6 * i, 0.6, 1.2, 0.9, mane[(i % #mane) + 1])
		end
		b:group("tail", 0, 5.8, 2.6, 1, 0, 0, 0.25, 4, 0)
		b:box(0, 5.5, 3.2, 0.9, 1.2, 1.0, tc[1], "tail", 30)
		b:box(0, 4.4, 3.8, 0.85, 1.4, 0.9, tc[(1 % #tc) + 1], "tail", 15)
		b:box(0, 3.0, 4.0, 0.8, 1.4, 0.8, tc[(2 % #tc) + 1], "tail")
	end

	-- ===== POULET =====
	DEFS["Poulet"] = function(b)
		b.hops = true
		local W, Y, R, O = C.white, C.yellow, C.red, C.orange
		legs2(b, 0.8, 0.2, 1.7, 0.45, Y, O)
		b:box(0, 3.2, 0.3, 3.4, 3.0, 3.8, W)
		b:box(0, 3.4, -1.65, 2.6, 2.2, 0.5, W)
		b:box(0, 5.4, -1.5, 2.2, 2.4, 2.2, W)
		-- crete a 3 pointes, bec, barbillon
		b:box(0, 6.75, -1.3, 0.5, 0.3, 1.8, R)
		b:box(0, 7.0, -1.9, 0.5, 0.5, 0.6, R)
		b:box(0, 7.25, -1.3, 0.5, 0.9, 0.6, R)
		b:box(0, 7.0, -0.7, 0.5, 0.6, 0.5, R)
		b:box(0, 5.3, -3.0, 1.0, 0.6, 0.8, O)
		b:box(0, 4.95, -2.85, 0.8, 0.3, 0.6, rgb(200, 110, 35))
		b:box(0, 4.45, -2.75, 0.5, 0.8, 0.4, R)
		b:eye(0.7, 5.9, -2.62, 0.4)
		-- queue en eventail
		b:group("tail", 0, 4.0, 2.0, 0, 1, 0, 0.35, 6, 0)
		b:box(0, 5.2, 2.6, 1.0, 2.6, 0.8, W, "tail", 25)
		b:mir(0.6, 4.8, 2.5, 0.5, 2.0, 0.7, W, "tail", "tail", 25, 0, -12)
		b:box(0, 6.4, 3.2, 0.8, 1.0, 0.7, C.cream, "tail", 25)
		for _, s in ipairs({ -1, 1 }) do
			local g = s < 0 and "wingL" or "wingR"
			b:group(g, s * 1.75, 4.4, 0.4, 0, 0, s, 0.45, 9, 0)
			b:box(s * 2.05, 3.4, 0.6, 0.5, 2.2, 2.6, C.cream, g)
			b:box(s * 2.05, 2.5, 1.6, 0.45, 0.8, 1.2, W, g)
		end
	end

	-- ===== CHIEN =====
	DEFS["Chien"] = function(b)
		local c, c2, dk = C.lbrown, C.tan, C.brown
		legs4(b, 1.0, 2.0, 2.4, 1.0, c, dk)
		b:box(0, 3.7, 0, 3.0, 2.6, 5.4, c)
		b:box(0, 3.4, -2.75, 2.2, 1.8, 0.2, c2)
		b:box(0, 2.45, 0, 2.6, 0.3, 4.4, c2)
		b:box(1.52, 4.1, 0.9, 0.1, 1.4, 1.6, dk)
		b:box(-0.6, 5.02, 1.2, 1.2, 0.1, 1.4, dk)
		-- collier rouge + medaille
		b:box(0, 4.6, -2.5, 2.4, 0.45, 0.6, C.red)
		b:box(0, 4.15, -2.85, 0.4, 0.4, 0.1, C.gold)
		b:group("head", 0, 5.0, -2.4, 1, 0, 0, 0.08, 3, 0)
		b:box(0, 5.6, -3.2, 2.6, 2.4, 2.4, c, "head")
		b:box(0, 5.0, -4.8, 1.6, 1.1, 1.2, c2, "head")
		b:box(0, 5.4, -5.45, 0.7, 0.5, 0.2, C.black, "head")
		b:box(0, 4.35, -4.95, 0.5, 0.4, 0.6, C.pink, "head")
		b:eye(0.7, 6.1, -4.42, 0.4, nil, "head")
		-- oreilles tombantes
		b:mir(1.45, 5.6, -3.0, 0.4, 2.0, 1.2, dk, "head", "head", 0, 0, -10)
		b:group("tail", 0, 4.7, 2.7, 0, 0, 1, 0.45, 9, 0)
		b:box(0, 5.4, 3.1, 0.6, 1.8, 0.6, c, "tail", 30)
		b:box(0, 6.2, 3.6, 0.5, 0.6, 0.5, c2, "tail", 30)
	end

	-- ===== RENARD =====
	DEFS["Renard"] = function(b)
		local o, w, k = C.orange, C.white, C.black
		legs4(b, 0.9, 1.7, 2.1, 0.8, k, k)
		b:box(0, 3.2, 0, 2.6, 2.2, 4.6, o)
		b:box(0, 3.0, -2.35, 1.8, 1.8, 0.3, w)
		b:box(0, 2.15, -0.3, 2.0, 0.2, 3.6, w)
		b:group("head", 0, 4.0, -2.0, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 4.9, -2.9, 2.4, 1.9, 2.0, o, "head")
		b:mir(0.95, 4.4, -3.6, 0.6, 0.9, 1.2, w, "head", "head")
		-- museau fin : dessus roux, dessous blanc
		b:box(0, 4.65, -4.4, 1.1, 0.6, 1.2, o, "head")
		b:box(0, 4.2, -4.4, 1.0, 0.4, 1.2, w, "head")
		b:box(0, 4.75, -5.05, 0.45, 0.35, 0.2, k, "head")
		-- grandes oreilles pointues a bout noir
		b:mir(0.75, 6.4, -2.5, 0.75, 1.4, 0.5, o, "head", "head")
		b:mir(0.75, 7.25, -2.5, 0.55, 0.4, 0.45, k, "head", "head")
		b:mir(0.75, 6.3, -2.77, 0.4, 0.8, 0.05, w, "head", "head")
		b:eye(0.55, 5.2, -3.92, 0.32, nil, "head")
		-- grosse queue touffue a bout blanc
		b:group("tail", 0, 3.8, 2.3, 0, 1, 0, 0.4, 5, 0)
		b:box(0, 4.0, 3.4, 1.5, 1.5, 2.4, o, "tail", 15)
		b:box(0, 4.5, 5.3, 1.9, 1.9, 2.0, o, "tail", 15)
		b:box(0, 5.0, 6.9, 1.5, 1.5, 1.4, w, "tail", 15)
	end

	-- ===== OURS =====
	DEFS["Ours"] = function(b)
		local c, c2, dk = C.brown, C.lbrown, C.black
		legs4(b, 1.5, 1.6, 2.3, 1.4, c, C.dgrey)
		local i = 0
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				i += 1
				b:box(sx * 1.5, 0.15, sz * 1.6 - 0.95, 1.2, 0.2, 0.3, C.white, "leg" .. i)
			end
		end
		-- corps lourd + bosse sur les epaules
		b:box(0, 4.2, 0.2, 4.4, 3.6, 4.6, c)
		b:box(0, 6.2, -1.0, 3.4, 0.8, 2.2, c)
		b:box(0, 2.35, 0.2, 3.6, 0.3, 3.8, rgb(85, 52, 32))
		b:group("head", 0, 5.6, -2.0, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 6.6, -3.0, 3.0, 2.6, 2.4, c, "head")
		b:box(0, 6.0, -4.6, 1.6, 1.2, 1.2, c2, "head")
		b:box(0, 6.45, -5.25, 0.7, 0.5, 0.25, dk, "head")
		b:box(0, 5.55, -5.22, 0.8, 0.1, 0.05, dk, "head")
		b:mir(1.2, 8.1, -2.6, 0.9, 0.8, 0.6, c, "head", "head")
		b:mir(1.2, 8.05, -2.92, 0.5, 0.45, 0.1, c2, "head", "head")
		b:eye(0.8, 7.0, -4.22, 0.35, nil, "head")
		b:box(0, 4.6, 2.6, 0.8, 0.8, 0.6, c)
	end

	-- ===== CERF =====
	DEFS["Cerf"] = function(b)
		local c, w, br, cr = C.lbrown, C.white, C.cream, rgb(225, 205, 165)
		legs4(b, 0.9, 2.0, 3.6, 0.65, c, C.brown)
		b:box(0, 5.1, 0, 2.6, 2.4, 5.0, c)
		b:box(0, 3.85, 0, 2.2, 0.2, 4.2, cr)
		b:box(0, 5.2, 2.52, 1.8, 1.6, 0.1, w)
		for _, p in ipairs({ { -0.7, -1.2 }, { 0.8, -0.1 }, { -0.6, 1.2 }, { 0.7, 2.0 } }) do
			b:box(p[1], 6.32, p[2], 0.5, 0.1, 0.5, w)
		end
		b:box(0, 7.2, -2.3, 1.3, 2.8, 1.3, c, nil, -20)
		b:box(0, 6.7, -2.95, 0.8, 1.4, 0.1, cr, nil, -20)
		b:group("head", 0, 8.2, -2.9, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 8.8, -3.4, 1.5, 1.5, 2.0, c, "head")
		b:box(0, 8.5, -4.8, 1.0, 0.9, 1.0, c, "head")
		b:box(0, 8.7, -5.32, 0.5, 0.4, 0.1, C.black, "head")
		b:eye(0.55, 9.1, -4.42, 0.3, nil, "head")
		b:mir(1.0, 9.6, -3.0, 1.0, 0.4, 0.6, c, "head", "head")
		b:mir(1.0, 9.6, -3.32, 0.6, 0.25, 0.05, cr, "head", "head")
		-- bois ramifies
		b:mir(0.6, 10.3, -3.1, 0.35, 1.8, 0.35, br, "head", "head", 0, 0, -20)
		b:mir(1.15, 11.6, -3.0, 0.3, 1.4, 0.3, br, "head", "head", 0, 0, -30)
		b:mir(0.8, 10.8, -3.6, 0.25, 0.8, 0.25, br, "head", "head", -40)
		b:mir(1.35, 11.9, -3.5, 0.25, 0.7, 0.25, br, "head", "head", -40)
		b:mir(1.6, 12.4, -3.0, 0.25, 0.6, 0.25, br, "head", "head")
		b:box(0, 6.0, 2.65, 0.6, 0.8, 0.4, w)
	end

	-- ===== LICORNE =====
	DEFS["Licorne"] = function(b)
		H.horse(b, { c = C.white, hoof = C.gold, muzzle = rgb(255, 215, 230), belly = C.white,
			mane = { C.pink, C.lpurple, C.lblue, C.cyan }, tailCols = { C.pink, C.lpurple, C.lblue } })
		-- corne torsadee
		b:box(0, 9.6, -4.0, 0.55, 0.6, 0.55, C.gold, "head", -15, 20)
		b:box(0, 10.15, -4.15, 0.47, 0.6, 0.47, C.yellow, "head", -15, 45)
		b:box(0, 10.7, -4.3, 0.38, 0.6, 0.38, C.gold, "head", -15, 70)
		b:box(0, 11.2, -4.45, 0.28, 0.5, 0.28, C.yellow, "head", -15, 95).neon = true
	end
end
