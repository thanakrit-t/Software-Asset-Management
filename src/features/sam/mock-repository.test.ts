import { mockSamRepository } from "./mock-repository";

test("returns assets for the requested site", async () => {
  const assets = await mockSamRepository.listAssets({ siteId: "factory" });
  expect(assets.length).toBeGreaterThan(0);
  expect(assets.every((asset) => asset.site.id === "factory")).toBe(true);
});

test("finds assets by code, computer name, user, MAC, or IP", async () => {
  const byComputer = await mockSamRepository.listAssets({ query: "TPO-083-PC" });
  const byIp = await mockSamRepository.listAssets({ query: "192.168.1.57" });
  expect(byComputer.map((asset) => asset.assetCode)).toContain("TPO-083");
  expect(byIp.map((asset) => asset.assetCode)).toContain("TPO-083");
});

test("derives available seats from owned and allocated quantities", async () => {
  const licenses = await mockSamRepository.listLicenses({});
  expect(
    licenses.every(
      (license) =>
        license.availableQuantity === license.ownedQuantity - license.allocatedQuantity,
    ),
  ).toBe(true);
});
