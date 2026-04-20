export type Co2Route = {
  id: number
  tripCo2Kg: number | null
}

export type DecoratedCo2Route<T extends Co2Route> = T & {
  exceedsCo2Limit: boolean
}

export function normalizeMaxCo2Kg(value: string | number | null | undefined): number | null {
  if (value === "" || value == null) return null
  const parsed = Number(value)
  if (Number.isNaN(parsed) || parsed < 0) return null
  return parsed
}

export function decorateRoutesWithCo2Limit<T extends Co2Route>(
  routes: T[],
  limit: number | null,
): Array<DecoratedCo2Route<T>> {
  return routes.map((route) => ({
    ...route,
    exceedsCo2Limit: limit != null && route.tripCo2Kg != null && route.tripCo2Kg > limit,
  }))
}

export function filterVisibleRoutes<T extends { exceedsCo2Limit: boolean }>(
  routes: T[],
  action: "mark" | "hide",
): T[] {
  if (action !== "hide") return routes
  return routes.filter((route) => !route.exceedsCo2Limit)
}
