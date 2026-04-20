<script setup>
import { LMap, LTileLayer, LPolyline, LMarker, LTooltip } from "@vue-leaflet/vue-leaflet"
import "leaflet/dist/leaflet.css"
import { ref, computed, watch, onMounted } from "vue"
import { API_BASE_URL } from "../api/auth"
import {
  decorateRoutesWithCo2Limit,
  filterVisibleRoutes,
  normalizeMaxCo2Kg,
} from "../utils/routeFilter"

const props = defineProps({
  activeCarId: {
    type: Number,
    default: undefined,
  },
})

const mapRef = ref(null)
const zoom = ref(12)
const center = ref([54.6872, 25.2797])
const startCoord = ref([54.6872, 25.2797])

/** Next map click sets start or destination */
const mapTarget = ref("end")

const routes = ref([
  {
    id: 1,
    name: "Route A",
    from: "",
    to: "",
    distance: null,
    duration: null,
    type: "Alternate",
    points: [],
    distanceKmRaw: null,
    tripCo2Kg: null,
  },
  {
    id: 2,
    name: "Route B",
    from: "",
    to: "",
    distance: null,
    duration: null,
    type: "Alternate",
    points: [],
    distanceKmRaw: null,
    tripCo2Kg: null,
  },
  {
    id: 3,
    name: "Route C",
    from: "",
    to: "",
    distance: null,
    duration: null,
    type: "Alternate",
    points: [],
    distanceKmRaw: null,
    tripCo2Kg: null,
  },
])

const loading = ref(false)
const error = ref(null)
const clickedPoint = ref(null)
const hasRoutes = ref(false)

const emissionLoading = ref(false)
const emissionError = ref("")
const emissionData = ref(null)
const routeEmissionLoading = ref(false)
const routeEmissionError = ref("")

const maxCo2Kg = ref("")
const overLimitAction = ref("mark")

const CAR_REQUIRED_MSG =
  "Select a car in My cars (top right) before planning or choosing a route."

const startPlaceLabel = ref("")
const endPlaceLabel = ref("Click map (destination mode)")

async function reverseGeocodeLabel(latlng) {
  if (!latlng || latlng.length < 2) return "—"
  const fallback = formatCoordLabel(latlng)
  try {
    const token = getAuthToken()
    if (!token) return fallback
    const [lat, lng] = latlng
    const q = new URLSearchParams({ lat: String(lat), lng: String(lng) })
    const res = await fetch(`${API_BASE_URL}/geocode/reverse?${q}`, {
      headers: { Authorization: `Bearer ${token}` },
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) return fallback
    if (typeof data.label === "string" && data.label.trim()) return data.label.trim()
    return fallback
  } catch {
    return fallback
  }
}

onMounted(async () => {
  startPlaceLabel.value = await reverseGeocodeLabel(startCoord.value)
})

function getPerpOffset(start, end, factor) {
  const dlat = end[0] - start[0]
  const dlng = end[1] - start[1]
  const midLat = (start[0] + end[0]) / 2
  const midLng = (start[1] + end[1]) / 2
  return [midLat - dlng * factor, midLng + dlat * factor]
}

function formatCoordLabel(latlng) {
  if (!latlng || latlng.length < 2) return "—"
  return `${Number(latlng[0]).toFixed(4)}°, ${Number(latlng[1]).toFixed(4)}°`
}

function getAuthToken() {
  return localStorage.getItem("token")
}

async function fetchMapboxDirections(params) {
  const token = getAuthToken()
  if (!token) {
    throw new Error("AUTH_REQUIRED")
  }

  const q = new URLSearchParams({
    start_lat: String(params.start_lat),
    start_lng: String(params.start_lng),
    end_lat: String(params.end_lat),
    end_lng: String(params.end_lng),
  })
  if (params.via_lat != null && params.via_lng != null) {
    q.set("via_lat", String(params.via_lat))
    q.set("via_lng", String(params.via_lng))
  }

  const res = await fetch(`${API_BASE_URL}/directions?${q}`, {
    headers: { Authorization: `Bearer ${token}` },
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    const msg = Array.isArray(data.errors) ? data.errors.join(", ") : (data.error || res.statusText)
    throw new Error(msg || "Directions request failed")
  }
  if (data.code !== "Ok" || !data.routes?.[0]) {
    throw new Error("No route returned")
  }
  return data
}

function formatDistanceKm(distanceKm) {
  if (distanceKm == null || Number.isNaN(Number(distanceKm))) return "—"
  return `${Number(distanceKm).toFixed(2)} km`
}

function formatCo2Kg(value) {
  if (value == null || Number.isNaN(Number(value))) return "—"
  return `${Number(value).toFixed(3)} kg`
}

const normalizedMaxCo2Kg = computed(() => normalizeMaxCo2Kg(maxCo2Kg.value))

const routesWithFilterState = computed(() => {
  return decorateRoutesWithCo2Limit(routes.value, normalizedMaxCo2Kg.value)
})

const visibleRoutes = computed(() => filterVisibleRoutes(routesWithFilterState.value, overLimitAction.value))

function requireCarOrExplain() {
  if (props.activeCarId != null) return true
  error.value = CAR_REQUIRED_MSG
  return false
}

async function fetchRouteEmissionsForAll() {
  routeEmissionError.value = ""
  if (!hasRoutes.value || props.activeCarId == null) {
    routes.value.forEach((route) => {
      route.tripCo2Kg = null
    })
    return
  }

  const token = getAuthToken()
  if (!token) return

  routeEmissionLoading.value = true
  try {
    const responseData = await Promise.all(
      routes.value.map(async (route) => {
        if (route.distanceKmRaw == null) return { id: route.id, total_emission_kg: null }
        const res = await fetch(`${API_BASE_URL}/emissions/calculate`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: "application/json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            car_id: props.activeCarId,
            distance_km: route.distanceKmRaw,
          }),
        })
        const data = await res.json().catch(() => ({}))
        if (!res.ok) {
          throw new Error(typeof data.error === "string" ? data.error : "Route emissions request failed")
        }
        return { id: route.id, total_emission_kg: Number(data.total_emission_kg) }
      }),
    )
    const byId = new Map(responseData.map((item) => [item.id, item.total_emission_kg]))
    routes.value.forEach((route) => {
      const value = byId.get(route.id)
      route.tripCo2Kg = typeof value === "number" && !Number.isNaN(value) ? value : null
    })
  } catch (e) {
    routeEmissionError.value = e instanceof Error ? e.message : "Could not load route emissions."
  } finally {
    routeEmissionLoading.value = false
  }
}

async function fetchRoutes(endCoord) {
  if (!endCoord) return
  if (!requireCarOrExplain()) return

  loading.value = true
  error.value = null

  const offsets = [0, 0.3, -0.3]
  const start = startCoord.value

  try {
    const baseParams = {
      start_lat: start[0],
      start_lng: start[1],
      end_lat: endCoord[0],
      end_lng: endCoord[1],
    }

    const [results, fromLabel, toLabel] = await Promise.all([
      Promise.all(
        offsets.map(async (factor) => {
          let params = { ...baseParams }
          if (factor !== 0) {
            const wp = getPerpOffset(start, endCoord, factor)
            params = { ...params, via_lat: wp[0], via_lng: wp[1] }
          }
          return fetchMapboxDirections(params)
        }),
      ),
      reverseGeocodeLabel(start),
      reverseGeocodeLabel(endCoord),
    ])

    startPlaceLabel.value = fromLabel
    endPlaceLabel.value = toLabel

    results.forEach((mapboxData, i) => {
      const leg = mapboxData.routes[0]
      const km = leg.distance_km != null ? Number(leg.distance_km) : null
      routes.value[i].points = leg.geometry.coordinates.map(([lng, lat]) => [lat, lng])
      routes.value[i].distance = formatDistanceKm(km)
      routes.value[i].duration = `${Math.round(leg.duration / 60)} min`
      routes.value[i].from = fromLabel
      routes.value[i].to = toLabel
      routes.value[i].distanceKmRaw = km != null && !Number.isNaN(km) ? km : null
      routes.value[i].tripCo2Kg = null
    })

    hasRoutes.value = true
    selectedRouteId.value = null
    emissionData.value = null
    emissionError.value = ""

    const allPoints = results.flatMap((d) =>
      d.routes[0].geometry.coordinates.map(([lng, lat]) => [lat, lng]),
    )
    const lats = allPoints.map((p) => p[0])
    const lngs = allPoints.map((p) => p[1])
    const bounds = [
      [Math.min(...lats), Math.min(...lngs)],
      [Math.max(...lats), Math.max(...lngs)],
    ]
    mapRef.value.leafletObject.fitBounds(bounds, { padding: [40, 40] })
    fetchRouteEmissionsForAll()
  } catch (e) {
    error.value =
      e.message === "AUTH_REQUIRED"
        ? "Please sign in to calculate routes (JWT required)."
        : "Could not load routes. Please try again."
    console.error(e)
  } finally {
    loading.value = false
  }
}

function onMapClick(e) {
  const { lat, lng } = e.latlng
  if (!requireCarOrExplain()) return

  if (mapTarget.value === "start") {
    startCoord.value = [lat, lng]
    reverseGeocodeLabel(startCoord.value).then((t) => {
      startPlaceLabel.value = t
    })
    if (clickedPoint.value) {
      selectedRouteId.value = null
      fetchRoutes(clickedPoint.value)
    }
    return
  }

  clickedPoint.value = [lat, lng]
  selectedRouteId.value = null
  fetchRoutes([lat, lng])
}

const routeColors = {
  default: ["#93c5fd", "#86efac", "#fca5a5"],
  active: ["#2563eb", "#16a34a", "#dc2626"],
}

const selectedRouteId = ref(null)
const selectedRoute = computed(() => routes.value.find((r) => r.id === selectedRouteId.value) || null)

function getRouteColor(route, isActive) {
  const idx = routes.value.findIndex((r) => r.id === route.id)
  const safeIdx = idx >= 0 ? idx : 0
  return isActive ? routeColors.active[safeIdx] : routeColors.default[safeIdx]
}

function getRouteAccent(route) {
  const idx = routes.value.findIndex((r) => r.id === route.id)
  const safeIdx = idx >= 0 ? idx : 0
  return routeColors.active[safeIdx]
}

function canSelectRoute() {
  return props.activeCarId != null
}

function selectRoute(route) {
  if (!canSelectRoute()) return
  selectedRouteId.value = route.id
}

watch(
  () => [selectedRouteId.value, props.activeCarId, selectedRoute.value?.distanceKmRaw],
  async () => {
    emissionData.value = null
    emissionError.value = ""
    const r = selectedRoute.value
    if (!r || selectedRouteId.value == null || props.activeCarId == null || r.distanceKmRaw == null) {
      emissionLoading.value = false
      return
    }

    const token = getAuthToken()
    if (!token) return

    emissionLoading.value = true
    try {
      const res = await fetch(`${API_BASE_URL}/emissions/calculate`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          car_id: props.activeCarId,
          distance_km: r.distanceKmRaw,
        }),
      })
      const data = await res.json().catch(() => ({}))
      if (!res.ok) {
        throw new Error(typeof data.error === "string" ? data.error : "Emissions request failed")
      }
      emissionData.value = data
    } catch (e) {
      emissionError.value = e instanceof Error ? e.message : "Could not load emissions."
    } finally {
      emissionLoading.value = false
    }
  },
  { flush: "post" },
)

watch(
  () => [hasRoutes.value, props.activeCarId],
  () => {
    if (hasRoutes.value && props.activeCarId != null) fetchRouteEmissionsForAll()
  },
)

watch(
  [visibleRoutes, () => selectedRouteId.value],
  ([nextVisible]) => {
    if (!nextVisible.find((route) => route.id === selectedRouteId.value)) {
      selectedRouteId.value = null
      emissionData.value = null
      emissionError.value = ""
    }
  },
)

watch(
  () => props.activeCarId,
  (id) => {
    if (id == null) {
      selectedRouteId.value = null
      emissionData.value = null
      emissionError.value = ""
      routes.value.forEach((route) => {
        route.tripCo2Kg = null
      })
      routeEmissionError.value = ""
    } else if (error.value === CAR_REQUIRED_MSG) {
      error.value = null
    }
  },
)
</script>

<template>
  <div class="map-wrapper">
    <div class="map-card">
      <div class="map-header">
        <span class="map-dot" />
        <p class="map-title">Route Planner</p>
      </div>

      <div class="map-content">
        <div class="sidebar">
          <div class="route-meta">
            <p class="meta-hint">Choose what the next map click sets:</p>
            <div class="mode-row">
              <button
                type="button"
                class="mode-btn"
                :class="{ active: mapTarget === 'start' }"
                @click="mapTarget = 'start'"
              >
                Set start
              </button>
              <button
                type="button"
                class="mode-btn"
                :class="{ active: mapTarget === 'end' }"
                @click="mapTarget = 'end'"
              >
                Set destination
              </button>
            </div>
            <div class="meta-row">
              <span class="meta-icon">📍</span>
              <span class="meta-text meta-text--place">{{ startPlaceLabel || formatCoordLabel(startCoord) }}</span>
            </div>
            <div class="meta-divider" />
            <div class="meta-row">
              <span class="meta-icon">🏁</span>
              <span class="meta-text meta-text--place">{{
                clickedPoint ? endPlaceLabel : "Click map (destination mode)"
              }}</span>
            </div>
          </div>

          <p class="sidebar-label">Available Routes</p>
          <div v-if="hasRoutes" class="filters-box">
            <p class="filters-title">CO₂ filter</p>
            <label class="filter-label">
              Max trip CO₂ (kg)
              <input
                v-model="maxCo2Kg"
                type="number"
                min="0"
                step="0.001"
                class="filter-input"
                placeholder="No limit"
              />
            </label>
            <div class="filter-mode">
              <label>
                <input v-model="overLimitAction" type="radio" value="mark" />
                Mark routes over limit
              </label>
              <label>
                <input v-model="overLimitAction" type="radio" value="hide" />
                Hide routes over limit
              </label>
            </div>
          </div>

          <div v-if="!activeCarId" class="state-box car-hint">
            <span class="state-icon">🚗</span>
            <p>Open <strong>My cars</strong> (top right) and pick or add a car to plan routes and see emissions.</p>
          </div>

          <div v-else-if="!hasRoutes && !loading && !error" class="state-box">
            <span class="state-icon">🗺️</span>
            <p>
              {{
                mapTarget === "start"
                  ? "Click the map to set the start point, then switch to Set destination."
                  : "Click the map to set the destination and load routes."
              }}
            </p>
          </div>

          <div v-else-if="loading" class="state-box">
            <div class="spinner" />
            <p>Calculating routes...</p>
          </div>

          <div v-else-if="error" class="state-box error">
            <span>⚠️</span>
            <p>{{ error }}</p>
            <button
              v-if="clickedPoint && activeCarId"
              type="button"
              class="retry-btn"
              @click="fetchRoutes(clickedPoint)"
            >
              Retry
            </button>
          </div>

          <template v-else>
            <div
              v-for="route in visibleRoutes"
              :key="route.id"
              class="route-card"
              :class="{
                active: selectedRouteId === route.id,
                disabled: !canSelectRoute(),
                overlimit: route.exceedsCo2Limit && overLimitAction === 'mark',
              }"
              :style="{ '--accent': getRouteAccent(route) }"
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
              <div class="route-card-stats">
                <span>🌿 {{ formatCo2Kg(route.tripCo2Kg) }}</span>
                <span v-if="route.exceedsCo2Limit && overLimitAction === 'mark'" class="overlimit-tag">
                  Above CO₂ limit
                </span>
              </div>
            </div>
            <div v-if="routeEmissionLoading" class="emission-muted">Refreshing route CO₂ values…</div>
            <div v-if="routeEmissionError" class="emission-err">{{ routeEmissionError }}</div>
            <div
              v-if="overLimitAction === 'hide' && normalizedMaxCo2Kg != null && visibleRoutes.length === 0"
              class="state-box"
            >
              <span class="state-icon">🧪</span>
              <p>No routes match current CO₂ limit. Increase limit or switch filter mode.</p>
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

                <div class="emission-block">
                  <p class="emission-title">CO₂ estimate (your car)</p>
                  <div v-if="emissionLoading" class="emission-muted">Calculating emissions…</div>
                  <div v-else-if="emissionError" class="emission-err">{{ emissionError }}</div>
                  <template v-else-if="emissionData">
                    <div class="info-item">
                      <span class="info-label">Trip CO₂</span>
                      <span class="info-value">{{ Number(emissionData.total_emission_kg).toFixed(3) }} kg</span>
                    </div>
                    <div class="info-item">
                      <span class="info-label">Rate</span>
                      <span class="info-value">{{ emissionData.emission_rate_g_per_km }} g/km</span>
                    </div>
                  </template>
                  <div v-else class="emission-muted">—</div>
                </div>
              </div>
              <div v-else class="route-info-empty">
                <span>👆</span>
                <p v-if="!canSelectRoute()">Select a car in My cars to choose a route.</p>
                <p v-else>Click a route card or line on the map to view details and emissions.</p>
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
                v-for="(route, idx) in visibleRoutes"
                :key="route.id"
                :bubbling-mouse-events="false"
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
            <div class="hint-pill">
              {{
                !activeCarId
                  ? "Select a car in My cars first"
                  : mapTarget === "start"
                    ? "Click map to set start"
                    : "Click map to set destination"
              }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.map-wrapper {
  min-height: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e8edf5 0%, #dce3ee 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  box-sizing: border-box;
  font-family: "Inter", sans-serif;
}

.map-card {
  width: 100%;
  max-width: 100%;
  height: 100%;
  background: #ffffff;
  border-radius: 0;
  box-shadow:
    0 2px 4px rgba(0, 0, 0, 0.04),
    0 8px 24px rgba(0, 0, 0, 0.1);
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
.map-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.map-content {
  display: flex;
  height: calc(100% - 49px);
}

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

.route-meta {
  background: #f8fafc;
  border-radius: 10px;
  padding: 10px 12px;
}
.meta-hint {
  margin: 0 0 8px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #94a3b8;
}
.mode-row {
  display: flex;
  gap: 6px;
  margin-bottom: 10px;
}
.mode-btn {
  flex: 1;
  padding: 6px 8px;
  font-size: 11px;
  font-weight: 600;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  color: #64748b;
  cursor: pointer;
  transition:
    background 0.15s,
    border-color 0.15s,
    color 0.15s;
}
.mode-btn:hover {
  border-color: #cbd5e1;
  color: #334155;
}
.mode-btn.active {
  border-color: #2563eb;
  background: #eff6ff;
  color: #1d4ed8;
}
.meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.meta-icon {
  font-size: 13px;
}
.meta-text {
  font-size: 12px;
  font-weight: 500;
  color: #334155;
  word-break: break-all;
}
.meta-text--place {
  word-break: break-word;
}
.meta-divider {
  width: 1px;
  height: 14px;
  background: #cbd5e1;
  margin: 4px 0 4px 6px;
}

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
.route-card:hover:not(.disabled) {
  border-color: var(--accent);
  background: #f8fafc;
}
.route-card.active {
  border-color: var(--accent);
  background: color-mix(in srgb, var(--accent) 8%, white);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 15%, transparent);
}
.route-card.overlimit {
  border-color: #f59e0b;
  background: #fffbeb;
}
.route-card.disabled {
  cursor: not-allowed;
  opacity: 0.45;
  pointer-events: none;
}
.route-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}
.route-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}
.route-badge {
  font-size: 10px;
  font-weight: 600;
  color: var(--accent);
  background: color-mix(in srgb, var(--accent) 12%, white);
  padding: 2px 7px;
  border-radius: 20px;
}
.route-card-stats {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: #64748b;
}
.overlimit-tag {
  font-size: 10px;
  font-weight: 700;
  color: #b45309;
}

.filters-box {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.filters-title {
  margin: 0;
  font-size: 11px;
  font-weight: 700;
  color: #334155;
}
.filter-label {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 11px;
  color: #64748b;
}
.filter-input {
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 6px 8px;
  font-size: 12px;
}
.filter-mode {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 11px;
  color: #334155;
}

.route-info-box {
  background: #f8fafc;
  border-radius: 12px;
  padding: 12px;
  margin-top: auto;
}
.info-title {
  margin: 0 0 8px;
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}
.info-grid {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.info-item {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}
.info-label {
  font-size: 11px;
  color: #94a3b8;
  flex-shrink: 0;
}
.info-value {
  font-size: 11px;
  font-weight: 600;
  color: #334155;
  text-align: right;
}

.emission-block {
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px solid #e2e8f0;
}
.emission-title {
  margin: 0 0 8px;
  font-size: 11px;
  font-weight: 700;
  color: #0f172a;
}
.emission-muted {
  font-size: 11px;
  color: #94a3b8;
}
.emission-err {
  font-size: 11px;
  color: #dc2626;
}

.route-info-empty {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 16px;
  text-align: center;
  color: #94a3b8;
  font-size: 12px;
}
.route-info-empty span {
  font-size: 22px;
}

.state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 20px;
  text-align: center;
  font-size: 12px;
  color: #64748b;
}
.state-box.car-hint {
  background: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 12px;
  color: #92400e;
}
.state-box.car-hint strong {
  font-weight: 700;
}
.state-icon {
  font-size: 28px;
}
.state-box.error {
  color: #dc2626;
}
.retry-btn {
  margin-top: 4px;
  padding: 5px 14px;
  font-size: 12px;
  font-weight: 600;
  border: 1.5px solid #dc2626;
  border-radius: 8px;
  color: #dc2626;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.retry-btn:hover {
  background: #fef2f2;
}

.map-body {
  flex: 1;
  position: relative;
}
.map {
  height: 100%;
  width: 100%;
  cursor: crosshair;
}

.map-loading {
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.75);
  backdrop-filter: blur(3px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  font-size: 13px;
  color: #64748b;
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
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(6px);
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  padding: 8px 18px;
  font-size: 12px;
  font-weight: 500;
  color: #334155;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  white-space: nowrap;
}

.spinner {
  width: 22px;
  height: 22px;
  border: 2.5px solid #e2e8f0;
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}
.spinner.large {
  width: 36px;
  height: 36px;
  border-width: 3.5px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@keyframes pulse {
  0%,
  100% {
    box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2);
  }
  50% {
    box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.08);
  }
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
