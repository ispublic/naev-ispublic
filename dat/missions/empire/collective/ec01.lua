--[[

   Collective Espionage I

   Second mission in the mini collective campaign.

   You must inspect a system for wireless communications.

]]--

lang = naev.lang()
if lang == "es" then
   -- not translated atm
else -- default english
   bar_desc = "You notice Lt. Commander Dimitri who seems to be motioning for you to come over."
   misn_title = "Collective Espionage"
   misn_reward = "None"
   misn_desc = {}
   misn_desc[1] = "Scan the Collective systems for wireless communications."
   misn_desc[2] = "Travel back to %s in %s."
   title = {}
   title[1] = "Lt. Commander Dimitri"
   title[2] = "Collective Espionage"
   title[3] = "Mission Accomplished"
   text = {}
   text[1] = [[You meet up with Lt. Commander Dimitri.
"We managed to capture the drone after you located it.  It didn't seem to be in good health.  Our scientists are studying it as we speak, but we've found something strange in it.  Some sort of weird wireless module.  We'd like you to go run through the Collective systems to see if you can pick up any strange wireless communications.  Just do a quick run through, be careful of the Collective though.  You interested in doing the run?  It'll be dangerous."]]
   text[2] = [["Just run through some systems while keeping your communications system on logging.  We'll parse the results when you get back.  With just visiting 2 or 3 Collective systems it should be more then enough.  Good luck."]]
   text[3] = [[After landing Lt. Commander Dimitri greets you on the land pad.
"I suppose all went well?  Those drones can really give a beating.  We'll have the researchers start looking at your logs right away.  Meet me in the bar again in a while."]]
end


function create ()
   misn.setNPC( "Dimitri", "none" )
   misn.setDesc( bar_desc )
end


function accept ()
   -- Intro text
   if not tk.yesno( title[1], text[1] ) then
      misn.finish()
   end

   -- Accept mission
   misn.accept()

   misn_stage = 0      
   systems_visited = 0 -- Number of Collective systems visited
   misn_base,misn_base_sys = planet.get("Omega Station")

   -- Mission details
   misn.setTitle(misn_title)
   misn.setReward( misn_reward )
   misn.setDesc(misn_desc[1])
   misn.setMarker( system.get("C-00"), "misc" )

   tk.msg( title[2], text[2] )

   hook.enter("enter")
end


function enter()
   local sys = system.get()
   local factions = sys:faction()

   -- Increment System visited count
   if misn_stage == 0 and factions["Collective"] then
      systems_visited = systems_visited + 1

      -- Visited enough systems
      if misn_stage == 0 and systems_visited >= 2 then
         misn.setDesc( string.format(misn_desc[2],
               misn_base:name(), misn_base_sys:name()) )
         misn_stage = 1
         misn.setMarker(misn_base_sys, "misc") -- now we mark return to base
         hook.land("land")
         player.msg("You have enough recordings, return to base.");
      end
   end
end

function land()
   local pnt = planet.get()

   if misn_stage == 1 and  pnt == misn_base then
      tk.msg( title[3], text[3] )
      player.modFaction("Empire",5)
      misn.finish(true)
   end
end

