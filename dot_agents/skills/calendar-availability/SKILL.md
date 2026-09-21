---
name: calendar-availability
description: My calendar availability rules. Use this whenever listing free dates or evenings, proposing meeting times, or deciding whether a calendar slot is realistically available. Inspect event titles and travel context, infer away periods from flights and travel markers, and never rely on Busy/Free alone.
---

# Calendar availability

When I ask which dates or times are free, answer the practical question "could I normally make a local appointment then?", not merely "does Google Calendar report this interval as free?"

## Inspect calendar context before declaring availability

- **Do not use Free/Busy as the only source.** Retrieve actual calendar events so you can inspect titles, dates, times, locations, and surrounding context. Free/Busy is useful for detecting ordinary conflicts, but it loses the semantic information needed to recognize travel.
- **Inspect the full requested date range, plus nearby dates when possible.** Travel can start just before the requested range or end just after it. For availability searches spanning days or weeks, use a buffer of about a week on each side when the calendar tool permits it.
- **Check the calendars that can affect my real availability**, including calendars where I keep travel or personal events. Do not assume the primary calendar is sufficient when other relevant calendars are accessible.
- **For an evening-availability query, inspect the whole candidate day and nearby travel events**, not only events whose timestamps overlap the evening. A flight earlier that day or an all-day travel marker can make an otherwise empty evening unavailable.
- Declined meetings can normally be ignored as conflicts, but transparent/all-day events may still be important travel evidence.

## Recognize travel evidence

Treat the following as evidence that I may be away. They are semantic clues, not just ordinary Busy blocks.

### Travel markers in event titles

Examples include:

- `KR`, `Korea`, `Seoul`
- `Taipei`, `Taiwan`
- `Hong Kong`
- other city/country names
- conference or event names that plausibly imply travel
- multi-day or all-day entries whose title looks like a destination or trip label

For me, short entries such as `KR` are meaningful travel clues, especially when they are multi-day/all-day or occur near flight events. Do not discard them merely because the title is terse.

### Likely flight or intercity travel events

Do not require one exact title format. Interpret the event semantically and look for evidence that it represents movement between places.

**Treat route-shaped IATA airport code pairs as a particularly strong positive signal.** I commonly write flight events this way, so strings such as these are useful search keys as well as strong evidence once found:

- `HND-GMP`
- `GMP-HND`
- `NRT-ICN`
- `TPE-HND`

More generally, two three-letter airport codes separated by `-`, `/`, or an arrow should receive high weight as a likely flight route.

Also recognize less structured travel notation. Examples include:

- airport names such as `羽田`, `成田`, `金浦`, `仁川`, `松山`, `桃園`, or their English names
- origin/destination expressions such as `羽田→金浦`, `羽田発`, `ソウル行き`, `台北から帰国`, or `Tokyo to Seoul`
- airline names, flight numbers, terminal names, or other aviation terms when they appear with a plausible origin, destination, or travel time
- natural-language titles whose wording and timing clearly imply departure, arrival, transit, or return even if no airport code appears

Use event title, location, description, chronology, and nearby events together when the calendar tool exposes them. An airport name by itself is weaker evidence than an explicit route, but several consistent clues should be treated as travel.

For me, HND/NRT and 羽田/成田 are normally Tokyo-side airports. A route or departure phrasing from one of them toward another city is therefore strong evidence of an outbound trip. A route or arrival phrasing toward one of them is strong evidence of a return. This is still a clue rather than an absolute rule, so use chronology and nearby events as well.

## Infer the away period

Build a travel interval from the available evidence before producing free dates.

- An outbound trip followed later by a return normally means I am away from the outbound departure through the return arrival.
- **Exclude every date inside that interval from normal local availability**, even if its calendar is otherwise empty.
- Treat the outbound and return dates themselves as travel days and exclude them from ordinary "free evening" results unless I explicitly ask whether a narrow slot on a travel day is usable.
- A multi-day travel event can establish or reinforce the same away interval.
- Intermediate travel between non-Tokyo locations usually means the trip is continuing, not that I have returned home.
- If outbound travel is visible but the return is not, do not start listing subsequent empty dates as confidently free. Search farther if practical; otherwise treat them as uncertain.
- If a travel marker and route pattern disagree, or the direction/extent of the trip cannot be determined confidently, **ask me a short clarification question before presenting the affected dates as available**.

Do not ask merely because travel exists. When the evidence clearly identifies the away interval, silently exclude it and, when useful, mention the excluded travel period.

## Classify candidate dates conservatively

Before returning a date as available, put it mentally into one of these categories:

1. unavailable because an explicit event conflicts;
2. unavailable because travel context says I am away or in transit;
3. uncertain because travel is plausible but the interval cannot be resolved;
4. available.

Return category 4 as free. Exclude categories 1 and 2. Resolve category 3 with me before calling it free.

**Prefer false negatives over false positives.** It is better to omit a possibly usable evening or flag it for confirmation than to tell me I am free while I am actually traveling.
