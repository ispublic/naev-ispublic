--[[
   Support common functions for Points of Interest
--]]
local lmisn = require "lmisn"
local fmt = require "format"
local luaspfx = require "luaspfx"
local prob = require "prob"
local poi = {}

-- luacheck: globals _poi_enter _poi_scan _poi_heartbeat_nooutfit _poi_heartbeat (Hook functions passed by name)

--[[--
   @brief Tries to generate a new setting for a point of interest.
      @treturn table A table of parameters for the point of interest mission or nil if failed to generate.
--]]
function poi.generate()
   local syscand = lmisn.getSysAtDistance( nil, 1, 5, function( sys )
      -- Want no inhabited spobs
      for k,p in ipairs(sys:spobs()) do
         if sys.land and sys.inhabitable then
            return false
         end
      end
      return true
   end )

   -- Didn't find system
   if #syscand<=0 then return end

   local sys = syscand[ rnd.rnd(1,#syscand) ]

   -- Bias towards easier at start
   local risk = math.min(prob.poisson_sample( 1.5 ),5) -- 0 to 5
   risk = math.min( poi.done(), risk ) -- Only easy ones at first

   -- Return parameter table
   return {
      sys = sys,
      risk = risk,
   }
end

--[[--
   @brief sets up a point of interest mission. Meant to be called before starting the point of interest mission with naev.missionStart()
      @tparam table params Parameter table. Can be passed directly from poi.generate
--]]
function poi.setup( params )
   local risk = params.risk or 0
   local sys = system.get( params.sys )

   if var.peek("_poi_system") ~= nil or var.peek("_poi_risk") ~= nil then
      warn(_("Point of Interest variables being overwritten!"))
   end

   var.push( "_poi_system", sys:nameRaw() )
   var.push( "_poi_risk", risk )
end

function poi.start ()
   local sys = var.peek("_poi_system")
   local risk = var.peek("_poi_risk")
   if sys==nil or risk==nil then
      warn(_("Point of Interest not properly initialized!"))
   end
   if sys ~= nil then
      sys = system.get( sys )
   end
   return sys, risk
end

local pos, timer, path, goal, mrk
function _poi_enter ()
   if system.cur() ~= mem.poi.sys then
      pos = nil
      goal = nil
      if mem.poi.chook then
         hook.rm( mem.poi.chook )
         mem.poi.chook = nil
      end
      if timer then
         hook.rm( timer )
         timer = nil
      end
      return
   end

   -- Find the initial point of interest, and path to the real location
   pos = vec2.newP( system.cur():radius()*0.6, rnd.angle() ) -- TODO better initialization
   path = {}
   local angle = rnd.angle()
   local mpos = pos
   for i=1,rnd.rnd(13,17) do -- should average 15*5505 = 8250 units
      mpos = vec2.newP( 400+300*rnd.rnd(), angle ) + mpos
      angle = angle + rnd.sigma()
      table.insert( path, mpos )
   end
   goal = mpos + vec2.newP( 300+400*rnd.rnd(), angle )
   mem.goal = goal

   mrk = system.mrkAdd( pos, _("Point of Interest") )

   -- Custom hook for when the player scans
   mem.poi.chook = hook.custom( "poi_scan", "_poi_scan" )

   -- If the player has no scanning outfit we have to help them out
   local pp = player.pilot()
   local haspoi = false
   for k,v in ipairs(pp:outfits()) do
      if v:tags().poi_scan then
         haspoi = true
         break
      end
   end
   if not haspoi then
      timer = hook.timer( 5, "_poi_heartbeat_nooutfit" )
   end
end

function _poi_heartbeat_nooutfit ()
   if player.pos():dist( pos ) < 3e3 then
      -- TODO ship AI message
      player.msg(_("You lack an outtfit no scan the point of interest."),true)
      return
   end
   timer = hook.timer( 1, "_poi_heartbeat_nooutfit" )
end

local started, path_spfx
function _poi_scan ()
   -- Ignore if not close
   if started or player.pos():dist( pos ) > 3e3 then
      return
   end

   -- Starts marks
   started = true
   path_spfx = {}

   timer = hook.timer( 1, "_poi_heartbeat" )
end

function _poi_heartbeat ()
   for k,v in ipairs(path) do
      -- Have to follow the path
      if not path_spfx[k] and (k<=1 or path_spfx[k-1]) and player.pos():dist( v ) < 1e3 then
         path_spfx[k] = luaspfx.trail( v, path[k+1] or goal )
      end
   end

   -- Found goal
   if path_spfx[ #path ] and player.pos():dist( goal ) < 1e3 then
      _G[ mem.poi.found ]()
      return
   end

   timer = hook.timer( 1, "_poi_heartbeat" )
end

--[[--
   @brief Sets up a Point Of Interest (POI) mission
      @tparam table params Table of parameters to use. `sys` and `found` must be defined, where `sys` is the system the POI takes place in, and `found` is the name of the global function to call when found.
--]]
function poi.misnSetup( params )
   local function riskstr( r )
      if r > 3 then
         return _("High")
      elseif r > 1 then
         return _("Low")
      else
         return _("None")
      end
   end
   mem.poi = {
      sys      = params.sys,
      found    = params.found,
      risk     = params.risk,
      riskstr  = params.riskstr or riskstr( params.risk ),
      rewardstr= params.rewardstr or _("Unknown"),
   }

   -- Accept and set up mission
   misn.accept()
   misn.setTitle(_("Point of Interest")) -- TODO maybe randomize somewhat?
   misn.setReward(_("Unknown")) -- TODO give some hint?
   misn.setDesc(fmt.f(_([[A point of interest has been found in the {sys} system. It is not clear what can be foound, however, it warrants investigation. You should bring an outfit that can perform scans such as a #bPulse Scanner#0.

#nEstimated Risk:#0 {risk}
#nEstimated Reward:#0 {reward}]]),
      {sys=mem.poi.sys, risk=mem.poi.riskstr, reward=mem.poi.rewardstr} ) )

   misn.markerAdd( mem.poi.sys, "low" )

   hook.enter( "_poi_enter" )
   if system.cur() == mem.poi.sys then
      _poi_enter()
   end
end

--[[--
   @brief Cleans up after a point of interest mission.
--]]
function poi.misnDone( failed )
   system.mrkRm( mrk )
   for k,v in ipairs(path_spfx) do
      v:rm()
   end

   if not failed then
      var.push( "poi_done", poi.done()+1 )
   end
end

--[[--
   @brief Gets how many points of interest were completed by the player.
      @treturn number Number of points of interest completed by the player.
--]]
function poi.done()
   return var.peek("poi_done") or 0
end

return poi