import axios from "axios"
import { API_BASE_URL, DEFAULT_HEADERS } from "./config"

const USER_CARS_PATHS = ["/me/cars", "/api/me/cars", "/api/v1/me/cars"]

function authApi() {
  return axios.create({
    baseURL: API_BASE_URL,
    headers: {
      ...DEFAULT_HEADERS,
      Authorization: `Bearer ${localStorage.getItem("token")}`,
    },
  })
}

async function authRequestWithFallback(method: "get" | "post" | "delete", paths: string[], payload?: unknown) {
  let lastError: unknown
  for (const path of paths) {
    try {
      if (method === "get") {
        const res = await authApi().get(path, { params: payload })
        return res.data
      }
      if (method === "delete") {
        const res = await authApi().delete(path)
        return res.data
      }
      const res = await authApi().post(path, payload)
      return res.data
    } catch (e) {
      lastError = e
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      if ((e as any)?.response?.status !== 404) throw e
    }
  }
  throw lastError
}

export function fetchUserCars() {
  return authRequestWithFallback("get", USER_CARS_PATHS)
}

export function assignUserCar(car_id: number) {
  return authRequestWithFallback("post", USER_CARS_PATHS, { car_id })
}

export function deleteUserCar(car_id: number) {
  return authRequestWithFallback(
    "delete",
    USER_CARS_PATHS.map((path) => `${path}/${car_id}`),
  )
}
