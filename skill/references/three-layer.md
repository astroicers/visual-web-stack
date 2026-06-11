# 3D 層（R3F + Drei + 後處理）

> 適用：鋪 Canvas、選 Drei 工具、配後處理管線、做效能降級。
>
> 對應鐵則：#5（dpr=[1,2]、antialias: false）。

## Canvas 佈局：fixed 鋪底

Canvas 固定鋪滿視窗、墊在最底層；DOM 內容（`relative z-10`）疊在上面滾動。
滾動的是 DOM，Canvas 永遠不動——3D 的「滾動感」來自 store 裡的
`scrollProgress` / `storyPhase` 驅動相機與物件（見 state-bridge.md）。

```tsx
// src/components/three/ThreeLayer.tsx
import { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { Scene } from './Scene'
import { Effects } from './Effects'

export function ThreeLayer() {
  return (
    <div className="fixed inset-0 z-0" aria-hidden>
      <Canvas
        dpr={[1, 2]} // 鐵則 #5：上限 2，高密度螢幕不爆 GPU
        gl={{ antialias: false, powerPreference: 'high-performance' }} // 抗鋸齒交給 SMAA
        camera={{ position: [0, 0, 5], fov: 45 }}
      >
        <Suspense fallback={null}>
          <Scene />
        </Suspense>
        <Effects />
      </Canvas>
    </div>
  )
}
```

## 場景骨架

```tsx
// src/components/three/Scene.tsx
import { ContactShadows, Environment, useGLTF } from '@react-three/drei'
import { CameraRig } from './CameraRig'

function HeroModel() {
  const { scene } = useGLTF('/models/hero.glb')
  return <primitive object={scene} position={[0, -0.5, 0]} />
}
useGLTF.preload('/models/hero.glb') // 模組載入即開始抓模型，避免進場才載（閃白）

export function Scene() {
  return (
    <>
      <ambientLight intensity={0.4} />
      <directionalLight position={[3, 4, 5]} intensity={1.2} />
      {/* 若採用 ui-theming.md 的 ThemedStage，刪掉這行——
          一個場景只能有一個 Environment，後掛載的會覆寫前者的 scene.environment */}
      <Environment preset="city" />
      <HeroModel />
      <ContactShadows position={[0, -0.5, 0]} opacity={0.5} blur={2.4} far={4} />
      <CameraRig /> {/* Anime.js 相機飛行，見 animation-recipes.md */}
    </>
  )
}
```

主題連動（背景色、Environment preset 跟 dark/light 切換）見
[ui-theming.md](ui-theming.md)。

## Drei 常用工具對照

| 工具 | 用途 | 備註 |
|------|------|------|
| `Environment` | IBL 環境光＋（可選）背景 | 用 `preset` 快速起步；正式上線改自架 HDR 避免 CDN 依賴 |
| `useGLTF` | 載入 glTF/GLB | 一定搭 `useGLTF.preload()`；模型先用 gltf-transform 壓過（見 pitfalls.md） |
| `Text` | SDF 高品質 3D 文字 | 比 TextGeometry 輕；字型檔記得子集化 |
| `ContactShadows` | 接觸陰影 | 免實體地板、免 shadow map，視覺系場景的高 CP 值選擇 |
| `useProgress` | 載入進度 | DOM 端也能用，做 loading 畫面（下方範例） |
| `PerformanceMonitor` | FPS 監測 | 降級鏈的觸發器（下方範例） |

### Loading 畫面（useProgress 在 DOM 端使用）

```tsx
// src/components/ui/LoadingGate.tsx
import { useProgress } from '@react-three/drei'
import { AnimatePresence, motion } from 'motion/react'

export function LoadingGate() {
  const { progress, active } = useProgress()

  return (
    <AnimatePresence>
      {active && (
        <motion.div
          className="fixed inset-0 z-50 grid place-items-center bg-zinc-950 text-zinc-100"
          exit={{ opacity: 0, transition: { duration: 0.5 } }}
        >
          <p className="text-sm tabular-nums">{Math.round(progress)}%</p>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
```

## 後處理管線（完整實作，含降級鏈）

順序固定：**SMAA → Bloom → ChromaticAberration → Noise → Vignette**。
SMAA 要在最前（對乾淨畫面抗鋸齒），Vignette 在最後（壓整體畫面邊緣）。
Bloom 的 `luminanceThreshold` 必須 **≥ 0.8**，只讓真正的高光發光（見 pitfalls.md
「Bloom 過曝」）。

PerformanceMonitor 降級鏈（FPS 不足時逐級執行，不回升，行為可預測）：

1. 關 ChromaticAberration ＋ Noise（最貴的全屏 pass，視覺損失最小）
2. 關 Bloom
3. 降 DPR 到 1

```tsx
// src/components/three/Effects.tsx
import { useMemo, useState } from 'react'
import { Vector2 } from 'three'
import { useThree } from '@react-three/fiber'
import { PerformanceMonitor } from '@react-three/drei'
import {
  Bloom,
  ChromaticAberration,
  EffectComposer,
  Noise,
  SMAA,
  Vignette,
} from '@react-three/postprocessing'

export function Effects() {
  // 0=全開 1=關色差+Noise 2=再關 Bloom 3=再降 DPR
  const [level, setLevel] = useState(0)
  const setDpr = useThree((state) => state.setDpr)
  const chromaOffset = useMemo(() => new Vector2(0.0012, 0.0012), [])

  const degrade = () =>
    setLevel((current) => {
      const next = Math.min(current + 1, 3)
      if (next === 3) setDpr(1)
      return next
    })

  // EffectComposer 的 children 型別是 JSX.Element | JSX.Element[]，
  // 不接受 {cond && <Effect/>} 產生的 false（TS2322）——用陣列組裝
  const effects: JSX.Element[] = [<SMAA key="smaa" />]
  if (level < 2) {
    effects.push(<Bloom key="bloom" mipmapBlur luminanceThreshold={0.9} intensity={0.7} />)
  }
  if (level < 1) {
    effects.push(
      // radialModulation / modulationOffset 在 v2 型別中是必填，少了過不了 tsc
      <ChromaticAberration key="ca" offset={chromaOffset} radialModulation={false} modulationOffset={0} />,
      <Noise key="noise" premultiply opacity={0.15} />,
    )
  }
  effects.push(<Vignette key="vignette" eskil={false} offset={0.15} darkness={0.85} />)

  return (
    <>
      <PerformanceMonitor onDecline={degrade} />
      <EffectComposer multisampling={0}>{effects}</EffectComposer>
    </>
  )
}
```

要點：

- `multisampling={0}`：已有 SMAA，MSAA 是重複花費。
- 降級會重建 composer，屬一次性成本，可接受；不要每 frame 改 effect 組成。
- 想要「FPS 恢復就升回去」可加 `onIncline`，但務必配 PerformanceMonitor 的
  `flipflops` 上限，否則臨界機器會無限震盪。預設建議：只降不升。
- 材質要能被 Bloom 點亮：`emissive` 色 ＋ `emissiveIntensity > 1`
  （配 `luminanceThreshold 0.9` 剛好只有它發光）。
