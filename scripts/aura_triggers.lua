--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals bDebug bDebugPerformance tokenMovement getExtensions AuraEffectTriggers
-- luacheck: globals updateAurasForMap updateAurasForActor updateAurasForEffect addEffect_new
-- luacheck: globals updateAurasForTurnStart AuraEffect.clearOncePerTurn AuraTracker AuraToken
-- luacheck: globals AuraFactionConditional.DetectedEffectManager.parseEffectComp hasExtension
-- luacheck: globals linkToken_new onTokenDelete_new initTracker onTabletopInit onHeathUpdate

bDebug = false
bDebugPerformance = false
local tExtensions = {}

-- Trigger AURA effect calculation on supplied effect node.
function updateAurasForEffect(nodeEffect, rMoved)
	if type(nodeEffect) ~= 'databasenode' then
		return
	end -- sometimes userdata shows up here when used with BCE
	local rAuraDetails = AuraEffect.getAuraDetails(nodeEffect)
	if rAuraDetails.nRange == 0 then
		return
	end -- 0 means no valid aura found
	local tokenSource = CombatManager.getTokenFromCT(DB.findNode(rAuraDetails.sSource))
	AuraEffect.updateAura(tokenSource, nodeEffect, rAuraDetails, rMoved)
end

-- Trigger AURA effect calculation on all effects in a supplied CT node.
-- If supplied with windowFilter instance, abort if actor's map doesn't match
-- If supplied with effectFilter node, skip that effect
function updateAurasForActor(nodeCT, windowFilter, effectFilter, rMoved)
	if windowFilter then -- if windowFilter is provided, save winImage to filterImage
		local _, winImage, _ = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCT))
		if winImage ~= windowFilter then
			return
		end -- if filterImage is set and doesn't match, abort
	end
	local aEffectList
	if rMoved then
		aEffectList = AuraTracker.getAuraEffects(nodeCT)
	else
		aEffectList = DB.getChildList(nodeCT, 'effects')
	end
	for _, nodeEffect in ipairs(aEffectList) do
		if not effectFilter and nodeEffect ~= effectFilter then
			AuraEffectTriggers.updateAurasForEffect(nodeEffect, rMoved)
		end
	end
end

-- Calls updateAurasForActor on each CT node whose token is on the same image supplied as 'window'
function updateAurasForMap(window, rMoved)
	if not window or not StringManager.contains({ 'imagepanelwindow', 'imagewindow' }, window.getClass()) then
		return
	end

	-- If we have a node that has moved (nodeCTMoved), use the aura tracker else we haven't initialized the tracker yet
	-- so do the inefficient way (when a map is opened).
	if rMoved then
		local aAuras = AuraTracker.getAllTrackedAuras()
		for sSourceNode, _ in pairs(aAuras) do
			local nodeCT = DB.findNode(sSourceNode)
			local _, winImage = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCT))
			if winImage == window then
				AuraEffectTriggers.updateAurasForActor(nodeCT, winImage, nil, rMoved)
			end
		end
		return
	end

	for _, nodeCT in ipairs(DB.getChildList(CombatManager.CT_LIST)) do
		local _, winImage = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCT))
		if winImage == window then
			AuraEffectTriggers.updateAurasForActor(nodeCT, winImage)
		end
	end
end

--SINGLE aura type to update on turn start
function updateAurasForTurnStart(nodeCTStart)
	AuraTracker.clearOncePerTurn()
	local _, window = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCTStart))
	local aAuras = AuraTracker.getAllTrackedAuras()
	local rNodeStart = ActorManager.resolveActor(nodeCTStart)

	for sSourceNode, _ in pairs(aAuras) do
		local nodeCT = DB.findNode(sSourceNode)
		local _, winImage = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCT))
		if winImage == window then
			AuraEffectTriggers.updateAurasForActor(nodeCT, winImage, nil, rNodeStart)
		end
	end
end

local sTime = ''
function tokenMovement(token)
	local time1 = nil
	if not token or Input.isShiftPressed() then
		return
	end
	if bDebugPerformance then
		time1 = os.clock()
	end

	local nodeCT = CombatManager.getCTFromToken(token)
	local rNodeStart = ActorManager.resolveActor(nodeCT)
	if not rNodeStart then
		return
	end

	if AuraToken.isMovedFilter(rNodeStart.sCTNode, token) then
		local _, winImage = ImageManager.getImageControl(token)
		AuraEffectTriggers.updateAurasForMap(winImage, rNodeStart)
		if bDebugPerformance then
			sTime = string.format('%s%s,', sTime, tostring(os.clock() - time1))
			Debug.console(sTime)
		end
	end
end

local function onMove(token)
	AuraEffectTriggers.tokenMovement(token)
end

local linkToken_old
local function linkToken_new(nodeCT, newTokenInstance)
	linkToken_old(nodeCT, newTokenInstance)
	local _, winImage = ImageManager.getImageControl(newTokenInstance)
	AuraEffectTriggers.updateAurasForMap(winImage)
end

local onTokenDelete_old
local function onTokenDelete_new(token)
	local nodeCT = CombatManager.getCTFromToken(token)
	local aEffectList = DB.getChildList(nodeCT, 'effects')
	for _, nodeEffect in ipairs(aEffectList) do
		AuraEffect.removeAllFromAuras(nodeEffect)
	end
	onTokenDelete_old(token)
end

-- Recalculate auras when opening images
local onWindowOpened_old
local function onWindowOpened_new(window, ...)
	if onWindowOpened_old then
		onWindowOpened_old(window, ...)
	end
	AuraEffectTriggers.updateAurasForMap(window)
end

-- Recalculate auras when adding tokens
local handleStandardCombatAddPlacement_old
local function handleStandardCombatAddPlacement_new(tCustom, ...)
	if handleStandardCombatAddPlacement_old then
		handleStandardCombatAddPlacement_old(tCustom, ...)
	end
	AuraEffectTriggers.updateAurasForActor(tCustom.nodeCT)
end

---	Recalculate auras when effect text is changed to facilitate conditionals before aura effects
local function onEffectChanged(nodeLabel)
	if not nodeLabel or type(nodeLabel) ~= 'databasenode' then
		return
	end
	local nodeEffect = DB.getParent(nodeLabel)
	local sEffect = DB.getValue(nodeEffect, 'label', '')
	if string.match(sEffect, 'AURA[:;]') then
		local sNode = DB.getPath(DB.getChild(nodeEffect, '...'))
		local sAuraEffect = DB.getPath(nodeEffect)
		AuraTracker.removeTrackedFromAura(sNode, sAuraEffect) -- Effect changed
		AuraTracker.addTrackedAura(sNode, sAuraEffect) -- Effect changed to no AURA and then back to AURA
	else
		AuraTracker.removeTrackedAura(DB.getPath(DB.getChild(nodeEffect, '...')), DB.getPath(nodeEffect))
	end

	if sEffect == '' or string.match(sEffect, 'AURA[:;]') then
		return
	end -- don't recalculate when changing aura or fromaura
	AuraEffectTriggers.updateAurasForActor(DB.getChild(nodeEffect, '...'))
end

---	Remove fromaura effects just before source aura is removed
local function onEffectToBeRemoved(nodeEffect)
	if not nodeEffect or type(nodeEffect) ~= 'databasenode' then
		return
	end
	local sEffect = DB.getValue(nodeEffect, 'label', '')
	if not string.find(sEffect, AuraEffect.auraString) then
		return
	end
	for _, sEffectComp in ipairs(EffectManager.parseEffect(sEffect)) do
		local rEffectComp = AuraFactionConditional.DetectedEffectManager.parseEffectComp(sEffectComp)
		if rEffectComp.type:upper() == 'AURA' then
			local bSticky = false
			for _, sFilter in ipairs(rEffectComp.remainder) do
				if sFilter:lower() == 'sticky' then
					bSticky = true
					break
				end
			end
			if not bSticky then
				AuraEffect.removeAllFromAuras(nodeEffect)
			end
			AuraTracker.removeTrackedAura(DB.getPath(DB.getChild(nodeEffect, '...')), DB.getPath(nodeEffect))
			break
		end
	end
end

local addEffect_old
function addEffect_new(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg)
	addEffect_old(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg)
	if AuraFactionConditional.DetectedEffectManager.parseEffectComp then
		for _, sEffectComp in ipairs(EffectManager.parseEffect(rNewEffect.sName)) do
			local rEffectComp = AuraFactionConditional.DetectedEffectManager.parseEffectComp(sEffectComp)
			if rEffectComp.type:upper() == 'AURA' then
				local _, winImage = ImageManager.getImageControl(CombatManager.getTokenFromCT(nodeCT))
				local rNodeStart = ActorManager.resolveActor(nodeCT)
				AuraEffectTriggers.updateAurasForMap(winImage, rNodeStart)
				break
			end
		end
	end
end

function initTracker()
	local ctEntries = CombatManager.getCombatantNodes()
	for _, nodeCT in pairs(ctEntries) do
		local bUpdate = false
		-- Effects
		for _, nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
			local sEffect = DB.getValue(nodeEffect, 'label', '')
			if string.match(sEffect, 'AURA[:;]') then
				local sAuraEffect = DB.getPath(nodeEffect)
				AuraTracker.addTrackedAura(nodeCT, sAuraEffect)
				bUpdate = true
			end
		end
		if bUpdate then
			AuraEffectTriggers.updateAurasForActor(nodeCT)
		end
	end
end

function getExtensions()
	local tReturn = {}
	for _, sName in pairs(Extension.getExtensions()) do
		tReturn[sName] = Extension.getExtensionInfo(sName)
	end
	return tReturn
end

-- Matches on the filname minus the .ext or on the name in defined in the extension.xml
function hasExtension(sName)
	local bReturn = false

	if tExtensions[sName] then
		bReturn = true
	else
		for _, tExtension in pairs(tExtensions) do
			if tExtension.name == sName then
				bReturn = true
				break
			end
		end
	end
	return bReturn
end

---	Recalculate auras after effects are removed to ensure conditionals before aura are respected
local function onEffectRemoved(nodeEffects)
	if not nodeEffects or type(nodeEffects) ~= 'databasenode' then
		return
	end
	AuraEffectTriggers.updateAurasForActor(DB.getParent(nodeEffects))
end

function onTabletopInit()
	if Session.IsHost then
		AuraEffectTriggers.initTracker()
	end
end

local function onHealthUpdate(nodeHP)
	if not nodeHP or type(nodeHP) ~= 'databasenode' then
		return
	end
	local nodeActor = DB.getParent(nodeHP)
	local _, window = ImageManager.getImageControl(CombatManager.getTokenFromCT(DB.getParent(nodeHP)))

	AuraEffectTriggers.updateAurasForActor(nodeActor, window)
end

function onInit()
	tExtensions = AuraEffectTriggers.getExtensions()
	-- all handlers should be created on GM machine
	if not Session.IsHost then
		return
	end
	DB.addHandler(DB.getPath(CombatManager.CT_LIST .. '.*.effects.*.label'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(CombatManager.CT_LIST .. '.*.effects.*.isactive'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(CombatManager.CT_LIST .. '.*.effects.*'), 'onDelete', onEffectToBeRemoved)
	DB.addHandler(DB.getPath(CombatManager.CT_LIST .. '.*.effects'), 'onChildDeleted', onEffectRemoved)
	DB.addHandler(DB.getPath(CombatManager.CT_LIST .. '.*.wounds'), 'onUpdate', onHealthUpdate)

	-- create the proxy function to trigger aura calculation on token movement.
	Token.addEventHandler('onMove', onMove)

	-- Handle add/delete of tokens
	onTokenDelete_old = CombatManager.onTokenDelete
	CombatManager.onTokenDelete = onTokenDelete_new

	linkToken_old = TokenManager.linkToken
	TokenManager.linkToken = linkToken_new

	-- create proxy function to recalculate auras when adding tokens
	handleStandardCombatAddPlacement_old = CombatRecordManager.handleStandardCombatAddPlacement
	CombatRecordManager.handleStandardCombatAddPlacement = handleStandardCombatAddPlacement_new

	-- create proxy function to recalculate auras when new windows are opened
	onWindowOpened_old = Interface.onWindowOpened
	Interface.onWindowOpened = onWindowOpened_new

	CombatManager.setCustomTurnStart(updateAurasForTurnStart)

	addEffect_old = EffectManager.addEffect
	EffectManager.addEffect = addEffect_new
end
