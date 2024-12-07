-- MIT License
-- 
-- Copyright (c) 2024 Qubik
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


-- fetch display
-- NOTE: this project was made using 128x128 display,
-- and other resolutions for now will not be scaled
local display = getComponent("display")
display.setOptimizationLevel(0)

-- fetch display resolution
local WIDTH, HEIGHT = display.getSize()
local HWIDTH, HHEIGHT = WIDTH / 2, HEIGHT / 2

-- constants
local FOV = 120
local DRAW_THRESHOLD = 0.01

-- object vertices
local cube_vertices = {
	{ 1,  1,  1},  -- 1 (1, 1, 1)
	{ 1,  1, -1},  -- 2
	{ 1, -1,  1},  -- 3
	{ 1, -1, -1},  -- 4
	{-1,  1,  1},  -- 5
	{-1,  1, -1},  -- 6
	{-1, -1,  1},  -- 7
	{-1, -1, -1},  -- 8 (0, 0, 0)
}

-- indexes into 'cube_vertices'
local cube_polygons = {
	-- front
	{7, 3, 4},
	{7, 4, 8},
	-- back
	{1, 5, 6},
	{1, 6, 2},
	-- left
	{5, 7, 8},
	{5, 8, 6},
	-- right
	{3, 1, 2},
	{3, 2, 4},
	-- top
	{5, 1, 3},
	{5, 3, 7},
	-- bottom
	{8, 4, 2},
	{8, 2, 6}
}

-- poly_queue
local poly_queue = {}
local poly_queue_ptr = 0

-- [rotations]
-- rotate around X axis
function rotX(x, y, z, theta)
	return x, y * math.cos(theta) - z * math.sin(theta), z * math.cos(theta) + y * math.sin(theta)
end

-- rotate around Y axis
function rotY(x, y, z, theta)
	return x * math.cos(theta) - z * math.sin(theta), y, z * math.cos(theta) + x * math.sin(theta)
end

-- rotate around Z axis
function rotZ(x, y, z, theta)
	return x * math.cos(theta) - y * math.sin(theta), y * math.cos(theta) + x * math.sin(theta), z
end

-- rotate around X then Y then Z axies
function rotXYZ(x, y, z, rx, ry, rz)
	px, py, pz = rotX(x, y, z, rx)
	px, py, pz = rotY(px, py, pz, ry)
	return rotZ(px, py, pz, rz)
end

-- simple perspective projection
function project3d(x, y, z)
	return x * FOV / z + HWIDTH, y * FOV / z + HHEIGHT
end

-- call to draw polygons
function draw_call()
	table.sort(
		poly_queue,
		function(a, b) return math.max(a[3], a[6], a[9]) < math.max(b[3], b[6], b[9]) end)
	for i, v in ipairs(poly_queue) do
		
	end
end

function append_poly(x1, y1, z1, x2, y2, z2, x3, y3, z3, color)
	table.insert(poly_queue, {x1, y1, z1, x2, y2, z2, x3, y3, z3, color})
end

-- draw triangle function
-- NOTE: uses naive / simplistic scanline filling algorithm
function draw_poly(x1, y1, x2, y2, x3, y3, color)
	-- sort vectors (y3 - biggest, y1 - smallest)
	-- selection sorting
	if y1 > y2 then  -- swap p1 with p2
		x1, y1, x2, y2 = x2, y2, x1, y1
	end
	if y2 > y3 then  -- swap p2 with p3
		x2, y2, x3, y3 = x3, y3, x2, y2
		if y1 > y2 then  -- swap p1 with p2
			x1, y1, x2, y2 = x2, y2, x1, y1
		end
	end

	-- 0 height triangle
	if y1 - y3 == 0 then return end

	-- slope for line p1 to p3
	local slope_middle = (x3 - x1) / (y3 - y1)

	-- scanline filling algorithm
	local xo1, xo2 = x1, x1  -- 'x offset 1' and 'x offset 2'
	if y2 - y1 > DRAW_THRESHOLD then  -- draw top-flat triangle
		-- slope for line p1 to p2
		local slope_top = (x2 - x1) / (y2 - y1)
		for yo = y1, y2 do
			display.drawLine(xo1, yo, xo2, yo, color)
			xo1 = xo1 + slope_top
			xo2 = xo2 + slope_middle
		end
	end

	-- reset 'x offset 1' to be at 'x2', otherwise triangle will be drawn incorrectly
	xo1 = x2

	if y3 - y2 > DRAW_THRESHOLD then  -- draw bottom-flat triangle
		-- slope for line p2 to p3
		local slope_bottom = (x3 - x2) / (y3 - y2)
		for yo = y2, y3 do
			display.drawLine(xo1, yo, xo2, yo, color)
			xo1 = xo1 + slope_bottom
			xo2 = xo2 + slope_middle
		end
	end
end

-- object drawing function (for now just cube)
function draw_cube(x, y, z, sx, sy, sz, rx, ry, rz)
	local vertex_count = 12
	for i=1, vertex_count do
		-- fetch vertices
		x1, y1, z1 = unpack(cube_vertices[cube_polygons[i][1]])
		x2, y2, z2 = unpack(cube_vertices[cube_polygons[i][2]])
		x3, y3, z3 = unpack(cube_vertices[cube_polygons[i][3]])

		-- rotate vertices
		x1, y1, z1 = rotXYZ(x1 * sx, y1 * sy, z1 * sz, rx, ry, rz)
		x2, y2, z2 = rotXYZ(x2 * sx, y2 * sy, z2 * sz, rx, ry, rz)
		x3, y3, z3 = rotXYZ(x3 * sx, y3 * sy, z3 * sz, rx, ry, rz)

		append_poly(x1, y1, z1, x2, y2, z2, x3, y3, z3, i / vertex_count * 255)

		-- project them from 3d to 2d
		px1, py1 = project3d(x1 + x, y1 + y, z1 + z)
		px2, py2 = project3d(x2 + x, y2 + y, z2 +z)
		px3, py3 = project3d(x3 + x, y3 + y, z3 +z)

		-- draw polygon
		draw_poly(px1, py1, px2, py2, px3, py3, i / vertex_count * 255)
	end
end

-- main loop
local frame_count = 0
function onStart()
	display.clear()
	frame_count = frame_count + 1
	draw_cube(
		0, 0, 20,
		3, 3, 3,
		frame_count / 100, frame_count / 100, frame_count / 100)
	draw_call()
	display.flush()
end

_enableCallbacks = true