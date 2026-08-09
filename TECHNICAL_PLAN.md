# WE Match — Technical Plan

This describes the system as built at the end of Phase 1. The original version of this
document was the written exercise answer, written before the code; where the two differ,
the code and this page are right.

## 3.1 Data model

WE Match centres on **groups**, **people**, and **match cycles** — one biweekly round per
group.

| Entity | Purpose |
|--------|---------|
| **AdminUser** | A WE team member who can sign in. Created from a rake task; no public sign-up |
| **Member** | A woman in the WE Community: name, email, IANA time zone |
| **Group** | A community such as WE Fellows or Higher Ed Explorers. Carries the auto-cycling flag |
| **GroupMembership** | Many-to-many between people and groups, with a cohort label |
| **Topic** | A conversation topic. Global, or scoped to one group. Ordered, and deactivated rather than deleted |
| **TopicOption** | The private dropdown under a topic. Collected for aggregate insight only |
| **MatchCycle** | One matching round for one group: status, response window, and the week the meetings are for |
| **CycleInvitation** | One person's private link into a cycle: unique token, sent and responded timestamps, send count |
| **MatchResponse** | Her answer for a cycle: one topic, an optional option, and free-text if the option was "other" |
| **ResponseSlot** | One offered hour, stored in UTC. One or two per response |
| **Match** | A paired introduction: two responses, their shared topic, and the hour they share |
| **EmailDelivery** | A record of every email the app intended to send, whether or not sending is switched on |

**Relationships**

- People ↔ groups through `GroupMembership`.
- Each `MatchCycle` belongs to one `Group`; all matching is scoped to that cycle.
- One `CycleInvitation` per person per cycle, and one `MatchResponse` per person per cycle.
- `MatchResponse` has one or two `ResponseSlot`s; `Match` references both responses and the
  slot they have in common.
- `EmailDelivery` optionally references the person, cycle, and match it concerns.

**Decisions worth naming**

- **Invitations are rows, not signed URLs.** A signed URL would have been less code, but a
  persisted token also gives link export for manual sending, resend, and per-person
  response tracking — all of which the pilot needs.
- **Topics are records, not strings.** The first version compared free text through an alias
  list, which quietly mismatched. Matching now compares `topic_id`. `TopicCompatibility`
  survives only to backfill the old rows in a migration.
- **Availability is a set of fixed hours, not an interval.** Two people offering
  09:00–17:00 technically overlap for eight hours, which is not a meeting. They now either
  offer the same hour or they do not.
- **Time zones are stored on the person, and slots in UTC.** Labels are rendered in her
  zone; nothing about matching depends on where anyone lives.

## 3.2 Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Backend | **Ruby on Rails 7.2** | Fast CRUD, validations, mailers, conventions |
| Database | **PostgreSQL** | Relational integrity across memberships, cycles, and slots |
| Frontend | **Hotwire and ERB** | No Node build step; two small Stimulus controllers for time zone detection and the topic option dropdown |
| Auth | **`has_secure_password` and a session** | Admin screens are private by default; the participant flow opts out and is authenticated by its token instead |
| API | **`/api/v1` with a shared token** | Programmatic access alongside the HTML UI, same guards |
| Email | **Action Mailer through `MailDelivery`** | One gate that records every send and honours the delivery flag |
| Jobs | **Solid Queue** | Runs in the same Postgres, so the pilot needs one database and one worker process |
| Matching | **PORO service** | Easy to test and change without framework lock-in |

## 3.3 Matching logic

**Rules**

1. Only responses in the **same cycle**, therefore the same group, are considered.
2. Each person is matched **at most once** per cycle.
3. Topics must be the **same record** — `topic_id` equality, not similar wording.
4. The two must offer an **identical UTC hour**.
5. Pairs matched in the group's last six cycles are avoided where possible.
6. Anything unpaired stays unmatched, with `match_id` nil.
7. Matches are persisted, and the cycle becomes `matched`. It cannot be re-run.

**Algorithm**

Two greedy passes. The first refuses recent repeat pairs; the second runs over whatever is
left with that restriction lifted, because a repeat introduction is better than leaving
someone with nobody. Each pass sorts by fewest eligible partners first, so the hardest
people to place are dealt with while options remain. The result reports how many pairs were
repeats, so a group that keeps producing them is visible.

Deterministic and easy to explain to a CM, at the cost of not being globally optimal. For
20–50 people per group the difference is a pair or two; if that matters later, this is the
one function to replace.

**Edge cases**

| Case | Handling |
|------|----------|
| Odd number of respondents | One person unmatched |
| No shared topic, or no shared hour | Unmatched |
| Only eligible partner is a recent repeat | Matched on the second pass, and counted as a repeat |
| Re-running matching | Blocked once the cycle is `matched`, on both the HTML and JSON paths |
| Cross-group | Impossible: cycle scope plus a membership validation on the response |
| A response from someone no longer in the group | Kept, and still listed in the report |

**Afterwards**

`MatchMailer#introduction` goes to both women with both names and emails, the shared topic,
and the shared hour rendered in each recipient's own zone. The private option is never
included. Delivery goes through `MailDelivery` like everything else.

## 3.4 Automation

`config/recurring.yml` drives four jobs, all of which are idempotent and safe to run when
nothing is due:

| Job | When | What it does |
|-----|------|--------------|
| `OpenBiweeklyCyclesJob` | Monday | For each auto-cycling group due a round, creates the cycle and sends invitations |
| `SendResponseRemindersJob` | Wednesday | Reminds people in open cycles who have not answered |
| `CloseDueCyclesJob` | Thursday | Closes cycles past their response deadline |
| `RunDueMatchingJob` | Friday | Matches closed, auto-created cycles that have responses |

The Monday job runs weekly but only acts on groups that are actually due, so the fortnightly
rhythm does not depend on the schedule being restarted at the right time.

## 3.5 Email and the delivery flag

`MailDelivery.deliver` writes an `EmailDelivery` row for every intended message and then
queues the real send — but only when `EMAIL_DELIVERY_ENABLED` is set. In production it is
unset by default.

That is not caution for its own sake: sending from `womenemerging.org` needs SPF, DKIM, and
DMARC records that WE IT has to add. Until they exist, sending would land in spam. With the
flag off, the pilot still runs: the intent is recorded, the dashboard shows what would have
gone out, and CMs hand out the invitation links exported from the cycle page. Switching on
is one environment variable and no code.

## 3.6 Testing

`bin/rails test` covers model validations, the matching service across time zones and
repeat pairs, meeting window generation, CSV import, the report figures, admin access
control on every route, the API token, and mailer content — including a test that asserts
the private option never reaches an introduction email. `bin/rails test:system` drives
Chrome through admin sign-in and a real participant response.

## 3.7 Known limits and follow-ups

- **Ruby 3.2 and Rails 7.2 are both out of support.** The upgrade needs to land before the
  app goes on a public URL; it is the first item in the hosting phase of the
  [project plan](docs/PROJECT_PLAN.md).
- **Greedy matching** is not optimal, as above.
- **No bounce handling.** The provider's webhook is Phase 2 work; failures are currently
  visible as failed `EmailDelivery` rows only.
- **Repeat-pair avoidance looks back six cycles and then gives up.** A small group running
  many rounds will start seeing repeat introductions; the count is reported, but nothing
  acts on it yet. Worth revisiting once the pilot shows real group sizes.
- **Nothing records *why* someone was unmatched.** The topic and window distributions in the
  report make it inferable, not explicit. A per-person reason would be a genuine
  improvement for CMs.
- **Reporting is read-only aggregation over the live tables.** Fine at pilot scale; at
  2,500–3,000 people it will want summarising.
