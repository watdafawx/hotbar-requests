data:extend({
  { type = "bool-setting", name = "hotbar-requests-enabled", setting_type = "runtime-per-user", default_value = true, order = "a" },
  { type = "string-setting", name = "hotbar-requests-group", setting_type = "runtime-per-user", default_value = "Hotbar",
    allow_blank = false, order = "b" },
  { type = "double-setting", name = "hotbar-requests-stacks", setting_type = "runtime-per-user", default_value = 1,
    minimum_value = 0.01, maximum_value = 100, order = "c" },
  { type = "int-setting", name = "hotbar-requests-pages", setting_type = "runtime-per-user", default_value = 10,
    minimum_value = 1, maximum_value = 10, order = "d" },
  { type = "bool-setting", name = "hotbar-requests-trash", setting_type = "runtime-per-user", default_value = false, order = "e" },
})
