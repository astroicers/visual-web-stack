# visual-web-stack

視覺系網站技術棧的 Claude Code skill——把跨套件整合的踩坑知識固化，讓第一版
scaffold 就符合架構規範。

涵蓋技術棧：React 18 + Vite + TypeScript + Tailwind CSS + Radix UI +
React Three Fiber + Drei + @react-three/postprocessing + Anime.js + Motion +
GSAP ScrollTrigger + Lenis + Zustand + Leva + next-themes。

## 結構

```
visual-web-stack/
├── README.md                   # 本文件
├── LICENSE                     # MIT
├── install.sh                  # 安裝腳本
├── .asp-fact-check.md          # 第三方套件 API 查證紀錄
└── skill/
    ├── SKILL.md                # 核心：四層架構 + 8 條鐵則 + 引擎分工 + 路由表
    └── references/             # 按需載入的完整實作範例
        ├── setup.md            # 專案初始化、依賴、Vite/Tailwind 設定、目錄結構
        ├── scroll-system.md    # Lenis + ScrollTrigger 整合
        ├── three-layer.md      # Canvas、Drei 工具、後處理管線、效能降級
        ├── animation-recipes.md# Motion×Radix、Anime.js×Three 完整配方
        ├── state-bridge.md     # Zustand transient read、store 設計
        ├── ui-theming.md       # Radix 包裝規範、next-themes 與 3D 同步
        └── pitfalls.md         # 地雷對照表 + 效能守則
```

## 安裝

```bash
git clone https://github.com/astroicers/visual-web-stack.git
cd visual-web-stack
./install.sh          # 已存在會詢問；--force 直接覆蓋
```

或手動 symlink（改 repo 即時生效，適合開發本 skill 時）：

```bash
# 先移除既有安裝（目錄或舊連結）——若目標已是目錄，ln 會把連結建到目錄「裡面」而非取代它
rm -rf ~/.claude/skills/visual-web-stack
ln -s "$(pwd)/skill" ~/.claude/skills/visual-web-stack
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
| react / react-dom | 18 | setup.md |
| vite | 8 | setup.md |
| typescript | 5 | setup.md |
| tailwindcss | 4 | setup.md、ui-theming.md |
| @radix-ui/react-*（逐 primitive） | 1 | ui-theming.md、animation-recipes.md |
| three | 0.1xx | three-layer.md |
| @react-three/fiber | 8（React 18 配對） | three-layer.md |
| @react-three/drei | 9（fiber 8 配對） | three-layer.md |
| @react-three/postprocessing | 2（fiber 8 配對） | three-layer.md |
| animejs | 4（具名匯入） | animation-recipes.md |
| motion | 12+（匯入路徑 `motion/react`） | animation-recipes.md |
| gsap / @gsap/react | 3 / 2 | scroll-system.md |
| lenis | 1 | scroll-system.md |
| zustand | 5 | state-bridge.md |
| leva | 0.10 | setup.md |
| next-themes | 0.4 | ui-theming.md |

## License

MIT
