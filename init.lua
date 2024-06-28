local F = minetest.formspec_escape

local function setup(itemstack, player)
	if not minetest.check_player_privs(player,{luawand=true}) then return end
	local meta = itemstack:get_meta()
	minetest.show_formspec(player:get_player_name(), "luawand_code", "size[16,9]" ..
		"style[code;font=mono]" ..
		"field[0.4,0.5;15.7,1;description;Description;"..F(meta:get("description") or "LuaWand").."]" ..
		"textarea[0.4,1.3;15.7,8.3;code;Variables: itemstack\\, player\\, pointed_thing;"..F(meta:get_string("code")).."]" ..
		"set_focus[save]" ..
		"button[13.8,8.4;2,1;save;Save]")
end

minetest.register_privilege("luawand",{
	description = "Allows to configure LuaWand",
	give_to_singleplayer = false,
	give_to_admin = false
})

minetest.register_tool("luawand:luawand",{
	description = "LuaWand",
	inventory_image = "luawand.png",
	on_place = setup,
	on_secondary_use = setup,
	on_use = function(itemstack, player, pointed_thing)
		local name = player:get_player_name()
		local meta = itemstack:get_meta()
		local code = meta and meta:get_string("code")
		if not code or code == "" then
			minetest.chat_send_player(name, "The LuaWand is not configured!")
		end
		local func, synerr = loadstring("return function(itemstack,player,pointed_thing)"..code.." end")
		if func then
			local good, err = pcall(func(),itemstack,player,pointed_thing)
			if not good then
				minetest.chat_send_player(name,"/!\\ LuaWand error: "..dump(err))
			end
		else
			minetest.chat_send_player(name,"/!\\ LuaWand error: "..dump(synerr))
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "luawand_code" or not player then return end
	if fields.save then
		local name = player:get_player_name()
		local witem = player:get_wielded_item()
		local meta = witem and witem:get_meta()
		local winame = witem and witem:get_name()
		if not (winame == "luawand:luawand" and meta) then
			minetest.chat_send_player(name, "/!\\ LuaWand: Something went wrong")
		end
		meta:set_string("code",fields.code)
		if fields.description then
			meta:set_string("description",fields.description)
		end
		player:set_wielded_item(witem)
		minetest.chat_send_player(name,"(i) LuaWand: Saved")
	end
end)
