# 狀態橋接（Zustand）

> 適用：定義 store、Canvas 要讀 DOM 狀態（或反向）。
>
> 對應鐵則：#2（useFrame 內一律 transient read）。
> 核心原則：DOM 與 Canvas 只透過 Zustand 通訊。

## Store 完整定義

```tsx
// src/stores/useAppStore.ts
import { create } from 'zustand'

export type StoryPhase = 'intro' | 'build' | 'reveal'

interface AppState {
  /** 全頁滾動進度 0–1（高頻：每個滾動 frame 都在變） */
  scrollProgress: number
  /** 敘事階段（低頻：ScrollTrigger 跨過分段點才變） */
  storyPhase: StoryPhase
  /** 目前視口所在的 section id（低頻） */
  activeSection: string
  setScrollProgress: (value: number) => void
  setStoryPhase: (phase: StoryPhase) => void
  setActiveSection: (id: string) => void
}

export const useAppStore = create<AppState>()((set) => ({
  scrollProgress: 0,
  storyPhase: 'intro',
  activeSection: 'hero',
  setScrollProgress: (scrollProgress) => set({ scrollProgress }),
  setStoryPhase: (storyPhase) => set({ storyPhase }),
  setActiveSection: (activeSection) => set({ activeSection }),
}))
```

寫入端：Lenis 的 scroll 事件寫 `scrollProgress`、ScrollTrigger 的 `onUpdate`
寫 `storyPhase`（見 scroll-system.md）。

## ❌ 反例：hook 訂閱高頻值

```tsx
// ❌ 千萬不要這樣寫
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Group } from 'three'
import { useAppStore } from '../../stores/useAppStore'

export function BadHeroObject() {
  // 災難：scrollProgress 每個滾動 frame 都變，
  // 這個 hook 訂閱讓整個元件（含所有子元件）每 frame re-render
  const scrollProgress = useAppStore((state) => state.scrollProgress)
  const groupRef = useRef<Group>(null)

  useFrame(() => {
    if (!groupRef.current) return
    groupRef.current.rotation.y = scrollProgress * Math.PI * 2
  })

  return <group ref={groupRef}>{/* … */}</group>
}
```

症狀：滾動時 FPS 掉到個位數、React DevTools 整片狂閃。

## ✅ 正例：useFrame 內 transient read

```tsx
// ✅ 正確寫法
import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Group } from 'three'
import { useAppStore } from '../../stores/useAppStore'

export function HeroObject() {
  const groupRef = useRef<Group>(null)

  useFrame(() => {
    // 鐵則 #2：getState() 是 transient read——拿值不訂閱，零 re-render
    const { scrollProgress } = useAppStore.getState()
    if (!groupRef.current) return
    groupRef.current.rotation.y = scrollProgress * Math.PI * 2
    groupRef.current.position.y = -scrollProgress * 1.5
  })

  return <group ref={groupRef}>{/* … */}</group>
}
```

## 判斷準則：這個值能不能用 hook 訂閱？

| 值的變化頻率 | 例子 | 讀取方式 |
|--------------|------|---------|
| 高頻（每 frame 變） | scrollProgress、滑鼠位置、速度 | `useFrame` 內 `getState()`；DOM 側用 `subscribe` + 直接改 style |
| 低頻（使用者操作才變） | storyPhase、activeSection、主題、Dialog 開關 | 正常 hook 訂閱：`useAppStore((s) => s.storyPhase)` |

低頻值用 hook 訂閱是**正確**的——re-render 正是你要的（換文案、切 class）：

```tsx
import { useAppStore } from '../../stores/useAppStore'

export function PhaseCaption() {
  const storyPhase = useAppStore((state) => state.storyPhase) // 低頻，訂閱 OK
  const captions = { intro: '起點', build: '堆疊', reveal: '揭示' } as const
  return <p className="text-sm uppercase tracking-widest opacity-60">{captions[storyPhase]}</p>
}
```

## DOM 側的高頻消費：subscribe + 直接改 style

DOM 元件想跟著滾動進度動（例如進度條），同樣不准 hook 訂閱——
用 `subscribe` 拿值、直接寫 style，繞過 React：

```tsx
// src/components/ui/ScrollProgressBar.tsx
import { useEffect, useRef } from 'react'
import { useAppStore } from '../../stores/useAppStore'

export function ScrollProgressBar() {
  const barRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // 訂閱但不進 React：callback 裡直接改 DOM（只動 transform，鐵則 #8）
    const unsubscribe = useAppStore.subscribe((state) => {
      if (barRef.current) {
        barRef.current.style.transform = `scaleX(${state.scrollProgress})`
      }
    })
    return unsubscribe
  }, [])

  return (
    <div className="fixed inset-x-0 top-0 z-50 h-0.5 bg-white/10">
      <div ref={barRef} className="h-full origin-left bg-indigo-400" style={{ transform: 'scaleX(0)' }} />
    </div>
  )
}
```

## Store 設計守則

- **一個 app 一個 store**。視覺系網站的狀態量撐不起多 store 的複雜度。
- store 只放「跨層共享」的狀態。單一元件的 UI 狀態（Dialog 開關、輸入值）
  留在元件的 `useState`。
- actions 跟著 state 放在同一個 store 裡，元件不准直接 `setState`。
- 不要把 Three 物件（camera、mesh）放進 store——store 是值的橋，
  不是物件的註冊表；要操作 Three 物件，在 Canvas 內的元件做（見 animation-recipes.md）。
