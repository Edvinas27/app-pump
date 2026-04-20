<script setup lang="ts">
import MapView from "./components/MapView.vue"
import SelectCar from "./components/SelectCar.vue"
import FeedbackPanel from "./components/FeedbackPanel.vue"
import AuthScreen from "./components/AuthScreen.vue"
import { ref, onMounted } from "vue"
import {
  isTokenUsable,
  clearStoredAuth,
  LOGIN_LOCATION_KEY,
  type AuthUser,
  type AuthSuccess,
  type LoginLocation,
} from "./api/auth"

const expanded = ref(false)
const feedbackExpanded = ref(false)
const bootstrapping = ref(true)
const authenticated = ref(false)

const currentUser = ref<AuthUser | null>(null)
const loginLocation = ref<LoginLocation | null>(null)
const carsKey = ref(0)
const activeCarId = ref<number | undefined>(undefined)

onMounted(() => {
  clearStoredAuth()
  authenticated.value = false
  currentUser.value = null
  loginLocation.value = null
  bootstrapping.value = false
})

function onAuthSuccess(payload: AuthSuccess) {
  if (!isTokenUsable(payload.token)) {
    clearStoredAuth()
    authenticated.value = false
    currentUser.value = null
    loginLocation.value = null
    return
  }
  localStorage.setItem("token", payload.token)
  localStorage.setItem("user", JSON.stringify(payload.user))
  if (payload.location) {
    localStorage.setItem(LOGIN_LOCATION_KEY, JSON.stringify(payload.location))
  } else {
    localStorage.removeItem(LOGIN_LOCATION_KEY)
  }
  authenticated.value = true
  currentUser.value = payload.user
  loginLocation.value = payload.location
  carsKey.value += 1
}

</script>

<template>
  <div class="app">
    <div v-if="bootstrapping" class="boot">
      <div class="boot-spinner" />
    </div>

    <AuthScreen v-else-if="!authenticated" @success="onAuthSuccess" />

    <template v-else>
      <MapView :active-car-id="activeCarId" :initial-location="loginLocation" />
      <div class="user-top-name" :title="currentUser?.email ?? ''">
        {{ currentUser?.username || currentUser?.email || "Signed in" }}
      </div>

      <div class="feedback-overlay" :class="{ expanded: feedbackExpanded }">
        <div v-show="feedbackExpanded" class="feedback-panel-wrap">
          <FeedbackPanel />
        </div>
        <button type="button" class="toggle fb-toggle" @click="feedbackExpanded = !feedbackExpanded">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <span class="toggle-label">Feedback</span>
          <span class="toggle-chevron">{{ feedbackExpanded ? "✕" : "↑" }}</span>
        </button>
      </div>

      <div class="overlay" :class="{ expanded }">
        <button type="button" class="toggle" @click="expanded = !expanded">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3" />
            <rect x="9" y="11" width="14" height="10" rx="2" />
            <circle cx="12" cy="21" r="1" />
            <circle cx="20" cy="21" r="1" />
          </svg>
          <span class="toggle-label">My cars</span>
          <span class="toggle-chevron">{{ expanded ? "✕" : "↓" }}</span>
        </button>

        <div v-show="expanded" class="panel-body">
          <SelectCar :key="carsKey" @active-car-change="activeCarId = $event ?? undefined" />
        </div>
      </div>
    </template>
  </div>
</template>

<style>
*,
*::before,
*::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}
html,
body,
#app {
  height: 100%;
  overflow: hidden;
  overflow-x: clip;
}
</style>

<style scoped>
@import url("https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700&display=swap");

.app {
  position: relative;
  height: 100vh;
  width: 100%;
  max-width: 100%;
  overflow-x: clip;
}

.boot {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #0f1117;
  z-index: 3000;
}

.boot-spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #272d3d;
  border-top-color: #5b6cf6;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
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

.user-top-name {
  position: absolute;
  top: 14px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1000;
  font-family: "Syne", sans-serif;
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
  text-shadow:
    0 0 10px #fff,
    0 0 6px #fff,
    0 0 2px #fff;
  max-width: min(420px, calc(100vw - 120px));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  text-align: center;
  pointer-events: none;
}

.feedback-overlay {
  position: absolute;
  bottom: 16px;
  right: 16px;
  z-index: 1000;
  width: 360px;
  max-width: calc(100vw - 32px);
  max-height: calc(100vh - 40px);
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: stretch;
  gap: 6px;
}

.feedback-panel-wrap {
  border-radius: 16px;
  overflow: hidden;
  overflow-y: auto;
  max-height: calc(100vh - 120px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
  scrollbar-width: none;
}

.feedback-panel-wrap::-webkit-scrollbar {
  display: none;
}

.feedback-panel-wrap :deep(.fb-page) {
  min-height: unset;
}

.feedback-panel-wrap :deep(.fb-panel) {
  max-width: 100%;
  border-radius: 16px;
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
  font-family: "Syne", sans-serif;
  font-size: 12px;
  font-weight: 600;
  transition: background 0.15s;
  width: 100%;
}
.toggle:hover {
  background: #1e2235ee;
}
.toggle svg {
  width: 15px;
  height: 15px;
  color: #5b6cf6;
  flex-shrink: 0;
}
.toggle-label {
  flex: 1;
  text-align: left;
}
.toggle-chevron {
  font-size: 11px;
  color: #4a5268;
}
.panel-body {
  margin-top: 6px;
  border-radius: 16px;
  overflow-y: auto;
  max-height: calc(100vh - 90px);
  scrollbar-width: none;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
}
.panel-body::-webkit-scrollbar {
  display: none;
}

.panel-body :deep(.page) {
  min-height: unset;
  padding: 0;
  background: transparent;
}
.panel-body :deep(.panel) {
  border-radius: 16px;
  max-width: 100%;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
