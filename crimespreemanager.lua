local NewFunc1 = function(level)
	if type(level) ~= "table" then
		return false
	end
	return #level >= (#tweak_data.crime_spree.modifiers.loud + #tweak_data.crime_spree.modifiers.stealth + math.floor(math.max(tweak_data.crime_spree.modifier_levels.loud * #tweak_data.crime_spree.modifiers.loud, tweak_data.crime_spree.modifier_levels.stealth * #tweak_data.crime_spree.modifiers.stealth) / tweak_data.crime_spree.modifier_levels.forced))
end

local NewFunc2 = function(self)
	local modifiers = {}
	for i, modifier in ipairs(tweak_data.crime_spree.modifiers.loud) do
		table.insert(modifiers, {id = modifier.id, level = math.max(i-2, 1) * tweak_data.crime_spree.modifier_levels.loud})
	end
	for i, modifier in ipairs(tweak_data.crime_spree.modifiers.stealth) do
		table.insert(modifiers, {id = modifier.id, level = math.max(i-2, 1) * tweak_data.crime_spree.modifier_levels.stealth})
	end
	local server_spree_level = self:server_spree_level()
	table.insert(modifiers, {id = tweak_data.crime_spree.modifiers.forced[1].id, level = math.floor((server_spree_level ~= -1 and server_spree_level or self._global.spree_level or 0) / tweak_data.crime_spree.modifier_levels.forced)})
	return modifiers
end

local OldFunc1 = CrimeSpreeManager._setup_modifiers
function CrimeSpreeManager:_setup_modifiers()
	local checker = false
	for _, active_data in ipairs(self:server_active_modifiers()) do
		if self:get_modifier(active_data.id).class == "ModifierEnemyHealthAndDamage" then
			checker = true
			break
		end
	end
	if not checker then
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
	local stack_data = OldFunc2(self, modifier_type)
	local stack = math.floor(self:server_spree_level() / tweak_data.crime_spree.modifier_levels.forced)
	for key, _ in pairs(tweak_data.crime_spree.modifiers.forced[1].data) do
		stack_data[key] = tweak_data.crime_spree.modifiers.forced[1].data[key][1] * stack
	end
	return stack_data
end

local OldFunc3 = CrimeSpreeManager.active_modifiers
function CrimeSpreeManager:active_modifiers()
	if self:is_active() or not NewFunc1(OldFunc3(self)) then
		return OldFunc3(self)
	end
	return NewFunc2(self)
end

local OldFunc4 = CrimeSpreeManager.server_active_modifiers
function CrimeSpreeManager:server_active_modifiers()
	if not NewFunc1(OldFunc4(self)) then
		return OldFunc4(self)
	end
	return NewFunc2(self)
end

local OldFunc5 = CrimeSpreeManager.modifiers_to_select
function CrimeSpreeManager:modifiers_to_select(table_name, add_repeating)
	if not add_repeating then
		return OldFunc5(self, table_name)
	end
	return 0
end

local OldFunc6 = CrimeSpreeManager._get_modifiers
function CrimeSpreeManager:_get_modifiers(table_name, max_count, add_repeating)
	return OldFunc6(self, table_name, max_count)
end
