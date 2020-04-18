if SERVER then
	local function AutoReplicateConVar(name, data)
		local cv = GetConVar(name)

		if not cv then return end

		local cv_value

		if data.slider and not data.decimal then
			cv_value = cv:GetInt()
		elseif data.slider then
			cv_value = cv:GetFloat()
		elseif data.checkbox then
			cv_value = cv:GetBool()
		else
			cv_value = cv:GetString()
		end

		ULib.replicatedWritableCvar(
			name,
			"rep_" .. name,
			cv_value,
			true,
			true,
			"xgui_gmsettings"
		)
	end

	local ttt2_minigames = CreateConVar("ttt2_minigames", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	local ttt2_minigames_autostart = CreateConVar("ttt2_minigames_autostart", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})

	-- ConVar Replicating
	hook.Add("TTTUlxInitCustomCVar", "TTT2MGInitRWCVar", function()
		ULib.replicatedWritableCvar(ttt2_minigames:GetName(), "rep_" .. ttt2_minigames:GetName(), ttt2_minigames:GetBool(), true, true, "xgui_gmsettings")
		ULib.replicatedWritableCvar(ttt2_minigames_autostart:GetName(), "rep_" .. ttt2_minigames_autostart:GetName(), ttt2_minigames_autostart:GetInt(), true, true, "xgui_gmsettings")

		---- minigames dynamical ConVars
		local mgs = minigames.GetList()

		for i = 1, #mgs do
			local mg = mgs[i]
			local cvd = mg.conVarData

			if not istable(cvd) or table.Count(cvd) < 1 then continue end

			for name, data in pairs(cvd) do
				AutoReplicateConVar(name, data)
			end
		end
	end)
else
	CreateConVar("ttt2_minigames_show_popup", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})

	hook.Add("TTTUlxModifyAddonSettings", "TTT2MGModifySettings", function(settingsName)
		local pnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

		local clp = vgui.Create("DCollapsibleCategory", pnl)
		clp:SetSize(390, 150)
		clp:SetExpanded(1)
		clp:SetLabel("Basic Settings")

		local lst = vgui.Create("DPanelList", clp)
		lst:SetPos(5, 25)
		lst:SetSize(390, 150)
		lst:SetSpacing(5)

		lst:AddItem(xlib.makelabel{
			x = 0,
			y = 0,
			w = 415,
			wordwrap = true,
			label = "Disabling TTT2 Minigames disables the functionality of any add-on that depends on it.",
			parent = lst
		})

		lst:AddItem(xlib.makecheckbox{
			label = "Enable TTT2 Minigames? (ttt2_minigames) (Def. 1)",
			repconvar = "rep_ttt2_minigames",
			parent = lst
		})

		lst:AddItem(xlib.makelabel{ -- empty line
			x = 0,
			y = 0,
			w = 415,
			wordwrap = true,
			label = "",
			parent = lst
		})

		lst:AddItem(xlib.makelabel{
			x = 0,
			y = 0,
			w = 415,
			wordwrap = true,
			label = "Enabling TTT2 Minigames autostart will lead to the result that a random minigame is activated on every round start.",
			parent = lst
		})

		lst:AddItem(xlib.makecheckbox{
			label = "Enable TTT2 Minigames autostart? (ttt2_minigames_autostart) (Def. 1)",
			repconvar = "rep_ttt2_minigames_autostart",
			parent = lst
		})

		---- minigames dynamical ConVars
		local mgs = minigames.GetList()
		local b = true

		for i = 1, #mgs do
			local mg = mgs[i]
			local cvd = mg.conVarData

			if not istable(cvd) or table.Count(cvd) < 1 then continue end

			local size = 0

			for _, data in pairs(cvd) do
				if data.slider then
					size = size + 25
				end

				if data.checkbox then
					size = size + 20
				end

				if data.combobox then
					size = size + 30

					if data.desc then
						size = size + 13
					end
				end

				if data.label then
					size = size + 13
				end
			end

			clp = vgui.Create("DCollapsibleCategory", pnl)
			clp:SetSize(390, size)
			clp:SetExpanded(b and 1 or 0)
			clp:SetLabel(LANG.TryTranslation("ttt2_minigames_" .. mg.name .. "_name"))

			b = false

			lst = vgui.Create("DPanelList", clp)
			lst:SetPos(5, 25)
			lst:SetSize(390, size)
			lst:SetSpacing(5)

			for name, data in pairs(cvd) do
				if data.checkbox then
					lst:AddItem(xlib.makecheckbox{
						label = name .. ": " .. (data.desc or ""),
						repconvar = "rep_" .. name,
						parent = lst
					})
				elseif data.slider then
					lst:AddItem(xlib.makeslider{
						label = name .. ": " .. (data.desc or ""),
						min = data.min or 1,
						max = data.max or 1000,
						decimal = data.decimal or 0,
						repconvar = "rep_" .. name,
						parent = lst
					})
				elseif data.combobox then
					if data.desc then
						lst:AddItem(xlib.makelabel{
							label = name .. ": " .. (data.desc or ""),
							parent = lst
						})
					end

					lst:AddItem(xlib.makecombobox{
						enableinput = data.enableinput or false,
						choices = data.choices,
						isNumberConvar = true,
						repconvar = "rep_" .. name,
						numOffset = (-1) * (data.numStart or 0) + 1,
						parent = lst
					})
				elseif data.label then
					lst:AddItem(xlib.makelabel{
						label = data.desc or "",
						parent = lst
					})
				end
			end
		end

		xgui.hookEvent("onProcessModules", nil, pnl.processModules)
		xgui.addSubModule("TTT2 Minigames", pnl, nil, settingsName)
	end)
end
