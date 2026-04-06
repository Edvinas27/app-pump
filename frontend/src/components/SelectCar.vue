<script setup>
import { ref, computed } from "vue"

const makes = {
  Toyota:     ["Corolla", "Camry", "Yaris", "RAV4"],
  Volkswagen: ["Golf", "Passat", "Tiguan", "Polo"],
  BMW:        ["3 Series", "5 Series", "X3", "X5"],
  Mercedes:   ["A-Class", "C-Class", "GLC", "E-Class"],
  Ford:       ["Focus", "Fiesta", "Kuga", "Mustang"],
  Tesla:      ["Model 3", "Model Y", "Model S", "Model X"],
  Audi:       ["A3", "A4", "Q5", "TT"],
  Skoda:      ["Octavia", "Fabia", "Superb", "Kodiaq"],
}
const allMakes  = Object.keys(makes)
const yearList  = Array.from({ length: 15 }, (_, i) => 2024 - i)

const cars = ref([
  { id: 1, make: "Toyota",     model: "Corolla",  year: 2021 },
  { id: 2, make: "BMW",        model: "X3",       year: 2022 },
  { id: 3, make: "Tesla",      model: "Model 3",  year: 2023 },
])
const activeId   = ref(1)
const nextId     = ref(4)

const showModal  = ref(false)
const editTarget = ref(null) 

const form = ref({ make: "", model: "", year: "" })
const formModels = computed(() => form.value.make ? makes[form.value.make] : [])

function openAdd() {
  editTarget.value = null
  form.value = { make: "", model: "", year: "" }
  showModal.value = true
}

function openEdit(car) {
  editTarget.value = car
  form.value = { make: car.make, model: car.model, year: car.year }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function onMakeChange() {
  form.value.model = ""
}

function saveForm() {
  if (!form.value.make || !form.value.model || !form.value.year) return
  if (editTarget.value) {
    const car = cars.value.find(c => c.id === editTarget.value.id)
    if (car) { car.make = form.value.make; car.model = form.value.model; car.year = form.value.year }
  } else {
    cars.value.push({ id: nextId.value++, ...form.value })
  }
  closeModal()
}

function deleteCar(id) {
  cars.value = cars.value.filter(c => c.id !== id)
  if (activeId.value === id) activeId.value = cars.value[0]?.id ?? null
}

function setActive(id) {
  activeId.value = id
}

const activeCar = computed(() => cars.value.find(c => c.id === activeId.value))
const canSave   = computed(() => form.value.make && form.value.model && form.value.year)

const makeColors = {
  Toyota: "#e53935", Volkswagen: "#1565c0", BMW: "#0277bd",
  Mercedes: "#37474f", Ford: "#1976d2", Tesla: "#c62828",
  Audi: "#4a148c", Skoda: "#2e7d32",
}
function makeColor(make) { return makeColors[make] ?? "#546e7a" }

function initials(make) { return make.slice(0, 2).toUpperCase() }
</script>

<template>
  <div class="page">
    <div class="panel">

      <!-- Top bar -->
      <div class="topbar">
        <div class="topbar-left">
          <svg class="topbar-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3"/>
            <rect x="9" y="11" width="14" height="10" rx="2"/>
            <circle cx="12" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
          </svg>
          <div>
            <h1 class="topbar-title">My cars</h1>
            <p class="topbar-sub">{{ cars.length }} saved · {{ activeCar ? activeCar.make + ' ' + activeCar.model : '—' }} active</p>
          </div>
        </div>
        <button class="btn-add" @click="openAdd">
          <span class="btn-add-icon">+</span> Add
        </button>
      </div>

      <div v-if="activeCar" class="hero">
        <div class="hero-badge" :style="{ background: makeColor(activeCar.make) }">
          {{ initials(activeCar.make) }}
        </div>
        <div class="hero-info">
          <div class="hero-name">{{ activeCar.make }} {{ activeCar.model }}</div>
          <div class="hero-year">{{ activeCar.year }} · Active car</div>
        </div>
        <div class="hero-pulse">
          <span class="pulse-dot" />
          Active
        </div>
      </div>

      <div v-else class="hero hero-empty">
        <p>No active car</p>
      </div>

      <div class="list-header">
        <span class="list-label">All cars</span>
      </div>

      <div class="list">
        <transition-group name="car-list">
          <div
            v-for="car in cars"
            :key="car.id"
            class="car-row"
            :class="{ 'car-row--active': car.id === activeId }"
            @click="setActive(car.id)"
          >
            <div class="car-avatar" :style="{ background: makeColor(car.make) }">
              {{ initials(car.make) }}
            </div>

            <div class="car-info">
              <div class="car-name">{{ car.make }} {{ car.model }}</div>
              <div class="car-meta">{{ car.year }}</div>
            </div>

            <div class="car-actions" @click.stop>
              <button
                class="action-btn action-btn--active"
                :class="{ selected: car.id === activeId }"
                @click="setActive(car.id)"
                :title="car.id === activeId ? 'Aktyvus' : 'Pasirinkti'"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                  <polyline points="20 6 9 17 4 12"/>
                </svg>
              </button>
              <button class="action-btn" @click="openEdit(car)" title="Redaguoti">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="action-btn action-btn--del" @click="deleteCar(car.id)" title="Pašalinti">
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

    </div>

    <transition name="modal">
      <div v-if="showModal" class="modal-backdrop" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h2 class="modal-title">{{ editTarget ? 'Redaguoti automobilį' : 'Pridėti automobilį' }}</h2>
            <button class="modal-close" @click="closeModal">×</button>
          </div>

          <div class="modal-body">
            <div class="field">
              <label class="flabel">Brand</label>
              <div class="sel-wrap">
                <select v-model="form.make" class="fselect" @change="onMakeChange">
                  <option value="" disabled>Select brand</option>
                  <option v-for="m in allMakes" :key="m" :value="m">{{ m }}</option>
                </select>
              </div>
            </div>

            <div class="field" :class="{ 'field--off': !form.make }">
              <label class="flabel">Model</label>
              <div class="sel-wrap">
                <select v-model="form.model" class="fselect" :disabled="!form.make">
                  <option value="" disabled>Select model</option>
                  <option v-for="m in formModels" :key="m" :value="m">{{ m }}</option>
                </select>
              </div>
            </div>

            <div class="field" :class="{ 'field--off': !form.model }">
              <label class="flabel">Year</label>
              <div class="sel-wrap">
                <select v-model="form.year" class="fselect" :disabled="!form.model">
                  <option value="" disabled>Select year</option>
                  <option v-for="y in yearList" :key="y" :value="y">{{ y }}</option>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button class="btn-cancel" @click="closeModal">Cancel</button>
            <button class="btn-save" :class="{ 'btn-save--on': canSave }" :disabled="!canSave" @click="saveForm">
              {{ editTarget ? 'Save' : 'Add' }}
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

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 24px 18px;
  border-bottom: 1px solid #272d3d;
}
.topbar-left { display: flex; align-items: center; gap: 12px; }
.topbar-icon { width: 22px; height: 22px; color: #5b6cf6; flex-shrink: 0; }
.topbar-title {
  margin: 0 0 2px;
  font-family: 'Syne', sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #f1f3f9;
  letter-spacing: -0.2px;
}
.topbar-sub { margin: 0; font-size: 11px; color: #4a5268; }

.btn-add {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: #5b6cf6;
  color: #fff;
  border: none;
  border-radius: 10px;
  font-family: 'Syne', sans-serif;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s, transform 0.1s;
}
.btn-add:hover { background: #4a5ae5; transform: translateY(-1px); }
.btn-add:active { transform: translateY(0); }
.btn-add-icon { font-size: 16px; line-height: 1; }


.hero {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px 24px;
  background: linear-gradient(135deg, #1e2235 0%, #181c27 100%);
  border-bottom: 1px solid #272d3d;
}
.hero-empty { justify-content: center; color: #4a5268; font-size: 13px; }

.hero-badge {
  width: 46px;
  height: 46px;
  border-radius: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Syne', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #fff;
  flex-shrink: 0;
  letter-spacing: 0.5px;
}
.hero-info { flex: 1; }
.hero-name {
  font-family: 'Syne', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #f1f3f9;
  letter-spacing: -0.2px;
}
.hero-year { font-size: 11px; color: #4a5268; margin-top: 2px; }

.hero-pulse {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 600;
  color: #34d399;
  background: rgba(52,211,153,0.1);
  padding: 5px 10px;
  border-radius: 20px;
  border: 1px solid rgba(52,211,153,0.2);
}
.pulse-dot {
  width: 6px;
  height: 6px;
  background: #34d399;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

/* List */
.list-header {
  padding: 14px 24px 8px;
}
.list-label {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: #4a5268;
}

.list { padding: 0 12px 16px; display: flex; flex-direction: column; gap: 4px; }

.car-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 11px 12px;
  border-radius: 12px;
  cursor: pointer;
  border: 1px solid transparent;
  transition: background 0.15s, border-color 0.15s;
}
.car-row:hover { background: #1e2235; }
.car-row--active {
  background: #1e2235;
  border-color: #2d3452;
}

.car-avatar {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Syne', sans-serif;
  font-size: 12px;
  font-weight: 700;
  color: #fff;
  flex-shrink: 0;
  letter-spacing: 0.3px;
}
.car-info { flex: 1; min-width: 0; }
.car-name {
  font-family: 'Syne', sans-serif;
  font-size: 13px;
  font-weight: 600;
  color: #d6daf0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.car-meta { font-size: 11px; color: #4a5268; margin-top: 1px; }

.car-actions { display: flex; gap: 4px; align-items: center; }

.action-btn {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  border: 1px solid #272d3d;
  background: transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  color: #4a5268;
}
.action-btn svg { width: 13px; height: 13px; }
.action-btn:hover { background: #272d3d; color: #d6daf0; }

.action-btn--active { color: #4a5268; }
.action-btn--active.selected {
  background: rgba(52,211,153,0.12);
  border-color: rgba(52,211,153,0.3);
  color: #34d399;
}
.action-btn--active:not(.selected):hover { color: #34d399; background: rgba(52,211,153,0.08); }

.action-btn--del:hover { background: rgba(239,68,68,0.1); border-color: rgba(239,68,68,0.25); color: #ef4444; }

/* Empty list */
.list-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 36px 24px;
  color: #4a5268;
}
.list-empty svg { width: 36px; height: 36px; opacity: 0.4; }
.list-empty p { margin: 0; font-size: 13px; }
.btn-add-inline {
  padding: 8px 18px;
  background: #5b6cf6;
  color: #fff;
  border: none;
  border-radius: 9px;
  font-family: 'Syne', sans-serif;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 4px;
  transition: background 0.15s;
}
.btn-add-inline:hover { background: #4a5ae5; }

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.7);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
}
.modal {
  width: 100%;
  max-width: 380px;
  background: #181c27;
  border: 1px solid #272d3d;
  border-radius: 18px;
  box-shadow: 0 24px 60px rgba(0,0,0,0.6);
  overflow: hidden;
}
.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 22px 16px;
  border-bottom: 1px solid #272d3d;
}
.modal-title {
  margin: 0;
  font-family: 'Syne', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #f1f3f9;
}
.modal-close {
  width: 28px; height: 28px;
  border-radius: 8px;
  background: #272d3d;
  border: none;
  color: #8892aa;
  font-size: 18px;
  line-height: 1;
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: background 0.12s, color 0.12s;
}
.modal-close:hover { background: #ef4444; color: #fff; }

.modal-body { padding: 20px 22px; display: flex; flex-direction: column; gap: 14px; }

.field { display: flex; flex-direction: column; gap: 6px; }
.field--off { opacity: 0.4; pointer-events: none; }
.flabel {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  color: #4a5268;
}
.sel-wrap { position: relative; }
.fselect {
  width: 100%;
  appearance: none;
  background: #1e2235;
  border: 1px solid #272d3d;
  border-radius: 10px;
  padding: 10px 14px;
  font-family: 'DM Sans', sans-serif;
  font-size: 13px;
  font-weight: 500;
  color: #d6daf0;
  cursor: pointer;
  outline: none;
  transition: border-color 0.15s;
}
.fselect:focus { border-color: #5b6cf6; }

.modal-footer {
  display: flex;
  gap: 10px;
  padding: 16px 22px 20px;
  border-top: 1px solid #272d3d;
}
.btn-cancel {
  flex: 1; padding: 10px;
  background: transparent;
  border: 1px solid #272d3d;
  border-radius: 10px;
  font-family: 'Syne', sans-serif;
  font-size: 13px; font-weight: 600;
  color: #8892aa;
  cursor: pointer;
  transition: all 0.12s;
}
.btn-cancel:hover { background: #272d3d; color: #d6daf0; }

.btn-save {
  flex: 1; padding: 10px;
  background: #272d3d;
  border: none;
  border-radius: 10px;
  font-family: 'Syne', sans-serif;
  font-size: 13px; font-weight: 600;
  color: #4a5268;
  cursor: not-allowed;
  transition: all 0.15s;
}
.btn-save--on {
  background: #5b6cf6;
  color: #fff;
  cursor: pointer;
}
.btn-save--on:hover { background: #4a5ae5; transform: translateY(-1px); }

.car-list-enter-active { transition: all 0.25s ease; }
.car-list-leave-active { transition: all 0.2s ease; }
.car-list-enter-from { opacity: 0; transform: translateX(-12px); }
.car-list-leave-to   { opacity: 0; transform: translateX(12px); }

.modal-enter-active { transition: all 0.22s cubic-bezier(0.16,1,0.3,1); }
.modal-leave-active { transition: all 0.16s ease; }
.modal-enter-from   { opacity: 0; transform: scale(0.94); }
.modal-leave-to     { opacity: 0; transform: scale(0.96); }

@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(52,211,153,0.4); }
  50%       { box-shadow: 0 0 0 5px rgba(52,211,153,0); }
}
</style>