---
title: 'CRDT - Conflict Free Replicated Data Types'
description: 'A brief intro to Conflict Free Replicated Data Types'
date: 2025-02-24T09:58:08+07:00
draft: false
tags:
  - programming
  - dart
  - data
---

## Background
When searching techniques for syncing data between peers, I stumbled upon CRDT (Conflict-free Replicated Data Types). It's basically a algorithm for syncing for distributed systems. CRDT ensures all data changes between peer will be synced with correct order and no data loss.

Since I working with Dart (for Flutter project), I use a [CRDT library for Dart](https://github.com/cachapa/crdt). This library implements core concept of CRDT and it's pretty basic. Here some types of CRDT that often used:

1. **G-Counter (Grow-only Counter)**: A counter that can only be incremented.
2. **P-Counter (Decrement Counter)**: A counter that can be both incremented and decremented.
3. **G-Set (Grow-only Set)**: A set that only allows elements to be added.
4. **2P-Set (Two-Phase Set)**: A set that allows elements to be added and removed, maintaining two sets (one for additions and one for removals).
5. **OR-Set (Observed Remove Set)**: A set that allows elements to be added and removed, using unique identifiers to track additions and removals.
6. **LWW-Register (Last Write Wins Register)**: A register that stores the last written value, using a timestamp to determine the most recent update.
7. **MV-Register (Multi-Value Register)**: A register that stores all values that have been written, using unique identifiers to track writes.
## How it works -- basic version
Main components:
- HLC (Hardware Logical Clock). Combines _wall clock/local time_, a counter that increments, and an optional _node ID_ for uniqueness sake.
- The data itself (usually contains a key, value, and the HLC object).
### **Scenario: Two Devices Synchronizing Data**
We have two devices, **Device A** and **Device B**, which both maintain their own local datasets. Each device can modify data independently. When they synchronize, their CRDT implementations will merge their changes and resolve conflicts.
#### Initial State
- Both devices start with the same data:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice | false | HLC: A1 |
| 2 | Bob | false | HLC: A2 |

- Device A's last modified HLC: `A2`.
- Device B's last modified HLC: `A2`.

---
#### Changes Made on Each Device
1. **Device A deletes Bob's record (key 2):**

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 2 | null | true | HLC: A3 |

2. **Device B updates Alice's name to Alice Smith (key 1):**

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice Smith | false | HLC: B3 |

---
#### Synchronization and Merge
- Device A sends its **changeset** to Device B:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 2 | null | true | HLC: A3 |

- Device B sends its **changeset** to Device A:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice Smith | false | HLC: B3 |

---
#### Step-by-Step Conflict Resolution

The `merge` method processes these changes:
1. **Validate Changeset**:
    Each incoming record is validated to ensure it matches the expected schema and contains valid HLC timestamps.
    
2. **Compare Records for Key 1 (`Alice`)**:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice | false | HLC: A1 |

Incoming record from Device B:
| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice Smith | false | HLC: B3 |

**Conflict Resolution Rule**: The record with the higher `Last Modified` HLC wins. HLC `B3 > A1,` so Device A updates Alice's record to:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice Smith | false | HLC: B3 |

3. **Compare Records for Key 2 (`Bob`)**:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 2 | Bob | false | HLC: A2 |

Incoming record from Device A:
| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 2 | null | true | HLC: A3 |

**Conflict Resolution Rule**: The record with the higher `Last Modified` HLC wins. HLC `A3 > A2`, so Device B updates Bob's record to:

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 2 | null | true | HLC: A3 |

4. **Propagate Changes**:
   Both devices now have identical datasets after merging.

---
#### Final Merged Dataset on Both Devices

| Key | Value | isDeleted | Last Modified |
| --- | ----- | --------- | ------------- |
| 1 | Alice Smith | false | HLC: B3 |
| 2 | null | true | HLC: A3 |

---
#### Summary of Conflict Resolution Rules

1. **Higher HLC Wins**
   Records with higher HLCs (later timestamps) overwrite those with lower HLCs.
2. **Soft Deletes**
   A `null` value with `isDeleted: true` is treated as a soft delete. It wins if its HLC is higher.
3. **Deterministic Behavior**
   All nodes independently apply the same conflict resolution logic, ensuring eventual consistency.

