-- ============================================================================
-- Alternate World - Character Profile View UI Module Panel (v0.3.0)
-- ============================================================================

AlternateWorldCharacterView = {}

local CharacterPanel = nil
local ElementsRegistry = {}
local ProfLineFramesPool = {}

function AlternateWorldCharacterView.CreatePanel(parentWindow)
    if CharacterPanel then return CharacterPanel end

    CharacterPanel = CreateFrame("Frame", "AWCharacterPanelGlobal", parentWindow)
    CharacterPanel:SetAllPoints(parentWindow)
    CharacterPanel:Hide()

    ElementsRegistry.Panel = CharacterPanel

    ElementsRegistry.MainTitleText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ElementsRegistry.MainTitleText:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -10)
    ElementsRegistry.MainTitleText:SetText("|cFFFFFFFFCharacter Profile Overview|r")

    ElementsRegistry.LastUpdateText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ElementsRegistry.LastUpdateText:SetPoint("TOPLEFT", ElementsRegistry.MainTitleText, "BOTTOMLEFT", 0, -2)

    ElementsRegistry.DefaultPortrait2D = CharacterPanel:CreateTexture(nil, "OVERLAY")
    ElementsRegistry.DefaultPortrait2D:SetSize(50, 50)
    ElementsRegistry.DefaultPortrait2D:SetPoint("TOPLEFT", ElementsRegistry.LastUpdateText, "BOTTOMLEFT", 0, -10)

    ElementsRegistry.DetailLine1 = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ElementsRegistry.DetailLine1:SetPoint("TOPLEFT", ElementsRegistry.DefaultPortrait2D, "TOPRIGHT", 15, -2)
    ElementsRegistry.DetailLine1:SetJustifyH("LEFT")

    ElementsRegistry.ClassIconTexture = CharacterPanel:CreateTexture(nil, "OVERLAY")
    ElementsRegistry.ClassIconTexture:SetSize(14, 14)
    ElementsRegistry.ClassIconTexture:SetPoint("TOPLEFT", ElementsRegistry.DetailLine1, "BOTTOMLEFT", 0, -4)
    ElementsRegistry.ClassIconTexture:Hide()

    ElementsRegistry.DetailLine2 = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ElementsRegistry.DetailLine2:SetPoint("LEFT", ElementsRegistry.ClassIconTexture, "RIGHT", 5, 0)
    ElementsRegistry.DetailLine2:SetJustifyH("LEFT")

    ElementsRegistry.SpecIconTexture = CharacterPanel:CreateTexture(nil, "OVERLAY")
    ElementsRegistry.SpecIconTexture:SetSize(14, 14)
    ElementsRegistry.SpecIconTexture:SetPoint("TOPLEFT", ElementsRegistry.ClassIconTexture, "BOTTOMLEFT", 0, -5)
    ElementsRegistry.ClassIconTexture:Hide()

    ElementsRegistry.SpecTextString = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ElementsRegistry.SpecTextString:SetPoint("LEFT", ElementsRegistry.SpecIconTexture, "RIGHT", 6, 0)
    ElementsRegistry.SpecTextString:SetJustifyH("LEFT")

    ElementsRegistry.InfoTextLeft = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ElementsRegistry.InfoTextLeft:SetPoint("TOPLEFT", ElementsRegistry.DefaultPortrait2D, "BOTTOMLEFT", 0, -32)
    ElementsRegistry.InfoTextLeft:SetJustifyH("LEFT")

    ElementsRegistry.AccountTotalsLeft = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ElementsRegistry.AccountTotalsLeft:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -255)
    ElementsRegistry.AccountTotalsLeft:SetJustifyH("LEFT")

    ElementsRegistry.AccountTotalsRight = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ElementsRegistry.AccountTotalsRight:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 220, -255)
    ElementsRegistry.AccountTotalsRight:SetJustifyH("LEFT")

    ElementsRegistry.DeleteCharButton = CreateFrame("Button", "AW_DeleteCharacterProfileButton", CharacterPanel, "UIPanelButtonTemplate")
    ElementsRegistry.DeleteCharButton:SetSize(110, 22)
    ElementsRegistry.DeleteCharButton:SetPoint("BOTTOMRIGHT", CharacterPanel, "BOTTOMRIGHT", -25, 15)
    ElementsRegistry.DeleteCharButton:SetText("Delete Profile")

    -- FIXED TEXT: Unified naming convention from 'remove' to 'delete' to align seamlessly with the UI button text
    StaticPopupDialogs["AW_CONFIRM_DELETE_PROFILE"] = {
        text = "Are you sure you want to delete this profile?",
        button1 = "Yes", button2 = "No",
        OnAccept = function(self, data)
            if AlternateWorldDB and data.targetKey then
                AlternateWorldDB[data.targetKey] = nil
                PlaySound(830)
                if AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.OnAddonLoaded then
                    AlternateWorldMainFrameEngine.OnAddonLoaded()
                end
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3
    }

    return CharacterPanel
end

function AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    if not CharacterPanel or not selectedCharacterKey then return end
    CharacterPanel:Show()
    if AlternateWorldCharacterEngine and AlternateWorldCharacterEngine.ProcessShowData then
        AlternateWorldCharacterEngine.ProcessShowData(selectedCharacterKey, ElementsRegistry, ProfLineFramesPool)
    end
end

function AlternateWorldCharacterView.HidePanel() if CharacterPanel then CharacterPanel:Hide() end end
function AlternateWorldCharacterView.IsShown() return CharacterPanel and CharacterPanel:IsShown() end

-- End of [alternatecharacterui.lua]
