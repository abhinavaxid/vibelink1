# VibeLink Backend - UAT Test Plan

## Test Environment
- **Backend URL:** http://localhost:5000
- **WebSocket URL:** ws://localhost:4000
- **Database:** PostgreSQL (Docker)
- **Date:** February 13, 2026

---

## 🔐 Authentication Tests

### Test AU-001: User Registration
- **Endpoint:** POST /api/auth/register
- **Input:**
  ```json
  {
    "email": "testuser@vibelink.com",
    "username": "testuser123",
    "password": "StrongPass123!"
  }
  ```
- **Expected:** 201 Created with user object and token
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test AU-002: User Login
- **Endpoint:** POST /api/auth/login
- **Input:**
  ```json
  {
    "email": "testuser@vibelink.com",
    "password": "StrongPass123!"
  }
  ```
- **Expected:** 200 OK with tokens
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test AU-003: Get Current User
- **Endpoint:** GET /api/auth/me
- **Headers:** Authorization: Bearer {token}
- **Expected:** 200 OK with user profile
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test AU-004: Duplicate Email Registration
- **Endpoint:** POST /api/auth/register (with existing email)
- **Expected:** 409 Conflict error
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test AU-005: Invalid Password
- **Endpoint:** POST /api/auth/login (wrong password)
- **Expected:** 401 Unauthorized
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 👥 User Management Tests

### Test US-001: List Users with Pagination
- **Endpoint:** GET /api/users?page=1&pageSize=10
- **Expected:** 200 OK with users array and total count
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test US-002: Search Users
- **Endpoint:** GET /api/users/search?q=testuser
- **Expected:** 200 OK with matching users
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test US-003: Get User Profile
- **Endpoint:** GET /api/users/{userId}
- **Expected:** 200 OK with user details
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test US-004: Update User Profile
- **Endpoint:** PATCH /api/users/{userId}
- **Headers:** Authorization: Bearer {token}
- **Input:**
  ```json
  {
    "bio": "Updated bio",
    "avatar": "https://example.com/avatar.jpg"
  }
  ```
- **Expected:** 200 OK with updated user
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test US-005: User Not Found
- **Endpoint:** GET /api/users/nonexistent-id
- **Expected:** 404 Not Found
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 🎮 Game Session Tests

### Test GM-001: Create Game Session
- **Endpoint:** POST /api/games/session
- **Headers:** Authorization: Bearer {token}
- **Input:**
  ```json
  {
    "roomId": "room-uuid-here",
    "participantIds": ["user-uuid-1", "user-uuid-2"]
  }
  ```
- **Expected:** 201 Created with session details
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test GM-002: Get Game Session
- **Endpoint:** GET /api/games/session/{sessionId}
- **Expected:** 200 OK with session data
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test GM-003: Update Game Session
- **Endpoint:** PATCH /api/games/session/{sessionId}
- **Headers:** Authorization: Bearer {token}
- **Input:**
  ```json
  {
    "status": "playing",
    "currentRound": 1
  }
  ```
- **Expected:** 200 OK with updated session
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test GM-004: Get Session Leaderboard
- **Endpoint:** GET /api/games/session/{sessionId}/leaderboard
- **Expected:** 200 OK with ranked players
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test GM-005: Submit Round Response
- **Endpoint:** POST /api/games/session/{sessionId}/response
- **Headers:** Authorization: Bearer {token}
- **Input:**
  ```json
  {
    "roundNumber": 1,
    "responseText": "Sample response",
    "roundType": "real-talk"
  }
  ```
- **Expected:** 201 Created with response stored
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 🏠 Room Management Tests

### Test RM-001: List All Rooms
- **Endpoint:** GET /api/rooms
- **Expected:** 200 OK with rooms array
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test RM-002: Get Room Details
- **Endpoint:** GET /api/rooms/{roomId}
- **Expected:** 200 OK with room information
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test RM-003: Get Room Active Sessions
- **Endpoint:** GET /api/rooms/{roomId}/sessions
- **Expected:** 200 OK with active sessions
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test RM-004: Get Room Statistics
- **Endpoint:** GET /api/rooms/stats/overview
- **Expected:** 200 OK with aggregated stats
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 💑 Match Tests

### Test MT-001: Get Session Matches
- **Endpoint:** GET /api/matches/session/{sessionId}
- **Expected:** 200 OK with calculated matches
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test MT-002: Get User Matches
- **Endpoint:** GET /api/matches/user/{userId}
- **Headers:** Authorization: Bearer {token}
- **Expected:** 200 OK with top matches
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test MT-003: Get Match History
- **Endpoint:** GET /api/matches/user/{userId}/with/{otherUserId}
- **Expected:** 200 OK with match history
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test MT-004: Get Recommendations
- **Endpoint:** GET /api/matches/explore
- **Expected:** 200 OK with recommended matches
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test MT-005: Global Leaderboard
- **Endpoint:** GET /api/matches/leaderboard
- **Expected:** 200 OK with ranked users
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 🔌 WebSocket Tests

### Test WS-001: Connect to WebSocket
- **Endpoint:** ws://localhost:4000
- **Expected:** Connection established
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test WS-002: Join Session Event
- **Event:** join-session
- **Payload:** `{ "sessionId": "uuid-here" }`
- **Expected:** Success callback + user-joined broadcast
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test WS-003: Start Game Event
- **Event:** start-game
- **Expected:** Game-started broadcast to all participants
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test WS-004: Submit Response Event
- **Event:** submit-response
- **Payload:** `{ "roundNumber": 1, "responseText": "answer" }`
- **Expected:** Response stored + response-submitted broadcast
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test WS-005: Message Broadcasting
- **Event:** send-message
- **Payload:** `{ "text": "Hello team!" }`
- **Expected:** new-message broadcast to room
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## ⚠️ Error Handling Tests

### Test ER-001: Missing Required Fields
- **Endpoint:** POST /api/auth/register (missing email)
- **Expected:** 422 Validation error
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test ER-002: Invalid Email Format
- **Endpoint:** POST /api/auth/register (invalid email)
- **Expected:** 422 Validation error
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test ER-003: Weak Password
- **Endpoint:** POST /api/auth/register (password too short)
- **Expected:** 422 Validation error
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test ER-004: Unauthorized Access
- **Endpoint:** POST /api/games/session (no auth token)
- **Expected:** 401 Unauthorized
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test ER-005: Database Connection Error Handling
- **Action:** Stop PostgreSQL container, try API call
- **Expected:** 500 error with friendly message
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 📈 Performance Tests

### Test PF-001: Response Time - List Users
- **Endpoint:** GET /api/users
- **Metric:** Response time < 500ms
- **Result:** _______ ms [ ] Pass [ ] Fail

### Test PF-002: Response Time - Get Game Session
- **Endpoint:** GET /api/games/session/{sessionId}
- **Metric:** Response time < 300ms
- **Result:** _______ ms [ ] Pass [ ] Fail

### Test PF-003: Concurrent Connections
- **Test:** 10 simultaneous WebSocket connections
- **Expected:** All connections established
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

### Test PF-004: Rate Limiting
- **Test:** Send 150 requests in 15 seconds
- **Expected:** Requests > 100 get 429 Too Many Requests
- **Status:** [ ] Pass [ ] Fail [ ] Notes: _______

---

## 📋 Summary

| Category | Total | Pass | Fail | Notes |
|----------|-------|------|------|-------|
| Authentication | 5 | ___ | ___ | |
| Users | 5 | ___ | ___ | |
| Games | 5 | ___ | ___ | |
| Rooms | 4 | ___ | ___ | |
| Matches | 5 | ___ | ___ | |
| WebSocket | 5 | ___ | ___ | |
| Errors | 5 | ___ | ___ | |
| Performance | 4 | ___ | ___ | |
| **TOTAL** | **38** | ___ | ___ | |

---

## ✅ Sign-Off

- **Tested By:** _______________________
- **Date:** February 13, 2026
- **Status:** [ ] All Pass [ ] Some Fail [ ] Pending
- **Comments:** 

_____________________________________________________________________________

_____________________________________________________________________________

