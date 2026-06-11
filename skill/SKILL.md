---
name: visual-web-stack
description: |
  React 視覺系網站技術棧整合規範，涵蓋 React 18 + Vite + TypeScript +
  Tailwind CSS + Radix UI + React Three Fiber (R3F) + Drei +
  @react-three/postprocessing + Anime.js + Motion (Framer Motion) +
  GSAP ScrollTrigger + Lenis + Zustand + Leva + next-themes。
  當專案使用以下任一組合時必須載入：R3F / Three.js + React、Lenis 平滑滾動、
  GSAP ScrollTrigger、Anime.js、Motion、Radix UI、@react-three/postprocessing。
  Handles: 專案 scaffold、滾動驅動 3D 敘事、Canvas 與 DOM 狀態橋接、
  動畫引擎選型、後處理效果、效能降級策略。
  Triggers: 視覺系網站, 3D 網站, 滾動動畫, scroll-driven, R3F,
  react-three-fiber, lenis, scrolltrigger, 作品集網站, landing page,
  官網, hero 動畫, WebGL, three.js, postprocessing, bloom.
---

# Visual Web Stack — 視覺系網站技術棧整合規範

本 skill 固化「視覺系網站」（滾動驅動 3D 敘事、作品集、品牌官網、landing page）
的跨套件整合知識。目標：**第一版 scaffold 就符合架構規範**，不靠事後重構補課。

## 四層架構

```
┌──────────────────────────────────────────────────────────────┐
│  UI 層（DOM）                                                 │
│  Radix UI ＋ Motion ＋ Tailwind ＋ next-themes                │
│  選單、Dialog、卡片、文字排版、進出場動畫、主題切換            │
├──────────────────────────────────────────────────────────────┤
│  3D 層（Canvas）                                              │
│  R3F ＋ Drei ＋ @react-three/postprocessing ＋ Anime.js       │
│  場景、模型、材質、相機、後處理特效（開發期掛 Leva 調參）      │
├──────────────────────────────────────────────────────────────┤
│  滾動編排層                                                   │
│  Lenis（滾動物理）＋ GSAP ScrollTrigger（觸發點與時間軸）      │
│  唯一的 RAF 來源：gsap.ticker                                 │
├──────────────────────────────────────────────────────────────┤
│  狀態層                                                       │
│  Zustand — DOM 與 Canvas 之間「唯一」的通訊橋樑               │
│  scrollProgress / storyPhase / activeSection                  │
└──────────────────────────────────────────────────────────────┘
```

**核心原則：DOM 與 Canvas 只透過 Zustand 通訊。**
DOM 事件（滾動、點擊、主題切換）寫入 store；Canvas 內以 transient read 讀取。
禁止 DOM 元件直接操作 Three 物件，也禁止 Canvas 元件直接操作 DOM。

## 鐵則（MUST，違反即重寫）

1. **單一 Lenis 實例、單一 RAF 來源**：全站只允許一個 Lenis 實例，且必須由
   `gsap.ticker` 驅動 `lenis.raf`（`gsap.ticker.add((t) => lenis.raf(t * 1000))`），
   並設定 `gsap.ticker.lagSmoothing(0)`。禁止自建 `requestAnimationFrame` 迴圈。
2. **useFrame 內一律 transient read**：在 `useFrame` 內讀取 store 必須用
   `useAppStore.getState()`，禁止以 hook 訂閱高頻值（滾動進度、滑鼠位置）——
   hook 訂閱會讓元件每 frame re-render。
3. **Radix × Motion exit 動畫三件套**：Radix 元件要配 Motion 的 exit 動畫，
   必須同時使用 `forceMount` ＋ `AnimatePresence` ＋ `asChild`，缺一不可。
4. **一個元素只由一套動畫引擎驅動**：禁止 GSAP 與 Motion（或任兩套引擎）
   同時操作同一元素的同一屬性。
5. **Canvas 固定設定**：`dpr={[1, 2]}`、`gl={{ antialias: false }}`
   （抗鋸齒交給後處理的 SMAA）。
6. **Dialog/Drawer 內的滾動容器必須加 `data-lenis-prevent`**，否則內部無法滾動。
7. **程式化捲動只用 `lenis.scrollTo()`**，禁止 `scrollIntoView`（會繞過 Lenis
   造成位置錯亂）。
8. **DOM 側動畫只動 transform / opacity**，禁止動 layout 屬性
   （width / height / top / left / margin）——會觸發 reflow 並讓 ScrollTrigger 失準。

## 動畫引擎分工表（選型路由）

| 需求 | 引擎 | 參考檔 |
|------|------|--------|
| 滾動驅動（pin、scrub、進視口觸發） | GSAP ScrollTrigger | [references/scroll-system.md](references/scroll-system.md) |
| React 元件進出場、layout 動畫、hover/tap | Motion（`motion/react`） | [references/animation-recipes.md](references/animation-recipes.md) |
| Canvas 內數值（相機路徑、材質 uniform、3D 物件屬性）、複雜 stagger 時間軸、SVG 描邊 | Anime.js v4 | [references/animation-recipes.md](references/animation-recipes.md) |

判斷順序：先問「跟滾動位置綁定嗎？」→ GSAP ScrollTrigger；
再問「是 React 元件的掛載／互動狀態嗎？」→ Motion；
再問「是 Canvas 內的純數值嗎？」→ Anime.js。

## references/ 路由表

按需載入，維持本檔精簡。**動手寫碼前先讀對應檔案。**

| 情境 | 讀這個檔 |
|------|---------|
| 專案剛開始、要 scaffold、裝依賴、設定 Vite/Tailwind、決定目錄結構 | [references/setup.md](references/setup.md) |
| 接 Lenis、寫 ScrollTrigger pin/scrub、滾動進度要進 store | [references/scroll-system.md](references/scroll-system.md) |
| 鋪 Canvas、選 Drei 工具、配後處理管線、做效能降級 | [references/three-layer.md](references/three-layer.md) |
| 寫 Radix + Motion 進出場、用 Anime.js 動相機或材質 | [references/animation-recipes.md](references/animation-recipes.md) |
| 定義 store、Canvas 要讀 DOM 狀態（或反向） | [references/state-bridge.md](references/state-bridge.md) |
| 包 Radix 元件、設定 next-themes、3D 場景要跟主題連動 | [references/ui-theming.md](references/ui-theming.md) |
| 出現怪 bug（觸發點漂移、Dialog 閃退、卡頓、過曝…）、上線前效能檢查 | [references/pitfalls.md](references/pitfalls.md) |

## 與 AI-SOP-Protocol（ASP）的關係

本 skill 是**知識層**（怎麼蓋），ASP 是**治理層**（怎麼工作），兩者透過專案層
CLAUDE.md 引用疊加，互不取代：

- 本 skill 不取代 ASP 的品質門檻（G1–G6）、commit 流程、ADR 紀律。
- 若專案啟用 ASP 的 `frontend_quality` profile，**三態驗證、i18n、a11y 規則
  以 ASP 為準**，本 skill 不重複定義。
- 衝突時：工作流程聽 ASP，技術棧整合細節（本檔鐵則與 references/）聽本 skill。
