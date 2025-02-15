local base = "pure_skin_element"
DEFINE_BASECLASS(base)
HUDELEMENT.Base = base

if CLIENT then
    -- local GetLang = LANG.GetUnsafeLanguageTable
    local pad = 14 -- padding
    local lpw = 44 -- left panel width
    local sri_text_width_padding = 8 -- secondary role information padding (needed for size calculations)

    local const_defaults = {
        basepos = {
            x = 0,
            y = 0
        },
        size = {
            w = 365,
            h = 146 -- fix 4 for hud position
        },
        minsize = {
            w = 240,
            h = 146 -- fix 4 for hud postion
        }
    }

    function HUDELEMENT:Initialize()
        self.scale = 1.0
        self.basecolor = self:GetHUDBasecolor()
        self.pad = pad
        self.lpw = lpw
        self.sri_text_width_padding = sri_text_width_padding
        -- self.secondaryRoleInformationFunc = nil
        BaseClass.Initialize(self)
    end

    -- parameter overwrites
    function HUDELEMENT:IsResizable()
        return true, true
    end

    -- parameter overwrites end
    function HUDELEMENT:ShouldDraw()
        return LocalPlayer():IsGhost() and LocalPlayer():Alive() or HUDEditor.IsEditing
    end

    function HUDELEMENT:GetDefaults()
        const_defaults["basepos"] = {
            x = 10 * self.scale, -- fix 4 for hud postion
            y = ScrH() - (10 * self.scale + self.size.h)
        }

        return const_defaults
    end

    function HUDELEMENT:PerformLayout()
        local defaults = self:GetDefaults()
        self.basecolor = self:GetHUDBasecolor()
        self.scale = math.min(self.size.w / defaults.minsize.w, self.size.h / defaults.minsize.h)
        self.lpw = lpw * self.scale
        self.pad = pad * self.scale
        self.sri_text_width_padding = sri_text_width_padding * self.scale
        BaseClass.PerformLayout(self)
    end

    -- Returns player's ammo information
    function HUDELEMENT:GetAmmo(ply)
        local weap = ply:GetActiveWeapon()
        if not weap or not ply:Alive() then return -1 end
        local ammo_inv = weap.Ammo1 and weap:Ammo1() or 0
        local ammo_clip = weap:Clip1() or 0
        local ammo_max = weap.Primary.ClipSize or 0

        return ammo_clip, ammo_max, ammo_inv
    end

    --[[
		This function expects to receive a function as a parameter which later returns a table with the following keys: { text: "", color: Color }
		The function should also take care of managing the visibility by returning nil to tell the UI that nothing should be displayed
	]]
    --
    function HUDELEMENT:SetSecondaryRoleInfoFunction(func)
        if func and isfunction(func) then
            self.secondaryRoleInformationFunc = func
        end
    end

    local watching_icon = Material("vgui/ttt/watching_icon")

    --local credits_default = Material("vgui/ttt/equip/credits_default")
    --local credits_zero = Material("vgui/ttt/equip/credits_zero")
    function HUDELEMENT:Draw()
        local client = LocalPlayer()
        local cactiveGhost = client:IsGhost()
        -- local calive = client:Alive()
        -- local L = GetLang()
        local x2, y2, w2, h2 = self.pos.x, self.pos.y, self.size.w, self.size.h
        -- draw bg and shadow
        self:DrawBg(x2, y2, w2, h2, self.basecolor)
        -- draw left panel
        local c
        c = Color(100, 100, 100, 200)
        surface.SetDrawColor(clr(c))
        surface.DrawRect(x2, y2, self.lpw, h2)
        local ry = y2 + self.lpw * 0.5
        local ty = y2 + self.lpw + self.pad -- new y
        local nx = x2 + self.lpw + self.pad -- new x
        -- draw role icon
        local rd = client:GetSubRoleData()

        if rd then
            util.DrawFilteredTexturedRect(x2 + 4, y2 + 4, self.lpw - 8, self.lpw - 8, watching_icon)
            -- draw role string name
            local text

            if cactiveGhost then
                text = LANG.TryTranslation("ttt2_spectator_deathmatch_name")
            end

            -- calculate the scale multiplier for role text
            surface.SetFont("PureSkinRole")

            if cactiveGhost then
                local role_text_width = surface.GetTextSize(string.upper(text)) * self.scale
                local role_scale_multiplier = (self.size.w - self.lpw - 2 * self.pad) / role_text_width
                role_scale_multiplier = math.Clamp(role_scale_multiplier, 0.55, 0.85) * self.scale
                draw.AdvancedText(string.upper(text), "PureSkinRole", nx, ry, self:GetDefaultFontColor(self.basecolor), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, true, Vector(role_scale_multiplier * 0.9, role_scale_multiplier, role_scale_multiplier))
            end
        end

        -- player information
        if cactiveGhost then
            -- draw secondary role information
            -- draw dark bottom overlay
            surface.SetDrawColor(0, 0, 0, 90)
            surface.DrawRect(x2, y2 + self.lpw, w2, h2 - self.lpw)
            -- draw bars
            local bw = w2 - self.lpw - self.pad * 2 -- bar width
            local bh = 26 * self.scale -- bar height
            local sbh = 8 * self.scale -- spring bar height
            local spc = 7 * self.scale -- space between bars
            -- health bar
            local health = math.max(0, client:Health())
            self:DrawBar(nx, ty, bw, bh, Color(234, 41, 41), health / client:GetMaxHealth(), self.scale, string.upper(LANG.TryTranslation("hud_health")) .. ": " .. health)
            -- ammo bar
            ty = ty + bh + spc

            -- Draw ammo
            if client:GetActiveWeapon().Primary then
                local ammo_clip, ammo_max, ammo_inv = self:GetAmmo(client)

                if ammo_clip ~= -1 then
                    local text = string.format("%i + %02i", ammo_clip, ammo_inv)
                    self:DrawBar(nx, ty, bw, bh, Color(238, 151, 0), ammo_clip / ammo_max, self.scale, text)
                end
            end

            local color_sprint = Color(36, 154, 198) -- fix 4 for sprint bar
            ty = ty + bh + spc

            -- fix 4 for sprint bar
            if GetGlobalBool("ttt2_sprint_enabled", true) then
                self:DrawBar(nx, ty, bw, sbh, color_sprint, client.sprintProgress, t_scale, "")
            end
        end

        -- draw lines around the element
        self:DrawLines(x2, y2, w2, h2, self.basecolor.a)
    end
end
