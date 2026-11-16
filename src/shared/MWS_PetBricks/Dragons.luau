-- Dragons : Dragon de glace, de lave, des ombres, cosmique, du vide, lunaire, primordial
return function(DEFS, H)
	local C = H.C
	local function rgb(r, g, bl) return Color3.fromRGB(r, g, bl) end

	-- gabarit commun : o.c corps, o.c2 ventre, o.horn cornes/griffes, o.mem membrane, o.eye yeux
	-- silhouette : o.bulk (carrure), o.neck (longueur du cou), o.hornStyle (back/curl/quad/crown/frill),
	-- o.tailTip (spade/blade/crystal/orb), o.span/o.chord/o.wn (ailes), o.extra(b, d) details
	local function dragon(b, o)
		b.flyer = true
		b.hmul = o.hmul or 1
		local c, c2, hn, mem = o.c, o.c2 or o.c, o.horn, o.mem
		local bulk, nk = o.bulk or 1, o.neck or 1
		local glow = o.glowSpikes

		-- pattes avant fines, pattes arriere musclees
		local i = 0
		for _, sx in ipairs({ -1, 1 }) do
			i += 1
			local gn = "leg" .. i
			local x = sx * 1.25 * bulk
			b:group(gn, x, 2.6, -1.6, 1, 0, 0, 0.3, 6, (sx > 0) and 0 or math.pi)
			b:box(x, 1.9, -1.6, 0.9, 1.6, 0.9, c, gn)
			b:box(x, 0.7, -1.75, 0.8, 1.2, 0.8, c, gn)
			b:box(x, 0.15, -2.05, 1.0, 0.3, 1.0, hn, gn)
			b:box(x, 0.15, -2.65, 0.6, 0.2, 0.3, C.white, gn)
		end
		for _, sx in ipairs({ -1, 1 }) do
			i += 1
			local gn = "leg" .. i
			local x = sx * 1.45 * bulk
			b:group(gn, x, 3.2, 1.4, 1, 0, 0, 0.3, 6, (sx > 0) and math.pi or 0)
			b:box(x, 2.6, 1.4, 1.3, 2.0, 1.6, c, gn)
			b:box(x, 0.9, 1.7, 0.9, 1.4, 0.9, c, gn)
			b:box(x, 0.15, 1.3, 1.1, 0.3, 1.4, hn, gn)
			b:box(x, 0.15, 0.45, 0.7, 0.2, 0.3, C.white, gn)
		end

		-- corps : poitrail + hanches, plaques de ventre
		b:box(0, 4.2, -1.0, 3.0 * bulk, 3.0, 2.8, c)
		b:box(0, 4.0, 1.4, 2.7 * bulk, 2.6, 2.6, c)
		for z = -1.8, 1.8, 0.9 do
			b:box(0, 2.75, z, 2.2 * bulk, 0.35, 0.75, c2)
		end
		for z = -1.6, 2.4, 0.8 do
			local sp = b:box(0, 5.85, z, 0.35, 0.7, 0.55, o.spike or hn, nil, 25)
			if glow then sp.neon = true end
			if o.spikeTrans then sp.trans = o.spikeTrans end
		end

		-- cou en deux parties
		b:box(0, 5.6, -2.4, 1.6, 1.8, 1.6, c, nil, -30)
		b:box(0, 6.4 + 0.9 * nk, -3.0, 1.4, 1.8 * nk, 1.4, c, nil, -15)
		b:box(0, 5.3 + 0.5 * nk, -3.25, 1.0, 1.2 * nk, 0.3, c2, nil, -15)

		-- tete : crane, museau, machoire, dents, sourcils
		local hy, hz = 7.6 + (nk - 1) * 1.8, -3.3
		b:group("head", 0, hy - 0.4, hz + 0.2, 1, 0, 0, 0.07, 3, 0)
		b:box(0, hy, hz - 0.4, 2.2, 1.6, 2.2, c, "head")
		b:box(0, hy - 0.2, hz - 2.2, 1.6, 0.9, 1.6, c, "head")
		b:box(0, hy - 0.85, hz - 1.8, 1.4, 0.5, 2.0, c2, "head")
		b:mir(0.4, hy + 0.15, hz - 3.02, 0.25, 0.2, 0.1, C.black, "head", "head")
		b:mir(0.55, hy - 0.6, hz - 2.8, 0.18, 0.3, 0.18, C.white, "head", "head")
		b:mir(0.75, hy + 0.85, hz - 1.3, 0.8, 0.3, 0.6, hn, "head", "head")
		b:eye(0.8, hy + 0.3, hz - 1.52, 0.36, o.eye or C.yellow, "head")
		b:mir(1.25, hy - 0.2, hz - 0.2, 0.4, 0.4, 1.0, hn, "head", "head")

		local hs = o.hornStyle or "back"
		local function backHorns()
			b:mir(0.7, hy + 1.2, hz + 0.6, 0.45, 0.45, 2.2, hn, "head", "head", -30)
			b:mir(0.7, hy + 1.9, hz + 1.8, 0.3, 0.3, 0.9, hn, "head", "head", -45)
		end
		if hs == "curl" then
			b:mir(1.2, hy + 0.9, hz + 0.2, 0.6, 0.6, 1.4, hn, "head", "head")
			b:mir(1.5, hy + 0.4, hz + 0.9, 0.55, 1.2, 0.55, hn, "head", "head")
			b:mir(1.4, hy - 0.3, hz + 0.4, 0.5, 0.5, 0.9, hn, "head", "head")
		elseif hs == "quad" then
			backHorns()
			b:mir(0.4, hy + 1.1, hz - 0.6, 0.3, 1.2, 0.3, hn, "head", "head", 20)
		elseif hs == "crown" then
			backHorns()
			for _, x in ipairs({ -0.6, 0, 0.6 }) do
				b:box(x, hy + 1.2 + ((x == 0) and 0.3 or 0), hz - 0.5, 0.3, (x == 0) and 1.6 or 1.0, 0.3, hn, "head").neon = true
			end
		elseif hs == "frill" then
			backHorns()
			local f = b:box(0, hy + 0.6, hz + 1.0, 2.8, 1.4, 0.2, o.spike or hn, "head", -20)
			if o.spikeTrans then f.trans = o.spikeTrans end
		else
			backHorns()
		end

		-- queue longue et effilee
		b:group("tail", 0, 4.0, 2.6, 0, 1, 0, 0.35, 4, 0)
		b:box(0, 3.8, 3.6, 2.0, 1.8, 2.2, c, "tail")
		b:box(0, 3.4, 5.5, 1.5, 1.4, 2.0, c, "tail")
		b:box(0, 3.0, 7.3, 1.1, 1.0, 1.8, c, "tail")
		b:box(0, 2.7, 8.9, 0.7, 0.7, 1.6, c, "tail")
		for _, p in ipairs({ { 4.9, 3.6 }, { 4.3, 5.5 }, { 3.7, 7.3 } }) do
			local sp = b:box(0, p[1], p[2], 0.3, 0.6, 0.5, o.spike or hn, "tail", 25)
			if glow then sp.neon = true end
			if o.spikeTrans then sp.trans = o.spikeTrans end
		end
		local tt = o.tailTip or "spade"
		if tt == "blade" then
			b:box(0, 3.1, 10.0, 0.3, 1.4, 1.8, hn, "tail", -20).neon = glow or false
		elseif tt == "crystal" then
			b:box(0, 2.9, 10.1, 0.9, 1.5, 0.9, C.ice, "tail").trans = 0.25
		elseif tt == "orb" then
			b:box(0, 2.7, 10.1, 1.0, 1.0, 1.0, hn, "tail").neon = true
		else
			b:box(0, 2.7, 10.2, 1.6, 0.3, 1.2, hn, "tail")
			b:box(0, 2.7, 10.9, 0.8, 0.3, 0.6, hn, "tail")
		end

		-- ailes a 4 doigts
		local wo = { span = o.span or 7.5, chord = o.chord or 4.4, col = c, mem = mem, bone = c, claw = hn, n = o.wn or 4, amp = 0.5 }
		H.batwing(b, -1, 1.3 * bulk, 5.6, -0.8, wo)
		H.batwing(b, 1, 1.3 * bulk, 5.6, -0.8, wo)
		if o.extra then o.extra(b, { side = 1.5 * bulk + 0.05, hy = hy, hz = hz }) end
	end

	DEFS["Dragon de glace"] = function(b)
		dragon(b, { c = rgb(150, 205, 235), c2 = C.white, horn = C.white, mem = rgb(205, 240, 252), eye = C.blue,
			bulk = 0.9, neck = 1.3, hornStyle = "frill", tailTip = "crystal", spike = C.ice, spikeTrans = 0.25,
			extra = function(b, d)
				b:mir(d.side, 4.4, -0.6, 0.1, 0.8, 0.8, C.ice).trans = 0.2
				b:mir(d.side, 4.0, 1.2, 0.1, 0.6, 0.6, C.ice).trans = 0.2
			end })
	end

	DEFS["Dragon de lave"] = function(b)
		dragon(b, { c = rgb(62, 52, 58), c2 = rgb(120, 55, 30), horn = rgb(255, 120, 30), mem = rgb(215, 75, 28),
			eye = rgb(255, 230, 60), glowSpikes = true, bulk = 1.2, neck = 0.8, hornStyle = "curl", tailTip = "spade",
			extra = function(b, d)
				b:mir(d.side, 4.6, -0.8, 0.1, 0.4, 1.6, C.magma).neon = true
				b:mir(d.side, 3.9, 1.4, 0.1, 0.4, 1.2, C.magma).neon = true
				b:mir(d.side, 4.9, 1.0, 0.1, 0.9, 0.3, C.magma).neon = true
				b:box(0, d.hy - 0.85, d.hz - 2.81, 1.0, 0.15, 0.05, C.magma, "head").neon = true
			end })
	end

	DEFS["Dragon des ombres"] = function(b)
		dragon(b, { c = rgb(42, 32, 64), c2 = rgb(75, 52, 105), horn = rgb(160, 105, 230), mem = rgb(92, 48, 142),
			eye = rgb(235, 110, 255), glowSpikes = true, bulk = 0.9, neck = 1.1, span = 8, hornStyle = "back", tailTip = "blade",
			extra = function(b, d)
				local p = rgb(180, 120, 255)
				b:mir(d.side, 4.5, -0.4, 0.1, 0.3, 2.0, p).neon = true
				b:mir(d.side, 4.0, 1.6, 0.1, 0.3, 1.4, p).neon = true
			end })
	end

	DEFS["Dragon cosmique"] = function(b)
		dragon(b, { c = rgb(34, 40, 112), c2 = rgb(110, 72, 200), horn = rgb(255, 230, 120), mem = rgb(55, 150, 225),
			eye = rgb(255, 235, 120), glowSpikes = true, hmul = 1.05, neck = 1.4, hornStyle = "back", tailTip = "orb",
			extra = function(b, d)
				local st = rgb(255, 245, 160)
				for _, p in ipairs({ { 4.8, -1.4 }, { 4.0, -0.2 }, { 4.6, 1.0 }, { 3.7, 2.0 } }) do
					b:mir(d.side, p[1], p[2], 0.1, 0.35, 0.35, st).neon = true
				end
				b:mir(4.0, 5.55, 0.8, 0.5, 0.1, 0.5, st, "wingL", "wingR").neon = true
				b:mir(6.5, 5.55, 1.6, 0.4, 0.1, 0.4, st, "wingL", "wingR").neon = true
				b:mir(2.8, 5.55, 2.2, 0.35, 0.1, 0.35, st, "wingL", "wingR").neon = true
			end })
	end

	DEFS["Dragon du vide"] = function(b)
		dragon(b, { c = rgb(26, 16, 38), c2 = rgb(84, 22, 96), horn = rgb(230, 60, 205), mem = rgb(74, 16, 86),
			eye = rgb(255, 80, 230), glowSpikes = true, hmul = 1.05, hornStyle = "quad", tailTip = "blade", wn = 5, span = 8.5,
			extra = function(b, d)
				local p = rgb(230, 60, 205)
				-- oeil du vide sur le poitrail
				b:box(0, 4.3, -2.42, 1.2, 1.2, 0.1, p).neon = true
				b:box(0, 4.3, -2.48, 0.5, 0.8, 0.05, C.black)
				b:mir(d.side, 4.6, 0.6, 0.1, 0.5, 1.8, p).neon = true
			end })
	end

	DEFS["Dragon lunaire"] = function(b)
		dragon(b, { c = rgb(212, 222, 240), c2 = C.white, horn = C.gold, mem = rgb(150, 182, 235),
			eye = C.blue, hmul = 1.08, neck = 1.2, hornStyle = "back", tailTip = "orb",
			extra = function(b, d)
				local g = C.gold
				-- croissant de lune sur le front
				b:box(0, d.hy + 1.05, d.hz - 1.0, 0.9, 0.25, 0.2, g, "head").neon = true
				b:mir(0.55, d.hy + 1.3, d.hz - 1.0, 0.25, 0.45, 0.2, g, "head", "head").neon = true
				b:box(0, 4.6, -2.45, 1.0, 0.25, 0.1, g).neon = true
				b:mir(0.6, 4.85, -2.45, 0.25, 0.5, 0.1, g).neon = true
			end })
	end

	DEFS["Dragon primordial"] = function(b)
		dragon(b, { c = C.gold, c2 = C.cream, horn = C.white, mem = rgb(255, 238, 185),
			eye = C.red, glowSpikes = true, hmul = 1.15, bulk = 1.25, neck = 1.2, span = 9, chord = 4.8,
			hornStyle = "crown", tailTip = "spade",
			extra = function(b, d)
				-- deuxieme paire d'ailes
				local wo = { span = 5.2, chord = 3.0, col = C.gold, mem = rgb(255, 238, 185), bone = C.gold, claw = C.white,
					n = 3, amp = 0.5, gname = "wingB", phase = 1.2 }
				H.batwing(b, -1, 1.5, 4.6, 1.6, wo)
				H.batwing(b, 1, 1.5, 4.6, 1.6, wo)
				-- plaques d'armure
				b:mir(d.side, 4.4, -1.0, 0.15, 1.6, 1.8, C.white).neon = true
				b:mir(d.side, 4.1, 1.4, 0.15, 1.2, 1.6, C.cream)
			end })
	end
end
