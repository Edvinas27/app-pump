export const API_BASE_URL: string =
  import.meta.env.VITE_API_BASE_URL ?? "http://127.0.0.1:3000"

const DEFAULT_HEADERS: Record<string, string> = {
  "ngrok-skip-browser-warning": "true",
}

/**
 * Drop-in replacement for `fetch` that always injects the ngrok header
 * (and any other project-wide default headers).
 */
export function apiFetch(
  input: RequestInfo | URL,
  init?: RequestInit,
): Promise<Response> {
  const headers: Record<string, string> = {
    ...DEFAULT_HEADERS,
    ...((init?.headers as Record<string, string>) ?? {}),
  }
  return fetch(input, { ...init, headers })
}
