# WE Match — Project Plan

Revised 9 August 2026. This replaces the version dated for a 31 July finish, which is
now out of date in two ways: the build went further than that plan assumed, and the
July dates have passed.

Capacity assumption throughout: **60% of a working week** on WE Match, per Mia — about
three days a week. Every date below is set on that basis, so a week of WE Match work is
a fortnight of calendar time.

## Where things stand

Phase 1 is **built and tested**. The app has admin sign-in, groups, people, topics with
private options, biweekly cycles, private per-person response links, one-hour windows in
local time zones, matching, introductions, reporting, and CSV import. The automated test
suite covers all of it and passes.

Two things went further than the previous plan promised, both because they were cheap
once the rest existed:

- **Biweekly automation** is built (open Monday, remind Wednesday, close Thursday, match
  Friday), switchable per group. It needs a worker process to be running, which is a
  hosting decision, not more code.
- **In-app email** is built and sits behind a switch that is **off**. Nothing is sent
  until WE IT adds the DNS records. With it off, every intended email is still recorded
  and CMs hand out exported links, exactly as the previous plan assumed.

Not done: it is not on a real URL, WE has not reviewed the copy, and no real participant
data is loaded. Those are the next three phases.

Target: hosted in August, pilot data loaded in September, at least one real cycle with
Higher Ed Explorers and Wavemakers in October, Phase 2 plan signed off in November.

## How this rolls out

**Phase 1 — admin-managed matching.** The WE team manages groups, topics, and people in
the admin dashboard. Cycles can run on the biweekly schedule or by hand. Invitations and
introductions go out through existing WE channels (Outlook or Mailchimp) using the links
the app generates; the app does not send them. WE Match makes the introduction only —
the pair agree their own meeting time.

**Phase 2 — fully automated end to end.** Switch on in-app email, scale to the full
community. Separate written plan after the pilot, with team sign-off.

Pilot groups: Higher Ed Explorers and Wavemakers, October 2026.

---

## Phase 1 — Build, test, complete

**Status: complete, 9 August 2026.** What is actually in place:

| Area | In place | Still to do | By when |
|------|----------|-------------|---------|
| Admin sign-in | Password sign-in, every admin screen private, JSON API behind a token | — | Done |
| Groups | Create, edit, delete, auto-cycle toggle | — | Done |
| People | Create, edit, delete, multiple groups, cohort labels, time zones | — | Done |
| Topics | Create, edit, delete, active/inactive, private option dropdowns | — | Done |
| CSV import | Preview-then-commit importer, updates people by email | Run once against a real WE file | With pilot data, Sep |
| Match cycles | Draft → open → closed → matched, response deadline, meeting week | — | Done |
| Invitations | One private link per person, resend, CSV export for manual sending | — | Done |
| Participant response | Token-linked form: one topic, optional private option, one or two one-hour windows, local time zone | — | Done |
| Edge cases | Unknown link, closed cycle, already matched | — | Done |
| Matching | Same group, same topic, identical window in UTC, avoids recent repeat pairs | — | Done |
| Matches and reporting | Pairs and unmatched per cycle, response rates, topic and option counts, CSV export | — | Done |
| Biweekly automation | Open Monday, remind Wednesday, close Thursday, match Friday, per group | Needs a worker process in hosting | Phase 2 below |
| In-app email | Built, switched off, every send recorded | Needs DNS records from WE IT | 18 Sep, see below |
| Branding | WE logo, palette, and typography across admin, participant, and email views | Copy review with Sonam and Mia | 21 Aug |
| Tests | Models, services, request flows, mailers, jobs, and browser tests of sign-in and the participant flow | — | Done |
| Documentation | Technical docs plus a [Community Manager runbook](CM_RUNBOOK.md) | Walk the runbook through with the CMs | 25 Sep |

### Carried forward as follow-ups

| Item | Why it matters | By when |
|------|----------------|---------|
| Upgrade Ruby and Rails | Both reached end of support during the build, so security patches have stopped. Needs to land before the app is on a public URL. | 21 Aug, with hosting |
| WE copy review | Sonam's copy for the participant form, invitation, and introduction emails is not in yet. Placeholder copy uses WE Words language. | 21 Aug |

---

## Phase 2 — Hosting and production setup

**Goal: the app on a real URL the WE team can use.** Deadline 28 August 2026.

| Task | Owner | By when |
|------|-------|---------|
| Confirm hosting budget and account owner | Mia / WE | 14 Aug |
| Upgrade Ruby and Rails to supported versions | Ahmed | 21 Aug |
| Set up hosting: app, database, and worker | Ahmed | 21 Aug |
| Subdomain, e.g. `wematch.womenemerging.org` | Ahmed + WE IT | 26 Aug |
| Production admin accounts for the CMs | Ahmed | 26 Aug |
| Smoke test every flow on production | Ahmed | 28 Aug |
| Share URL and sign-in details with the WE team | Ahmed | 28 Aug |

A note on the worker: the biweekly automation needs a second, always-on process. Free
hosting plans do not include one. Without it everything still works, the CM just presses
**Send invitations**, **Close responses**, and **Run matching** on the cycle page. It is
worth paying for — it is the smallest paid instance on the tier and well inside the ~$40
a month already discussed — but it is a decision for Mia, not a blocker.

---

## Phase 3 — Data and pilot prep

**Goal: Higher Ed Explorers and Wavemakers loaded, topics ready, WE team trained.**
Deadline 30 September 2026.

| Task | Owner | By when |
|------|-------|---------|
| Confirm pilot groups and expected headcounts | Mia / WE | 10 Sep |
| Finalise conversation topics and their private options | WE team | 15 Sep |
| **SPF, DKIM, and DMARC records on `womenemerging.org`** | WE IT | 18 Sep |
| Participant CSV ready (name, email, time zone, group, cohort) | WE team | 20 Sep |
| Import the CSV: preview, correct, then commit | Ahmed + WE | 25 Sep |
| Admin walkthrough on production, using the runbook | Ahmed | 25 Sep |
| Decide: in-app email on for the pilot, or manual sending | Mia / Ahmed | 25 Sep |
| Verify headcounts and group membership | WE team | 30 Sep |

The DNS date is the one external dependency worth watching. **18 September** is not
arbitrary: new sending domains need one to two weeks of low-volume sending before real
delivery, so records added later than that mean the October cycles go out manually. That
is a fine outcome — it is what Phase 1 was planned around — but it is a decision made by
that date rather than a surprise.

---

## Phase 4 — Pilot

**Goal: at least one real cycle with each pilot group.** Deadline 31 October 2026.

| Task | Owner |
|------|-------|
| Run cycle — Higher Ed Explorers | Ahmed + WE |
| Run cycle — Wavemakers | Ahmed + WE |
| Send invitation links (in-app, or WE channels if DNS is not ready) | WE team |
| Participants submit topic and windows | Participants |
| Run matching, share introductions | Ahmed + WE |
| Track response rate, pairs, unmatched, topic and option counts | Ahmed + WE |
| Collect feedback from participants and CMs | Mia / WE |
| Log bugs and improvements | Ahmed |

The per-cycle report gives the first four of those numbers directly, including the
aggregate topic and option counts for the insight reporting.

---

## Phase 5 — Bug fixes and improvements

Ongoing from August 2026. Triage weekly, critical fixes as they come, smaller
improvements on a biweekly rhythm, tracker updated weekly.

---

## Phase 6 — Phase 2 plan and sign-off

**Goal: a written plan for fully automated WE Match, agreed by the team.** Deadline
30 November 2026.

Likely Phase 2 scope, now that automation and email exist behind switches:

- Switch the biweekly schedule and in-app email on for all groups
- Bounce and complaint handling from the email provider
- Scaling for 2,500–3,000 people, and what that costs
- Whatever the pilot's response rates say about topics, windows, and cadence

| Task | Owner | By when |
|------|-------|---------|
| Draft Phase 2 plan from pilot learnings | Ahmed | 15 Nov |
| Review with Mia and the WE team | Mia / WE | 22 Nov |
| Team sign-off | Mia / WE | 30 Nov |

---

## Timeline

| Phase | What | Target | Status |
|-------|------|--------|--------|
| 1 | Build, test, complete | 9 Aug 2026 | Complete |
| 2 | Hosting | 28 Aug 2026 | Next |
| 3 | Pilot prep | 30 Sep 2026 | Pending |
| 4 | Pilot (HE Explorers + Wavemakers) | 31 Oct 2026 | Pending |
| 5 | Bug fixes | Ongoing | — |
| 6 | Phase 2 plan | 30 Nov 2026 | Pending |

## What WE Match needs from WE

| What | Who | By when | If it slips |
|------|-----|---------|-------------|
| Hosting budget and account owner confirmed | Mia / WE | 14 Aug | Hosting, and everything after it, slips |
| Copy for the participant form and both emails | Sonam | 21 Aug | Pilot runs on placeholder copy |
| SPF, DKIM, DMARC on `womenemerging.org` | WE IT | 18 Sep | Pilot invitations are sent manually |
| Confirmation: one-hour windows, not 30-minute | Mia | 21 Aug | Built as one hour; changing it later is a small change, but not after data is collected |
| Participant CSV for both pilot groups | WE team | 20 Sep | Pilot slips into November |
| Admin walkthrough attendance | CMs | 25 Sep | CMs run the pilot from the runbook alone |
| Phase 2 scope sign-off | Mia / WE | 30 Nov | — |

## Assumptions and risks

Assumptions:

- Phase 1 stays admin-managed for the pilot, with automation and in-app email switched
  on only when WE chooses
- Pilot groups are 20–50 people each to start
- Sixty percent of a working week remains the working assumption

Risks:

| Risk | Effect | What reduces it |
|------|--------|-----------------|
| DNS records arrive late | Pilot invitations go out manually | Already the planned path; links export to CSV |
| Participant data arrives late | Pilot slips past October | Import is a preview-then-commit step and takes minutes once the file exists |
| Low response rate in the pilot | Not enough signal to plan Phase 2 | Reminder on Wednesday; a second cycle in the same month is cheap |
| Small groups produce few pairs | Pilot looks less useful than it is | Offering fewer topics and asking for two windows rather than one both raise the match rate; the report's topic and window counts show where the gaps are |
| No worker process in hosting | Automation does not run | CM runs each step by hand; no data or feature is lost |

## Budget

| Item | Cost |
|------|------|
| Hosting: app and database | ~$40/month from August, to confirm against current pricing |
| Worker process for automation | Smallest paid instance on the same tier; inside the figure above |
| Subdomain | Free, DNS under `womenemerging.org` |
| Email in Phase 1 | Free, existing WE channels |
| Email in Phase 2 | Transactional provider free tier covers pilot volumes; a paid tier is only needed at full community scale |
