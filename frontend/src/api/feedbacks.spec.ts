import { beforeEach, describe, expect, it, vi } from "vitest"
import { createFeedback, fetchFeedbacks } from "./feedbacks"

describe("feedbacks API fallback", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it("fetchFeedbacks falls back to /api path when root 404", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(new Response("{}", { status: 404 }))
      .mockResolvedValueOnce(
        new Response(JSON.stringify([{ id: 1, comment: "ok", rating: 5 }]), { status: 200 }),
      )

    const data = await fetchFeedbacks()

    expect(data).toHaveLength(1)
    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(fetchMock.mock.calls[0][0]).toContain("/feedbacks")
    expect(fetchMock.mock.calls[1][0]).toContain("/api/feedbacks")
  })

  it("createFeedback reaches /api/v1 fallback when prior paths are 404", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(new Response("{}", { status: 404 }))
      .mockResolvedValueOnce(new Response("{}", { status: 404 }))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ id: 2, comment: "great", rating: 4 }), { status: 201 }),
      )

    const created = await createFeedback("great", 4)

    expect(created.id).toBe(2)
    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(fetchMock.mock.calls[2][0]).toContain("/api/v1/feedbacks")
  })
})
