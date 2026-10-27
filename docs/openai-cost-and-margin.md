# Prayer Lock: AI cost and profit margin

Prices come from https://developers.openai.com/api/docs/pricing (read on 11 Oct 2026).
Prices change, so check the page again before you plan a big launch.

## 1. What one prayer costs

The app uses **gpt-4o-mini** (input $0.15 and output $0.60 per 1 million tokens).

| Part | Tokens | Cost |
|---|---|---|
| Our instructions + the user's two answers (input) | about 120 | $0.000018 |
| The prayer written by the AI (output, about 75 words) | about 110 | $0.000066 |
| **One prayer** | | **about $0.00008** |

Worst case (the longest allowed prayer, 160 tokens): $0.00011.

So **1,000 prayers cost about 8 cents.**

### Other models (same use)

| Model | Input / Output per 1M | Cost of one prayer |
|---|---|---|
| gpt-4o-mini (we use this) | $0.15 / $0.60 | $0.000084 |
| gpt-4.1-nano | $0.10 / $0.40 | $0.000056 |
| gpt-5-nano | $0.05 / $0.40 | $0.000050 (it also "thinks" in hidden tokens, so the real cost is higher) |
| gpt-5-mini | $0.25 / $2.00 | $0.000250 |

gpt-4o-mini is cheap enough and gives warm, reliable prayers. No need to change.

## 2. Cost per user per month

| User type | Prayers per day | Prayers per month | AI cost per month |
|---|---|---|---|
| Light (morning + night) | 2 | 60 | $0.005 |
| Typical (plus 2 before apps) | 4 | 120 | $0.010 |
| Heavy | 15 | 450 | $0.038 |
| Extreme (30 a day) | 30 | 900 | $0.076 |

Other running costs per user are tiny (Firebase sign in is free at this size, Cloud Functions has 2 million free calls a month, about $0.0002 per user after that).

## 3. What a user pays you

| Plan | Price | Per month |
|---|---|---|
| Yearly | $29.99 | $2.50 |
| Monthly | $9.99 | $9.99 |

Use the worst case: a **yearly** user at **$2.50 a month**.

| User type | AI cost | Share of $2.50 |
|---|---|---|
| Typical | $0.010 | 0.4% |
| Heavy | $0.038 | 1.5% |
| Extreme | $0.076 | 3.0% |

So the AI costs **under 3% of revenue even for extreme users.**

## 4. Profit margin before the Play Store / App Store cut

Fixed costs: Apple Developer $99 a year ($8.25 a month), Secret Manager and small Firebase items about $4 a month. Google Play is a one-time $25. RevenueCat is free until $2,500 of monthly tracked revenue.

| Paying users (all yearly) | Revenue / month | AI + servers | Fixed | Profit | **Margin** |
|---|---|---|---|---|---|
| 20 | $50 | $0.5 | $12 | $37.5 | 75% |
| 50 | $125 | $1.3 | $12 | $111.7 | **89%** |
| 100 | $250 | $2.5 | $12 | $235.5 | **94%** |
| 500 | $1,250 | $12 | $12 | $1,226 | **98%** |
| 1,000 | $2,500 | $25 | $12 | $2,463 | **98.5%** |

**You pass 75% from about 20 paying users.** Before that, the $99 Apple fee is what makes the margin lower, not the AI.

After the store cut (15% for small developers, 30% otherwise), a 1,000 user app still keeps about **84%** (15% cut) or **68%** (30% cut). Taxes are not included.

## 5. Free trial cost

A trial user who never pays uses about 28 prayers in 7 days = **$0.0024**.
Even 10,000 trial users who never subscribe cost about **$24**.

## 6. The one real risk: abuse

Anyone can make free guest accounts and call the prayer function in a loop. One call costs $0.0001, so 1 million calls cost about $100.

To protect your margin (I can build these next):
1. **Daily limit per account**, for example 30 prayers a day.
2. **Firebase App Check**, so only the real app can call the function.
3. **A monthly budget limit on OpenAI** (Settings > Limits). Set it to, for example, $20.
4. Keep `max_tokens` at 160 (already done).


## 7. Update 27 Oct 2026: new prices and longer prayers

Prices: Pro Monthly $4.99, Pro Yearly $29.99, Pro Lifetime $49.99.
Prayers are now 4 to 6 sentences with a verse, so one prayer costs about **$0.0001** (worst case $0.00017).

| Plan | Per month | After 15% store cut | After 30% store cut | Margin after AI (15% / 30%) |
|---|---|---|---|---|
| Monthly | $4.99 | $4.24 | $3.49 | 85% / 70% |
| Yearly | $2.50 | $2.12 | $1.75 | 85% / 70% |
| Lifetime (spread over 3 years) | $1.39 | $1.18 | $0.97 | 84% / 69% |

AI cost per user per month: typical (120 prayers) $0.012, heavy (450) $0.045, extreme (900) $0.15.
Lifetime over 5 years: profit about $41.8 for a typical user, about $33.3 for an extreme user (15% cut).

Fixed costs about $12.25 a month (Apple $99 a year plus small Firebase items).
Break-even: 3 monthly, 6 yearly or 11 lifetime buyers (15% cut), about 4, 8 or 13 with a 30% cut.

Mix of 60% yearly and 40% monthly, typical use, profit after the store cut, AI and fixed costs:

| Paying users | Profit / month (15% cut) | Margin | Profit / month (30% cut) | Margin |
|---|---|---|---|---|
| 25 | $62 | 71% | $49 | 56% |
| 100 | $284 | 81% | $231 | 66% |
| 500 | $1,467 | 84% | $1,205 | 69% |
| 1,000 | $2,947 | 84% | $2,423 | 69% |
