-- ============================================================================
-- Alternate World - Server Clusters Core Constants & Dialogs Engine (v0.4.0)
-- ============================================================================

AlternateWorldClusterConstants = {}

AlternateWorldClusterConstants.Assets = {
    ["cluster_1"] = { name = "Cluster 1", icon = "interface\\icons\\inv_jewelcrafting_gem_04" },
    ["cluster_2"] = { name = "Cluster 2", icon = "interface\\icons\\inv_jewelcrafting_gem_02" },
    ["cluster_3"] = { name = "Cluster 3", icon = "interface\\icons\\inv_jewelcrafting_gem_03" },
    ["cluster_4"] = { name = "Cluster 4", icon = "interface\\icons\\inv_jewelcrafting_gem_01" },
    ["cluster_5"] = { name = "Cluster 5", icon = "interface\\icons\\inv_jewelcrafting_gem_05" }
}

StaticPopupDialogs["AW_RENAME_CLUSTER_PROMPT"] = {
    text = "Enter new name for %s (Max 20 characters):",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 20,
    OnShow = function(self, data)
        -- FIXED ERA API: Changed 'editBox' to 'EditBox' to align with native Vanilla metadata structures
        if data and AlternateWorldDB.Settings.ClusterNames[data] then
            self.EditBox:SetText(AlternateWorldDB.Settings.ClusterNames[data])
            self.EditBox:HighlightText()
        end
    end,
    OnAccept = function(self, data)
        -- FIXED ERA API: Enforced capital 'EditBox' reference for strict Era compatibility
        local text = self.EditBox:GetText()
        if text and string.gsub(text, "%s+", "") ~= "" and data then
            AlternateWorldDB.Settings.ClusterNames[data] = text
            if AlternateWorldClustersView and AlternateWorldClustersView.RefreshClusterView then
                AlternateWorldClustersView.RefreshClusterView()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["AW_RENAME_CLUSTER_PROMPT"] = {
    text = "Enter new name for %s (Max 20 characters):",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 20,
    OnAccept = function(self, data)
        local text = self.EditBox:GetText()
        if text and string.gsub(text, "%s+", "") ~= "" and data then
            AlternateWorldDB.Settings.ClusterNames[data] = text
            if AlternateWorldClustersView and AlternateWorldClustersView.RefreshClusterView then
                AlternateWorldClustersView.RefreshClusterView()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- End of [alternateclusterconstants.lua]
