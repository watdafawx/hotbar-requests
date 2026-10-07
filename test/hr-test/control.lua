local out = {}
local function check(name, ok, detail) out[#out + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" :: " .. tostring(detail)) or "") end
local function group_of(ch, name)
  for _, s in pairs(ch.get_requester_point().sections) do if s.group == name then return s end end
end
script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 5 then return end
  local s, force = game.surfaces.nauvis, game.forces.player
  local ch = s.create_entity({ name = "character", position = { 0, 0 }, force = force })
  local before = remote.call("hotbar-requests", "apply", ch, "Hotbar", { "iron-plate" }, 1)
  check("nothing before personal logistics are researched", not before or not group_of(ch, "Hotbar"), before)
  force.research_all_technologies()
  -- a request section of the player's own, which must be left alone
  local mine = ch.get_requester_point().add_section()
  mine.set_slot(1, { value = { type = "item", name = "coal", quality = "normal" }, min = 50 })
  local ok = remote.call("hotbar-requests", "apply", ch, "Hotbar", { "iron-plate", "transport-belt", "inserter" }, 1)
  local g = group_of(ch, "Hotbar")
  check("group made and filled", ok and g and #g.filters == 3, g and #g.filters)
  check("one stack each", g and g.filters[1].min == 100 and g.filters[2].min == 100 and g.filters[3].min == 50,
    g and (g.filters[1].min .. "," .. g.filters[2].min .. "," .. g.filters[3].min))
  remote.call("hotbar-requests", "apply", ch, "Hotbar", { "inserter" }, 0.5, true)
  g = group_of(ch, "Hotbar")
  check("shrinks with the hotbar, half stack, trash", g and #g.filters == 1 and g.filters[1].min == 25 and g.filters[1].max == 25,
    g and #g.filters)
  local n = 0
  for _, sec in pairs(ch.get_requester_point().sections) do if sec.group == "Hotbar" then n = n + 1 end end
  check("still one Hotbar section", n == 1, n)
  check("your own section untouched", mine.valid and mine.filters[1] and mine.filters[1].value.name == "coal" and mine.filters[1].min == 50)
  helpers.write_file("hr-test.txt", table.concat(out, "\n") .. "\n")
end)
