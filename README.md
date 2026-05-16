# WE Match

Internal networking for women in leadership expedition communities: maintain groups and members, collect availability and topics via biweekly invitations, match pairs **within a group**, and send introduction emails (no meeting scheduling).

## Understand the flow

**Do you create match cycles yourself?** → **Yes.** See **[Guide](/guide)** in the app (or [FLOW.md](FLOW.md) in the repo) for the full step-by-step and reviewer demo.

## Product alignment

| Product requirement | Implemented? | How in this MVP |
|---------------------|--------------|-----------------|
| Database of **groups** and **members** | Yes | `Group`, `Member`, `GroupMembership` — members can belong to multiple groups |
| Matching **only within a group** | Yes | Each `MatchCycle` belongs to one `Group`; responses validated against group membership |
| **Biweekly email** to all members | Partial | `MatchCycleMailer#invitation` sent via **Send Invitations** button or `rake match:send_invitations` — not auto-scheduled every 2 weeks |
| Email asks for **time window** + **topic** | Yes | Invitation copy + response form fields |
| Member **responds** with availability & interest | Yes | `MatchResponse` form (linked from email with `member_id`) |
| **Matching** when same group, compatible topic & overlapping time | Yes | `MatchingService` + `TopicCompatibility` |
| **Introduction email** to matched pairs | Yes | `MatchMailer#introduction` on each match |
| Platform does **not** schedule meetings | Yes | Intro emails only; no calendar links |

### Intentional MVP shortcuts

- **No login** — admin picks member from a dropdown (simulates “this member is responding”).
- **Biweekly send is manual** — use UI or rake; production would use cron + Solid Queue.
- **No cross-group matching** — enforced by data model, not configurable.

---

## Setup (local)

```bash
cd we-match
bundle install
bin/rails db:setup
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000).

## Deploy live (share with reviewers)

**Recommended: [Render](https://render.com)** — **$0**, sleeps when idle (fine for demos). One-click via [`render.yaml`](render.yaml).

1. Push repo to GitHub  
2. [Render](https://dashboard.render.com) → **New +** → **Blueprint** → connect repo  
3. Set `RAILS_MASTER_KEY` from `config/master.key`  
4. Share the `*.onrender.com` URL  

Full steps: **[DEPLOY.md](DEPLOY.md)**. Optional alternatives: Fly.io, Koyeb (see DEPLOY).

---

## End-to-end test (full product flow)

Use this once after `db:setup` to walk through all three product functions.

### Function 1 — Groups & members

| Step | Action | Expected result |
|------|--------|-----------------|
| 1.1 | Visit **Groups** | See *Expedition Alumni* and *Fellows Circle* |
| 1.2 | Open **Expedition Alumni** | 6 members listed |
| 1.3 | Visit **Members** → open **Grace Kim** | Member appears in **both** groups (multi-group membership) |
| 1.4 | Confirm **Fellows Circle** has a separate member list | Matching later stays inside each group’s cycle |

### Function 2 — Invitation & response

| Step | Action | Expected result |
|------|--------|-----------------|
| 2.1 | **Match Cycles** → open **Expedition Alumni** cycle (status `open`) | 5 seeded responses visible |
| 2.2 | Click **Send Invitations** (or run `bin/rails "match:send_invitations[ID]"`) | Flash: N emails sent; check `log/development.log` for `[WE Match Mail]` lines |
| 2.3 | Preview email at [/rails/mailers](http://localhost:3000/rails/mailers) → **Match Cycle Mailer → invitation** | Mentions time window + topic; link includes member |
| 2.4 | **Submit response** — choose **Elena Rossi**, topic `Mentorship`, overlapping times with existing Mentorship response if any | Response saved or validation shown |
| 2.5 | Try submitting again as **Elena** | Redirected to **edit** existing response |

**Fresh cycle test (optional):**

1. **New Match Cycle** → group *Fellows Circle* → status `open` → Create  
2. **Send Invitations** → **Submit response** for 2+ members with same topic and overlapping UTC windows  

### Function 3 — Match & introduce

| Step | Action | Expected result |
|------|--------|-----------------|
| 3.1 | On **Expedition Alumni** cycle, click **Run Matching** | Redirect to matches page |
| 3.2 | View **Matches** | **2 pairs** expected from seeds: Leadership (Ava + Brianna), Career Transitions (Claire + Diana); **Elena** (Mentorship) unmatched alone |
| 3.3 | Check log for introduction emails | Two `[WE Match Mail]` entries with both recipients per match |
| 3.4 | Preview at **Match Mailer → introduction** | Shows both names, topics, availability; states no scheduling |
| 3.5 | Try **Run Matching** again | Blocked — cycle already `matched` |

### Negative / edge-case tests

| Scenario | How to test | Expected |
|----------|-------------|----------|
| Cross-group match impossible | Create responses only in Fellows cycle; run matching | Only Fellows members paired |
| No overlap on time | Two members, same topic, non-overlapping windows | Both stay unmatched |
| Different topics | Same window, topics `Leadership` vs `Mentorship` | No match |
| Alias topics | `Leadership` + `Leading Teams`, overlapping times | Match created |
| Run matching with zero responses | New empty cycle → Run Matching | Alert: no responses yet |
| Member not in group | (API) POST response with outsider `member_id` | Validation error |

---

## Seeded demo data

| Item | Detail |
|------|--------|
| Groups | Expedition Alumni (6 members), Fellows Circle (5 members, overlap with Alumni) |
| Open cycle | Expedition Alumni — 5 responses pre-loaded |
| Expected matches after **Run Matching** | 2 pairs, 1 unmatched (Mentorship only has one person) |

Reset data: `bin/rails db:seed`

---

## UI map (where each feature lives)

| Screen | URL | Product function |
|--------|-----|------------------|
| Dashboard | `/` | Overview + **How WE Match works** workflow |
| Groups | `/groups` | Function 1 |
| Members | `/members` | Function 1 |
| Match cycles | `/match_cycles` | Cycles per group |
| Cycle detail | `/match_cycles/:id` | Send invitations, submit responses, run matching |
| Submit response | `/match_cycles/:id/match_responses/new` | Function 2 |
| Matches | `/match_cycles/:id/matches` | Function 3 results |
| Mailer previews | `/rails/mailers` | Dev email preview |

---

## Email (development)

- Delivery: `:test` adapter + log interceptor  
- Previews: [http://localhost:3000/rails/mailers](http://localhost:3000/rails/mailers)  
- Rake: `bin/rails "match:send_invitations[CYCLE_ID]"`

---

## Automated tests

```bash
bin/rails test test/services/
```

Covers topic compatibility, matching pairs, unmatched leftovers, and blocked re-run.

---

## API (JSON)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/groups` | List groups + members |
| GET | `/api/v1/members` | List members + groups |
| GET | `/api/v1/match_cycles/:id` | Cycle detail |
| POST | `/api/v1/match_cycles/:id/match_responses` | Submit response |
| POST | `/api/v1/match_cycles/:id/run_matching` | Run matching |
| GET | `/api/v1/match_cycles/:match_cycle_id/matches` | List matches |

---

## Technical plan

See [TECHNICAL_PLAN.md](TECHNICAL_PLAN.md) for the written exercise (data model, stack, matching algorithm, build order).

## Project structure

```
app/models/       Member, Group, GroupMembership, MatchCycle, MatchResponse, Match
app/services/     MatchingService, TopicCompatibility
app/mailers/      MatchCycleMailer (invitation), MatchMailer (introduction)
db/seeds.rb       Demo groups, members, open cycle with sample responses
```
