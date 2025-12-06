<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import * as Cesium from 'cesium'

const props = defineProps({
  trajectories: {
    type: Array,
    default: () => [],
  },
  selectedTrajectoryId: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['coordinate-selected'])

const containerRef = ref(null)
const viewerRef = ref(null)
const handlerRef = ref(null)
const trajectoryEntities = new Map()

const createViewer = () => {
  if (!containerRef.value) return

  viewerRef.value = new Cesium.Viewer(containerRef.value, {
    animation: false,
    baseLayerPicker: false,
    fullscreenButton: false,
    geocoder: false,
    homeButton: false,
    infoBox: false,
    navigationHelpButton: false,
    sceneModePicker: false,
    selectionIndicator: false,
    timeline: false,
    vrButton: false,
    navigationInstructionsInitiallyVisible: false,
  })

  viewerRef.value.scene.globe.enableLighting = true
  viewerRef.value.scene.globe.showGroundAtmosphere = true
  viewerRef.value.scene.globe.depthTestAgainstTerrain = true
  viewerRef.value.scene.globe.minimumZoomDistance = 500000
  viewerRef.value.cesiumWidget.creditContainer.style.display = 'none'

  setClickHandler()
  resetView()
  syncTrajectories(props.trajectories)
  highlightSelected(props.selectedTrajectoryId)
}

const resetView = () => {
  if (!viewerRef.value) return
  viewerRef.value.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(-98.5795, 39.8283, 2500000),
    duration: 1.4,
  })
}

const setClickHandler = () => {
  if (!viewerRef.value) return
  handlerRef.value = new Cesium.ScreenSpaceEventHandler(
    viewerRef.value.scene.canvas,
  )
  handlerRef.value.setInputAction(
    (movement) => {
      const scene = viewerRef.value.scene
      const picked =
        scene.pickPosition(movement.position) ||
        viewerRef.value.camera.pickEllipsoid(
          movement.position,
          scene.globe.ellipsoid,
        )

      if (!picked) return
      const cartographic = Cesium.Cartographic.fromCartesian(picked)
      emit('coordinate-selected', {
        lat: Cesium.Math.toDegrees(cartographic.latitude),
        lon: Cesium.Math.toDegrees(cartographic.longitude),
        height: cartographic.height,
      })
    },
    Cesium.ScreenSpaceEventType.LEFT_CLICK,
  )
}

const syncTrajectories = (list) => {
  if (!viewerRef.value) return
  const ids = new Set(list.map((item) => item.id))

  for (const [id, entity] of trajectoryEntities.entries()) {
    if (!ids.has(id)) {
      viewerRef.value.entities.remove(entity)
      trajectoryEntities.delete(id)
    }
  }

  list.forEach((item) => {
    const positions = Cesium.Cartesian3.fromDegreesArrayHeights(
      item.positions.flatMap((p) => [p.lon, p.lat, p.height ?? 0]),
    )
    const color = Cesium.Color.fromCssColorString(
      item.color || '#2563eb',
    ).withAlpha(0.9)
    const material = new Cesium.ColorMaterialProperty(color)
    const width = item.id === props.selectedTrajectoryId ? 4 : 2.5

    if (trajectoryEntities.has(item.id)) {
      const entity = trajectoryEntities.get(item.id)
      entity.polyline.positions = positions
      entity.polyline.material = material
      entity.polyline.width = width
    } else {
      const entity = viewerRef.value.entities.add({
        id: item.id,
        polyline: {
          positions,
          material,
          width,
          clampToGround: false,
          arcType: Cesium.ArcType.GEODESIC,
        },
      })
      trajectoryEntities.set(item.id, entity)
    }
  })
}

const highlightSelected = async (selectedId) => {
  if (!viewerRef.value) return
  trajectoryEntities.forEach((entity, id) => {
    if (!entity.polyline) return
    const isActive = id === selectedId
    entity.polyline.width = isActive ? 4 : 2.5
    const current = entity.polyline.material
    if (
      current instanceof Cesium.ColorMaterialProperty &&
      current.color instanceof Cesium.ConstantProperty
    ) {
      const baseColor = current.color.getValue(Cesium.JulianDate.now())
      const adjusted = isActive
        ? Cesium.Color.clone(baseColor).brighten(0.15, new Cesium.Color())
        : Cesium.Color.clone(baseColor).withAlpha(0.9)
      current.color = new Cesium.ConstantProperty(adjusted)
    }
  })

  if (selectedId && trajectoryEntities.has(selectedId)) {
    const entity = trajectoryEntities.get(selectedId)
    await viewerRef.value.flyTo(entity, {
      duration: 1.2,
    })
  }
}

onMounted(() => {
  createViewer()
})

onBeforeUnmount(() => {
  handlerRef.value?.destroy?.()
  if (viewerRef.value && !viewerRef.value.isDestroyed()) {
    viewerRef.value.entities.removeAll()
    viewerRef.value.destroy()
  }
})

watch(
  () => props.trajectories,
  (next) => syncTrajectories(next),
  { deep: true },
)

watch(
  () => props.selectedTrajectoryId,
  (next) => highlightSelected(next),
)

defineExpose({ resetView })
</script>

<template>
  <div class="relative h-full w-full overflow-hidden rounded-2xl border">
    <div ref="containerRef" class="h-full w-full bg-slate-900/40" />
    <div
      class="pointer-events-none absolute left-4 top-4 z-10 rounded-full bg-white/80 px-4 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-slate-700 shadow-sm backdrop-blur"
    >
      Click to sample coordinates
    </div>
  </div>
</template>
