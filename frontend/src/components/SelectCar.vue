<script setup>
import { ref, computed, watch } from "vue"
import axios from "axios"
import { API_BASE_URL } from "../api/http"

const emit = defineEmits(["active-car-change"])

/* ---------------- API ---------------- */

const NGROK_HEADER = { "ngrok-skip-browser-warning": "true" }

const api = axios.create({ baseURL: API_BASE_URL, headers: NGROK_HEADER })

const getToken = () => localStorage.getItem("token")

const authApi = () => axios.create({
  baseURL: API_BASE_URL,
  headers: { ...NGROK_HEADER, Authorization: `Bearer ${getToken()}` }
})

const fetchBrands       = ()                     => api.get("/cars/brands").then(r => r.data)
const fetchModels       = (brand)                => api.get("/cars/models",     { params: { brand_name: brand } }).then(r => r.data)
const fetchFuelTypes    = (brand, model)         => api.get("/cars/fuel_types", { params: { brand_name: brand, model } }).then(r => r.data)
const fetchYears        = (brand, model, fuelId) => api.get("/cars/years",      { params: { brand_name: brand, model, fuel_type_id: fuelId } }).then(r => r.data)
const findCar           = (brand, model, fuelId, year) => api.get("/cars", { params: { brand_name: brand, model, fuel_type_id: fuelId, year } }).then(r => r.data)
const createCatalogCar  = (payload)              => api.post("/cars", payload).then(r => r.data)

const fetchUserCars  = ()       => authApi().get("/me/cars").then(r => r.data)
const assignUserCar  = (car_id) => authApi().post("/me/cars", { car_id }).then(r => r.data)
const deleteUserCar  = (car_id) => authApi().delete(`/me/cars/${car_id}`).then(r => r.data)

/* ---------------- STATE ---------------- */

const cars     = ref([])
const activeId = ref(null)
const loading  = ref(false)
const error    = ref("")

const activeCar = computed(() => cars.value.find(c => c.id === activeId.value))

watch(
  activeId,
  (id) => {
    emit("active-car-change", id ?? null)
  },
  { immediate: true },
)

/* ---------------- FORM ---------------- */

const showModal  = ref(false)
const editTarget = ref(null)
const saving     = ref(false)
const saveError  = ref("")

// mode: 'catalog' | 'custom'
const mode = ref("catalog")

// catalog mode fields
const form = ref({ make: "", model: "", fuel_type_id: "", year: "" })

// custom mode fields
const custom = ref({ brand_name: "", model: "", fuel_type_id: "", year: "", co2_emission: "" })

/* ---------------- DROPDOWN OPTIONS ---------------- */

const brands    = ref([])
const models    = ref([])
const fuelTypes = ref([])   // catalog cascade
const years     = ref([])

const allFuelTypes = ref([])  // custom mode: all fuel types

const loadingBrands    = ref(false)
const loadingModels    = ref(false)
const loadingFuel      = ref(false)
const loadingYears     = ref(false)
const loadingAllFuel   = ref(false)
const brandsError      = ref(false)

/* ---------------- HELPERS ---------------- */

function makeColor(make) {
  const palette = ["#5b6cf6","#34d399","#f59e0b","#ef4444","#8b5cf6","#06b6d4","#ec4899","#10b981"]
  let hash = 0
  for (let i = 0; i < (make || "").length; i++) hash = make.charCodeAt(i) + ((hash << 5) - hash)
  return palette[Math.abs(hash) % palette.length]
}

function initials(make) { return (make || "").slice(0, 2).toUpperCase() }

/* ---------------- LOAD USER CARS ---------------- */

async function loadUserCars() {
  loading.value = true
  error.value   = ""
  try {
    const data = await fetchUserCars()
    cars.value  = data
    if (!activeId.value && data.length) activeId.value = data[0].id
  } catch (e) {
    if (e.response?.status === 401) cars.value = []
    else error.value = "Could not load cars."
  } finally {
    loading.value = false
  }
}

loadUserCars()

/* ---------------- DROPDOWN LOADERS ---------------- */

async function loadBrands() {
  loadingBrands.value = true
  brandsError.value   = false
  brands.value        = []
  try {
    const data = await fetchBrands()
    brands.value = Array.isArray(data) ? data : []
  } catch (e) {
    console.error("loadBrands failed:", e)
    brandsError.value = true
  } finally {
    loadingBrands.value = false
  }
}

async function loadModels(brand) {
  if (!brand) return
  loadingModels.value = true
  try { models.value = await fetchModels(brand) }
  finally { loadingModels.value = false }
}

async function loadFuel(brand, model) {
  if (!brand || !model) return
  loadingFuel.value = true
  try { fuelTypes.value = await fetchFuelTypes(brand, model) }
  finally { loadingFuel.value = false }
}

async function loadYears(brand, model, fuelId) {
  if (!brand || !model || !fuelId) return
  loadingYears.value = true
  try { years.value = await fetchYears(brand, model, fuelId) }
  finally { loadingYears.value = false }
}

// Hardcoded fallback fuel types in case all API probes fail
const FALLBACK_FUEL_TYPES = [
  { id: 1, name: "Petrol" },
  { id: 2, name: "Diesel" },
  { id: 3, name: "Electric" },
  { id: 4, name: "Hybrid" },
  { id: 5, name: "Plug-in Hybrid" },
  { id: 6, name: "LPG" },
]

// For custom mode: probe several brand/model combos to build a full deduplicated fuel type list
async function loadAllFuelTypes() {
  if (allFuelTypes.value.length) return
  loadingAllFuel.value = true
  try {
    const probes = [
      ["TOYOTA",     "Yaris"],
      ["VOLKSWAGEN", "Golf"],
      ["BMW",        "3 Series"],
      ["TESLA",      "Model 3"],
      ["RENAULT",    "Clio"],
    ]
    const seen = new Map()
    for (const [brand, model] of probes) {
      try {
        const data = await fetchFuelTypes(brand, model)
        if (Array.isArray(data)) {
          for (const ft of data) {
            if (!seen.has(ft.id)) seen.set(ft.id, ft)
          }
        }
      } catch { /* skip failed probes */ }
    }
    allFuelTypes.value = seen.size > 0
      ? Array.from(seen.values()).sort((a, b) => a.id - b.id)
      : FALLBACK_FUEL_TYPES
  } catch {
    allFuelTypes.value = FALLBACK_FUEL_TYPES
  } finally {
    loadingAllFuel.value = false
  }
}

/* ---------------- WATCHERS (catalog cascade) ---------------- */

watch(() => form.value.make, async (val) => {
  form.value.model        = ""
  form.value.fuel_type_id = ""
  form.value.year         = ""
  models.value    = []
  fuelTypes.value = []
  years.value     = []
  if (val) await loadModels(val)
})

watch(() => form.value.model, async (val) => {
  form.value.fuel_type_id = ""
  form.value.year         = ""
  fuelTypes.value = []
  years.value     = []
  if (val) await loadFuel(form.value.make, val)
})

watch(() => form.value.fuel_type_id, async (val) => {
  form.value.year = ""
  years.value     = []
  if (val) await loadYears(form.value.make, form.value.model, val)
})

/* ---------------- MODE SWITCH ---------------- */

async function switchMode(m) {
  mode.value      = m
  saveError.value = ""
  if (m === "custom" && !allFuelTypes.value.length) await loadAllFuelTypes()
}

/* ---------------- MODAL ACTIONS ---------------- */

function closeModal() {
  showModal.value = false
  saveError.value = ""
}

async function openAdd() {
  editTarget.value = null
  mode.value       = "catalog"
  form.value       = { make: "", model: "", fuel_type_id: "", year: "" }
  custom.value     = { brand_name: "", model: "", fuel_type_id: "", year: "", co2_emission: "" }
  models.value     = []
  fuelTypes.value  = []
  years.value      = []
  saveError.value  = ""
  showModal.value  = true
  await loadBrands()
}

async function openEdit(car) {
  editTarget.value = car
  mode.value       = "catalog"
  form.value = {
    make:         car.brand_name,
    model:        car.model,
    fuel_type_id: car.fuel_type?.id ?? "",
    year:         car.year
  }
  custom.value    = { brand_name: "", model: "", fuel_type_id: "", year: "", co2_emission: "" }
  saveError.value = ""
  showModal.value = true
  await loadBrands()
  await loadModels(car.brand_name)
  await loadFuel(car.brand_name, car.model)
  await loadYears(car.brand_name, car.model, car.fuel_type?.id)
}

/* ---------------- SAVE ---------------- */

async function saveForm() {
  if (mode.value === "catalog" && !canSaveCatalog.value) return
  if (mode.value === "custom"  && !canSaveCustom.value)  return

  saving.value    = true
  saveError.value = ""

  try {
    if (mode.value === "catalog") {
      await saveCatalogCar()
    } else {
      await saveCustomCar()
    }
    closeModal()
  } catch (e) {
    const msg = e.response?.data?.error || e.response?.data?.errors
    saveError.value = typeof msg === "string" ? msg
      : (msg && typeof msg === "object" ? Object.values(msg).join(", ") : "Failed to save car. Please try again.")
  } finally {
    saving.value = false
  }
}

async function saveCatalogCar() {
  const { make, model, fuel_type_id, year } = form.value
  const catalogCar = await findCar(make, model, fuel_type_id, year)
  const isEmpty = !catalogCar || (Array.isArray(catalogCar) && catalogCar.length === 0)
  if (isEmpty) throw new Error("catalog_not_found")
  const targetId = Array.isArray(catalogCar) ? catalogCar[0]?.id : catalogCar.id
  if (!targetId) throw new Error("catalog_not_found")

  if (editTarget.value) {
    try { await deleteUserCar(editTarget.value.id) } catch { /* best effort */ }
    const saved = await assignUserCar(targetId)
    const idx = cars.value.findIndex(c => c.id === editTarget.value.id)
    if (idx !== -1) cars.value.splice(idx, 1, saved)
    else cars.value.push(saved)
    if (activeId.value === editTarget.value.id) activeId.value = saved.id
  } else {
    const saved = await assignUserCar(targetId)
    cars.value.push(saved)
    if (!activeId.value) activeId.value = saved.id
  }
}

async function saveCustomCar() {
  const { brand_name, model, fuel_type_id, year, co2_emission } = custom.value

  // Create the catalog entry
  const created = await createCatalogCar({
    brand_name:   brand_name.trim().toUpperCase(),
    model:        model.trim(),
    fuel_type_id: Number(fuel_type_id),
    year:         Number(year),
    co2_emission: parseFloat(co2_emission)
  })

  // Assign to user
  if (editTarget.value) {
    try { await deleteUserCar(editTarget.value.id) } catch { /* best effort */ }
    const saved = await assignUserCar(created.id)
    const idx = cars.value.findIndex(c => c.id === editTarget.value.id)
    if (idx !== -1) cars.value.splice(idx, 1, saved)
    else cars.value.push(saved)
    if (activeId.value === editTarget.value.id) activeId.value = saved.id
  } else {
    const saved = await assignUserCar(created.id)
    cars.value.push(saved)
    if (!activeId.value) activeId.value = saved.id
  }
}

/* ---------------- DELETE ---------------- */

async function deleteCar(id) {
  try { await deleteUserCar(id) } catch { /* best effort */ }
  cars.value = cars.value.filter(c => c.id !== id)
  if (activeId.value === id) activeId.value = cars.value[0]?.id || null
}

/* ---------------- SET ACTIVE ---------------- */

function setActive(id) { activeId.value = id }

/* ---------------- CAN SAVE ---------------- */

const canSaveCatalog = computed(() =>
  form.value.make && form.value.model && form.value.fuel_type_id && form.value.year
)

const canSaveCustom = computed(() => {
  const c = custom.value
  return c.brand_name.trim() && c.model.trim() && c.fuel_type_id &&
         c.year && Number(c.year) > 1900 && Number(c.year) <= new Date().getFullYear() + 1 &&
         c.co2_emission && parseFloat(c.co2_emission) >= 0
})

const canSave = computed(() =>
  mode.value === "catalog" ? canSaveCatalog.value : canSaveCustom.value
)
</script>

<template>
  <div class="page">
    <div class="panel">

      <!-- Topbar -->
      <div class="topbar">
        <div class="topbar-left">
          <svg class="topbar-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3"/>
            <rect x="9" y="11" width="14" height="10" rx="2"/>
            <circle cx="12" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
          </svg>
          <div>
            <h1 class="topbar-title">My cars</h1>
            <p class="topbar-sub">{{ cars.length }} saved · {{ activeCar ? activeCar.brand_name + ' ' + activeCar.model : '—' }} active</p>
          </div>
        </div>
        <button class="btn-add" @click="openAdd">
          <span class="btn-add-icon">+</span> Add
        </button>
      </div>

      <!-- Error banner -->
      <div v-if="error" class="error-banner">{{ error }}</div>

      <!-- Loading skeleton -->
      <div v-if="loading" class="skeleton-wrap">
        <div class="skeleton-hero" />
        <div class="skeleton-row" v-for="i in 2" :key="i" />
      </div>

      <template v-else>
        <!-- Hero -->
        <div v-if="activeCar" class="hero">
          <div class="hero-badge" :style="{ background: makeColor(activeCar.brand_name) }">{{ initials(activeCar.brand_name) }}</div>
          <div class="hero-info">
            <div class="hero-name">{{ activeCar.brand_name }} {{ activeCar.model }}</div>
            <div class="hero-year">{{ activeCar.year }} · {{ activeCar.fuel_type?.name }} · Active car</div>
          </div>
          <div class="hero-pulse"><span class="pulse-dot" />Active</div>
        </div>
        <div v-else class="hero hero-empty"><p>No active car</p></div>

        <!-- List -->
        <div class="list-header"><span class="list-label">All cars</span></div>

        <div class="list">
          <transition-group name="car-list">
            <div
              v-for="car in cars" :key="car.id"
              class="car-row" :class="{ 'car-row--active': car.id === activeId }"
              @click="setActive(car.id)"
            >
              <div class="car-avatar" :style="{ background: makeColor(car.brand_name) }">{{ initials(car.brand_name) }}</div>
              <div class="car-info">
                <div class="car-name">{{ car.brand_name }} {{ car.model }}</div>
                <div class="car-meta">{{ car.year }} · {{ car.fuel_type?.name }} · {{ car.co2_emission }} g/km</div>
              </div>
              <div class="car-actions" @click.stop>
                <button class="action-btn action-btn--active" :class="{ selected: car.id === activeId }" @click="setActive(car.id)" title="Set active">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="20 6 9 17 4 12"/></svg>
                </button>
                <button class="action-btn" @click="openEdit(car)" title="Edit">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <button class="action-btn action-btn--del" @click="deleteCar(car.id)" title="Remove">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                    <path d="M10 11v6M14 11v6"/>
                    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                  </svg>
                </button>
              </div>
            </div>
          </transition-group>

          <div v-if="cars.length === 0" class="list-empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3"/>
              <rect x="9" y="11" width="14" height="10" rx="2"/>
            </svg>
            <p>No saved cars</p>
            <button class="btn-add-inline" @click="openAdd">Add your first car</button>
          </div>
        </div>
      </template>
    </div>

    <!-- Modal -->
    <transition name="modal">
      <div v-if="showModal" class="modal-backdrop" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h2 class="modal-title">{{ editTarget ? 'Edit car' : 'Add car' }}</h2>
            <button class="modal-close" @click="closeModal">×</button>
          </div>

          <!-- Mode tabs -->
          <div class="mode-tabs">
            <button class="mode-tab" :class="{ 'mode-tab--active': mode === 'catalog' }" @click="switchMode('catalog')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
              From catalog
            </button>
            <button class="mode-tab" :class="{ 'mode-tab--active': mode === 'custom' }" @click="switchMode('custom')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>
              Custom car
            </button>
          </div>

          <div class="modal-body">

            <!-- ===== CATALOG MODE ===== -->
            <template v-if="mode === 'catalog'">

              <!-- Brand -->
              <div class="field">
                <label class="flabel">Brand</label>
                <div class="sel-wrap">
                  <div v-if="brandsError" class="field-error">
                    Failed to load brands. Check console for details.
                    <button class="retry-link" @click="loadBrands">Retry</button>
                  </div>
                  <template v-else>
                    <select v-model="form.make" class="fselect" :disabled="loadingBrands">
                      <option value="" disabled>{{ loadingBrands ? 'Loading…' : 'Select brand' }}</option>
                      <option v-for="b in brands" :key="b" :value="b">{{ b }}</option>
                    </select>
                    <span v-if="loadingBrands" class="sel-spinner" />
                    <span v-else class="sel-arrow">↓</span>
                  </template>
                </div>
              </div>

              <!-- Model -->
              <div class="field" :class="{ 'field--off': !form.make }">
                <label class="flabel">Model</label>
                <div class="sel-wrap">
                  <select v-model="form.model" class="fselect" :disabled="!form.make || loadingModels">
                    <option value="" disabled>{{ loadingModels ? 'Loading…' : 'Select model' }}</option>
                    <option v-for="m in models" :key="m" :value="m">{{ m }}</option>
                  </select>
                  <span v-if="loadingModels" class="sel-spinner" />
                  <span v-else class="sel-arrow">↓</span>
                </div>
              </div>

              <!-- Fuel type -->
              <div class="field" :class="{ 'field--off': !form.model }">
                <label class="flabel">Fuel type</label>
                <div class="sel-wrap">
                  <select v-model="form.fuel_type_id" class="fselect" :disabled="!form.model || loadingFuel">
                    <option value="" disabled>{{ loadingFuel ? 'Loading…' : 'Select fuel type' }}</option>
                    <option v-for="f in fuelTypes" :key="f.id" :value="f.id">{{ f.name }}</option>
                  </select>
                  <span v-if="loadingFuel" class="sel-spinner" />
                  <span v-else class="sel-arrow">↓</span>
                </div>
              </div>

              <!-- Year -->
              <div class="field" :class="{ 'field--off': !form.fuel_type_id }">
                <label class="flabel">Year</label>
                <div class="sel-wrap">
                  <select v-model="form.year" class="fselect" :disabled="!form.fuel_type_id || loadingYears">
                    <option value="" disabled>{{ loadingYears ? 'Loading…' : 'Select year' }}</option>
                    <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
                  </select>
                  <span v-if="loadingYears" class="sel-spinner" />
                  <span v-else class="sel-arrow">↓</span>
                </div>
              </div>

            </template>

            <!-- ===== CUSTOM MODE ===== -->
            <template v-else>

              <div class="custom-notice">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>
                Can't find your car? Enter its details manually and it will be added to the catalog.
              </div>

              <!-- Brand -->
              <div class="field">
                <label class="flabel">Brand</label>
                <input
                  v-model="custom.brand_name"
                  class="finput"
                  type="text"
                  placeholder="e.g. HONDA"
                  autocomplete="off"
                />
              </div>

              <!-- Model -->
              <div class="field">
                <label class="flabel">Model</label>
                <input
                  v-model="custom.model"
                  class="finput"
                  type="text"
                  placeholder="e.g. Civic"
                  autocomplete="off"
                />
              </div>

              <!-- Fuel type -->
              <div class="field">
                <label class="flabel">Fuel type</label>
                <div class="sel-wrap">
                  <select v-model="custom.fuel_type_id" class="fselect" :disabled="loadingAllFuel">
                    <option value="" disabled>{{ loadingAllFuel ? 'Loading…' : 'Select fuel type' }}</option>
                    <option v-for="f in allFuelTypes" :key="f.id" :value="f.id">{{ f.name }}</option>
                  </select>
                  <span v-if="loadingAllFuel" class="sel-spinner" />
                  <span v-else class="sel-arrow">↓</span>
                </div>
              </div>

              <!-- Year + CO2 side by side -->
              <div class="field-row">
                <div class="field">
                  <label class="flabel">Year</label>
                  <input
                    v-model="custom.year"
                    class="finput"
                    type="number"
                    placeholder="e.g. 2023"
                    min="1900"
                    :max="new Date().getFullYear() + 1"
                  />
                </div>
                <div class="field">
                  <label class="flabel">CO₂ (g/km)</label>
                  <input
                    v-model="custom.co2_emission"
                    class="finput"
                    type="number"
                    placeholder="e.g. 142"
                    min="0"
                    step="0.1"
                  />
                </div>
              </div>

            </template>

            <!-- Save error -->
            <div v-if="saveError" class="field-error save-error">{{ saveError }}</div>

          </div>

          <div class="modal-footer">
            <button class="btn-cancel" @click="closeModal" :disabled="saving">Cancel</button>
            <button
              class="btn-save"
              :class="{ 'btn-save--on': canSave && !saving }"
              :disabled="!canSave || saving"
              @click="saveForm"
            >
              <span v-if="saving" class="btn-spinner" />
              <span v-else>{{ editTarget ? 'Save' : 'Add' }}</span>
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700&family=DM+Sans:wght@400;500&display=swap');

*, *::before, *::after { box-sizing: border-box; }

.page {
  min-height: 100vh;
  background: #0f1117;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px 16px;
  font-family: 'DM Sans', sans-serif;
}
.panel {
  width: 100%;
  max-width: 480px;
  background: #181c27;
  border-radius: 20px;
  border: 1px solid #272d3d;
  overflow: hidden;
  box-shadow: 0 32px 64px rgba(0,0,0,0.5);
}

/* Topbar */
.topbar { display: flex; align-items: center; justify-content: space-between; padding: 22px 24px 18px; border-bottom: 1px solid #272d3d; }
.topbar-left { display: flex; align-items: center; gap: 12px; }
.topbar-icon { width: 22px; height: 22px; color: #5b6cf6; flex-shrink: 0; }
.topbar-title { margin: 0 0 2px; font-family: 'Syne', sans-serif; font-size: 16px; font-weight: 700; color: #f1f3f9; letter-spacing: -0.2px; }
.topbar-sub { margin: 0; font-size: 11px; color: #4a5268; }
.btn-add { display: flex; align-items: center; gap: 6px; padding: 8px 16px; background: #5b6cf6; color: #fff; border: none; border-radius: 10px; font-family: 'Syne', sans-serif; font-size: 13px; font-weight: 600; cursor: pointer; transition: background 0.15s, transform 0.1s; }
.btn-add:hover { background: #4a5ae5; transform: translateY(-1px); }
.btn-add-icon { font-size: 16px; line-height: 1; }

/* Error banner */
.error-banner { margin: 12px 24px; padding: 10px 14px; background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.25); border-radius: 10px; color: #ef4444; font-size: 12px; }

/* Skeleton */
.skeleton-wrap { padding: 16px 24px; display: flex; flex-direction: column; gap: 10px; }
.skeleton-hero { height: 64px; border-radius: 12px; background: linear-gradient(90deg, #1e2235 25%, #272d3d 50%, #1e2235 75%); background-size: 200% 100%; animation: shimmer 1.4s infinite; }
.skeleton-row  { height: 52px; border-radius: 12px; background: linear-gradient(90deg, #1e2235 25%, #272d3d 50%, #1e2235 75%); background-size: 200% 100%; animation: shimmer 1.4s infinite; }

/* Hero */
.hero { display: flex; align-items: center; gap: 14px; padding: 18px 24px; background: linear-gradient(135deg, #1e2235 0%, #181c27 100%); border-bottom: 1px solid #272d3d; }
.hero-empty { justify-content: center; color: #4a5268; font-size: 13px; }
.hero-badge { width: 46px; height: 46px; border-radius: 13px; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 15px; font-weight: 700; color: #fff; flex-shrink: 0; }
.hero-info { flex: 1; }
.hero-name { font-family: 'Syne', sans-serif; font-size: 15px; font-weight: 700; color: #f1f3f9; letter-spacing: -0.2px; }
.hero-year { font-size: 11px; color: #4a5268; margin-top: 2px; }
.hero-pulse { display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 600; color: #34d399; background: rgba(52,211,153,0.1); padding: 5px 10px; border-radius: 20px; border: 1px solid rgba(52,211,153,0.2); }
.pulse-dot { width: 6px; height: 6px; background: #34d399; border-radius: 50%; animation: pulse 2s infinite; }

/* List */
.list-header { padding: 14px 24px 8px; }
.list-label { font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; color: #4a5268; }
.list { padding: 0 12px 16px; display: flex; flex-direction: column; gap: 4px; }
.car-row { display: flex; align-items: center; gap: 12px; padding: 11px 12px; border-radius: 12px; cursor: pointer; border: 1px solid transparent; transition: background 0.15s, border-color 0.15s; }
.car-row:hover { background: #1e2235; }
.car-row--active { background: #1e2235; border-color: #2d3452; }
.car-avatar { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-family: 'Syne', sans-serif; font-size: 12px; font-weight: 700; color: #fff; flex-shrink: 0; }
.car-info { flex: 1; min-width: 0; }
.car-name { font-family: 'Syne', sans-serif; font-size: 13px; font-weight: 600; color: #d6daf0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.car-meta { font-size: 11px; color: #4a5268; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.car-actions { display: flex; gap: 4px; align-items: center; }
.action-btn { width: 30px; height: 30px; border-radius: 8px; border: 1px solid #272d3d; background: transparent; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.15s; color: #4a5268; }
.action-btn svg { width: 13px; height: 13px; }
.action-btn:hover { background: #272d3d; color: #d6daf0; }
.action-btn--active.selected { background: rgba(52,211,153,0.12); border-color: rgba(52,211,153,0.3); color: #34d399; }
.action-btn--active:not(.selected):hover { color: #34d399; background: rgba(52,211,153,0.08); }
.action-btn--del:hover { background: rgba(239,68,68,0.1); border-color: rgba(239,68,68,0.25); color: #ef4444; }

.list-empty { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 36px 24px; color: #4a5268; }
.list-empty svg { width: 36px; height: 36px; opacity: 0.4; }
.list-empty p { margin: 0; font-size: 13px; }
.btn-add-inline { padding: 8px 18px; background: #5b6cf6; color: #fff; border: none; border-radius: 9px; font-family: 'Syne', sans-serif; font-size: 12px; font-weight: 600; cursor: pointer; transition: background 0.15s; }
.btn-add-inline:hover { background: #4a5ae5; }

/* Modal */
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal { width: 100%; max-width: 380px; background: #181c27; border: 1px solid #272d3d; border-radius: 18px; box-shadow: 0 24px 60px rgba(0,0,0,0.6); overflow: hidden; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 22px 16px; border-bottom: 1px solid #272d3d; }
.modal-title { margin: 0; font-family: 'Syne', sans-serif; font-size: 15px; font-weight: 700; color: #f1f3f9; }
.modal-close { width: 28px; height: 28px; border-radius: 8px; background: #272d3d; border: none; color: #8892aa; font-size: 18px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: background 0.12s, color 0.12s; }
.modal-close:hover { background: #ef4444; color: #fff; }

/* Mode tabs */
.mode-tabs { display: flex; gap: 0; border-bottom: 1px solid #272d3d; }
.mode-tab { flex: 1; display: flex; align-items: center; justify-content: center; gap: 7px; padding: 11px 16px; background: transparent; border: none; border-bottom: 2px solid transparent; margin-bottom: -1px; font-family: 'Syne', sans-serif; font-size: 12px; font-weight: 600; color: #4a5268; cursor: pointer; transition: color 0.15s, border-color 0.15s, background 0.15s; }
.mode-tab svg { width: 13px; height: 13px; flex-shrink: 0; }
.mode-tab:hover { color: #8892aa; background: rgba(255,255,255,0.02); }
.mode-tab--active { color: #5b6cf6; border-bottom-color: #5b6cf6; }

.modal-body { padding: 20px 22px; display: flex; flex-direction: column; gap: 14px; }

/* Custom notice */
.custom-notice { display: flex; align-items: flex-start; gap: 9px; padding: 11px 13px; background: rgba(91,108,246,0.08); border: 1px solid rgba(91,108,246,0.2); border-radius: 10px; font-size: 12px; color: #8892aa; line-height: 1.5; }
.custom-notice svg { width: 14px; height: 14px; color: #5b6cf6; flex-shrink: 0; margin-top: 1px; }

/* Fields */
.field { display: flex; flex-direction: column; gap: 6px; transition: opacity 0.2s; flex: 1; }
.field--off { opacity: 0.4; pointer-events: none; }
.flabel { font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.8px; color: #4a5268; }

.field-row { display: flex; gap: 12px; }

.sel-wrap { position: relative; display: flex; align-items: center; }
.fselect { width: 100%; appearance: none; background: #1e2235; border: 1px solid #272d3d; border-radius: 10px; padding: 10px 36px 10px 14px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; color: #d6daf0; cursor: pointer; outline: none; transition: border-color 0.15s; }
.fselect:focus { border-color: #5b6cf6; }
.fselect:disabled { cursor: not-allowed; opacity: 0.6; }

.finput { width: 100%; background: #1e2235; border: 1px solid #272d3d; border-radius: 10px; padding: 10px 14px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; color: #d6daf0; outline: none; transition: border-color 0.15s; }
.finput:focus { border-color: #5b6cf6; }
.finput::placeholder { color: #4a5268; }
/* hide number spinners */
.finput[type=number]::-webkit-inner-spin-button,
.finput[type=number]::-webkit-outer-spin-button { -webkit-appearance: none; }
.finput[type=number] { -moz-appearance: textfield; }

.sel-arrow { position: absolute; right: 12px; font-size: 12px; color: #4a5268; pointer-events: none; }
.sel-spinner { position: absolute; right: 12px; width: 14px; height: 14px; border: 2px solid #272d3d; border-top-color: #5b6cf6; border-radius: 50%; animation: spin 0.65s linear infinite; pointer-events: none; }

.field-error { font-size: 12px; color: #ef4444; display: flex; align-items: center; gap: 8px; }
.save-error  { margin-top: 4px; }
.retry-link  { background: none; border: none; color: #5b6cf6; font-size: 12px; cursor: pointer; text-decoration: underline; padding: 0; }

.modal-footer { display: flex; gap: 10px; padding: 16px 22px 20px; border-top: 1px solid #272d3d; }
.btn-cancel { flex: 1; padding: 10px; background: transparent; border: 1px solid #272d3d; border-radius: 10px; font-family: 'Syne', sans-serif; font-size: 13px; font-weight: 600; color: #8892aa; cursor: pointer; transition: all 0.12s; }
.btn-cancel:hover:not(:disabled) { background: #272d3d; color: #d6daf0; }
.btn-save { flex: 1; padding: 10px; background: #272d3d; border: none; border-radius: 10px; font-family: 'Syne', sans-serif; font-size: 13px; font-weight: 600; color: #4a5268; cursor: not-allowed; transition: all 0.15s; display: flex; align-items: center; justify-content: center; gap: 8px; }
.btn-save--on { background: #5b6cf6; color: #fff; cursor: pointer; }
.btn-save--on:hover { background: #4a5ae5; transform: translateY(-1px); }

.btn-spinner { width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.65s linear infinite; }

/* Transitions */
.car-list-enter-active { transition: all 0.25s ease; }
.car-list-leave-active { transition: all 0.2s ease; }
.car-list-enter-from   { opacity: 0; transform: translateX(-12px); }
.car-list-leave-to     { opacity: 0; transform: translateX(12px); }
.modal-enter-active    { transition: all 0.22s cubic-bezier(0.16,1,0.3,1); }
.modal-leave-active    { transition: all 0.16s ease; }
.modal-enter-from      { opacity: 0; transform: scale(0.94); }
.modal-leave-to        { opacity: 0; transform: scale(0.96); }

@keyframes pulse   { 0%, 100% { box-shadow: 0 0 0 0 rgba(52,211,153,0.4); } 50% { box-shadow: 0 0 0 5px rgba(52,211,153,0); } }
@keyframes spin    { to { transform: rotate(360deg); } }
@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
</style>
