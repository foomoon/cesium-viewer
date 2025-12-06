<script setup>
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

const props = defineProps({
  coordinate: {
    type: Object,
    default: null,
  },
})

const formatNumber = (value) =>
  typeof value === 'number' ? value.toFixed(4) : '—'
</script>

<template>
  <Card class="border border-slate-200/60 shadow-sm backdrop-blur-sm">
    <CardHeader>
      <CardTitle class="text-lg">Selected Position</CardTitle>
      <CardDescription>Click the globe to capture a point.</CardDescription>
    </CardHeader>
    <CardContent>
      <div
        v-if="coordinate"
        class="grid grid-cols-2 gap-3 text-sm leading-tight"
      >
        <div class="space-y-1">
          <p class="text-xs uppercase tracking-[0.2em] text-slate-500">
            Latitude
          </p>
          <p class="font-semibold text-slate-900">
            {{ formatNumber(coordinate.lat) }}°
          </p>
        </div>
        <div class="space-y-1">
          <p class="text-xs uppercase tracking-[0.2em] text-slate-500">
            Longitude
          </p>
          <p class="font-semibold text-slate-900">
            {{ formatNumber(coordinate.lon) }}°
          </p>
        </div>
        <div class="space-y-1">
          <p class="text-xs uppercase tracking-[0.2em] text-slate-500">
            Altitude
          </p>
          <p class="font-semibold text-slate-900">
            {{ formatNumber(coordinate.height) }} m
          </p>
        </div>
      </div>
      <p v-else class="text-sm text-slate-500">
        Nothing selected yet. Choose a point on the globe to see its
        coordinates.
      </p>
    </CardContent>
  </Card>
</template>
