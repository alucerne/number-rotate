# Phone Rotating API - Supabase Edge Functions

This project implements a Supabase Edge Function API for phone validation and management, migrated from the original FastAPI implementation at [alucerne/number-rotate](https://github.com/alucerne/number-rotate).

## Project Structure

```
phone_rotating_api/
├── supabase/
│   ├── functions/
│   │   ├── hello/          # Test function
│   │   ├── mark-number/    # Phone validation function
│   │   ├── next-number/    # Get next number to call
│   │   └── seed-poc/       # Seed phone candidates
│   ├── migrations/
│   │   └── 20250101000000_create_phone_tables.sql
│   └── config.toml         # Supabase configuration
├── .env                    # Environment variables
├── env.example            # Environment variables template
└── package.json           # Node.js dependencies
```

## Migration from FastAPI to Supabase Edge Functions

This project has been migrated from the original FastAPI implementation to use Supabase Edge Functions for better scalability and performance. The API maintains the same functionality but now runs on Supabase's serverless infrastructure.

### Original FastAPI Endpoints → Supabase Edge Functions

| FastAPI Endpoint | Supabase Function | Method | Purpose |
|------------------|-------------------|--------|---------|
| `/mark-number` | `/functions/v1/mark-number` | POST | Update phone candidate status |
| `/next-number` | `/functions/v1/next-number` | GET | Get next number to call |
| `/seed-poc` | `/functions/v1/seed-poc` | POST | Seed phone candidates |

## Setup Instructions

### Prerequisites

1. **Supabase CLI**: Already installed (v2.31.4)
2. **Supabase Project**: Connected to https://qfymtspwafjamwiogpft.supabase.co

### Environment Configuration

1. Copy the environment template:
   ```bash
   cp env.example .env
   ```

2. Update `.env` with your Supabase credentials:
   ```
   SUPABASE_URL=https://qfymtspwafjamwiogpft.supabase.co
   SUPABASE_ANON_KEY=your_actual_anon_key_here
   PORT=3000
   ```

   **To get your anon key:**
   - Go to your Supabase project dashboard
   - Navigate to Settings > API
   - Copy the "anon public" key

### Database Setup

1. Apply the database migration:
   ```bash
   supabase db push
   ```

   This will create the required tables:
   - `phone_candidates`
   - `validated_phones`

## API Endpoints

### 1. Mark Number (POST `/functions/v1/mark-number`)

Updates phone candidate status and optionally adds to validated phones.

**Request Body:**
```json
{
  "sha256_id": "contact-001",
  "mobile_number": "555-1234",
  "disposition": "connected_good",
  "first_name": "John",
  "last_name": "Doe",
  "source": "manual",
  "agent_id": "agent-123"
}
```

**Valid dispositions:**
- `wrong_number`, `disconnected`, `no_answer` → status: "failed"
- `connected_good`, `positive_interaction` → status: "verified"

**Response:**
```json
{
  "status": "success",
  "updated_status": "verified"
}
```

### 2. Next Number (GET `/functions/v1/next-number`)

Gets the next number to call for a contact.

**Query Parameters:**
- `sha256_id` (required): The contact identifier

**Response:**
```json
{
  "status": "candidate",
  "mobile_number": "555-1234",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Status types:**
- `verified`: Returns validated phone number
- `candidate`: Returns next untested candidate
- `404`: No numbers available

### 3. Seed POC (POST `/functions/v1/seed-poc`)

Seeds phone candidates for testing.

**Request Body:**
```json
{
  "sha256_id": "contact-001",
  "numbers": ["555-1234", "555-5678", "555-9012"],
  "first_name": "John",
  "last_name": "Doe",
  "source": "poc_source"
}
```

**Response:**
```json
{
  "status": "success",
  "inserted_count": 3
}
```

## Testing the Functions

### Local Testing (requires Docker Desktop)

```bash
# 1. Start Docker Desktop
open -a Docker

# 2. Start the functions server
supabase functions serve

# 3. Test the hello function
curl -X GET http://localhost:54321/functions/v1/hello

# 4. Test mark-number function
curl -X POST http://localhost:54321/functions/v1/mark-number \
  -H "Content-Type: application/json" \
  -d '{
    "sha256_id": "contact-001",
    "mobile_number": "555-1234",
    "disposition": "connected_good",
    "first_name": "John",
    "last_name": "Doe"
  }'

# 5. Test next-number function
curl -X GET "http://localhost:54321/functions/v1/next-number?sha256_id=contact-001"

# 6. Test seed-poc function
curl -X POST http://localhost:54321/functions/v1/seed-poc \
  -H "Content-Type: application/json" \
  -d '{
    "sha256_id": "contact-001",
    "numbers": ["555-1234", "555-5678"],
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Production Testing

Once deployed to Supabase, test against your production URL:

```bash
# Replace with your actual Supabase project URL
BASE_URL="https://qfymtspwafjamwiogpft.supabase.co/functions/v1"

# Test mark-number
curl -X POST "$BASE_URL/mark-number" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "sha256_id": "contact-001",
    "mobile_number": "555-1234",
    "disposition": "connected_good"
  }'

# Test next-number
curl -X GET "$BASE_URL/next-number?sha256_id=contact-001" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# Test seed-poc
curl -X POST "$BASE_URL/seed-poc" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "sha256_id": "contact-001",
    "numbers": ["555-1234", "555-5678"]
  }'
```

## Database Schema

### phone_candidates
- `id` (SERIAL PRIMARY KEY)
- `sha256_id` (TEXT, indexed)
- `mobile_number` (TEXT)
- `first_name` (TEXT)
- `last_name` (TEXT)
- `source` (TEXT)
- `priority_order` (INTEGER, default: 0)
- `status` (TEXT, default: 'untested')
- `last_attempted_at` (TIMESTAMP)
- `last_attempted_by` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### validated_phones
- `sha256_id` (TEXT PRIMARY KEY)
- `mobile_number` (TEXT)
- `first_name` (TEXT)
- `last_name` (TEXT)
- `wrong_number` (BOOLEAN, default: FALSE)
- `disconnected` (BOOLEAN, default: FALSE)
- `positive_interaction` (BOOLEAN, default: FALSE)
- `verified_at` (TIMESTAMP)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

## Deployment

### Deploy to Supabase

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy mark-number
supabase functions deploy next-number
supabase functions deploy seed-poc
```

### Environment Variables in Production

Set the following environment variables in your Supabase project:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anon key

## Benefits of Migration

1. **Better Scalability**: Supabase Edge Functions auto-scale based on demand
2. **Reduced Infrastructure**: No need to manage servers or containers
3. **Global Distribution**: Functions run closer to your users
4. **Integrated Database**: Direct access to Supabase PostgreSQL
5. **Cost Effective**: Pay only for actual usage

## Troubleshooting

1. **Docker not running**: Start Docker Desktop for local testing
2. **Environment variables not loaded**: Ensure `.env` file exists and has correct values
3. **Database errors**: Verify tables exist in your Supabase project
4. **CORS issues**: Functions include CORS headers for cross-origin requests
5. **Authentication errors**: Ensure you're using the correct anon key

## Original Repository

This project was migrated from: [alucerne/number-rotate](https://github.com/alucerne/number-rotate) 