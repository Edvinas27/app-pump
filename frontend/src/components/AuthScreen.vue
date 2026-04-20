<script setup lang="ts">
import { ref, watch, computed } from "vue"
import { loginSession, registerUser, type AuthSuccess } from "../api/auth"

const emit = defineEmits<{
  success: [payload: AuthSuccess]
}>()

type Tab = "login" | "register"
const tab = ref<Tab>("login")

const email = ref("")
const username = ref("")
const password = ref("")
const submitting = ref(false)
const error = ref("")

watch(tab, () => {
  error.value = ""
})

async function submitLogin() {
  error.value = ""
  submitting.value = true
  try {
    const payload = await loginSession(email.value.trim(), password.value)
    emit("success", payload)
    resetFields()
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Sign in failed"
  } finally {
    submitting.value = false
  }
}

async function submitRegister() {
  error.value = ""
  submitting.value = true
  try {
    const payload = await registerUser(email.value.trim(), username.value.trim(), password.value)
    emit("success", payload)
    resetFields()
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Registration failed"
  } finally {
    submitting.value = false
  }
}

function resetFields() {
  email.value = ""
  username.value = ""
  password.value = ""
}

function onSubmit() {
  if (tab.value === "login") void submitLogin()
  else void submitRegister()
}

const canSubmitRegister = computed(
  () => Boolean(email.value.trim() && username.value.trim() && password.value),
)
</script>

<template>
  <div class="auth-page">
    <div class="auth-card">
      <div class="brand">
        <span class="brand-dot" />
        <h1 class="brand-title">App Pump</h1>
        <p class="brand-sub">Sign in or create an account to use the map and your cars.</p>
      </div>

      <div class="tabs" role="tablist">
        <button
          type="button"
          role="tab"
          class="tab"
          :class="{ 'tab--active': tab === 'login' }"
          :aria-selected="tab === 'login'"
          @click="tab = 'login'"
        >
          Sign in
        </button>
        <button
          type="button"
          role="tab"
          class="tab"
          :class="{ 'tab--active': tab === 'register' }"
          :aria-selected="tab === 'register'"
          @click="tab = 'register'"
        >
          Register
        </button>
      </div>

      <form class="form" @submit.prevent="onSubmit">
        <div v-if="tab === 'register'" class="field">
          <label class="flabel" for="reg-username">Username</label>
          <input
            id="reg-username"
            v-model="username"
            class="finput"
            type="text"
            name="username"
            autocomplete="username"
            required
            placeholder="e.g. vilnius_driver"
          />
        </div>

        <div class="field">
          <label class="flabel" for="auth-email">Email</label>
          <input
            id="auth-email"
            v-model="email"
            class="finput"
            type="email"
            name="email"
            :autocomplete="tab === 'login' ? 'username' : 'email'"
            required
            placeholder="you@example.com"
          />
        </div>

        <div class="field">
          <label class="flabel" for="auth-password">Password</label>
          <input
            id="auth-password"
            v-model="password"
            class="finput"
            type="password"
            name="password"
            :autocomplete="tab === 'login' ? 'current-password' : 'new-password'"
            required
            placeholder="••••••••"
          />
        </div>

        <div v-if="error" class="field-error" role="alert">{{ error }}</div>

        <button
          type="submit"
          class="submit"
          :disabled="submitting || (tab === 'register' && !canSubmitRegister)"
        >
          <span v-if="submitting" class="btn-spinner" />
          <span v-else-if="tab === 'login'">Sign in</span>
          <span v-else>Create account</span>
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
@import url("https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700&family=DM+Sans:wght@400;500&display=swap");

.auth-page {
  min-height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
  box-sizing: border-box;
  background: #0f1117;
  font-family: "DM Sans", sans-serif;
}

.auth-card {
  width: 100%;
  max-width: 400px;
  background: #181c27;
  border: 1px solid #272d3d;
  border-radius: 20px;
  padding: 28px 26px 30px;
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.45);
}

.brand {
  text-align: center;
  margin-bottom: 22px;
}

.brand-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  background: #5b6cf6;
  border-radius: 50%;
  margin-bottom: 10px;
}

.brand-title {
  margin: 0 0 8px;
  font-family: "Syne", sans-serif;
  font-size: 22px;
  font-weight: 700;
  color: #f1f3f9;
  letter-spacing: -0.3px;
}

.brand-sub {
  margin: 0;
  font-size: 12px;
  line-height: 1.5;
  color: #4a5268;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-radius: 12px;
  background: #1e2235;
  padding: 4px;
  gap: 4px;
}

.tab {
  flex: 1;
  border: none;
  border-radius: 10px;
  padding: 10px 12px;
  font-family: "Syne", sans-serif;
  font-size: 12px;
  font-weight: 600;
  color: #4a5268;
  background: transparent;
  cursor: pointer;
  transition:
    color 0.15s,
    background 0.15s;
}

.tab:hover {
  color: #8892aa;
}

.tab--active {
  background: #272d3d;
  color: #5b6cf6;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.flabel {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  color: #4a5268;
}

.finput {
  width: 100%;
  box-sizing: border-box;
  background: #1e2235;
  border: 1px solid #272d3d;
  border-radius: 10px;
  padding: 10px 14px;
  font-family: "DM Sans", sans-serif;
  font-size: 13px;
  font-weight: 500;
  color: #d6daf0;
  outline: none;
  transition: border-color 0.15s;
}

.finput:focus {
  border-color: #5b6cf6;
}

.finput::placeholder {
  color: #4a5268;
}

.field-error {
  font-size: 12px;
  color: #ef4444;
  line-height: 1.4;
}

.submit {
  margin-top: 4px;
  width: 100%;
  padding: 12px 16px;
  border: none;
  border-radius: 10px;
  font-family: "Syne", sans-serif;
  font-size: 13px;
  font-weight: 600;
  color: #fff;
  background: #5b6cf6;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition:
    background 0.15s,
    transform 0.1s;
}

.submit:hover:not(:disabled) {
  background: #4a5ae5;
  transform: translateY(-1px);
}

.submit:disabled {
  opacity: 0.55;
  cursor: not-allowed;
  transform: none;
}

.btn-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.65s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
