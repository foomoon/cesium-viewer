<script setup>
import { computed, ref } from 'vue'
import CesiumGlobe from './components/CesiumGlobe.vue'
import CoordinateCard from './components/CoordinateCard.vue'
import DataSelector from './components/DataSelector.vue'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'

const trajectories = ref([
  {
    id: 'atlantic-hop',
    name: 'Atlantic hop',
    color: '#2563eb',
    positions: [
      { lat: 40.6413, lon: -73.7781, height: 0 },
      { lat: 46.5, lon: -45, height: 11000 },
      { lat: 51.47, lon: -0.4543, height: 0 },
    ],
  },
  {
    id: 'pacific-arc',
    name: 'Pacific arc',
    color: '#db2777',
    positions: [
      { lat: 37.6189, lon: -122.375, height: 0 },
      { lat: 45.5, lon: -160, height: 12500 },
      { lat: 42.2, lon: 170, height: 12500 },
      { lat: 35.5494, lon: 139.7798, height: 0 },
    ],
  },
  {
    id: 'andes-traverse',
    name: 'Andes traverse',
    color: '#0ea5e9',
    positions: [
      { lat: -33.4489, lon: -70.6693, height: 0 },
      { lat: -20.5, lon: -68.3, height: 9000 },
      { lat: -13.5319, lon: -71.9675, height: 4500 },
      { lat: -3.99, lon: -79.2, height: 9000 },
      { lat: 6.207, lon: -75.575, height: 800 },
    ],
  },
])

const selectedTrajectoryId = ref(trajectories.value[0].id)
const selectedCoordinate = ref(null)
const globeRef = ref(null)

const datasetOptions = computed(() =>
  trajectories.value.map((t) => ({
    value: t.id,
    label: t.name,
  })),
)

const selectedTrajectory = computed(() =>
  trajectories.value.find((t) => t.id === selectedTrajectoryId.value),
)

const handleCoordinateSelected = (coord) => {
  selectedCoordinate.value = coord
}

const handleSelectChange = (value) => {
  selectedTrajectoryId.value = value
}

const resetCamera = () => globeRef.value?.resetView?.()
</script>

<template>
  <div class="min-h-screen bg-white/90">
    <div class="mx-auto flex max-w-6xl flex-col gap-6 px-6 pb-10 pt-8 lg:px-10">
      <header class="flex flex-wrap items-center justify-between gap-4">
        <div class="space-y-2">
          <p class="text-xs uppercase tracking-[0.25em] text-slate-500">
            Cesium baseline
          </p>
          <h1 class="text-3xl font-semibold text-slate-900 lg:text-4xl">
            Globe Explorer
          </h1>
          <p class="max-w-2xl text-sm text-slate-600">
            A clean Cesium canvas with no built-in controls. Click anywhere on
            the globe to capture coordinates, toggle between tracks, and keep
            multiple trajectories visible at once.
          </p>
        </div>
        <Button variant="outline" size="sm" @click="resetCamera">
          Reset view
        </Button>
      </header>

      <div class="grid gap-6 lg:grid-cols-[360px_1fr]">
        <div class="space-y-4">
          <CoordinateCard :coordinate="selectedCoordinate" />

          <Card class="border border-slate-200/60 shadow-sm backdrop-blur-sm">
            <CardHeader>
              <CardTitle class="text-lg">Data source</CardTitle>
              <CardDescription>
                Pick a track from the list below. This dropdown will be wired to
                your API later.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <DataSelector
                :options="datasetOptions"
                :model-value="selectedTrajectoryId"
                label="Active track"
                description="Switch focus without hiding the other polylines."
                @update:model-value="handleSelectChange"
              />
            </CardContent>
          </Card>

          <Card class="border border-slate-200/60 shadow-sm backdrop-blur-sm">
            <CardHeader>
              <CardTitle class="text-lg">Trajectories</CardTitle>
              <CardDescription>
                All paths are rendered on the globe. The active one is
                emphasized.
              </CardDescription>
            </CardHeader>
            <CardContent class="space-y-3">
              <div
                v-for="trajectory in trajectories"
                :key="trajectory.id"
                class="flex items-center justify-between rounded-xl border border-slate-100 bg-white/70 px-3 py-2"
              >
                <div class="flex items-center gap-3">
                  <span
                    class="h-2 w-12 rounded-full"
                    :style="{ backgroundColor: trajectory.color }"
                  />
                  <div>
                    <p class="text-sm font-semibold text-slate-900">
                      {{ trajectory.name }}
                    </p>
                    <p class="text-xs text-slate-500">
                      {{ trajectory.positions.length }} control points
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
          class="relative h-[720px] overflow-hidden rounded-3xl border border-slate-200/70 bg-gradient-to-b from-slate-950 to-slate-900 shadow-2xl"
        >
          <CesiumGlobe
            ref="globeRef"
            class="h-full"
            :trajectories="trajectories"
            :selected-trajectory-id="selectedTrajectoryId"
            @coordinate-selected="handleCoordinateSelected"
          />
          <div
            class="pointer-events-none absolute inset-x-6 bottom-6 rounded-2xl border border-white/10 bg-white/10 p-4 text-sm text-white backdrop-blur"
          >
            <div class="flex flex-wrap items-center gap-3">
              <div class="font-semibold">Interaction tips</div>
              <div class="h-px flex-1 bg-white/20" />
              <p class="text-xs uppercase tracking-[0.25em] text-white/70">
                Click to sample · Drag to orbit · Scroll to zoom
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
