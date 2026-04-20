/**
 * Single source of truth for the API base URL and the default headers
 * that must be attached to every request (e.g. the ngrok bypass header).
 *
 * Change the value in one place (frontend/.env → VITE_API_BASE_URL) and
 * every request in the app picks it up automatically.
 */

export const API_BASE_URL: string =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://127.0.0.1:3000"

/** Headers that must be present on every single request the frontend sends. */
export const DEFAULT_HEADERS: Record<string, string> = {
  "ngrok-skip-browser-warning": "true",
}

/** Build an absolute URL from a relative path (or pass-through absolute URLs). */
export function apiUrl(path: string): string {
  if (/^https?:\/\//i.test(path)) return path
  const base = API_BASE_URL.replace(/\/+$/, "")
  const suffix = path.startsWith("/") ? path : `/${path}`
  return `${base}${suffix}`
}

/**
 * Thin `fetch` wrapper that:
 *  - resolves relative paths against API_BASE_URL
 *  - merges DEFAULT_HEADERS into every request
 * Pass either a relative path ("/sessions") or an absolute URL.
 */
export function apiFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const mergedHeaders = mergeHeaders(init.headers, DEFAULT_HEADERS)
  return fetch(apiUrl(path), { ...init, headers: mergedHeaders })
}

function mergeHeaders(
  incoming: HeadersInit | undefined,
  defaults: Record<string, string>,
): Headers {
  const h = new Headers(incoming ?? {})
  for (const [k, v] of Object.entries(defaults)) {
    if (!h.has(k)) h.set(k, v)
  }
  return h
}
