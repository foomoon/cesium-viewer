<script setup>
import { computed, onBeforeUnmount, ref } from 'vue'
import CesiumGlobe from './components/CesiumGlobe.vue'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import {
  Plane,
  Ship,
  Satellite,
  Navigation,
  Circle,
} from 'lucide-vue-next'

const trajectories = ref([
  {
    id: 'atlantic-hop',
    name: 'Atlantic hop',
    type: 'air',
    positions: [
      { lat: 40.6413, lon: -73.7781, height: 0, marker: 'start' },
      { lat: 46.5, lon: -45, height: 11000, marker: 'waypoint' },
      { lat: 51.47, lon: -0.4543, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'pacific-arc',
    name: 'Pacific arc',
    type: 'air',
    positions: [
      { lat: 37.6189, lon: -122.375, height: 0, marker: 'start' },
      { lat: 45.5, lon: -160, height: 12500, marker: 'waypoint' },
      { lat: 42.2, lon: 170, height: 12500, marker: 'waypoint' },
      { lat: 35.5494, lon: 139.7798, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'andes-traverse',
    name: 'Andes traverse',
    type: 'air',
    positions: [
      { lat: -33.4489, lon: -70.6693, height: 0, marker: 'start' },
      { lat: -20.5, lon: -68.3, height: 9000, marker: 'waypoint' },
      { lat: -13.5319, lon: -71.9675, height: 4500, marker: 'waypoint' },
      { lat: -3.99, lon: -79.2, height: 9000, marker: 'waypoint' },
      { lat: 6.207, lon: -75.575, height: 800, marker: 'end' },
    ],
  },
  {
    id: 'arctic-bridge',
    name: 'Arctic bridge',
    type: 'air',
    positions: [
      { lat: 64.1265, lon: -21.8174, height: 0, marker: 'start' },
      { lat: 75, lon: -30, height: 10500, marker: 'waypoint' },
      { lat: 68.707, lon: 33.55, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'med-corridor',
    name: 'Mediterranean corridor',
    type: 'naval',
    positions: [
      { lat: 36.8987, lon: 30.7133, height: 0, marker: 'start' },
      { lat: 38.5, lon: 15, height: 9500, marker: 'waypoint' },
      { lat: 41.3851, lon: 2.1734, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'sahara-link',
    name: 'Sahara link',
    type: 'ground',
    positions: [
      { lat: 31.6295, lon: -7.9811, height: 0, marker: 'start' },
      { lat: 20.5, lon: 13.0, height: 10500, marker: 'waypoint' },
      { lat: 12.9716, lon: 77.5946, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'austral-loop',
    name: 'Austral loop',
    type: 'air',
    positions: [
      { lat: -37.8136, lon: 144.9631, height: 0, marker: 'start' },
      { lat: -46, lon: 160, height: 11000, marker: 'waypoint' },
      { lat: -36.8485, lon: 174.7633, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'baltic-run',
    name: 'Baltic run',
    type: 'naval',
    positions: [
      { lat: 59.437, lon: 24.7536, height: 0, marker: 'start' },
      { lat: 57.7, lon: 19.0, height: 8000, marker: 'waypoint' },
      { lat: 55.6761, lon: 12.5683, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'polar-sweep',
    name: 'Polar sweep',
    type: 'air',
    positions: [
      { lat: 64.2008, lon: -149.4937, height: 0, marker: 'start' },
      { lat: 70.0, lon: -50.0, height: 11000, marker: 'waypoint' },
      { lat: 78.2232, lon: 15.6469, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'southern-arc',
    name: 'Southern arc',
    type: 'air',
    positions: [
      { lat: -12.4634, lon: 130.8456, height: 0, marker: 'start' },
      { lat: -25.0, lon: 140.0, height: 10500, marker: 'waypoint' },
      { lat: -33.8688, lon: 151.2093, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'andean-ridge',
    name: 'Andean ridge',
    type: 'ground',
    positions: [
      { lat: -20.1619, lon: -70.1322, height: 0, marker: 'start' },
      { lat: -15.5, lon: -71.0, height: 7500, marker: 'waypoint' },
      { lat: -12.0464, lon: -77.0428, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'balkan-bridge',
    name: 'Balkan bridge',
    type: 'air',
    positions: [
      { lat: 45.815, lon: 15.9819, height: 0, marker: 'start' },
      { lat: 43.8563, lon: 18.4131, height: 9000, marker: 'waypoint' },
      { lat: 41.9973, lon: 21.428, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'caribbean-thread',
    name: 'Caribbean thread',
    type: 'naval',
    positions: [
      { lat: 18.4655, lon: -66.1057, height: 0, marker: 'start' },
      { lat: 16.3064, lon: -61.084, height: 0, marker: 'waypoint' },
      { lat: 14.6415, lon: -61.0242, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'north-sea-loop',
    name: 'North Sea loop',
    type: 'naval',
    positions: [
      { lat: 53.4808, lon: -2.2426, height: 0, marker: 'start' },
      { lat: 55.95, lon: 3.0, height: 0, marker: 'waypoint' },
      { lat: 57.7089, lon: 11.9746, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'steppe-corridor',
    name: 'Steppe corridor',
    type: 'ground',
    positions: [
      { lat: 50.4501, lon: 30.5234, height: 0, marker: 'start' },
      { lat: 48.708, lon: 44.513, height: 0, marker: 'waypoint' },
      { lat: 43.2389, lon: 76.8897, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'sundarbans-sprint',
    name: 'Sundarbans sprint',
    type: 'ground',
    positions: [
      { lat: 22.5726, lon: 88.3639, height: 0, marker: 'start' },
      { lat: 21.5, lon: 90.0, height: 0, marker: 'waypoint' },
      { lat: 23.8103, lon: 90.4125, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'island-chain',
    name: 'Island chain',
    type: 'air',
    positions: [
      { lat: 25.7617, lon: -80.1918, height: 0, marker: 'start' },
      { lat: 19.8968, lon: -155.5828, height: 11500, marker: 'waypoint' },
      { lat: 21.3069, lon: -157.8583, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'saharan-band',
    name: 'Saharan band',
    type: 'air',
    positions: [
      { lat: 14.7167, lon: -17.4677, height: 0, marker: 'start' },
      { lat: 19.0, lon: 13.0, height: 11500, marker: 'waypoint' },
      { lat: 30.0444, lon: 31.2357, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'black-sea-arc',
    name: 'Black Sea arc',
    type: 'naval',
    positions: [
      { lat: 41.0082, lon: 28.9784, height: 0, marker: 'start' },
      { lat: 42.6983, lon: 27.2167, height: 0, marker: 'waypoint' },
      { lat: 44.4328, lon: 26.1043, height: 0, marker: 'waypoint' },
      { lat: 45.4642, lon: 28.777, height: 10000, marker: 'end' },
    ],
  },
  {
    id: 'pacific-hinge',
    name: 'Pacific hinge',
    type: 'air',
    positions: [
      { lat: 47.6062, lon: -122.3321, height: 0, marker: 'start' },
      { lat: 55.0, lon: 170.0, height: 12000, marker: 'waypoint' },
      { lat: 35.6762, lon: 139.6503, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'andes-to-atlantic',
    name: 'Andes to Atlantic',
    type: 'ground',
    positions: [
      { lat: -34.6037, lon: -58.3816, height: 0, marker: 'start' },
      { lat: -27.0, lon: -48.6, height: 0, marker: 'waypoint' },
      { lat: -22.9068, lon: -43.1729, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'pan-arabian',
    name: 'Pan Arabian',
    type: 'ground',
    positions: [
      { lat: 24.7136, lon: 46.6753, height: 0, marker: 'start' },
      { lat: 29.3759, lon: 47.9774, height: 0, marker: 'waypoint' },
      { lat: 33.3152, lon: 44.3661, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'nordic-dash',
    name: 'Nordic dash',
    type: 'air',
    positions: [
      { lat: 60.1699, lon: 24.9384, height: 0, marker: 'start' },
      { lat: 64.1265, lon: -21.8174, height: 10500, marker: 'waypoint' },
      { lat: 59.9139, lon: 10.7522, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'baltic-thread',
    name: 'Baltic thread',
    type: 'naval',
    positions: [
      { lat: 59.3293, lon: 18.0686, height: 0, marker: 'start' },
      { lat: 58.3776, lon: 24.7474, height: 0, marker: 'waypoint' },
      { lat: 59.9133, lon: 10.739, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'red-sea-run',
    name: 'Red Sea run',
    type: 'naval',
    positions: [
      { lat: 29.5521, lon: 34.9519, height: 0, marker: 'start' },
      { lat: 25.4, lon: 36.0, height: 0, marker: 'waypoint' },
      { lat: 21.4858, lon: 39.1925, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'great-plains-pass',
    name: 'Great Plains pass',
    type: 'ground',
    positions: [
      { lat: 39.7392, lon: -104.9903, height: 0, marker: 'start' },
      { lat: 41.2572, lon: -95.9951, height: 0, marker: 'waypoint' },
      { lat: 44.9778, lon: -93.265, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'maritime-seam',
    name: 'Maritime seam',
    type: 'naval',
    positions: [
      { lat: 1.3521, lon: 103.8198, height: 0, marker: 'start' },
      { lat: 5.0, lon: 112.0, height: 0, marker: 'waypoint' },
      { lat: 7.9519, lon: 98.3381, height: 0, marker: 'end' },
    ],
  },
  {
    id: 'pacific-ridge',
    name: 'Pacific ridge',
    type: 'air',
    positions: [
      { lat: 34.0522, lon: -118.2437, height: 0, marker: 'start' },
      { lat: 45.0, lon: -150.0, height: 12500, marker: 'waypoint' },
      { lat: 35.6895, lon: 139.6917, height: 0, marker: 'end' },
    ],
  },
])

const selectedTrajectoryId = ref(trajectories.value[0].id)
const selectedCoordinate = ref(null)
const globeRef = ref(null)
const coordinateOverlayVisible = ref(false)
let overlayTimer = null
const useOfflineMap = ref(false)

const iconByType = {
  air: Plane,
  naval: Ship,
  space: Satellite,
  ground: Navigation,
}

const getIcon = (type) => iconByType[type] || Circle
const waypointCount = (trajectory) =>
  trajectory.positions.filter((p) => p.marker === 'waypoint').length

const activeTrajectory = computed(() =>
  trajectories.value.find((t) => t.id === selectedTrajectoryId.value),
)

const handleCoordinateSelected = (coord) => {
  selectedCoordinate.value = coord
  coordinateOverlayVisible.value = true
  if (overlayTimer) {
    clearTimeout(overlayTimer)
  }
  overlayTimer = setTimeout(() => {
    coordinateOverlayVisible.value = false
  }, 4500)
}

const resetCamera = () => globeRef.value?.resetView?.()

const toggleMapMode = () => {
  useOfflineMap.value = !useOfflineMap.value
}

onBeforeUnmount(() => {
  if (overlayTimer) {
    clearTimeout(overlayTimer)
  }
})
</script>

<template>
  <div class="min-h-screen bg-white/90">
    <div class="mx-auto flex w-full flex-col gap-6 px-6 pb-10 pt-8 lg:px-10">
      <header class="flex flex-wrap items-center justify-between gap-4">
        <div class="space-y-2">
          <p class="text-xs uppercase tracking-[0.25em] text-slate-500">
            Cesium baseline
          </p>
          <h1 class="text-3xl font-semibold text-slate-900 lg:text-4xl">
            Atlas Nexus
          </h1>
          <p class="max-w-2xl text-sm text-slate-600">
            A focused Cesium canvas for engineers and mission teams. Click to
            sample coordinates, toggle between tracks, and keep multiple
            trajectories visible at once.
          </p>
        </div>
        <div class="flex items-center gap-2">
          <Button variant="outline" size="sm" @click="toggleMapMode">
            Map: {{ useOfflineMap ? 'Offline' : 'Default' }}
          </Button>
          <Button variant="outline" size="sm" @click="resetCamera">
            Reset view
          </Button>
        </div>
      </header>

      <div class="grid gap-6 lg:grid-cols-[380px_1fr] xl:grid-cols-[420px_1fr]">
        <div class="space-y-4">
          <Card class="border border-slate-200/60 shadow-sm backdrop-blur-sm">
            <CardHeader>
              <CardTitle class="text-lg">Trajectories</CardTitle>
              <CardDescription>
                All paths are rendered on the globe. Click a row to set the
                active path; selected is highlighted, others are muted.
              </CardDescription>
            </CardHeader>
            <CardContent class="space-y-3 h-[calc(100vh-360px)] overflow-y-auto pr-1">
              <div
                v-for="trajectory in trajectories"
                :key="trajectory.id"
                role="button"
                tabindex="0"
                class="flex cursor-pointer items-center justify-between gap-3 rounded-xl border border-slate-100 px-3 py-2 transition hover:border-slate-300 hover:bg-white"
                :class="{
                  'border-slate-300 bg-white shadow-sm':
                    selectedTrajectoryId === trajectory.id,
                }"
                @click="selectedTrajectoryId = trajectory.id"
                @keydown.enter.prevent="selectedTrajectoryId = trajectory.id"
                @keydown.space.prevent="selectedTrajectoryId = trajectory.id"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="flex h-9 w-9 items-center justify-center rounded-full border border-slate-200 bg-white/80 text-slate-600"
                  >
                    <component
                      :is="getIcon(trajectory.type)"
                      class="h-4 w-4"
                      aria-hidden="true"
                    />
                  </div>
                  <span
                    class="h-2 w-12 rounded-full"
                    :style="{ backgroundColor: trajectory.color || '#2563eb' }"
                  />
                  <div>
                    <p class="text-sm font-semibold text-slate-900">
                      {{ trajectory.name }}
                    </p>
                    <p class="text-xs text-slate-500">
                      {{ waypointCount(trajectory) }} waypoints ·
                      {{ trajectory.type || 'other' }}
                    </p>
                  </div>
                </div>
                <span
                  v-if="selectedTrajectoryId === trajectory.id"
                  class="text-[10px] uppercase tracking-[0.2em] text-slate-500"
                >
                  Active
                </span>
              </div>
            </CardContent>
          </Card>
        </div>

        <div
          class="relative h-[calc(100vh-220px)] min-h-[640px] w-full overflow-hidden rounded-3xl border border-slate-200/70 bg-gradient-to-b from-slate-950 to-slate-900 shadow-2xl"
        >
          <CesiumGlobe
            ref="globeRef"
            class="h-full"
            :trajectories="trajectories"
            :selected-trajectory-id="selectedTrajectoryId"
            :use-offline-map="useOfflineMap"
            @coordinate-selected="handleCoordinateSelected"
          />
          <div
            v-if="activeTrajectory"
            class="pointer-events-none absolute right-6 top-6 flex flex-col gap-2 text-white"
          >
            <div
              class="rounded-2xl border border-white/10 bg-white/10 px-4 py-3 backdrop-blur"
            >
              <p class="text-[11px] uppercase tracking-[0.25em] text-white/70">
                Active trajectory
              </p>
              <div class="mt-2 space-y-1">
                <p class="text-lg font-semibold">
                  {{ activeTrajectory.name }}
                </p>
                <p class="text-xs uppercase tracking-[0.2em] text-white/70">
                  {{ activeTrajectory.type || 'unspecified' }}
                  · {{ activeTrajectory.positions.length }} control points
                </p>
              </div>
            </div>
          </div>
          <div
            v-if="selectedCoordinate"
            class="pointer-events-none absolute left-6 top-6 flex flex-col gap-2 text-white"
            :class="coordinateOverlayVisible ? 'opacity-100' : 'opacity-0'"
            style="transition: opacity 400ms ease"
          >
            <div
              class="rounded-2xl border border-white/10 bg-white/10 px-4 py-3 backdrop-blur"
            >
              <p class="text-[11px] uppercase tracking-[0.25em] text-white/70">
                Selected position
              </p>
              <div class="mt-2 grid grid-cols-2 gap-4 text-sm">
                <div class="space-y-1">
                  <p class="text-[11px] uppercase tracking-[0.2em] text-white/70">
                    Latitude
                  </p>
                  <p class="text-lg font-semibold">
                    {{ selectedCoordinate.lat?.toFixed(4) }}°
                  </p>
                </div>
                <div class="space-y-1">
                  <p class="text-[11px] uppercase tracking-[0.2em] text-white/70">
                    Longitude
                  </p>
                  <p class="text-lg font-semibold">
                    {{ selectedCoordinate.lon?.toFixed(4) }}°
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
