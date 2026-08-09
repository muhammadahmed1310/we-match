# WE Match — complete app flow

Who does what, in what order, and how it maps to the product document. If you are a
Community Manager looking for the steps you actually take, read the
**[CM runbook](docs/CM_RUNBOOK.md)** instead — it says the same things without the
implementation detail.

---

## Do cycles get created automatically or by hand?

**Both.** A cycle is one matching round for one group.

Groups flagged for **auto-cycling** get one every second Monday: `OpenBiweeklyCyclesJob`
opens the cycle and sends invitations, `SendResponseRemindersJob` nudges non-responders on
Wednesday, `CloseDueCyclesJob` closes it Thursday evening, and `RunDueMatchingJob` matches
on Friday. The rhythm lives in `config/recurring.yml` and needs the `bin/jobs` worker
running.

Any cycle can also be created and driven by hand from the cycle page, which is what a CM
does for a one-off round, and what happens for every group when no worker is running.

---

## Roles

| Role | Who | How they get in |
|------|-----|-----------------|
| Admin (CM or Ahmed) | WE team | Email and password. Every admin screen is private |
| Participant | A woman in the WE Community | Her own private link. No account, no password |

There is no public sign-up. Admins are created with `bin/rails admin:create`.

A participant's link identifies her. She never picks her name from a list, and no URL
contains a `member_id`, so nobody can answer on anyone else's behalf.

---

## Function 1 — Groups and people

Women belong to one or more groups; matching never crosses groups. A group membership
also carries a **cohort** label, so *2026* and *2025* Explorers can be told apart inside
one group.

| Screen | What it does |
|--------|--------------|
| **Groups** | Create, edit, delete; switch auto-cycling on or off |
| **WE Community** | Create, edit, delete a person; set her time zone; put her in any number of groups with a cohort |
| **Import CSV** | Load a spreadsheet of people. Previews created, updated, and invalid rows; nothing is written until confirmed. People are matched on email, so re-importing corrects rather than duplicates |
| **Topics** | Topics offered to participants, each with its own dropdown of private options |

Topics can be global or restricted to one group. Deleting a topic or option that has
already been chosen is blocked; make it inactive instead so old cycles keep their meaning.

---

## Function 2 — Invitation and response

| Step | Who | What happens |
|------|-----|--------------|
| 1 | Admin or job | Cycle created for one group, with a response deadline and the week the meetings are for |
| 2 | Admin or job | **Send invitations** creates one `CycleInvitation` per person in the group, each with a unique token, and mails the link. Pressing it again only sends to people who have not been sent one yet |
| 3 | Admin | While in-app email is off, **Invitation links → Download CSV** gives name, email, and link per person for a mail merge |
| 4 | Participant | Opens `/respond/:token`: confirms her time zone, picks one topic and optionally the private option under it, and picks one or two one-hour windows shown in her own local time |
| 5 | Participant | Can reopen the same link and change her answer until the cycle closes |
| 6 | Admin or job | **Close responses** stops the links accepting answers |

Windows come from `MeetingWindows`, which generates the fixed hours of the cycle's meeting
week. They are rendered in her zone and stored in UTC as `ResponseSlot` rows, so
availability from different continents compares correctly.

The option she picks under a topic is private. It is never rendered in any mailer and
never shown to the woman she is matched with; it exists for the aggregate counts in
**Reports**.

Participants meet a clear page rather than an error for every dead end: an unknown or
expired token, a cycle that has closed, and a cycle that has already been matched.

---

## Function 3 — Matching and introduction

**Run matching** pairs two responses when all of these hold:

- same cycle, therefore same group
- the same `topic_id` — an exact match, not a guess at similar wording
- an identical window once both are in UTC
- the two were not paired in the group's last six cycles — avoided on a first pass, then
  allowed on a second, because a repeat introduction beats leaving someone with nobody

Everyone is paired at most once per cycle; anyone left over is listed as unmatched, on the
cycle page and in the report. Matching runs once — a matched cycle cannot be re-run, so
nobody receives two conflicting introductions.

Each pair gets `MatchMailer#introduction`: both names and emails, the shared topic, and
the window they have in common in each recipient's own time zone. No calendar link and no
meeting booked; they arrange it themselves.

---

## One round, end to end

```
JOBS / ADMIN                        GROUP
     |                                |
     |-- Monday: open cycle --------->|
     |-- send invitations ----------->| private link each
     |                                |
     |<---- topic + 1–2 windows ------| response (editable)
     |-- Wednesday: reminder -------->| non-responders only
     |                                |
     |-- Thursday: close responses ---|
     |-- Friday: run matching --------|
     |-- introductions -------------->| pairs notified
     |                                |
     |-- read the report              | they arrange the meeting
```

---

## Cycle statuses

| Status | Meaning |
|--------|---------|
| **draft** | Created; no invitations sent |
| **open** | Invitations sent; links accept and edit responses |
| **closed** | Links stop accepting; admins can still correct a response |
| **matched** | Pairs created and introduced. Final |

---

## Email

Everything outbound goes through `MailDelivery`, which writes an `EmailDelivery` row for
each intended message and then queues the send. Real sending only happens when
`EMAIL_DELIVERY_ENABLED` is set, which is off in production until SPF, DKIM, and DMARC
exist on `womenemerging.org`. With it off, the record is still written, the dashboard shows
what would have gone out, and CMs hand out exported links.

---

## Reporting

**Reports** gives per-cycle response rate, pairs, unmatched women, and the aggregate topic
and option counts, plus the same figures rolled up across cycles and filtered by group.
Both export to CSV.

---

## FAQ

**Can a woman in two groups be matched twice?** Yes, once per group cycle. Intended.

**Can someone from group A match with someone from group B?** No. Different groups run
different cycles.

**What if nobody shares her topic or her hour?** She stays unmatched for that cycle. The
report shows which of the two it was.

**Can matching be re-run?** No. Run a new cycle.

**Does WE Match book the meeting?** No. It introduces the pair and stops there.
