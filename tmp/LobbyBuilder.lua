-- LobbyBuilder: Starhaven, the lobby spaceship interior.
-- Layout (x = along the ship, -z = toward the planet window):
--   Great Hall / Concourse (x -100..100, z -90..55, 96 tall): core tower with the spawn ring,
--     stacked multi-storey blocks along both side walls, trusses and pipe arcs overhead, a three-portal
--     window onto the planet at the front, market stalls under a full-width mezzanine at the back.
--   The east and west wings are built in their own coordinates and shifted out by `shift`.
--   Crew Quarters (upper level, behind the concourse): cabin doors (soon).
--   East wing: corridor to three Upgrade Halls (Scanning, Loot, Player) and the Bridge (star map).
--   West wing: tall Hangar / Launch Deck with the launch pad, drop shuttles and a catwalk
--     that links straight to the concourse mezzanine.
-- Gameplay only relies on: Ground (PrimaryPart), the Spawns folder, and parts with a
-- "PadAction" attribute (Sell, Upgrades, Map, Launch) that hold a ProximityPrompt.
local Lobby = {}

local C = {
	Hull = Color3.fromRGB(128, 136, 150),
	Panel = Color3.fromRGB(98, 106, 122),
	Dark = Color3.fromRGB(46, 52, 64),
	Floor = Color3.fromRGB(92, 98, 110),
	FloorDark = Color3.fromRGB(70, 76, 88),
	Teal = Color3.fromRGB(60, 214, 224),
	Orange = Color3.fromRGB(255, 150, 60),
	Yellow = Color3.fromRGB(255, 212, 72),
	Pink = Color3.fromRGB(255, 110, 180),
	Purple = Color3.fromRGB(165, 115, 255),
	Green = Color3.fromRGB(110, 226, 120),
	Blue = Color3.fromRGB(95, 155, 255),
	Glass = Color3.fromRGB(165, 215, 255),
	White = Color3.fromRGB(188, 194, 204),
}
Lobby.Colors = C

local SP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local DECOR = { CanCollide = false, CanQuery = false, CanTouch = false }
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

function Lobby.Build(parent, origin, spawnCount)
	local model = Instance.new("Model")
	model.Name = "Hub"
	model:SetAttribute("PlanetKey", "Hub")
	model:SetAttribute("Radius", 300)
	model.Parent = parent
	local cur = model

	local shift = Vector3.zero -- wings are built in their own coordinates, then pushed out past the great hall
	local function at(x, y, z)
		return CFrame.new(origin + shift + Vector3.new(x, y, z))
	end
	local function section(name)
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = model
		cur = m
		task.wait()
		return m
	end
	local function P(name, size, cf, color, mat, props)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat or SP
		if props then
			for k, v in pairs(props) do
				p[k] = v
			end
		end
		p.Parent = cur
		return p
	end
	-- box from two corners
	local function B(name, x1, y1, z1, x2, y2, z2, color, mat, props)
		local sx, sy, sz = math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)
		if sx < 0.05 or sy < 0.05 or sz < 0.05 then
			return nil
		end
		return P(name, Vector3.new(sx, sy, sz), at((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2), color, mat, props)
	end
	local function light(p, range, bright, color)
		local l = Instance.new("PointLight")
		l.Range = range or 40
		l.Brightness = (bright or 1.5) * 0.65
		l.Color = color or Color3.fromRGB(255, 248, 235)
		l.Shadows = false
		l.Parent = p
		return l
	end
	-- maps (along, height) spans onto a wall line: axis "x" = wall runs along x at z = f
	local function mk(axis, f)
		return function(name, a, b, ya, yb, t, col, mat, props)
			if axis == "x" then
				return B(name, a, ya, f - t / 2, b, yb, f + t / 2, col, mat, props)
			end
			return B(name, f - t / 2, ya, a, f + t / 2, yb, b, col, mat, props)
		end
	end

	-- Solid wall with bulkhead doorways: doors = { {c=center, w=width, h=height, y=bottom?, color=?, glass=?} }
	local function wall(axis, f, u1, u2, y0, y1, doors, color)
		local s = mk(axis, f)
		color = color or C.Hull
		doors = doors or {}
		table.sort(doors, function(a, b)
			return a.c < b.c
		end)
		local u = u1
		for _, d in ipairs(doors) do
			local a, b = d.c - d.w / 2, d.c + d.w / 2
			local db = d.y or y0
			s("Wall", u, a, y0, y1, 2, color)
			if db + d.h < y1 then
				s("Wall", a, b, db + d.h, y1, 2, color)
			end
			if db > y0 then
				s("Wall", a, b, y0, db, 2, color)
			end
			if d.glass then
				s("ForceField", a, b, db, db + d.h, 0.6, C.Glass, NEON, { Transparency = 0.88, CastShadow = false })
			end
			s("DoorFrame", a - 1.2, a, db, db + d.h + 1.2, 3, C.Dark)
			s("DoorFrame", b, b + 1.2, db, db + d.h + 1.2, 3, C.Dark)
			s("DoorFrame", a, b, db + d.h, db + d.h + 1.2, 3, C.Dark)
			s("DoorGlow", a - 0.6, b + 0.6, db + d.h + 0.35, db + d.h + 0.85, 3.4, d.color or C.Teal, NEON, DECOR)
			s("DoorGlow", a - 0.8, a - 0.4, db, db + d.h, 3.4, d.color or C.Teal, NEON, DECOR)
			s("DoorGlow", b + 0.4, b + 0.8, db, db + d.h, 3.4, d.color or C.Teal, NEON, DECOR)
			u = b
		end
		s("Wall", u, u2, y0, y1, 2, color)
	end

	-- Wall with a big window band between sill and head, split by mullions
	local function windowWall(axis, f, u1, u2, y0, y1, sill, head, every)
		local s = mk(axis, f)
		s("Wall", u1, u2, y0, sill, 2, C.Hull)
		s("Wall", u1, u2, head, y1, 2, C.Hull)
		s("Window", u1, u2, sill, head, 0.6, C.Glass, SP, { Transparency = 0.9, CastShadow = false }) -- not Glass: Glass hides transparent parts behind it
		s("WindowFrame", u1, u2, sill - 0.6, sill, 3, C.Dark)
		s("WindowFrame", u1, u2, head, head + 0.6, 3, C.Dark)
		local mid = (sill + head) / 2
		s("WindowFrame", u1, u2, mid - 0.4, mid + 0.4, 2.4, C.Dark)
		local u = u1 + every
		while u < u2 - 1 do
			s("WindowFrame", u - 0.8, u + 0.8, sill, head, 3, C.Dark)
			u += every
		end
		s("SillGlow", u1, u2, sill - 0.9, sill - 0.6, 3.2, C.Teal, NEON, DECOR)
	end

	local function rail(axis, f, u1, u2, y)
		local s = mk(axis, f)
		s("RailGlass", u1, u2, y, y + 3.2, 0.3, C.Glass, Enum.Material.Glass, { Transparency = 0.6 })
		s("RailTop", u1, u2, y + 3.2, y + 3.7, 0.7, C.White)
		local u = u1
		while u <= u2 + 0.01 do
			s("RailPost", u - 0.3, u + 0.3, y, y + 3.2, 0.6, C.Dark)
			u += 8
		end
	end

	-- Steps: start at `start` on the stair axis, descend toward `dir`; a1..a2 across
	local function stairs(axis, start, dir, a1, a2, yTop, depth, color)
		for i = 1, yTop do
			local s1, s2 = start + dir * (i - 1) * depth, start + dir * i * depth
			local top = yTop - i + 1
			if axis == "z" then
				B("Step", a1, 0, s1, a2, top, s2, color or C.Panel)
			else
				B("Step", s1, 0, a1, s2, top, a2, color or C.Panel)
			end
		end
	end

	-- Room dressing: floor, ceiling, upper ribs + braces, ceiling beams, glow trims, lamps
	local function dress(x1, z1, x2, z2, h, o)
		o = o or {}
		local acc = o.accent or C.Teal
		if o.floor ~= false then
			B("Floor", x1, -1, z1, x2, 0, z2, o.floorColor or C.Floor, o.floorMat or SP)
		end
		B("Ceiling", x1, h, z1, x2, h + 1.5, z2, C.Panel)
		B("FloorGlow", x1, 0, z1, x2, 0.12, z1 + 0.5, acc, NEON, DECOR)
		B("FloorGlow", x1, 0, z2 - 0.5, x2, 0.12, z2, acc, NEON, DECOR)
		B("FloorGlow", x1, 0, z1, x1 + 0.5, 0.12, z2, acc, NEON, DECOR)
		B("FloorGlow", x2 - 0.5, 0, z1, x2, 0.12, z2, acc, NEON, DECOR)
		local rf = o.ribFrom or h * 0.55
		B("WallGlow", x1, rf - 1, z1, x2, rf - 0.6, z1 + 0.3, acc, NEON, DECOR)
		B("WallGlow", x1, rf - 1, z2 - 0.3, x2, rf - 0.6, z2, acc, NEON, DECOR)
		B("WallGlow", x1, rf - 1, z1, x1 + 0.3, rf - 0.6, z2, acc, NEON, DECOR)
		B("WallGlow", x2 - 0.3, rf - 1, z1, x2, rf - 0.6, z2, acc, NEON, DECOR)
		local longX = (x2 - x1) >= (z2 - z1)
		local every = o.rib or 14
		if longX then
			local x = x1 + every / 2
			while x < x2 - 1 do
				B("Rib", x - 1, rf, z1, x + 1, h, z1 + 1.2, C.Panel)
				B("Rib", x - 1, rf, z2 - 1.2, x + 1, h, z2, C.Panel)
				B("Brace", x - 1, h - 3, z1, x + 1, h, z1 + 3, C.Panel)
				B("Brace", x - 1, h - 3, z2 - 3, x + 1, h, z2, C.Panel)
				B("Beam", x - 0.8, h - 1.6, z1, x + 0.8, h, z2, C.Dark)
				x += every
			end
		else
			local z = z1 + every / 2
			while z < z2 - 1 do
				B("Rib", x1, rf, z - 1, x1 + 1.2, h, z + 1, C.Panel)
				B("Rib", x2 - 1.2, rf, z - 1, x2, h, z + 1, C.Panel)
				B("Brace", x1, h - 3, z - 1, x1 + 3, h, z + 1, C.Panel)
				B("Brace", x2 - 3, h - 3, z - 1, x2, h, z + 1, C.Panel)
				B("Beam", x1, h - 1.6, z - 0.8, x2, h, z + 0.8, C.Dark)
				z += every
			end
		end
		local drop = o.lampDrop or 2
		local len = longX and (x2 - x1) or (z2 - z1)
		local n = math.max(1, math.floor(len / (o.lampEvery or 30)))
		for i = 1, n do
			local t = (i - 0.5) / n
			local lx = longX and (x1 + (x2 - x1) * t) or (x1 + x2) / 2
			local lz = longX and (z1 + z2) / 2 or (z1 + (z2 - z1) * t)
			local hx, hz = longX and 4 or 1.4, longX and 1.4 or 4
			local lamp = B("Lamp", lx - hx, h - drop - 0.6, lz - hz, lx + hx, h - drop, lz + hz, C.White, NEON, DECOR)
			if drop > 1.7 then
				B("LampCable", lx - 0.15, h - drop, lz - 0.15, lx + 0.15, h, lz + 0.15, C.Dark, SP, DECOR)
			end
			light(lamp, o.range or 50, o.bright or 1.6)
		end
	end

	local function label(adornee, lines, offsetY, size)
		local gui = Instance.new("BillboardGui")
		gui.Name = "Label"
		gui.Adornee = adornee
		gui.Size = UDim2.fromOffset(size or 240, 30 * #lines)
		gui.StudsOffset = Vector3.new(0, offsetY or 6, 0)
		gui.MaxDistance = 90
		gui.LightInfluence = 0
		local list = Instance.new("UIListLayout")
		list.Parent = gui
		for i, text in ipairs(lines) do
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 0, i == 1 and 34 or 24)
			t.Font = i == 1 and Enum.Font.FredokaOne or Enum.Font.GothamMedium
			t.TextScaled = true
			t.TextColor3 = Color3.new(1, 1, 1)
			t.TextStrokeTransparency = 0.3
			t.Text = text
			t.LayoutOrder = i
			t.Parent = gui
		end
		gui.Parent = adornee
		return gui
	end

	-- Flat sign with a glowing outline. yaw 0 faces -z, 180 faces +z, -90 faces +x, 90 faces -x.
	local function wallSign(x, y, z, w, h, yaw, text, color, sub)
		local cf = at(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
		local p = P("Sign", Vector3.new(w, h, 0.4), cf, C.Dark, SP, DECOR)
		P("SignGlow", Vector3.new(w + 0.8, h + 0.8, 0.2), cf * CFrame.new(0, 0, 0.3), color, NEON, DECOR)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 24
		g.LightInfluence = 0
		g.MaxDistance = 300
		local function txt(t, sy, py, font, col)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(0.94, sy)
			l.Position = UDim2.fromScale(0.03, py)
			l.Font = font
			l.TextScaled = true
			l.TextColor3 = col
			l.TextStrokeTransparency = 0.7
			l.Text = t
			l.Parent = g
		end
		if sub then
			txt(text, 0.6, 0.04, Enum.Font.FredokaOne, color)
			txt(sub, 0.3, 0.64, Enum.Font.GothamBold, C.White)
		else
			txt(text, 0.84, 0.08, Enum.Font.FredokaOne, color)
		end
		g.Parent = p
		return p
	end

	local function pad(name, text, actionText, action, color, x, y, z)
		P("PadRing", Vector3.new(0.8, 12, 12), at(x, y + 0.4, z) * CFrame.Angles(0, 0, math.rad(90)), C.Dark, SP, { Shape = CYL })
		local p = P(name, Vector3.new(9, 1, 9), at(x, y + 0.5, z), color, NEON)
		p:SetAttribute("PadAction", action)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = actionText
		prompt.ObjectText = text
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = p
		label(p, { text }, 5, 240)
		light(p, 14, 1, color)
		return p
	end

	-- Friendly crew robot (decor)
	local function bot(x, y, z, color, yaw)
		local base = at(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
		P("BotBody", Vector3.new(4, 3, 3), base * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), C.White, SP, { Shape = CYL })
		P("BotBelt", Vector3.new(0.6, 3.2, 3.2), base * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), color, SP, { Shape = CYL })
		P("BotHead", Vector3.one * 3.2, base * CFrame.new(0, 5.2, 0), color, SP, { Shape = BALL })
		P("BotVisor", Vector3.new(2.2, 0.8, 0.4), base * CFrame.new(0, 5.4, -1.45), C.Teal, NEON, DECOR)
		P("BotAntenna", Vector3.new(0.3, 1.4, 0.3), base * CFrame.new(0, 7.3, 0), C.Dark, SP, DECOR)
		P("BotTip", Vector3.one * 0.7, base * CFrame.new(0, 8.1, 0), color, NEON, { Shape = BALL, CanCollide = false, CanQuery = false })
	end

	local function tree(x, z)
		B("Planter", x - 3, 0, z - 3, x + 3, 2.5, z + 3, C.White)
		B("PlanterRim", x - 3.3, 2.5, z - 3.3, x + 3.3, 3, z + 3.3, C.Green)
		B("Trunk", x - 0.5, 3, z - 0.5, x + 0.5, 8, z + 0.5, Color3.fromRGB(150, 100, 70))
		P("Leaves", Vector3.one * 6, at(x, 9.5, z), C.Green, SP, { Shape = BALL })
		P("Leaves", Vector3.one * 4, at(x + 1.5, 12, z - 1), Color3.fromRGB(140, 236, 120), SP, { Shape = BALL })
	end

	local function bench(x, z, yaw)
		local base = at(x, 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
		P("Bench", Vector3.new(8, 0.8, 2.6), base * CFrame.new(0, 1.8, 0), C.White)
		P("BenchBack", Vector3.new(8, 2.2, 0.6), base * CFrame.new(0, 3, 1.2), C.Teal)
		P("BenchLeg", Vector3.new(6, 1.4, 1.4), base * CFrame.new(0, 0.7, 0), C.Dark)
	end

	local function crate(x, y, z, s, color)
		B("Crate", x - s / 2, y, z - s / 2, x + s / 2, y + s, z + s / 2, color, SP)
		B("CrateBand", x - s / 2 - 0.15, y + s * 0.4, z - s / 2 - 0.15, x + s / 2 + 0.15, y + s * 0.6, z + s / 2 + 0.15, C.Dark, SP, DECOR)
	end

	local function rocket(x, z, color)
		local function cyl(name, len, d, y, col, mat, props)
			props = props or {}
			props.Shape = CYL
			return P(name, Vector3.new(len, d, d), at(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), col, mat, props)
		end
		cyl("RocketBase", 1.5, 18, 0.75, C.Dark)
		cyl("RocketBody", 22, 10, 13, C.White)
		cyl("RocketStripe", 2, 10.4, 8, color)
		cyl("RocketStripe", 2, 10.4, 19, color)
		P("RocketNose", Vector3.one * 10, at(x, 24, z), color, SP, { Shape = BALL })
		P("RocketWindow", Vector3.new(0.8, 4.2, 4.2), at(x + 4.8, 15, z), C.Teal, NEON, { Shape = CYL })
		for _, a in ipairs({ 0, 120, 240 }) do
			P("RocketFin", Vector3.new(1, 8, 6), at(x, 5.5, z) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0, 6), color)
		end
		local glow = P("Thruster", Vector3.new(0.6, 7, 7), at(x, 1.7, z) * CFrame.Angles(0, 0, math.rad(90)), C.Orange, NEON, { Shape = CYL, CanCollide = false })
		light(glow, 18, 1.5, C.Orange)
	end

	---------------------------------------------------------------- Concourse: the great hall
	-- A tall hall built like a small town inside the hull: a central core tower, stacked
	-- multi-storey blocks along both side walls, trusses, ducts and big pipe arcs overhead, and a
	-- three-portal window onto the planet. Everything above head height is visual only.
	section("Concourse")
	local HX, HZF, HZB, HH = 100, -90, 55, 96 -- half width, window plane, back wall, ceiling
	local TZ = -22 -- core tower centre (x = 0)
	local ground = B("Ground", -60, -4, -46, 60, 0, 54, C.Dark, SP)
	model.PrimaryPart = ground
	B("HallFloor", -HX, -4, HZF + 8, -60, 0, HZB - 1, C.Dark)
	B("HallFloor", 60, -4, HZF + 8, HX, 0, HZB - 1, C.Dark)
	B("HallFloor", -60, -4, HZF + 8, 60, 0, -46, C.Dark)
	B("WindowFloor", -HX, -1, HZF, HX, 0, HZF + 8, C.FloorDark, SP)
	-- floor plates with seams between them
	for i = 0, 12 do
		for j = 0, 7 do
			local x, z = -HX + i * 16, HZF + 8 + j * 16
			B("FloorPlate", x + 0.15, 0, z + 0.15, math.min(x + 15.85, HX), 0.15, z + 15.85, (i + j) % 2 == 0 and C.Floor or C.FloorDark)
		end
	end
	-- inner pane: keeps players (and their camera) back from the window
	local innerGlass = B("InnerGlass", -HX, 0, HZF + 7.8, HX, 70, HZF + 8.2, C.Glass, SP, { Transparency = 0.85, CastShadow = false })
	innerGlass:AddTag("CameraBlock") -- client keeps the camera on the room side of this pane

	-- helpers: rods/beams between two points, regular octagons
	local function rod(name, a, b, d, color, props, box)
		local cf = CFrame.lookAt(at(a.X, a.Y, a.Z).Position:Lerp(at(b.X, b.Y, b.Z).Position, 0.5), at(b.X, b.Y, b.Z).Position)
		if math.abs((b - a).Unit.Y) > 0.999 then
			cf = at((a.X + b.X) / 2, (a.Y + b.Y) / 2, (a.Z + b.Z) / 2) * CFrame.Angles(math.rad(90), 0, 0)
		end
		cf = cf * CFrame.Angles(0, math.rad(90), 0)
		props = props or {}
		if not box then
			props.Shape = CYL
		end
		return P(name, Vector3.new((b - a).Magnitude, d, d), cf, color, SP, props)
	end
	local function octo(name, cx, cz, y1, y2, w, color)
		for i = 0, 3 do
			P(name, Vector3.new(w, y2 - y1, w * 0.4142), at(cx, (y1 + y2) / 2, cz) * CFrame.Angles(0, math.rad(45 * i), 0), color, SP)
		end
	end
	local function arc(name, p0, p1, p2, d, color, n)
		local prev = p0
		for i = 1, n do
			local t = i / n
			local p = p0 * (1 - t) ^ 2 + p1 * 2 * t * (1 - t) + p2 * t * t
			rod(name, prev, p, d, color, { CanCollide = false })
			P(name .. "Joint", Vector3.one * d, at(p.X, p.Y, p.Z), color, SP, { Shape = BALL, CanCollide = false })
			prev = p
		end
		-- flanges at both ends
		rod(name .. "Flange", p0, p0 + (p1 - p0).Unit * 1.2, d * 1.3, C.Dark, { CanCollide = false })
		rod(name .. "Flange", p2 - (p2 - p1).Unit * 1.2, p2, d * 1.3, C.Dark, { CanCollide = false })
	end
	local function fixture(x, y, z, range, color)
		local f = B("LampFixture", x - 2, y - 1, z - 2, x + 2, y, z + 2, C.Panel)
		light(f, range or 60, 1.6, color)
		return f
	end

	---------------------------------------------------------------- window wall: three framed portals
	local portals = { { -88, -44, 6, 58 }, { -30, 30, 3, 72 }, { 44, 88, 6, 58 } }
	local solids = { { -HX - 2, -88 }, { -44, -30 }, { 30, 44 }, { 88, HX + 2 } }
	for _, s in ipairs(solids) do
		B("WindowWall", s[1], 0, HZF - 2, s[2], HH, HZF, C.Hull)
		-- stepped pier: deep base layer, narrower front layer
		B("Pier", s[1], 0, HZF, s[2], HH, HZF + 4, C.Panel)
		B("Pier", s[1] + 2, 0, HZF + 4, s[2] - 2, 64, HZF + 7, C.Hull)
		B("PierCap", s[1] + 1, 64, HZF + 4, s[2] - 1, 66, HZF + 7.5, C.Dark)
		B("PierBase", s[1] + 1, 0, HZF + 4, s[2] - 1, 3, HZF + 7.6, C.Dark)
	end
	for _, p in ipairs(portals) do
		local x1, x2, y1, y2 = p[1], p[2], p[3], p[4]
		B("WindowWall", x1, 0, HZF - 2, x2, y1, HZF, C.Hull)
		B("WindowWall", x1, y2, HZF - 2, x2, HH, HZF, C.Hull)
		B("Sill", x1, 0, HZF, x2, y1, HZF + 6, C.Panel)
		B("SillLip", x1, y1, HZF + 4, x2, y1 + 0.6, HZF + 6.5, C.Dark)
		B("Lintel", x1, y2, HZF, x2, y2 + 6, HZF + 5, C.Panel)
		B("Lintel", x1, y2 + 6, HZF, x2, HH, HZF + 3, C.Hull)
		B("Window", x1, y1, HZF - 1.2, x2, y2, HZF - 0.8, C.Glass, SP, { Transparency = 0.9, CastShadow = false })
		-- chamfered corners
		for _, c in ipairs({ { x1, y2, 1 }, { x2, y2, -1 }, { x1, y1, 1 }, { x2, y1, -1 } }) do
			local top = c[2] == y2
			local sz = top and 9 or 5
			local ang = (top and 1 or -1) * c[3] * 45
			P("Chamfer", Vector3.new(sz * 1.6, sz * 0.5, 5), at(c[1] + c[3] * sz * 0.3, c[2] + (top and -sz * 0.3 or sz * 0.3), HZF + 2.5) * CFrame.Angles(0, 0, math.rad(ang)), C.Panel)
		end
		-- slim mullions on the outer pane
		local w = x2 - x1
		local n = math.max(1, math.floor(w / 20))
		for i = 1, n - 1 do
			local mx = x1 + w * i / n
			B("Mullion", mx - 0.6, y1, HZF - 1.6, mx + 0.6, y2, HZF - 0.4, C.Dark)
		end
		local ty = y1 + (y2 - y1) * 0.72
		B("Transom", x1, ty - 0.5, HZF - 1.6, x2, ty + 0.5, HZF - 0.4, C.Dark)
	end
	-- viewing platform in front of the centre portal
	B("ViewDeck", -34, 0, HZF + 8.2, 34, 1.6, -70, C.Panel)
	B("ViewDeckStep", -34, 0, -70, 34, 0.8, -68, C.Panel)
	B("ViewDeckEdge", -34.5, 1.6, -70.4, 34.5, 1.9, -69.6, C.Dark)
	for _, x in ipairs({ -60, -76, 60, 76 }) do
		bench(x, -72, 180)
	end
	for _, x in ipairs({ -50, 50 }) do
		B("ScopeLeg", x - 0.2, 0, HZF + 10.8, x + 0.2, 4, HZF + 11.2, C.Dark)
		P("Scope", Vector3.new(5, 1.4, 1.4), at(x, 4.8, HZF + 11) * CFrame.Angles(0, math.rad(90), math.rad(20)), C.White, SP, { Shape = CYL })
	end

	---------------------------------------------------------------- shell: side walls, back wall, ceiling
	wall("z", -HX - 1, HZF - 2, 71, 0, HH, { { c = 0, w = 26, h = 20, color = C.Orange }, { c = 44, w = 8, h = 8, y = 14, color = C.Orange } })
	wall("z", HX + 1, HZF - 2, 71, 0, HH, { { c = 0, w = 14, h = 12, color = C.Teal } })
	wall("x", HZB, -HX - 2, HX + 2, 0, HH, { { c = 0, w = 10, h = 8, y = 14, color = C.Purple } })
	B("Ceiling", -HX - 2, HH, HZF - 2, HX + 2, HH + 3, HZB + 1, C.Panel)
	-- heavy bulkhead frames round the two ground doors
	for _, d in ipairs({ { -1, 26, 20 }, { 1, 14, 12 } }) do
		local s, w, h = d[1], d[2], d[3]
		local xf = s * HX
		local xi = xf - s * 5
		local lo, hi = math.min(xf, xi), math.max(xf, xi)
		B("Bulkhead", lo, 0, -w / 2 - 4, hi, h + 4, -w / 2, C.Panel)
		B("Bulkhead", lo, 0, w / 2, hi, h + 4, w / 2 + 4, C.Panel)
		B("Bulkhead", lo, h, -w / 2 - 4, hi, h + 4, w / 2 + 4, C.Panel)
		for _, zc in ipairs({ -w / 2, w / 2 }) do
			P("Chamfer", Vector3.new(5, 4, 3.2), at((lo + hi) / 2, h - 0.6, zc + (zc < 0 and 1.2 or -1.2)) * CFrame.Angles(math.rad(zc < 0 and 45 or -45), 0, 0), C.Panel)
		end
	end
	-- wall pilasters and ceiling braces (show above the buildings)
	for _, s in ipairs({ -1, 1 }) do
		for z = HZF + 14, HZB - 6, 18 do
			local xf = s * HX
			local lo, hi = math.min(xf, xf - s * 2.5), math.max(xf, xf - s * 2.5)
			if math.abs(z) > 18 then
				B("Pilaster", lo, 0, z - 1.5, hi, HH, z + 1.5, C.Panel)
			else
				B("Pilaster", lo, 30, z - 1.5, hi, HH, z + 1.5, C.Panel)
			end
			rod("Brace", Vector3.new(s * (HX - 2), HH - 14, z), Vector3.new(s * (HX - 14), HH, z), 2.4, C.Panel, nil, true)
		end
		-- high pipe runs along each side wall
		for k, py in ipairs({ 82, 86 }) do
			rod("WallPipe", Vector3.new(s * (HX - 3 - k * 2), py, HZF + 1), Vector3.new(s * (HX - 3 - k * 2), py, HZB - 1), k == 1 and 3.2 or 2, k == 1 and C.Hull or C.Dark, { CanCollide = false })
		end
	end
	for z = HZF + 4, HZB - 4, 12 do
		for _, s in ipairs({ -1, 1 }) do
			B("PipeBracket", s * (HX - 8) - 1, 80, z - 0.4, s * HX + (s > 0 and 0 or 0), 80.8, z + 0.4, C.Dark)
		end
	end

	---------------------------------------------------------------- side "town": stacked multi-storey blocks
	local rng = Random.new(4242)
	local shades = { C.Hull, C.Panel, Color3.fromRGB(112, 118, 130), Color3.fromRGB(104, 100, 98) }
	local warm, cool = Color3.fromRGB(255, 196, 140), Color3.fromRGB(150, 190, 255)
	local function block(s, z1, z2, y1, y2, depth, ground)
		local xf = s * HX
		local xi = xf - s * depth
		local lo, hi = math.min(xf, xi), math.max(xf, xi)
		local col = shades[rng:NextInteger(1, #shades)]
		B("Block", lo, y1, z1, hi, y2, z2, col)
		local face = xi -- inner face plane
		local function onFace(name, za, zb, ya, yb, proud, c, props)
			local a, b = face, face - s * proud
			return B(name, math.min(a, b), ya, za, math.max(a, b), yb, zb, c, SP, props)
		end
		if ground then
			-- shop-front bay: posts, header, dark recessed shutter, canopy
			onFace("BayPost", z1, z1 + 1.6, y1, y2 - 3, 1.4, C.Dark)
			onFace("BayPost", z2 - 1.6, z2, y1, y2 - 3, 1.4, C.Dark)
			onFace("BayHeader", z1, z2, y2 - 4.5, y2 - 2.5, 1.6, C.Dark)
			onFace("Shutter", z1 + 1.6, z2 - 1.6, y1, y2 - 4.5, 0.2, Color3.fromRGB(58, 60, 66))
			for yy = y1 + 1.2, y2 - 5.2, 1.4 do
				onFace("ShutterSlat", z1 + 1.6, z2 - 1.6, yy, yy + 0.35, 0.45, Color3.fromRGB(78, 80, 88), DECOR)
			end
			onFace("Canopy", z1 - 0.6, z2 + 0.6, y2 - 0.8, y2, 3.5, C.Panel)
		else
			-- window band between two lips
			local mid = y1 + (y2 - y1) * 0.55
			onFace("Lip", z1, z2, mid - 2.2, mid - 1.6, 0.8, C.Dark)
			onFace("Lip", z1, z2, mid + 1.6, mid + 2.2, 0.8, C.Dark)
			local band = onFace("WindowBand", z1 + 1, z2 - 1, mid - 1.6, mid + 1.6, 0.1, Color3.fromRGB(44, 46, 54))
			for zz = z1 + 4, z2 - 3, 4 do
				onFace("BandRib", zz - 0.25, zz + 0.25, mid - 1.6, mid + 1.6, 0.5, C.Dark, DECOR)
			end
			if band and rng:NextNumber() < 0.35 then
				light(band, 18, 0.9, rng:NextNumber() < 0.6 and warm or cool)
			end
			onFace("Ledge", z1 - 0.4, z2 + 0.4, y2 - 0.6, y2, 1.6, C.Dark)
		end
		return xi
	end
	local function roofUnits(s, z1, z2, y, depth)
		local xf = s * HX
		for i = 1, rng:NextInteger(1, 2) do
			local w = rng:NextNumber(3, 6)
			local zc = rng:NextNumber(z1 + w, z2 - w)
			local dx = rng:NextNumber(2, depth - 2)
			local xc = xf - s * dx
			B("RoofUnit", xc - w / 2, y, zc - w / 2, xc + w / 2, y + rng:NextNumber(2, 4), zc + w / 2, C.Dark)
		end
	end
	local function stack(s, z1, z2, yBase, groundFloor)
		local y = yBase
		local depth = rng:NextNumber(12, 18)
		local levels = rng:NextInteger(2, 4)
		for lvl = 1, levels do
			local h = (lvl == 1 and groundFloor) and rng:NextNumber(12, 15) or rng:NextNumber(9, 14)
			local inset = lvl == 1 and 0 or rng:NextNumber(0, 2)
			block(s, z1 + inset, z2 - inset, y, y + h, depth, lvl == 1 and groundFloor)
			y += h
			if lvl < levels then
				local nd = math.max(6, depth - rng:NextNumber(1, 5))
				-- part of the roof below stays visible as a terrace
				depth = nd
			end
		end
		roofUnits(s, z1 + 1, z2 - 1, y, depth)
		-- an occasional pipe running down the front
		if rng:NextNumber() < 0.4 then
			local px = s * (HX - depth - 0.8)
			rod("DownPipe", Vector3.new(px, yBase, (z1 + z2) / 2 + 2), Vector3.new(px, y, (z1 + z2) / 2 + 2), 1, C.Dark, { CanCollide = false })
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		local gap = s < 0 and 18 or 12
		for _, run in ipairs({ { HZF + 10, -gap }, { gap, 30 } }) do
			local z = run[1]
			while z < run[2] - 6 do
				local w = math.min(rng:NextNumber(12, 22), run[2] - z)
				stack(s, z + 0.5, z + w - 0.5, 0, true)
				z += w
			end
		end
		-- a bridge block over the door gap, with more storeys on top
		local yb = s < 0 and 28 or 22
		stack(s, -gap - 2, gap + 2, yb, false)
		B("BridgeUnder", s < 0 and -HX or HX - 12, yb - 1.2, -gap - 2, s < 0 and -HX + 12 or HX, yb, gap + 2, C.Dark)
	end
	-- direction signs in the door gaps, coming-soon boards on the tower
	wallSign(-HX + 5.6, 24.5, 0, 22, 3, -90, "HANGAR  ·  LAUNCH", C.Orange)
	wallSign(HX - 5.6, 17, 0, 18, 3, 90, "UPGRADE HALLS  ·  BRIDGE", C.Teal)

	---------------------------------------------------------------- core tower
	octo("Plinth", 0, TZ, 0, 1.2, 36, C.Panel)
	octo("Plinth", 0, TZ, 1.2, 2.4, 30, C.Hull)
	octo("TowerBase", 0, TZ, 2.4, 8, 22, C.Panel)
	octo("TowerCore", 0, TZ, 8, HH, 16, C.Hull)
	for _, y in ipairs({ 22, 46, 70 }) do
		octo("TowerCollarUnder", 0, TZ, y - 1.5, y, 19, C.Panel)
		octo("TowerCollar", 0, TZ, y, y + 3, 23, C.Dark)
		for i = 0, 3 do
			local a = math.rad(45 + i * 90)
			fixture(math.cos(a) * 9, y - 1.5, TZ + math.sin(a) * 9, 46, i % 2 == 0 and warm or Color3.fromRGB(255, 236, 210))
		end
	end
	for _, y in ipairs({ 32, 56, 80 }) do
		octo("TowerBand", 0, TZ, y, y + 5, 16.8, Color3.fromRGB(56, 60, 70))
	end
	octo("TowerCrown", 0, TZ, HH - 8, HH - 3, 26, C.Panel)
	octo("TowerCrown", 0, TZ, HH - 3, HH, 34, C.Dark)
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local ca, sa = math.cos(a), math.sin(a)
		-- buttress from the plinth up to the core (on the diagonals, clear of the signs)
		rod("Buttress", Vector3.new(ca * 14, 2.4, TZ + sa * 14), Vector3.new(ca * 8, 20, TZ + sa * 8), 2.6, C.Panel, nil, true)
		-- riser pipes at the octagon corners
		local d = math.rad(22.5 + i * 90)
		rod("Riser", Vector3.new(math.cos(d) * 9.4, 2.4, TZ + math.sin(d) * 9.4), Vector3.new(math.cos(d) * 9.4, HH, TZ + math.sin(d) * 9.4), 1.6, C.Dark, { CanCollide = false })
	end
	wallSign(0, 41.5, TZ + 8.6, 13, 4, 180, "STARHAVEN", C.Teal, "lobby ship")
	wallSign(0, 41.5, TZ - 8.6, 13, 4, 0, "STARHAVEN", C.Teal, "lobby ship")
	wallSign(-8.6, 14, TZ, 10, 5, 90, "TOP ROLLS", C.Yellow, "leaderboards soon")
	wallSign(8.6, 14, TZ, 10, 5, -90, "EVENTS", C.Pink, "coming soon")

	---------------------------------------------------------------- walkway lane with grates
	local laneCol = Color3.fromRGB(112, 98, 64)
	for _, seg in ipairs({ { -68, TZ - 18.5 }, { TZ + 18.5, 31 } }) do
		local z1, z2 = seg[1], seg[2]
		B("Lane", -6, 0, z1, 6, 0.3, z2, laneCol)
		for _, s in ipairs({ -1, 1 }) do
			B("LaneEdge", s * 6 - 0.3, 0, z1, s * 6 + 0.3, 0.45, z2, C.Dark)
			local a, b = s * 6.3, s * 9.5
			B("GratePit", math.min(a, b), 0, z1, math.max(a, b), 0.16, z2, Color3.fromRGB(30, 32, 38))
			for z = z1 + 0.4, z2 - 0.4, 1.1 do
				B("GrateBar", math.min(a, b), 0.16, z, math.max(a, b), 0.3, z + 0.45, C.Hull, SP, DECOR)
			end
			B("LaneEdge", s * 9.5 - 0.3, 0, z1, s * 9.5 + 0.3, 0.45, z2, C.Dark)
		end
	end

	---------------------------------------------------------------- overhead: trusses, ducts, pipe arcs, lamps
	for _, z in ipairs({ HZF + 22, -44, 0, 24, 46 }) do
		local yb, yt = HH - 12, HH - 1
		B("TrussChord", -HX, yt - 1, z - 1, HX, yt + 1, z + 1, C.Dark)
		B("TrussChord", -HX, yb - 1, z - 1, HX, yb + 1, z + 1, C.Dark)
		local step = 12.5
		local x = -HX
		local flip = false
		while x < HX - 0.1 do
			local xn = x + step
			if math.abs(x) > 14 or math.abs(z - TZ) > 16 then
				B("TrussPost", x - 0.6, yb, z - 0.6, x + 0.6, yt, z + 0.6, C.Dark)
			end
			if math.abs(x + step / 2) > 16 or math.abs(z - TZ) > 16 then
				rod("TrussWeb", Vector3.new(flip and xn or x, yb, z), Vector3.new(flip and x or xn, yt, z), 1, C.Dark, nil, true)
			end
			flip = not flip
			x = xn
		end
	end
	for _, x in ipairs({ -42, 42 }) do
		B("Duct", x - 3, HH - 6, HZF, x + 3, HH - 2, HZB, C.Panel)
		for z = HZF + 6, HZB - 4, 12 do
			B("DuctFlange", x - 3.4, HH - 6.4, z - 0.4, x + 3.4, HH - 1.6, z + 0.4, C.Dark)
		end
	end
	-- big pipes arcing from the side walls over to the core tower
	for _, s in ipairs({ -1, 1 }) do
		arc("BigPipe", Vector3.new(s * (HX - 1), 60, -58), Vector3.new(s * 52, 100, -40), Vector3.new(s * 11.5, 72, TZ - 4), 5, C.Hull, 12)
		arc("BigPipe", Vector3.new(s * (HX - 1), 52, 14), Vector3.new(s * 48, 92, 0), Vector3.new(s * 11.5, 48, TZ + 4), 3.6, C.Panel, 12)
	end
	-- a few dim hanging lamps
	for _, p in ipairs({ { -60, HZF + 22 }, { 60, HZF + 22 }, { -60, 0 }, { 60, 0 }, { -30, 46 }, { 30, 46 } }) do
		B("LampCable", p[1] - 0.15, HH - 30, p[2] - 0.15, p[1] + 0.15, HH - 12, p[2] + 0.15, C.Dark, SP, DECOR)
		fixture(p[1], HH - 30, p[2], 80)
	end

	-- spawn ring around the core tower
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = model
	for i = 1, spawnCount do
		local a = (i - 1) / spawnCount * math.pi * 2 + math.pi / spawnCount
		local sp = Instance.new("Part")
		sp.Name = "Spawn"
		sp.Anchored = true
		sp.CanCollide = false
		sp.CanQuery = false
		sp.Transparency = 1
		sp.Size = Vector3.new(4, 0.2, 4)
		sp.CFrame = at(math.cos(a) * 23, 0.3, TZ + math.sin(a) * 23)
		sp.Parent = spawns
	end

	---------------------------------------------------------------- Market + mezzanine
	section("Market")
	B("Mezzanine", -HX, 13, 32, HX, 14, 54, C.Panel)
	rail("x", 32, -HX, -60, 14)
	rail("x", 32, 60, HX, 14)
	B("MezzanineFascia", -60, 12.4, 31.6, 60, 13, 32.2, C.Teal, NEON, DECOR)
	rail("x", 32, -60, -44, 14)
	rail("x", 32, -36, 36, 14)
	rail("x", 32, 44, 60, 14)
	stairs("z", 32, -1, -44, -36, 14, 1.6)
	stairs("z", 32, -1, 36, 44, 14, 1.6)
	for _, x in ipairs({ -56, -33.5, -11, 11, 33.5, 56 }) do
		B("Column", x - 1, 0, 31, x + 1, 13, 33, C.White)
		B("ColumnGlow", x - 1.1, 5, 30.9, x + 1.1, 5.4, 33.1, C.Teal, NEON, DECOR)
	end
	for _, x in ipairs({ -35, 0, 35 }) do
		local l = B("MezzLamp", x - 3, 12.4, 41, x + 3, 13, 45, C.White, NEON, DECOR)
		light(l, 26, 1.4)
	end
	local function stall(x, title, sub, color)
		local zb = 54
		B("StallPost", x - 8, 0, zb - 12, x - 7, 10, zb, C.Dark)
		B("StallPost", x + 7, 0, zb - 12, x + 8, 10, zb, C.Dark)
		B("StallBack", x - 7, 1, zb - 0.6, x + 7, 9.5, zb, color)
		for i, sx in ipairs({ -4.5, 0, 4.5 }) do
			B("Shelf", x + sx - 1.8, 5, zb - 2.2, x + sx + 1.8, 5.4, zb - 0.6, C.White)
			B("Goods", x + sx - 1.2, 5.4, zb - 2, x + sx + 1.2, 7, zb - 0.8, i == 2 and C.White or color)
		end
		B("Counter", x - 7, 0, zb - 10, x + 7, 4, zb - 7, C.White)
		B("CounterTop", x - 7.3, 4, zb - 10.3, x + 7.3, 4.6, zb - 6.7, color)
		local n = 7
		for i = 0, n - 1 do
			B("Awning", x - 8 + i * 16 / n, 10, zb - 12.5, x - 8 + (i + 1) * 16 / n, 10.8, zb, i % 2 == 0 and color or C.White)
		end
		wallSign(x, 11.7, zb - 12.9, 14, 2, 0, title, color)
		bot(x, 0, zb - 4, color, 0)
		if sub then
			local p = B("SoonPad", x - 4.5, 0, zb - 21.5, x + 4.5, 0.6, zb - 12.5, color, SP, { Transparency = 0.5 })
			label(p, { title, sub }, 4, 240)
		end
	end
	stall(-45, "CRAFTING", "coming soon", C.Purple)
	stall(-22, "GEAR SHOP", "coming soon", C.Orange)
	stall(0, "TRADE POST", nil, C.Yellow)
	pad("SellPad", "TRADE POST", "Sell all sellables", "Sell", C.Yellow, 0, 0, 37)
	stall(22, "HELPER PODS", "coming soon", C.Teal)
	stall(45, "COSMETICS", "coming soon", C.Pink)

	---------------------------------------------------------------- Crew quarters (upper level)
	section("CrewQuarters")
	B("QuartersFloor", -40, 13, 56, 40, 14, 70, C.Floor)
	B("QuartersCeiling", -40, 28, 56, 40, 29.5, 70, C.Panel)
	wall("x", 71, -42, 42, 13, 30)
	wall("z", -41, 56, 70, 13, 30)
	wall("z", 41, 56, 70, 13, 30)
	B("QuartersGlow", -40, 14, 69.4, 40, 14.15, 70, C.Purple, NEON, DECOR)
	B("QuartersGlow", -40, 25, 56, 40, 25.4, 56.4, C.Purple, NEON, DECOR)
	for i, x in ipairs({ -30, -10, 10, 30 }) do
		B("CabinDoor", x - 4, 14, 69.2, x + 4, 23, 70, C.Dark)
		B("CabinDoorGlow", x - 4.4, 23, 69.1, x + 4.4, 23.4, 70, C.Purple, NEON, DECOR)
		B("CabinDoorLine", x - 0.15, 14, 69, x + 0.15, 23, 69.2, C.Purple, NEON, DECOR)
		wallSign(x, 25, 69.2, 8, 1.6, 0, "CABIN " .. i, C.Purple)
	end
	for _, x in ipairs({ -20, 20 }) do
		local l = B("QuartersLamp", x - 4, 27.4, 61, x + 4, 28, 65, C.White, NEON, DECOR)
		light(l, 30, 1.4)
	end
	wallSign(0, 25.5, 53.4, 22, 3, 0, "CREW QUARTERS", C.Purple, "cabins coming soon")

	---------------------------------------------------------------- East wing: corridor, upgrade halls, bridge
	shift = Vector3.new(HX - 60, 0, 0)
	section("EastWing")
	dress(62, -9, 206, 9, 16, { ribFrom = 13.5, accent = C.Teal, lampEvery = 28, range = 36 })
	wall("x", 10, 62, 208, 0, 24, { { c = 99.25, w = 12, h = 12, color = C.Teal }, { c = 172.25, w = 12, h = 12, color = C.Yellow } })
	wall("x", -10, 62, 208, 0, 24, { { c = 99.25, w = 12, h = 12, color = C.Pink }, { c = 172.25, w = 12, h = 12, color = C.Blue } })
	wall("z", 207, -71, 71, 0, 24)
	wall("x", 70, 62, 208, 0, 24)
	wall("x", -70, 62, 137.5, 0, 24)
	windowWall("x", -70, 137.5, 206, 0, 24, 3, 20, 13.5)
	wall("z", 137.5, 11, 69, 0, 24)
	wall("z", 137.5, -69, -11, 0, 24)
	for i, d in ipairs({ { 7.4, C.Orange }, { 6, C.Teal }, { -7.4, C.Yellow } }) do
		P("Pipe", Vector3.new(144, 1.1, 1.1), at(134, 14.4 - (i == 2 and 0.6 or 0), d[1]), d[2], SP, { Shape = CYL, CanCollide = false })
	end
	wallSign(99.25, 14.6, 8.6, 12, 1.6, 0, "SCANNING", C.Teal)
	wallSign(172.25, 14.6, 8.6, 12, 1.6, 0, "LOOT", C.Yellow)
	wallSign(99.25, 14.6, -8.6, 12, 1.6, 180, "PLAYER", C.Pink)
	wallSign(172.25, 14.6, -8.6, 12, 1.6, 180, "BRIDGE", C.Blue)

	local function terminal(name, x, z, yaw, tree, color)
		local base = at(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
		P("Terminal", Vector3.new(12, 4, 4), base * CFrame.new(0, 2, 0), C.White)
		P("TerminalTrim", Vector3.new(12.4, 0.5, 4.4), base * CFrame.new(0, 4, 0), color)
		P("TerminalPost", Vector3.new(2, 6, 2), base * CFrame.new(0, 7, 1), C.Dark)
		local screen = P("TerminalScreen", Vector3.new(11, 6, 0.4), base * CFrame.new(0, 10, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), color, NEON, { Transparency = 0.15 })
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.LightInfluence = 0
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 24
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(0.9, 0.8)
		t.Position = UDim2.fromScale(0.05, 0.1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = C.Dark
		t.Text = string.upper(tree) .. "\nUPGRADES"
		t.Parent = g
		g.Parent = screen
		local front = base * CFrame.new(0, 0, -8)
		local p = pad(name, string.upper(tree) .. " UPGRADES", "Open upgrades", "Upgrades", color, front.Position.X - origin.X - shift.X, 0, front.Position.Z - origin.Z - shift.Z)
		p:SetAttribute("Tree", tree)
	end

	-- Scanning Hall (north-west of the corridor)
	dress(62, 11, 136.5, 69, 24, { accent = C.Teal, ribFrom = 14 })
	wallSign(99.25, 17, 68.4, 34, 5, 0, "SCANNING HALL", C.Teal, "scan speed · luck · timing")
	terminal("UpgradePad", 86, 42, 0, "Scanning", C.Teal)
	P("DishBase", Vector3.new(3, 9, 9), at(118, 1.5, 50) * CFrame.Angles(0, 0, math.rad(90)), C.Dark, SP, { Shape = CYL })
	B("DishMast", 117, 3, 49, 119, 12, 51, C.White)
	P("Dish", Vector3.new(1.4, 18, 18), at(118, 15, 50) * CFrame.Angles(math.rad(30), 0, 0) * CFrame.Angles(0, 0, math.rad(90)), C.White, SP, { Shape = CYL })
	P("DishInner", Vector3.new(1.5, 12, 12), at(118, 15.1, 50) * CFrame.Angles(math.rad(30), 0, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Teal, SP, { Shape = CYL })
	local feed = P("DishFeed", Vector3.one * 2, at(118, 19, 47.7), C.Teal, NEON, { Shape = BALL, CanCollide = false })
	light(feed, 20, 1.2, C.Teal)
	for _, z in ipairs({ 24, 40, 56 }) do
		B("RadarScreen", 62, 6, z - 5, 62.5, 12, z + 5, C.Teal, NEON, { Transparency = 0.3 })
		B("RadarFrame", 62, 5.4, z - 5.6, 62.3, 12.6, z + 5.6, C.Dark)
	end

	-- Loot Hall (north-east)
	dress(138.5, 11, 206, 69, 24, { accent = C.Yellow, ribFrom = 14 })
	wallSign(172.25, 17, 68.4, 34, 5, 0, "LOOT HALL", C.Yellow, "sell value · drops · magnet")
	terminal("UpgradePad", 172, 42, 0, "Loot", C.Yellow)
	local function chest(x, z)
		B("Chest", x - 3, 0, z - 2, x + 3, 3.5, z + 2, Color3.fromRGB(190, 120, 70))
		B("ChestLid", x - 3.2, 3.5, z - 2.2, x + 3.2, 4.6, z + 2.2, C.Yellow)
		B("ChestLock", x - 0.5, 2.6, z - 2.4, x + 0.5, 3.8, z - 2, C.Dark)
	end
	chest(150, 60)
	chest(194, 60)
	chest(196, 24)
	for _, c in ipairs({ { 156, 52 }, { 188, 52 }, { 150, 24 }, { 160, 64 } }) do
		for k = 1, 3 do
			P("Coins", Vector3.new(0.7, 3, 3), at(c[1] + (k - 2) * 0.4, 0.35 + (k - 1) * 0.7, c[2]) * CFrame.Angles(0, 0, math.rad(90)), C.Yellow, SP, { Shape = CYL })
		end
	end
	crate(201, 0, 44, 6, C.Orange)
	crate(201, 6, 44, 5, C.Yellow)
	crate(143, 0, 40, 6, C.Teal)

	-- Player Hall (south-west)
	dress(62, -69, 136.5, -11, 24, { accent = C.Pink, ribFrom = 14 })
	wallSign(99.25, 17, -68.4, 34, 5, 180, "PLAYER HALL", C.Pink, "speed · jump · health")
	terminal("UpgradePad", 86, -42, 180, "Player", C.Pink)
	for _, s in ipairs({ { 66, -65, 132, -63.6 }, { 66, -16.4, 132, -15 }, { 66, -65, 67.4, -15 }, { 130.6, -65, 132, -15 } }) do
		B("Track", s[1], 0, s[2], s[3], 0.12, s[4], C.Pink, NEON, DECOR)
	end
	P("Dummy", Vector3.new(7, 3.5, 3.5), at(118, 3.5, -56) * CFrame.Angles(0, 0, math.rad(90)), C.Pink, SP, { Shape = CYL })
	P("DummyHead", Vector3.one * 3, at(118, 8.4, -56), C.White, SP, { Shape = BALL })
	P("JumpPad", Vector3.new(0.5, 8, 8), at(118, 0.25, -28) * CFrame.Angles(0, 0, math.rad(90)), C.Pink, NEON, { Shape = CYL })
	B("Dumbbell", 104, 0.6, -58.2, 110, 1, -57.8, C.Dark)
	P("Weight", Vector3.one * 2.4, at(104, 1, -58), C.Dark, SP, { Shape = BALL })
	P("Weight", Vector3.one * 2.4, at(110, 1, -58), C.Dark, SP, { Shape = BALL })

	-- Bridge (south-east): consoles at the window, holo star map
	dress(138.5, -69, 206, -11, 24, { accent = C.Blue, ribFrom = 14 })
	wallSign(139.4, 17, -40, 30, 5, -90, "BRIDGE", C.Blue, "star map · travel")
	B("BridgeDeck", 140, 0, -69, 205, 2, -54, C.Panel)
	B("BridgeStep", 140, 0, -54, 205, 1, -52, C.Panel)
	B("BridgeDeckGlow", 140, 2, -54.4, 205, 2.15, -54, C.Blue, NEON, DECOR)
	for _, x in ipairs({ 154, 172, 190 }) do
		B("Console", x - 5, 2, -66, x + 5, 5, -62, C.White)
		P("ConsoleScreen", Vector3.new(9, 0.4, 3.4), at(x, 5.4, -64) * CFrame.Angles(math.rad(20), 0, 0), C.Blue, NEON, { Transparency = 0.2 })
	end
	local bridgeGlass = B("BridgeInnerGlass", 138.5, 2, -61.7, 206, 20, -61.3, C.Glass, SP, { Transparency = 0.85, CastShadow = false })
	bridgeGlass:AddTag("CameraBlock")
	B("CaptainSeat", 170, 2, -60, 174, 4, -57, C.Pink)
	B("CaptainBack", 170, 4, -57, 174, 8, -56, C.Pink)
	P("MapTable", Vector3.new(3, 14, 14), at(172, 1.5, -36) * CFrame.Angles(0, 0, math.rad(90)), C.White, SP, { Shape = CYL })
	local sun = P("MapSun", Vector3.one * 3, at(172, 7, -36), C.Yellow, NEON, { Shape = BALL, CanCollide = false })
	light(sun, 20, 1.4, C.Yellow)
	P("MapOrbit", Vector3.new(0.2, 11, 11), at(172, 7, -36) * CFrame.Angles(0, 0, math.rad(90)), C.Blue, NEON, { Shape = CYL, Transparency = 0.5, CanCollide = false })
	for i, col in ipairs({ C.Teal, C.Pink, C.Orange }) do
		local a = i * 2.1
		P("MapPlanet", Vector3.one * (0.8 + i * 0.3), at(172 + math.cos(a) * 5.5, 7, -36 + math.sin(a) * 5.5), col, NEON, { Shape = BALL, CanCollide = false })
	end
	pad("MapPad", "STAR MAP", "Open star map", "Map", C.Blue, 172, 0, -23)

	---------------------------------------------------------------- West wing: hangar / launch deck
	shift = Vector3.new(60 - HX, 0, 0)
	section("Hangar")
	dress(-232, -69, -62, 69, 52, { floorColor = C.FloorDark, floorMat = Enum.Material.DiamondPlate, ribFrom = 26, lampDrop = 18, range = 60, bright = 2.2, accent = C.Orange, lampEvery = 34 })
	wall("x", 70, -233, -61, 0, 52)
	wall("x", -70, -233, -61, 0, 52)
	wall("z", -233, -71, 71, 0, 52, { { c = 0, w = 90, h = 40, y = 4, color = C.Orange, glass = true } })
	for i = 0, 14 do
		local z = -45 + i * 6
		B("Hazard", -232, 0, z, -226, 0.12, z + 3, C.Yellow, SP, DECOR)
		B("Hazard", -232, 0, z + 3, -226, 0.12, z + 6, C.Dark, SP, DECOR)
	end
	-- launch platform + main launch pad
	P("LaunchRing", Vector3.new(0.4, 48, 48), at(-150, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Yellow, SP, { Shape = CYL })
	P("LaunchDisc", Vector3.new(0.5, 44, 44), at(-150, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Dark, SP, { Shape = CYL })
	P("LaunchGlow", Vector3.new(0.55, 30, 30), at(-150, 0.27, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Orange, NEON, { Shape = CYL })
	P("LaunchInner", Vector3.new(0.6, 28, 28), at(-150, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Dark, SP, { Shape = CYL })
	pad("LaunchPad", "LAUNCH", "Launch to your planet", "Launch", C.Orange, -150, 0.3, 0)
	rocket(-190, -40, C.Orange)
	rocket(-190, 40, C.Teal)
	pad("LaunchPad", "DROP SHUTTLE", "Launch to your planet", "Launch", C.Orange, -172, 0, -40)
	pad("LaunchPad", "DROP SHUTTLE", "Launch to your planet", "Launch", C.Teal, -172, 0, 40)
	wallSign(-150, 34, 68.4, 50, 8, 0, "LAUNCH DECK", C.Orange, "step on a pad to launch")
	-- gantry crane
	B("Gantry", -232, 44, -22, -62, 46, -20, C.Dark)
	B("Gantry", -232, 44, 20, -62, 46, 22, C.Dark)
	B("GantryCross", -112, 42, -22, -108, 44, 22, C.Yellow)
	B("CraneCable", -110.2, 30, -0.2, -109.8, 42, 0.2, C.Dark, SP, DECOR)
	crate(-110, 24, 0, 6, C.Orange)
	-- catwalk to the concourse mezzanine
	B("Catwalk", -120, 13, 38, -62, 14, 50, C.Panel)
	rail("x", 38, -120, -62, 14)
	rail("x", 50, -120, -62, 14)
	stairs("x", -120, -1, 38, 50, 14, 1.6)
	-- cargo + fuel tanks + crew
	for _, c in ipairs({ { -215, -62, C.Orange }, { -200, -62, C.Teal }, { -120, -62, C.Yellow }, { -95, -62, C.Pink }, { -80, -62, C.Purple }, { -215, 62, C.Green }, { -90, 62, C.Orange } }) do
		crate(c[1], 0, c[2], 6, c[3])
	end
	crate(-215, 6, -62, 5, C.Yellow)
	crate(-95, 6, -62, 5, C.Teal)
	for _, x in ipairs({ -140, -120 }) do
		P("FuelTank", Vector3.new(16, 6, 6), at(x - 20, 3, -55), C.White, SP, { Shape = CYL })
		P("FuelStripe", Vector3.new(2, 6.3, 6.3), at(x - 20, 3, -55), C.Orange, SP, { Shape = CYL })
	end
	bot(-165, 0, 16, C.Orange, 90)
	bot(-135, 0, -20, C.Teal, -90)
	bot(-205, 0, -22, C.Yellow, 0)
	bot(-100, 0, 22, C.Pink, 180)

	shift = Vector3.zero

	---------------------------------------------------------------- Metallic finish for the ship structure
	local metal = {
		[C.Hull:ToHex()] = Enum.Material.Metal,
		[C.Panel:ToHex()] = Enum.Material.Metal,
		[C.Dark:ToHex()] = Enum.Material.Metal,
		[C.White:ToHex()] = Enum.Material.Metal,
		[C.Floor:ToHex()] = Enum.Material.DiamondPlate,
		[C.FloorDark:ToHex()] = Enum.Material.DiamondPlate,
	}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Part") and d.Material == SP and d.Shape ~= BALL then
			local m = metal[d.Color:ToHex()]
			if m then
				d.Material = m
			end
		end
	end

	---------------------------------------------------------------- Toned down (Sami: nothing bright for now)
	-- Neon decor (trim lines, strips, rings, holograms) is removed; neon that holds something or
	-- belongs to a pad becomes dark metal; light colours are pulled down to hull grey; lamps and signs are dimmed.
	local function hasPadAncestor(inst)
		while inst and inst ~= model do
			if inst:GetAttribute("PadAction") then
				return true
			end
			inst = inst.Parent
		end
		return false
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == NEON then
			local onlyLights = true
			for _, c in ipairs(d:GetChildren()) do
				if not c:IsA("Light") then
					onlyLights = false
				end
			end
			if onlyLights and not hasPadAncestor(d) then
				d:Destroy()
			else
				local h, sat, v = d.Color:ToHSV()
				d.Color = Color3.fromHSV(h, sat * 0.7, math.min(v, 0.45))
				d.Material = Enum.Material.Metal
			end
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Color:ToHex() == C.White:ToHex() then
			d.Color = C.Hull
		elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			d.Brightness *= 0.4
		elseif d:IsA("SurfaceGui") then
			d.LightInfluence = 1
		end
	end
	-- darken every solid surface so the room reads as a dim metal interior
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.5 then
			local c = d.Color
			d.Color = Color3.new(c.R * 0.6, c.G * 0.6, c.B * 0.6)
		end
	end

	-- The planet seen through the windows is a skybox (ReplicatedStorage.LobbySky), shown by the
	-- client only while on the ship, so it has no edges and no parallax from any angle.

	cur = model
	return model
end

return Lobby
