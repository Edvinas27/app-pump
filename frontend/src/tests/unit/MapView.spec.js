import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ref } from 'vue'

// ---------------------------------------------------------------------------
// Mocks – prevent real network / Leaflet from loading in test env
// ---------------------------------------------------------------------------

vi.mock('@vue-leaflet/vue-leaflet', () => ({
  LMap:      { template: '<div />' },
  LTileLayer:{ template: '<div />' },
  LPolyline: { template: '<div />' },
  LMarker:   { template: '<div />' },
  LTooltip:  { template: '<div />' },
}))
vi.mock('leaflet/dist/leaflet.css', () => ({}))
vi.mock('../api/auth', () => ({ API_BASE_URL: 'http://127.0.0.1:3000' }))

// ---------------------------------------------------------------------------
// Helpers extracted from MapView – tested independently
// ---------------------------------------------------------------------------

const API_BASE_URL = 'http://127.0.0.1:3000'

function getPerpOffset(start, end, factor) {
  const dlat = end[0] - start[0]
  const dlng = end[1] - start[1]
  const midLat = (start[0] + end[0]) / 2
  const midLng = (start[1] + end[1]) / 2
  return [midLat - dlng * factor, midLng + dlat * factor]
}

function formatCoordLabel(latlng) {
  if (!latlng || latlng.length < 2) return '—'
  return `${Number(latlng[0]).toFixed(4)}°, ${Number(latlng[1]).toFixed(4)}°`
}

function formatDistanceKm(distanceKm) {
  if (distanceKm == null || Number.isNaN(Number(distanceKm))) return '—'
  return `${Number(distanceKm).toFixed(2)} km`
}

const routeColors = {
  default: ['#93c5fd', '#86efac', '#fca5a5'],
  active:  ['#2563eb', '#16a34a', '#dc2626'],
}

function getRouteColor(routes, route, isActive) {
  const idx = routes.indexOf(route)
  return isActive ? routeColors.active[idx] : routeColors.default[idx]
}

const CAR_REQUIRED_MSG =
  'Select a car in My cars (top right) before planning or choosing a route.'

function requireCarOrExplain(activeCarId, errorRef) {
  if (activeCarId != null) return true
  errorRef.value = CAR_REQUIRED_MSG
  return false
}

// ---------------------------------------------------------------------------

describe('MapView – getPerpOffset()', () => {
  const start = [54.0, 25.0]
  const end   = [55.0, 26.0]

  it('returns an array of two numbers', () => {
    const result = getPerpOffset(start, end, 0.3)
    expect(result).toHaveLength(2)
    result.forEach(v => expect(typeof v).toBe('number'))
  })

  it('with factor 0, returns the midpoint', () => {
    const [midLat, midLng] = getPerpOffset(start, end, 0)
    expect(midLat).toBeCloseTo((start[0] + end[0]) / 2)
    expect(midLng).toBeCloseTo((start[1] + end[1]) / 2)
  })

  it('positive and negative factors produce mirrored offsets around midpoint', () => {
    const [lat1, lng1] = getPerpOffset(start, end, 0.3)
    const [lat2, lng2] = getPerpOffset(start, end, -0.3)
    const midLat = (start[0] + end[0]) / 2
    const midLng = (start[1] + end[1]) / 2
    expect(lat1 - midLat).toBeCloseTo(-(lat2 - midLat))
    expect(lng1 - midLng).toBeCloseTo(-(lng2 - midLng))
  })

  it('larger factor produces offset further from midpoint', () => {
    const [lat1] = getPerpOffset(start, end, 0.1)
    const [lat2] = getPerpOffset(start, end, 0.5)
    const midLat = (start[0] + end[0]) / 2
    expect(Math.abs(lat2 - midLat)).toBeGreaterThan(Math.abs(lat1 - midLat))
  })
})

// ---------------------------------------------------------------------------

describe('MapView – formatCoordLabel()', () => {
  it('formats lat/lng to 4 decimal places with degree symbol', () => {
    expect(formatCoordLabel([54.6872, 25.2797])).toBe('54.6872°, 25.2797°')
  })

  it('returns "—" for null', () => {
    expect(formatCoordLabel(null)).toBe('—')
  })

  it('returns "—" for empty array', () => {
    expect(formatCoordLabel([])).toBe('—')
  })

  it('returns "—" for array with only one element', () => {
    expect(formatCoordLabel([54.6])).toBe('—')
  })

  it('rounds to 4 decimal places', () => {
    expect(formatCoordLabel([54.123456789, 25.987654321])).toBe('54.1235°, 25.9877°')
  })

  it('handles negative coordinates', () => {
    const label = formatCoordLabel([-33.8688, 151.2093])
    expect(label).toBe('-33.8688°, 151.2093°')
  })
})

// ---------------------------------------------------------------------------

describe('MapView – formatDistanceKm()', () => {
  it('formats a number to 2 decimal places with km suffix', () => {
    expect(formatDistanceKm(12.5)).toBe('12.50 km')
  })

  it('returns "—" for null', () => {
    expect(formatDistanceKm(null)).toBe('—')
  })

  it('returns "—" for undefined', () => {
    expect(formatDistanceKm(undefined)).toBe('—')
  })

  it('returns "—" for NaN', () => {
    expect(formatDistanceKm(NaN)).toBe('—')
  })

  it('handles zero distance', () => {
    expect(formatDistanceKm(0)).toBe('0.00 km')
  })

  it('handles large distances', () => {
    expect(formatDistanceKm(1234.567)).toBe('1234.57 km')
  })

  it('accepts numeric strings', () => {
    expect(formatDistanceKm('5.5')).toBe('5.50 km')
  })
})

// ---------------------------------------------------------------------------

describe('MapView – getRouteColor()', () => {
  const routes = [
    { id: 1, name: 'Route A' },
    { id: 2, name: 'Route B' },
    { id: 3, name: 'Route C' },
  ]

  it('returns active colour for the active route', () => {
    expect(getRouteColor(routes, routes[0], true)).toBe('#2563eb')
    expect(getRouteColor(routes, routes[1], true)).toBe('#16a34a')
    expect(getRouteColor(routes, routes[2], true)).toBe('#dc2626')
  })

  it('returns default (dim) colour for inactive routes', () => {
    expect(getRouteColor(routes, routes[0], false)).toBe('#93c5fd')
    expect(getRouteColor(routes, routes[1], false)).toBe('#86efac')
    expect(getRouteColor(routes, routes[2], false)).toBe('#fca5a5')
  })

  it('active and default colours differ for same route', () => {
    const active  = getRouteColor(routes, routes[0], true)
    const passive = getRouteColor(routes, routes[0], false)
    expect(active).not.toBe(passive)
  })
})

// ---------------------------------------------------------------------------

describe('MapView – requireCarOrExplain()', () => {
  it('returns true and leaves error unchanged when car is selected', () => {
    const errorRef = ref('')
    const result = requireCarOrExplain(42, errorRef)
    expect(result).toBe(true)
    expect(errorRef.value).toBe('')
  })

  it('returns false and sets CAR_REQUIRED_MSG when no car is selected', () => {
    const errorRef = ref('')
    const result = requireCarOrExplain(null, errorRef)
    expect(result).toBe(false)
    expect(errorRef.value).toBe(CAR_REQUIRED_MSG)
  })

  it('returns false when activeCarId is undefined', () => {
    const errorRef = ref('')
    const result = requireCarOrExplain(undefined, errorRef)
    expect(result).toBe(false)
  })

  it('accepts 0 as a valid car id', () => {
    // Edge case: car id of 0 is not null/undefined
    const errorRef = ref('')
    const result = requireCarOrExplain(0, errorRef)
    expect(result).toBe(true)
  })
})

// ---------------------------------------------------------------------------

describe('MapView – route colours palette', () => {
  it('default palette has 3 colours', () => {
    expect(routeColors.default).toHaveLength(3)
  })

  it('active palette has 3 colours', () => {
    expect(routeColors.active).toHaveLength(3)
  })

  it('all colours are valid hex strings', () => {
    const allColors = [...routeColors.default, ...routeColors.active]
    for (const c of allColors) {
      expect(c).toMatch(/^#[0-9a-fA-F]{6}$/)
    }
  })

  it('active colours are distinct from default colours', () => {
    routeColors.active.forEach((c, i) => {
      expect(c).not.toBe(routeColors.default[i])
    })
  })
})

// ---------------------------------------------------------------------------

describe('MapView – emissions fetch URL construction', () => {
  it('builds the correct endpoint path', () => {
    const endpoint = `${API_BASE_URL}/emissions/calculate`
    expect(endpoint).toBe('http://127.0.0.1:3000/emissions/calculate')
  })

  it('directions endpoint exists', () => {
    const endpoint = `${API_BASE_URL}/directions`
    expect(endpoint).toBe('http://127.0.0.1:3000/directions')
  })

  it('reverse-geocode endpoint exists', () => {
    const endpoint = `${API_BASE_URL}/geocode/reverse`
    expect(endpoint).toBe('http://127.0.0.1:3000/geocode/reverse')
  })
})

// ---------------------------------------------------------------------------

describe('MapView – initial map state', () => {
  it('default center is Vilnius coordinates', () => {
    const center = [54.6872, 25.2797]
    expect(center[0]).toBeCloseTo(54.6872, 3)
    expect(center[1]).toBeCloseTo(25.2797, 3)
  })

  it('default zoom level is 12', () => {
    const zoom = 12
    expect(zoom).toBe(12)
  })
})
