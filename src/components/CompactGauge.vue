<script setup>
import { computed } from 'vue'

const props = defineProps({
  min: { type: Number, required: true },
  max: { type: Number, required: true },
  value: { type: Number, required: true },
  label: { type: String, default: '' },
  unit: { type: String, default: '' },
})

const clampedValue = computed(() =>
  Math.min(Math.max(props.value, props.min), props.max),
)
const percent = computed(() => {
  if (props.max === props.min) return 0
  return ((clampedValue.value - props.min) / (props.max - props.min)) * 100
})
</script>

<template>
  <div class="flex items-center gap-2 text-xs">
    <div class="flex-1 space-y-1">
      <div class="flex items-center justify-between text-[11px] uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">
        <span>{{ label }}</span>
        <span>{{ value }}{{ unit }}</span>
      </div>
      <div class="relative h-1.5 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-800">
        <div
          class="absolute inset-y-0 left-0 rounded-full bg-blue-500 transition-all"
          :style="{ width: `${percent}%` }"
        />
      </div>
      <div class="flex justify-between text-[10px] text-slate-500 dark:text-slate-400">
        <span>{{ min }}{{ unit }}</span>
        <span>{{ max }}{{ unit }}</span>
      </div>
    </div>
  </div>
</template>
