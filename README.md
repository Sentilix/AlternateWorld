# Alternate World - Technical Overview (v0.5.1)

A decoupled modular logistics engine designed for World of Warcraft Classic Era. The addon tracks character data, bags, bank inventories, gold balances, and mail queues across multiple accounts, synchronizing everything through a shared SavedVariables database framework.

## Software Architecture & Module Routing

The addon is structured into independent micro-modules initialized strictly sequentially by the WoW client layout system via `AlternateWorld.toc`:

1. **`alternateconstants.lua`**: Global immutable registry. Houses color hex configurations, data structures, and database keys.
2. **`alternatecore.lua`**: Core database initialization layer. Instantiates the global `AlternateWorldDB` object and manages user settings structures.
3. **`alternatebankers.lua`**: Core backend data engine. Executes standard structural logic, cross-realm clustering, database updates, profiles, and deletion routines. Fully uncoupled from UI render paths.
4. **`alternatevirtualbankerui.lua`**: Independent fleet manager viewport layer. Controls UI rendering, layout anchoring, and object pooling for custom realms. Completely isolated from the legacy scanned banker code.
5. **`alternatebankersui.lua`**: Main Bankers configuration window layer. Manages item routing assignments and hierarchical dropdown matrix displays.
6. **`alternatenavigation.lua`**: Structural layout matrix router. Controls navigation sidebar tab toggles and coordinate-driven display swaps.
7. **`alternatemain.lua`**: UI Shell manager bootstrapper. Instantiates the primary core frame windows.

## Advanced Data & Security Implementations

* **Hierarchical Object Pooling**: Separate memory pools (`AW_VBRowsPool`, `AW_VBHeadersPool`, `ExportCheckboxesPool`, etc.) manage UI rows. This prevents memory leaks, widget duplication, and UI collision artifacts.
* **Hermetic Input Validation Shields**: Synchronized 2-way entry filters enforce strict constraints on user strings (Name letters: 2-12 chars; Realm characters: 4-24 chars). No multi-byte corruption leaks into the WTF environment.
* **ASCII Syntax Sanitization**: Escapes dynamic string tokens (e.g., control brackets `[]`, dynamic matching tags `%`, and quotation delimiters `""`). This eliminates risks of local SavedVariables serialization crashes.
* **Deterministic Layout Anchoring**: Uses absolute dynamically-scaled `TOPRIGHT` parent orientation locks paired with parent wrapper frame visibility watchers (`OnHide`). This ensures clean alignment margins (exactly 30px clear of native scrollbars) and prevents ghost dialogs.
