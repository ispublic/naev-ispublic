local lg = require 'love.graphics'
local lf = require 'love.filesystem'

local blink_shader_frag = lf.read( "scripts/luaspfx/shaders/blink.frag" )
local blink_shader
local ttl = 2

local function update( s, dt )
   local d = s:data()
   d.timer = d.timer + dt / ttl
end

local function render( sp, x, y, z )
   local d = sp:data()
   local c = d.canvas

   blink_shader:send( "u_progress", 1-d.timer )

   lg.setColor( 1, 1, 1 )
   local old_shader = lg.getShader()
   lg.setShader( blink_shader )
   -- We have to flip the y axis
   c:draw( x-c.w*z*0.5, y+c.h*z*0.5, 0, z, -z )
   lg.setShader( old_shader )
end

local function blink( pos, vel )
   if not blink_shader then
      blink_shader = lg.newShader( blink_shader_frag )
   end

   local s = spfx.new( ttl, update, render, nil, nil, pos, vel, nil )
   local d  = s:data()
   d.canvas = lg.newCanvas( player.pilot():render() )
   d.timer = 0
end

return blink