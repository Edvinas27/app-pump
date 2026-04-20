export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://127.0.0.1:3000"

export type AuthUser = {
  id: number
  email: string
  username: string
  created_at: string
}

export type LoginLocation = {
  country: string | null
  city: string | null
  latitude: number | null
  longitude: number | null
  login_ip: string | null
}

export type AuthSuccess = {
  user: AuthUser
  token: string
  location: LoginLocation | null
}

export const LOGIN_LOCATION_KEY = "loginLocation"

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split(".")
  if (parts.length !== 3) return null
  try {
    const b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/")
    const pad = (4 - (b64.length % 4)) % 4
    const padded = b64 + "=".repeat(pad)
    const json = atob(padded)
    return JSON.parse(json) as Record<string, unknown>
  } catch {
    return null
  }
}

/** True if token looks like a JWT and `exp` is in the future (server uses exp, see JsonWebToken.encode). */
export function isTokenUsable(token: string | null): boolean {
  if (!token || typeof token !== "string") return false
  const payload = decodeJwtPayload(token)
  if (!payload) return false
  const exp = payload.exp
  if (typeof exp !== "number") return false
  const now = Math.floor(Date.now() / 1000)
  return exp > now + 30
}

/**
 * POST /sessions — OpenAPI `LoginRequest`: { email, password }.
 */
export async function loginSession(email: string, password: string): Promise<AuthSuccess> {
  const res = await fetch(`${API_BASE_URL}/sessions`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  })

  const data = (await res.json().catch(() => ({}))) as Record<string, unknown>

  if (!res.ok) {
    const msg = typeof data.error === "string" ? data.error : "Sign in failed"
    throw new Error(msg)
  }

  return parseAuthSuccess(data)
}

/**
 * POST /users — OpenAPI `RegisterRequest`: { email, username, password }.
 */
export async function registerUser(
  email: string,
  username: string,
  password: string,
): Promise<AuthSuccess> {
  const res = await fetch(`${API_BASE_URL}/users`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, username, password }),
  })

  const data = (await res.json().catch(() => ({}))) as Record<string, unknown>

  if (!res.ok) {
    if (res.status === 422 && data.errors && typeof data.errors === "object" && !Array.isArray(data.errors)) {
      const errs = data.errors as Record<string, unknown>
      const msg = Object.values(errs)
        .map((v) => (typeof v === "string" ? v : String(v)))
        .filter(Boolean)
        .join(", ")
      throw new Error(msg || "Validation failed")
    }
    const err = typeof data.error === "string" ? data.error : "Registration failed"
    throw new Error(err)
  }

  return parseAuthSuccess(data)
}

function parseAuthSuccess(data: Record<string, unknown>): AuthSuccess {
  const token = data.token
  const user = data.user
  if (typeof token !== "string" || !user || typeof user !== "object") {
    throw new Error("Invalid response from server")
  }
  return { token, user: user as AuthUser, location: parseLoginLocation(data) }
}

function parseLoginLocation(data: Record<string, unknown>): LoginLocation | null {
  const hasAny =
    "country" in data ||
    "city" in data ||
    "latitude" in data ||
    "longitude" in data ||
    "login_ip" in data
  if (!hasAny) return null

  const num = (v: unknown): number | null =>
    typeof v === "number" && Number.isFinite(v) ? v : null
  const str = (v: unknown): string | null =>
    typeof v === "string" && v.length > 0 ? v : null

  return {
    country: str(data.country),
    city: str(data.city),
    latitude: num(data.latitude),
    longitude: num(data.longitude),
    login_ip: str(data.login_ip),
  }
}

export function readStoredUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem("user")
    if (!raw) return null
    return JSON.parse(raw) as AuthUser
  } catch {
    return null
  }
}

export function readStoredLoginLocation(): LoginLocation | null {
  try {
    const raw = localStorage.getItem(LOGIN_LOCATION_KEY)
    if (!raw) return null
    return JSON.parse(raw) as LoginLocation
  } catch {
    return null
  }
}

export function clearStoredAuth(): void {
  localStorage.removeItem("token")
  localStorage.removeItem("user")
  localStorage.removeItem(LOGIN_LOCATION_KEY)
}
