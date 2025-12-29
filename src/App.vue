<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { usePreferredDark, useStorage } from '@vueuse/core'
import * as Cesium from 'cesium'
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
  Map,
  Globe2,
  SunMedium,
  SunMoon,
  RefreshCcw,
  MapPin,
} from 'lucide-vue-next'
import CompactGauge from './components/CompactGauge.vue'

const trajectories = ref([])

const selectedTrajectoryId = ref('')
const selectedCoordinate = ref(null)
const globeRef = ref(null)
const coordinateOverlayVisible = ref(false)
let overlayTimer = null
const useOfflineMap = ref(false)
const useFlatMap = ref(false)
const useLighting = ref(true)
const showBoundaries = ref(false)
const isInitialLoading = ref(true)
const initialLoadError = ref('')
const isLoadingExtras = ref(false)
const extrasLoaded = ref(false)
const loadError = ref('')
const isUploadingTrajectory = ref(false)
const uploadError = ref('')
const fileInputRef = ref(null)
const uploadSuccess = ref('')
const pendingDeleteId = ref('')
const downsampleEnabled = ref(false)
const downsampleEvery = ref(5)
const initialTrajectories = computed(() => [...trajectories.value])

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
    t.positions?.map((p, idx) => ({
      ...p,
      altitude: p.altitude ?? p.height ?? 0,
      height: p.altitude ?? p.height ?? 0,
      time: p.time ?? idx * 60,
    })) || []
  const normalizedWaypoints =
    t.waypoints?.map((p, idx) => ({
      ...p,
      altitude: p.altitude ?? p.height ?? 0,
      height: p.altitude ?? p.height ?? 0,
      time: p.time ?? idx * 60,
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
    (max, p) => Math.max(max, p.altitude ?? p.height ?? 0),
    0,
  )
}
const durationSeconds = (trajectory) => {
  if (!trajectory || !trajectory.positions?.length) return 0
  const first = trajectory.positions[0].time ?? 0
  const last = trajectory.positions[trajectory.positions.length - 1].time ?? 0
  return Math.max(0, last - first)
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
  loadInitialTrajectories()
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

const toggleFlatMap = () => {
  useFlatMap.value = !useFlatMap.value
}

const toggleLighting = () => {
  useLighting.value = !useLighting.value
}

const toggleBoundaries = () => {
  showBoundaries.value = !showBoundaries.value
}

const loadInitialTrajectories = async () => {
  isInitialLoading.value = true
  initialLoadError.value = ''
  try {
    await loadTrajectoriesFrom('/data/trajectories.json')
    if (!selectedTrajectoryId.value && trajectories.value.length) {
      selectedTrajectoryId.value = trajectories.value[0].id
    }
  } catch (err) {
    console.error(err)
    initialLoadError.value = 'Failed to load initial trajectories.'
  } finally {
    isInitialLoading.value = false
  }
}

const loadMoreTrajectories = async () => {
  if (isLoadingExtras.value || extrasLoaded.value) return
  isLoadingExtras.value = true
  loadError.value = ''
  try {
    await loadTrajectoriesFrom('/data/trajectories-extra.json')
    extrasLoaded.value = true
  } catch (err) {
    loadError.value = 'Failed to load extra trajectories.'
    console.error(err)
  } finally {
    isLoadingExtras.value = false
  }
}

const loadLrbmTrajectory = async () => {
  // no-op placeholder retained to avoid breaking references
}

const handleUploadClick = () => {
  uploadError.value = ''
  uploadSuccess.value = ''
  fileInputRef.value?.click()
}

const handleFileSelected = async (event) => {
  const files = Array.from(event.target.files || [])
  if (!files.length) return
  isUploadingTrajectory.value = true
  uploadError.value = ''
  uploadSuccess.value = ''
  try {
    for (const file of files) {
      const ext = file.name.split('.').pop()?.toLowerCase()
      const text = await file.text()
      if (ext === 'txt') {
        const trajectory = convertTxtToTrajectory(text, file.name)
        addTrajectoryIfNew(trajectory)
      } else if (ext === 'json') {
        const parsed = JSON.parse(text)
        const incoming = Array.isArray(parsed) ? parsed : [parsed]
        incoming.forEach(addTrajectoryIfNew)
      } else {
        uploadError.value = 'Unsupported file type. Use .txt or .json.'
      }
    }
    if (!uploadError.value) {
      uploadSuccess.value = 'Upload complete.'
    }
  } catch (err) {
    console.error(err)
    uploadError.value = 'Failed to convert trajectory file.'
  } finally {
    isUploadingTrajectory.value = false
    if (fileInputRef.value) {
      fileInputRef.value.value = ''
    }
  }
}

const loadTrajectoriesFrom = async (path) => {
  const res = await fetch(path)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  const data = await res.json()
  const existingIds = new Set(trajectories.value.map((t) => t.id))
  const merged = data.filter((item) => !existingIds.has(item.id))
  trajectories.value = [...trajectories.value, ...merged]
}

const addTrajectoryIfNew = (trajectory) => {
  const existingIds = new Set(trajectories.value.map((t) => t.id))
  if (!existingIds.has(trajectory.id)) {
    const processed = downsampleEnabled.value
      ? downsampleTrajectory(trajectory, Math.max(1, Number(downsampleEvery.value) || 1))
      : trajectory
    trajectories.value = [...trajectories.value, processed]
  } else {
    uploadError.value = 'A trajectory with this id already exists.'
  }
}

const downsampleTrajectory = (trajectory, step) => {
  const ds = (list) => {
    if (!Array.isArray(list) || list.length === 0) return []
    if (step <= 1) return list
    const result = []
    list.forEach((p, idx) => {
      if (idx === 0 || idx === list.length - 1 || idx % step === 0) {
        result.push(p)
      }
    })
    return result
  }
  return {
    ...trajectory,
    positions: ds(trajectory.positions),
    waypoints: ds(trajectory.waypoints),
  }
}

const clearTrajectories = () => {
  trajectories.value = []
  selectedTrajectoryId.value = ''
}

const deleteTrajectory = (id, confirmed = false) => {
  if (!confirmed) {
    pendingDeleteId.value = id
    return
  }
  trajectories.value = trajectories.value.filter((t) => t.id !== id)
  pendingDeleteId.value = ''
  if (selectedTrajectoryId.value === id) {
    selectedTrajectoryId.value =
      trajectories.value.length > 0 ? trajectories.value[0].id : ''
  }
}

const convertTxtToTrajectory = (text, filename) => {
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0)
  const dataLines = lines.filter((l) => !l.trim().startsWith('Time'))
  const FEET_TO_METERS = 0.3048

  const positions = dataLines.map((line) => {
    const cols = line.trim().split(/\s+/).map(Number)
    const [time, x, y, z] = cols
    const cartesian = new Cesium.Cartesian3(
      x * FEET_TO_METERS,
      y * FEET_TO_METERS,
      z * FEET_TO_METERS,
    )
    const carto = Cesium.Cartographic.fromCartesian(cartesian)
    return {
      lat: +Cesium.Math.toDegrees(carto.latitude).toFixed(6),
      lon: +Cesium.Math.toDegrees(carto.longitude).toFixed(6),
      altitude: Math.round(carto.height),
      time: time,
    }
  })

  const id = filename.replace(/\.[^/.]+$/, '')
  return {
    id,
    name: formatLabel(id),
    type: 'other',
    velocityProfile: 'other',
    maneuverability: 'no-waypoint',
    convergence: 'nominal',
    positions,
    waypoints: [],
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
            Trajectory dashboard
          </p>
          <h1
            class="text-3xl font-semibold lg:text-4xl"
            :class="isDark ? 'text-slate-50' : 'text-slate-900'"
          >
            Atlas Nexus
          </h1>
          <p class="max-w-2xl text-sm text-slate-600">
            Mission-grade Cesium workspace for plotting and comparing trajectories.
            Click to sample lat/lon, swap base layers, load new tracks, and inspect
            waypoints, range, and apogee at a glance.
          </p>
        </div>
        <div class="flex items-center gap-2">
          <Button variant="outline" size="sm" @click="toggleMapMode">
            <Map class="mr-2 h-4 w-4" aria-hidden="true" />
            Map: {{ useOfflineMap ? 'Offline' : 'Default' }}
          </Button>
          <Button variant="outline" size="sm" @click="toggleFlatMap">
            <Globe2 class="mr-2 h-4 w-4" aria-hidden="true" />
            View: {{ useFlatMap ? 'Flat' : 'Globe' }}
          </Button>

          <Button variant="outline" size="sm" @click="toggleLighting">
            <SunMedium class="mr-2 h-4 w-4" aria-hidden="true" />
            Lighting: {{ useLighting ? 'On' : 'Off' }}
          </Button>
          <Button variant="outline" size="sm" @click="toggleDark">
            <SunMoon class="mr-2 h-4 w-4" aria-hidden="true" />
            {{ isDark ? 'Light mode' : 'Dark mode' }}
          </Button>
          <Button variant="outline" size="sm" @click="resetCamera">
            <RefreshCcw class="mr-2 h-4 w-4" aria-hidden="true" />
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
              <div
                class="mt-3 grid gap-2 rounded-xl border border-neutral-200/70 bg-white/60 p-3 text-sm dark:border-neutral-700 dark:bg-neutral-900/60"
              >
                <div
                  class="flex items-center justify-between text-[11px] uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400"
                >
                  <span>Envelopes</span>
                  <!-- <span class="text-[10px]">Apogee · Range</span> -->
                </div>

                <CompactGauge
                  :min="0"
                  :max="12000"
                  :value="Math.round(groundRangeKm(activeTrajectory || decoratedTrajectories[0]))"
                  label="Range"
                  unit=" km"
                />
              </div>
            </CardHeader>
            <CardContent class="space-y-3 flex-1 overflow-y-auto">
              <template v-if="isInitialLoading">
                <div
                  class="rounded-xl border border-slate-200/80 bg-white/60 p-4 text-sm text-slate-600 dark:border-neutral-700 dark:bg-neutral-900/60 dark:text-slate-200"
                >
                  Loading trajectories…
                </div>
              </template>
              <template v-else-if="decoratedTrajectories.length">
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
                  <div class="flex items-center gap-2">
                    <Button
                      v-if="pendingDeleteId !== trajectory.id"
                      variant="ghost"
                      size="icon-sm"
                      class="text-slate-400 hover:text-red-500"
                      @click.stop="deleteTrajectory(trajectory.id)"
                      aria-label="Delete trajectory"
                    >
                      ×
                    </Button>
                    <div
                      v-else
                      class="flex items-center gap-1 text-[11px] uppercase tracking-[0.15em] text-slate-500"
                    >
                      <span>Confirm?</span>
                      <Button
                        variant="outline"
                        size="icon-sm"
                        class="text-green-600"
                        @click.stop="deleteTrajectory(trajectory.id, true)"
                        aria-label="Confirm delete"
                      >
                        ✓
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon-sm"
                        class="text-slate-500 hover:text-slate-700"
                        @click.stop="pendingDeleteId = ''"
                        aria-label="Cancel delete"
                      >
                        ✕
                      </Button>
                    </div>
                  </div>
                </div>
              </template>
              <div
                v-else
                class="rounded-xl border border-dashed border-slate-200/80 bg-white/60 p-4 text-sm text-slate-600 dark:border-neutral-700 dark:bg-neutral-900/60 dark:text-slate-200"
              >
                <p class="font-semibold">No trajectories loaded.</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  Upload a track or load samples to get started.
                </p>
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
                <Button
                  variant="outline"
                  size="sm"
                  class="w-full"
                  :disabled="isUploadingTrajectory"
                  @click="handleUploadClick"
                >
                  <span v-if="isUploadingTrajectory">Uploading…</span>
                  <span v-else>Upload</span>
                </Button>
                <input
                  ref="fileInputRef"
                  type="file"
                  accept=".txt,.json,application/json,text/plain"
                  multiple
                  class="hidden"
                  @change="handleFileSelected"
                />
              </div>
              <p v-if="loadError" class="text-xs text-red-600">
                {{ loadError }}
              </p>
              <p v-if="uploadError" class="text-xs text-red-600">
                {{ uploadError }}
              </p>
              <p v-if="uploadSuccess" class="text-xs text-green-600">
                {{ uploadSuccess }}
              </p>
              <p v-if="initialLoadError" class="text-xs text-red-600">
                {{ initialLoadError }}
              </p>
              <details class="pt-3 text-xs text-slate-700 dark:text-slate-200">
                <summary class="cursor-pointer select-none text-[11px] uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                  Advanced
                </summary>
                <div class="mt-2 grid grid-cols-2 gap-2">
                  <label class="flex items-center gap-2">
                    <input
                      v-model="downsampleEnabled"
                      type="checkbox"
                      class="h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                    />
                    <span class="text-slate-600 dark:text-slate-300">
                      Downsample imports
                    </span>
                  </label>
                  <div class="flex items-center gap-2 justify-end">
                    <span class="text-slate-600 dark:text-slate-300">Every</span>
                    <input
                      v-model.number="downsampleEvery"
                      type="number"
                      min="1"
                      class="w-16 rounded border border-slate-300 bg-white/80 px-2 py-1 text-xs text-slate-700 dark:border-neutral-700 dark:bg-neutral-900 dark:text-neutral-100"
                    />
                    <span class="text-slate-600 dark:text-slate-300">pts</span>
                  </div>
                </div>
              </details>
              <div class="pt-2">
                <Button
                  variant="outline"
                  size="sm"
                  class="w-full text-red-600 hover:text-red-700"
                  :disabled="!trajectories.length"
                  @click="clearTrajectories"
                >
                  Clear all trajectories
                </Button>
              </div>
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
            :use-flat-map="useFlatMap"
            :use-lighting="useLighting"
            :show-boundaries="showBoundaries"
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
                    <p class="text-[11px]">Duration</p>
                    <p class="text-sm font-semibold text-white">
                      {{ Math.round(durationSeconds(activeTrajectory)) }} s
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
