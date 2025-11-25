import { describe, it, expect } from "vitest";
import { types } from "@stacks/transactions";

// simnet is provided globally by vitest-environment-clarinet

describe("vesting-schedule contract", () => {
  it("owner can create a valid schedule", () => {
    const deployer = simnet.getAccount("deployer");
    const employee = simnet.getAccount("wallet_1");

    const res = simnet.callPublicFn(
      "vesting-schedule",
      "create-schedule",
      [
        types.principal(employee.address),
        types.uint(100n), // start
        types.uint(110n), // cliff
        types.uint(100n), // duration
        types.uint(1_000_000n), // total-amount
      ],
      deployer.address
    );

    expect(res.result).toBeOk();
  });

  it("non-owner cannot create schedule", () => {
    const deployer = simnet.getAccount("deployer");
    const employee = simnet.getAccount("wallet_1");
    const attacker = simnet.getAccount("wallet_2");

    const res = simnet.callPublicFn(
      "vesting-schedule",
      "create-schedule",
      [
        types.principal(employee.address),
        types.uint(100n),
        types.uint(110n),
        types.uint(100n),
        types.uint(1_000_000n),
      ],
      attacker.address
    );

    expect(res.result).toBeErr();
  });

  it("schedule summary exposes stored data", () => {
    const deployer = simnet.getAccount("deployer");
    const employee = simnet.getAccount("wallet_1");

    const create = simnet.callPublicFn(
      "vesting-schedule",
      "create-schedule",
      [
        types.principal(employee.address),
        types.uint(100n),
        types.uint(110n),
        types.uint(100n),
        types.uint(1_000_000n),
      ],
      deployer.address
    );

    const id = (create.result.expectOk() as any).value ?? 0n;

    const summary = simnet.callReadOnlyFn(
      "vesting-schedule",
      "list-schedule-summary",
      [types.uint(id)],
      deployer.address
    );

    expect(summary.result).toBeOk();
  });
});
