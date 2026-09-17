# WE Match — Community Manager runbook

Everything a Community Manager does in WE Match, in the order they do it. No technical
knowledge needed. If a step here does not match what you see on screen, tell Ahmed —
the screen is right and this page is wrong.

Two words used throughout:

- A **cycle** is one matching round for one group (for example Higher Ed Explorers).
- A **window** is a fixed one-hour slot someone offers, e.g. Tuesday 14:00–15:00 in
  her own time zone. WE Match introduces the pair on that shared window; they reach out
  to each other to start the conversation.

In the admin screens, people are called **Users**.

---

## How a normal fortnight works

Once a group has a **matching start date** and at least two users, WE Match runs on its
own. You do not need to create a match cycle for every round.

| Day | What happens |
|-----|----------------|
| **Monday** | A new cycle opens. Invitation emails go out with each person’s private link. |
| **Wednesday** | Reminder emails go to people who have not responded yet. |
| **Thursday evening** | Responses close. |
| **Friday morning** | Matching runs. Introduction emails go to each pair. |
| **One week after pairs are introduced** | Feedback emails go to people who were matched. |

Your day-to-day job is: keep **groups** and **users** correct, then watch responses and
reports. Conversation **topics** are the same across groups and only change when Mia
initiates an update — you do not manage them day to day. Buttons on the cycle page
(**Send invitations**, **Close responses**, **Run matching**) are backups — use them if
something failed, someone needs a resend, or you need to act early.

---

## Before the first cycle

| # | Do this | Where |
|---|---------|-------|
| 1 | Sign in with the address Ahmed set up for you | **Sign in** |
| 2 | Create the group and set its matching dates | **Groups → Create Group** (or **New group**) |
| 3 | Load the people, either one at a time or from a spreadsheet | **Users → Add person**, or **Import Excel** |

Topics are already set up for everyone. You do not need to add or edit them before the
first cycle.

### Creating a group

On the group form you set:

- **Group name** (required)
- **Description** (optional)
- **Matching start date** (required) — cycles will not open before this date
- **Matching end date** (optional) — leave blank if matching has no end date

Cycles run every two weeks between those dates: invites Monday → respond by Thursday →
matches Friday. If the start date is not a Monday, the first cycle opens on the next
Monday on or after that date.

You need **at least two users** in the group before a cycle will open.

### Topics and their options

Topics are shared across matching. Mia decides the wording; Ahmed implements changes in
WE Match. CMs do not edit topics as part of normal work.

A **topic** is what the pair will talk about — *Leadership*, *Women Emerging*. It is
shown on the response form and in the introduction email.

An **option** under a topic (sometimes called a subtopic) is more specific —
*Difficult conversations*, *Asking for a raise*. Options are **not** chosen when someone
submits availability. They appear later on the **feedback** form, after the match, so WE
can see in aggregate what resonated. Counts show under **Reports**. Options stay
**private** — they never appear in introduction emails.

### Importing people from a spreadsheet

**Users → Import Excel**. Upload an `.xlsx` workbook only (not CSV). The first sheet
needs a header row with `name` and `email`; `time_zone`, `groups`, and `cohort` are
optional. Separate multiple groups with a semicolon.

| name | email | time_zone | groups | cohort |
|------|-------|-----------|--------|--------|
| Amara Okafor | amara@example.com | Africa/Lagos | Higher Ed Explorers | 2026 |
| Priya Raman | priya@example.com | Asia/Kolkata | Higher Ed Explorers;Wavemakers | 2026 |

The import always previews first: **Preview import** shows which rows would be added,
updated, already correct, or have a problem. Nothing is written until you confirm on that
screen.

If any row has a problem the import will not run at all — fix the file and preview again.
Groups named in the file must already exist, unless you tick **Create groups that don't
exist yet**.

People are matched on email, so re-importing a corrected file updates the same people
rather than creating duplicates.

External sign-up (name, email, timezone) happens outside WE Match. You bring those people
in through **Users** or Excel import.

---

## During a cycle

You usually only watch. Open **Match Cycles** (or the group page) to see the open cycle.

| What you might do | When | Where |
|-------------------|------|-------|
| Check who has responded | Any time while open | Cycle page |
| Enter a response for someone | They cannot use their link | Cycle page → **Enter a response for someone** |
| **Resend to everyone** / send one link again | Lost email or new joiners | Cycle page |
| **Close responses** early | You need to stop answers before Thursday | Cycle page |
| **Run matching** early | You need pairs before Friday | Cycle page |
| Read the numbers | After matching, and after feedback | **Reports** or cycle → **Report** |

### Extra / one-off cycles

Almost never needed. If you must run an extra round by hand: **Match Cycles → New
cycle**, pick the **group** only. WE Match sets the usual dates (open now, close in about
three days, meeting week the week after). Then send invitations from the cycle page if
email did not already go out.

### Invitation links (backup)

Each person has a private link. Treat it like a password: do not put it in a group email
or a shared document.

On the cycle page use **Invitation links** (and **Download CSV** if you need a mail
merge). She can reopen her own link any time before the cycle closes and change her
answer.

### What she sees (response form)

Her page asks for:

1. Her **time zone** (the browser guesses it; she can correct it)
2. One **topic**
3. One or two **one-hour windows** for the meeting week

Windows are listed in her own time zone; WE Match stores them in UTC so a Lagos morning
and a Singapore afternoon line up correctly.

She does **not** pick a private option on this form. That comes later in feedback.

---

## Matching, in plain terms

Two people are introduced when all of these are true:

- they are in the same group, in the same cycle
- they chose the **same topic**
- they offered the **same one-hour window**, once both are converted to UTC
- they were not introduced to each other recently — WE Match avoids repeating a pairing
  from the group's last few cycles, though it will repeat one rather than leave someone
  with nobody

Everyone is introduced at most once per cycle. Anyone left over stays unmatched and is
listed on the cycle page and in the report — worth a personal note from you, and worth
watching if the same person is unmatched twice in a row.

### When somebody is unmatched

Almost always one of two things: she was the only person to pick that topic, or her
windows did not line up with anyone else's. The report does not spell out which, but the
topic and window counts on the same page usually make it obvious.

Nudging people to offer two windows rather than one raises the match rate in a small
group.

---

## After the match — feedback

**One week after pairs are introduced**, each matched person gets an email with a private
feedback link. The form asks:

1. Did you actually meet?
2. If yes — what was the value for the time of the conversation?
3. Which option under the matched topic resonated most? (private; for WE reports only)

Unmatched people are not asked for feedback.

Submitted answers feed the cycle **Report** (who met, average value, what resonated).

---

## Common questions

**Someone lost her link.** Open the cycle, find her under invitation links, and send it
again. Or use **Resend to everyone**. The link itself does not change.

**Someone replied to the wrong thing.** Ask her to reopen her link and resubmit while
the cycle is open. After it closes you can edit her response from the cycle page.

**Someone joined the group after invitations went out.** Add her to the group, then
press **Send invitations** again. Only people who have not been sent a link get one, so
nobody is emailed twice by mistake.

**Do I create a cycle every fortnight?** No. Set the group’s matching start date; the
app opens cycles automatically.

**Why are there still Send / Close / Match buttons?** Backups for failures, early runs,
and resends. The scheduled jobs do the same steps on Monday / Thursday / Friday.

**Can I run matching twice?** No. Once a cycle is matched it is final. Run a fresh cycle
instead if you need another round.

**Can someone in two groups be matched twice?** Yes — once in each group's cycle. That
is intended.

**Did the emails actually go out?** The dashboard shows whether in-app email is on and
lists what was recently sent. While delivery is off, intended emails are still recorded,
and you can hand out links from the cycle page.

---

## Who to ask

| Situation | Who |
|-----------|-----|
| A screen is broken, or a number looks wrong | Ahmed (implementor) |
| Someone should be added to or removed from a group | You, in **Users** |
| Topics or topic options need to change | Mia (responsible for topics); Ahmed implements |
| Matching dates or automation questions | Ahmed |
| Switching on or fixing in-app email | Ahmed |
