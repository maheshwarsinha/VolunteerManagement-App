-- ========================================================
-- VOLUNTEER COMMUNITY MANAGEMENT PLATFORM
-- PRODUCTION-READY POSTGRESQL + SUPABASE SCHEMA
-- WITH ROW LEVEL SECURITY (RLS) & FREE-TIER OPTIMIZATIONS
-- ========================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================================
-- 1. ENUMS
-- ========================================================
CREATE TYPE location_visibility_enum AS ENUM (
    'all_members', 
    'admins_coordinators_only', 
    'team_members_only'
);

CREATE TYPE member_role_enum AS ENUM (
    'owner', 
    'admin', 
    'coordinator', 
    'volunteer'
);

CREATE TYPE member_status_enum AS ENUM (
    'active', 
    'suspended', 
    'left'
);

CREATE TYPE request_status_enum AS ENUM (
    'pending', 
    'approved', 
    'rejected'
);

CREATE TYPE location_activity_status AS ENUM (
    'online', 
    'stale', 
    'offline'
);

CREATE TYPE attendance_status_enum AS ENUM (
    'registered', 
    'attended', 
    'cancelled'
);

-- ========================================================
-- 2. PROFILES TABLE
-- ========================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(30) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_photo_url TEXT,
    city VARCHAR(100),
    volunteer_id VARCHAR(50),
    skills TEXT[] DEFAULT '{}',
    organization VARCHAR(150),
    emergency_contact VARCHAR(50),
    location_sharing_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles (LOWER(username));

-- ========================================================
-- 3. COMMUNITIES TABLE
-- ========================================================
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url TEXT,
    code VARCHAR(15) UNIQUE NOT NULL,
    code_enabled BOOLEAN DEFAULT true,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    category VARCHAR(50) DEFAULT 'General',
    city VARCHAR(100),
    contact_info VARCHAR(150),
    requires_approval BOOLEAN DEFAULT false,
    location_visibility location_visibility_enum DEFAULT 'all_members',
    location_retention_days INT DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_communities_code ON public.communities (UPPER(code));
CREATE INDEX IF NOT EXISTS idx_communities_owner ON public.communities (owner_id);

-- ========================================================
-- 4. COMMUNITY MEMBERS TABLE
-- ========================================================
CREATE TABLE IF NOT EXISTS public.community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role member_role_enum NOT NULL DEFAULT 'volunteer',
    status member_status_enum NOT NULL DEFAULT 'active',
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_community_user UNIQUE(community_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_comm_members_comm_id ON public.community_members (community_id);
CREATE INDEX IF NOT EXISTS idx_comm_members_user_id ON public.community_members (user_id);

-- ========================================================
-- 5. JOIN REQUESTS TABLE
-- ========================================================
CREATE TABLE IF NOT EXISTS public.join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status request_status_enum DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES public.profiles(id),
    CONSTRAINT uq_join_request UNIQUE(community_id, user_id, status)
);

CREATE INDEX IF NOT EXISTS idx_join_requests_comm ON public.join_requests (community_id, status);

-- ========================================================
-- 6. TEAMS & TEAM MEMBERS
-- ========================================================
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    description TEXT,
    leader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_team_comm_name UNIQUE(community_id, name)
);

CREATE INDEX IF NOT EXISTS idx_teams_community ON public.teams (community_id);

CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_team_member UNIQUE(team_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_team_members_team ON public.team_members (team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON public.team_members (user_id);

-- ========================================================
-- 7. LIVE LOCATIONS (Single-row state per member/community)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.locations_live (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    battery_level INT,
    status location_activity_status DEFAULT 'online',
    last_updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY(user_id, community_id)
);

CREATE INDEX IF NOT EXISTS idx_locations_live_comm ON public.locations_live (community_id);
CREATE INDEX IF NOT EXISTS idx_locations_live_updated ON public.locations_live (last_updated_at);

-- ========================================================
-- 8. LOCATION SNAPSHOTS (5-minute History Archive)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.location_snapshots (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_snapshots_comm_time ON public.location_snapshots (community_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_snapshots_user_time ON public.location_snapshots (user_id, recorded_at DESC);

-- ========================================================
-- 9. EVENTS & ATTENDANCE
-- ========================================================
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    venue_name VARCHAR(150) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    image_url TEXT,
    qr_code_token VARCHAR(64) UNIQUE,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_events_community ON public.events (community_id, start_time);

CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status attendance_status_enum DEFAULT 'registered',
    check_in_time TIMESTAMPTZ,
    check_in_lat DOUBLE PRECISION,
    check_in_lon DOUBLE PRECISION,
    verified_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_event_user_att UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_event ON public.attendance (event_id);

-- ========================================================
-- 10. ANNOUNCEMENTS & AUDIT LOGS
-- ========================================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal',
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_announcements_comm ON public.announcements (community_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id BIGSERIAL PRIMARY KEY,
    community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id),
    action VARCHAR(60) NOT NULL,
    target_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_audit_comm ON public.audit_logs (community_id, created_at DESC);

-- ========================================================
-- 11. HELPER FUNCTIONS FOR ROW LEVEL SECURITY (RLS)
-- ========================================================
CREATE OR REPLACE FUNCTION public.is_community_member(cid UUID)
RETURNS BOOLEAN SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = cid
          AND user_id = auth.uid()
          AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.is_community_admin(cid UUID)
RETURNS BOOLEAN SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = cid
          AND user_id = auth.uid()
          AND role IN ('owner', 'admin')
          AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.shares_team(cid UUID, other_user UUID)
RETURNS BOOLEAN SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.team_members tm1
        JOIN public.teams t ON tm1.team_id = t.id
        JOIN public.team_members tm2 ON tm2.team_id = t.id
        WHERE t.community_id = cid
          AND tm1.user_id = auth.uid()
          AND tm2.user_id = other_user
    );
END;
$$ LANGUAGE plpgsql;

-- ========================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations_live ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Can read profile of self or fellow community members
CREATE POLICY "Profiles readable by self or community peers"
ON public.profiles FOR SELECT USING (
    id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.community_members cm1
        JOIN public.community_members cm2 ON cm1.community_id = cm2.community_id
        WHERE cm1.user_id = auth.uid() AND cm2.user_id = public.profiles.id
    )
);

CREATE POLICY "Profiles updatable by self"
ON public.profiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Profiles insertable on signup"
ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());

-- Communities: readable if member OR looking up by code
CREATE POLICY "Communities readable by members or code search"
ON public.communities FOR SELECT USING (
    public.is_community_member(id)
    OR code_enabled = true
);

CREATE POLICY "Communities creatable by authenticated users"
ON public.communities FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Communities updatable by admin"
ON public.communities FOR UPDATE USING (public.is_community_admin(id));

-- Community Members: readable by community members
CREATE POLICY "Community members readable by fellow members"
ON public.community_members FOR SELECT USING (
    public.is_community_member(community_id)
);

CREATE POLICY "Community members insertable by self or admin"
ON public.community_members FOR INSERT WITH CHECK (
    user_id = auth.uid() OR public.is_community_admin(community_id)
);

CREATE POLICY "Community members updatable by admin"
ON public.community_members FOR UPDATE USING (
    public.is_community_admin(community_id)
);

CREATE POLICY "Community members deletable by self or admin"
ON public.community_members FOR DELETE USING (
    user_id = auth.uid() OR public.is_community_admin(community_id)
);

-- Live Locations: strictly protected
CREATE POLICY "Live locations viewable only to authorized community members"
ON public.locations_live FOR SELECT USING (
    user_id = auth.uid()
    OR (
        public.is_community_member(community_id)
        AND EXISTS (SELECT 1 FROM public.profiles WHERE id = locations_live.user_id AND location_sharing_enabled = true)
        AND (
            (SELECT location_visibility FROM public.communities WHERE id = locations_live.community_id) = 'all_members'
            OR (
                (SELECT location_visibility FROM public.communities WHERE id = locations_live.community_id) = 'admins_coordinators_only'
                AND EXISTS (
                    SELECT 1 FROM public.community_members
                    WHERE community_id = locations_live.community_id
                      AND user_id = auth.uid()
                      AND role IN ('owner', 'admin', 'coordinator')
                )
            )
            OR (
                (SELECT location_visibility FROM public.communities WHERE id = locations_live.community_id) = 'team_members_only'
                AND (
                    public.is_community_admin(community_id)
                    OR public.shares_team(community_id, locations_live.user_id)
                )
            )
        )
    )
);

CREATE POLICY "Live locations writable by self member"
ON public.locations_live FOR ALL USING (
    user_id = auth.uid() AND public.is_community_member(community_id)
);

-- Events & Announcements
CREATE POLICY "Events readable by community members"
ON public.events FOR SELECT USING (public.is_community_member(community_id));

CREATE POLICY "Events writable by community coordinators & admins"
ON public.events FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = events.community_id
          AND user_id = auth.uid()
          AND role IN ('owner', 'admin', 'coordinator')
    )
);

CREATE POLICY "Announcements readable by community members"
ON public.announcements FOR SELECT USING (public.is_community_member(community_id));

CREATE POLICY "Announcements writable by coordinators & admins"
ON public.announcements FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = announcements.community_id
          AND user_id = auth.uid()
          AND role IN ('owner', 'admin', 'coordinator')
    )
);

-- ========================================================
-- 13. REALTIME REPLICATION CONFIGURATION
-- ========================================================
-- Add key tables to supabase_realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.locations_live;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.community_members;
