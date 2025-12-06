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
  useOfflineMap: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['coordinate-selected'])

const containerRef = ref(null)
const viewerRef = ref(null)
const handlerRef = ref(null)
const trajectoryEntities = new Map()
const defaultBaseLayer = Cesium.ImageryLayer.fromProviderAsync(
  Cesium.ArcGisMapServerImageryProvider.fromUrl(
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer',
    {},
  ),
)
const NaturalEarthIILayer = Cesium.ImageryLayer.fromProviderAsync(
  new Cesium.TileMapServiceImageryProvider({
    url: Cesium.buildModuleUrl('Assets/Textures/NaturalEarthII'),
    credit: '',
  }),
)

const getImageryProvider = (isDefault) =>
  isDefault ? NaturalEarthIILayer : defaultBaseLayer

const applyImageryProvider = (offline) => {
  if (!viewerRef.value) return
  const layers = viewerRef.value.imageryLayers
  const provider = getImageryProvider(offline)
  // layers.removeAll()
  layers.addImageryProvider(provider)
}

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
    // baseLayer: defaultBaseLayer,
    baseLayer: getImageryProvider(false),
  })

  console.log(Cesium.buildModuleUrl('Assets/Textures/NaturalEarthII'))

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
  handlerRef.value.setInputAction((movement) => {
    const scene = viewerRef.value.scene
    const cartesian =
      scene.pickPosition(movement.position) ||
      viewerRef.value.camera.pickEllipsoid(
        movement.position,
        scene.globe.ellipsoid,
      )

    if (!cartesian) return
    const cartographic = Cesium.Cartographic.fromCartesian(cartesian)
    emit('coordinate-selected', {
      lat: Cesium.Math.toDegrees(cartographic.latitude),
      lon: Cesium.Math.toDegrees(cartographic.longitude),
    })
  }, Cesium.ScreenSpaceEventType.LEFT_CLICK)
}

const getStyleFor = (id) => {
  const isActive = id === props.selectedTrajectoryId
  return {
    color: isActive ? '#2563eb' : '#94a3b8',
    width: isActive ? 4 : 2.5,
    alpha: isActive ? 1 : 0.5,
  }
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
    const { color, width, alpha } = getStyleFor(item.id)
    const material = new Cesium.ColorMaterialProperty(
      Cesium.Color.fromCssColorString(color).withAlpha(alpha),
    )

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
    const { color, width, alpha } = getStyleFor(id)
    entity.polyline.width = width
    entity.polyline.material = new Cesium.ColorMaterialProperty(
      Cesium.Color.fromCssColorString(color).withAlpha(alpha),
    )
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

watch(
  () => props.useOfflineMap,
  (next) => applyImageryProvider(next),
)

defineExpose({ resetView })
</script>

<template>
  <div class="relative h-full w-full overflow-hidden rounded-2xl border">
    <div ref="containerRef" class="h-full w-full bg-slate-900/40" />
  </div>
</template>
