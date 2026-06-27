# Alternate World - Changelog

## [v0.5.1] - 2026-06-27
### Added
- Hierarchical text formatting matrix to category dropdowns on the main panel.
- Three-space horizontal layout indentation for character row items in dropdown selections.
- Intermittent white blank row separators between realm category lists to improve spacing contrast.
- Solid background canvas textures (`WHITE8X` overlay buffers) on popup frames to block out underlying text bleed.
- `OnHide` monitoring triggers on dynamic sub-panels to force absolute automatic closures.
### Changed
- Converted all legacy `SOUNDKIT` global object paths to stable native numeric sound aliases (`830`, `841`, `856`, `846`).
- Optimized `InitializeCategoryDropdown` routines to render large, clean white server headers.
### Fixed
- Fixed local scope block crashes where table arrays returned `nil` states on dedicated single-realm setups.
- Eliminated legacy server-string text extensions (e.g., `-mir`, `-net`) inside option rows.
- Re-enforced proper class token overrides on Virtual profiles to prevent them from misrendering as white Priests.

## [v0.5.0] - 2026-06-26
### Added
- Created the dedicated Virtual Bankers layout manager system under an independent navigation tab.
- Integrated cross-account Profile Exporter and Importer serialization text tools.
- Deployed strict alphanumeric filter locks (Letters only for name strings; escaped hyphens and apostrophes for realms).
- Re-anchored dynamic frame pools directly to absolute `TOPRIGHT` parent nodes to enforce clear scrollbar clearances.
### Changed
- Re-architected code structure by splitting core systems into 7 decoupled sequential boot modules.
- Migrated Virtual Banker registration components fully out of the main `alternatebankersui.lua` workspace.
### Fixed
- Pulverized object memory collision crashes by implementing distinct line and header memory pools (`AW_VBRowsPool`, `AW_VBHeadersPool`).
- Closed critical injection vulnerability loopholes on the Edit window dialog system.
- Corrected initialization execution paths by re-ordering internal `.toc` load assignments.

## [v0.4.2] - 2026-06-15
### Fixed
- Resolved alignment shifts on main text labels within custom UI frames.
- Repaired a font-rendering glitch affecting non-standard screen scales.

## [v0.4.1] - 2026-06-02
### Changed
- Standardized localized naming metrics across global data array structures.
- Fine-tuned texture coordinates for default character class icon borders.

## [v0.4.0] - 2026-05-20
### Added
- Implemented strict hierarchical flow routing for dropdown populates.
- Enforced Single-Realm Isolation Mode rulesets to restrict floodgates to unassigned local realms.

## [v0.3.0] - 2026-04-12
### Added
- Deployed the Multi-Realm Cluster routing configuration interface parameters.
### Changed
- Optimized the core scanning engine to handle multiple connected realm families seamlessly.

## [v0.2.0] - Legacy Baseline
### Added
- Implemented core character scan log mechanisms for local gold, level tracking, resting states, bags, and bank windows.
- Created multi-tab selection layouts interface frameworks.

## [v0.1.0] - Initial Prototype
### Added
- Initial proof-of-concept logistics engine tracking local character data parameters.
