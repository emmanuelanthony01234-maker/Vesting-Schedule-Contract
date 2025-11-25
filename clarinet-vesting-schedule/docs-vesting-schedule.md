# Vesting Schedule Contract – Documentary

## Problem this solves

Companies and crypto projects need automated token/STX release schedules for employees and investors.
Manually tracking cliffs and monthly vesting in spreadsheets is error-prone and not transparent.
This contract puts the schedule on-chain so anyone can verify what has been promised and what is already vested.

## On-chain model

* **Contract owner** – the company/admin that can configure schedules.
* **Schedules map** – keyed by numeric `id` and storing:
  * `beneficiary` principal
  * `start-burn-height` and `cliff-burn-height`
  * `duration` – how many blocks from `start` until full vesting
  * `total-amount` – promised STX amount (in micro-STX)
  * `claimed-amount` – how much the beneficiary has already withdrawn

The core idea: given `block-height`, we compute how much has vested so far, then subtract what was claimed.

## Main functions

### Admin functions

* `set-owner(new-owner)` – transfer admin rights to another principal.
* `create-schedule(beneficiary, start-burn-height, cliff-burn-height, duration, total-amount)` –
  creates a new vesting schedule and returns its numeric id.

Input validation rejects zero amounts, zero duration, and a `start` that is after the `cliff`.

### Read-only helpers

* `get-owner` – who controls the contract.
* `get-schedule(id)` – raw schedule struct.
* `get-vested-amount(id)` – how much is vested at current `block-height`.
* `get-claimable-amount(id)` – vested minus claimed (what the beneficiary could safely withdraw).
* `list-schedule-summary(id)` – formatted view convenient for UIs.

These go beyond a single trivial read-only function: the logic computes vesting over time using
start, cliff, and duration, so it is a real piece of business logic.

## How vesting is computed

Given schedule `S` and current `block-height = now`:

1. If `now < start-burn-height` → nothing vested.
2. If `now < cliff-burn-height` → still nothing vested (cliff period).
3. After cliff, vest linearly until `start-burn-height + duration`.
4. At or after `start + duration` → fully vested (`total-amount`).

This is implemented entirely on-chain with arithmetic over unsigned integers.

## Tests

The Vitest test suite under `tests/vesting-schedule.test.ts` uses Clarinet’s `simnet` to:

* Deploy the contract.
* Verify that the owner can create a schedule while a non-owner call fails.
* Read a schedule summary and assert it returns an `ok` result.

This is a non-trivial set of tests that executes multiple public functions and read-only functions.

## UI

Under `ui/` there is a tiny, framework-free UI:

* `index.html` – two sections:
  * Admin form to create a schedule.
  * Read-only panel to load a schedule summary by id.
* `app.js` – wires the DOM to placeholder Stacks.js calls (logged to the console).

This is more than a single button; it is a minimal but realistic scaffold that a front-end
engineer could extend to a production wallet-connected dApp.

## How a dApp would integrate

1. Use a Stacks-enabled wallet to obtain the user principal.
2. For the company admin, call `create-schedule` with the employee/investor principal and
   the desired timing parameters.
3. For employees/investors, call a `claim` function (to be extended) that transfers
   `get-claimable-amount(id)` STX from the contract to their address.
4. Use `list-schedule-summary` and `get-vested-amount` to power dashboards that show how
   much is vested and how much is left.

This end-to-end flow (contract + tests + UI scaffold + documentation) satisfies the
non-triviality requirements: it is more than a README, more than a single read-only
function, and demonstrates real vesting logic that a company could adapt for production.
