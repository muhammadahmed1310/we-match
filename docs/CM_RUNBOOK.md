# WE Match — Community Manager runbook

Everything a Community Manager does in WE Match, in the order they do it. No technical
knowledge needed. If a step here does not match what you see on screen, tell Ahmed —
the screen is right and this page is wrong.

Two words used throughout:

- A **cycle** is one matching round for one group. WE Fellows and Higher Ed Explorers
  each get their own cycle.
- A **window** is a fixed one-hour slot someone offers, e.g. Tuesday 14:00–15:00 in
  her own time zone. WE Match introduces the pair; the two of them agree the actual
  time between themselves.

---

## Before the first cycle

| # | Do this | Where |
|---|---------|-------|
| 1 | Sign in with the address Ahmed set up for you | **Sign in** |
| 2 | Create the group, e.g. *Higher Ed Explorers* | **Groups → New group** |
| 3 | Add the conversation topics, and the private options under each one | **Topics → New topic** |
| 4 | Load the people, either one at a time or from a spreadsheet | **WE Community → Add person**, or **Import CSV** |

### Topics and their options

A **topic** is what the pair will talk about — *Leadership*, *Career transitions*. It is
shown to participants and to the pair in their introduction email.

An **option** under a topic is the more specific thing she wants to discuss —
*Difficult conversations*, *Asking for a raise*. This is Julia's dropdown. It is
**private**: it never appears in anyone's introduction email. It exists so WE can see,
in aggregate, what the community is actually wrestling with. You will find those counts
under **Reports**.

Set a topic or option to inactive rather than deleting it when you stop offering it.
Deleting is blocked once anyone has chosen it, so past cycles keep their meaning.

### Importing people from a spreadsheet

**WE Community → Import CSV**. The file needs a header row with `name` and `email`;
`time_zone`, `groups`, and `cohort` are optional. Separate multiple groups with a
semicolon.

```csv
name,email,time_zone,groups,cohort
Amara Okafor,amara@example.com,Africa/Lagos,Higher Ed Explorers,2026
Priya Raman,priya@example.com,Asia/Kolkata,Higher Ed Explorers;Wavemakers,2026
```

The import always previews first: **Preview import** shows exactly which rows would be
added, which would be updated, which are already correct, and which have a problem, with
the reason on each line. Nothing is written until you press the import button on that
screen.

Two things to know. If any row has a problem the import will not run at all — fix the file
and preview again, because half an imported file is more work than none. And groups named in
the file must already exist, unless you tick **Create groups that don't exist yet**.

People are matched on email, so re-importing a corrected file updates the same people
rather than creating duplicates.

---

## Running a cycle

If the group has **auto-cycling** switched on and the jobs worker is running, the app
does steps 1, 4, and 5 on its own: opens a cycle every second Monday, closes it Thursday
evening, and matches on Friday morning. You still hand out the links (step 2) while
in-app email is off. Everything below also works by hand at any time.

| # | Do this | Where | What to expect |
|---|---------|-------|----------------|
| 1 | Create the cycle: pick the group, the response deadline, and the week the meetings are for | **Match Cycles → New match cycle** | Status **draft** |
| 2 | **Send invitations** | Cycle page | One private link per person in the group. Status becomes **open** |
| 3 | Watch responses arrive | Cycle page | Each person shows as invited, responded, or not yet |
| 4 | **Close responses** after the deadline | Cycle page | Status **closed**; the links stop accepting new answers |
| 5 | **Run matching** | Cycle page | Status **matched**; pairs are created and introductions go out |
| 6 | Read the numbers | **Reports → the cycle** | Response rate, pairs, who was left unmatched, topic counts |

### Handing out the links while in-app email is off

During the pilot WE sends the messages from its own channels. On the cycle page use
**Invitation links → Download CSV**. You get one row per person with her name, email,
and her own private link. Paste that into Outlook or Mailchimp as a mail merge.

Each link is personal. It identifies her, so she never picks her own name from a list
and nobody can answer on her behalf. Treat it like a password: do not put it in a group
email or a shared document.

She can reopen her own link any time before the cycle closes and change her answer.

### What she sees

Her page asks for three things: her time zone (the browser guesses it, she can correct
it), one topic and optionally the private option under it, and one or two one-hour
windows. Windows are listed in her own time zone; WE Match stores them in UTC so a
Lagos morning and a Singapore afternoon line up correctly.

---

## Matching, in plain terms

Two people are introduced when all of these are true:

- they are in the same group, in the same cycle
- they chose the **same topic**
- they offered the **same one-hour window**, once both are converted to UTC
- they were not introduced to each other recently — WE Match avoids repeating a pairing
  from the group's last few cycles, though it will repeat one rather than leave someone with
  nobody

Everyone is introduced at most once per cycle. Anyone left over stays unmatched and is
listed on the cycle page and in the report — worth a personal note from you, and worth
watching if the same person is unmatched twice in a row.

### When somebody is unmatched

Almost always one of two things: she was the only person to pick that topic, or her windows
did not line up with anyone else's. The report does not spell out which, but the topic and
window counts on the same page usually make it obvious — a topic with a single response, or
an hour nobody else offered.

Offering fewer topics, or nudging people to offer two windows rather than one, both raise
the match rate in a small group.

---

## Common questions

**Someone lost her link.** Open the cycle, find her under invitation links, and send it
again. It does not change.

**Someone replied to the wrong thing.** Ask her to reopen her link and resubmit while
the cycle is open. After it closes you can edit her response from the cycle page.

**Someone joined the group after invitations went out.** Add her to the group, then
press **Send invitations** again. Only people who have not been sent a link get one, so
nobody is emailed twice.

**Can I run matching twice?** No. Once a cycle is matched it is final, so nobody gets
two conflicting introductions. Run a fresh cycle instead.

**Can someone in two groups be matched twice?** Yes — once in each group's cycle. That
is intended.

**Did the emails actually go out?** The dashboard shows whether in-app email is on and
lists what was recently sent. While it is off, everything that *would* have been sent is
still recorded, so nothing is lost when it is switched on.

---

## Who to ask

| Situation | Who |
|-----------|-----|
| A screen is broken, or a number looks wrong | Ahmed |
| Someone should be added to or removed from a group | You, in **WE Community** |
| Topics need to change for the next round | WE team, then you in **Topics** |
| Switching on in-app email | Ahmed, once WE IT has added the DNS records |
