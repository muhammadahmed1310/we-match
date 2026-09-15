# WE Match

Internal networking for women in the WE Community. WE Match keeps groups and people,
runs biweekly cycles that ask each woman for a topic and her availability, pairs women
**within a group**, and introduces the pair. It does not schedule the meeting — the pair
agree the time themselves.

- Community Managers: start with the **[CM runbook](docs/CM_RUNBOOK.md)**.
- Where the project stands and what is next: **[project plan](docs/PROJECT_PLAN.md)**.
- Data model, stack, and matching algorithm: **[TECHNICAL_PLAN.md](TECHNICAL_PLAN.md)**.
- Hosting: **[DEPLOY.md](DEPLOY.md)**.

## What it does

| Requirement | How |
|-------------|-----|
| Groups and people, with people in more than one group | `Group`, `Member`, `GroupMembership`, plus a cohort label per membership |
| Matching only within a group | Each `MatchCycle` belongs to one `Group`; responses are validated against membership |
| Biweekly invitations | `OpenBiweeklyCyclesJob` opens a cycle every second Monday for groups flagged `auto_cycle`; also available as a button |
| Each woman asked for a topic and availability | Private per-person link (`CycleInvitation#token`) to a form asking for one topic and one or two one-hour windows |
| Only she can answer for herself | The link identifies her; there is no name dropdown and no `member_id` in any URL |
| Local time zones | Windows are shown in her own zone, stored and matched in UTC (`ResponseSlot`, `MeetingWindows`) |
| Matching on topic and time | `MatchingService`: same group, same `topic_id`, an identical UTC window, avoiding recent repeat pairings where it can |
| Introduction to the pair | `MatchMailer#introduction`, one per match |
| Post-match feedback | Two weeks after meeting-week Monday, matched people get a private link asking if they met, value for time, and which subtopic resonated |
| No meeting scheduling | Introductions only, no calendar links |

## Setup

Ruby 3.2.2 (see `.ruby-version`) and PostgreSQL.

```bash
bundle install
bin/rails db:setup   # creates, migrates, and seeds demo data
bin/rails server
```

Open <http://localhost:3000> and sign in with the development admin the seeds print:
`cm@womenemerging.org` / `change-me-please`.

Create your own admin at any time:

```bash
ADMIN_EMAIL=you@womenemerging.org ADMIN_PASSWORD=at-least-12-chars bin/rails admin:create
bin/rails admin:list
```

Background jobs run inline in development. To exercise the real queue:

```bash
JOB_ADAPTER=solid_queue bin/rails server
bin/jobs   # in a second terminal
```

## Walking the whole flow locally

The seeds leave an open WE Fellows cycle with responses already in, so you can see a
match on the first try.

1. **Match Cycles → WE Fellows** → **Send invitations**. Every woman in the group gets a
   private link; `log/development.log` shows the mail.
2. **Invitation links** → **Download CSV** — this is what a CM hands out while in-app
   email is off.
3. Open one of those links in a private window. This is the participant view: time zone,
   one topic with its private option, one or two one-hour windows. Submit, then reopen the
   same link and change the answer.
4. Back on the cycle: **Close responses**, then **Run matching**.
5. **View matches** — the seeded data gives two pairs and one woman unmatched, because she
   is the only one on her topic.
6. **Reports → the cycle** — response rate, pairs, unmatched, and the topic and option
   counts. **Download CSV** for the same thing as a spreadsheet.
7. `/rails/mailers` — invitation, reminder, and introduction previews. Check that the
   introduction shows the topic and the shared window but **never** the private option.

Worth trying deliberately: an invented token (`/respond/nonsense`), a link after the
cycle is closed, matching a cycle with no responses, and two women with the same topic but
no shared window.

## Email

Delivery goes through `MailDelivery`, which records every intended message as an
`EmailDelivery` row and then queues the send. It only really sends when
`EMAIL_DELIVERY_ENABLED` is set — off in production by default, on everywhere else. With
it off, nothing is lost: the dashboard lists what would have gone out, and CMs send the
exported links by hand.

This is deliberate. Sending from `womenemerging.org` needs SPF, DKIM, and DMARC records
that WE IT has to add; see the [project plan](docs/PROJECT_PLAN.md) for the date that is
needed by.

## Tests

```bash
bin/rails test          # models, services, requests, mailers, jobs
bin/rails test:system   # browser tests of sign-in and the participant flow (needs Chrome)
```

Both run in CI, along with RuboCop, Brakeman, and an importmap audit.

## JSON API

Every endpoint needs a token in `Authorization: Bearer <token>` or `X-Api-Token`, from
`WE_MATCH_API_TOKEN` or the `api_token` credential. Without it, everything returns 401.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/groups` | Groups with their people |
| GET | `/api/v1/members` | People with their groups |
| GET | `/api/v1/topics` | Active topics and their options |
| GET | `/api/v1/match_cycles/:id` | Cycle with responses and matches |
| POST | `/api/v1/match_cycles/:id/match_responses` | Submit a response |
| PATCH | `/api/v1/match_cycles/:id/match_responses/:id` | Update a response |
| POST | `/api/v1/match_cycles/:id/run_matching` | Run matching, with the same guards as the admin screen |
| GET | `/api/v1/match_cycles/:id/matches` | Matches for a cycle |

## Screens

| Screen | URL |
|--------|-----|
| Sign in | `/sign_in` |
| Dashboard | `/` |
| Groups | `/groups` |
| Users | `/members` |
| Topics and their options | `/topics` |
| Excel import | `/import/new` |
| Match cycles | `/match_cycles` |
| Invitation links for a cycle | `/match_cycles/:id/invitations` |
| Matches for a cycle | `/match_cycles/:id/matches` |
| Reports | `/reports` |
| Participant response | `/respond/:token` — the only screen that does not need an admin session |

## Layout

```
app/models/       Group, Member, GroupMembership, Topic, TopicOption, MatchCycle,
                  CycleInvitation, MatchResponse, ResponseSlot, Match, EmailDelivery,
                  AdminUser
app/services/     MatchingService, MeetingWindows, CycleInvitationService, PeopleImport,
                  MailDelivery, CycleReport, ProgrammeReport, InvitationLinkExport
app/jobs/         OpenBiweeklyCyclesJob, SendResponseRemindersJob, CloseDueCyclesJob,
                  RunDueMatchingJob, SendTrackedEmailJob
app/mailers/      MatchCycleMailer (invitation, reminder), MatchMailer (introduction)
config/recurring.yml   The biweekly rhythm
docs/             CM runbook, project plan, draft reply to Mia
```
