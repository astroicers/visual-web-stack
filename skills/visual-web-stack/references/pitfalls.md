# 地雷對照表與效能守則

> 適用：出現怪 bug、上線前效能檢查。先查表，再回對應 reference 看完整解法。

## 地雷對照表

| 症狀 | 原因 | 解法 |
|------|------|------|
| ScrollTrigger 觸發點漂移（越滾越不準） | Lenis 與 ScrollTrigger 各自跑 RAF，讀到過期的滾動值；或圖片／模型載入後撐開頁面高度 | `lenis.on('scroll', …)` 內呼叫 `ScrollTrigger.update()`、由 `gsap.ticker` 驅動 `lenis.raf`（鐵則 #1，scroll-system.md）；媒體元素固定尺寸或載入完成後呼叫 `ScrollTrigger.refresh()` |
| Dialog / Popover 關閉時瞬間消失，exit 動畫不播 | Radix 在 close 當下就卸載 DOM，Motion 來不及播 exit | forceMount ＋ AnimatePresence ＋ asChild 三件套（鐵則 #3，animation-recipes.md） |
| 滾動卡頓、FPS 驟降 | Lenis 沒交給 gsap.ticker、自己另跑 RAF；或元件 hook 訂閱了 scrollProgress 之類的高頻值，每 frame re-render | 滾動鏈路唯一 RAF＝gsap.ticker（鐵則 #1）；高頻值一律 `getState()` / `subscribe`（鐵則 #2，state-bridge.md） |
| Bloom 過曝，整個畫面白成一片 | `luminanceThreshold` 太低，普通亮度的像素全在發光 | `luminanceThreshold ≥ 0.8`（建議 0.9），要發光的材質用 `emissiveIntensity > 1` 點名（three-layer.md） |
| Dialog 內容滾不動 | Lenis 攔截了 wheel 事件 | 彈出層內的滾動容器加 `data-lenis-prevent`（鐵則 #6），並確認 main.tsx 有匯入 `lenis/dist/lenis.css`（官方樣式的 `overscroll-behavior: contain` 防止內層滾到底把整頁帶著滾） |
| pin 區段跳動、pin 結束位置錯亂 | pin 元素的 margin 參與排版；或動了 layout 屬性讓 ScrollTrigger 計算失準 | pin 元素不要帶 margin（外層包 wrapper）；動畫只動 transform/opacity（鐵則 #8）；多個 pin 依序宣告或用 `refreshPriority` |
| 主題切換後 3D 場景沒跟上 | 讀了 `theme`（系統模式下是 `"system"`）；或在 Canvas 內 `useTheme` 拿不到外層 context | 一律讀 `resolvedTheme`，且在 Canvas 外讀、以 prop 傳入（ui-theming.md） |
| 模型載入時閃白／場景突然彈出 | 模型沒 preload，Suspense 邊界外又沒有 loading 遮罩 | `useGLTF.preload()` ＋ `useProgress` 做 LoadingGate 遮罩，進度到 100% 才淡出（three-layer.md） |
| 程式化跳轉後位置錯亂、平滑失效 | 用了 `scrollIntoView`，繞過 Lenis 直接改了原生 scroll | 一律 `lenis.scrollTo()`（鐵則 #7，scroll-system.md） |
| 開發模式滾動異常、疑似兩個 Lenis | StrictMode 的 mount→cleanup→mount **不會**留下雙實例（cleanup 會 destroy）；真的出現兩個，幾乎都是掛了兩個 SmoothScroll | 全站只掛一個 SmoothScroll；provider 內建防呆會在 dev console 警告（scroll-system.md） |

## 效能守則

上線前逐條檢查：

1. **DPR 上限 2**：`<Canvas dpr={[1, 2]}>`（鐵則 #5）。3x 螢幕跑 3x DPR 是
   純浪費，肉眼差異趨近零、GPU 負擔多一倍以上。
2. **模型先壓再上**：gltf-transform 一條龍（幾何 Draco、貼圖 KTX2），
   **單模型 < 2MB**：

   ```bash
   npx @gltf-transform/cli optimize input.glb output.glb \
     --compress draco --texture-compress ktx2
   ```

3. **靜態場景用 `frameloop="demand"`**：畫面沒有持續動畫時，改
   `<Canvas frameloop="demand">`，有變化才 `invalidate()`。注意：滾動驅動的
   連續場景**不適用**——每個滾動事件都要 invalidate 等於沒省。另外，
   Anime.js 等在 R3F 體系外改 Three 物件的動畫（CameraRig、PulsingCore），
   demand 模式下不會觸發重繪，每個 `onUpdate` 都要呼叫 `invalidate()`，
   否則畫面凍住、動畫無聲無息地消失（animation-recipes.md）。
4. **字型子集化**：中文字型全量 woff2 動輒 5–10MB。標題字型用
   `glyphhanger` / `subfont` 只留用到的字；內文優先系統字。
5. **延後掛載 Canvas**：依 Canvas 的型態選對手段——
   - **鋪底主 Canvas（fixed 全螢幕，three-layer.md 的 ThreeLayer）**：
     IntersectionObserver 對它無效（錨點在版面裡沒有高度，且 fixed Canvas
     一掛載就蓋全視窗，跟「進視口」無關）。正確手段是「首屏 paint 完再掛」，
     讓首屏 DOM 先上、3D bundle 與初始化讓出主執行緒：

     ```tsx
     // src/components/three/DeferredThreeLayer.tsx
     import { Suspense, lazy, useEffect, useState } from 'react'

     const ThreeLayer = lazy(() =>
       import('./ThreeLayer').then((m) => ({ default: m.ThreeLayer })),
     )

     export function DeferredThreeLayer() {
       const [ready, setReady] = useState(false)

       useEffect(() => {
         // 雙重 rAF：保證至少完成一次首屏 paint 後才開始載 3D
         let raf2 = 0
         const raf1 = requestAnimationFrame(() => {
           raf2 = requestAnimationFrame(() => setReady(true))
         })
         return () => {
           cancelAnimationFrame(raf1)
           cancelAnimationFrame(raf2)
         }
       }, [])

       if (!ready) return null
       return (
         <Suspense fallback={null}>
           <ThreeLayer />
         </Suspense>
       )
     }
     ```

   - **區段內嵌 Canvas（非 fixed、只屬於某個 section）**：才用
     IntersectionObserver，錨點要有佔位高度，進視口前不掛載：

     ```tsx
     // src/components/sections/ShowcaseCanvas.tsx
     import { Suspense, useEffect, useRef, useState } from 'react'
     import { Canvas } from '@react-three/fiber'

     export function ShowcaseCanvas() {
       const anchorRef = useRef<HTMLDivElement>(null)
       const [visible, setVisible] = useState(false)

       useEffect(() => {
         const anchor = anchorRef.current
         if (!anchor) return
         const observer = new IntersectionObserver(
           ([entry]) => entry.isIntersecting && setVisible(true),
           { rootMargin: '200px' }, // 提前 200px 開始載，進視口時已就緒
         )
         observer.observe(anchor)
         return () => observer.disconnect()
       }, [])

       return (
         <div ref={anchorRef} className="h-[60vh]">
           {visible && (
             <Suspense fallback={null}>
               <Canvas dpr={[1, 2]} gl={{ antialias: false }}>
                 {/* 區段場景 */}
               </Canvas>
             </Suspense>
           )}
         </div>
       )
     }
     ```

6. **後處理降級鏈要真的接上**：PerformanceMonitor 的 onDecline 沒接，
   低階機器就是 10 FPS 看完整條 Bloom 管線（three-layer.md）。
7. **Leva 面板只在開發模式渲染**：`{import.meta.env.DEV && <Leva />}`，且面板是
   DOM 元件、必須掛在 Canvas 外（setup.md）。注意 leva 套件本身仍會進 bundle，
   條件渲染只是 production 不渲染面板。
