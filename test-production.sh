#!/bin/bash

# Phone Rotating API Production Test Script
# Tests all Supabase Edge Functions in production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="https://qfymtspwafjamwiogpft.supabase.co/functions/v1"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmeW10c3B3YWZqYW13aW9ncGZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMjYyMzksImV4cCI6MjA2OTcwMjIzOX0.5wEhBaePqYVtUL1Lryi9PYw0ktrDW1YJCNn6Gmffmjk"
CONTACT_ID="prod-test-$(date +%s)"

echo -e "${BLUE}🧪 Testing Phone Rotating API (Production)${NC}"
echo -e "${BLUE}Base URL: $BASE_URL${NC}"
echo -e "${BLUE}Contact ID: $CONTACT_ID${NC}"
echo ""

# Function to make HTTP requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}Testing: $description${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer $ANON_KEY" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ANON_KEY" \
            -d "$data" \
            "$BASE_URL$endpoint")
    fi
    
    # Split response and status code
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✅ Success ($http_code)${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        echo -e "${RED}❌ Failed ($http_code)${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    fi
    echo ""
}

# Test 1: Hello function
make_request "GET" "/hello" "" "Hello function"

# Test 2: Seed POC data
seed_data='{
  "sha256_id": "'$CONTACT_ID'",
  "numbers": ["555-1234", "555-5678", "555-9012"],
  "first_name": "John",
  "last_name": "Doe",
  "source": "production-test"
}'
make_request "POST" "/seed-poc" "$seed_data" "Seed POC data"

# Test 3: Get next number (should return first candidate)
make_request "GET" "/next-number?sha256_id=$CONTACT_ID" "" "Get next number (first candidate)"

# Test 4: Mark number as wrong
mark_wrong='{
  "sha256_id": "'$CONTACT_ID'",
  "mobile_number": "555-1234",
  "disposition": "wrong_number",
  "first_name": "John",
  "last_name": "Doe",
  "agent_id": "prod-test-agent"
}'
make_request "POST" "/mark-number" "$mark_wrong" "Mark number as wrong"

# Test 5: Get next number (should return second candidate)
make_request "GET" "/next-number?sha256_id=$CONTACT_ID" "" "Get next number (second candidate)"

# Test 6: Mark number as verified
mark_verified='{
  "sha256_id": "'$CONTACT_ID'",
  "mobile_number": "555-5678",
  "disposition": "connected_good",
  "first_name": "John",
  "last_name": "Doe",
  "agent_id": "prod-test-agent"
}'
make_request "POST" "/mark-number" "$mark_verified" "Mark number as verified"

# Test 7: Get next number (should return verified number)
make_request "GET" "/next-number?sha256_id=$CONTACT_ID" "" "Get next number (verified number)"

# Test 8: Mark number as positive interaction
mark_positive='{
  "sha256_id": "'$CONTACT_ID'",
  "mobile_number": "555-5678",
  "disposition": "positive_interaction",
  "first_name": "John",
  "last_name": "Doe",
  "agent_id": "prod-test-agent"
}'
make_request "POST" "/mark-number" "$mark_positive" "Mark number as positive interaction"

echo -e "${GREEN}🎉 All production tests completed!${NC}"
echo -e "${BLUE}Contact ID used: $CONTACT_ID${NC}"
echo -e "${BLUE}You can check the database in your Supabase dashboard to see the test data.${NC}"
echo -e "${BLUE}Dashboard: https://supabase.com/dashboard/project/qfymtspwafjamwiogpft/table-editor${NC}" 