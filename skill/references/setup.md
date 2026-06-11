# 專案初始化（setup）

> 適用：專案剛開始、要 scaffold、安裝依賴、設定 Vite / Tailwind、決定目錄結構。

## 1. 建立專案

```bash
npm create vite@latest my-site -- --template react-ts
cd my-site
```

注意：本技術棧鎖定 **React 18**（R3F v8 的相容要求），若 scaffold 出來是
React 19，降版：

```bash
npm install react@^18.3.1 react-dom@^18.3.1
npm install -D @types/react@^18 @types/react-dom@^18
```

## 2. 安裝依賴

```bash
# 3D 層（版本配對：React 18 → fiber@8 → drei@9 → postprocessing@2）
npm install three @react-three/fiber@^8 @react-three/drei@^9 @react-three/postprocessing@^2
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

## 4. Tailwind v4 入口 CSS

```css
/* src/index.css */
@import 'tailwindcss';

/* next-themes 用 class 切換主題，需自訂 dark variant */
@custom-variant dark (&:where(.dark, .dark *));

html.lenis,
html.lenis body {
  height: auto;
}

.lenis.lenis-smooth {
  scroll-behavior: auto !important;
}
```

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

Provider 由外而內：`ThemeProvider` → `SmoothScroll` → 內容。
Canvas 鋪底、DOM 內容疊上（z-index 分層見 three-layer.md）。

```tsx
// src/App.tsx
import { ThemeProvider } from 'next-themes'
import { SmoothScroll } from './providers/SmoothScroll'
import { ThreeLayer } from './components/three/ThreeLayer'
import { HeroSection } from './components/sections/HeroSection'
import { StorySection } from './components/sections/StorySection'

export default function App() {
  return (
    <ThemeProvider attribute="class" defaultTheme="dark" disableTransitionOnChange>
      <SmoothScroll>
        <ThreeLayer />
        <main className="relative z-10">
          <HeroSection />
          <StorySection />
        </main>
      </SmoothScroll>
    </ThemeProvider>
  )
}
```

```tsx
// src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

## 7. Leva 只進開發版

Leva 是開發期調參面板，production 不該出現：

```tsx
// src/components/three/Scene.tsx 內使用
import { useControls, Leva } from 'leva'

export function DebugPanel() {
  // import.meta.env.DEV 為 Vite 內建旗標，production build 會被 tree-shake
  return <Leva hidden={!import.meta.env.DEV} />
}

export function TunableLight() {
  const { intensity } = useControls('light', { intensity: { value: 1.2, min: 0, max: 5 } })
  return <directionalLight position={[3, 4, 5]} intensity={intensity} />
}
```

## 版本配對速查

| 套件 | 版本 | 配對理由 |
|------|------|---------|
| react / react-dom | 18.x | R3F v8 的相容基準 |
| @react-three/fiber | 8.x | v9 需要 React 19 |
| @react-three/drei | 9.x | v10 需要 fiber v9 |
| @react-three/postprocessing | 2.x | v2 對應 fiber v8 |
| tailwindcss | 4.x | CSS-first，用 @tailwindcss/vite |
| animejs | 4.x | 具名匯入（見 animation-recipes.md） |
| motion | 12.x+ | 匯入路徑 `motion/react` |

升級任一套件 major 前，先確認此配對鏈是否同步升級（特別是 React 19 → fiber 9 → drei 10 → postprocessing 3 整條一起動）。
