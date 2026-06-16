# Voice & Microcopy Guide

How JOBBees talks. This is the single source of truth for every button label, error message, empty state, and notification copy. When the AI (or you) is unsure how to write a string, check here first.

---

## Tone in three words

**Warm. Plain. Direct.**

We're an Australian peer-to-peer marketplace. Clients are busy parents, renters, professionals. Taskers are tradespeople, students, side-hustlers. Both deserve to be talked to like adults — not marketed at.

If a sentence sounds like it could be on a SaaS landing page, rewrite it.

---

## Voice principles

1. **Plain over clever.** "Your job is live" beats "Your task is now adventurously seeking heroes!" Pun-free zone.
2. **Direct over polite.** "Add a payment method" beats "Please consider adding a payment method when you're ready." Aussies don't need padding.
3. **Specific over abstract.** "Stripe needs your driver's licence" beats "We need to verify your identity." Tell people exactly what's needed.
4. **Now over later.** "Tap to upload" beats "You can upload when convenient." Active voice, present tense, no hedging.
5. **Confident over apologetic.** "This card was declined" beats "We're so sorry, it seems there might have been an issue." Don't apologise unless we caused the problem.
6. **You over we.** "Your held funds" beats "Funds we are holding for you." Centre the user, not the platform.
7. **Conversational confirms over OK/Cancel.** "Yes, post this job" + "Not yet" beats "OK" + "Cancel." Buttons should restate the action.

---

## Forbidden phrases

If you find any of these in the codebase, replace them. The AI defaults to these and they all sound like 2018-era marketing copy.

| Don't use                     | Use instead                                                                   |
| ----------------------------- | ----------------------------------------------------------------------------- |
| "AI-powered"                  | (just describe what it does — "We'll fill in the details from your photo")    |
| "Seamlessly"                  | (delete the word; rewrite the sentence)                                       |
| "Delightful"                  | (describe the actual benefit)                                                 |
| "Leverage"                    | "Use"                                                                         |
| "Empower"                     | (describe what they can do)                                                   |
| "Effortlessly"                | (delete)                                                                      |
| "Magical"                     | (we're a marketplace, not a wizard)                                           |
| "Revolutionary"               | (we're literally just one feature)                                            |
| "Best-in-class"               | (just be the thing)                                                           |
| "Synergy"                     | (don't)                                                                       |
| "Tap into"                    | "Use"                                                                         |
| "Unlock"                      | "Get to" / "See"                                                              |
| "Robust"                      | (describe the property — "Stripe handles 99.99% of payment requests")         |
| "Industry-leading"            | (delete)                                                                      |
| "Cutting-edge"                | (delete)                                                                      |
| "Streamline"                  | "Simplify" / (rewrite)                                                        |
| "Oops!"                       | "Something went wrong." (no exclamation; users have heard "Oops" 10000 times) |
| "Whoops!"                     | (same)                                                                        |
| "Sorry for the inconvenience" | (apologise only if we caused the problem; otherwise just say what to do next) |
| "Please" + button labels      | (delete "please" from CTAs — buttons are actions, not requests)               |
| "Click here"                  | (link the noun: "View invoice" not "Click here to view invoice")              |
| Emoji in microcopy            | (use sparingly — once per screen max, only if it adds clarity)                |
| "Welcome to the family!"      | (we're a marketplace, not a cult)                                             |

---

## Example strings — by surface

### Buttons (CTAs)

✅ **Good**

- Post a job
- Make an offer
- Pay $84
- Accept this offer
- Verify with Stripe
- Become a tasker
- Get started
- Add a card
- I'll do it later
- Yes, withdraw my offer
- No, keep it open

❌ **Bad**

- Submit (what am I submitting?)
- Continue (continue what?)
- Next (next what?)
- OK (boring + ambiguous)
- Click here
- Please confirm (delete "please")
- Submit your application! (no exclamation; what's the application?)

### Empty states

These do double duty as tutorials. Don't waste them.

✅ **Good**

- **No jobs near you yet** — Be the first to post one. We'll send it to taskers in your suburb. _[Post a job]_
- **No offers yet** — Most jobs get their first offer within 2 hours. You can edit the job while you wait. _[Edit job]_
- **You haven't been a tasker before** — Get verified once with Stripe, then offer on any job. Takes 5 minutes. _[Become a tasker]_
- **Inbox is quiet** — When you have an accepted offer, your conversations will live here.

❌ **Bad**

- "No items found" (cold)
- "Nothing here" (lazy)
- "404" (we're not a webpage)
- "Empty" (literally nothing else)

### Error states

State the problem. State the fix. Move on.

✅ **Good**

- **This card was declined** — Try a different card, or contact your bank. _[Add a card]_
- **Connection lost** — We'll retry when you're back online. _[Retry]_
- **That email is already in use** — Log in instead, or use a different email. _[Log in]_
- **Photo upload failed** — File was too large (max 10 MB). Try a smaller photo. _[Choose another]_
- **OTP didn't match** — You can try 3 more times. _[Send again]_

❌ **Bad**

- "Something went wrong" (what? what do I do?)
- "An error occurred" (still useless)
- "Please try again" (when? why?)
- "Oops!" (delete)
- "We're sorry" (don't apologise unless we caused it)

### Success states

Be brief. Don't make people read.

✅ **Good**

- **Job posted.** We're notifying matched taskers.
- **Payment authorised.** $84 will release when work is complete.
- **Offer accepted.** Your tasker has been notified.
- **Verified.** You can now make offers.

❌ **Bad**

- "Congratulations! 🎉 You've successfully posted your job!" (one exclamation is too many)
- "Your action was completed successfully" (literally tell me nothing)

### Confirmation modals (destructive actions)

Restate the action in the affirmative button.

✅ **Good**

- **Withdraw your offer?** The client will no longer see it.
  _[Yes, withdraw]_ _[Keep it open]_
- **Delete your account?** This anonymises your reviews, releases any held funds, and can't be reversed.
  _[Yes, delete it]_ _[I'll keep it for now]_
- **Cancel this job?** You'll forfeit the $50 cancellation fee per our cancellation policy.
  _[Yes, cancel and pay $50]_ _[Keep the job]_

❌ **Bad**

- "Are you sure?" + "OK" / "Cancel" — restates nothing; the user has to remember what's about to happen

### Notifications (push, email, SMS)

Lead with the most important word. Front-load value.

✅ **Good**

- **Push:** "New offer on your fence repair — $180" → tap → offer detail
- **Email subject:** "Sarah accepted your offer — Saturday 10am"
- **SMS:** "JOBBees: Your verification code is 482917. Valid 5 min."

❌ **Bad**

- "You have a new notification!" (useless)
- "An update is available" (what update?)
- "Action required" (vague + scary)

### OTP / verification

✅ **Good**

- "Enter the 6-digit code we sent to +61 4XX XXX XXX"
- "Didn't arrive? Try again in 30 seconds." _[Send again — disabled until 30s passes]_

❌ **Bad**

- "Please enter your one-time password" (don't say "password" for OTP — confusing)

### License / KYC verification

These are sensitive. Be honest about why.

✅ **Good**

- "Stripe needs your driver's licence and a selfie to verify you. Required by Australian law."
- "Plumbing jobs need a current NSW plumbing licence. Upload yours below — we'll check it against the NSW Fair Trading register."

❌ **Bad**

- "Verify your identity" (vague — what's needed? why?)
- "Compliance step" (cold + scary)

---

## How to write microcopy — 5 rules

1. **Read it out loud.** If you wouldn't say it to a friend, don't write it.
2. **Cut "please" from buttons.** Buttons are actions, not requests.
3. **State the verb, then the noun.** "Post a job" not "Job posting."
4. **Lead with the most important word.** "New offer — $180" not "You have received a new offer in the amount of $180."
5. **Make the destructive button restate the action.** "Yes, delete it" not "OK."

---

## When in doubt

Imagine you're at a backyard barbecue explaining JOBBees to a mate. How would you say it? Write that.

---

## Maintenance

- This file is the canon. If you find better example strings during the build, add them.
- The AI should check this file when generating any user-facing string. If it doesn't, flag it in PR review.
- Voice principles change slowly. Forbidden-phrase list changes as you find new offenders.
