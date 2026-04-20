<script setup lang="ts">
import { ref, onMounted } from "vue"
import { fetchFeedbacks, createFeedback, type Feedback } from "../api/feedbacks"

const items = ref<Feedback[]>([])
const loading = ref(true)
const loadError = ref("")

const comment = ref("")
const rating = ref(5)
const submitting = ref(false)
const formError = ref("")
const formSuccess = ref("")

async function load() {
  loading.value = true
  loadError.value = ""
  try {
    items.value = await fetchFeedbacks()
  } catch {
    loadError.value = "Could not load feedbacks."
    items.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  void load()
})

async function submit() {
  formError.value = ""
  formSuccess.value = ""
  if (!comment.value.trim()) {
    formError.value = "Please enter a comment."
    return
  }
  submitting.value = true
  try {
    const created = await createFeedback(comment.value, rating.value)
    items.value = [created, ...items.value.filter((f) => f.id !== created.id)]
    comment.value = ""
    rating.value = 5
    formSuccess.value = "Thanks — your feedback was posted."
  } catch (e) {
    formError.value = e instanceof Error ? e.message : "Something went wrong."
  } finally {
    submitting.value = false
  }
}

function formatWhen(iso: string) {
  try {
    const d = new Date(iso)
    return d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" })
  } catch {
    return iso
  }
}
</script>

<template>
  <div class="fb-page">
    <div class="fb-panel">
      <div class="fb-top">
        <div class="fb-top-left">
          <svg class="fb-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <div>
            <h1 class="fb-title">Feedback</h1>
            <p class="fb-sub">Share a rating and comment. Everyone can read posts below.</p>
          </div>
        </div>
      </div>

      <div class="fb-form">
        <label class="flabel" for="fb-comment">Your comment</label>
        <textarea
          id="fb-comment"
          v-model="comment"
          class="ftextarea"
          rows="3"
          maxlength="2000"
          placeholder="What works well? What could be better?"
        />

        <span class="flabel">Rating (1–5)</span>
        <div class="stars" role="group" aria-label="Rating">
          <button
            v-for="n in 5"
            :key="n"
            type="button"
            class="star"
            :class="{ on: rating >= n }"
            :aria-pressed="rating === n"
            @click="rating = n"
          >
            ★
          </button>
        </div>

        <p v-if="formError" class="ferr">{{ formError }}</p>
        <p v-if="formSuccess" class="fok">{{ formSuccess }}</p>

        <button type="button" class="fsubmit" :disabled="submitting" @click="submit">
          {{ submitting ? "Sending…" : "Send feedback" }}
        </button>
      </div>

      <div class="fb-list-head">
        <span class="fb-list-label">Recent feedback</span>
      </div>

      <div v-if="loading" class="fb-skel">Loading…</div>
      <div v-else-if="loadError" class="fb-skel ferr">{{ loadError }}</div>
      <div v-else class="fb-list">
        <div v-for="f in items" :key="f.id" class="fb-row">
          <div class="fb-row-top">
            <span class="fb-stars" aria-hidden="true">{{ "★".repeat(f.rating) }}{{ "☆".repeat(5 - f.rating) }}</span>
            <span class="fb-date">{{ formatWhen(f.created_at) }}</span>
          </div>
          <p class="fb-comment">{{ f.comment }}</p>
        </div>
        <p v-if="items.length === 0" class="fb-empty">No feedback yet — be the first.</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import url("https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700&family=DM+Sans:wght@400;500&display=swap");

.fb-page {
  font-family: "DM Sans", sans-serif;
}

.fb-panel {
  width: 100%;
  max-width: 480px;
  background: #181c27;
  border-radius: 16px;
  border: 1px solid #272d3d;
  overflow: hidden;
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.5);
}

.fb-top {
  padding: 18px 20px 14px;
  border-bottom: 1px solid #272d3d;
}

.fb-top-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.fb-icon {
  width: 22px;
  height: 22px;
  color: #5b6cf6;
  flex-shrink: 0;
  margin-top: 2px;
}

.fb-title {
  margin: 0 0 4px;
  font-family: "Syne", sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #f1f3f9;
}

.fb-sub {
  margin: 0;
  font-size: 11px;
  color: #4a5268;
  line-height: 1.45;
}

.fb-form {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border-bottom: 1px solid #272d3d;
}

.flabel {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.7px;
  color: #4a5268;
}

.ftextarea {
  width: 100%;
  box-sizing: border-box;
  resize: vertical;
  min-height: 72px;
  background: #1e2235;
  border: 1px solid #272d3d;
  border-radius: 10px;
  padding: 10px 12px;
  font-family: "DM Sans", sans-serif;
  font-size: 13px;
  color: #d6daf0;
  outline: none;
}

.ftextarea:focus {
  border-color: #5b6cf6;
}

.ftextarea::placeholder {
  color: #4a5268;
}

.stars {
  display: flex;
  gap: 4px;
}

.star {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  border: 1px solid #272d3d;
  background: #1e2235;
  color: #4a5268;
  font-size: 18px;
  line-height: 1;
  cursor: pointer;
  transition:
    color 0.12s,
    border-color 0.12s,
    background 0.12s;
}

.star.on {
  color: #fbbf24;
  border-color: rgba(251, 191, 36, 0.35);
  background: rgba(251, 191, 36, 0.08);
}

.ferr {
  margin: 0;
  font-size: 12px;
  color: #ef4444;
}

.fok {
  margin: 0;
  font-size: 12px;
  color: #34d399;
}

.fsubmit {
  margin-top: 6px;
  padding: 10px 14px;
  border: none;
  border-radius: 10px;
  background: #5b6cf6;
  color: #fff;
  font-family: "Syne", sans-serif;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.fsubmit:hover:not(:disabled) {
  background: #4a5ae5;
}

.fsubmit:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.fb-list-head {
  padding: 12px 20px 6px;
}

.fb-list-label {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  color: #4a5268;
}

.fb-list {
  max-height: min(280px, 40vh);
  overflow-y: auto;
  padding: 0 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.fb-skel {
  padding: 20px;
  text-align: center;
  font-size: 12px;
  color: #4a5268;
}

.fb-row {
  padding: 10px 12px;
  border-radius: 12px;
  background: #1e2235;
  border: 1px solid #272d3d;
}

.fb-row-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.fb-stars {
  font-size: 12px;
  letter-spacing: 1px;
  color: #fbbf24;
}

.fb-date {
  font-size: 10px;
  color: #4a5268;
  flex-shrink: 0;
}

.fb-comment {
  margin: 0;
  font-size: 12px;
  line-height: 1.45;
  color: #d6daf0;
  white-space: pre-wrap;
  word-break: break-word;
}

.fb-empty {
  margin: 0;
  padding: 16px 8px;
  text-align: center;
  font-size: 12px;
  color: #4a5268;
}
</style>
