-- Hotbar Requests: a logistic request group (section) on your character that always holds the items pinned to
-- your quickbar. Rebuilt whenever a quickbar slot changes, when you join or respawn, and when settings change.

-- planners, remotes and the like: nothing a robot can deliver
local NOT_REQUESTABLE = {
  ["blueprint"] = true, ["blueprint-book"] = true, ["deconstruction-item"] = true, ["upgrade-item"] = true,
  ["selection-tool"] = true, ["copy-paste-tool"] = true, ["spidertron-remote"] = true,
}

--- unique {name, quality} of the quickbar's items
--- @param player LuaPlayer
local function hotbar_items(player, pages)
  local out, seen = {}, {}
  for i = 1, pages * 10 do
    local f = player.get_quick_bar_slot(i)
    if f then
      local name = type(f.name) == "string" and f.name or (f.name and f.name.name)
      local quality = f.quality and (type(f.quality) == "string" and f.quality or f.quality.name) or "normal"
      local proto = name and prototypes.item[name]
      if proto and not NOT_REQUESTABLE[proto.type] and not proto.has_flag("only-in-cursor")
          and not proto.has_flag("spawnable") then
        local key = name .. "/" .. quality
        if not seen[key] then
          seen[key] = true
          out[#out + 1] = { name = name, quality = quality, stack = proto.stack_size }
        end
      end
    end
  end
  return out
end

--- write `items` into the character's request section named `group` (made if missing)
--- @param character LuaEntity
--- @return boolean written
local function apply(character, group, items, stacks, trash)
  local point = character.get_requester_point()
  if not point then
    return false
  end
  local section
  for _, s in pairs(point.sections) do
    if s.group == group then
      section = s
      break
    end
  end
  if not section then
    section = point.add_section(group)  -- nil before personal logistics are researched
    if not section then
      return false
    end
  end
  if not section.is_manual then
    return false
  end
  local filters = {}
  for i, it in pairs(items) do
    local count = math.max(1, math.floor(it.stack * stacks + 0.5))
    filters[i] = {
      value = { type = "item", name = it.name, quality = it.quality, comparator = "=" },
      min = count,
      max = trash and count or nil,
    }
  end
  section.filters = filters
  return true
end

--- the character's section for this group, if it has one
local function find_section(character, group)
  local point = character.get_requester_point()
  for _, s in pairs(point and point.sections or {}) do
    if s.group == group then return s end
  end
end

--- @param player LuaPlayer
--- @param only_if_changed boolean? the periodic check: write only when the hotbar, settings or section changed
local function sync(player, only_if_changed)
  if not (player and player.valid and player.character and player.character.valid) then
    return
  end
  local s = player.mod_settings
  if not s["hotbar-requests-enabled"].value then
    return
  end
  local group = s["hotbar-requests-group"].value --[[@as string]]
  local stacks, trash = s["hotbar-requests-stacks"].value --[[@as number]], s["hotbar-requests-trash"].value --[[@as boolean]]
  local items = hotbar_items(player, s["hotbar-requests-pages"].value --[[@as integer]])
  local parts = { group, tostring(stacks), tostring(trash), tostring(player.character.unit_number) }
  for _, it in pairs(items) do parts[#parts + 1] = it.name .. "/" .. it.quality end
  local sig = table.concat(parts, "|")
  storage.last = storage.last or {}
  if only_if_changed and storage.last[player.index] == sig then
    local section = find_section(player.character, group)
    if section and #section.filters == #items then
      return  -- nothing changed
    end
  end
  if apply(player.character, group, items, stacks, trash) then
    storage.last[player.index] = sig
  end
end

local function sync_event(e)
  sync(game.get_player(e.player_index))
end

-- added to (or updated in) a save: loading a single-player save raises no "joined" event, so sync everyone here
local function sync_all()
  for _, player in pairs(game.players) do sync(player) end
end
script.on_init(sync_all)
script.on_configuration_changed(sync_all)

-- a safety net every 5 s, for what no event reports (a section deleted or renamed by hand, another mod changing
-- the quickbar, a character swap): a few API reads per player, and a write only when something changed
script.on_nth_tick(300, function()
  for _, player in pairs(game.connected_players) do sync(player, true) end
end)

script.on_event(defines.events.on_player_set_quick_bar_slot, sync_event)
script.on_event(defines.events.on_player_joined_game, sync_event)
script.on_event(defines.events.on_player_respawned, sync_event)
script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.player_index and string.sub(e.setting, 1, 16) == "hotbar-requests-" then
    sync(game.get_player(e.player_index))
  end
end)
-- personal logistics researched: the section can be made now
script.on_event(defines.events.on_research_finished, function(e)
  for _, player in pairs(e.research.force.connected_players) do
    local point = player.character and player.character.valid and player.character.get_requester_point()
    if point then
      local has = false
      for _, s in pairs(point.sections) do
        if s.group == player.mod_settings["hotbar-requests-group"].value then has = true end
      end
      if not has then sync(player) end
    end
  end
end)

-- for automated tests (headless has no players): fill a character's group from a list of item names
remote.add_interface("hotbar-requests", {
  apply = function(character, group, names, stacks, trash)
    local items = {}
    for _, n in pairs(names) do
      local proto = prototypes.item[n]
      if proto then items[#items + 1] = { name = n, quality = "normal", stack = proto.stack_size } end
    end
    return apply(character, group, items, stacks or 1, trash)
  end,
})
