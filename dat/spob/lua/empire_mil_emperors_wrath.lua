local luaspob = require "spob.lua.lib.spob"

function load( spb )
   return luaspob.setup( spb, {
      std_land = 90,
      std_bribe = 100,
      msg_granted = {
         _([["The Emperor permits you to land."]]),
      },
      msg_notyet = {
         _([["You may not approach the Emperor."]]),
      },
      msg_cantbribe = {
         _([["Don't attempt to bribe an Empire official, pilot."]]),
      },
   } )
end

can_land = luaspob.can_land
comm = luaspob.comm