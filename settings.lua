dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.

-- This file can't access other files from this or other mods in all circumstances.
-- Settings will be automatically saved.
-- Settings don't have access unsafe lua APIs.

-- Use ModSettingGet() in the game to query settings.
-- For some settings (for example those that affect world generation) you might want to retain the current value until a certain point, even
-- if the player has changed the setting while playing.
-- To make it easy to define settings like that, each setting has a "scope" (e.g. MOD_SETTING_SCOPE_NEW_GAME) that will define when the changes
-- will actually become visible via ModSettingGet(). In the case of MOD_SETTING_SCOPE_NEW_GAME the value at the start of the run will be visible
-- until the player starts a new game.
-- ModSettingSetNextValue() will set the buffered value, that will later become visible via ModSettingGet(), unless the setting scope is MOD_SETTING_SCOPE_RUNTIME.
--
-- Noita's gui library has gained quite a few peculiarities over the years. For example not all widgets support all GUI_OPTION values.
-- The gui library isn't our main work of art, and if something doesn't seem to work, it might very well be our fault.
-- We probably never have time to fix the bugs (and all the code that has various workarounds to get around them :) )

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value  )
	print( mod_id.."."..setting.id..":"..tostring(old_value).."->"..tostring(new_value) )
end

local mod_id = "wand_workshop" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.
mod_settings =
{
	{
		id = "mix_fraction",
		ui_name = "Mix Ratio",
		ui_description =
            "The percentage of stats the sacrificed wand should give the target." ..
            "\nIf target > sacrificed wand, (ratio - 100)% is added instead" ..
            "\nOmni pillar (rune omega) receives half of this %" ..
            "\nbut improves all 6 growth stats (shuffle/simulcast ignored!)." ..
            "\n0%: Single-stat pillars do nothing. The old stat is always kept." ..
            "\n50%: The stat becomes the average of both. Absorb OFF." ..
            "\n100%: If target < sacrifice, swap stats. Absorb OFF." ..
            "\n150%: If sacrifice < target, absorb 50% (Omni 25%)." ..
            "\n200%: If sacrifice < target, absorb 100% (Omni 50%)." ..
            "\nRecommended is 110 or 120, or go wild, who cares.",
		value_default = 1.1,
		value_min = 0,
		value_max = 2,
		value_display_multiplier = 100,
		value_display_formatting = " $0 %",
		scope = MOD_SETTING_SCOPE_NEW_GAME,
		change_fn = mod_setting_change_callback, -- Called when the user interact with the settings widget.
	},
	{
		id = "omni_override",
		ui_name = "Omni Ratio",
		ui_description =
            "Omni pillar (rune omega) absorbs (mix - 100), cut in half." ..
            "\nIf desired, this setting overrides that, up to 100%." ..
            "\n0%: Use the default (doesn't disable omni pillar)." ..
            "\n50%: Omni absorbs 50% (speed/reload/spread/mana/charge/slots)." ..
            "\n100%: Omni absorbs 100% (speed/reload/spread/mana/charge/slots)." ..
            "\nIf Mix Ratio is at or below 100, you can still" ..
            "\ngrow wands using the Omni pillar, if you set this > 0%.",
		value_default = 0,
		value_min = 0,
		value_max = 1,
		value_display_multiplier = 100,
		value_display_formatting = " $0 %",
		scope = MOD_SETTING_SCOPE_NEW_GAME,
		change_fn = mod_setting_change_callback, -- Called when the user interact with the settings widget.
	},
	{
		id = "capacity_max",
		ui_name = "Capacity Maximum",
		ui_description = "Wand slots can go off screen if they get too high.",
		value_default = 26,
		value_min = 0,
		value_max = 30,
		value_display_multiplier = 1,
		value_display_formatting = " $0",
		scope = MOD_SETTING_SCOPE_NEW_GAME,
		change_fn = mod_setting_change_callback, -- Called when the user interact with the settings widget.
	}
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )

	--example usage:
	--[[
	GuiLayoutBeginLayer( gui )

	GuiBeginAutoBox( gui )

	GuiZSet( gui, 10 )
	GuiZSetForNextWidget( gui, 11 )
	GuiText( gui, 50, 50, "Gui*AutoBox*")
	GuiImage( gui, im_id, 50, 60, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiZSetForNextWidget( gui, 13 )
	GuiImage( gui, im_id, 60, 150, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )

	GuiZSetForNextWidget( gui, 12 )
	GuiEndAutoBoxNinePiece( gui )

	GuiZSetForNextWidget( gui, 11 )
	GuiImageNinePiece( gui, 12368912341, 10, 10, 80, 20 )
	GuiText( gui, 15, 15, "GuiImageNinePiece")

	GuiBeginScrollContainer( gui, 1233451, 500, 100, 100, 100 )
	GuiLayoutBeginVertical( gui, 0, 0 )
	GuiText( gui, 10, 0, "GuiScrollContainer")
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiLayoutEnd( gui )
	GuiEndScrollContainer( gui )

	local c,rc,hov,x,y,w,h = GuiGetPreviousWidgetInfo( gui )
	print( tostring(c) .. " " .. tostring(rc) .." " .. tostring(hov) .." " .. tostring(x) .." " .. tostring(y) .." " .. tostring(w) .." ".. tostring(h) )

	GuiLayoutEndLayer( gui )]]--
end
