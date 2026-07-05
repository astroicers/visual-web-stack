# 動畫配方（Motion × Radix、Anime.js × Three）

> 適用：寫 Radix + Motion 進出場、用 Anime.js 動相機或材質、SVG 描邊。
>
> 對應鐵則：#3（forceMount 三件套）、#4（一元素一引擎）、#6（data-lenis-prevent）。
>
> 匯入路徑：Motion 一律 `motion/react`（不是 framer-motion）；
> Anime.js 一律 v4 具名匯入 `import { animate, createTimeline, svg } from 'animejs'`。

## A. Radix Dialog + Motion 進出場（forceMount 三件套）

Radix 預設在關閉時**立刻**卸載 DOM，exit 動畫根本來不及播。解法是三件套：

1. `AnimatePresence`——掌管 exit，等動畫播完才真正移除；
2. `forceMount`——叫 Radix 不要自己拆 DOM，掛載權交給 AnimatePresence；
3. `asChild`——讓 `motion.div` 直接成為 Radix 的節點，不多包一層。

```tsx
// src/components/ui/Dialog.tsx
import { useState, type ReactNode } from 'react'
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { AnimatePresence, motion } from 'motion/react'

interface DialogProps {
  trigger: ReactNode
  title: string
  /** 給 screen reader 的對話框描述；未提供時以 title 代用（Radix a11y 要求） */
  description?: string
  children: ReactNode
}

export function Dialog({ trigger, title, description, children }: DialogProps) {
  const [open, setOpen] = useState(false)

  return (
    <DialogPrimitive.Root open={open} onOpenChange={setOpen}>
      <DialogPrimitive.Trigger asChild>{trigger}</DialogPrimitive.Trigger>

      <AnimatePresence>
        {open && (
          <DialogPrimitive.Portal forceMount>
            <DialogPrimitive.Overlay asChild forceMount>
              <motion.div
                className="fixed inset-0 z-40 bg-black/60"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
              />
            </DialogPrimitive.Overlay>

            <DialogPrimitive.Content asChild forceMount>
              <motion.div
                className="fixed left-1/2 top-1/2 z-50 w-[min(90vw,32rem)] rounded-xl bg-white p-6 shadow-xl dark:bg-zinc-900"
                // 置中交給 Motion 的 transform，不用 Tailwind 的 -translate-*，
                // 避免兩套系統操作同一視覺屬性（鐵則 #4 的精神）
                style={{ x: '-50%', y: '-50%' }}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ duration: 0.2, ease: 'easeOut' }}
              >
                <DialogPrimitive.Title className="text-lg font-semibold">{title}</DialogPrimitive.Title>
                {/* Radix 要求 Content 一定要有 Description（無障礙），缺了會在 console 警告 */}
                {description ? (
                  <DialogPrimitive.Description className="mt-2 text-sm opacity-70">
                    {description}
                  </DialogPrimitive.Description>
                ) : (
                  <DialogPrimitive.Description className="sr-only">{title}</DialogPrimitive.Description>
                )}
                {/* 鐵則 #6：彈出層內的滾動容器必須 data-lenis-prevent */}
                <div data-lenis-prevent className="mt-4 max-h-[60vh] overflow-y-auto">
                  {children}
                </div>
                <DialogPrimitive.Close asChild>
                  <button type="button" aria-label="關閉" className="absolute right-4 top-4 opacity-60 transition-opacity hover:opacity-100">
                    ✕
                  </button>
                </DialogPrimitive.Close>
              </motion.div>
            </DialogPrimitive.Content>
          </DialogPrimitive.Portal>
        )}
      </AnimatePresence>
    </DialogPrimitive.Root>
  )
}
```

同模式適用 Radix 的 Popover / Tooltip / Toast / DropdownMenu——
任何要 exit 動畫的 Radix 元件都是這三件套。

### Motion 互動小抄（hover / tap 屬於 Motion，不要用 GSAP）

```tsx
import { motion } from 'motion/react'

export function CtaButton({ label }: { label: string }) {
  return (
    <motion.button
      type="button"
      className="rounded-full bg-indigo-500 px-6 py-3 text-white"
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.97 }}
      transition={{ type: 'spring', stiffness: 400, damping: 25 }}
    >
      {label}
    </motion.button>
  )
}
```

## B. Anime.js v4 × Three：相機飛行

原則：**直接操作 Three 物件屬性（`camera.position`），不經 React state**——
動畫每 frame 改值，走 React 會每 frame re-render。
`storyPhase` 是低頻值，用 `subscribe` 監聽即可（高頻值才禁止訂閱，見 state-bridge.md）。

```tsx
// src/components/three/CameraRig.tsx
import { useEffect, useRef } from 'react'
import { useThree } from '@react-three/fiber'
import { animate } from 'animejs'
import { useAppStore, type StoryPhase } from '../../stores/useAppStore'

const CAMERA_TARGETS: Record<StoryPhase, { x: number; y: number; z: number }> = {
  intro: { x: 0, y: 0, z: 5 },
  build: { x: 3, y: 1.5, z: 4 },
  reveal: { x: 0, y: 4, z: 8 },
}

export function CameraRig() {
  const camera = useThree((state) => state.camera)
  const flightRef = useRef<ReturnType<typeof animate> | null>(null)

  useEffect(() => {
    // mount 時先同步到「目前」phase——subscribe 只在變化時觸發，
    // 若掛載當下 storyPhase 已不是初始值（lazy mount、route 切換、HMR），
    // 少了這段相機會卡在 Canvas 預設位置直到下一次 phase 變化
    const current = CAMERA_TARGETS[useAppStore.getState().storyPhase]
    camera.position.set(current.x, current.y, current.z)
    camera.lookAt(0, 0, 0)

    const unsubscribe = useAppStore.subscribe((state, prev) => {
      if (state.storyPhase === prev.storyPhase) return
      const target = CAMERA_TARGETS[state.storyPhase]

      flightRef.current?.pause() // 中斷上一段飛行，避免兩段動畫搶同一個相機（鐵則 #4）
      flightRef.current = animate(camera.position, {
        x: target.x,
        y: target.y,
        z: target.z,
        duration: 1200,
        ease: 'inOutQuad',
        onUpdate: () => camera.lookAt(0, 0, 0),
      })
    })

    return () => {
      unsubscribe()
      flightRef.current?.pause()
    }
  }, [camera])

  return null
}
```

注意：若 Canvas 設了 `frameloop="demand"`，Anime.js 在 R3F 體系外改值
**不會觸發重繪**——`onUpdate` 內要多呼叫 `invalidate()`
（`useThree((s) => s.invalidate)`），本節與下一節的範例都適用。
預設 frameloop 不受影響。

## C. Anime.js v4 × Three：材質 emissive 脈衝（createTimeline）

```tsx
// src/components/three/PulsingCore.tsx
import { useEffect, useRef } from 'react'
import { createTimeline } from 'animejs'
import type { Mesh, MeshStandardMaterial } from 'three'

export function PulsingCore() {
  const meshRef = useRef<Mesh>(null)

  useEffect(() => {
    const mesh = meshRef.current
    if (!mesh) return
    const material = mesh.material as MeshStandardMaterial

    // 直接動材質與 scale，不經 React state
    const timeline = createTimeline({ loop: true, defaults: { ease: 'inOutSine' } })
    timeline
      .add(material, { emissiveIntensity: { from: 0.2, to: 2.4 }, duration: 900 })
      .add(mesh.scale, { x: 1.05, y: 1.05, z: 1.05, duration: 900 }, '-=900')
      .add(material, { emissiveIntensity: 0.2, duration: 1400 })
      .add(mesh.scale, { x: 1, y: 1, z: 1, duration: 1400 }, '-=1400')

    return () => timeline.revert()
  }, [])

  return (
    <mesh ref={meshRef}>
      <icosahedronGeometry args={[1, 1]} />
      {/* emissiveIntensity 峰值 2.4 配 Bloom luminanceThreshold 0.9：只有脈衝高峰發光 */}
      <meshStandardMaterial color="#1e1b4b" emissive="#818cf8" emissiveIntensity={0.2} />
    </mesh>
  )
}
```

## D. Anime.js v4：SVG 描邊

```tsx
// src/components/ui/SignatureStroke.tsx
import { useEffect, useRef } from 'react'
import { animate, svg } from 'animejs'

export function SignatureStroke() {
  const pathRef = useRef<SVGPathElement>(null)

  useEffect(() => {
    if (!pathRef.current) return
    const animation = animate(svg.createDrawable(pathRef.current), {
      draw: ['0 0', '0 1'], // 從不可見描到全長
      duration: 1800,
      ease: 'inOutQuad',
    })
    return () => animation.revert()
  }, [])

  return (
    <svg viewBox="0 0 240 80" className="h-20 w-60" aria-hidden>
      <path
        ref={pathRef}
        d="M10 60 C 60 10, 120 90, 230 30"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      />
    </svg>
  )
}
```

## E. prefers-reduced-motion：各引擎落地（鐵則 #9）

> 原則：偵測到「減少動態」時，**不是把動畫停成空白，而是落地到有意義的靜止終態**——
> 該顯示的資訊、該到位的相機/材質都在最終狀態呈現，只是不動。

**Motion**——`useReducedMotion` 給無位移變體，時長歸零：

```tsx
import { useReducedMotion } from 'motion/react'

function Reveal({ children }: { children: React.ReactNode }) {
  const reduce = useReducedMotion()
  return (
    <motion.div
      initial={reduce ? { opacity: 0 } : { opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: reduce ? 0 : 0.6, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  )
}
```

**GSAP**——用 `gsap.matchMedia()`，reduce 分支把 timeline 直接定格終態：

```tsx
useGSAP(() => {
  const mm = gsap.matchMedia()
  mm.add('(prefers-reduced-motion: no-preference)', () => {
    // 完整 ScrollTrigger scrub 動畫
  })
  mm.add('(prefers-reduced-motion: reduce)', () => {
    gsap.set('.story-title', { opacity: 1, yPercent: 0 }) // 直接到終態
  })
}, { scope: sectionRef })
```

**R3F**——`useReducedMotion` 為真就 `frameloop="never"`，掛載後 `invalidate()` 渲染一次終態相機/材質；驅動用的 Anime.js timeline 直接 `.seek(duration)` 到終點再停。

**Anime.js**——`matchMedia('(prefers-reduced-motion: reduce)').matches` 命中就跳過 `createTimeline`，直接對目標設終值（相機位置、`emissiveIntensity`、SVG `strokeDashoffset: 0`）。

**delta 夾限（所有 RAF 迴圈通用）**——分頁切走再回來時 `delta` 會累積成一大跳，動畫瞬移一格。useFrame 與 gsap.ticker 同理，讀到的 delta 一律夾上限：

```tsx
useFrame((_, delta) => {
  const dt = Math.min(delta, 0.05) // 夾在 ~20fps 一格內，防 tab 切換爆衝
  rig.current.position.x += (target - rig.current.position.x) * dt * 4
})
```

## 選錯引擎的訊號

- 在 React 元件上手刻 `animate(ref.current, …)` 做 hover → 應該用 Motion 的 `whileHover`。
- 用 Motion 的 `useScroll` 做 pin/scrub → 應該用 GSAP ScrollTrigger（見 scroll-system.md）。
- 用 `useFrame` 手寫 lerp 逼近目標值 → 一次性的數值過渡應該交給 Anime.js，
  `useFrame` 留給「每 frame 都依輸入重算」的連續映射（見 state-bridge.md）。
