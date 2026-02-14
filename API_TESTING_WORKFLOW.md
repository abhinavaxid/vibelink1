# 🧪 VibeLink Backend - Complete API Testing Guide

## The Issue You're Facing

**Error:** `Validation failed` when creating game session

**Reason:** You're using placeholder UUIDs, but the API requires real UUIDs

**Solution:** Follow the workflow below to get real data first

---

## ✅ Step-by-Step: Complete Testing Workflow

### **Step 1: Register First User** ✅

**Request:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user1@vibelink.com",
    "username": "user1",
    "password": "TestPassword123!"
  }'
```

**Response (SAVE THIS):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440001",  ← COPY THIS (User 1 ID)
    "email": "user1@vibelink.com",
    "username": "user1"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",  ← COPY THIS (Token 1)
  "refreshToken": "..."
}
```

**Save for next steps:**
- User 1 ID: `550e8400-e29b-41d4-a716-446655440001`
- Token 1: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

### **Step 2: Register Second User** ✅

**Request:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user2@vibelink.com",
    "username": "user2",
    "password": "TestPassword123!"
  }'
```

**Save:**
- User 2 ID: `[copy id from response]`

---

### **Step 3: Get Available Rooms** ✅

**Request:**
```bash
curl http://localhost:5000/api/rooms
```

**Response:**
```json
{
  "data": [
    {
      "id": "6fa85f64-5717-4562-b3fc-2c963f66afa6",  ← COPY THIS (Room ID)
      "name": "Friendship Bonding",
      "description": "...",
      "type": "friendship"
    },
    ...
  ]
}
```

**Save:**
- Room ID: `6fa85f64-5717-4562-b3fc-2c963f66afa6`

---

### **Step 4: Create Game Session** ✅ (NOW THIS WILL WORK!)

**Request:**
```bash
curl -X POST http://localhost:5000/api/games/session \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "roomId": "6fa85f64-5717-4562-b3fc-2c963f66afa6",
    "participantIds": ["550e8400-e29b-41d4-a716-446655440001", "550e8400-e29b-41d4-a716-446655440002"]
  }'
```

**Replace with YOUR real data:**
- `Authorization: Bearer [YOUR_TOKEN_FROM_STEP_1]`
- `roomId`: From Step 3
- `participantIds`: [User 1 ID from Step 1, User 2 ID from Step 2]

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "session": {
      "id": "new-session-uuid",
      "roomId": "6fa85f64-5717-4562-b3fc-2c963f66afa6",
      "participantIds": ["user-1-id", "user-2-id"],
      "status": "lobby",
      "currentRound": 0,
      "createdAt": "2026-02-13T18:30:00Z"
    }
  }
}
```

**Status Code:** `201 Created` ✅

---

## 🚀 Using Postman (Recommended)

### **Setup Postman Environment Variables:**

1. Open Postman
2. Click "Environments" (left sidebar)
3. Create new environment: `VibeLink-Local`
4. Add variables:

```
VARIABLE          | INITIAL VALUE | CURRENT VALUE
─────────────────┼───────────────┼──────────────
token             | (empty)       | (auto-fill)
user1_id          | (empty)       | (auto-fill)
user2_id          | (empty)       | (auto-fill)
room_id           | (empty)       | (auto-fill)
session_id        | (empty)       | (auto-fill)
```

### **Then Use: {{token}}, {{user1_id}}, {{room_id}}, etc.**

---

## 📋 Complete Test Sequence with Real Data

Here's a PowerShell script to do it all automatically:

```powershell
# 1. Register User 1
$user1Response = Invoke-WebRequest -Uri "http://localhost:5000/api/auth/register" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{
    "email": "user1@vibelink.com",
    "username": "user1",
    "password": "TestPassword123!"
  }'

$user1Data = $user1Response.Content | ConvertFrom-Json
$user1Id = $user1Data.user.id
$token = $user1Data.token

Write-Host "✅ User 1 Created: $user1Id"
Write-Host "✅ Token: $token"

# 2. Register User 2
$user2Response = Invoke-WebRequest -Uri "http://localhost:5000/api/auth/register" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{
    "email": "user2@vibelink.com",
    "username": "user2",
    "password": "TestPassword123!"
  }'

$user2Data = $user2Response.Content | ConvertFrom-Json
$user2Id = $user2Data.user.id

Write-Host "✅ User 2 Created: $user2Id"

# 3. Get Rooms
$roomsResponse = Invoke-WebRequest -Uri "http://localhost:5000/api/rooms"
$roomsData = $roomsResponse.Content | ConvertFrom-Json
$roomId = $roomsData.data[0].id

Write-Host "✅ Room ID: $roomId"

# 4. Create Game Session
$sessionResponse = Invoke-WebRequest -Uri "http://localhost:5000/api/games/session" `
  -Method POST `
  -Headers @{
    "Content-Type"="application/json"
    "Authorization"="Bearer $token"
  } `
  -Body @{
    "roomId" = "$roomId"
    "participantIds" = @($user1Id, $user2Id)
  } | ConvertTo-Json

$sessionData = $sessionResponse.Content | ConvertFrom-Json
$sessionId = $sessionData.data.session.id

Write-Host "✅ Game Session Created: $sessionId"

# Save for next tests
Write-Host ""
Write-Host "=== SAVED FOR NEXT TESTS ==="
Write-Host "Token: $token"
Write-Host "User 1 ID: $user1Id"
Write-Host "User 2 ID: $user2Id"
Write-Host "Room ID: $roomId"
Write-Host "Session ID: $sessionId"
```

---

## 🔑 Key Learning Points

### **Validation Rules in APIs**

The API has these rules:
```typescript
body('roomId').isUUID()              // Must be valid UUID format
body('participantIds').isArray({ min: 1 })  // Must be array with ≥1 item
```

### **Valid UUID Format**
```
✅ VALID:   "550e8400-e29b-41d4-a716-446655440000"
❌ INVALID: "room-uuid"
❌ INVALID: "user-uuid-1"
❌ INVALID: "random-string"
```

### **UUID Structure**
```
550e8400-e29b-41d4-a716-446655440000
│      │ │    │ │    │ │
8 hex  4 hex  4 hex  4 hex  12 hex
```

---

## 🧪 All Test Endpoints with Real Data

Once you complete steps 1-4, you have real data to test everything:

### **1. Get Current User**
```bash
curl -H "Authorization: Bearer {{token}}" \
  http://localhost:5000/api/auth/me
```

### **2. Get User Profile**
```bash
curl http://localhost:5000/api/users/{{user1_id}}
```

### **3. List Users**
```bash
curl http://localhost:5000/api/users?page=1&pageSize=10
```

### **4. Get Game Session**
```bash
curl -H "Authorization: Bearer {{token}}" \
  http://localhost:5000/api/games/session/{{session_id}}
```

### **5. Submit Round Response**
```bash
curl -X POST http://localhost:5000/api/games/session/{{session_id}}/response \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{token}}" \
  -d '{
    "roundNumber": 1,
    "responseText": "This is my response",
    "roundType": "real-talk"
  }'
```

### **6. Get Session Leaderboard**
```bash
curl http://localhost:5000/api/games/session/{{session_id}}/leaderboard
```

### **7. Get Matches**
```bash
curl http://localhost:5000/api/matches/session/{{session_id}}
```

---

## 📊 Database Inspection

If you want to verify data is being created:

```bash
# Connect to database
docker-compose exec -T postgres psql -U vibelink -d vibelink_db

# View users
SELECT id, email, username FROM users;

# View rooms
SELECT id, name, type FROM rooms;

# View game sessions
SELECT id, room_id, status, participant_ids FROM game_sessions;

# View round responses
SELECT id, session_id, response_text, created_at FROM round_responses;

# Exit
\q
```

---

## ✅ Quick Checklist

After completing the workflow:

- [ ] User 1 registered successfully
- [ ] User 2 registered successfully
- [ ] Retrieved real room ID from database
- [ ] Created game session with real UUIDs
- [ ] Got 201 Created response
- [ ] Saved session ID for next tests
- [ ] Tested all endpoints with real data

---

## 🎯 Summary

**The key issue:** Your test data used placeholder UUIDs instead of real ones

**The solution:** Follow the 4-step workflow to get real UUIDs, then use them

**Next:** You'll have real data to test all 27 API endpoints!

Would you like me to:
1. ✅ Create a complete Postman collection with this workflow?
2. ✅ Create an automated test script?
3. ✅ Update the database with seed data automatically?
