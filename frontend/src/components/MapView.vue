<script setup>
import { LMap, LTileLayer, LPolyline, LMarker, LTooltip } from "@vue-leaflet/vue-leaflet"
import "leaflet/dist/leaflet.css"
import { ref, computed, onMounted } from "vue"

const mapRef    = ref(null)
const zoom      = ref(12)
const center    = ref([54.6872, 25.2797])
const startCoord = [54.6872, 25.2797]

const routes = ref([
  { id: 1, name: "Route A", from: "Vilnius Old Town", to: "Clicked Location", distance: null, duration: null, type: "Example type",  points: [] },
  { id: 2, name: "Route B", from: "Vilnius Old Town", to: "Clicked Location", distance: null, duration: null, type: "Example type",   points: [] },
  { id: 3, name: "Route C", from: "Vilnius Old Town", to: "Clicked Location", distance: null, duration: null, type: "Example type",  points: [] },
])

const loading        = ref(false)
const error          = ref(null)
const clickedPoint   = ref(null)
const hasRoutes      = ref(false)

function getPerpOffset(start, end, factor) {
  const dlat = end[0] - start[0]
  const dlng = end[1] - start[1]
  const midLat = (start[0] + end[0]) / 2
  const midLng = (start[1] + end[1]) / 2
  return [midLat - dlng * factor, midLng + dlat * factor]
}

async function fetchRoutes(endCoord) {
  loading.value = true
  error.value   = null

  const offsets = [0, 0.3, -0.3] 

  try {
    const results = await Promise.all(
      offsets.map(async (factor, i) => {
        let coords
        if (factor === 0) {
          coords = [
            `${startCoord[1]},${startCoord[0]}`,
            `${endCoord[1]},${endCoord[0]}`,
          ].join(";")
        } else {
          const wp = getPerpOffset(startCoord, endCoord, factor)
          coords = [
            `${startCoord[1]},${startCoord[0]}`,
            `${wp[1]},${wp[0]}`,
            `${endCoord[1]},${endCoord[0]}`,
          ].join(";")
        }

        const url = `https://router.project-osrm.org/route/v1/driving/${coords}?overview=full&geometries=geojson`
        const res  = await fetch(url)
        const data = await res.json()
        if (data.code !== "Ok") throw new Error("OSRM routing failed")
        return data
      })
    )

    results.forEach((osrmData, i) => {
      routes.value[i].points   = osrmData.routes[0].geometry.coordinates.map(([lng, lat]) => [lat, lng])
      routes.value[i].distance = (osrmData.routes[0].distance / 1000).toFixed(1) + " km"
      routes.value[i].duration = Math.round(osrmData.routes[0].duration / 60) + " min"
    })

    hasRoutes.value = true

    const allPoints = results.flatMap(d =>
      d.routes[0].geometry.coordinates.map(([lng, lat]) => [lat, lng])
    )
    const lats = allPoints.map(p => p[0])
    const lngs = allPoints.map(p => p[1])
    const bounds = [
      [Math.min(...lats), Math.min(...lngs)],
      [Math.max(...lats), Math.max(...lngs)],
    ]
    mapRef.value.leafletObject.fitBounds(bounds, { padding: [40, 40] })

  } catch (e) {
    error.value = "Could not load routes. Please try again."
    console.error(e)
  } finally {
    loading.value = false
  }
}

function onMapClick(e) {
  const { lat, lng } = e.latlng
  clickedPoint.value  = [lat, lng]
  selectedRouteId.value = null
  fetchRoutes([lat, lng])
}

const routeColors = {
  default: ["#93c5fd", "#86efac", "#fca5a5"],
  active:  ["#2563eb", "#16a34a", "#dc2626"],
}

const selectedRouteId = ref(null)
const selectedRoute   = computed(() => routes.value.find(r => r.id === selectedRouteId.value) || null)

function getRouteColor(route, isActive) {
  const idx = routes.value.indexOf(route)
  return isActive ? routeColors.active[idx] : routeColors.default[idx]
}

function selectRoute(route) {
  selectedRouteId.value = route.id
}
</script>

<template>
  <div class="map-wrapper">
    <div class="map-card">

      <div class="map-header">
        <span class="map-dot" />
        <p class="map-title">Route Planner</p>
        <span class="map-hint" v-if="!hasRoutes && !loading">Click anywhere on the map to generate routes</span>
        <span class="map-coords" v-else>Vilnius, Lithuania</span>
      </div>

      <div class="map-content">

        <div class="sidebar">
          <div class="route-meta">
            <div class="meta-row">
              <span class="meta-icon">📍</span>
              <span class="meta-text">Vilnius Old Town</span>
            </div>
            <div class="meta-divider" />
            <div class="meta-row">
              <span class="meta-icon">🏁</span>
              <span class="meta-text">{{ clickedPoint ? `${clickedPoint[0].toFixed(4)}°, ${clickedPoint[1].toFixed(4)}°` : 'Click map to set destination' }}</span>
            </div>
          </div>

          <p class="sidebar-label">Available Routes</p>

          <div v-if="!hasRoutes && !loading && !error" class="state-box">
            <span class="state-icon">🗺️</span>
            <p>Click anywhere on the map to calculate routes</p>
          </div>

          <div v-else-if="loading" class="state-box">
            <div class="spinner" />
            <p>Calculating routes...</p>
          </div>

          <div v-else-if="error" class="state-box error">
            <span>⚠️</span>
            <p>{{ error }}</p>
            <button class="retry-btn" @click="fetchRoutes(clickedPoint)">Retry</button>
          </div>

          <template v-else>
            <div
              v-for="(route, idx) in routes"
              :key="route.id"
              class="route-card"
              :class="{ active: selectedRouteId === route.id }"
              :style="{ '--accent': routeColors.active[idx] }"
              @click="selectRoute(route)"
            >
              <div class="route-card-top">
                <span class="route-name">{{ route.name }}</span>
                <span class="route-badge">{{ route.type }}</span>
              </div>
              <div class="route-card-stats">
                <span>🛣 {{ route.distance ?? "—" }}</span>
                <span>⏱ {{ route.duration ?? "—" }}</span>
              </div>
            </div>

            <transition name="fade">
              <div v-if="selectedRoute" class="route-info-box">
                <p class="info-title">Selected: {{ selectedRoute.name }}</p>
                <div class="info-grid">
                  <div class="info-item">
                    <span class="info-label">From</span>
                    <span class="info-value">{{ selectedRoute.from }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label">To</span>
                    <span class="info-value">{{ selectedRoute.to }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label">Distance</span>
                    <span class="info-value">{{ selectedRoute.distance }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label">Duration</span>
                    <span class="info-value">{{ selectedRoute.duration }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label">Type</span>
                    <span class="info-value">{{ selectedRoute.type }}</span>
                  </div>
                </div>
              </div>
              <div v-else class="route-info-empty">
                <span>👆</span>
                <p>Click a route card or line on the map to view details</p>
              </div>
            </transition>
          </template>
        </div>

        <div class="map-body">
          <l-map ref="mapRef" class="map" :zoom="zoom" :center="center" @click="onMapClick">
            <l-tile-layer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution="&copy; OpenStreetMap contributors"
            />

            <template v-if="hasRoutes && !loading">
              <l-polyline
                v-for="(route, idx) in routes"
                :bubbling-mouse-events="false"
                :key="route.id"
                :lat-lngs="route.points"
                :color="getRouteColor(route, selectedRouteId === route.id)"
                :weight="selectedRouteId === route.id ? 6 : 4"
                :opacity="selectedRouteId === route.id ? 1 : 0.6"
                :dash-array="selectedRouteId === route.id ? null : '8, 6'"
                @click="selectRoute(route)"
              >
                <l-tooltip :options="{ sticky: true }">
                  {{ route.name }} — {{ route.distance }} / {{ route.duration }}
                </l-tooltip>
              </l-polyline>
            </template>

        
            <l-marker :lat-lng="startCoord">
              <l-tooltip :options="{ permanent: true, direction: 'top' }">Start</l-tooltip>
            </l-marker>

            <l-marker v-if="clickedPoint" :lat-lng="clickedPoint">
              <l-tooltip :options="{ permanent: true, direction: 'top' }">End</l-tooltip>
            </l-marker>
          </l-map>

  
          <div v-if="loading" class="map-loading">
            <div class="spinner large" />
            <p>Fetching road data...</p>
          </div>

          <div v-if="!hasRoutes && !loading" class="map-hint-overlay">
            <div class="hint-pill">🖱️ Click anywhere to set destination</div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<style scoped>
.map-wrapper {
  min-height: 100vh;
  background: linear-gradient(135deg, #e8edf5 0%, #dce3ee 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px;
  box-sizing: border-box;
  font-family: 'Inter', sans-serif;
}

.map-card {
  width: 100%;
  max-width: 1100px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.04), 0 8px 24px rgba(0,0,0,0.10);
  overflow: hidden;
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
  animation: pulse 2s infinite;
}
.map-title { margin: 0; font-size: 14px; font-weight: 600; color: #1e293b; }
.map-coords { margin-left: auto; font-size: 12px; color: #94a3b8; }
.map-hint   { margin-left: auto; font-size: 12px; color: #3b82f6; font-weight: 500; }

.map-content { display: flex; height: 560px; }

.sidebar {
  width: 270px;
  flex-shrink: 0;
  padding: 16px;
  border-right: 1px solid #eef0f4;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.route-meta { background: #f8fafc; border-radius: 10px; padding: 10px 12px; }
.meta-row { display: flex; align-items: center; gap: 8px; }
.meta-icon { font-size: 13px; }
.meta-text { font-size: 12px; font-weight: 500; color: #334155; }
.meta-divider { width: 1px; height: 14px; background: #cbd5e1; margin: 4px 0 4px 6px; }

.sidebar-label {
  margin: 0;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  color: #94a3b8;
}

.route-card {
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  padding: 10px 12px;
  cursor: pointer;
  transition: all 0.18s ease;
  background: #fff;
}
.route-card:hover { border-color: var(--accent); background: #f8fafc; }
.route-card.active {
  border-color: var(--accent);
  background: color-mix(in srgb, var(--accent) 8%, white);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 15%, transparent);
}
.route-card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.route-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.route-badge {
  font-size: 10px; font-weight: 600;
  color: var(--accent);
  background: color-mix(in srgb, var(--accent) 12%, white);
  padding: 2px 7px; border-radius: 20px;
}
.route-card-stats { display: flex; gap: 12px; font-size: 12px; color: #64748b; }

.route-info-box { background: #f8fafc; border-radius: 12px; padding: 12px; margin-top: auto; }
.info-title { margin: 0 0 8px; font-size: 12px; font-weight: 700; color: #1e293b; }
.info-grid { display: flex; flex-direction: column; gap: 5px; }
.info-item { display: flex; justify-content: space-between; }
.info-label { font-size: 11px; color: #94a3b8; }
.info-value { font-size: 11px; font-weight: 600; color: #334155; }

.route-info-empty {
  margin-top: auto;
  display: flex; flex-direction: column; align-items: center;
  gap: 6px; padding: 16px; text-align: center;
  color: #94a3b8; font-size: 12px;
}
.route-info-empty span { font-size: 22px; }


.state-box {
  display: flex; flex-direction: column; align-items: center;
  gap: 8px; padding: 20px; text-align: center;
  font-size: 12px; color: #64748b;
}
.state-icon { font-size: 28px; }
.state-box.error { color: #dc2626; }
.retry-btn {
  margin-top: 4px; padding: 5px 14px;
  font-size: 12px; font-weight: 600;
  border: 1.5px solid #dc2626; border-radius: 8px;
  color: #dc2626; background: transparent;
  cursor: pointer; transition: all 0.15s;
}
.retry-btn:hover { background: #fef2f2; }

/* Map */
.map-body { flex: 1; position: relative; }
.map { height: 100%; width: 100%; cursor: crosshair; }

.map-loading {
  position: absolute; inset: 0;
  background: rgba(255,255,255,0.75);
  backdrop-filter: blur(3px);
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 10px; font-size: 13px; color: #64748b;
  z-index: 1000;
}

.map-hint-overlay {
  position: absolute;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1000;
  pointer-events: none;
}
.hint-pill {
  background: rgba(255,255,255,0.92);
  backdrop-filter: blur(6px);
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  padding: 8px 18px;
  font-size: 12px;
  font-weight: 500;
  color: #334155;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
  white-space: nowrap;
}

/* Spinner */
.spinner {
  width: 22px; height: 22px;
  border: 2.5px solid #e2e8f0;
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}
.spinner.large { width: 36px; height: 36px; border-width: 3.5px; }

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 3px rgba(34,197,94,0.2); }
  50%       { box-shadow: 0 0 0 6px rgba(34,197,94,0.08); }
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>