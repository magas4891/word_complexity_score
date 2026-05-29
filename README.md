# Word Complexity Score API

Asynchronous REST API that calculates a complexity score for a list of words by analyzing their definitions, synonyms, and antonyms via the [Free Dictionary API](https://api.dictionaryapi.dev).

## Requirements

- Ruby 3.2.1
- Rails 8.1
- PostgreSQL
- Redis 6.2+
- Sidekiq 7

## Setup

```bash
bundle install
cp .env.example .env  # fill in your DB credentials
rails db:create db:migrate
```

## Running

Start the Rails server and Sidekiq worker in separate terminals:

```bash
rails server
bundle exec sidekiq
```

## API

### POST /complexity-score

Accepts a JSON array of words and enqueues a background job. Returns a `job_id` for tracking.

**Request:**
```bash
curl -X POST http://localhost:3000/complexity-score \
  -H "Content-Type: application/json" \
  -d '{"words": ["happy", "sad", "angry"]}'
```

**Response `202 Accepted`:**
```json
{ "job_id": "6702f0fc-1f46-4049-b191-6b74caa1834f" }
```

**Validation error `422 Unprocessable Entity`:**
```json
{ "error": "words must be a non-empty array" }
```

---

### GET /complexity-score/:job_id

Returns the current status and result of the job.

**Request:**
```bash
curl http://localhost:3000/complexity-score/6702f0fc-1f46-4049-b191-6b74caa1834f
```

**Response — in progress:**
```json
{ "status": "pending" }
{ "status": "in_progress" }
```

**Response — completed `200 OK`:**
```json
{
  "status": "completed",
  "result": {
    "happy": 3.0,
    "sad": 1.8,
    "angry": 4.0
  }
}
```

**Response — not found `404`:**
```json
{ "error": "Job not found" }
```

## Complexity Score Formula

```
score = (synonyms + antonyms) / definitions
```

Synonyms and antonyms are collected from both the meaning level and individual definition level of the API response.

### Key design decisions

- **Async processing** — words are processed in a background Sidekiq job so the POST endpoint returns immediately
- **Parallel HTTP** — words within a job are fetched concurrently (up to 10 threads) via the `parallel` gem
- **Idempotent job execution** — atomic `UPDATE WHERE status='pending'` prevents duplicate processing if the job is delivered twice
- **Service objects** — `DictionaryApiService` and `WordComplexityService` encapsulate external API calls and scoring logic independently of the job layer
