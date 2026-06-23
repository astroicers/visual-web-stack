# Changelog

本專案的所有重大變更記錄於此。格式依循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/)。

## [1.0.1] - 2026-06-23

### Added

- README 快速上手（5 分鐘）+ 術語速查（R3F / Lenis / ScrollTrigger / three-layer / state-bridge）。
- README 姊妹 skill 連結（talk-craft / slidev-deck-stack，同一條工具鏈）。
- `SKILL.md` 邊界段（不做什麼 / 何時別用、快照會過期、「貼 SKILL.md 即用」誠實底線、cross-runtime 未實測標註）。
- README 方法 D：`npx skills` / `gh skill` 安裝法（跨 agent 開放安裝器，對齊 agent-skills 規範）。

### Changed

- `SKILL.md`「與…的關係」段點名姊妹 talk-craft / slidev-deck-stack（原本只提 ASP），補上家族定位。

## [1.0.0] - 2026-06-15

首個正式版。視覺系網站技術棧的 Claude Code skill / plugin。

### Added

- 四層架構（UI / 3D / Scroll / State）+ 8 條鐵則的 `SKILL.md` 核心規範。
- 7 份 references 實作配方：`setup`、`scroll-system`、`three-layer`、`animation-recipes`、`state-bridge`、`ui-theming`、`pitfalls`。
- Claude Code marketplace 支援：`.claude-plugin/marketplace.json` + `plugin.json`，可直接從 Manage Plugins → Marketplaces 加入安裝。
- `install.sh` 安裝腳本與手動 symlink 安裝法。
- `.asp-fact-check.md` 第三方套件 API/版本查證紀錄。

### Changed

- 技術基準由 React 18 改為 **React 19**（對齊實際使用情境），3D 鏈同步為 fiber@9 → drei@10 → postprocessing@3 → three 0.159+；React 18 保留為相容備援。
- `postprocessing` 範例註解更新至 v3 型別行為（`ChromaticAberration` props 不再強制必填）。

### Fixed

- 推版前 review 修復 20 條 confirmed findings。
- README 安裝段缺少 marketplace 安裝法、`plugin.json`/`marketplace.json` 缺 `version`/`license` 等規範欄位。

[1.0.0]: https://github.com/astroicers/visual-web-stack/releases/tag/v1.0.0
