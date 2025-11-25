// Minimal pseudo-UI showing how a wallet/Stacks.js app would talk to the contract.
// This is intentionally lightweight but more than a single button.

const CONTRACT_ADDRESS = "ST_TEST_CONTRACT_ADDRESS"; // replace with real address when deployed
const CONTRACT_NAME = "vesting-schedule";

async function onCreateSchedule() {
  const beneficiary = document.getElementById("beneficiary").value;
  const start = BigInt(document.getElementById("start").value || "0");
  const cliff = BigInt(document.getElementById("cliff").value || "0");
  const duration = BigInt(document.getElementById("duration").value || "0");
  const total = BigInt(document.getElementById("total").value || "0");

  // Here you would build a contract call with Stacks.js `makeContractCall`.
  // This file is a scaffold so you can plug in your own wallet integration.
  console.log("Would call create-schedule with", {
    beneficiary,
    start,
    cliff,
    duration,
    total,
  });
}

async function onLoadSummary() {
  const id = BigInt(document.getElementById("summary-id").value || "0");
  console.log("Would call read-only list-schedule-summary for id", id);
}

document.getElementById("create-btn")?.addEventListener("click", onCreateSchedule);
document.getElementById("summary-btn")?.addEventListener("click", onLoadSummary);
