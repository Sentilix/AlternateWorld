# Alternate World - Changelog

## [v0.6.1] - 2026-06-29
### Added
* **Scarlet Monastery**: Added Scarlet Monastery tracking with proper icon and name to the dungeon grid.

### Changed
* **Crafter Wordwrap**: Increased right layout margin layout boundary to 80px to clear the professions scrollbar clearance.
* **Keyring Scanning**: Re-engineered item loops to scan the Era keyring container once per snapshot pass via an initialization cache to prevent event-storm overhead.

### Fixed
* **Virtual Dropdown Isolation**: (Bug): Virtual profiles leaked into the main character selection dropdown - fixed by adding a contextual `allowVirtual` parameter.
* **Red X Frame Sync**: (Bug): Closing the addon via the red close button caused double-click requirements and black display sheets upon next load - fixed via atomic `OnHide` watchdog frame sync hooks.
* **Attunement Case-Sensitivity**: (Bug): Raid attunements went blank after a reload due to case-sensitive text key mismatches against `DATA_KEY_MAP` - fixed.
* **Gold Scraper Eviction**: (Bug): Personal gold and item level wiped to 0 when switching tabs due to missing `money` parameters in the live snapshot returns - fixed via `GetMoney()` API integration.
* **Gnomeregan Key ID**: (Bug): Workshop Key used an incorrect item ID - corrected to `6893` to match the true Era keyring registry.
* **Dungeon Icon Texture**: (Bug): Key icons for Scarlet, BRD, and Stratholme misrendered - updated to their true classic artwork strings (`_01`, `_08`, `_13`).


## [v0.6.0] - 2026-06-28
## Added
* **Minimap Icon**: Yellow Human Female icon added to border (draggable).
* **Titan Panel**: Added LibDataBroker support for top bar tracking.
* **Addon Options**: Created config page under Esc -> Options -> AddOns.

## Changed
* **Minimap Toggle**: Added "Show Minimap Icon" checkbox (updates live).
* **Sidebar Sorting**: Reordered Rested XP, History Log, and Professions into a leveling block.

## Fixed
* **Bag & Bank Isolation**: Bag items leaked into Bank layout slots - fixed.
* **Banker Suffix Dropdown**: Suffix (-Net, -Mir, -Fir) cleared upon dropdown click - fixed.
* **Zone & Flight Wipe**: Character tabs blanked out during zone loads or flights - fixed via `AWCachedCharacterKey`.
* **Favorite Star Reload**: Toggle state wiped on reload due to `isFavorite` spelling mismatch - fixed.
* **History Linebreaks**: Long history logs extended horizontally past canvas margins - fixed via autowrap.
* **Escape & Spell Errors**: Insecure UI close lines broke the Escape key target and caused BugSack errors - fixed.


## [v0.5.1] - 2026-06-27
### Added
* **Dropdown Formatting**: Character rows indented with 3 spaces under server headers.
* **Dropdown Spacers**: Added blank spacing rows between different realm lists.
* **Popup Text Bleed**: Added solid background textures to block background text bleed.
* **Auto-closure**: Added OnHide triggers to force sub-panels to close automatically.

### Changed
* **Soundkit IDs**: Converted legacy sound paths to native numeric IDs (830, 841, 856, 846).

### Fixed
* **Single-realm Crash**: Fixed crashes where empty tables returned nil on single-realm setups.
* **Row Server Strings**: Cleaned up server-string extensions (-mir, -net) inside rows.
* **Virtual Class Colors**: Fixed virtual profiles misrendering as white Priests.


## [v0.5.0] - 2026-06-26
### Added
* **Virtual Bankers**: Added virtual bankers system under a new navigation tab.
* **Profile Sync**: Added cross-account exporter and importer text tools.
* **Input Filters**: Restricted names to letters only, with allowed hyphens/apostrophes for realms.
* **Scrollbar Alignment**: Re-anchored frames to TOPRIGHT to clear scrollbar paths.

### Changed
* **Module Split**: Re-architected code from single files into 7 decoupled boot modules.

### Fixed
* **Memory Collisions**: Fixed pool crashes by separating row and header pools.
* **Edit Box Injection**: Closed critical input vulnerability loopholes on edit dialogs.
* **TOC Loading**: Corrected initialization order by rewriting internal .toc load paths.


## [v0.4.2] - 2026-06-15
### Fixed
* **Label Shifts**: Fixed alignment shifts on main text labels.
* **Font Scaling**: Repaired font-rendering glitches on non-standard screen scales.


## [v0.4.1] - 2026-06-02
### Changed
* **Naming Standardization**: Localized naming metrics standardized across global arrays.
* **Class Icon Borders**: Fine-tuned texture coordinates for character class borders.


## [v0.4.0] - 2026-05-20
### Added
* **Dropdown Flow**: Implemented structural flow routing for dropdown populations.
* **Realm Isolation**: Enforced Single-Realm Isolation rules to restrict views to local realms.


## [v0.3.0] - 2026-04-12
### Added
* **Multi-Realm Clusters**: Added routing configurations for connected realm families.

### Changed
* **Scanner Optimization**: Optimized scanning engine to handle multiple connected servers.


## [v0.2.0] - Legacy Baseline
### Added
* **Core Scanner**: Added tracking for local gold, level, resting state, bags, and bank windows.
* **Multi-Tab Dashboard**: Created multi-tab selection interface frame layers.


## [v0.1.0] - Initial Prototype
### Added
* **Proof of Concept**: Initial prototype engine tracking local character variables.
