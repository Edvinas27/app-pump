import { describe, expect, it } from "vitest"
import {
  decorateRoutesWithCo2Limit,
  filterVisibleRoutes,
  normalizeMaxCo2Kg,
} from "./routeFilter"

describe("normalizeMaxCo2Kg", () => {
  it("returns null for empty values", () => {
    expect(normalizeMaxCo2Kg("")).toBeNull()
    expect(normalizeMaxCo2Kg(null)).toBeNull()
    expect(normalizeMaxCo2Kg(undefined)).toBeNull()
  })

  it("returns null for invalid or negative values", () => {
    expect(normalizeMaxCo2Kg("abc")).toBeNull()
    expect(normalizeMaxCo2Kg(-1)).toBeNull()
  })

  it("parses valid numeric values", () => {
    expect(normalizeMaxCo2Kg("1.25")).toBe(1.25)
    expect(normalizeMaxCo2Kg(2)).toBe(2)
  })
})

describe("route CO2 filtering", () => {
  const routes = [
    { id: 1, tripCo2Kg: 0.9 },
    { id: 2, tripCo2Kg: 1.4 },
    { id: 3, tripCo2Kg: null },
  ]

  it("marks routes over limit", () => {
    const decorated = decorateRoutesWithCo2Limit(routes, 1.0)
    expect(decorated[0].exceedsCo2Limit).toBe(false)
    expect(decorated[1].exceedsCo2Limit).toBe(true)
    expect(decorated[2].exceedsCo2Limit).toBe(false)
  })

  it("keeps all routes in mark mode", () => {
    const decorated = decorateRoutesWithCo2Limit(routes, 1.0)
    const visible = filterVisibleRoutes(decorated, "mark")
    expect(visible).toHaveLength(3)
  })

  it("hides only routes above limit in hide mode", () => {
    const decorated = decorateRoutesWithCo2Limit(routes, 1.0)
    const visible = filterVisibleRoutes(decorated, "hide")
    expect(visible.map((r) => r.id)).toEqual([1, 3])
  })
})
