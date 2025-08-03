# Phone Rotating API - Production Endpoints

Your Supabase Edge Functions API is now live and ready for production use!

## Base URL
```
https://qfymtspwafjamwiogpft.supabase.co/functions/v1
```

## Authentication
All requests require the Authorization header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk
```

## API Endpoints

### 1. Hello Function (Test)
**GET** `/hello`

Simple test endpoint to verify the API is working.

**Response:**
```
Hello World
```

**cURL Example:**
```bash
curl -X GET "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/hello" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"
```

### 2. Seed POC Data
**POST** `/seed-poc`

Seed phone candidates for testing or initial setup.

**Request Body:**
```json
{
  "sha256_id": "contact-001",
  "numbers": ["555-1234", "555-5678", "555-9012"],
  "first_name": "John",
  "last_name": "Doe",
  "source": "manual"
}
```

**Response:**
```json
{
  "status": "success",
  "inserted_count": 3
}
```

**cURL Example:**
```bash
curl -X POST "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/seed-poc" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk" \
  -d '{
    "sha256_id": "contact-001",
    "numbers": ["555-1234", "555-5678", "555-9012"],
    "first_name": "John",
    "last_name": "Doe",
    "source": "manual"
  }'
```

### 3. Get Next Number
**GET** `/next-number?sha256_id={contact_id}`

Get the next number to call for a contact. Returns verified number if available, otherwise returns next untested candidate.

**Query Parameters:**
- `sha256_id` (required): The contact identifier

**Response (Verified Number):**
```json
{
  "status": "verified",
  "mobile_number": "555-1234",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (Candidate Number):**
```json
{
  "status": "candidate",
  "mobile_number": "555-5678",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (No Numbers Available):**
```json
{
  "error": "No valid or untested numbers available"
}
```

**cURL Example:**
```bash
curl -X GET "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/next-number?sha256_id=contact-001" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"
```

### 4. Mark Number
**POST** `/mark-number`

Update phone candidate status and optionally add to validated phones.

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

**Valid Dispositions:**
- `wrong_number`, `disconnected`, `no_answer` → status: "failed"
- `connected_good`, `positive_interaction` → status: "verified"

**Response:**
```json
{
  "status": "success",
  "updated_status": "verified"
}
```

**cURL Example:**
```bash
curl -X POST "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/mark-number" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk" \
  -d '{
    "sha256_id": "contact-001",
    "mobile_number": "555-1234",
    "disposition": "connected_good",
    "first_name": "John",
    "last_name": "Doe",
    "agent_id": "agent-123"
  }'
```

## Complete Workflow Example

Here's a complete workflow example:

```bash
# 1. Seed phone candidates
curl -X POST "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/seed-poc" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk" \
  -d '{
    "sha256_id": "workflow-demo",
    "numbers": ["555-1111", "555-2222", "555-3333"],
    "first_name": "Demo",
    "last_name": "User"
  }'

# 2. Get next number to call
curl -X GET "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/next-number?sha256_id=workflow-demo" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"

# 3. Mark first number as wrong
curl -X POST "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/mark-number" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk" \
  -d '{
    "sha256_id": "workflow-demo",
    "mobile_number": "555-1111",
    "disposition": "wrong_number"
  }'

# 4. Get next number (should return 555-2222)
curl -X GET "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/next-number?sha256_id=workflow-demo" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"

# 5. Mark second number as verified
curl -X POST "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/mark-number" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk" \
  -d '{
    "sha256_id": "workflow-demo",
    "mobile_number": "555-2222",
    "disposition": "connected_good"
  }'

# 6. Get next number (should return verified 555-2222)
curl -X GET "https://qfymtspwafjamwiogpft.supabase.co/functions/v1/next-number?sha256_id=workflow-demo" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"
```

## Error Responses

All endpoints return appropriate HTTP status codes and error messages:

**400 Bad Request:**
```json
{
  "error": "Missing sha256_id, mobile_number, or disposition"
}
```

**404 Not Found:**
```json
{
  "error": "No valid or untested numbers available"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Database error message"
}
```

## Dashboard Access

You can monitor your API usage and view the database in the Supabase dashboard:
- **Functions Dashboard**: https://supabase.com/dashboard/project/qfymtspwafjamwiogpft/functions
- **Database Table Editor**: https://supabase.com/dashboard/project/qfymtspwafjamwiogpft/table-editor

## Migration Complete ✅

Your API has been successfully migrated from FastAPI to Supabase Edge Functions and is now ready for production use with better scalability and performance! 