import { resolveViewer, type ViewerGateway } from "./viewer";

function gateway(
  claims: { sub?: string } | null,
  profile: Awaited<ReturnType<ViewerGateway["getProfile"]>>,
): ViewerGateway {
  return {
    getClaims: async () => claims,
    getProfile: async () => profile,
  };
}

test("returns null when verified claims have no subject", async () => {
  expect(await resolveViewer(gateway(null, null))).toBeNull();
  expect(await resolveViewer(gateway({}, null))).toBeNull();
});

test("returns null when profile is missing or not active", async () => {
  expect(await resolveViewer(gateway({ sub: "user-1" }, null))).toBeNull();
  expect(
    await resolveViewer(
      gateway(
        { sub: "user-1" },
        {
          id: "user-1",
          display_name: "Inactive User",
          email: "inactive@example.com",
          app_role: "user",
          account_status: "inactive",
        },
      ),
    ),
  ).toBeNull();
});

test("maps only approved viewer fields for an active profile", async () => {
  await expect(
    resolveViewer(
      gateway(
        { sub: "admin-1" },
        {
          id: "admin-1",
          display_name: "Admin User",
          email: "admin@example.com",
          app_role: "admin",
          account_status: "active",
        },
      ),
    ),
  ).resolves.toEqual({
    id: "admin-1",
    displayName: "Admin User",
    email: "admin@example.com",
    role: "admin",
  });
});

test("rejects a profile role outside the application role contract", async () => {
  expect(
    await resolveViewer(
      gateway(
        { sub: "user-1" },
        {
          id: "user-1",
          display_name: "Unexpected Role",
          email: "unexpected@example.com",
          app_role: "owner",
          account_status: "active",
        },
      ),
    ),
  ).toBeNull();
});
