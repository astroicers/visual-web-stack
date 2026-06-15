# UI 與主題（Radix 包裝、next-themes、3D 場景同步）

> 適用：包 Radix 元件、設定 next-themes、3D 場景要跟主題連動。
>
> 對應鐵則：#3（Radix × Motion 動畫需 forceMount 三件套，完整配方見 animation-recipes.md）。

## Radix Primitive 包裝規範

1. **每個 primitive 包成專案元件**，放 `src/components/ui/<Name>.tsx`，
   一個 primitive 一個檔案。
2. **業務元件禁止直接 import `@radix-ui/*`**——只能用 `components/ui/` 的包裝。
   Radix 升版或換元件庫時，改動被鎖在包裝層。
3. **樣式集中在包裝層**：Tailwind class 全寫在包裝元件裡，業務端不帶樣式進來。
4. **對外 API 收斂**：包裝層只暴露這個專案真正用到的 props，不要轉發整包
   Radix props。
5. 需要進出場動畫的 primitive → forceMount 三件套，見
   [animation-recipes.md](animation-recipes.md)。

### 範例：Tooltip 包裝

```tsx
// src/components/ui/Tooltip.tsx
import type { ReactNode } from 'react'
import * as TooltipPrimitive from '@radix-ui/react-tooltip'

/** 掛一次在 App 最外層（setup.md 的 App.tsx 組裝已包含） */
export function TooltipProvider({ children }: { children: ReactNode }) {
  return <TooltipPrimitive.Provider delayDuration={200}>{children}</TooltipPrimitive.Provider>
}

interface TooltipProps {
  label: string
  children: ReactNode
}

export function Tooltip({ label, children }: TooltipProps) {
  return (
    <TooltipPrimitive.Root>
      <TooltipPrimitive.Trigger asChild>{children}</TooltipPrimitive.Trigger>
      <TooltipPrimitive.Portal>
        <TooltipPrimitive.Content
          sideOffset={6}
          className="z-50 rounded-md bg-zinc-900 px-3 py-1.5 text-sm text-zinc-50 shadow-md dark:bg-zinc-100 dark:text-zinc-900"
        >
          {label}
          <TooltipPrimitive.Arrow className="fill-zinc-900 dark:fill-zinc-100" />
        </TooltipPrimitive.Content>
      </TooltipPrimitive.Portal>
    </TooltipPrimitive.Root>
  )
}
```

## next-themes 設定

next-themes 不依賴 Next.js，Vite SPA 直接用。`attribute="class"` 會在 `<html>`
上掛 `.dark` / `.light`，配 setup.md 的
`@custom-variant dark (&:where(.dark, .dark *));` 讓 Tailwind `dark:` 生效。

```tsx
// App.tsx 最外層（完整組裝見 setup.md）
import { ThemeProvider } from 'next-themes'

<ThemeProvider attribute="class" defaultTheme="dark" disableTransitionOnChange>
  {/* … */}
</ThemeProvider>
```

### 主題切換按鈕

```tsx
// src/components/ui/ThemeToggle.tsx
import { useEffect, useState } from 'react'
import { useTheme } from 'next-themes'

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  // 首次 render 時 resolvedTheme 尚未從 localStorage 解析，先不畫，避免閃錯圖示
  useEffect(() => setMounted(true), [])
  if (!mounted) return null

  return (
    <button
      type="button"
      aria-label="切換主題"
      className="rounded-full p-2 opacity-70 transition-opacity hover:opacity-100"
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
    >
      {resolvedTheme === 'dark' ? '🌙' : '☀️'}
    </button>
  )
}
```

**一律讀 `resolvedTheme`，不要讀 `theme`**——`theme` 在系統模式下是字串
`"system"`，拿去判斷 dark/light 必錯（pitfalls.md「主題切換 3D 沒跟上」）。

## 3D 場景與主題同步

主題是 DOM 側狀態。依「DOM 與 Canvas 只透過橋接通訊」的原則，
`useTheme` 在 **Canvas 外**讀，再以 prop 傳進 3D 層（Canvas 內是另一個
React reconciler，外層 context 不保證可達，prop 永遠安全）。

**ThemedStage 取代 three-layer.md Scene 裡的 `<Environment preset="city" />`**——
一個場景只能有一個 Environment（後掛載的會覆寫前者的 `scene.environment`，
還多載一份 HDR），採用本節模式時要把 Scene 裡那行刪掉：

```tsx
// src/components/three/ThemedStage.tsx
import { Environment } from '@react-three/drei'

export type SceneTheme = 'dark' | 'light'

const SCENE_THEME = {
  dark: { background: '#09090b', preset: 'night' },
  light: { background: '#f4f4f5', preset: 'dawn' },
} as const

export function ThemedStage({ theme }: { theme: SceneTheme }) {
  const { background, preset } = SCENE_THEME[theme]
  return (
    <>
      <color attach="background" args={[background]} />
      <Environment preset={preset} />
    </>
  )
}
```

```tsx
// src/components/three/ThreeLayer.tsx（在 three-layer.md 的版本上加主題）
import { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { useTheme } from 'next-themes'
import { Scene } from './Scene'
import { Effects } from './Effects'
import { ThemedStage, type SceneTheme } from './ThemedStage'

export function ThreeLayer() {
  const { resolvedTheme } = useTheme()
  const sceneTheme: SceneTheme = resolvedTheme === 'light' ? 'light' : 'dark'

  return (
    <div className="fixed inset-0 z-0" aria-hidden>
      <Canvas
        dpr={[1, 2]}
        gl={{ antialias: false, powerPreference: 'high-performance' }}
        camera={{ position: [0, 0, 5], fov: 45 }}
      >
        <Suspense fallback={null}>
          <ThemedStage theme={sceneTheme} />
          {/* Scene 內原本的 <Environment preset="city" /> 已移除，
              環境光與背景統一由 ThemedStage 提供 */}
          <Scene />
        </Suspense>
        <Effects />
      </Canvas>
    </div>
  )
}
```

注意：切換 `Environment preset` 會重新載入 HDR，畫面會頓一下。在意的話，
固定一組 Environment、改成只切 `background` 與燈光強度／色溫；或把兩種主題
的資源在 loading 階段就全部載完。
