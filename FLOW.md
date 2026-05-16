# WE Match — Complete app flow

This explains **who does what**, in what order, and how it maps to the product document.

---

## Short answer: do you create match cycles yourself?

**Yes, in this MVP.** An admin (you) creates each **match cycle** manually — one cycle = one matching round for **one group**.

In a full production system, a **scheduled job** would create a new cycle every two weeks automatically. This demo uses buttons instead of a cron job so reviewers can run the flow on demand.

| Product document says | This MVP does |
|----------------------|---------------|
| “Send a **biweekly** email to all members” | You click **Send Invitations** when ready (simulates the biweekly send) |
| Matching within a group | Each cycle is tied to **one group** — never mixed |
| Member submits time + topic | **Submit response** form (or link from email) |
| Introduce matched pairs | **Run matching** → introduction emails logged |

---

## Roles

| Role | Who | What they do |
|------|-----|----------------|
| **Admin / operator** | You (or any reviewer with the URL) | Manage groups, create cycles, send invitations, run matching |
| **Member** | Woman in the network | Receives email, submits availability + topic |

There is **no login** in the MVP. On the response form, the member picks her name from a dropdown (trusted internal tool).

---

## The three product functions → app steps

### Function 1 — Maintain groups and members

**Document:** Women belong to one or more groups. Matching is only inside a group.

**In the app:**

1. Data lives in **Groups** and **Members** (seeded on setup, or you add via console/seeds).
2. **Group membership** links members to groups (e.g. Grace is in two groups).
3. You **view** this under **Groups** and **Members** — no matching happens here.

**Reviewer check:** Members → Grace Kim → see two groups. Matching later will not pair her with someone from the other group in the same cycle.

---

### Function 2 — Biweekly email + member response

**Document:** Email asks for preferred time window and topic. She responds.

**In the app (admin steps):**

| Step | Screen | Action |
|------|--------|--------|
| 2a | **New Match Cycle** | Choose **one group**, set status **Open** (or Draft then open later), optional open/close dates → **Create** |
| 2b | Match cycle page | Click **Send Invitations** → every member **in that group** gets an invitation email |
| 2c | Email (preview at `/rails/mailers`) | Link goes to **Submit response** with that member pre-selected |

**Member steps:**

| Step | Screen | Action |
|------|--------|--------|
| 2d | Submit response | Pick name, enter **topic**, **availability start/end** (UTC) → save |
| 2e | Same cycle | One response per member per cycle; submitting again → **edit** existing |

**Reviewer check:** After 2b, check logs or mailer preview. After 2d, response appears on the cycle page table.

---

### Function 3 — Matching + introduction (no scheduling)

**Document:** Pair women in the same group with compatible time and topic; send intro email; do **not** schedule the meeting.

**In the app:**

| Step | Screen | Action |
|------|--------|--------|
| 3a | Match cycle page | Click **Run Matching** (needs at least one response) |
| 3b | System | `MatchingService` pairs by: same cycle (same group), compatible topic, overlapping times, each member once per cycle |
| 3c | Matches page | See pairs; unmatched members stay unmatched |
| 3d | Email | Introduction email to both (logged in dev; not real SMTP in demo) |

**Reviewer check:** Seeded **Expedition Alumni** cycle → Run Matching → **2 pairs**, **1 unmatched** (Elena / Mentorship alone).

---

## End-to-end timeline (one group, one round)

```
YOU (admin)                          MEMBERS (group)
     |                                      |
     |-- 1. Create Match Cycle ------------>|
     |      (pick group, status Open)       |
     |                                      |
     |-- 2. Send Invitations -------------->| receive email
     |                                      |
     |                                      |-- 3. Submit response
     |                                      |    (topic + time window)
     |                                      |
     |-- 4. Run Matching ------------------>| (automatic)
     |                                      |
     |-- 5. Introduction emails ---------->| matched pairs notified
     |                                      |
     |-- 6. View Matches ------------------>| they arrange meeting offline
```

---

## Match cycle statuses

| Status | Meaning |
|--------|---------|
| **draft** | Created but invitations not sent yet |
| **open** | Invitations sent (or ready); accepting responses |
| **closed** | Optional: stop new responses (MVP still allows matching if open or closed) |
| **matched** | Matching has run; no more changes or re-run |

---

## Demo path (fastest for reviewers — ~5 minutes)

Seeds already created an **open** cycle with 5 responses for **Expedition Alumni**.

1. Open **Dashboard** → read the 3 steps.
2. **Match Cycles** → open **Expedition Alumni** cycle.
3. (Optional) **Send Invitations** — see flash / logs.
4. (Optional) **Submit response** as another member.
5. Click **Run Matching**.
6. **View matches** — expect 2 pairs + 1 unmatched.
7. **Mailer previews** → `/rails/mailers` → see invitation + introduction.

To test **from scratch** (including creating a cycle yourself):

1. **New Match Cycle** → Fellows Circle → status **Open** → Create.
2. **Send Invitations**.
3. **Submit response** for 2+ members (same topic, overlapping UTC times).
4. **Run Matching** → **View matches**.

---

## Document requirements checklist

| Requirement | Met? | How |
|-------------|------|-----|
| Database of groups and members | Yes | Groups, Members, GroupMembership |
| Women in multiple groups | Yes | e.g. Grace in two groups |
| Matching only within a group | Yes | MatchCycle belongs to one Group |
| Biweekly email to all members | Partial | Manual **Send Invitations** (no auto every 2 weeks) |
| Email asks time window + topic | Yes | Invitation copy + form fields |
| Member responds | Yes | MatchResponse |
| Match on compatible time + topic | Yes | MatchingService |
| Introduction email to pairs | Yes | MatchMailer |
| Does not schedule meeting | Yes | Intro only, no calendar |

---

## FAQ

**Why create a match cycle if seeds already have one?**  
Seeds give you a ready demo. Creating a new cycle is how you start a **new round** for any group (like the next biweekly round).

**Can I run matching without sending invitations?**  
Yes. If members already submitted responses (or you submit as them), **Run Matching** still works.

**Can the same member be in two matches in one cycle?**  
No. At most one match per member per cycle.

**Can Ava in Group A match with Zoe in Group B?**  
No. Different groups use different cycles.

**What if nobody has the same topic or time?**  
They stay **unmatched** for that cycle.
