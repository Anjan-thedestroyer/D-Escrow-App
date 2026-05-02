# Milestone-Based Escrow System

> A trustless, gas-safe escrow protocol built in Solidity — enabling secure, milestone-driven service payments with on-chain dispute resolution and pull-based fund withdrawal.

---

## Table of Contents

- [Overview](#overview)
- [Why This Contract Exists](#why-this-contract-exists)
- [Architecture](#architecture)
- [Contract Features](#contract-features)
- [Deal Lifecycle](#deal-lifecycle)
- [Functions Reference](#functions-reference)
- [Events](#events)
- [Security Model](#security-model)
- [Getting Started](#getting-started)
- [Example Usage](#example-usage)
- [Design Decisions](#design-decisions)
- [License](#license)

---

## Overview

The **Milestone-Based Escrow System** is a smart contract deployed on any EVM-compatible blockchain that serves as a neutral, automated intermediary between a **payer** (client) and a **payee** (service provider). Instead of requiring full upfront payment — which exposes the client to risk — or asking the service provider to work on trust alone, this protocol divides every engagement into a series of **milestones**, releasing funds incrementally as each deliverable is verified and approved by the payer.

All logic is executed entirely on-chain. There is no backend server, no centralized database, and no trusted third party required for the core payment flow. The contract is self-executing and tamper-proof.

Built with OpenZeppelin's audited `Ownable` and `ReentrancyGuard` modules, and implementing the **Pull-over-Push** payment pattern, this contract is engineered to production-grade security standards.

---

## Why This Contract Exists

Traditional freelance and service agreements carry a fundamental problem: **trust asymmetry**. The client does not want to pay before receiving work; the service provider does not want to work without a guaranteed payment. In practice, this tension is resolved by:

- Relying on reputation platforms that can be gamed or shut down
- Using payment processors that charge fees and can reverse transactions arbitrarily
- Simply trusting the other party — which frequently goes wrong

This contract removes that dependency entirely. Once a deal is created and funded, the ETH is locked and neither party can access it outside the defined flow. The payer cannot disappear with the funds, and the payee cannot claim money they have not earned. If a conflict arises mid-engagement, either party can raise a formal dispute, freezing the deal until an arbitrator resolves it with a proportional settlement.

---

## Architecture

The contract is built around three core data structures and one payment ledger.

### `Deal`
The central record of an agreement. It stores the wallet addresses of both parties, the total locked ETH balance, the number of milestones, a progress counter tracking how many have been completed, and the deal's current status.

### `Milestone`
Each deal contains one or more milestones. A milestone holds a human-readable description, its designated ETH value in wei, and a boolean flag indicating whether it has been approved and credited.

### `Dispute`
When a conflict arises, either party can file a dispute on-chain. The record permanently captures who raised it, their stated reason, and the deal it pertains to — serving as an immutable audit trail.

### `pendingWithdrawals` — The Pull Ledger
Rather than sending ETH directly to recipients during state transitions, the contract maintains an internal balance ledger. When funds are released — through milestone approval, deal finalization, cancellation, or dispute resolution — the recipient's entry in `pendingWithdrawals` is credited. Recipients then call `withdraw()` at their own convenience to collect what they are owed. This is the **Pull-over-Push** pattern and is a cornerstone of the contract's security design.

### Status State Machine

Every deal moves through a strict, validated sequence of states:

```
AwaitingPayment
      │
      ▼
  InProgress ──────────────────► Completed
      │
      ├──── (dispute raised) ──► Disputed ──► Refunded
      │
      └──── (no work started) ─► Canceled
```

The contract enforces that every state transition is valid at each entry point, making out-of-order operations impossible.

---

## Contract Features

| Feature | Description |
|---|---|
| **Milestone Payments** | Deal value is partitioned across milestones at creation. Each is individually credited to the payee upon payer approval. |
| **Full Escrow** | 100% of the deal value is locked in the contract at creation time. Neither party has unilateral access. |
| **Pull Withdrawals** | All fund releases credit an internal ledger. Recipients withdraw on their own terms, preventing gas-griefing and forced-transfer vulnerabilities. |
| **Dispute Resolution** | Either party can freeze a deal and submit a written reason on-chain. The owner can apportion the remaining balance in any proportion to resolve the conflict. |
| **Safe Cancellation** | A deal can be canceled — but only if no milestones have been approved yet (`currentMilestone == 0`). The full balance is returned to the payer. |
| **Milestone Cap** | Deals are limited to a maximum of 20 milestones, preventing unbounded initialization loops that could hit the block gas limit. |
| **OpenZeppelin Modules** | Uses audited `Ownable` and `ReentrancyGuard` contracts, reducing attack surface versus hand-rolled implementations. |
| **Rich On-chain Queries** | Getter functions allow frontends and indexers to retrieve a user's complete deal history — including all milestone details — in a single RPC call. |

---

## Deal Lifecycle

### 1. Deal Creation
The payer calls `createDeal`, providing the payee's address, an array of milestone descriptions, and a corresponding array of ETH amounts in wei. The total ETH sent with the transaction must exactly match the sum of all milestone amounts. Funds are immediately locked, both parties are indexed, and the deal enters `InProgress`.

### 2. Milestone Completion
As the service provider completes each deliverable, the payer calls `completeMilestone` for the corresponding milestone ID. The milestone's ETH value is credited to the payee's `pendingWithdrawals` balance. Milestones can be approved in any order, and each can only be approved once.

### 3. Deal Completion
Once every milestone has been approved, the payer calls `completeDeal`. Any residual balance is credited to the payee and the deal status is set to `Completed`.

### 4. Withdrawal
Any party owed funds — whether a payee collecting earned payments or a payer receiving a refund — calls `withdraw()`. This transfers the caller's full accumulated `pendingWithdrawals` balance to their wallet in a single, reentrancy-safe operation.

### 5. Dispute (Optional Path)
If either party believes the agreement has been violated, they call `raisedDispute` with a written explanation. The deal is immediately frozen — no further milestone approvals or cancellations are possible. The contract owner reviews the situation and calls `resolveDispute`, specifying the exact amount each party should receive from the remaining locked balance. Both amounts are credited to their respective withdrawal ledgers.

### 6. Cancellation (Optional Path)
If no milestones have been approved yet, either party may call `cancelDeal`. The full locked balance is credited to the payer's withdrawal ledger and the deal is marked `Canceled`.

---

## Functions Reference

### `createDeal(address _payee, string[] _description, uint256[] _amount)`
**Payable · Called by payer · `nonReentrant`**

Creates a new escrow deal. The ETH sent must equal the sum of all milestone amounts exactly. Arrays must be equal in length and are capped at 20 entries. Both parties are registered in `userDeals` for off-chain lookup.

---

### `completeMilestone(uint256 _dealId, uint256 _milestoneId)`
**Called by payer · `nonReentrant`**

Approves a specific milestone. Validates that the deal is active, the milestone ID is valid, and the milestone has not already been approved. Credits the milestone's ETH to the payee's `pendingWithdrawals` entry.

---

### `completeDeal(uint256 _dealId)`
**Called by payer · `nonReentrant`**

Finalizes a deal once all milestones are approved. Credits any residual balance to the payee and sets the deal status to `Completed`. Reverts if any milestone remains incomplete.

---

### `withdraw()`
**Called by any creditor · `nonReentrant`**

Transfers the caller's full `pendingWithdrawals` balance to their address. Zeroes out the ledger entry before making the external call (CEI-compliant). Available to both payees collecting earned payments and payers receiving refunds.

---

### `raisedDispute(uint256 _dealId, string _reason)`
**Called by payer or payee**

Freezes the deal and logs the dispute reason permanently on-chain. Valid only if the deal is in `InProgress` or `AwaitingPayment` status.

---

### `resolveDispute(uint256 _dealId, uint256 _payerAmount, uint256 _payeeAmount)`
**Owner only · `nonReentrant`**

Distributes the remaining locked balance between both parties. The sum of both arguments must equal the deal's current balance exactly. Credits each party's withdrawal ledger and sets the deal status to `Refunded`.

---

### `cancelDeal(uint256 _dealId)`
**Called by payer or payee · `nonReentrant`**

Cancels an in-progress deal. Only permitted if `currentMilestone == 0`, meaning no work has been approved yet. Credits the full balance to the payer's withdrawal ledger and sets the deal status to `Canceled`.

---

### `getDeal(uint256 _dealId) → Deal`
Returns the core data record for a deal by its ID.

---

### `getMilestones(uint256 _dealId) → Milestone[]`
Returns the complete array of milestones for a given deal.

---

### `getFullDealsByUser(address _user) → DealWithMilestones[]`
Returns every deal associated with a given address, including all milestone details for each. Designed to minimize RPC calls for frontend consumers.

---

## Events

| Event | Description |
|---|---|
| `DealCreated(dealId, payee, payer, totalBalance)` | A new deal has been funded and created. |
| `MilestoneCompleted(dealId, milestoneId, amountReleased)` | A milestone has been approved and its value credited. |
| `DealCompleted(dealId, payee, payer, totalBalance)` | A deal has been fully finalized by the payer. |
| `DealCanceled(dealId, payer, refundedAmount)` | A deal was canceled before any work began. |
| `DisputeRaised(raisor, dealId, reason)` | A party has initiated a dispute and frozen the deal. |
| `DisputeResolved(dealId)` | The owner has resolved a dispute and apportioned remaining funds. |
| `FundsWithdrawn(user, amount)` | A user has successfully withdrawn their accumulated credits. |

All indexed parameters support efficient off-chain filtering for dashboards, notification services, and subgraph indexers.

---

## Security Model

> **Static Analysis**: This contract was analyzed with [Slither](https://github.com/crytic/slither). **Zero High, Medium, or Low severity issues were identified.** All findings are Informational. See [Known Limitations](#known-limitations) for a full breakdown.

### Pull-over-Push Payment Pattern
This is the most significant security property of the contract. In a naive push model, every payment-releasing function makes a direct ETH transfer to an external address. This introduces two critical vulnerabilities:

1. **Reentrancy** — A malicious recipient contract could re-enter the escrow during the transfer to manipulate state and drain additional funds.
2. **Gas Griefing / DoS** — A recipient contract could deliberately cause the transfer to revert (e.g., via a failing `receive()` function), permanently blocking a deal from completing.

The pull pattern eliminates both vectors. All state-transition functions — `completeMilestone`, `completeDeal`, `resolveDispute`, `cancelDeal` — never make external ETH calls. They only update numbers in the `pendingWithdrawals` mapping. The sole external call is isolated inside `withdraw()`, which operates on a zeroed-out balance before transferring, making reentrancy a non-issue.

```solidity
function withdraw() external nonReentrant {
    uint256 amount = pendingWithdrawals[msg.sender];
    require(amount > 0, "No funds to withdraw");

    // Effect: zero the ledger BEFORE the external call
    pendingWithdrawals[msg.sender] = 0;

    // Interaction: transfer happens last
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Withdrawal transfer failed");

    emit FundsWithdrawn(msg.sender, amount);
}
```

### OpenZeppelin `ReentrancyGuard`
All state-modifying functions are decorated with the `nonReentrant` modifier, which applies a mutex lock that reverts any re-entry mid-execution. This acts as a defense-in-depth layer on top of the pull pattern.

### OpenZeppelin `Ownable`
Administrative rights are managed through the well-audited `Ownable` module rather than a manually implemented variable and modifier. This reduces the risk of access control bugs and provides a standard `transferOwnership` interface compatible with multi-sig wallets and governance contracts.

### State Machine Enforcement
The `Status` enum and its validation at every function entry point ensures deals cannot be moved into invalid states. A `Completed` deal cannot be re-opened; a `Canceled` deal cannot have milestones approved.

### Amount Validation
At deal creation, `msg.value` is verified to equal the sum of all declared milestone amounts exactly. This guarantees every milestone has its capital reserved and prevents underfunded deals from entering an active state.

### Milestone Cap
The 20-milestone hard cap prevents a deal from being initialized with enough entries to push the setup loop past the block gas limit — a denial-of-service vector that is easy to overlook.

### Known Limitations

The following limitations were identified through a Slither static analysis audit. **No High, Medium, or Low severity issues were found.** All findings are informational in nature.

**Owner Trust**
Dispute resolution depends on a trusted contract owner. In a production deployment, this role should be assigned to a multi-sig wallet (e.g., Gnosis Safe) or a DAO governance contract to eliminate single-point-of-failure risk.

**No Deadline Mechanism**
The contract has no time-based auto-release or auto-cancel. If a payer becomes unresponsive, the payee's only recourse is to raise a dispute. A deadline-based fallback is a natural candidate for a future iteration.

**No Partial Cancellation**
Once a milestone is approved and credited, it cannot be reversed. Disputes are the intended escalation path for disagreements arising after work has begun.

**Low-Level ETH Transfer in `withdraw()`** *(Slither: `low-level-calls`, Informational)*
The `withdraw()` function uses a low-level `.call{value: amount}("")` to transfer ETH. This is the recommended approach in modern Solidity — `transfer()` and `send()` are deprecated due to their fixed 2300 gas stipend, which can fail for smart contract recipients. The low-level call, combined with the `nonReentrant` modifier and CEI ordering, is the correct and safe pattern here.

**Inline Assembly in OpenZeppelin Dependencies** *(Slither: `assembly`, Informational)*
Several functions within OpenZeppelin's `StorageSlot.sol` utility use inline assembly (`INLINE ASM`) for gas-efficient low-level storage access. These findings originate entirely from OpenZeppelin's own library code and are not present anywhere in the application contract. They are expected, intentional, and carry no risk to this contract.

**Compiler Version Pragma** *(Slither: `solc-version`, Informational)*
The `^0.8.20` pragma used by OpenZeppelin's dependency files is flagged as containing three known compiler bugs: `VerbatimInvalidDeduplication`, `FullInlinerNonExpressionSplitArgumentEvaluationOrder`, and `MissingSideEffectsOnSelectorAccess`. These bugs affect highly specific edge cases in the optimizer and inline assembly — none of which are exercised by this contract's logic. The risk is negligible in practice, but pinning to a specific patched compiler version (e.g., `0.8.24`) in a production deployment is advisable.

**Parameter Naming Convention** *(Slither: `naming-convention`, Informational)*
Several function parameters (e.g., `_dealId`, `_payee`, `_amount`) use an underscore-prefixed naming style, which Slither flags as not conforming strictly to Solidity's mixedCase convention. This is a widely used convention in Solidity development for distinguishing local parameters from storage variables, and does not affect security or correctness in any way.

---

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- Solidity `^0.8.13`
- OpenZeppelin Contracts v5

### Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

### Compile

```bash
forge build
```

### Run Tests

```bash
forge test -vvv
```

### Deploy to Local Testnet

```bash
anvil &
forge script script/Deploy.s.sol --broadcast --rpc-url http://localhost:8545
```

---

## Example Usage

### Standard Deal Flow

```solidity
// Alice creates a 1 ETH deal with Bob across two milestones
escrow.createDeal{value: 1 ether}(
    bobAddress,
    ["Design mockups", "Final delivery"],
    [0.4 ether, 0.6 ether]
);
// → 1 ETH is locked. Both parties are indexed.

// Bob delivers the first phase. Alice approves milestone 0.
escrow.completeMilestone(1, 0);
// → pendingWithdrawals[Bob] += 0.4 ETH

// Bob withdraws his first payment at any time.
escrow.withdraw(); // called by Bob
// → 0.4 ETH transferred to Bob's wallet

// Bob completes the final deliverable. Alice approves milestone 1.
escrow.completeMilestone(1, 1);
// → pendingWithdrawals[Bob] += 0.6 ETH

// Alice closes out the deal.
escrow.completeDeal(1);

// Bob collects his final payment.
escrow.withdraw(); // called by Bob
// → 0.6 ETH transferred to Bob's wallet
```

### Dispute Flow

```solidity
// Bob believes Alice changed the agreed scope. He raises a dispute.
escrow.raisedDispute(1, "Client changed requirements after work began.");
// → Deal is frozen. Status: Disputed.

// Owner reviews the situation and splits the remaining 0.6 ETH equally.
escrow.resolveDispute(1, 0.3 ether, 0.3 ether);
// → pendingWithdrawals[Alice] += 0.3 ETH
// → pendingWithdrawals[Bob]   += 0.3 ETH

// Both parties withdraw their share independently.
escrow.withdraw(); // called by Alice → 0.3 ETH
escrow.withdraw(); // called by Bob   → 0.3 ETH
```

---

## Design Decisions

**Why use OpenZeppelin modules instead of custom implementations?**
Hand-rolled access control and reentrancy guards introduce surface area for subtle bugs that are easy to miss and costly to exploit. OpenZeppelin's modules are formally audited, reviewed by thousands of developers, and battle-tested across production deployments at scale. Choosing them reflects an understanding of when to leverage established, proven infrastructure over reinventing it.

**Why cap milestones at 20?**
Initialization loops over unbounded arrays are a denial-of-service vector. A deal created with hundreds of milestones could push the `createDeal` setup loop past the block gas limit, bricking the transaction. The cap is a deliberate, principled guard against this edge case.

**Why is the cancellation guard `currentMilestone == 0` rather than balance-based?**
A balance-based check could theoretically be circumvented if a zero-value milestone existed. The `currentMilestone == 0` check is semantically precise — it means no work has been formally approved — which is the actual condition that makes a full refund equitable. Intent-based checks are more robust than arithmetic ones.

**Why does `resolveDispute` set status to `Refunded` rather than `Completed`?**
Semantics matter when reading on-chain history. `Completed` implies mutual fulfillment of obligations. `Refunded` accurately communicates that the deal ended due to a conflict and funds were distributed through arbitration — important context for any analytics layer, dashboard, or audit built on top of this contract.

**Why do both payer and payee use the same `withdraw()` function?**
Whether a user is a payee collecting earned payments or a payer receiving a refund, the mechanics are identical: check the ledger, zero it, transfer. A single, well-secured code path is always preferable to duplicating transfer logic across multiple functions.

---

## License

This project is released under the **UNLICENSED** identifier. All rights reserved by the author. Contact for usage permissions.

---

*Built with Solidity · Secured with Pull-over-Push · Powered by OpenZeppelin*