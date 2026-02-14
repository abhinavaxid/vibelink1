# VibeLink Database Schema (PostgreSQL)

## Core Tables

### 1. **users** - User profiles and authentication
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    avatar VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Index for fast lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

### 2. **user_profiles** - Extended user personality data
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    -- Personality Traits (JSON for flexibility)
    personality_traits JSONB DEFAULT '{}',
    -- Example: {"nightOwl": true, "texter": false, "introvert": true}
    
    -- Vibe Characteristics
    communication_style VARCHAR(50), -- direct, diplomatic, humorous, empathetic
    energy_level VARCHAR(50), -- high, medium, low
    response_speed VARCHAR(50), -- quick, moderate, thoughtful
    
    interests TEXT[], -- Array of interests
    location VARCHAR(255),
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_interests ON user_profiles USING GIN(interests);
```

### 3. **rooms** - Connection rooms
```sql
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_type VARCHAR(50) NOT NULL, -- friendship, collaborators, mentorship, travel, gamers, love-connection
    name VARCHAR(255) NOT NULL,
    description TEXT,
    max_participants INT DEFAULT 8,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rooms_type ON rooms(room_type);
CREATE INDEX idx_rooms_active ON rooms(is_active);
```

### 4. **game_sessions** - Active/completed game sessions
```sql
CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL, -- lobby, playing, completed, cancelled
    current_round INT DEFAULT 0,
    game_state VARCHAR(50), -- questions, synergy, blindChat, humor, results
    
    -- Participants
    participant_ids UUID[] NOT NULL, -- Array of user IDs
    
    -- Timing
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}', -- Store any round-specific data
    
    CONSTRAINT session_has_participants CHECK (array_length(participant_ids, 1) > 0)
);

CREATE INDEX idx_sessions_room_id ON game_sessions(room_id);
CREATE INDEX idx_sessions_status ON game_sessions(status);
CREATE INDEX idx_sessions_created_at ON game_sessions(created_at DESC);
CREATE INDEX idx_sessions_participants ON game_sessions USING GIN(participant_ids);
```

### 5. **round_responses** - Individual responses per round
```sql
CREATE TABLE round_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    round_type VARCHAR(50), -- questions, synergy, blindChat, humor
    
    response_text TEXT,
    response_data JSONB, -- Store complex responses (ratings, choices, etc)
    
    -- Scoring
    raw_score INT DEFAULT 0,
    sentiment_score FLOAT, -- -1 to 1 (from NLP analysis)
    empathy_score FLOAT, -- 0 to 1
    energy_level INT, -- 1 to 5
    
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(game_session_id, user_id, round_number)
);

CREATE INDEX idx_responses_session_id ON round_responses(game_session_id);
CREATE INDEX idx_responses_user_id ON round_responses(user_id);
CREATE INDEX idx_responses_round ON round_responses(round_number);
```

### 6. **matches** - Connection matches/compatibility scores
```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Scoring
    connection_score INT, -- 0-100
    compatibility_breakdown JSONB, -- {communication: 85, humor: 90, teamwork: 75}
    match_strength VARCHAR(50), -- perfect, excellent, good, fair
    
    -- Tags/Categories
    match_tags TEXT[], -- ['Humor Match 😂', 'Team Chemistry', 'Deep Thinker']
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure no duplicate matches
    UNIQUE(game_session_id, LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)),
    -- Ensure user1_id < user2_id for consistency
    CHECK (user1_id < user2_id)
);

CREATE INDEX idx_matches_session_id ON matches(game_session_id);
CREATE INDEX idx_matches_user1_id ON matches(user1_id);
CREATE INDEX idx_matches_user2_id ON matches(user2_id);
CREATE INDEX idx_matches_score ON matches(connection_score DESC);
```

### 7. **connection_history** - Tracks all connections between users
```sql
CREATE TABLE connection_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    total_match_count INT DEFAULT 1,
    average_score INT DEFAULT 0,
    last_matched_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id))
);

CREATE INDEX idx_connection_user1 ON connection_history(user1_id);
CREATE INDEX idx_connection_user2 ON connection_history(user2_id);
```

### 8. **audience_votes** - Audience voting for spectator mode
```sql
CREATE TABLE audience_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    voter_id UUID REFERENCES users(id) ON DELETE SET NULL, -- NULL for anonymous viewers
    
    category VARCHAR(100) NOT NULL, -- best_communicator, funniest_team, most_supportive, best_team_chemistry
    nominee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    vote_weight INT DEFAULT 1, -- Can weight votes (registered user = 2, anonymous = 1)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_votes_session_id ON audience_votes(game_session_id);
CREATE INDEX idx_votes_nominee_id ON audience_votes(nominee_id);
CREATE INDEX idx_votes_category ON audience_votes(category);
```

### 9. **meme_uploads** - User-generated memes for humor round
```sql
CREATE TABLE meme_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    meme_url VARCHAR(255) NOT NULL,
    caption TEXT NOT NULL,
    template_id VARCHAR(100), -- Reference to meme template used
    
    total_reactions INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_memes_session_id ON meme_uploads(game_session_id);
CREATE INDEX idx_memes_user_id ON meme_uploads(user_id);
```

### 10. **meme_reactions** - Reactions to memes
```sql
CREATE TABLE meme_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meme_id UUID NOT NULL REFERENCES meme_uploads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    reaction_type VARCHAR(50) NOT NULL, -- funny, genius, okay, notfunny
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(meme_id, user_id)
);

CREATE INDEX idx_reactions_meme_id ON meme_reactions(meme_id);
CREATE INDEX idx_reactions_user_id ON meme_reactions(user_id);
```

### 11. **chat_messages** - Message history for blind chat and general chat
```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    message_text TEXT NOT NULL,
    round_type VARCHAR(50), -- blindChat, general, etc
    
    -- Metadata
    sentiment_score FLOAT, -- -1 to 1 (analyzed via NLP)
    is_anonymous BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_session_id ON chat_messages(game_session_id);
CREATE INDEX idx_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_messages_timestamp ON chat_messages(created_at);
```

### 12. **user_connections** - User social graph (followers/following)
```sql
CREATE TABLE user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    status VARCHAR(50) DEFAULT 'connected', -- connected, pending, blocked
    connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_connections_follower ON user_connections(follower_id);
CREATE INDEX idx_connections_following ON user_connections(following_id);
```

### 13. **leaderboards** - Global/session leaderboards
```sql
CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    rank INT,
    score INT NOT NULL,
    matches_count INT DEFAULT 0,
    average_match_score INT DEFAULT 0,
    
    leaderboard_type VARCHAR(50), -- session, weekly, all_time
    period_start_date DATE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(game_session_id, user_id)
);

CREATE INDEX idx_leaderboards_session_id ON leaderboards(game_session_id);
CREATE INDEX idx_leaderboards_user_id ON leaderboards(user_id);
CREATE INDEX idx_leaderboards_score ON leaderboards(score DESC);
```

### 14. **analytics_events** - Track user behavior for analytics
```sql
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL, -- session_started, round_completed, user_matched, etc
    room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
    game_session_id UUID REFERENCES game_sessions(id) ON DELETE SET NULL,
    
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at);
```

---

## Key Design Principles

### ✅ **Normalization**
- 3NF compliant, minimal redundancy
- Separate personality traits into dedicated table
- Match history separated from current matches

### ✅ **Performance**
- Strategic indexes on frequently queried columns
- JSONB for flexible, queryable metadata
- Array columns for participant tracking
- Partition by game_session_id for large tables

### ✅ **Scalability**
- UUID primary keys (distributed)
- Timestamps for analytics
- Analytics table separate
- Connection history denormalized for quick access

### ✅ **Data Integrity**
- Foreign key constraints with CASCADE delete
- UNIQUE constraints for preventing duplicates
- CHECK constraints for business rules
- LEAST/GREATEST for unordered pairs

### ✅ **Real-time Features**
- Chat messages table with timestamps
- Reactions/votes with real-time counts
- Session status for live tracking

---

## Example Queries

```sql
-- Find top matches for a user in a session
SELECT 
    m.user1_id, 
    m.user2_id, 
    m.connection_score,
    m.compatibility_breakdown
FROM matches m
WHERE m.game_session_id = 'session-uuid'
ORDER BY m.connection_score DESC
LIMIT 10;

-- Get user connection stats
SELECT 
    u.username,
    COUNT(DISTINCT ch.user2_id) as total_connections,
    AVG(ch.average_score) as avg_compatibility
FROM users u
LEFT JOIN connection_history ch ON u.id = ch.user1_id OR u.id = ch.user2_id
WHERE u.id = 'user-uuid'
GROUP BY u.id, u.username;

-- Audience voting results
SELECT 
    category,
    nominee_id,
    COUNT(*) as vote_count,
    SUM(vote_weight) as weighted_votes
FROM audience_votes
WHERE game_session_id = 'session-uuid'
GROUP BY category, nominee_id
ORDER BY category, weighted_votes DESC;
```

---

## Migration Strategy

1. Create all tables in order (dependencies respected)
2. Add indexes last
3. Add sample data
4. Setup foreign key constraints
5. Enable Row Level Security (RLS) for multi-tenancy if needed
