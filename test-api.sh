#!/bin/bash

# Phone Rotating API Test Script
# Tests all Supabase Edge Functions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL=${1:-"http://localhost:54321/functions/v1"}
CONTACT_ID="test-contact-$(date +%s)"

echo -e "${BLUE}🧪 Testing Phone Rotating API${NC}"
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
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
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
  "source": "test"
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
  "agent_id": "test-agent"
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
  "agent_id": "test-agent"
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
  "agent_id": "test-agent"
}'
make_request "POST" "/mark-number" "$mark_positive" "Mark number as positive interaction"

# Test 9: Test error handling - missing parameters
make_request "POST" "/mark-number" '{"sha256_id": "test"}' "Error handling - missing parameters"

# Test 10: Test error handling - invalid disposition
invalid_disposition='{
  "sha256_id": "'$CONTACT_ID'",
  "mobile_number": "555-9999",
  "disposition": "invalid_disposition"
}'
make_request "POST" "/mark-number" "$invalid_disposition" "Error handling - invalid disposition"

# Test 11: Test error handling - missing sha256_id
make_request "GET" "/next-number" "" "Error handling - missing sha256_id"

echo -e "${GREEN}🎉 All tests completed!${NC}"
echo -e "${BLUE}Contact ID used: $CONTACT_ID${NC}"
echo -e "${BLUE}You can check the database to see the test data.${NC}" 