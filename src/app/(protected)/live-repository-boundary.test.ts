import { expect, test, vi } from "vitest";

vi.mock("@/features/sam/mock-repository", () => {
  throw new Error("Protected routes must not import mockSamRepository");
});

test("protected operational pages do not depend on the mock repository", async () => {
  await expect(Promise.all([
    import("./page"),
    import("./assets/page"),
    import("./assets/[id]/page"),
    import("./software/page"),
    import("./licenses/page"),
    import("./licenses/[id]/page"),
    import("./allocations/page"),
    import("./notifications/page"),
    import("./(admin)/audit-logs/page"),
    import("./(admin)/users/page"),
  ])).resolves.toHaveLength(10);
}, 15_000);

