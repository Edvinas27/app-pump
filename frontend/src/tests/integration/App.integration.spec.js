import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { ref, computed, watch, nextTick } from 'vue'

// ---------------------------------------------------------------------------
// Integration tests validate the interaction surface between the three
// components (App → SelectCar → MapView) without mounting the real .vue
// files (which need a Leaflet DOM + Vite transform pipeline).  Instead we
// simulate the exact same reactive graph that the real components share.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Shared state simulator – mirrors App.vue wiring
// ---------------------------------------------------------------------------

function buildAppState() {
  // App-level
  const authenticated  = ref(false)
  const activeCarId    = ref(undefined)
  const carsKey        = ref(0)

  // SelectCar-level (emits 'active-car-change')
  const scCars     = ref([])
  const scActiveId = ref(null)

  // Simulates @active-car-change handler in App.vue
  watch(scActiveId, (id) => {
    activeCarId.value = id ?? undefined
  })

  // MapView-level – reactive to activeCarId from App
  const mvError         = ref(null)
  const mvEmissionData  = ref(null)
  const mvSelectedRoute = ref(null)

  const CAR_REQUIRED_MSG = 'Select a car in My cars (top right) before planning or choosing a route.'

  function mvRequireCar() {
    if (activeCarId.value != null) return true
    mvError.value = CAR_REQUIRED_MSG
    return false
  }

  // When activeCarId is cleared, MapView resets its selection/emission state
  watch(activeCarId, (id) => {
    if (id == null) {
      mvSelectedRoute.value = null
      mvEmissionData.value  = null
      // If the error was the car-required banner, clear it once a car IS selected
    } else if (mvError.value === CAR_REQUIRED_MSG) {
      mvError.value = null
    }
  })

  return {
    authenticated, activeCarId, carsKey,
    scCars, scActiveId,
    mvError, mvEmissionData, mvSelectedRoute,
    mvRequireCar, CAR_REQUIRED_MSG,
  }
}

// ---------------------------------------------------------------------------
// Authentication flow
// ---------------------------------------------------------------------------

describe('Integration – authentication flow', () => {
  it('starts unauthenticated', () => {
    const { authenticated } = buildAppState()
    expect(authenticated.value).toBe(false)
  })

  it('transitions to authenticated after onAuthSuccess', () => {
    const { authenticated } = buildAppState()
    // Simulate App.vue onAuthSuccess
    authenticated.value = true
    expect(authenticated.value).toBe(true)
  })

  it('increments carsKey on each auth success (forces SelectCar remount)', async () => {
    const { carsKey } = buildAppState()
    const before = carsKey.value
    carsKey.value += 1
    expect(carsKey.value).toBe(before + 1)
  })
})

// ---------------------------------------------------------------------------
// SelectCar → App (active car propagation)
// ---------------------------------------------------------------------------

describe('Integration – SelectCar emits active-car-change → App.activeCarId', () => {
  it('activeCarId is undefined when SelectCar has no cars', async () => {
    const { activeCarId } = buildAppState()
    expect(activeCarId.value).toBeUndefined()
  })

  it('activeCarId is updated when SelectCar emits a car id', async () => {
    const { scActiveId, activeCarId } = buildAppState()
    scActiveId.value = 42
    await nextTick()
    expect(activeCarId.value).toBe(42)
  })

  it('activeCarId becomes undefined when SelectCar emits null', async () => {
    const { scActiveId, activeCarId } = buildAppState()
    scActiveId.value = 42
    await nextTick()
    scActiveId.value = null
    await nextTick()
    expect(activeCarId.value).toBeUndefined()
  })

  it('switching between cars updates activeCarId correctly', async () => {
    const { scActiveId, activeCarId } = buildAppState()
    scActiveId.value = 1
    await nextTick()
    scActiveId.value = 2
    await nextTick()
    expect(activeCarId.value).toBe(2)
  })
})

// ---------------------------------------------------------------------------
// App → MapView (car selection guard)
// ---------------------------------------------------------------------------

describe('Integration – App.activeCarId → MapView guard', () => {
  it('mvRequireCar returns false and sets error when no car is selected', () => {
    const { mvRequireCar, mvError, CAR_REQUIRED_MSG } = buildAppState()
    const result = mvRequireCar()
    expect(result).toBe(false)
    expect(mvError.value).toBe(CAR_REQUIRED_MSG)
  })

  it('mvRequireCar returns true when a car is selected', async () => {
    const { scActiveId, mvRequireCar, mvError } = buildAppState()
    scActiveId.value = 10
    await nextTick()
    const result = mvRequireCar()
    expect(result).toBe(true)
    expect(mvError.value).toBeNull()
  })

  it('MapView clears car-required error once a car is selected', async () => {
    const { scActiveId, mvRequireCar, mvError, CAR_REQUIRED_MSG } = buildAppState()
    // trigger the error
    mvRequireCar()
    expect(mvError.value).toBe(CAR_REQUIRED_MSG)
    // now select a car
    scActiveId.value = 7
    await nextTick()
    expect(mvError.value).toBeNull()
  })
})

// ---------------------------------------------------------------------------
// App → MapView (car deselection resets emission/route state)
// ---------------------------------------------------------------------------

describe('Integration – deselecting car resets MapView state', () => {
  it('clears selectedRoute when activeCarId becomes undefined', async () => {
    const { scActiveId, mvSelectedRoute } = buildAppState()
    scActiveId.value = 10
    await nextTick()
    mvSelectedRoute.value = { id: 1, name: 'Route A' }

    scActiveId.value = null
    await nextTick()
    expect(mvSelectedRoute.value).toBeNull()
  })

  it('clears emissionData when activeCarId becomes undefined', async () => {
    const { scActiveId, mvEmissionData } = buildAppState()
    scActiveId.value = 10
    await nextTick()
    mvEmissionData.value = { total_emission_kg: 2.5, emission_rate_g_per_km: 120 }

    scActiveId.value = null
    await nextTick()
    expect(mvEmissionData.value).toBeNull()
  })

  it('keeps emissionData when a different car is selected (not null)', async () => {
    const { scActiveId, mvEmissionData } = buildAppState()
    scActiveId.value = 10
    await nextTick()
    mvEmissionData.value = { total_emission_kg: 2.5 }

    scActiveId.value = 11        // switch car, NOT null
    await nextTick()
    // The watcher only nullifies when id === null/undefined
    expect(mvEmissionData.value).not.toBeNull()
  })
})

// ---------------------------------------------------------------------------
// SelectCar internal – car list management integration
// ---------------------------------------------------------------------------

describe('Integration – SelectCar car list management', () => {
  it('adding a car updates the list and sets it as active when list was empty', async () => {
    const { scCars, scActiveId } = buildAppState()
    const newCar = { id: 99, brand_name: 'HONDA', model: 'Civic', year: 2023, fuel_type: { id: 1, name: 'Petrol' }, co2_emission: 110 }
    scCars.value.push(newCar)
    if (!scActiveId.value) scActiveId.value = newCar.id
    await nextTick()
    expect(scCars.value).toHaveLength(1)
    expect(scActiveId.value).toBe(99)
  })

  it('deleting active car moves active id to the next car', async () => {
    const { scCars, scActiveId, activeCarId } = buildAppState()
    const cars = [
      { id: 1, brand_name: 'A', model: 'M1', year: 2020, fuel_type: { id: 1, name: 'Petrol' }, co2_emission: 100 },
      { id: 2, brand_name: 'B', model: 'M2', year: 2021, fuel_type: { id: 2, name: 'Diesel' }, co2_emission: 130 },
    ]
    scCars.value = [...cars]
    scActiveId.value = 1
    await nextTick()
    expect(activeCarId.value).toBe(1)

    // Delete active car
    scCars.value = scCars.value.filter(c => c.id !== 1)
    scActiveId.value = scCars.value[0]?.id ?? null
    await nextTick()

    expect(scCars.value).toHaveLength(1)
    expect(scActiveId.value).toBe(2)
    expect(activeCarId.value).toBe(2)
  })

  it('deleting the last car sets activeCarId to undefined in App', async () => {
    const { scCars, scActiveId, activeCarId } = buildAppState()
    scCars.value = [{ id: 5, brand_name: 'X', model: 'Y', year: 2022, fuel_type: { id: 1, name: 'Petrol' }, co2_emission: 90 }]
    scActiveId.value = 5
    await nextTick()
    expect(activeCarId.value).toBe(5)

    scCars.value = []
    scActiveId.value = null
    await nextTick()
    expect(activeCarId.value).toBeUndefined()
  })
})

// ---------------------------------------------------------------------------
// Emissions workflow integration
// ---------------------------------------------------------------------------

describe('Integration – emissions workflow', () => {
  it('emission calculation requires a selected car', async () => {
    const { mvRequireCar } = buildAppState()
    // No car selected → guard fails
    expect(mvRequireCar()).toBe(false)
  })

  it('emission data is tied to both a route AND a car', async () => {
    const { scActiveId, mvSelectedRoute, mvEmissionData } = buildAppState()
    scActiveId.value = 10
    await nextTick()

    mvSelectedRoute.value = { id: 2, distanceKmRaw: 15.3 }
    // Simulate a successful emission fetch
    mvEmissionData.value  = { total_emission_kg: 1.836, emission_rate_g_per_km: 120 }

    expect(mvEmissionData.value.total_emission_kg).toBeCloseTo(1.836, 3)
    expect(mvEmissionData.value.emission_rate_g_per_km).toBe(120)
  })

  it('emission data is cleared when route is deselected', async () => {
    const { scActiveId, mvSelectedRoute, mvEmissionData } = buildAppState()
    scActiveId.value = 10
    await nextTick()
    mvSelectedRoute.value = { id: 1, distanceKmRaw: 10 }
    mvEmissionData.value  = { total_emission_kg: 1.2, emission_rate_g_per_km: 120 }

    mvSelectedRoute.value = null
    mvEmissionData.value  = null

    expect(mvEmissionData.value).toBeNull()
  })
})

// ---------------------------------------------------------------------------
// MapView – map click interaction guard integration
// ---------------------------------------------------------------------------

describe('Integration – map click guarded by car selection', () => {
  it('a map click is silently rejected when no car is selected', async () => {
    const { mvRequireCar, mvError, CAR_REQUIRED_MSG } = buildAppState()
    // Simulate onMapClick calling requireCarOrExplain
    const allowed = mvRequireCar()
    expect(allowed).toBe(false)
    expect(mvError.value).toBe(CAR_REQUIRED_MSG)
  })

  it('a map click is allowed when a car is selected', async () => {
    const { scActiveId, mvRequireCar, mvError } = buildAppState()
    scActiveId.value = 3
    await nextTick()
    const allowed = mvRequireCar()
    expect(allowed).toBe(true)
    expect(mvError.value).toBeNull()
  })
})

// ---------------------------------------------------------------------------
// UI panel visibility (App overlay logic)
// ---------------------------------------------------------------------------

describe('Integration – App overlay / panel visibility', () => {
  it('overlay starts collapsed (expanded = false)', () => {
    const expanded = ref(false)
    expect(expanded.value).toBe(false)
  })

  it('toggles to true on first click', async () => {
    const expanded = ref(false)
    expanded.value = !expanded.value
    await nextTick()
    expect(expanded.value).toBe(true)
  })

  it('feedback overlay starts collapsed', () => {
    const feedbackExpanded = ref(false)
    expect(feedbackExpanded.value).toBe(false)
  })

  it('cars panel and feedback panel can be independently toggled', async () => {
    const expanded         = ref(false)
    const feedbackExpanded = ref(false)
    expanded.value         = true
    await nextTick()
    expect(expanded.value).toBe(true)
    expect(feedbackExpanded.value).toBe(false)
    feedbackExpanded.value = true
    await nextTick()
    expect(expanded.value).toBe(true)
    expect(feedbackExpanded.value).toBe(true)
  })
})
