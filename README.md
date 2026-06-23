# visual-web-stack

視覺系網站技術棧的 Claude Code skill——把跨套件整合的踩坑知識固化，讓第一版
scaffold 就符合架構規範。

涵蓋技術棧：React 19 + Vite + TypeScript + Tailwind CSS + Radix UI +
React Three Fiber + Drei + @react-three/postprocessing + Anime.js + Motion +
GSAP ScrollTrigger + Lenis + Zustand + Leva + next-themes。
（React 18 為相容備援，見「套件版本對照表」。）

> **姊妹 skill（同一條工具鏈）**：[`talk-craft`](https://github.com/astroicers/talk-craft)（簡報內容 / 敘事）、
> [`slidev-deck-stack`](https://github.com/astroicers/slidev-deck-stack)（Slidev 簡報視覺）。三者都是知識層
> skill、各管一個領域，可同專案併用。

## 快速上手（5 分鐘）

React + Three.js + GSAP + Lenis 一堆套件兜在一起，觸發點漂移、Dialog 閃退、卡頓、過曝？這個 skill 把跨套件整合的踩坑固化，第一版 scaffold 就對。

1. **裝**：`/plugin marketplace add astroicers/visual-web-stack`（或 `npx skills add astroicers/visual-web-stack`）。
2. 在對話說：「用 visual-web-stack 幫我搭一個 scroll-driven 3D 首頁」。
3. 它依鐵則 scaffold：**three-layer** 架構、**Lenis** + **ScrollTrigger** 滾動、**R3F** Canvas、用 store 橋接 DOM ↔ Canvas（**state-bridge**）。
4. 主題走 `next-themes` + token；Radix + Motion 進出場；3D 跟主題連動。
5. 上線前過 `references/pitfalls.md` 的效能檢查。

## 術語速查

- **R3F** — React Three Fiber，用 React 寫 Three.js 3D 場景。
- **Lenis** — 平滑滾動函式庫，驅動滾動進度。
- **ScrollTrigger** — GSAP 的滾動觸發（pin / scrub）。
- **three-layer** — DOM / Canvas / 狀態三層架構，避免互相打架。
- **state-bridge** — 用 store 讓 DOM 與 Canvas 共享狀態（或反向）。

（完整方法見 `SKILL.md` 與 `references/`。）

## 結構

```
visual-web-stack/
├── README.md                   # 本文件
├── LICENSE                     # MIT
├── install.sh                  # 安裝腳本
├── .asp-fact-check.md          # 第三方套件 API 查證紀錄
├── .claude-plugin/
│   ├── marketplace.json        # Claude Code Marketplace 定義
│   └── plugin.json             # Plugin 描述
└── skills/
    └── visual-web-stack/
        ├── SKILL.md            # 核心：四層架構 + 8 條鐵則 + 引擎分工 + 路由表
        └── references/         # 按需載入的完整實作範例
            ├── setup.md        # 專案初始化、依賴、Vite/Tailwind 設定、目錄結構
            ├── scroll-system.md# Lenis + ScrollTrigger 整合
            ├── three-layer.md  # Canvas、Drei 工具、後處理管線、效能降級
            ├── animation-recipes.md  # Motion×Radix、Anime.js×Three 完整配方
            ├── state-bridge.md # Zustand transient read、store 設計
            ├── ui-theming.md   # Radix 包裝規範、next-themes 與 3D 同步
            └── pitfalls.md     # 地雷對照表 + 效能守則
```

## 安裝

> 以下方法**擇一**即可。全域安裝法（marketplace / install.sh / symlink / `npx skills -g`
> / `gh skill`）都會寫入 `~/.claude/skills/visual-web-stack`，**勿混用**以免版本不一致。

### 方法 A：Claude Code Marketplace（推薦）

1. Claude Code → **Manage Plugins** → **Marketplaces**
2. 貼上 `https://github.com/astroicers/visual-web-stack` → **Add**
3. 切到 **Plugins** tab，找到 `visual-web-stack` → **Install**

更新由 Claude Code 自行管理。

### 方法 B：安裝腳本

```bash
git clone https://github.com/astroicers/visual-web-stack.git
cd visual-web-stack
./install.sh          # 已存在會詢問；--force 直接覆蓋
```

### 方法 C：手動 symlink（開發本 skill 時，改 repo 即時生效）

```bash
# 先移除既有安裝（目錄或舊連結）——若目標已是目錄，ln 會把連結建到目錄「裡面」而非取代它
rm -rf ~/.claude/skills/visual-web-stack
ln -s "$(pwd)/skills/visual-web-stack" ~/.claude/skills/visual-web-stack
```

### 方法 D：npx skills / gh skill（跨 agent 開放安裝器）

open agent-skills 安裝器，Claude Code / Cursor / opencode 等通用（會自動偵測 agent）：

```bash
# 全域（user base，所有專案共用；知識層 skill 建議用這個）
npx skills add astroicers/visual-web-stack -g -a claude-code
# 僅本專案（裝到 ./.claude/skills/）
npx skills add astroicers/visual-web-stack -a claude-code
# 先預覽會裝哪些 skill（不安裝）
npx skills add astroicers/visual-web-stack --list
```

或用 GitHub CLI（gh v2.90+，GitHub 原生；預設目標是 Copilot，故需指定 agent）：

```bash
gh skill install astroicers/visual-web-stack --agent claude-code --scope user
```

驗證：

```bash
head -5 ~/.claude/skills/visual-web-stack/SKILL.md
```

## 更新

```bash
cd visual-web-stack
git pull
./install.sh --force
```

（symlink 安裝只需 `git pull`。）

## 解除安裝

```bash
rm -rf ~/.claude/skills/visual-web-stack
```

## 與 AI-SOP-Protocol（ASP）搭配

本 skill 是**知識層**（怎麼蓋），ASP 是**治理層**（怎麼工作），兩者疊加、互不取代。

在 ASP 管理的專案中，於專案 CLAUDE.md 加入一行：

```
本專案前端技術棧遵循 visual-web-stack skill，跨套件整合規範以該 skill 鐵則為準。
```

分工界線：

- 品質門檻（G1–G6）、commit 流程、ADR 紀律 → 聽 ASP。
- 若專案啟用 ASP 的 `frontend_quality` profile，三態驗證 / i18n / a11y 以
  ASP 為準，本 skill 不重複定義。
- 技術棧整合細節（Lenis 單例、transient read、forceMount 三件套…）→ 聽本 skill。

## 套件版本對照表

撰寫基準：2026-06（查證紀錄見 `.asp-fact-check.md`）。
**套件 API 變更時，更新對應的 references 檔並同步此表。**

| 套件 | Major | 對應 references 檔 |
|------|-------|--------------------|
| react / react-dom | 19 | setup.md |
| vite | 8 | setup.md |
| typescript | 5+ | setup.md |
| tailwindcss | 4 | setup.md、ui-theming.md |
| @radix-ui/react-*（逐 primitive） | 1 | ui-theming.md、animation-recipes.md |
| three | 0.159+ | three-layer.md |
| @react-three/fiber | 9（React 19 配對） | three-layer.md |
| @react-three/drei | 10（fiber 9 配對） | three-layer.md |
| @react-three/postprocessing | 3（fiber 9 配對） | three-layer.md |
| animejs | 4（具名匯入） | animation-recipes.md |
| motion | 12+（匯入路徑 `motion/react`） | animation-recipes.md |
| gsap / @gsap/react | 3 / 2 | scroll-system.md |
| lenis | 1 | scroll-system.md |
| zustand | 5 | state-bridge.md |
| leva | 0.10 | setup.md |
| next-themes | 0.4 | ui-theming.md |

> **React 18 相容備援**：3D 鏈降版為 fiber@8 → drei@9 → postprocessing@2（three 0.156 內），
> 其餘套件與 8 條鐵則皆不變。詳見 `references/setup.md` 文末「版本配對速查」。

## License

MIT
