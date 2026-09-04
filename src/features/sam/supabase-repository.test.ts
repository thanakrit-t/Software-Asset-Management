import { describe, expect, test } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { createSupabaseSamRepository } from "./supabase-repository";

class FakeQuery implements PromiseLike<{ data: unknown[] | unknown | null; error: null }> {
  readonly calls: Array<[string, ...unknown[]]> = [];

  constructor(private readonly result: unknown[] | unknown | null) {}

  select(...args: unknown[]) { this.calls.push(["select", ...args]); return this; }
  is(...args: unknown[]) { this.calls.push(["is", ...args]); return this; }
  eq(...args: unknown[]) { this.calls.push(["eq", ...args]); return this; }
  order(...args: unknown[]) { this.calls.push(["order", ...args]); return this; }
  maybeSingle() { this.calls.push(["maybeSingle"]); return Promise.resolve({ data: this.result, error: null }); }
  then<TResult1 = { data: unknown[] | unknown | null; error: null }, TResult2 = never>(
    onfulfilled?: ((value: { data: unknown[] | unknown | null; error: null }) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve({ data: this.result, error: null }).then(onfulfilled, onrejected);
  }
}

function fakeClient(fixtures: Record<string, unknown[] | unknown | null>) {
  const queries = new Map<string, FakeQuery>();
  const client = {
    from(table: string) {
      const query = new FakeQuery(fixtures[table] ?? []);
      queries.set(table, query);
      return query;
    },
  } as unknown as SupabaseClient<Database>;
  return { client, queries };
}

describe("SupabaseSamRepository", () => {
  test("reads active assets from the safe inventory view and maps filters", async () => {
    const { client, queries } = fakeClient({
      asset_inventory_v: [{
        id: "asset-1", asset_code: "TKC-001", computer_name: "PC-001",
        asset_type_code: "pc", asset_status_code: "active", site_id: "site-1",
        site_name: "Factory", site_code: "FAC", version: 4, archived_at: null,
      }],
    });

    const result = await createSupabaseSamRepository(client).listAssets({ siteId: "site-1" });

    expect(result[0]).toMatchObject({ id: "asset-1", assetCode: "TKC-001", version: 4 });
    expect(queries.get("asset_inventory_v")?.calls).toEqual(expect.arrayContaining([
      ["select", "*"], ["is", "archived_at", null], ["eq", "site_id", "site-1"],
    ]));
  });

  test("reads Licenses only from the secret-safe view", async () => {
    const { client, queries } = fakeClient({
      license_safe_v: [{
        id: "license-1", license_reference: "LIC-001", product_name: "Office",
        publisher_name: "Microsoft", version_edition: "2024", owned_quantity: 5,
        allocated_quantity: 1, available_quantity: 4, lifecycle_status: "active",
        compliance_status: "compliant", scope_mode: "all_sites", version: 2,
        archived_at: null, license_key_masked: "****-ABCD", serial_number_masked: null,
      }],
    });

    const result = await createSupabaseSamRepository(client).listLicenses();

    expect(result[0]).not.toHaveProperty("licenseKey");
    expect(result[0]).toMatchObject({ licenseKeyMasked: "****-ABCD", version: 2 });
    expect(queries.has("license_safe_v")).toBe(true);
    expect([...queries.keys()]).not.toContain("license_entitlements");
    expect(queries.get("license_safe_v")?.calls).toContainEqual(["is", "archived_at", null]);
  });
});
