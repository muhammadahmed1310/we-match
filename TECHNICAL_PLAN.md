# WE Match — Technical Plan

## 3.1 Data model

WE Match centers on **groups**, **members**, and **match cycles** (one biweekly round per group).

| Entity | Purpose |
|--------|---------|
| **Member** | A woman in the network (name, email). |
| **Group** | An expedition or fellows community. |
| **GroupMembership** | Many-to-many: a member can belong to multiple groups. |
| **MatchCycle** | A single matching round for one group (status, open/close dates). |
| **MatchResponse** | A member’s topic + availability window for a cycle. |
| **Match** | A paired introduction (two members in the same cycle). |

**Relationships**

- Members ↔ Groups via `GroupMembership`.
- Each `MatchCycle` belongs to one `Group`; all matching is scoped to that cycle’s group.
- Each member submits at most one `MatchResponse` per cycle.
- `Match` links two members; matched responses reference the `Match` via `match_id`.

**Assumptions**

- No user accounts in MVP; responses use a member picker (trusted internal tool).
- Availability stored as UTC datetimes.
- Topics are free-text strings with normalized/alias compatibility (see matching).

---

## 3.2 Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Backend | **Ruby on Rails 7.2** | Fast CRUD, validations, mailers, conventions. |
| Database | **PostgreSQL** | Relational integrity, good fit for memberships and cycles. |
| Frontend | **Hotwire (Turbo) + ERB** | No Node build step; SPA-like navigation with shared layout. |
| API | **JSON namespace** (`/api/v1`) | Optional programmatic access alongside HTML UI. |
| Email | **Action Mailer** | Invitation + introduction templates; previews at `/rails/mailers`. |
| Matching | **PORO service** (`MatchingService`) | Easy to test and evolve without framework lock-in. |
| Jobs (later) | Solid Queue + cron | MVP uses UI button + `rake match:send_invitations` instead. |

---

## 3.3 Matching logic

**Rules (MVP)**

1. Only responses in the **same `MatchCycle`** (hence same group) are considered.
2. A member is matched **at most once** per cycle.
3. **Topics** must be compatible: exact normalized match or alias group (e.g. “Leadership” / “Leading Teams”).
4. **Availability** intervals must overlap: `start_a < end_b && start_b < end_a`.
5. If no partner is found, the response stays **unmatched** (`match_id` nil).
6. Matches are **persisted** in `matches`; cycle status becomes `matched`.

**Algorithm**

Greedy pairing: sort unmatched responses by fewest compatible partners first, then pair each with the first eligible partner. This is simple and deterministic but not globally optimal (acceptable for MVP).

**Edge cases**

| Case | Handling |
|------|----------|
| Odd number of respondents | One (or more) unmatched |
| No topic/availability overlap | Unmatched |
| Re-run matching | Blocked once cycle is `matched` |
| Cross-group | Prevented by cycle scope + membership validation |

**Post-match**

`MatchMailer.introduction` emails both members (logged/stubbed in development).

---

## 3.4 How I'd build it

**Order of work**

1. Schema + models + seeds — prove data shape with realistic group/member data.
2. `MatchingService` + tests — core product value.
3. Mailers + rake task — invitation/intro flow.
4. HTML UI + API — operators can run a cycle end-to-end.
5. Documentation — setup, assumptions, limitations.

**Deprioritized for v1**

- Authentication and per-member magic links
- Automated biweekly scheduling (cron/ActiveJob)
- Calendar integrations and meeting links
- Optimal matching (max-cardinality / weighted graph)
- Admin analytics dashboard

**Risks / open questions**

- **Topic taxonomy**: MVP uses aliases; production may need a curated topic list.
- **Time zones**: Stored in UTC; members may expect local-time UI.
- **Email deliverability**: Production needs SPF/DKIM and a real provider (SendGrid, etc.).
- **Fairness**: Greedy matching may leave “hard to match” members unmatched; monitor in production.

---

## MVP assumptions (implemented)

- No login; member selected from dropdown when submitting a response.
- Biweekly invitations triggered manually (UI or rake), not scheduled.
- Emails use `:test` delivery in development with logging; previews at `/rails/mailers`.
- Re-running matching on a completed cycle is disabled.
