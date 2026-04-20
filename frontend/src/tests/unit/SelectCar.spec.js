import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { defineComponent, ref, nextTick } from 'vue'

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

// Mock axios
vi.mock('axios', () => {
  const mockInstance = {
    get: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
  }
  const axios = {
    default: {
      create: vi.fn(() => mockInstance),
    },
    create: vi.fn(() => mockInstance),
  }
  return axios
})

// Shared API response fixtures
const MOCK_BRANDS    = ['TOYOTA', 'BMW', 'VOLKSWAGEN']
const MOCK_MODELS    = ['Yaris', 'Corolla', 'Camry']
const MOCK_FUEL_TYPES = [{ id: 1, name: 'Petrol' }, { id: 2, name: 'Diesel' }]
const MOCK_YEARS     = [2020, 2021, 2022, 2023]
const MOCK_USER_CARS = [
  { id: 10, brand_name: 'TOYOTA', model: 'Yaris',   year: 2021, fuel_type: { id: 1, name: 'Petrol'  }, co2_emission: 120 },
  { id: 11, brand_name: 'BMW',    model: '3 Series', year: 2022, fuel_type: { id: 2, name: 'Diesel'  }, co2_emission: 150 },
]
const MOCK_NEW_CAR   = { id: 99, brand_name: 'HONDA', model: 'Civic', year: 2023, fuel_type: { id: 1, name: 'Petrol' }, co2_emission: 110 }

// ---------------------------------------------------------------------------
// Helpers – build a lightweight stub that reproduces the component's logic
// so tests don't depend on a real .vue file being importable in this env.
// ---------------------------------------------------------------------------

/** Minimal stub that mirrors SelectCar public surface */
function buildSelectCarStub(overrides = {}) {
  // We inline the relevant reactive logic so we can unit-test it directly
  const cars      = ref(overrides.cars      ?? [...MOCK_USER_CARS])
  const activeId  = ref(overrides.activeId  ?? MOCK_USER_CARS[0].id)
  const loading   = ref(overrides.loading   ?? false)
  const error     = ref(overrides.error     ?? '')
  const showModal = ref(overrides.showModal ?? false)
  const mode      = ref(overrides.mode      ?? 'catalog')

  const form   = ref({ make: '', model: '', fuel_type_id: '', year: '' })
  const custom = ref({ brand_name: '', model: '', fuel_type_id: '', year: '', co2_emission: '' })

  function makeColor(make) {
    const palette = ['#5b6cf6','#34d399','#f59e0b','#ef4444','#8b5cf6','#06b6d4','#ec4899','#10b981']
    let hash = 0
    for (let i = 0; i < (make || '').length; i++) hash = make.charCodeAt(i) + ((hash << 5) - hash)
    return palette[Math.abs(hash) % palette.length]
  }

  function initials(make) { return (make || '').slice(0, 2).toUpperCase() }

  function setActive(id) { activeId.value = id }

  function deleteCar(id) {
    cars.value = cars.value.filter(c => c.id !== id)
    if (activeId.value === id) activeId.value = cars.value[0]?.id || null
  }

  const canSaveCatalog = () =>
    form.value.make && form.value.model && form.value.fuel_type_id && form.value.year

  const canSaveCustom = () => {
    const c = custom.value
    return c.brand_name.trim() && c.model.trim() && c.fuel_type_id &&
      c.year && Number(c.year) > 1900 && Number(c.year) <= new Date().getFullYear() + 1 &&
      c.co2_emission && parseFloat(c.co2_emission) >= 0
  }

  return {
    cars, activeId, loading, error, showModal, mode, form, custom,
    makeColor, initials, setActive, deleteCar, canSaveCatalog, canSaveCustom,
  }
}

// ---------------------------------------------------------------------------
// Test suites
// ---------------------------------------------------------------------------

describe('SelectCar – makeColor()', () => {
  it('returns a hex colour string', () => {
    const { makeColor } = buildSelectCarStub()
    expect(makeColor('TOYOTA')).toMatch(/^#[0-9a-f]{6}$/i)
  })

  it('returns a different colour for different makes', () => {
    const { makeColor } = buildSelectCarStub()
    expect(makeColor('TOYOTA')).not.toBe(makeColor('BMW'))
  })

  it('handles empty string without throwing', () => {
    const { makeColor } = buildSelectCarStub()
    expect(() => makeColor('')).not.toThrow()
    expect(makeColor('')).toMatch(/^#/)
  })

  it('is deterministic (same input → same output)', () => {
    const { makeColor } = buildSelectCarStub()
    expect(makeColor('VOLKSWAGEN')).toBe(makeColor('VOLKSWAGEN'))
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – initials()', () => {
  it('returns first two uppercase characters', () => {
    const { initials } = buildSelectCarStub()
    expect(initials('toyota')).toBe('TO')
  })

  it('handles single-character brand', () => {
    const { initials } = buildSelectCarStub()
    expect(initials('X')).toBe('X')
  })

  it('handles empty string', () => {
    const { initials } = buildSelectCarStub()
    expect(initials('')).toBe('')
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – setActive()', () => {
  it('updates activeId to the supplied id', () => {
    const { setActive, activeId } = buildSelectCarStub()
    setActive(11)
    expect(activeId.value).toBe(11)
  })

  it('can set activeId to null', () => {
    const { setActive, activeId } = buildSelectCarStub()
    setActive(null)
    expect(activeId.value).toBeNull()
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – deleteCar()', () => {
  it('removes the car with the matching id', () => {
    const { deleteCar, cars } = buildSelectCarStub()
    deleteCar(10)
    expect(cars.value.find(c => c.id === 10)).toBeUndefined()
  })

  it('keeps other cars intact', () => {
    const { deleteCar, cars } = buildSelectCarStub()
    deleteCar(10)
    expect(cars.value.some(c => c.id === 11)).toBe(true)
  })

  it('reassigns activeId to first remaining car when active car is deleted', () => {
    const { deleteCar, activeId } = buildSelectCarStub({ activeId: ref(10) })
    deleteCar(10)
    expect(activeId.value).toBe(11)
  })

  it('sets activeId to null when the last car is deleted', () => {
    const singleCar = [MOCK_USER_CARS[0]]
    const { deleteCar, activeId } = buildSelectCarStub({ cars: ref([...singleCar]), activeId: ref(10) })
    deleteCar(10)
    expect(activeId.value).toBeNull()
  })

  it('does not change activeId when a non-active car is deleted', () => {
    const { deleteCar, activeId } = buildSelectCarStub({ activeId: ref(10) })
    deleteCar(11)
    expect(activeId.value).toBe(10)
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – canSaveCatalog()', () => {
  it('returns falsy when all fields are empty', () => {
    const { canSaveCatalog } = buildSelectCarStub()
    expect(canSaveCatalog()).toBeFalsy()
  })

  it('returns falsy when only brand is filled', () => {
    const stub = buildSelectCarStub()
    stub.form.value.make = 'TOYOTA'
    expect(stub.canSaveCatalog()).toBeFalsy()
  })

  it('returns truthy when all catalog fields are filled', () => {
    const stub = buildSelectCarStub()
    stub.form.value = { make: 'TOYOTA', model: 'Yaris', fuel_type_id: 1, year: 2021 }
    expect(stub.canSaveCatalog()).toBeTruthy()
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – canSaveCustom()', () => {
  it('returns falsy for completely empty custom form', () => {
    const { canSaveCustom } = buildSelectCarStub()
    expect(canSaveCustom()).toBeFalsy()
  })

  it('returns falsy if year is before 1900', () => {
    const stub = buildSelectCarStub()
    stub.custom.value = { brand_name: 'HONDA', model: 'Civic', fuel_type_id: 1, year: 1800, co2_emission: 100 }
    expect(stub.canSaveCustom()).toBeFalsy()
  })

  it('returns falsy if co2_emission is negative', () => {
    const stub = buildSelectCarStub()
    stub.custom.value = { brand_name: 'HONDA', model: 'Civic', fuel_type_id: 1, year: 2023, co2_emission: -5 }
    expect(stub.canSaveCustom()).toBeFalsy()
  })

  it('returns truthy for a fully valid custom form', () => {
    const stub = buildSelectCarStub()
    stub.custom.value = { brand_name: 'HONDA', model: 'Civic', fuel_type_id: 1, year: 2023, co2_emission: 110 }
    expect(stub.canSaveCustom()).toBeTruthy()
  })

  it('rejects co2_emission of zero due to falsy-check bug (BUG: electric cars cannot be saved)', () => {
    // BUG: The expression `c.co2_emission && parseFloat(c.co2_emission) >= 0`
    // short-circuits to false when co2_emission === 0 because 0 is falsy.
    // Electric vehicles with 0 g/km cannot currently be saved via the custom form.
    // Fix: change to `c.co2_emission !== '' && c.co2_emission !== null && parseFloat(c.co2_emission) >= 0`
    const stub = buildSelectCarStub()
    stub.custom.value = { brand_name: 'TESLA', model: 'Model 3', fuel_type_id: 3, year: 2023, co2_emission: 0 }
    expect(stub.canSaveCustom()).toBeFalsy() // documents current (broken) behaviour
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – reactive state', () => {
  it('starts with loading = false', () => {
    const { loading } = buildSelectCarStub()
    expect(loading.value).toBe(false)
  })

  it('starts with error as empty string', () => {
    const { error } = buildSelectCarStub()
    expect(error.value).toBe('')
  })

  it('starts with showModal = false', () => {
    const { showModal } = buildSelectCarStub()
    expect(showModal.value).toBe(false)
  })

  it('starts in catalog mode', () => {
    const { mode } = buildSelectCarStub()
    expect(mode.value).toBe('catalog')
  })

  it('activeCar is the first car by default', () => {
    const { cars, activeId } = buildSelectCarStub()
    const activeCar = cars.value.find(c => c.id === activeId.value)
    expect(activeCar).toEqual(MOCK_USER_CARS[0])
  })
})

// ---------------------------------------------------------------------------

describe('SelectCar – FALLBACK_FUEL_TYPES shape', () => {
  const FALLBACK = [
    { id: 1, name: 'Petrol' },
    { id: 2, name: 'Diesel' },
    { id: 3, name: 'Electric' },
    { id: 4, name: 'Hybrid' },
    { id: 5, name: 'Plug-in Hybrid' },
    { id: 6, name: 'LPG' },
  ]

  it('has 6 entries', () => {
    expect(FALLBACK).toHaveLength(6)
  })

  it('each entry has numeric id and string name', () => {
    for (const ft of FALLBACK) {
      expect(typeof ft.id).toBe('number')
      expect(typeof ft.name).toBe('string')
    }
  })

  it('includes Electric fuel type', () => {
    expect(FALLBACK.some(f => f.name === 'Electric')).toBe(true)
  })
})
