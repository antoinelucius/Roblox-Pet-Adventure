-- MWS_BossBricks : boss construits en briques, comme les pets (Plastic + peau Inlet)
-- Un boss regarde vers +Z, les pieds a Y = 0. createBossModel les remet a la bonne taille.
-- Le debut du nom d'une piece decide de son mouvement : "head", "left arm", "right arm", "body".
-- La premiere piece d'un bras doit etre l'epaule : c'est le point de rotation du bras.
local Bricks = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local V = Vector3.new

local function newBuilder(name)
	local model = Instance.new("Model")
	model.Name = name
	local b = { model = model }

	local function place(part, partName, size, cf, color, neon)
		part.Name = partName
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Material = neon and Enum.Material.Neon or Enum.Material.Plastic
		-- peau en briques "Inlet" (MaterialService), la meme que sur les arbres
		part.MaterialVariant = neon and "" or "Inlet"
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = model
		return part
	end

	function b.box(partName, size, position, color, neon, rotation)
		return place(Instance.new("Part"), partName, size, CFrame.new(position) * (rotation or CFrame.new()), color, neon)
	end

	-- triangle : la pointe haute est du cote de `side` (-1 ou 1), face tournee vers +Z
	function b.triangle(partName, width, height, depth, position, color, neon, side)
		return place(Instance.new("WedgePart"), partName, V(depth, height, width),
			CFrame.new(position) * CFrame.Angles(0, side * math.pi / 2, 0), color, neon)
	end

	-- pointe en escalier de briques ; `cf` donne le depart, la pointe suit l'axe Y de `cf`
	function b.spike(partName, cf, base, length, steps, color, tipColor, tipNeon)
		for i = 0, steps - 1 do
			local width = base * (1 - 0.72 * i / math.max(1, steps - 1))
			local last = i == steps - 1
			place(Instance.new("Part"), partName, V(width, length / steps, width),
				cf * CFrame.new(0, (i + 0.5) * length / steps, 0), last and tipColor or color, last and tipNeon)
		end
	end

	-- rocher irregulier : plusieurs blocs tournes qui se chevauchent
	local chunks = {
		{ 0, 0, 0, 1, 0.82, 1, 0.14, 0.3, 0.08 },
		{ 0.34, 0.22, 0.08, 0.66, 0.62, 0.7, 0.45, 0.1, 0.35 },
		{ -0.32, 0.24, -0.1, 0.7, 0.6, 0.64, -0.3, 0.55, 0.2 },
		{ 0.1, -0.3, 0.26, 0.74, 0.5, 0.62, 0.1, -0.4, -0.45 },
		{ -0.12, 0.08, -0.36, 0.62, 0.62, 0.52, 0.55, 0.2, -0.3 },
	}
	function b.boulder(partName, center, size, colorA, colorB, colorC)
		local colors = { colorA, colorB, colorC, colorB, colorA }
		for i, c in ipairs(chunks) do
			b.box(partName, V(c[4], c[5], c[6]) * size, center + V(c[1], c[2], c[3]) * size, colors[i], false, CFrame.Angles(c[7] * 0.45, c[8] * 0.45, c[9] * 0.45))
		end
	end

	-- fissure lumineuse en zigzag, posee sur une face tournee vers +Z
	function b.crack(partName, position, height, color)
		local third = height / 3
		b.box(partName, V(0.9, third * 1.2, 0.4), position + V(-0.5, third, 0), color, true, CFrame.Angles(0, 0, 0.5))
		b.box(partName, V(0.9, third * 1.2, 0.4), position, color, true, CFrame.Angles(0, 0, -0.5))
		b.box(partName, V(0.9, third * 1.2, 0.4), position + V(0.5, -third, 0), color, true, CFrame.Angles(0, 0, 0.5))
	end

	return b
end

local builders = {}

-- Golem de lave : colosse voute en blocs de pierre, plaques de roche sur un corps en fusion,
-- petite tete enfoncee, epaules enormes, avant-bras et poings gigantesques
function builders.GolemDeLave(b)
	local stone, stoneLight, stoneDark = rgb(120, 98, 92), rgb(156, 128, 112), rgb(76, 62, 66)
	local obsidian, magma = rgb(34, 30, 38), rgb(240, 96, 24)
	local lava, core = rgb(255, 120, 20), rgb(255, 214, 70)

	-- jambes courtes et lourdes, orteils de pierre
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 9
		b.box("body foot", V(13, 2.6, 14), V(x, 1.3, 2), stoneDark)
		for _, offset in ipairs({ -4, 0, 4 }) do
			b.box("body toe", V(3.4, 2.2, 3.6), V(x + offset, 1.1, 10), stone)
		end
		b.box("body ankle glow", V(9, 1, 9), V(x, 3.1, 0.5), lava, true)
		b.boulder("body shin", V(x, 7.2, 0), 9.5, stone, stoneLight, stoneDark)
		b.box("body knee", V(7.5, 4.6, 2.2), V(x, 9, 5), stoneLight, false, CFrame.Angles(-0.2, 0, side * 0.08))
		b.boulder("body thigh", V(x * 0.9, 12.6, 0), 9, stoneDark, stone, stoneLight)
	end

	-- corps en fusion, couvert de plaques de roche : la lave se voit dans les joints
	b.box("body magma", V(17, 16, 10), V(0, 22, 0), magma)
	b.box("body pelvis", V(18, 4, 11), V(0, 14.5, 0), stoneDark)
	b.box("body loin", V(7.5, 4.4, 2.4), V(0, 13.6, 5.6), stone)
	for _, side in ipairs({ -1, 1 }) do
		b.box("body pec", V(10.2, 7.4, 3), V(side * 5.6, 26.6, 5.4), stoneLight, false, CFrame.Angles(0.1, side * 0.16, side * -0.05))
		b.box("body abs", V(7.4, 3.2, 2.4), V(side * 4.2, 21, 5.2), stone, false, CFrame.Angles(0, 0, side * 0.05))
		b.box("body abs", V(6.8, 3.2, 2.4), V(side * 3.9, 17.4, 5.2), stoneDark, false, CFrame.Angles(0, 0, side * -0.05))
		b.box("body flank", V(3.4, 13, 8.6), V(side * 10, 21.6, 0), stone, false, CFrame.Angles(0, 0, side * 0.08))
		b.crack("body crack", V(side * 10.4, 19, 4.6), 4.5, lava)
	end
	b.box("body core frame", V(7.4, 7.4, 1), V(0, 22.6, 7), stoneDark, false, CFrame.Angles(0, 0, math.pi / 4))
	b.box("body core", V(5, 5, 1), V(0, 22.6, 7.4), core, true, CFrame.Angles(0, 0, math.pi / 4))
	b.box("body seam", V(16, 0.8, 0.8), V(0, 19.2, 6.5), lava, true)
	b.box("body seam", V(0.8, 6, 0.8), V(0, 16.4, 6.5), lava, true)

	-- dos voute et eclats d'obsidienne
	b.boulder("body hump", V(0, 31, -2), 14, stoneDark, stone, stoneLight)
	for _, shard in ipairs({ { -5, 34, -6, -0.5, 0.25, 6 }, { 5, 34, -6, -0.5, -0.25, 6 }, { -3.5, 27, -7, -1, 0.2, 5 }, { 3.5, 27, -7, -1, -0.2, 5 } }) do
		b.spike("body shard", CFrame.new(shard[1], shard[2], shard[3]) * CFrame.Angles(shard[4], 0, shard[5]), 3.4, shard[6], 3, obsidian, lava, true)
	end

	-- petite tete enfoncee entre les epaules, front lourd et machoire avancee
	b.box("head skull", V(9.5, 6.5, 8), V(0, 31.6, 7), stone)
	b.box("head jaw", V(10.5, 3.2, 8), V(0, 27.8, 8.8), stoneDark)
	b.box("head mouth", V(7.5, 0.9, 0.6), V(0, 29.5, 12.2), lava, true)
	for _, x in ipairs({ -3.2, 0, 3.2 }) do
		b.box("head tooth", V(1.8, 1.8, 1.2), V(x, 29.3, 12.8), stoneLight)
	end
	b.box("head nose", V(2.2, 2.6, 1.8), V(0, 31.4, 11.4), stoneLight)
	for _, side in ipairs({ -1, 1 }) do
		b.box("head eye", V(2.8, 1, 0.6), V(side * 2.9, 32.6, 11.1), core, true, CFrame.Angles(0, 0, side * 0.22))
		b.box("head brow", V(6, 2.3, 3.2), V(side * 3, 34.4, 10), stoneDark, false, CFrame.Angles(-0.15, 0, side * 0.26))
		b.box("head cheek", V(2.2, 4.2, 5.4), V(side * 5.4, 30.6, 7.6), stoneLight)
		b.spike("head horn", CFrame.new(side * 3.4, 34.6, 5.4) * CFrame.Angles(-0.2, 0, -side * 0.3), 2.8, 4, 3, stoneDark, lava, true)
	end

	-- epaules enormes, avant-bras massifs, poings qui touchent presque le sol
	for _, arm in ipairs({ { "left arm", -1 }, { "right arm", 1 } }) do
		local name, side = arm[1], arm[2]
		b.boulder(name .. " shoulder", V(side * 17.5, 30, 0), 15, stone, stoneLight, stoneDark)
		b.spike(name .. " shard", CFrame.new(side * 21, 35, -1) * CFrame.Angles(0, 0, -side * 0.4), 4, 8, 3, obsidian, lava, true)
		b.spike(name .. " shard", CFrame.new(side * 15, 36, 2) * CFrame.Angles(0.25, 0, -side * 0.12), 3.2, 6, 3, obsidian, lava, true)
		b.spike(name .. " shard", CFrame.new(side * 19, 34, -5) * CFrame.Angles(-0.5, 0, -side * 0.2), 3, 5, 3, obsidian, lava, true)

		b.boulder(name .. " upper", V(side * 22, 22.4, 1), 10, stoneDark, stone, stoneLight)
		b.box(name .. " elbow glow", V(10, 1.4, 10), V(side * 23.4, 17, 2), lava, true)
		b.crack(name .. " crack", V(side * 22, 23, 6.4), 5, lava)
		b.crack(name .. " crack", V(side * 16, 29, 8), 5, lava)
		b.box(name .. " forearm", V(11, 10, 11), V(side * 24, 11.6, 3), stone, false, CFrame.Angles(0, 0, side * -0.04))
		b.box(name .. " plate", V(8.4, 5, 2.2), V(side * 24, 13, 8.6), stoneLight, false, CFrame.Angles(0.08, 0, side * 0.1))
		b.crack(name .. " crack", V(side * 24, 9, 8.8), 3.5, lava)

		b.box(name .. " fist", V(15, 8, 13), V(side * 25, 4.2, 5), stoneDark)
		for _, offset in ipairs({ -5.4, -1.8, 1.8, 5.4 }) do
			b.box(name .. " knuckle", V(3.2, 3.4, 3.2), V(side * 25 + offset, 6.4, 12), stoneLight)
			b.box(name .. " finger", V(3, 3.2, 2.6), V(side * 25 + offset, 2.2, 12), stone)
		end
		b.box(name .. " seam", V(13.4, 0.8, 0.8), V(side * 25, 4.3, 11.9), lava, true)
		b.box(name .. " thumb", V(4.4, 5, 6), V(side * 16.8, 5.4, 7), stone)
	end
end

-- Fantome encapuchonne : cape dechiree, oeil unique lumineux, baton recourbe
function builders.SpectreOssuaireBriques(b)
	local cloak, cloakLight, dark = rgb(76, 76, 80), rgb(114, 112, 114), rgb(26, 26, 32)
	local wood, bone, eye, glow = rgb(132, 94, 60), rgb(226, 218, 198), rgb(215, 245, 255), rgb(90, 210, 255)

	-- cape qui s'elargit vers le bas, bas en lambeaux
	b.box("body cloak", V(14, 3, 10), V(0, 23, 0.5), cloakLight)
	b.box("body cloak", V(14, 4, 10.5), V(0, 19.5, 0.5), cloak)
	b.box("body cloak", V(16, 4, 11.5), V(0, 15.5, 0.5), cloakLight)
	b.box("body cloak", V(18.5, 3.5, 12.5), V(0, 11.8, 0.5), cloak)
	local lengths = { 7, 10, 6, 10.5, 8, 10.5, 7, 9 }
	for i, length in ipairs(lengths) do
		local x = -10.5 + (i - 1) * 3
		local color = (i % 2 == 0) and cloakLight or dark
		b.box("body rag", V(2.8, length, 2), V(x, 10.5 - length / 2, 6), color)
		b.box("body rag", V(2.8, lengths[9 - i], 2), V(x, 10.5 - lengths[9 - i] / 2, -5), (i % 2 == 0) and dark or cloak)
	end
	for _, side in ipairs({ -1, 1 }) do
		b.box("body rag", V(2, 8, 3), V(side * 10, 6.5, 3), cloak)
		b.box("body rag", V(2, 10, 3), V(side * 10, 5.5, -2), dark)
		b.box("body tear", V(3, 5, 0.6), V(side * 4.5, 17, 6.2), dark, false, CFrame.Angles(0, 0, side * 0.3))
	end

	-- capuche en pointe : le visage reste dans le noir, avec un seul oeil en losange
	b.box("head hood", V(12, 3, 11), V(0, 24.5, 1), cloakLight)
	b.box("head hood", V(12.5, 4, 11.5), V(0, 28, 1), cloak)
	b.box("head hood", V(10.5, 2.6, 10), V(0, 31.3, 0.6), cloakLight)
	b.box("head hood", V(7.5, 2.6, 7.5), V(0, 33.9, -0.4), cloak)
	b.box("head hood", V(4.4, 3, 4.6), V(0, 36.4, -2), cloakLight, false, CFrame.Angles(-0.4, 0, 0))
	b.box("head opening", V(7.6, 5.6, 1), V(0, 27.6, 6.4), dark)
	b.box("head opening", V(5, 1.6, 1), V(0, 31, 5.5), dark)
	b.box("head opening", V(5, 1.4, 1), V(0, 24.4, 6.4), dark)
	b.box("head eye", V(2.8, 2.8, 0.6), V(0, 27.6, 7), eye, true, CFrame.Angles(0, 0, math.pi / 4))
	b.box("head pupil", V(1, 1, 0.5), V(0, 27.6, 7.4), dark, false, CFrame.Angles(0, 0, math.pi / 4))

	-- lambeaux qui pendent de la poitrine et des epaules
	for i, x in ipairs({ -5.4, -2, 1.6, 5 }) do
		local length = ({ 6, 9, 7, 8 })[i]
		b.box("body rag", V(3, length, 1.4), V(x, 21.5 - length / 2, 6.2), (i % 2 == 0) and dark or cloak)
	end

	-- bras gauche tendu, main d'os
	b.box("left arm shoulder", V(5.4, 4.4, 6.4), V(-9, 22, 1), cloakLight)
	b.box("left arm sleeve", V(5, 9, 5), V(-12.4, 16.4, 3), cloak, false, CFrame.Angles(0, 0, -0.35))
	b.box("left arm rag", V(2.2, 5, 1.2), V(-13.4, 10, 5), dark)
	b.box("left arm rag", V(2.2, 7, 1.2), V(-15.6, 9.4, 3), cloak)
	b.box("left arm rag", V(3, 8, 1.2), V(-11, 8.6, 2), cloakLight)
	b.box("left arm rag", V(2, 5, 1.2), V(-16, 12, 0.8), dark)
	b.box("left arm hand", V(3.2, 3, 3.2), V(-15, 11.4, 3), bone)
	for _, offset in ipairs({ -1, 0, 1 }) do
		b.spike("left arm finger", CFrame.new(-15 + offset, 10, 3.6) * CFrame.Angles(math.pi - 0.2, 0, 0), 1.1, 3.4, 2, bone, glow, true)
	end

	-- bras droit qui tient le baton recourbe, avec une flamme bleue au bout
	b.box("right arm shoulder", V(5.4, 4.4, 6.4), V(9, 22, 1), cloakLight)
	b.box("right arm sleeve", V(5, 8, 5), V(12, 18.4, 5), cloak, false, CFrame.Angles(0.55, 0, 0.25))
	b.box("right arm rag", V(2.4, 6, 1.2), V(12.6, 12.4, 6), dark)
	b.box("right arm rag", V(2.4, 8, 1.2), V(10.4, 11.6, 5), cloakLight)
	b.box("right arm hand", V(3.4, 3.2, 3.4), V(13.5, 15, 9), bone)
	b.box("right arm staff", V(1.8, 37, 1.8), V(13.5, 18.5, 9), wood)
	b.box("right arm staff", V(2.6, 1.6, 2.6), V(13.5, 24, 9), dark)
	b.box("right arm staff", V(6.6, 1.8, 1.8), V(16, 37.4, 9), wood)
	b.box("right arm staff", V(1.8, 4.6, 1.8), V(18.6, 35.8, 9), wood)
	b.box("right arm flame", V(2.2, 2.2, 2.2), V(18.6, 32.4, 9), glow, true, CFrame.Angles(0, 0, math.pi / 4))
end

-- Empereur d'os : armure noire et or, couronne, grandes ailes d'os, queue de serpent
function builders.IgnarethBriques(b)
	local black, gold, goldDark = rgb(34, 30, 40), rgb(250, 208, 76), rgb(190, 136, 44)
	local purple, purpleLight = rgb(78, 40, 176), rgb(128, 96, 240)
	local shine, ember = rgb(255, 228, 96), rgb(255, 130, 30)

	-- queue de serpent enroulee a la place des jambes
	for i = 0, 10 do
		local t = i / 10
		local radius, angle, width = 5.4 * (1 - t) + 0.4, i * 1.15, 5 + 7 * t
		local color = (i % 3 == 2) and gold or ((i % 2 == 0) and purple or purpleLight)
		b.box("body tail", V(width, 2.4, width), V(math.cos(angle) * radius, 1.2 + i * 2, math.sin(angle) * radius), color)
	end
	b.spike("body tail tip", CFrame.new(4, 2, 4) * CFrame.Angles(1.3, 0, -0.7), 3.4, 8, 3, purple, purpleLight, true)

	-- torse noir, cotes d'or, coeur violet
	b.box("body belt", V(14, 3, 10.5), V(0, 23, 0), gold)
	b.box("body belt plate", V(5, 4.6, 1.2), V(0, 22.6, 5.6), goldDark)
	b.box("body waist", V(10.5, 3, 7.5), V(0, 26, 0), black)
	b.box("body chest", V(15.5, 8, 10), V(0, 31.4, 0), black)
	b.box("body collar", V(13.5, 2, 9.4), V(0, 35.8, 0.4), gold)
	b.box("body sternum", V(1.8, 7, 1), V(0, 31.4, 5.3), gold)
	for _, y in ipairs({ 28.8, 31, 33.2 }) do
		for _, side in ipairs({ -1, 1 }) do
			b.box("body rib", V(5.6, 1.2, 1), V(side * 3.9, y, 5.2), gold, false, CFrame.Angles(0, 0, side * -0.14))
		end
	end
	b.box("body core", V(3.2, 3.2, 0.8), V(0, 26, 4.1), purpleLight, true, CFrame.Angles(0, 0, math.pi / 4))

	-- crane couronne, sourire lumineux
	b.box("head skull", V(8.6, 7, 8), V(0, 39.8, 2), black)
	b.box("head jaw", V(7.4, 2.6, 6.4), V(0, 36.8, 3), goldDark)
	b.box("head mouth", V(6.4, 1.9, 0.6), V(0, 38.2, 6.1), shine, true)
	for _, x in ipairs({ -2.2, 0, 2.2 }) do
		b.box("head tooth", V(1.2, 1.2, 0.8), V(x, 38.8, 6.4), black)
	end
	b.box("head brow", V(9, 1.1, 1), V(0, 42.6, 6), gold)
	b.box("head crown", V(9.6, 1.6, 8.8), V(0, 44, 2), gold)
	for i, x in ipairs({ -3.8, -1.9, 0, 1.9, 3.8 }) do
		local heights = { 4, 5.4, 7.4, 5.4, 4 }
		b.spike("head crown spike", CFrame.new(x, 44.6, 5.4), 1.8, heights[i], 3, gold, shine, false)
	end
	for _, side in ipairs({ -1, 1 }) do
		b.triangle("head eye", 2.6, 2, 0.8, V(side * 2.2, 41.2, 6.1), ember, true, side)
		b.spike("head horn", CFrame.new(side * 4.6, 42, 2) * CFrame.Angles(0, 0, -side * 0.9), 2.4, 6, 3, black, gold, false)
	end

	-- bras puissants, enormes griffes d'or
	for _, arm in ipairs({ { "left arm", -1 }, { "right arm", 1 } }) do
		local name, side = arm[1], arm[2]
		b.box(name .. " shoulder", V(8.6, 6.4, 8.6), V(side * 11.5, 33.6, 0), black)
		b.box(name .. " trim", V(9.8, 1.4, 9.8), V(side * 11.5, 37.4, 0), gold)
		b.spike(name .. " spike", CFrame.new(side * 13.5, 38, -1) * CFrame.Angles(0, 0, -side * 0.35), 2.8, 6, 3, gold, shine, false)
		b.spike(name .. " spike", CFrame.new(side * 9.5, 38, 2) * CFrame.Angles(0.2, 0, -side * 0.1), 2.2, 4.6, 3, gold, shine, false)
		b.box(name .. " upper", V(4.8, 9, 4.8), V(side * 15.6, 28, 2), black, false, CFrame.Angles(0, 0, side * 0.35))
		b.box(name .. " ring", V(6, 1.4, 6), V(side * 17.6, 23.6, 4), gold)
		b.box(name .. " forearm", V(5.6, 8, 5.6), V(side * 18.8, 19, 7), goldDark, false, CFrame.Angles(0.3, 0, 0))
		b.box(name .. " hand", V(7.4, 3, 7.4), V(side * 19.4, 14.2, 10), black)
		for _, offset in ipairs({ -2.6, -0.9, 0.9, 2.6 }) do
			b.spike(name .. " claw", CFrame.new(side * 19.4 + offset, 13, 12) * CFrame.Angles(math.pi - 0.35, 0, 0), 2, 10, 3, gold, ember, true)
		end
	end

	-- grandes ailes d'os, plaques noires et longues pointes d'or
	for _, wing in ipairs({ { "left wing", -1 }, { "right wing", 1 } }) do
		local name, side = wing[1], wing[2]
		b.box(name .. " root", V(3.4, 3.4, 3.4), V(side * 8, 35, -6), gold)
		b.box(name .. " bone", V(16, 2.4, 2.4), V(side * 15, 39.5, -7), gold, false, CFrame.Angles(0, 0, side * 0.5))
		b.box(name .. " bone", V(16, 2, 2), V(side * 29, 44, -8), goldDark, false, CFrame.Angles(0, 0, -side * 0.08))
		for i, x in ipairs({ 16, 22, 28, 34 }) do
			local lengths = { 16, 19, 21, 17 }
			local top = (i == 1) and 41.5 or 44
			b.spike(name .. " finger", CFrame.new(side * x, top, -8) * CFrame.Angles(math.pi, 0, -side * 0.12), 2.2, lengths[i], 3, gold, shine, false)
			if i < 4 then
				local webColor = (i == 2) and rgb(52, 34, 110) or black
				b.box(name .. " web", V(3, 14, 0.8), V(side * (x + 1.5), 36, -8.6), webColor)
				b.box(name .. " web", V(3, 9, 0.8), V(side * (x + 4.5), 38.5, -8.6), webColor)
			end
		end
		b.spike(name .. " thorn", CFrame.new(side * 22, 45, -8) * CFrame.Angles(0, 0, -side * 0.2), 2, 4, 2, gold, shine, false)
		b.spike(name .. " thorn", CFrame.new(side * 32, 45, -8) * CFrame.Angles(0, 0, -side * 0.4), 2, 5, 2, gold, shine, false)
	end
end

-- Renvoie un boss neuf, ou nil s'il n'existe pas encore en briques
function Bricks.build(name)
	local build = builders[name]
	if not build then return nil end
	local b = newBuilder(name)
	build(b)
	return b.model
end

return Bricks
