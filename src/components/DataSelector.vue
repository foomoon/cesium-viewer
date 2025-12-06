<script setup>
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { cn } from '@/lib/utils'

const props = defineProps({
  label: {
    type: String,
    default: 'Data source',
  },
  description: {
    type: String,
    default: 'Choose a feed to focus on. This will come from the API later.',
  },
  options: {
    type: Array,
    default: () => [],
  },
  modelValue: {
    type: String,
    default: '',
  },
  class: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['update:modelValue'])

const handleChange = (value) => {
  emit('update:modelValue', value)
}
</script>

<template>
  <div :class="cn('space-y-2', props.class)">
    <div>
      <p class="text-sm font-semibold text-slate-900">
        {{ label }}
      </p>
      <p class="text-xs text-slate-500">
        {{ description }}
      </p>
    </div>
    <Select :model-value="modelValue" @update:model-value="handleChange">
      <SelectTrigger class="w-full bg-white/70">
        <SelectValue placeholder="Select a dataset" />
      </SelectTrigger>
      <SelectContent>
        <SelectGroup>
          <SelectLabel>Available</SelectLabel>
          <SelectItem
            v-for="option in options"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </SelectItem>
        </SelectGroup>
      </SelectContent>
    </Select>
  </div>
</template>
