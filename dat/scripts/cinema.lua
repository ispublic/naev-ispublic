--[[--
Functions for handling cinematic scenes.

@module cinema
--]]
local cinema = {}

local old = {}

--[[--
Enables cinematic mode.

   @param params Parameters.
--]]
function cinema.on( params )
   local pp = player.pilot()
   local plts = pp:followers()
   table.insert( plts, pp )

   for k,p in ipairs(plts) do
      old[ p ] = {
         invincible = p:flags("invincible"),
         control = p:flags("manualcontrol"),
      }

      p:control(true)
      p:brake()
      p:setInvincible(true)
   end

   player.cinematics( true, params )
end

--[[--
Disables cinematic mode.
--]]
function cinema.off ()
   for p,o in ipairs(old) do
      p:control( o.control )
      p:setInvincible( o.invincible )
   end

   camera.set()
   player.cinematics( false )

   old = {}
end

return cinema
