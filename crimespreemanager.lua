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

local OldFunc01 = CrimeSpreeManager._setup_modifiers
function CrimeSpreeManager:_setup_modifiers()
	if not self:is_active() then
		return
	end
	local Checker = false
	for _, active_data in ipairs(self:server_active_modifiers()) do
		if self:get_modifier(active_data.id).class == "ModifierEnemyHealthAndDamage" then
			Checker = true
			break
		end
	end
	if not Checker then
		return OldFunc01(self)
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
	OldFunc01(self)
	_G.ModifierEnemyHealthAndDamage.new, managers.modifiers.add_modifier = OldExtraFunc1, OldExtraFunc2
	return managers.modifiers:add_modifier(_G["ModifierEnemyHealthAndDamage"]:new(self:get_modifier_stack_data("ModifierEnemyHealthAndDamage")), "crime_spree")
end

local OldFunc02 = CrimeSpreeManager.get_modifier_stack_data
function CrimeSpreeManager:get_modifier_stack_data(modifier_type)
	if modifier_type ~= "ModifierEnemyHealthAndDamage" then
		return OldFunc02(self, modifier_type)
	end
	local stack = 0
	local modifiers = self:is_active() and self:server_active_modifiers() or self:active_modifiers()
	for _, active_data in ipairs(modifiers) do
		if active_data.id == tweak_data.crime_spree.modifiers.forced[1].id then
			stack = math.max(math.floor((self._global.peer_spree_levels and self._global.peer_spree_levels[1] or self._global.spree_level or 0) / tweak_data.crime_spree.modifier_levels.forced), active_data.level)
			if stack > active_data.level then
				active_data.level = stack
			end
			break
		end
	end
	local stack_data = OldFunc02(self, modifier_type)
	for key, _ in pairs(tweak_data.crime_spree.modifiers.forced[1].data) do
		stack_data[key] = tweak_data.crime_spree.modifiers.forced[1].data[key][1] * stack
	end
	return stack_data
end

local OldFunc03 = CrimeSpreeManager.reset_crime_spree
function CrimeSpreeManager:reset_crime_spree()
	self.SFM.active_modifiers = nil
	return OldFunc03(self)
end

local OldFunc04 = CrimeSpreeManager.active_modifiers
function CrimeSpreeManager:active_modifiers()
	if self:is_active() or not self:_is_host() then
		return OldFunc04(self)
	end
	return self:server_active_modifiers()
end

local OldFunc05 = CrimeSpreeManager.server_active_modifiers
function CrimeSpreeManager:server_active_modifiers()
	if not self.SFM.active_modifiers then
		local data = {
			id = tweak_data.crime_spree.modifiers.forced[1].id,
			level = math.floor((self._global.peer_spree_levels and self._global.peer_spree_levels[1] or self._global.spree_level or 0) / tweak_data.crime_spree.modifier_levels.forced)
		}
		local active_modifiers = (self:is_active() or not self:_is_host()) and OldFunc05(self) or OldFunc04(self)
		if not active_modifiers then
			return {data}
		end
		if not (self:is_active() or self.SFM.Checker) then
			local count = 0
			for _, v in pairs(tweak_data.crime_spree.modifier_levels) do
				count = count + math.floor(self._global.spree_level / v)
			end
			if #active_modifiers > count then
				self.SFM.Checker = true
			end
		end
		self.SFM.active_modifiers = {}
		local modifiers = {}
		if data.level >= math.max(tweak_data.crime_spree.modifier_levels.loud * #tweak_data.crime_spree.modifiers.loud, tweak_data.crime_spree.modifier_levels.stealth * #tweak_data.crime_spree.modifiers.stealth) then
			for i, modifier in ipairs(tweak_data.crime_spree.modifiers.loud) do
				table.insert(self.SFM.active_modifiers, {id = modifier.id, level = math.max(i-2, 1) * tweak_data.crime_spree.modifier_levels.loud})
			end
			for i, modifier in ipairs(tweak_data.crime_spree.modifiers.stealth) do
				table.insert(self.SFM.active_modifiers, {id = modifier.id, level = math.max(i-2, 1) * tweak_data.crime_spree.modifier_levels.stealth})
			end
		else
			for _, v in ipairs(active_modifiers) do
				for _, id in ipairs(NewFunc()) do
					if v.id == id then
						if not modifiers[v.id] then
							table.insert(self.SFM.active_modifiers, v)
							modifiers[v.id] = true
						end
						break
					end
				end
			end
		end
		table.insert(self.SFM.active_modifiers, data)
		if self.SFM.Checker then
			self._global.modifiers = self.SFM.active_modifiers
		end
	end
	return self.SFM.active_modifiers
end

local OldFunc06 = CrimeSpreeManager.modifiers_to_select
function CrimeSpreeManager:modifiers_to_select(table_name, ...)
	if table_name ~= "forced" then
		local OldExtraFunc = CrimeSpreeManager.server_active_modifiers
		CrimeSpreeManager.server_active_modifiers = OldFunc05
		local count = OldFunc06(self, table_name, ...)
		CrimeSpreeManager.server_active_modifiers = OldExtraFunc
		return count
	end
	if self:_is_host() then
		if self.SFM.Checker then
			local count = 0
			for _, v in ipairs(self.SFM.active_modifiers) do
				if v.id == tweak_data.crime_spree.modifiers.forced[1].id then
					count = v.level
					break
				end
			end
			for i = 1, count - 1 do
				self:select_modifier(tweak_data.crime_spree.repeating_modifiers.forced[1].id .. tostring(math.floor(self:server_spree_level() / tweak_data.crime_spree.repeating_modifiers.forced[1].level) * i))
			end
			self.SFM.Checker = nil
		else
			local base_number = self:server_spree_level() / tweak_data.crime_spree.modifier_levels.forced
			local Checker = false
			for _, v in ipairs(self._global.modifiers) do
				if table.contains(NewFunc(), v.id) then
					base_number = base_number + 1
				elseif v.id == tweak_data.crime_spree.modifiers.forced[1].id then
					Checker = true
				end
			end
			if not Checker then
				self:select_modifier(tweak_data.crime_spree.modifiers.forced[1].id)
			end
			for i = 1, base_number - #self._global.modifiers do
				self:select_modifier(tweak_data.crime_spree.repeating_modifiers.forced[1].id .. tostring(math.floor(self:server_spree_level() / tweak_data.crime_spree.repeating_modifiers.forced[1].level) * i))
			end
		end
	end
	return 0
end

local OldFunc07 = CrimeSpreeManager._get_modifiers
function CrimeSpreeManager:_get_modifiers(...)
	local OldExtraFunc = CrimeSpreeManager.server_active_modifiers
	CrimeSpreeManager.server_active_modifiers = OldFunc05
	local modifiers = OldFunc07(self, ...)
	CrimeSpreeManager.server_active_modifiers = OldExtraFunc
	return modifiers
end

local OldFunc08 = CrimeSpreeManager.select_modifier
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
	if self:_is_host() or table.contains(NewFunc(), modifier_id) then
		return OldFunc08(self, modifier_id)
	end
end

local OldFunc09 = CrimeSpreeManager.on_left_lobby
function CrimeSpreeManager:on_left_lobby()
	self.SFM.active_modifiers = nil
	return OldFunc09(self)
end

local OldFunc10 = CrimeSpreeManager.set_server_modifier
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
	if self:_is_host() or table.contains(NewFunc(), modifier_id) then
		return OldFunc10(self, modifier_id, modifier_level, ...)
	end
end