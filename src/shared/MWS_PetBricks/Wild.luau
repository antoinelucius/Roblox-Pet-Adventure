-- Tigre, Gorille, Mammouth, Crocodile, Taureau de feu, Salamandre (+ gabarit felin H.cat)
return function(DEFS, H)
	local C = H.C
	local function rgb(r, g, bl) return Color3.fromRGB(r, g, bl) end

	-- gabarit de felin : o.c corps, o.c2 ventre/museau, o.st rayures, o.eye, o.fang (longueur des crocs)
function H.cat(b, o)
		local c, c2, st = o.c, o.c2, o.st
		H.legs4(b, 1.25, 2.0, 2.4, 1.3, c, c2)
		-- epaules puissantes, hanches plus fines, ventre clair
		b:box(0, 4.0, -1.0, 3.8, 3.2, 3.2, c)
		b:box(0, 3.8, 1.4, 3.4, 2.8, 2.8, c)
		b:box(0, 2.65, -0.2, 3.0, 0.6, 4.6, c2)
		for _, z in ipairs({ -1.9, -0.7, 0.6, 1.8 }) do
			local front = z < 0.2
			b:mir(front and 1.92 or 1.72, 4.1, z, 0.1, 1.9, 0.45, st)
			b:box(0, front and 5.62 or 5.22, z, 1.6, 0.1, 0.45, st)
		end
		-- tete ronde, collerette sur les joues, menton blanc
		b:group("head", 0, 4.9, -2.6, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 5.3, -3.7, 3.0, 2.6, 2.4, c, "head")
		b:mir(1.55, 4.9, -3.6, 0.5, 1.6, 1.6, c2, "head", "head")
		b:box(0, 4.6, -5.2, 1.8, 1.2, 1.0, c2, "head")
		b:box(0, 5.05, -5.75, 0.7, 0.45, 0.2, rgb(150, 70, 80), "head")
		b:box(0, 4.0, -4.9, 1.2, 0.5, 1.0, C.white, "head")
		b:box(0, 6.62, -3.8, 0.3, 0.1, 1.2, st, "head")
		b:mir(0.8, 6.62, -3.4, 0.3, 0.1, 0.8, st, "head", "head")
		b:mir(1.1, 6.95, -3.3, 0.9, 0.9, 0.6, c, "head", "head")
		b:mir(1.1, 6.95, -3.62, 0.5, 0.5, 0.15, c2, "head", "head")
		b:eye(0.75, 5.6, -4.92, 0.4, o.eye, "head")
		if o.fang then
			b:mir(0.5, 4.1 - o.fang / 2, -5.5, 0.25, o.fang, 0.25, C.white, "head", "head")
		end
		-- longue queue qui remonte
		b:group("tail", 0, 4.6, 2.8, 0, 0, 1, 0.3, 4, 0)
		b:box(0, 4.9, 3.8, 0.9, 0.9, 2.0, c, "tail", -15)
		b:box(0, 5.5, 5.5, 0.85, 0.85, 1.8, st, "tail", -25)
		b:box(0, 6.3, 6.8, 0.8, 0.8, 1.4, c, "tail", -40)
		b:box(0, 7.0, 7.6, 0.8, 0.8, 0.8, st, "tail")
	end

	DEFS["Tigre"] = function(b)
		H.cat(b, { c = C.orange, c2 = C.cream, st = C.black, eye = C.yellow })
	end

	-- ===== GORILLE =====
DEFS["Gorille"] = function(b)
		local g, dg, sk, sv = rgb(70, 70, 78), rgb(42, 42, 48), rgb(120, 100, 90), rgb(175, 175, 185)
		-- jambes courtes et flechies
		for i, s in ipairs({ -1, 1 }) do
			local gn = "leg" .. i
			b:group(gn, s * 1.5, 3.4, 0.8, 1, 0, 0, 0.3, 5, (i == 1) and 0 or math.pi)
			b:box(s * 1.5, 2.6, 0.8, 1.9, 1.8, 2.0, g, gn)
			b:box(s * 1.5, 1.0, 0.6, 1.6, 1.6, 1.6, dg, gn)
			b:box(s * 1.5, 0.2, 0.2, 2.0, 0.4, 2.6, sk, gn)
		end
		-- torse massif + dos argente
		b:box(0, 4.4, 0.6, 4.4, 2.4, 3.0, g)
		b:box(0, 7.0, -0.3, 5.8, 3.6, 3.6, g)
		b:box(0, 6.8, -2.12, 3.8, 2.4, 0.1, dg)
		b:box(0, 6.0, 1.25, 4.2, 2.6, 0.2, sv)
		b:box(0, 8.9, 0.2, 5.0, 0.4, 2.8, sv)
		-- longs bras qui marchent sur les poings
		for i, s in ipairs({ -1, 1 }) do
			local gn = (s < 0) and "armL" or "armR"
			b:group(gn, s * 3.4, 8.2, -0.3, 1, 0, 0, 0.3, 5, (i == 1) and math.pi or 0)
			b:box(s * 3.6, 6.8, -0.4, 1.8, 3.0, 1.8, g, gn)
			b:box(s * 3.7, 3.9, -0.7, 1.7, 3.0, 1.7, g, gn)
			b:box(s * 3.7, 1.3, -0.9, 2.0, 1.8, 2.0, dg, gn)
		end
		-- tete : crete, arcade sourciliere, museau
		b:group("head", 0, 8.6, -1.6, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 9.6, -2.0, 2.8, 2.4, 2.4, dg, "head")
		b:box(0, 11.0, -1.6, 1.4, 0.6, 1.8, dg, "head")
		b:box(0, 10.25, -3.25, 2.6, 0.4, 0.3, C.black, "head")
		b:box(0, 9.3, -3.22, 2.2, 1.6, 0.1, sk, "head")
		b:box(0, 8.8, -3.5, 1.8, 0.9, 0.6, sk, "head")
		b:mir(0.3, 9.1, -3.82, 0.25, 0.2, 0.1, C.black, "head", "head")
		b:box(0, 8.55, -3.82, 1.0, 0.1, 0.05, C.black, "head")
		b:eye(0.6, 9.8, -3.3, 0.3, nil, "head")
	end

	-- ===== MAMMOUTH =====
DEFS["Mammouth"] = function(b)
		local c, c2, hair, tk = rgb(120, 70, 45), rgb(150, 95, 60), rgb(90, 52, 35), C.cream
		H.legs4(b, 1.9, 1.9, 3.0, 1.9, c, C.dgrey)
		-- corps avec bosse sur le dos et longs poils
		b:box(0, 5.2, 0.3, 5.8, 4.6, 6.0, c)
		b:box(0, 8.0, -1.0, 4.4, 1.4, 3.0, c2)
		b:box(0, 7.6, 1.8, 4.0, 0.8, 2.6, c)
		for z = -2.4, 2.4, 1.2 do
			b:mir(2.95, 3.3, z, 0.4, 1.4, 1.0, hair)
		end
		b:box(0, 2.7, 0.3, 5.0, 0.5, 5.4, hair)
		-- tete en dome, petites oreilles
		b:group("head", 0, 6.4, -2.8, 1, 0, 0, 0.05, 2.5, 0)
		b:box(0, 7.0, -4.0, 3.8, 3.8, 2.6, c, "head")
		b:box(0, 9.2, -3.8, 2.8, 1.0, 2.0, c2, "head")
		b:mir(2.1, 7.4, -3.6, 0.4, 1.6, 1.4, hair, "head", "head")
		b:eye(1.1, 7.6, -5.32, 0.4, nil, "head")
		-- defenses recourbees
		b:mir(1.3, 5.2, -5.8, 0.55, 0.55, 1.8, tk, "head", "head")
		b:mir(1.55, 5.4, -7.1, 0.5, 0.5, 1.4, tk, "head", "head", 20)
		b:mir(1.4, 6.1, -7.9, 0.45, 1.2, 0.45, tk, "head", "head")
		b:mir(1.0, 6.8, -7.6, 0.4, 0.6, 0.4, tk, "head", "head")
		-- trompe
		b:group("trunk", 0, 6.0, -5.3, 1, 0, 0, 0.2, 2.5, 0)
		b:box(0, 5.2, -5.6, 1.5, 2.0, 1.3, c2, "trunk")
		b:box(0, 3.6, -5.9, 1.3, 1.6, 1.2, c2, "trunk")
		b:box(0, 2.3, -6.4, 1.1, 1.2, 1.4, c2, "trunk")
		b:box(0, 1.9, -7.2, 0.9, 0.9, 0.9, c2, "trunk")
		b:box(0, 6.2, 3.4, 0.6, 1.8, 0.6, c)
		b:box(0, 5.0, 3.5, 0.8, 0.8, 0.8, hair)
	end

	-- ===== CROCODILE =====
DEFS["Crocodile"] = function(b)
		b.hmul = 0.62
		local g, dg, bl = rgb(85, 112, 60), rgb(55, 75, 40), rgb(215, 205, 150)
		-- pattes ecartees sur les cotes
		local i = 0
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1.7, 1.7 }) do
				i += 1
				local gn = "leg" .. i
				b:group(gn, sx * 1.7, 1.5, sz, 1, 0, 0, 0.3, 6, (sx * sz > 0) and 0 or math.pi)
				b:box(sx * 2.3, 1.4, sz, 1.2, 0.8, 1.0, g, gn)
				b:box(sx * 2.8, 0.6, sz, 0.9, 1.2, 0.9, dg, gn)
				b:box(sx * 2.85, 0.15, sz - 0.25, 1.3, 0.3, 1.4, dg, gn)
			end
		end
		-- corps bas et long, ecailles en double rangee
		b:box(0, 1.9, 0, 3.6, 1.6, 6.0, g)
		b:box(0, 1.15, 0, 3.2, 0.4, 5.6, bl)
		b:box(0, 2.8, 0, 2.8, 0.3, 5.6, dg)
		for z = -2.4, 2.4, 1.2 do
			b:mir(0.7, 3.1, z, 0.5, 0.4, 0.6, dg)
		end
		-- tete : long museau, dents qui depassent, yeux sur le dessus
		b:group("head", 0, 2.0, -3.0, 1, 0, 0, 0.05, 2.5, 0)
		b:box(0, 2.2, -3.9, 2.8, 1.4, 2.0, g, "head")
		b:box(0, 2.05, -6.4, 1.8, 0.8, 3.2, g, "head")
		b:box(0, 1.4, -6.0, 1.8, 0.5, 3.4, bl, "head")
		for k, z in ipairs({ -5.0, -5.8, -6.6, -7.4 }) do
			local up = (k % 2 == 0)
			b:mir(0.92, up and 1.75 or 1.55, z, 0.15, 0.35, 0.2, C.white, "head", "head")
		end
		b:mir(0.8, 3.1, -3.6, 0.7, 0.6, 0.8, g, "head", "head")
		b:mir(0.8, 3.15, -4.02, 0.45, 0.35, 0.1, C.yellow, "head", "head")
		b:mir(0.8, 3.15, -4.08, 0.12, 0.35, 0.05, C.black, "head", "head")
		b:mir(0.35, 2.5, -7.8, 0.25, 0.15, 0.25, C.black, "head", "head")
		-- longue queue avec crete
		b:group("tail", 0, 1.9, 3.0, 0, 1, 0, 0.35, 4, 0)
		b:box(0, 1.8, 4.2, 2.8, 1.4, 2.4, g, "tail")
		b:box(0, 1.6, 6.4, 2.0, 1.1, 2.2, g, "tail")
		b:box(0, 1.4, 8.4, 1.3, 0.9, 2.0, g, "tail")
		b:box(0, 1.3, 10.0, 0.7, 0.6, 1.4, dg, "tail")
		b:mir(0.6, 2.7, 4.2, 0.4, 0.5, 0.8, dg, "tail", "tail")
		b:mir(0.45, 2.35, 6.4, 0.35, 0.45, 0.8, dg, "tail", "tail")
		b:box(0, 2.05, 8.4, 0.35, 0.45, 0.8, dg, "tail")
	end

	-- ===== TAUREAU DE FEU =====
DEFS["Taureau de feu"] = function(b)
		local c, dk, hn = rgb(95, 35, 30), rgb(40, 20, 20), C.cream
		H.legs4(b, 1.2, 1.8, 3.0, 1.2, dk, C.black)
		-- avant massif avec bosse, arriere plus fin
		b:box(0, 4.9, -1.0, 3.8, 3.6, 3.0, c)
		b:box(0, 6.9, -1.3, 3.0, 1.2, 2.2, c)
		b:box(0, 4.5, 1.6, 3.2, 3.0, 2.6, c)
		b:box(0, 3.0, 0, 2.8, 0.4, 4.6, dk)
		b:box(0, 3.6, -2.6, 1.2, 1.0, 0.6, c)
		-- tete : cornes vers l'avant, anneau dore
		b:group("head", 0, 5.6, -2.6, 1, 0, 0, 0.07, 3, 0)
		b:box(0, 5.4, -3.8, 2.6, 2.4, 2.0, c, "head")
		b:box(0, 4.6, -5.1, 2.0, 1.4, 1.0, dk, "head")
		b:mir(0.5, 4.8, -5.62, 0.25, 0.25, 0.1, C.black, "head", "head")
		b:box(0, 4.2, -5.7, 0.9, 0.15, 0.15, C.gold, "head")
		b:mir(0.4, 4.35, -5.7, 0.15, 0.3, 0.15, C.gold, "head", "head")
		b:box(0, 6.6, -3.6, 1.6, 0.4, 1.0, dk, "head")
		b:mir(1.6, 6.3, -3.6, 1.2, 0.5, 0.5, hn, "head", "head")
		b:mir(2.3, 6.8, -3.9, 0.5, 1.0, 0.5, hn, "head", "head", -20)
		b:mir(2.3, 7.4, -4.4, 0.4, 0.6, 0.4, hn, "head", "head", -40)
		b:mir(1.5, 5.7, -3.2, 0.7, 0.35, 0.5, c, "head", "head")
		b:eye(0.8, 5.8, -4.82, 0.4, rgb(255, 90, 40), "head")
		-- criniere de feu sur la bosse
		b:group("flame", 0, 7.0, -1.0, 0, 0, 1, 0.12, 7, 0)
		b:box(0, 7.9, -2.2, 0.9, 1.2, 0.9, C.magma, "flame").neon = true
		b:box(0, 8.4, -1.2, 0.8, 1.4, 0.8, C.orange, "flame").neon = true
		b:box(0, 8.1, -0.2, 0.7, 1.2, 0.7, C.yellow, "flame").neon = true
		b:box(0, 7.4, 0.7, 0.6, 0.9, 0.6, C.magma, "flame").neon = true
		b:group("tail", 0, 5.5, 2.9, 1, 0, 0, 0.25, 4, 0)
		b:box(0, 4.5, 3.05, 0.5, 2.4, 0.5, dk, "tail")
		b:box(0, 3.0, 3.1, 0.9, 1.0, 0.9, C.magma, "tail").neon = true
	end

	-- ===== SALAMANDRE =====
DEFS["Salamandre"] = function(b)
		b.hmul = 0.6
		local dk, bel, o, y = rgb(35, 28, 30), rgb(90, 50, 30), C.magma, C.yellow
		-- pattes ecartees
		local i = 0
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1.5, 1.5 }) do
				i += 1
				local gn = "leg" .. i
				b:group(gn, sx * 1.1, 1.1, sz, 1, 0, 0, 0.35, 6, (sx * sz > 0) and 0 or math.pi)
				b:box(sx * 1.6, 1.0, sz, 1.0, 0.6, 0.8, dk, gn)
				b:box(sx * 2.0, 0.45, sz, 0.6, 0.9, 0.6, dk, gn)
				b:box(sx * 2.1, 0.1, sz - 0.2, 1.0, 0.2, 1.0, dk, gn)
			end
		end
		-- corps noir a taches de feu
		b:box(0, 1.4, 0, 2.2, 1.2, 4.6, dk)
		b:box(0, 0.85, 0, 2.0, 0.2, 4.2, bel)
		for k, p in ipairs({ { -0.5, -1.6 }, { 0.5, -0.6 }, { -0.5, 0.5 }, { 0.5, 1.6 } }) do
			b:box(p[1], 2.02, p[2], 0.7, 0.08, 0.8, (k % 2 == 0) and o or y).neon = true
		end
		b:mir(1.12, 1.5, -1.0, 0.08, 0.5, 0.7, o).neon = true
		b:mir(1.12, 1.5, 1.1, 0.08, 0.5, 0.7, y).neon = true
		-- tete plate, gros yeux
		b:group("head", 0, 1.4, -2.3, 1, 0, 0, 0.06, 3, 0)
		b:box(0, 1.5, -3.3, 2.4, 1.1, 2.0, dk, "head")
		b:box(0, 1.35, -4.6, 1.8, 0.8, 0.8, dk, "head")
		b:mir(0.85, 2.1, -3.7, 0.7, 0.6, 0.7, dk, "head", "head")
		b:mir(0.85, 2.15, -4.06, 0.4, 0.4, 0.1, C.black, "head", "head")
		b:mir(0.95, 2.25, -4.1, 0.15, 0.15, 0.05, C.white, "head", "head")
		b:mir(0.8, 2.07, -2.8, 0.7, 0.08, 0.9, y, "head", "head").neon = true
		b:box(0, 1.1, -5.02, 1.2, 0.1, 0.05, bel, "head")
		-- queue qui ondule
		b:group("tail", 0, 1.4, 2.3, 0, 1, 0, 0.5, 5, 0)
		b:box(0, 1.3, 3.4, 1.6, 1.0, 2.0, dk, "tail")
		b:box(0, 1.2, 5.2, 1.2, 0.8, 1.8, dk, "tail")
		b:box(0, 1.1, 6.8, 0.8, 0.6, 1.6, dk, "tail")
		b:box(0, 1.0, 8.0, 0.5, 0.4, 1.0, o, "tail").neon = true
		b:box(0, 1.82, 3.4, 0.6, 0.08, 0.7, y, "tail").neon = true
		b:box(0, 1.62, 5.4, 0.5, 0.08, 0.6, o, "tail").neon = true
	end
end
