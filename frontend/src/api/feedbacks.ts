import { apiFetch } from "./config"

export type Feedback = {
  id: number
  comment: string
  rating: number
  created_at: string
  updated_at: string
}

async function fetchWithFallback(path: string, init?: RequestInit): Promise<Response> {
  const paths = [path, `/api${path}`, `/api/v1${path}`]
  let lastResponse: Response | null = null
  for (const candidate of paths) {
    const res = await apiFetch(candidate, init)
    if (res.status !== 404) return res
    lastResponse = res
  }
  return lastResponse as Response
}

/** GET /feedbacks — public in current API. */
export async function fetchFeedbacks(): Promise<Feedback[]> {
  const res = await fetchWithFallback("/feedbacks", {
    headers: { Accept: "application/json" },
  })
  const data = (await res.json().catch(() => null)) as unknown
  if (!res.ok) {
    throw new Error("Could not load feedbacks.")
  }
  return Array.isArray(data) ? (data as Feedback[]) : []
}

/** POST /feedbacks — body matches OpenAPI FeedbackCreateRequest. */
export async function createFeedback(comment: string, rating: number): Promise<Feedback> {
  const res = await fetchWithFallback("/feedbacks", {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ comment: comment.trim(), rating: Math.round(rating) }),
  })
  const data = (await res.json().catch(() => ({}))) as Record<string, unknown>
  if (!res.ok) {
    if (res.status === 422 && data.errors && typeof data.errors === "object" && !Array.isArray(data.errors)) {
      const errs = data.errors as Record<string, string>
      const msg = Object.values(errs)
        .map((v) => (typeof v === "string" ? v : String(v)))
        .filter(Boolean)
        .join(", ")
      throw new Error(msg || "Validation failed")
    }
    throw new Error(typeof data.error === "string" ? data.error : "Could not send feedback.")
  }
  return data as Feedback
}
