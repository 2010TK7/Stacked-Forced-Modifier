CrimeSpreeManager.SFM = CrimeSpreeManager.SFM or {}

local NewFunc = function()
	if not CrimeSpreeManager.SFM.modifiers then
		CrimeSpreeManager.SFM.modifiers = {}
		for _, k in ipairs({"loud", "stealth"}) do
			for _, v in ipairs(tweak_data.crime_spree.modifiers[k]) do
				table.insert(CrimeSpreeManager.SFM.modifiers, v.id)
			end
		end
	end
	return CrimeSpreeManager.SFM.modifiers
end

local OldFunc1 = CrimeSpreeManager._setup_modifiers
function CrimeSpreeManager:_setup_modifiers()
	local Checker = false
	for _, active_data in ipairs(self:server_active_modifiers()) do
		if self:get_modifier(active_data.id).class == "ModifierEnemyHealthAndDamage" then
			Checker = true
			break
		end
	end
	if not Checker then
		return OldFunc1(self)
	end
	local OldExtraFunc1, OldExtraFunc2 = _G.ModifierEnemyHealthAndDamage.new, managers.modifiers.add_modifier
	function _G.ModifierEnemyHealthAndDamage:new()
		return
	end
	function managers.modifiers:add_modifier(modifier, ...)
		if modifier then
			return OldExtraFunc2(self, modifier, ...)
		end
	end
	OldFunc1(self)
	_G.ModifierEnemyHealthAndDamage.new, managers.modifiers.add_modifier = OldExtraFunc1, OldExtraFunc2
	return managers.modifiers:add_modifier(_G["ModifierEnemyHealthAndDamage"]:new(self:get_modifier_stack_data("ModifierEnemyHealthAndDamage")), "crime_spree")
end

local OldFunc2 = CrimeSpreeManager.get_modifier_stack_data
function CrimeSpreeManager:get_modifier_stack_data(modifier_type)
	if modifier_type ~= "ModifierEnemyHealthAndDamage" then
		return OldFunc2(self, modifier_type)
	end
	local stack = 0
	local modifiers = self:is_active() and self:server_active_modifiers() or self:active_modifiers()
	for _, active_data in ipairs(modifiers) do
		if active_data.id == tweak_data.crime_spree.modifiers.forced[1].id then
			stack = active_data.level
			break
		end
	end
	local stack_data = OldFunc2(self, modifier_type)
	for key, _ in pairs(tweak_data.crime_spree.modifiers.forced[1].data) do
		stack_data[key] = tweak_data.crime_spree.modifiers.forced[1].data[key][1] * stack
	end
	return stack_data
end

local OldFunc3 = CrimeSpreeManager.reset_crime_spree
function CrimeSpreeManager:reset_crime_spree()
	self.SFM.active_modifiers = nil
	return OldFunc3(self)
end

local OldFunc4 = CrimeSpreeManager.active_modifiers
function CrimeSpreeManager:active_modifiers()
	if self:is_active() then
		return OldFunc4(self)
	end
	return self:server_active_modifiers()
end

local OldFunc5 = CrimeSpreeManager.server_active_modifiers
function CrimeSpreeManager:server_active_modifiers()
	if not self.SFM.active_modifiers then
		local data = {
			id = tweak_data.crime_spree.modifiers.forced[1].id,
			level = math.floor((self._global.peer_spree_levels and self._global.peer_spree_levels[1] or self._global.spree_level or 0) / tweak_data.crime_spree.modifier_levels.forced)
		}
		local active_modifiers = self:is_active() and OldFunc5(self) or OldFunc4(self)
		if not active_modifiers or #active_modifiers == 0 then
			return {data}
		end
		if not self:is_active() then
			local modifiers = {}
			local count = 0
			for k, v in ipairs(active_modifiers) do
				if table.contains(NewFunc(), v.id) then
					if not modifiers[v.id] then
						modifiers[v.id] = true
					else
						table.insert(modifiers, 1, k)
					end
				else
					count = count + 1
					if count > data.level then
						table.insert(modifiers, 1, k)
					end
				end
			end
			if #modifiers ~= 0 then
				for _, k in ipairs(modifiers) do
					table.remove(active_modifiers, k)
				end
				self._global.modifiers = active_modifiers
			end
		end
		self.SFM.active_modifiers = {}
		local modifiers = {}
		for _, v in ipairs(active_modifiers) do
			local Checker = false
			for k, id in ipairs(NewFunc()) do
				if v.id == id then
					if not modifiers[v.id] then
						Checker = k
						modifiers[v.id] = true
					end
					break
				end
			end
			if Checker then
				table.insert(self.SFM.active_modifiers, v)
			end
		end
		table.insert(self.SFM.active_modifiers, data)
	end
	return self.SFM.active_modifiers
end

local OldFunc6 = CrimeSpreeManager.modifiers_to_select
function CrimeSpreeManager:modifiers_to_select(table_name, ...)
	if table_name ~= "forced" then
		return OldFunc6(self, table_name, ...)
	end
	local base_number = self:server_spree_level() / tweak_data.crime_spree.modifier_levels.forced
	local active_modifiers = deep_clone(self:is_active() and OldFunc5(self) or OldFunc4(self))
	for i = #active_modifiers, 1, -1 do
		local Checker = false
		for k, id in ipairs(NewFunc()) do
			if active_modifiers[i].id == id then
				Checker = k
				break
			end
		end
		if Checker then
			table.remove(active_modifiers, i)
		end
	end
	if base_number - #active_modifiers > 0 then
		local Checker = false
		local modifiers = {}
		for _, v in ipairs(active_modifiers) do
			if v.id == tweak_data.crime_spree.modifiers.forced[1].id then
				Checker = true
				break
			end
		end
		if not Checker then
			table.insert(modifiers, tweak_data.crime_spree.modifiers.forced[1])
			if base_number == #active_modifiers then
				return 0
			end
		end
		for i = 1, base_number - #active_modifiers do
			local new_mod = deep_clone(tweak_data.crime_spree.repeating_modifiers.forced[1])
			new_mod.id = new_mod.id .. tostring(math.floor(self:server_spree_level() / new_mod.level) * i)
			table.insert(modifiers, new_mod)
		end
		if Network:is_server() then
			for _, modifier in ipairs(modifiers) do
				self:select_modifier(modifier.id)
			end
		else
			for _, modifier in ipairs(modifiers) do
				self:set_server_modifier(modifier.id, self:server_spree_level())
			end
		end
	end
	return 0
end

local OldFunc7 = CrimeSpreeManager.select_modifier
function CrimeSpreeManager:select_modifier(modifier_id)
	if self.SFM.active_modifiers and table.contains(NewFunc(), modifier_id) then
		local Checker = true
		for _, data in ipairs(self.SFM.active_modifiers) do
			if data.id == modifier_id then
				Checker = false
				break
			end
		end
		if Checker then
			table.insert(self.SFM.active_modifiers, {id = modifier_id, level = self:spree_level()})
		end
	end
	return OldFunc7(self, modifier_id)
end

local OldFunc8 = CrimeSpreeManager.on_left_lobby
function CrimeSpreeManager:on_left_lobby()
	self.SFM.active_modifiers = nil
	return OldFunc8(self)
end

local OldFunc9 = CrimeSpreeManager.set_server_modifier
function CrimeSpreeManager:set_server_modifier(modifier_id, modifier_level, ...)
	if self.SFM.active_modifiers and table.contains(NewFunc(), modifier_id) then
		local Checker = true
		for _, data in ipairs(self.SFM.active_modifiers) do
			if data.id == modifier_id then
				Checker = false
				break
			end
		end
		if Checker then
			table.insert(self.SFM.active_modifiers, {id = modifier_id, level = modifier_level})
		end
	end
	return OldFunc9(self, modifier_id, modifier_level, ...)
end