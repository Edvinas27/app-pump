import { describe, it, expect, beforeEach, vi } from "vitest"
import { mount, flushPromises } from "@vue/test-utils"
import SelectCar from "./SelectCar.vue"

const fetchUserCarsMock = vi.fn()
const assignUserCarMock = vi.fn()
const deleteUserCarMock = vi.fn()

vi.mock("../api/userCars", () => ({
  fetchUserCars: (...args: unknown[]) => fetchUserCarsMock(...args),
  assignUserCar: (...args: unknown[]) => assignUserCarMock(...args),
  deleteUserCar: (...args: unknown[]) => deleteUserCarMock(...args),
}))

const axiosGetMock = vi.fn((url: string) => {
  if (url === "/cars/brands") return Promise.resolve({ data: ["AUDI"] })
  if (url === "/cars/models") return Promise.resolve({ data: ["A4"] })
  if (url === "/cars/fuel_types") return Promise.resolve({ data: [{ id: 1, name: "Petrol" }] })
  if (url === "/cars/years") return Promise.resolve({ data: [2022] })
  if (url === "/cars") {
    return Promise.resolve({
      data: { id: 99, brand_name: "AUDI", model: "A4", year: 2022, co2_emission: 120, fuel_type: { id: 1, name: "Petrol" } },
    })
  }
  return Promise.resolve({ data: [] })
})

vi.mock("axios", () => ({
  default: {
    create: () => ({
      get: axiosGetMock,
      post: vi.fn(() => Promise.resolve({ data: {} })),
      delete: vi.fn(() => Promise.resolve({ data: {} })),
    }),
  },
}))

describe("SelectCar", () => {
  beforeEach(() => {
    fetchUserCarsMock.mockReset()
    assignUserCarMock.mockReset()
    deleteUserCarMock.mockReset()
    axiosGetMock.mockClear()
  })

  it("loads and renders user cars", async () => {
    fetchUserCarsMock.mockResolvedValueOnce([
      { id: 1, brand_name: "AUDI", model: "A4", year: 2022, co2_emission: 120, fuel_type: { id: 1, name: "Petrol" } },
    ])

    const wrapper = mount(SelectCar)
    await flushPromises()

    expect(wrapper.find(".error-banner").exists()).toBe(false)
    expect(wrapper.findAll(".car-row")).toHaveLength(1)
    expect(wrapper.text()).toContain("AUDI A4")
  })

  it("shows endpoint-specific error on 404", async () => {
    fetchUserCarsMock.mockRejectedValueOnce({ response: { status: 404 } })

    const wrapper = mount(SelectCar)
    await flushPromises()

    expect(wrapper.text()).toContain("Cars endpoint not found")
  })
})