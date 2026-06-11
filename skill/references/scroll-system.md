# 滾動系統（Lenis + GSAP ScrollTrigger）

> 適用：接 Lenis、寫 ScrollTrigger pin/scrub、滾動進度要進 store、程式化捲動。
>
> 對應鐵則：#1（單一 Lenis、gsap.ticker 驅動）、#6（data-lenis-prevent）、
> #7（只用 lenis.scrollTo）、#8（只動 transform/opacity）。

## 架構

```
使用者滾動 → Lenis（平滑物理）
                │ lenis.on('scroll')
                ├──→ useAppStore.setScrollProgress()   （Canvas 透過 getState 讀）
                └──→ ScrollTrigger.update()            （DOM 動畫觸發點同步）
gsap.ticker ──→ lenis.raf(time * 1000)                 （唯一 RAF 來源）
```

## SmoothScroll Provider（完整實作）

全站唯一的 Lenis 實例。掛在 App 最外層（ThemeProvider 之內）。

```tsx
// src/providers/SmoothScroll.tsx
import { useEffect, type ReactNode } from 'react'
import Lenis from 'lenis'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { useAppStore } from '../stores/useAppStore'

gsap.registerPlugin(ScrollTrigger)

// 模組層單例：給 scrollToTarget 用，同時保證重複 mount 時不會產生第二個實例
let activeLenis: Lenis | null = null

/** 程式化捲動唯一入口（鐵則 #7：禁止 scrollIntoView） */
export function scrollToTarget(
  target: string | number | HTMLElement,
  options?: { offset?: number; duration?: number },
) {
  activeLenis?.scrollTo(target, options)
}

export function SmoothScroll({ children }: { children: ReactNode }) {
  useEffect(() => {
    if (activeLenis) return // StrictMode 二次 mount 防護

    const lenis = new Lenis({ lerp: 0.1 })
    activeLenis = lenis

    // 滾動值同時餵給狀態層與 ScrollTrigger
    lenis.on('scroll', (e: Lenis) => {
      useAppStore.getState().setScrollProgress(e.progress)
      ScrollTrigger.update()
    })

    // 鐵則 #1：由 gsap.ticker 驅動 lenis.raf（gsap 的 time 單位是秒，Lenis 要毫秒）
    const update = (time: number) => lenis.raf(time * 1000)
    gsap.ticker.add(update)
    gsap.ticker.lagSmoothing(0)

    return () => {
      gsap.ticker.remove(update)
      lenis.destroy()
      activeLenis = null
    }
  }, [])

  return <>{children}</>
}
```

## ScrollTrigger pin/scrub Section（完整範例）

固定一個 section、用滾動 scrub 動畫，並把敘事階段寫入 `storyPhase`
（Canvas 端的相機與材質會訂閱它，見 animation-recipes.md）。

```tsx
// src/components/sections/StorySection.tsx
import { useRef } from 'react'
import gsap from 'gsap'
import { useGSAP } from '@gsap/react'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { useAppStore, type StoryPhase } from '../../stores/useAppStore'

gsap.registerPlugin(useGSAP, ScrollTrigger)

const PHASES: readonly StoryPhase[] = ['intro', 'build', 'reveal']

export function StorySection() {
  const sectionRef = useRef<HTMLElement>(null)

  useGSAP(
    () => {
      gsap
        .timeline({
          scrollTrigger: {
            trigger: sectionRef.current,
            start: 'top top',
            end: '+=300%', // pin 住，滾 3 個視窗高度
            pin: true,
            scrub: 1,
            onUpdate: (self) => {
              const index = Math.min(
                PHASES.length - 1,
                Math.floor(self.progress * PHASES.length),
              )
              const { storyPhase, setStoryPhase } = useAppStore.getState()
              if (storyPhase !== PHASES[index]) setStoryPhase(PHASES[index])
            },
          },
        })
        // 鐵則 #8：只動 transform / opacity
        .to('.story-title', { yPercent: -60, opacity: 0, ease: 'none' })
        .from('.story-detail', { yPercent: 40, opacity: 0, ease: 'none' }, '<0.3')
    },
    { scope: sectionRef }, // selector 限定在本 section 內，避免誤傷同名 class
  )

  return (
    <section ref={sectionRef} className="relative flex h-screen items-center justify-center">
      <h2 className="story-title text-6xl font-bold">敘事標題</h2>
      <p className="story-detail absolute bottom-24 max-w-md text-lg opacity-80">
        滾動推進的補充說明文字。
      </p>
    </section>
  )
}
```

要點：

- `useGSAP` 自動處理 cleanup（timeline 與 ScrollTrigger 都會 revert），不要自己寫
  `ScrollTrigger.kill()`。
- `scope` 一定要給，否則 selector 是全域的。
- `onUpdate` 內用 `getState()` 讀寫（高頻 callback，同鐵則 #2 的精神），
  並先比對再 set，避免每 frame 觸發訂閱者。

## 程式化捲動（導覽列跳轉）

```tsx
// src/components/ui/NavLink.tsx
import { scrollToTarget } from '../../providers/SmoothScroll'

export function NavLink({ targetId, label }: { targetId: string; label: string }) {
  return (
    <button
      type="button"
      className="px-3 py-1 text-sm opacity-70 transition-opacity hover:opacity-100"
      onClick={() => scrollToTarget(`#${targetId}`, { offset: -80 })}
    >
      {label}
    </button>
  )
}
```

## Dialog / Drawer 內的滾動

Lenis 會攔截 wheel 事件，彈出層內的 `overflow-y-auto` 容器必須加
`data-lenis-prevent`（鐵則 #6），否則內部滾不動：

```tsx
<div data-lenis-prevent className="max-h-[60vh] overflow-y-auto">
  {longContent}
</div>
```

完整 Dialog 範例見 [animation-recipes.md](animation-recipes.md)。
