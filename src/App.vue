<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { usePreferredDark, useStorage } from '@vueuse/core'
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
      { lat: 40.6413, lon: -73.7781, altitude: 0 },
      { lat: 46.5, lon: -45, altitude: 11000 },
      { lat: 51.47, lon: -0.4543, altitude: 0 },
    ],
    waypoints: [{ lat: 46.5, lon: -45, altitude: 11000 }],
  },
  {
    id: 'pacific-arc',
    name: 'Pacific arc',
    type: 'air',
    positions: [
      { lat: 37.6189, lon: -122.375, altitude: 0 },
      { lat: 45.5, lon: -160, altitude: 12500 },
      { lat: 42.2, lon: 170, altitude: 12500 },
      { lat: 35.5494, lon: 139.7798, altitude: 0 },
    ],
    waypoints: [
      { lat: 45.5, lon: -160, altitude: 12500 },
      { lat: 42.2, lon: 170, altitude: 12500 },
    ],
  },
  {
    id: 'andes-traverse',
    name: 'Andes traverse',
    type: 'air',
    positions: [
      { lat: -33.4489, lon: -70.6693, altitude: 0 },
      { lat: -20.5, lon: -68.3, altitude: 9000 },
      { lat: -13.5319, lon: -71.9675, altitude: 4500 },
      { lat: -3.99, lon: -79.2, altitude: 9000 },
      { lat: 6.207, lon: -75.575, altitude: 800 },
    ],
    waypoints: [
      { lat: -20.5, lon: -68.3, altitude: 9000 },
      { lat: -13.5319, lon: -71.9675, altitude: 4500 },
      { lat: -3.99, lon: -79.2, altitude: 9000 },
    ],
  },
  {
    id: 'arctic-bridge',
    name: 'Arctic bridge',
    type: 'air',
    positions: [
      { lat: 64.1265, lon: -21.8174, altitude: 0 },
      { lat: 75, lon: -30, altitude: 10500 },
      { lat: 68.707, lon: 33.55, altitude: 0 },
    ],
    waypoints: [{ lat: 75, lon: -30, altitude: 10500 }],
  },
  {
    id: 'med-corridor',
    name: 'Mediterranean corridor',
    type: 'naval',
    positions: [
      { lat: 36.8987, lon: 30.7133, altitude: 0 },
      { lat: 38.5, lon: 15, altitude: 9500 },
      { lat: 41.3851, lon: 2.1734, altitude: 0 },
    ],
    waypoints: [{ lat: 38.5, lon: 15, altitude: 9500 }],
  },
  {
    id: 'sahara-link',
    name: 'Sahara link',
    type: 'ground',
    positions: [
      { lat: 31.6295, lon: -7.9811, altitude: 0 },
      { lat: 20.5, lon: 13.0, altitude: 10500 },
      { lat: 12.9716, lon: 77.5946, altitude: 0 },
    ],
    waypoints: [{ lat: 20.5, lon: 13.0, altitude: 10500 }],
  },
  {
    id: 'austral-loop',
    name: 'Austral loop',
    type: 'air',
    positions: [
      { lat: -37.8136, lon: 144.9631, altitude: 0 },
      { lat: -46, lon: 160, altitude: 11000 },
      { lat: -36.8485, lon: 174.7633, altitude: 0 },
    ],
    waypoints: [{ lat: -46, lon: 160, altitude: 11000 }],
  },
  {
    id: 'baltic-run',
    name: 'Baltic run',
    type: 'naval',
    positions: [
      { lat: 59.437, lon: 24.7536, altitude: 0 },
      { lat: 57.7, lon: 19.0, altitude: 8000 },
      { lat: 55.6761, lon: 12.5683, altitude: 0 },
    ],
    waypoints: [{ lat: 57.7, lon: 19.0, altitude: 8000 }],
  },
  {
    id: 'polar-sweep',
    name: 'Polar sweep',
    type: 'air',
    positions: [
      { lat: 64.2008, lon: -149.4937, altitude: 0 },
      { lat: 70.0, lon: -50.0, altitude: 11000 },
      { lat: 78.2232, lon: 15.6469, altitude: 0 },
    ],
    waypoints: [{ lat: 70.0, lon: -50.0, altitude: 11000 }],
  },
  {
    id: 'southern-arc',
    name: 'Southern arc',
    type: 'air',
    positions: [
      { lat: -12.4634, lon: 130.8456, altitude: 0 },
      { lat: -25.0, lon: 140.0, altitude: 10500 },
      { lat: -33.8688, lon: 151.2093, altitude: 0 },
    ],
    waypoints: [{ lat: -25.0, lon: 140.0, altitude: 10500 }],
  },
  {
    id: 'andean-ridge',
    name: 'Andean ridge',
    type: 'ground',
    positions: [
      { lat: -20.1619, lon: -70.1322, altitude: 0 },
      { lat: -15.5, lon: -71.0, altitude: 7500 },
      { lat: -12.0464, lon: -77.0428, altitude: 0 },
    ],
    waypoints: [{ lat: -15.5, lon: -71.0, altitude: 7500 }],
  },
  {
    id: 'balkan-bridge',
    name: 'Balkan bridge',
    type: 'air',
    positions: [
      { lat: 45.815, lon: 15.9819, altitude: 0 },
      { lat: 43.8563, lon: 18.4131, altitude: 9000 },
      { lat: 41.9973, lon: 21.428, altitude: 0 },
    ],
    waypoints: [{ lat: 43.8563, lon: 18.4131, altitude: 9000 }],
  },
  {
    id: 'caribbean-thread',
    name: 'Caribbean thread',
    type: 'naval',
    positions: [
      { lat: 18.4655, lon: -66.1057, altitude: 0 },
      { lat: 16.3064, lon: -61.084, altitude: 0 },
      { lat: 14.6415, lon: -61.0242, altitude: 0 },
    ],
    waypoints: [{ lat: 16.3064, lon: -61.084, altitude: 0 }],
  },
  {
    id: 'north-sea-loop',
    name: 'North Sea loop',
    type: 'naval',
    positions: [
      { lat: 53.4808, lon: -2.2426, altitude: 0 },
      { lat: 55.95, lon: 3.0, altitude: 0 },
      { lat: 57.7089, lon: 11.9746, altitude: 0 },
    ],
    waypoints: [{ lat: 55.95, lon: 3.0, altitude: 0 }],
  },
  {
    id: 'steppe-corridor',
    name: 'Steppe corridor',
    type: 'ground',
    positions: [
      { lat: 50.4501, lon: 30.5234, altitude: 0 },
      { lat: 48.708, lon: 44.513, altitude: 0 },
      { lat: 43.2389, lon: 76.8897, altitude: 0 },
    ],
    waypoints: [{ lat: 48.708, lon: 44.513, altitude: 0 }],
  },
  {
    id: 'sundarbans-sprint',
    name: 'Sundarbans sprint',
    type: 'ground',
    positions: [
      { lat: 22.5726, lon: 88.3639, altitude: 0 },
      { lat: 21.5, lon: 90.0, altitude: 0 },
      { lat: 23.8103, lon: 90.4125, altitude: 0 },
    ],
    waypoints: [{ lat: 21.5, lon: 90.0, altitude: 0 }],
  },
  {
    id: 'island-chain',
    name: 'Island chain',
    type: 'air',
    positions: [
      { lat: 25.7617, lon: -80.1918, altitude: 0 },
      { lat: 19.8968, lon: -155.5828, altitude: 11500 },
      { lat: 21.3069, lon: -157.8583, altitude: 0 },
    ],
    waypoints: [{ lat: 19.8968, lon: -155.5828, altitude: 11500 }],
  },
  {
    id: 'saharan-band',
    name: 'Saharan band',
    type: 'air',
    positions: [
      { lat: 14.7167, lon: -17.4677, altitude: 0 },
      { lat: 19.0, lon: 13.0, altitude: 11500 },
      { lat: 30.0444, lon: 31.2357, altitude: 0 },
    ],
    waypoints: [{ lat: 19.0, lon: 13.0, altitude: 11500 }],
  },
  {
    id: 'black-sea-arc',
    name: 'Black Sea arc',
    type: 'naval',
    positions: [
      { lat: 41.0082, lon: 28.9784, altitude: 0 },
      { lat: 42.6983, lon: 27.2167, altitude: 0 },
      { lat: 44.4328, lon: 26.1043, altitude: 0 },
      { lat: 45.4642, lon: 28.777, altitude: 10000 },
    ],
    waypoints: [
      { lat: 42.6983, lon: 27.2167, altitude: 0 },
      { lat: 44.4328, lon: 26.1043, altitude: 0 },
    ],
  },
  {
    id: 'pacific-hinge',
    name: 'Pacific hinge',
    type: 'air',
    positions: [
      { lat: 47.6062, lon: -122.3321, altitude: 0 },
      { lat: 55.0, lon: 170.0, altitude: 12000 },
      { lat: 35.6762, lon: 139.6503, altitude: 0 },
    ],
    waypoints: [{ lat: 55.0, lon: 170.0, altitude: 12000 }],
  },
  {
    id: 'andes-to-atlantic',
    name: 'Andes to Atlantic',
    type: 'ground',
    positions: [
      { lat: -34.6037, lon: -58.3816, altitude: 0 },
      { lat: -27.0, lon: -48.6, altitude: 0 },
      { lat: -22.9068, lon: -43.1729, altitude: 0 },
    ],
    waypoints: [{ lat: -27.0, lon: -48.6, altitude: 0 }],
  },
  {
    id: 'pan-arabian',
    name: 'Pan Arabian',
    type: 'ground',
    positions: [
      { lat: 24.7136, lon: 46.6753, altitude: 0 },
      { lat: 29.3759, lon: 47.9774, altitude: 0 },
      { lat: 33.3152, lon: 44.3661, altitude: 0 },
    ],
    waypoints: [{ lat: 29.3759, lon: 47.9774, altitude: 0 }],
  },
  {
    id: 'nordic-dash',
    name: 'Nordic dash',
    type: 'air',
    positions: [
      { lat: 60.1699, lon: 24.9384, altitude: 0 },
      { lat: 64.1265, lon: -21.8174, altitude: 10500 },
      { lat: 59.9139, lon: 10.7522, altitude: 0 },
    ],
    waypoints: [{ lat: 64.1265, lon: -21.8174, altitude: 10500 }],
  },
  {
    id: 'baltic-thread',
    name: 'Baltic thread',
    type: 'naval',
    positions: [
      { lat: 59.3293, lon: 18.0686, altitude: 0 },
      { lat: 58.3776, lon: 24.7474, altitude: 0 },
      { lat: 59.9133, lon: 10.739, altitude: 0 },
    ],
    waypoints: [{ lat: 58.3776, lon: 24.7474, altitude: 0 }],
  },
  {
    id: 'red-sea-run',
    name: 'Red Sea run',
    type: 'naval',
    positions: [
      { lat: 29.5521, lon: 34.9519, altitude: 0 },
      { lat: 25.4, lon: 36.0, altitude: 0 },
      { lat: 21.4858, lon: 39.1925, altitude: 0 },
    ],
    waypoints: [{ lat: 25.4, lon: 36.0, altitude: 0 }],
  },
  {
    id: 'great-plains-pass',
    name: 'Great Plains pass',
    type: 'ground',
    positions: [
      { lat: 39.7392, lon: -104.9903, altitude: 0 },
      { lat: 41.2572, lon: -95.9951, altitude: 0 },
      { lat: 44.9778, lon: -93.265, altitude: 0 },
    ],
    waypoints: [{ lat: 41.2572, lon: -95.9951, altitude: 0 }],
  },
  {
    id: 'maritime-seam',
    name: 'Maritime seam',
    type: 'naval',
    positions: [
      { lat: 1.3521, lon: 103.8198, altitude: 0 },
      { lat: 5.0, lon: 112.0, altitude: 0 },
      { lat: 7.9519, lon: 98.3381, altitude: 0 },
    ],
    waypoints: [{ lat: 5.0, lon: 112.0, altitude: 0 }],
  },
  {
    id: 'pacific-ridge',
    name: 'Pacific ridge',
    type: 'air',
    positions: [
      { lat: 34.0522, lon: -118.2437, altitude: 0 },
      { lat: 45.0, lon: -150.0, altitude: 12500 },
      { lat: 35.6895, lon: 139.6917, altitude: 0 },
    ],
    waypoints: [{ lat: 45.0, lon: -150.0, altitude: 12500 }],
  },
])

const selectedTrajectoryId = ref(trajectories.value[0].id)
const selectedCoordinate = ref(null)
const globeRef = ref(null)
const coordinateOverlayVisible = ref(false)
let overlayTimer = null
const useOfflineMap = ref(false)
const isLoadingExtras = ref(false)
const extrasLoaded = ref(false)
const loadError = ref('')

const iconByType = {
  air: Plane,
  naval: Ship,
  space: Satellite,
  ground: Navigation,
}

const getIcon = (type) => iconByType[type] || Circle
const waypointCount = (trajectory) =>
  Array.isArray(trajectory?.waypoints) ? trajectory.waypoints.length : 0

const decoratedTrajectories = computed(() =>
  trajectories.value.map(applyTrajectoryDefaults),
)
const activeTrajectory = computed(() =>
  decoratedTrajectories.value.find((t) => t.id === selectedTrajectoryId.value) ||
  decoratedTrajectories.value[0] ||
  null,
)
const totalTrajectories = computed(() => trajectories.value.length)
const totalWaypoints = computed(() =>
  decoratedTrajectories.value.reduce(
    (sum, t) => sum + waypointCount(t),
    0,
  ),
)
const typeCounts = computed(() => {
  return trajectories.value.reduce(
    (acc, t) => {
      const key = t.type || 'other'
      acc[key] = (acc[key] || 0) + 1
      return acc
    },
    {},
  )
})
const preferredDark = usePreferredDark()
const isDark = useStorage('atlas-theme', preferredDark.value)
const toggleDark = () => {
  isDark.value = !isDark.value
}
const inferVelocity = (type) => {
  switch (type) {
    case 'space':
      return 'suborbital'
    case 'air':
      return 'supersonic'
    case 'ground':
    case 'sea':
    case 'naval':
      return 'subsonic'
    default:
      return 'other'
  }
}
const positionsWithMarkers = (trajectory) => {
  const positions = trajectory.positions.map((p) => ({ ...p }))
  if (positions.length) {
    positions[0].marker = 'start'
    if (positions.length > 1) {
      positions[positions.length - 1].marker = 'end'
    }
  }
  if (Array.isArray(trajectory.waypoints)) {
    const approxEq = (a, b) => Math.abs(a - b) < 1e-6
    trajectory.waypoints.forEach((wp) => {
      const match = positions.find(
        (p) =>
          approxEq(p.lat, wp.lat)
          && approxEq(p.lon, wp.lon)
          && approxEq(p.altitude ?? 0, wp.altitude ?? 0),
      )
      if (match && match.marker !== 'start' && match.marker !== 'end') {
        match.marker = 'waypoint'
      }
    })
  }
  return positions
}

const applyTrajectoryDefaults = (t) => {
  const type = t.type || 'other'
  const normalizedPositions =
    t.positions?.map((p) => ({
      ...p,
      height: p.height ?? p.altitude ?? 0,
    })) || []
  const normalizedWaypoints =
    t.waypoints?.map((p) => ({
      ...p,
      height: p.height ?? p.altitude ?? 0,
    })) || []
  return {
    ...t,
    type,
    velocityProfile: t.velocityProfile || inferVelocity(type),
    maneuverability:
      t.maneuverability || (t.waypoints?.length ? 'waypoint' : 'no-waypoint'),
    convergence: t.convergence || 'nominal',
    positions: positionsWithMarkers({ ...t, positions: normalizedPositions, waypoints: normalizedWaypoints }),
    waypoints: normalizedWaypoints,
  }
}
const toRad = (deg) => (deg * Math.PI) / 180
const groundRangeKm = (trajectory) => {
  if (!trajectory || !trajectory.positions?.length) return 0
  let total = 0
  for (let i = 1; i < trajectory.positions.length; i += 1) {
    const prev = trajectory.positions[i - 1]
    const curr = trajectory.positions[i]
    const lat1 = toRad(prev.lat)
    const lat2 = toRad(curr.lat)
    const dLat = lat2 - lat1
    const dLon = toRad(curr.lon - prev.lon)
    const a =
      Math.sin(dLat / 2) ** 2
      + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    const earthRadiusKm = 6371
    total += earthRadiusKm * c
  }
  return total
}
const maxApogee = (trajectory) => {
  if (!trajectory || !trajectory.positions?.length) return 0
  return trajectory.positions.reduce(
    (max, p) => Math.max(max, p.height ?? p.altitude ?? 0),
    0,
  )
}
const formatLabel = (val) => {
  const str = val || 'other'
  return str
    .replace(/-/g, ' ')
    .replace(/\b\w/g, (m) => m.toUpperCase())
}
const cardTone = computed(() =>
  isDark.value
    ? 'border border-neutral-700 bg-neutral-900/80 text-neutral-100'
    : 'border border-slate-200/60 bg-white/70 text-slate-900',
)
const listTone = computed(() =>
  isDark.value
    ? 'border border-neutral-700 bg-neutral-900/70 text-neutral-100 hover:border-neutral-500 hover:bg-neutral-900'
    : 'border border-slate-100 text-slate-900 hover:border-slate-300 hover:bg-white',
)
const activeTone = computed(() =>
  isDark.value
    ? 'border border-neutral-500 bg-neutral-800 shadow-sm text-neutral-50'
    : 'border border-slate-300 bg-white shadow-sm text-slate-900',
)

onMounted(() => {
  document.documentElement.classList.toggle('dark', isDark.value)
})

watch(
  isDark,
  (val) => {
    document.documentElement.classList.toggle('dark', val)
  },
  { immediate: true },
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

const loadMoreTrajectories = async () => {
  if (isLoadingExtras.value || extrasLoaded.value) return
  isLoadingExtras.value = true
  loadError.value = ''
  try {
    const res = await fetch('/data/trajectories-extra.json')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    const existingIds = new Set(trajectories.value.map((t) => t.id))
    const merged = data.filter((item) => !existingIds.has(item.id))
    trajectories.value = [...trajectories.value, ...merged]
    extrasLoaded.value = true
  } catch (err) {
    loadError.value = 'Failed to load extra trajectories.'
    console.error(err)
  } finally {
    isLoadingExtras.value = false
  }
}

onBeforeUnmount(() => {
  if (overlayTimer) {
    clearTimeout(overlayTimer)
  }
})
</script>

<template>
  <div
    class="min-h-screen"
    :class="
      isDark
        ? 'bg-gradient-to-b from-neutral-950 via-neutral-900 to-neutral-950 text-neutral-100'
        : 'bg-white/90 text-slate-900'
    "
  >
    <div class="mx-auto flex w-full flex-col gap-6 px-6 pb-10 pt-8 lg:px-10">
      <header class="flex flex-wrap items-center justify-between gap-4">
        <div class="space-y-2">
          <p class="text-xs uppercase tracking-[0.25em] text-slate-500">
            Cesium baseline
          </p>
          <h1
            class="text-3xl font-semibold lg:text-4xl"
            :class="isDark ? 'text-slate-50' : 'text-slate-900'"
          >
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
          <Button variant="outline" size="sm" @click="toggleDark">
            {{ isDark ? 'Light mode' : 'Dark mode' }}
          </Button>
          <Button variant="outline" size="sm" @click="resetCamera">
            Reset view
          </Button>
        </div>
      </header>

      <div class="grid gap-6 lg:grid-cols-[380px_1fr] xl:grid-cols-[420px_1fr]">
        <div class="space-y-4">
          <Card
            :class="[cardTone, 'shadow-sm backdrop-blur-sm']"
            class="h-[calc(100vh-220px)] min-h-[640px] flex flex-col"
          >
            <CardHeader>
              <CardTitle class="text-lg">Trajectories</CardTitle>
              <CardDescription>
                {{ totalTrajectories }} tracks · {{ totalWaypoints }} waypoints
                · air: {{ typeCounts.air || 0 }} · naval: {{ typeCounts.naval || 0 }}
                · ground: {{ typeCounts.ground || 0 }} · other: {{ typeCounts.other || 0 }}
              </CardDescription>
            </CardHeader>
            <CardContent class="space-y-3 flex-1 overflow-y-auto">
              <div
                v-for="trajectory in decoratedTrajectories"
                :key="trajectory.id"
                role="button"
                tabindex="0"
                class="flex cursor-pointer items-center justify-between gap-3 rounded-xl px-3 py-2 transition"
                :class="[
                  listTone,
                  selectedTrajectoryId === trajectory.id ? activeTone : '',
                ]"
                @click="selectedTrajectoryId = trajectory.id"
                @keydown.enter.prevent="selectedTrajectoryId = trajectory.id"
                @keydown.space.prevent="selectedTrajectoryId = trajectory.id"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="flex h-9 w-9 items-center justify-center rounded-full"
                    :class="
                      isDark
                        ? 'border border-slate-600 bg-slate-800 text-slate-100'
                        : 'border border-slate-200 bg-white/80 text-slate-600'
                    "
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
                    <p
                      class="text-sm font-semibold"
                      :class="isDark ? 'text-slate-100' : 'text-slate-900'"
                    >
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
              <div class="flex items-center gap-2 pt-2">
                <Button
                  variant="outline"
                  size="sm"
                  class="w-full"
                  :disabled="isLoadingExtras || extrasLoaded"
                  @click="loadMoreTrajectories"
                >
                  <span v-if="extrasLoaded">More trajectories loaded</span>
                  <span v-else-if="isLoadingExtras">Loading…</span>
                  <span v-else>Load more trajectories</span>
                </Button>
              </div>
              <p v-if="loadError" class="text-xs text-red-600">
                {{ loadError }}
              </p>
            </CardContent>
          </Card>
        </div>

        <div
          class="relative h-[calc(100vh-220px)] min-h-[640px] w-full overflow-hidden rounded-3xl border bg-gradient-to-b shadow-2xl"
          :class="
            isDark
              ? 'border-slate-800 from-slate-950 to-slate-950'
              : 'border-slate-200/70 from-slate-900 to-slate-800'
          "
        >
          <CesiumGlobe
            ref="globeRef"
            class="h-full"
            :trajectories="decoratedTrajectories"
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
                <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-xs uppercase tracking-[0.2em] text-white/70">
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Type</p>
                    <p class="text-sm font-semibold text-white">
                      {{ formatLabel(activeTrajectory.type || 'unspecified') }}
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Waypoints</p>
                    <p class="text-sm font-semibold text-white">
                      {{ waypointCount(activeTrajectory) }}
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Ground range</p>
                    <p class="text-sm font-semibold text-white">
                      {{ groundRangeKm(activeTrajectory).toFixed(1) }} km
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Max apogee</p>
                    <p class="text-sm font-semibold text-white">
                      {{ Math.round(maxApogee(activeTrajectory)) }} m
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Velocity</p>
                    <p class="text-sm font-semibold text-white">
                      {{ formatLabel(activeTrajectory.velocityProfile) }}
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Maneuver</p>
                    <p class="text-sm font-semibold text-white">
                      {{ formatLabel(activeTrajectory.maneuverability) }}
                    </p>
                  </div>
                  <div class="space-y-0.5">
                    <p class="text-[11px]">Convergence</p>
                    <p class="text-sm font-semibold text-white">
                      {{ formatLabel(activeTrajectory.convergence) }}
                    </p>
                  </div>
                </div>
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
