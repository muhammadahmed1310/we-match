# Draft reply to Mia — 9 August 2026

Answers her open questions: in-app email in Phase 1 and whether it fits the $40, Phase 2
timing, CM training, one-hour windows before the pilot, and Julia's dropdown. Send once
the hosting budget question has an owner, since that is the only thing that blocks the
next step.

---

Hi Mia,

Good news first: Phase 1 is built and tested. That includes the two things you asked
about — in-app email and Julia's dropdown — plus time zones and one-hour windows ahead of
the October pilot. The updated plan is attached, with the dates rebased on WE Match
taking up to 60% of my week as you asked.

**Can we integrate in-app email in Phase 1? Yes, and it is already built.** It sits
behind a switch that is currently off, which I think is the right way to run the pilot.
With the switch off, WE Match records every message it would have sent and gives the CM a
download of one private link per person to paste into Outlook or Mailchimp — exactly the
manual flow we agreed. When you decide to turn it on, nothing needs building; it is one
setting.

I kept it behind a switch rather than simply switching it on because sending email from
`womenemerging.org` depends on three DNS records that WE IT has to add: SPF, DKIM, and
DMARC. Without them our invitations land in spam or are rejected, which is worse than
sending manually. A new sending domain also wants a week or two of low volume before it
is trusted, so the records need to exist a fortnight before we send anything real.

**The date I need: 18 September.** If the records are in by then, the October cycles can
go out from the app. Later than that and we send manually for the pilot and switch on
afterwards — that was always the plan, so it is not a setback. Could you point me at the
right person in WE IT and I will chase it from there?

**Is the cost inside the $40 a month? Yes.** The transactional email providers all have
free tiers well above pilot volumes — a couple of hundred messages a cycle across both
groups — so email itself is free for now, and only becomes a small paid line item at full
community scale in Phase 2. The one genuine addition to the hosting figure is a second
always-on process for the biweekly automation, since free plans do not include one. It is
the cheapest paid instance on the tier and stays inside the ~$40. Without it everything
still works, the CM just presses the three buttons herself. Worth paying for, but your
call.

**Time zones and one-hour windows are in, before the pilot as you asked.** Each woman
picks her time zone — the browser guesses it and she can correct it — and then one or two
one-hour windows shown in her own local time. WE Match stores them in UTC, so a Lagos
morning and a Singapore afternoon line up properly, and two people are only introduced
when they have offered the same hour.

One thing to confirm: I built one-hour windows, following the SMT paper. Your feedback in
June mentioned 30 minutes. One hour gives more matches, because it is a wider net, and
the pair agree their real meeting length between themselves anyway. If you would rather
have 30 minutes, tell me before the pilot data is collected and it is a small change.
Otherwise I will treat one hour as settled.

**Julia's idea is very good, and it was not difficult to build.** It is in. Each topic now
has its own dropdown of specific options — under *Jettisoning unhelpful Elements* you
could offer "good girl syndrome", "putting myself last", "not able to say no", and
"other", with a free-text box for other. The CM manages the topics and the options
herself, so you can change them between rounds without me.

The privacy point in her idea is respected exactly: the option a woman picks is **never**
shown to the person she is matched with, and never appears in any email. It is collected
for aggregate insight only. WE Match reports the counts, so after a few cycles you can
say something like "62% of women who chose Jettisoning unhelpful Elements picked the good
girl syndrome" with real numbers behind it. Please pass on that it was a clever idea —
it was the cheapest feature in this round and probably the most valuable one externally.

**Do we need to train the CMs? Yes, and I have written the runbook.** It covers every
action they take: setting up groups and topics, importing people from a spreadsheet,
running a cycle, handing out the private links, reading the results, and what to do when
someone loses her link or answers the wrong thing. I would like to walk two CMs through
it on the production site in late September, once the pilot data is loaded — about an
hour. Could you tell me who should be in that session?

**Phase 2 timing.** Written plan drafted from the pilot's actual numbers by 15 November,
reviewed with you and the team by 22 November, sign-off by 30 November. Now that
automation and email exist behind switches, Phase 2 is mostly turning them on for
everyone, handling bounces, and scaling to 2,500–3,000 — a smaller piece of work than we
first thought.

**What I need from you, in date order:**

| What | Who | By when |
|------|-----|---------|
| Hosting budget confirmed and an account owner named | You / WE | 14 Aug |
| Copy for the participant form and the two emails | Sonam | 21 Aug |
| One hour vs 30 minutes confirmed | You | 21 Aug |
| SPF, DKIM, DMARC on `womenemerging.org`, and the right contact in WE IT | WE IT | 18 Sep |
| Participant spreadsheet for Higher Ed Explorers and Wavemakers | WE team | 20 Sep |
| Two CMs for the walkthrough | You | 25 Sep |

The hosting budget is the only one that blocks the next step, so that is the one I would
most like an answer on this week.

Thanks,
Ahmed
