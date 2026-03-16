<script setup lang="ts">
import MapView from './components/MapView.vue'
import SelectCar from './components/SelectCar.vue'
import { ref } from 'vue'

const expanded = ref(false)
</script>

<template>
    <MapView />
    <div class="overlay" :class="{ expanded }">
      <button class="toggle" @click="expanded = !expanded">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3"/>
          <rect x="9" y="11" width="14" height="10" rx="2"/>
          <circle cx="12" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
        </svg>
        <span class="toggle-label">My cars</span>
        <span class="toggle-chevron">{{ expanded ? '✕' : '↓' }}</span>
      </button>


      <div class="panel-body" v-show="expanded">
        <SelectCar />
      </div>
    </div>
</template>

<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body, #app { height: 100%; overflow: hidden; }
</style>

<style scoped>
.app {
  position: relative;
  height: 100vh;
  width: 100vw;
}

.app :deep(.map-wrapper) {
  position: absolute;
  inset: 0;
  min-height: 100%;
  height: 100%;
  padding: 0;
}
.app :deep(.map-card) {
  height: 100%;
  max-width: 100%;
  border-radius: 0;
  box-shadow: none;
}
.app :deep(.map-content) {
  height: calc(100% - 49px);
}


.overlay {
  position: absolute;
  top: 16px;
  right: 16px;
  z-index: 1000;
  width: 360px;                     
  max-width: calc(100vw - 32px);       
  max-height: calc(100vh - 32px);
  display: flex;
  flex-direction: column;
  align-items: stretch;
}


.toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 9px 14px;
  background: #181c27ee;
  backdrop-filter: blur(8px);
  border: 1px solid #272d3d;
  border-radius: 12px;
  cursor: pointer;
  color: #d6daf0;
  font-family: 'Syne', sans-serif;
  font-size: 12px;
  font-weight: 600;
  transition: background 0.15s;
  width: 100%;
}
.toggle:hover { background: #1e2235ee; }
.toggle svg { width: 15px; height: 15px; color: #5b6cf6; flex-shrink: 0; }
.toggle-label { flex: 1; text-align: left; }
.toggle-chevron { font-size: 11px; color: #4a5268; }
.panel-body {
  margin-top: 6px;
  border-radius: 16px;
  overflow-y: auto;
  max-height: calc(100vh - 90px);
  scrollbar-width: none;
  box-shadow: 0 8px 32px rgba(0,0,0,0.5);
}
.panel-body::-webkit-scrollbar { display: none; }

.panel-body :deep(.page) {
  min-height: unset;
  padding: 0;
  background: transparent;
}
.panel-body :deep(.panel) {
  border-radius: 16px;
  max-width: 100%;
}
</style>