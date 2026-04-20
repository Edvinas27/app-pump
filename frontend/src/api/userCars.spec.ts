import { beforeEach, describe, expect, it, vi } from "vitest"

const mocks = vi.hoisted(() => {
  const getMock = vi.fn()
  const postMock = vi.fn()
  const deleteMock = vi.fn()
  const createMock = vi.fn(() => ({
    get: getMock,
    post: postMock,
    delete: deleteMock,
  }))
  return { getMock, postMock, deleteMock, createMock }
})

vi.mock("axios", () => ({
  default: { create: mocks.createMock },
}))

import { assignUserCar, deleteUserCar, fetchUserCars } from "./userCars"

describe("userCars API fallback", () => {
  beforeEach(() => {
    mocks.getMock.mockReset()
    mocks.postMock.mockReset()
    mocks.deleteMock.mockReset()
    mocks.createMock.mockClear()
  })

  it("fetchUserCars retries on /api when /me/cars is 404", async () => {
    mocks.getMock
      .mockRejectedValueOnce({ response: { status: 404 } })
      .mockResolvedValueOnce({ data: [{ id: 1 }] })

    const data = await fetchUserCars()

    expect(data).toEqual([{ id: 1 }])
    expect(mocks.getMock).toHaveBeenNthCalledWith(1, "/me/cars", { params: undefined })
    expect(mocks.getMock).toHaveBeenNthCalledWith(2, "/api/me/cars", { params: undefined })
  })

  it("assignUserCar keeps 422 validation error", async () => {
    const validationError = { response: { status: 422, data: { errors: { car_id: "taken" } } } }
    mocks.postMock.mockRejectedValueOnce(validationError)

    await expect(assignUserCar(10)).rejects.toBe(validationError)
    expect(mocks.postMock).toHaveBeenCalledTimes(1)
    expect(mocks.postMock).toHaveBeenCalledWith("/me/cars", { car_id: 10 })
  })

  it("deleteUserCar tries all fallback paths on 404", async () => {
    mocks.deleteMock
      .mockRejectedValueOnce({ response: { status: 404 } })
      .mockRejectedValueOnce({ response: { status: 404 } })
      .mockResolvedValueOnce({ data: { ok: true } })

    const data = await deleteUserCar(5)

    expect(data).toEqual({ ok: true })
    expect(mocks.deleteMock).toHaveBeenNthCalledWith(1, "/me/cars/5")
    expect(mocks.deleteMock).toHaveBeenNthCalledWith(2, "/api/me/cars/5")
    expect(mocks.deleteMock).toHaveBeenNthCalledWith(3, "/api/v1/me/cars/5")
  })
})
