<script setup>
import { LMap, LTileLayer, LMarker } from "@vue-leaflet/vue-leaflet"
import { ref } from "vue"

const zoom = ref(13)
const center = ref([54.6872, 25.2797]) 
</script>

<template>
  <l-map style="height: 500px" :zoom="zoom" :center="center">
    <l-tile-layer
      url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      attribution="&copy; OpenStreetMap contributors"
    />
    <l-marker :lat-lng="center"></l-marker>
  </l-map>
</template>