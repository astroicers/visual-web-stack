# 專案初始化（setup）

> 適用：專案剛開始、要 scaffold、安裝依賴、設定 Vite / Tailwind、決定目錄結構。

## 1. 建立專案

```bash
npm create vite@latest my-site -- --template react-ts
cd my-site
```

注意：本技術棧基準為 **React 19**（R3F v9 的相容要求，Vite 預設即 React 19）。
若專案受限必須用 React 18，降版並改用相容的 3D 鏈：

```bash
npm install react@^18.3.1 react-dom@^18.3.1
npm install -D @types/react@^18 @types/react-dom@^18
# 3D 層改裝 fiber@8 → drei@9 → postprocessing@2（見文末「版本配對速查」相容備援列）
```

## 2. 安裝依賴

```bash
# 3D 層（版本配對：React 19 → fiber@9 → drei@10 → postprocessing@3）
npm install three @react-three/fiber@^9 @react-three/drei@^10 @react-three/postprocessing@^3
npm install -D @types/three

# 滾動與動畫
npm install gsap @gsap/react lenis animejs motion

# 狀態、調參、主題
npm install zustand leva next-themes

# UI（Radix 依需求逐一安裝 primitive，不要裝整包）
npm install @radix-ui/react-dialog @radix-ui/react-tooltip

# Tailwind v4（CSS-first，不需要 tailwind.config.js）
npm install -D tailwindcss @tailwindcss/vite
```

## 3. Vite 設定

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

## 4. 入口 CSS（Tailwind v4 + Lenis 官方樣式）

```css
/* src/index.css */
@import 'tailwindcss';

/* next-themes 用 class 切換主題，需自訂 dark variant */
@custom-variant dark (&:where(.dark, .dark *));
```

Lenis 的基礎樣式**不要手抄**，直接匯入官方 stylesheet（見第 6 節 main.tsx）。
官方版包含 `[data-lenis-prevent]` 容器的 `overscroll-behavior: contain`
（防止彈出層內滾到底時把整頁帶著滾）、stopped 狀態、iframe 防呆等規則，
手抄片段很容易過時或漏規則。

## 5. 目錄結構

```
src/
├── main.tsx                 # 入口，只 render <App />
├── App.tsx                  # Provider 組裝（順序見下）
├── index.css                # Tailwind 入口 + Lenis 基礎樣式
├── providers/
│   └── SmoothScroll.tsx     # Lenis 單例（見 scroll-system.md）
├── stores/
│   └── useAppStore.ts       # Zustand store（見 state-bridge.md）
├── components/
│   ├── ui/                  # Radix 包裝元件（見 ui-theming.md）
│   ├── three/               # Canvas 與場景（見 three-layer.md）
│   └── sections/            # 頁面區塊（DOM）
└── lib/                     # 純函式工具
```

## 6. 入口組裝順序

Provider 由外而內：`ThemeProvider` → `TooltipProvider` → `SmoothScroll` → 內容。
Canvas 鋪底、DOM 內容疊上（z-index 分層見 three-layer.md）。

```tsx
// src/App.tsx
import { ThemeProvider } from 'next-themes'
import { SmoothScroll } from './providers/SmoothScroll'
import { TooltipProvider } from './components/ui/Tooltip'
import { ThreeLayer } from './components/three/ThreeLayer'
import { HeroSection } from './components/sections/HeroSection'
import { StorySection } from './components/sections/StorySection'

export default function App() {
  return (
    <ThemeProvider attribute="class" defaultTheme="dark" disableTransitionOnChange>
      <TooltipProvider>
        <SmoothScroll>
          <ThreeLayer />
          <main className="relative z-10">
            <HeroSection />
            <StorySection />
          </main>
        </SmoothScroll>
      </TooltipProvider>
    </ThemeProvider>
  )
}
```

（`TooltipProvider` 定義見 ui-theming.md、`StorySection` 見 scroll-system.md。）

```tsx
// src/components/sections/HeroSection.tsx — 最小首屏
export function HeroSection() {
  return (
    <section id="hero" className="flex h-screen items-center justify-center">
      <h1 className="text-7xl font-bold tracking-tight">Visual Web</h1>
    </section>
  )
}
```

```tsx
// src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import 'lenis/dist/lenis.css' // Lenis 官方樣式（data-lenis-prevent、stopped 等規則）
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

## 7. Leva 只在開發模式渲染

Leva 的面板是 DOM 元件，**必須掛在 Canvas 外**（掛進 Scene 會炸出
「Div is not part of the THREE namespace」）；`useControls` 則 Canvas 內外都能呼叫。

```tsx
// src/App.tsx 內（DOM 層、Canvas 外）
import { Leva } from 'leva'

{import.meta.env.DEV && <Leva />}
```

```tsx
// src/components/three/TunableLight.tsx（Canvas 內只用 useControls）
import { useControls } from 'leva'

export function TunableLight() {
  const { intensity } = useControls('light', { intensity: { value: 1.2, min: 0, max: 5 } })
  return <directionalLight position={[3, 4, 5]} intensity={intensity} />
}
```

注意：`import.meta.env.DEV` 條件渲染只保證 **production 不渲染面板**；
`useControls` 是靜態 import，leva 套件本身仍會進 bundle。視覺系網站通常可接受，
若要完全排除，得把所有調參程式碼隔離成 dev-only 模組再動態載入——多數情況不值得。

## 版本配對速查

| 套件 | 版本 | 配對理由 |
|------|------|---------|
| react / react-dom | 19.x | R3F v9 的相容基準（fiber 9 需 react >=19 <19.3） |
| @react-three/fiber | 9.x | 對應 React 19 |
| @react-three/drei | 10.x | 需 fiber v9 |
| @react-three/postprocessing | 3.x | 需 fiber v9 |
| three | 0.159+ | drei v10 下限（postprocessing v3 需 0.156+） |
| tailwindcss | 4.x | CSS-first，用 @tailwindcss/vite |
| animejs | 4.x | 具名匯入（見 animation-recipes.md） |
| motion | 12.x+ | 匯入路徑 `motion/react` |

**React 18 相容備援**：若必須用 React 18，整條 3D 鏈降版為 fiber@8 → drei@9 → postprocessing@2（three 0.156 內）；其餘套件與 8 條鐵則皆不變。

升級/降版任一套件 major 前，先確認此配對鏈是否同步（React ↔ fiber ↔ drei ↔ postprocessing 整條一起動）。
