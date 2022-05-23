--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Generic News">
 <trigger>load</trigger>
 <chance>100</chance>
</event>
--]]
--[[
   Event for creating news
--]]
local pir = require "common.pirate"
local fmt = require "format"
local lmisn = require "lmisn"
local lf = require "love.filesystem"

-- luacheck: globals land (Hook funtions passed by name)

local add_article, add_econ_article, add_header -- forward-declared functions

-- List to treat special factions diffferently
local override_list = {
   -- Treat pirate clans the same (at least for now)
   ["Wild Ones"] = "Pirate",
   ["Raven Clan"] = "Pirate",
   ["Dreamer Clan"] = "Pirate",
   ["Black Lotus"] = "Pirate",
   -- Other misc factions
   ["Strangelove"] = "Generic",
}

local header_table = {}
local greeting_table = {}
local articles = {}

header_table["Sirius"]     = _("Sirius News Reel. Words of the Sirichana for all.")
header_table["FLF"]        = _("The word of the Free Resistance.")
header_table["Frontier"]   = _("News from the Frontier Alliance.")
header_table["Proteron"]   = _("Word from the Proteron state.")
header_table["Soromid"]    = _("The voice of the future.")
header_table["Thurion"]    = _("Data Relay Network")

greeting_table["FLF"] = {""}
greeting_table["Frontier"] = {
   _("News you can trust."),
}
greeting_table["Sirius"] = {
   _("Stay faithful."),
   _("Sirichana watches and guides you."),
}
greeting_table["Proteron"] = {""}
greeting_table["Soromid"] = {
   _("Genetically tailoured for you."),
   _("Naturally selected news."),
}
greeting_table["Thurion"] = {""}

articles["Sirius"] = {
   --[[
      Science and technology
   --]]
   --[[
      Business
   --]]
   {
      tag = N_([[Trade Meeting at Lorelei]]),
      desc = _([[Lorelei, in the Churchill system, is the latest world to host major trade negotiations between the Fyrra and the Space Traders Guild. The Fyrra Arch-Canter has indicated that opening up trade routes is a major goal.]])
   },
   --[[
      Politics
   --]]
   {
      tag = N_([[Dvaered Extorting Pilgrims]]),
      desc = _([[Recent pilgrims headed to Mutris have been telling stories of extortion and violations by Dvaered operators. Dvaered Warlord Kra'tok claims that these are "figments of the touched's imagination". Official complaints have been made to the Emperor.]])
   },
   --[[
      Human interest.
   --]]
   {
      tag = N_([[Words of Tranquility]]),
      desc = _([[We welcome many new Touched who have recently begun ministering to the Shaira echelon after their long pilgrimage on Mutris. House Sirius is still a refugee for the orphans lost in this Universe.]])
   },
}

articles["Pirate"] = {
}

articles["Frontier"] = {
   --[[
      Science and technology
   --]]
   --[[
      Business
   --]]
   --[[
      Politics
   --]]
   {
      tag = N_([[Election on Caladan Marred by Fraud]]),
      desc = _([[As many as two of every hundred votes counted after the recent polling decaperiod may be falsified, an ombudsman reports. The opposition party demanded the election be annulled.]])
   },
   {
      tag = N_([[Empire Relies on Prison Labour]]),
      desc = _([[A recent report by the Soromid House Ways and Means Committee suggests infrastructure may be too dependent the on the incarcerated population.]])
   },
   {
      tag = N_([[Imperial Oversight Scandal]]),
      desc = _([[Sources close to the Imperial Chancellor say they see the failure at the Department of Oversight, whose inspectors overlooked serious failings in other supervisory bodies, as a serious oversight.]])
   },
   --[[
      Human interest.
   --]]
}

articles["FLF"] = {}
articles["Proteron"] = {}
articles["Thurion"] = {}

local econ_articles = {
   {
      title = _("Unfortunate Merchant Goes Bankrupt"),
      desc = _([[A merchant was forced into bankruptcy due to a badly timed trade of {cargo} on {pnt}. "I thought {credits} per tonne was a good deal, but it turns out I should have waited," the merchant said.]])
   },
   {
      title = _("Shipping Company Goes Out of Business"),
      desc = _([[A small shipping business failed just this decaperiod. While it was already failing, what finally put the company under was a poorly-timed trade of {cargo} on {pnt} for {credits} per tonne. "It was poor executive decision," one analyst asserts. "Patience is key when trading, and it's clear that the owner of this company didn't have enough of that."]])
   },
   {
      title = _("Interview with an Economist"),
      desc = _([[One of the galaxy's foremost experts on economics gives an interview explaining our modern economy. "We actually have a pretty good understanding of how the economy works. For example, we were able to predict what the price of {cargo} on {pnt} would reach very accurately; the actual price reached was {credits} per tonne, which we were only off by about 15%. Over time, we hope to lower that margin of error to as little as 2%."]])
   },
   {
      title = _("Economist Describes Sinusoidal Economic Theory"),
      desc = _([[A little-known economist discusses a controversial economic theory. "When you look at the trends, it resembles a sine wave. For instance, the price of {cargo} on {pnt} is now {credits} per tonne, and it seems to return to that price with some regularity. We are working on developing a model to predict these curves more accurately." Other economists disagree, however, attributing these economists' results to chance.]])
   },
   {
      title = _("Young Pilot Buys Their First Commodity"),
      desc = _([[A young pilot has bought some {cargo} as a way of breaking into the freelance piloting business. Born and raised on {pnt}, where they bought their first commodity, they spoke with enthusiasm for the new career. "You know, it's real exciting! Even on my home planet the price of {credits} per tonne isn't static, but when you look all around, there's so much price variation, so much potential for profit! I'm excited to finally get started."]])
   },
   {
      title = _("Corporate Scandal Rips Through the Galaxy"),
      desc = _([[Economists are attributing the price of {cargo} on {pnt} to a scandal involving WarpTron Industries. Debates have ensued regarding whether or not the price, seen to be {credits} per tonne, will go up, down, or remain the same this time.]])
   },
   {
      title = _("Commodity Trading Likened to Gambling"),
      desc = _([[In a controversial statement, one activist has likened commodity trading to gambling. "It's legalized gambling, plain and simple! Right now the price of {cargo} on {pnt} is {credits} per tonne, for example, but everyone knows the price fluctuates. Tomorrow it could be lower, or it could be higher. Who knows? Frankly, it is my firm opinion that this 'commodity trading' is self-destructive and needs to stop."]])
   },
   {
      title = _("Leadership Decision Disrupts Prices"),
      desc = _([[The price of {cargo} was jeopardized on {pnt} today when the local government passed a controversial law, bringing it to {credits} per tonne. Protests have erupted demanding a repeal of the law so that the economy can stabilize.]])
   },
   {
      title = _("Five Cycle Old Child Starts Commodity Trading"),
      desc = _([[A child no more than five cycles old has started commodity trading early, buying 1 tonne of {cargo}. A native of {pnt}, she explained that she has a keen interest in the economy and wishes to be a space trader some day. "I bought it for {credits}, but it goes up and down, so if you time it right, you can make more money! My mom is a trader too and I want to be just like her."]])
   },
}

-- Appends a table to a destination table
local function merger( dest, src, key )
   if not src then return end

   if not dest[key] then
      dest[key] = {}
   end

   for i,v in ipairs(src) do
      local k = key
      if type(v) == "table" and v.key then -- allow overwriting keys
         k = v.key
         if not dest[k] then
            dest[k] = {}
         end
      end
      table.insert( dest[k], v )
   end
end

-- Try to load all the modular news files
for k,v in ipairs(lf.enumerate("events/news")) do
   local key, head, greet, art = require( "events.news."..string.gsub(v,".lua","") )()
   merger( header_table, head, key )
   merger( greeting_table, greet, key )
   merger( articles, art, key )
end

-- Return an economy article based on the given commodity, planet object, and number of credits.
local function get_econ_article( cargo, pnt, credits )

   local i = rnd.rnd( 1, #econ_articles )
   local title = econ_articles[i]["title"]
   local desc = fmt.f( econ_articles[i]["desc"], {cargo=cargo, pnt=pnt, credits=fmt.credits(credits)} )

   return title, desc
end

function create()
   hook.land( "land" )
end

-- create news
function land ()
   local p = spob.cur()
   local s = p:services()
   -- Needs to be inhabited and have a bar for there to be news
   if not s["inhabited"] or not s["bar"] then evt.finish(false) end
   -- Needs a faction for there to be news
   local f = p:faction()
   if f == nil then evt.finish(false) end
   local my_faction = f:nameRaw()

   local t = override_list[my_faction]
   if t then
      my_faction = t
   end

   add_header( my_faction )
   add_article( my_faction )
   add_article( "Generic" )
   add_econ_article()
end


function add_header( my_faction )
   -- Remove old headers (we only want one at a time)
   for i, article in ipairs( news.get( "header" ) ) do
      article:rm()
   end

   if header_table[my_faction] == nil then
      warn( fmt.f( _([[News: Faction '{fct}' does not have entry in faction table!]]), {fct=my_faction}) )
      my_faction = 'Generic'
   end

   local cur_t = time.get()
   local header = header_table[my_faction]
   if type(header)=="table" then header = header[ rnd.rnd(1,#header) ] end
   local desc = greeting_table[my_faction][ rnd.rnd( 1, #greeting_table[my_faction] ) ]
   local a = news.add( my_faction, header, desc, cur_t + time.create( 0, 0, 1 ), 0, -1 ) -- Highest priority
   a:bind( "header" )
end

function add_article( my_faction )
   local last_article = var.peek( "news_last_article" )
   if last_article ~= nil then
      local t = time.fromnumber( last_article )
      if time.get() - t < time.create( 0, 1, 5000 ) then
         return
      end
   end

   if rnd.rnd() > 0.25 then
      return
   end

   local alst = articles[my_faction]
   if alst == nil or #alst <= 0 then
      return
   end

   local i = rnd.rnd( 1, #alst )
   local tag   = alst[i]["tag"]
   local title = alst[i]["title"] or _(tag)
   local desc  = alst[i]["desc"]
   if type(desc)=="function" then
      desc = desc()
   end

   if #news.get( tag ) > 0 then
      return
   end

   local exp = time.get() + time.create( 0, 10, 5000 * rnd.sigma() )
   local a = news.add( my_faction, title, desc, exp, nil, 6 ) -- Slightly lower priority than default
   a:bind( tag )
   var.push( "news_last_article", time.get():tonumber() )
end


function add_econ_article ()
   local last_article = var.peek( "news_last_econ_article" )
   local t = nil
   if last_article ~= nil then t = time.fromnumber( last_article ) end
   if (t == nil or time.get() - t > time.create( 0, 2, 0 ))
         and rnd.rnd() < 0.75 then
      local planets = {}
      for i, s in ipairs( lmisn.getSysAtDistance( system.cur(), 2, 4 ) ) do
         for j, p in ipairs( s:spobs() ) do
            if not pir.factionIsPirate( p:faction() )
                  and p:faction() ~= faction.get("FLF")
                  and #(p:commoditiesSold()) > 0 then
               planets[ #planets + 1 ] = p
            end
         end
      end
      if #planets > 0 then
         local p = planets[ rnd.rnd( 1, #planets ) ]
         local pd = time.get() - time.create(
               0, p:system():jumpDist() + rnd.rnd( 0, 1 ), 9000 * rnd.sigma() )
         local exp = time.get() + time.create( 0, 5, 5000 * rnd.sigma() )
         local commchoices = p:commoditiesSold()
         local commod = commchoices[ rnd.rnd( 1, #commchoices ) ]
         local price = commod:priceAtTime( p, pd )
         local title, desc = get_econ_article( commod, p, price )
         news.add( "Generic", title, desc, exp, pd, 6 ) -- Slightly lower priority
         p:recordCommodityPriceAtTime( pd )
         var.push( "news_last_econ_article", time.get():tonumber() )
      end
   end

   -- Remove old econ articles (we only want one at a time)
   for i, article in ipairs(news.get("econ")) do
      article:rm()
   end

   local cur_t = time.get()
   local body = ""
   for i, sys in ipairs( lmisn.getSysAtDistance( system.cur(), 0, 1 ) ) do
      for j, plnt in ipairs( sys:spobs() ) do
         local commodities = plnt:commoditiesSold()
         if #commodities > 0 then
            body = body .. "\n\n" .. fmt.f( _("{pnt} in {sys}"), {pnt=plnt, sys=sys} )
            for k, comm in ipairs( commodities ) do
               body = body .. "\n" .. fmt.f( _("{cargo}: {price}"), {cargo=comm,
                     price=fmt.number(comm:priceAtTime(plnt, cur_t))} )
            end
            plnt:recordCommodityPriceAtTime( cur_t )
         end
      end
   end
   if body ~= "" then
      -- Create news, expires immediately when time advances (i.e.
      -- when you take off from the planet).
      -- Lowest priority
      local a = news.add( "Generic", _("Current Market Prices"), body, cur_t + time.create( 0, 0, 1 ), nil, 11 )
      a:bind( "econ" )
   end
end
