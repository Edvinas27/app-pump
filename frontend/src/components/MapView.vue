<script setup>
import { LMap, LTileLayer, LMarker } from "@vue-leaflet/vue-leaflet"
import "leaflet/dist/leaflet.css"
import { ref } from "vue"

const zoom = ref(13)
const center = ref([54.6872, 25.2797])
</script>

<template>
  <div class="map-wrapper">
    <div class="map-card">
      <div class="map-header">
        <span class="map-dot" />
        <p class="map-title">Current Location</p>
        <span class="map-coords">54.6872° N, 25.2797° E</span>
      </div>
      <div class="map-body">
        <l-map class="map" :zoom="zoom" :center="center" :options="{ zoomControl: true, dragging: true, scrollWheelZoom: true }">
          <l-tile-layer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution="&copy; OpenStreetMap contributors"
          />
          <l-marker :lat-lng="center" />
        </l-map>
      </div>
    </div>
  </div>
</template>

<style scoped>
.map-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px;
  box-sizing: border-box;
  font-family: 'Inter', sans-serif;
}

.map-card {
  width: 100%;
  max-width: 860px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow:
    0 2px 4px rgba(0,0,0,0.04),
    0 8px 24px rgba(0,0,0,0.10),
    0 24px 48px rgba(0,0,0,0.06);
}

.map-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 20px;
  border-bottom: 1px solid #eef0f4;
}

.map-dot {
  width: 10px;
  height: 10px;
  background: #22c55e;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2);
  animation: pulse 2s infinite;
}

.map-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.map-coords {
  margin-left: auto;
  font-size: 12px;
  color: #94a3b8;
  font-weight: 400;
  letter-spacing: 0.3px;
}

.map-body {
  height: 500px;
  border-radius: 0 0 20px 20px;
  overflow: hidden;
}

.map {
  height: 100%;
  width: 100%;
}

@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2); }
  50%       { box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.08); }
}
</style>