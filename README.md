# kanban

A small kanban board with sign-in, written to see how [Spinel](https://github.com/matz/spinel), [CyberTrain](https://github.com/saeki-mototsune/CyberTrain), [cybertrain-kaisatsu](https://github.com/Yucky39/cybertrain-kaisatsu) (authentication) and [cybertrain-postal](https://github.com/Yucky39/cybertrain-postal) (mail) behave together in a real application. It is a test bed, not a product.

Each person has their own boards. A board has three columns (To do, Doing, Done); cards are added to To do and moved left or right. Everything is behind sign-in, and every query is scoped to the signed-in user.

## Run it

Needs Spinel 2026.09.12 (`cybertrain setup`), and on macOS with Homebrew:

```sh
export LIBRARY_PATH=$(brew --prefix openssl@3)/lib CPATH=$(brew --prefix openssl@3)/include   # for the mail worker only
cybertrain db migrate
cybertrain server 3990          # development server
script/verify http://127.0.0.1:3990
```

Production build:

```sh
cybertrain build
cd dist && ./kanban migrate
CYBERTRAIN_SECRET_KEY_BASE=$(openssl rand -hex 32) CYBERTRAIN_DATABASE=$PWD/storage/prod.sqlite3 \
KAISATSU_BASE_URL=https://example.com KAISATSU_MAIL_FROM=noreply@example.com SPINEL_WORKERS=2 PORT=3991 ./kanban
```

Mail (confirmation and reset links) is queued in `storage/mail_spool/` and sent by the separate worker: `cybertrain spin run mail_worker` with `KAISATSU_SMTP_HOST` set. Without `KAISATSU_MAIL_FROM`, mail is only printed to the log (development).

## What was checked

`script/verify` drives a running server with `curl` (42 checks) and `script/load` measures it with ApacheBench. Both were run against the development server and against the production binary (`cybertrain build`), on macOS arm64, Spinel 2026.09.12, CyberTrain v0.2.1.

**Behaviour: 42 of 42 checks pass, in development and in the production build.**

- Anonymous visitors are redirected to `/login`; a POST without a CSRF token is refused (403).
- Sign-up, sign-in (a wrong password is refused), sign-out, and the old cookie no longer works after sign-out.
- Boards and cards: create, add cards, move right and left (moving past the last column changes nothing), delete.
- Validation: an empty board name and a 201-character title are refused. A `<script>` in a card title or a tag in a board name is shown as text.
- **Ownership:** a second user gets 404 for the first user's board, for adding a card to it, for moving it, deleting it, and deleting the board; the first user's data is unchanged afterwards. A card id that does not exist is also 404.
- Sessions survive a restart of the server with the same `CYBERTRAIN_SECRET_KEY_BASE` and end when the secret changes (as documented).

**Load (production binary, one machine, ApacheBench with keep-alive, 20 connections):**

| | 1 worker | 2 workers |
| --- | --- | --- |
| `GET /login` (anonymous), requests per second | about 13,000 | about 18,000 |
| `GET` a board with 40 cards, signed in, requests per second | about 1,080 | about 1,620 |
| a cheap `GET /login` while four sign-ins run at once: median / 95th percentile | 168 ms / 177 ms | 60 ms / 113 ms |
| 16 concurrent sign-ins (4 at a time), total time | 8.3 s | 5.8 s |

- A password check costs about half a second of CPU. With one worker, a cheap request that arrives meanwhile waits for it (median 168 ms instead of well under 1 ms); two workers bring it down to about a third (60 ms). Plan for `SPINEL_WORKERS=2` or more.
- Forty card additions fired 20 at a time left 40 rows with 40 distinct positions (no lost update in this run; `next_position` reads and then writes, so it is not guaranteed in general).
- Memory: 8.7 MB at start, 14 MB after 6,000 requests, 12 MB after 26,000 (one worker); 12.5 MB at start and 17.9 MB after 26,000 with two. No growth that looks like a leak over that many requests.
- One run of `ab` reported 6 failed requests out of 3,000 on `GET /login`; the server logged no error, and two later runs of the same test had none. The cause is not known.

## What it showed about the stack

- **Template and controller code must avoid a few things.** `Array#index` with a column value did not compile (a loop over string comparisons does); inside a `DB.with` block `self` is not the controller, so `request`, `ctx` and `params` must be read into locals first.
- **OpenSSL cannot live in the web binary** ([CyberTrain#27](https://github.com/saeki-mototsune/CyberTrain/issues/27)): the mail worker is a separate program for that reason.
- **Test-harness class variables** can share an array with the router after a garbage collection ([CyberTrain#26](https://github.com/saeki-mototsune/CyberTrain/issues/26)); not relevant to the running application.
- The scaffold's generated controllers have no ownership checks; the ones here are hand-written with `Board.where(user_id: ...)`. Nothing in the framework enforces it, so every query has to remember it.

## Not checked

- A real SMTP provider (only Mailpit), and the TLS paths of the mail worker beyond what cybertrain-postal's own tests cover.
- Behind a TLS reverse proxy (session cookies are `Secure` in production; `curl` accepted them over plain `http://127.0.0.1`).
- More than one machine, a long soak test, or load from many clients; the numbers above are one laptop talking to itself.
- A security review.
