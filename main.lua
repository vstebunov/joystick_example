-- ����� ������������� ��� �������� � ����������� + ��� �������� �
-- �������������������
-- ������ ������ ��� ������ ������� ����� ��� �������� ����������
--
-- ����� physics ��� ��� ���� ����� ������ �������, � ��� ����� �� �� ������
-- �������� ���� ������
-- ���������� ��������������� ��� ������ � ��������������
HardonCollider = require "hardoncollider"
--
-- ����� ��� ������ http://www.colourlovers.com/palette/44745/Viking_Invasion

local START_JOYSTICK_POINTER = 1
local JOYSTICK_MAX_COUNT = 4

local BUTTON_ATTACK_NUMBER = 1
local BUTTON_SHOT_NUMBER = 2

local is_joystick_activated = {}
local player_circle = {}

local colors = { {252, 160, 85}, {230, 226, 162}, {0, 0, 255}, {50, 50, 50} }

local collider

local borderTop

local BAR_COUNT = 30
local bars = {}

local arrows = {}

function love.load()

	collider = HardonCollider(100, on_collision, collision_stop)

	--��������� ��� ��������� ��������� � �� ������ ������� � ������
	--��� ������� ��������� ������� ���������� � ������� �� ��������� �������
	for i = START_JOYSTICK_POINTER, JOYSTICK_MAX_COUNT do
		if love.joystick.open(i) then
			table.insert(is_joystick_activated, i)
			table.insert(player_circle, { 
				cx = 0,
				cy = 0,
				color = colors[i],
				body = collider:addCircle( 100 + 60 * i, 100, 25),
				button = {},
				angle = 1
			})

			player_circle[i].body.type = "player"

		end
	end

	-- ���������� � �������� ������ ���� �����
	for i = 1, BAR_COUNT do
		table.insert(bars, { body = collider:addCircle( math.random() * 800 + 10, math.random() * 600 + 10, 15) } )
		bars[i].body.type = "bar"
	end

	-- ������� ������
	borderTop = collider:addRectangle(0, -100, 800, 100)

	--test
	joy = { x = 100, y = 100 } 

end

function love.update(d)
	collider:update(d)
	--���������� ��� ��������� �� ������� ��������� �����
	for _, joy_index in ipairs(is_joystick_activated) do
		local ax1, ay1, ax2, ay2 = love.joystick.getAxes(joy_index)
		--�������� �� ����������� ��������� �������� 
		--��� ������ �� �����
		--����� �� ��������� ������� �� ������������
		local x, y = player_circle[joy_index].body:center()

		player_circle[joy_index].body:moveTo( 
			x + ax1 + player_circle[joy_index].cx,
			y + ay1 + player_circle[joy_index].cy)

		--���� ����� ����� �� �������, �� ������ ������
		if player_circle[joy_index].button[BUTTON_SHOT_NUMBER] then
			local ar_x = x + math.cos(player_circle[joy_index].angle) * 50
			local ar_y = y + math.sin(player_circle[joy_index].angle) * 50
			local arrow = { 
				body = collider:addCircle(ar_x, ar_y, 5), 
				x = math.cos(player_circle[joy_index].angle), 
				y = math.sin(player_circle[joy_index].angle)}
			arrow.body.type = "arrow"
			table.insert(arrows, arrow)
		end

		player_circle[joy_index].angle = math.atan2(ay1, ax1)

	end

	
	--� ������� ������ � ������ ����������� �������
	for _, arrow in ipairs(arrows) do
		local x, y = arrow.body:center()
		local ax, ay = arrow.x * 10, arrow.y * 10
		arrow.body:moveTo( x + ax, y + ay)
	end

end

function love.draw()
	love.graphics.setBackgroundColor(107, 131, 73)
	--������� ��� ������� ��������� ��������
	for _, joy_index in ipairs(is_joystick_activated) do
		love.graphics.setColor(player_circle[joy_index].color)
		local x, y = player_circle[joy_index].body:center()
		love.graphics.circle("fill", x, y, 25)
	end
	--������� ���� ����� �� �����
	for _, bar in ipairs(bars) do
		love.graphics.setColor({157,175,127})
		local x, y = bar.body:center()
		love.graphics.circle("fill", x, y, 15)
	end
	--������� ��� ������ �� �����
	for _, arrow in ipairs(arrows) do
		love.graphics.setColor({175,189,94})
		local x, y = arrow.body:center()
		love.graphics.circle("fill", x, y, 5)
	end
end

function on_collision(dt, a, b, mtv_x, mtv_y)
	-- ������ �������� ��������� ��� ������������
	for _, player in ipairs(is_joystick_activated) do
		if player_circle[player].body == a then
			player_circle[player].cx = mtv_x 
			player_circle[player].cy = mtv_y 
		end
		if player_circle[player].body == b then
			player_circle[player].cx = mtv_x * -1
			player_circle[player].cy = mtv_y * -1
		end

		-- ���� � ��� ����� ���� � �� ����� �������� �����
		-- �� ������� �����
		if player_circle[player].button[BUTTON_ATTACK_NUMBER]
			and ((player_circle[player].body == a and b.type == "bar") or
				(player_circle[player].body == b and a.type == "bar"))then

				local killed_bar = b
				if a.type == "bar" then
					killed_bar = a
				end

				remove_bar(killed_bar)

		end
	end
	
	--�������� �� ����� ������������� �����
	if a.type == "bar" and b.type == "bar" then
		local x, y = a:center()
		a:moveTo(x + mtv_x, y + mtv_y)
	end


	--������� ������ � ����� ������� ��������������
	if (a.type == "bar" and b.type == "arrow") 
		or (a.type == "arrow" and b.type =="bar") then

		local killed_bar = b
		local fallen_arrow = a
		if a.type == "bar" then
			killed_bar = a
			fallen_arrow = b
		end

		remove_bar(killed_bar)

		for i, arrow in ipairs(arrows) do
			if arrow.body == fallen_arrow then
				collider:remove(fallen_arrow)
				table.remove(arrows, i)
			end
		end
	end

end

function remove_bar(killed_bar)
	for i, bar in ipairs(bars) do
		if bar.body == killed_bar then
			collider:remove(killed_bar)
			table.remove(bars, i)
		end
	end
end

function collision_stop(dt, a, b)
	-- ����� ���� ��� ������������ ��������� ������� �������� ���� �� ������
	-- ������ ������ ������
	for _, player in ipairs(is_joystick_activated) do
		if player_circle[player].body == a 
			or player_circle[player].body == b then
			player_circle[player].cx = 0
			player_circle[player].cy = 0
		end
	end
end

function love.joystickpressed( joystick_number, button_number )
	player_circle[joystick_number].button[button_number] = true
end

function love.joystickreleased( joystick_number, button_number )
	player_circle[joystick_number].button[button_number] = false
end

