-- Reconstructed legacy schema through 016A, captured 2026-10-18.

-- Fresh Supabase database ONLY. Not a historical sequence of migrations.

-- Apply before migrations 017 onward. Contains no production/test user data.

begin;

do $$ begin if to_regclass('public.organizations') is not null then raise exception 'Legacy baseline requires an empty application schema'; end if; end; $$;

set local search_path = public, extensions;

set local check_function_bodies = off;

create schema if not exists extensions;

create extension if not exists pgcrypto with schema extensions;

create table public."cricket_innings" (
  "id" uuid default gen_random_uuid() not null,
  "match_id" uuid not null,
  "team_id" uuid not null,
  "innings_number" integer not null,
  "runs" integer not null,
  "wickets" integer default 0 not null,
  "balls_faced" integer not null,
  "max_balls" integer not null,
  "all_out" boolean default false not null,
  "declared" boolean default false not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."cricket_innings" enable row level security;

create table public."divisions" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "name" text not null,
  "description" text,
  "competition_type" text default 'TEAM'::text not null,
  "min_participants" integer,
  "max_participants" integer,
  "status" text default 'ACTIVE'::text not null,
  "sort_order" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."divisions" enable row level security;

create table public."event_staff_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "user_id" uuid not null,
  "staff_role" text not null,
  "status" text default 'ASSIGNED'::text not null,
  "notes" text,
  "assigned_at" timestamp with time zone default now() not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."event_staff_assignments" enable row level security;

create table public."events" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "sport_id" uuid not null,
  "venue_id" uuid,
  "event_name" text not null,
  "description" text,
  "event_type" text default 'TOURNAMENT'::text not null,
  "start_date" date not null,
  "end_date" date not null,
  "registration_open_at" timestamp with time zone,
  "registration_close_at" timestamp with time zone,
  "registration_type" text not null,
  "max_teams" integer,
  "max_participants" integer,
  "min_team_size" integer,
  "max_team_size" integer,
  "registration_fee" numeric(10,2) default 0 not null,
  "currency" text default 'USD'::text not null,
  "pricing_model" text default 'PER_TEAM'::text not null,
  "format" text,
  "status" text default 'DRAFT'::text not null,
  "rules_url" text,
  "banner_url" text,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."events" enable row level security;

create table public."group_members" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid not null,
  "team_id" uuid not null,
  "seed_number" integer,
  "position" integer,
  "status" text default 'ACTIVE'::text not null,
  "created_at" timestamp with time zone default now() not null
);

alter table public."group_members" enable row level security;

create table public."groups" (
  "id" uuid default gen_random_uuid() not null,
  "division_id" uuid not null,
  "name" text not null,
  "group_type" text default 'ROUND_ROBIN'::text not null,
  "sort_order" integer default 0 not null,
  "status" text default 'ACTIVE'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."groups" enable row level security;

create table public."match_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "match_id" uuid not null,
  "user_id" uuid not null,
  "assignment_role" text not null,
  "status" text default 'ASSIGNED'::text not null,
  "assigned_at" timestamp with time zone default now() not null
);

alter table public."match_assignments" enable row level security;

create table public."match_results" (
  "id" uuid default gen_random_uuid() not null,
  "match_id" uuid not null,
  "winner_team_id" uuid,
  "loser_team_id" uuid,
  "result_type" text not null,
  "result_summary" text,
  "home_points" numeric(10,2),
  "away_points" numeric(10,2),
  "verified" boolean default false not null,
  "verified_by" uuid,
  "verified_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."match_results" enable row level security;

create table public."matches" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "division_id" uuid,
  "group_id" uuid,
  "match_number" integer,
  "match_code" text,
  "stage" text default 'GROUP'::text not null,
  "round_number" integer,
  "home_team_id" uuid,
  "away_team_id" uuid,
  "playing_area_id" uuid,
  "scheduled_start" timestamp with time zone,
  "scheduled_end" timestamp with time zone,
  "actual_start" timestamp with time zone,
  "actual_end" timestamp with time zone,
  "status" text default 'SCHEDULED'::text not null,
  "winner_team_id" uuid,
  "result_status" text default 'PENDING'::text not null,
  "notes" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "home_source_type" text,
  "home_source_ref" text,
  "away_source_type" text,
  "away_source_ref" text
);

alter table public."matches" enable row level security;

create table public."organizations" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "slug" text not null,
  "logo_url" text,
  "country" text,
  "timezone" text default 'America/Chicago'::text not null,
  "status" text default 'ACTIVE'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."organizations" enable row level security;

create table public."payments" (
  "id" uuid default gen_random_uuid() not null,
  "registration_id" uuid,
  "event_id" uuid not null,
  "team_id" uuid,
  "user_id" uuid,
  "provider" text not null,
  "provider_transaction_id" text,
  "amount" numeric(10,2) not null,
  "currency" text default 'USD'::text not null,
  "payment_type" text default 'REGISTRATION'::text not null,
  "payment_status" text default 'PENDING'::text not null,
  "paid_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."payments" enable row level security;

create table public."playing_areas" (
  "id" uuid default gen_random_uuid() not null,
  "venue_id" uuid not null,
  "name" text not null,
  "area_type" text not null,
  "active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

alter table public."playing_areas" enable row level security;

create table public."profiles" (
  "id" uuid not null,
  "first_name" text,
  "last_name" text,
  "phone" text,
  "photo_url" text,
  "date_of_birth" date,
  "gender" text,
  "city" text,
  "state" text,
  "country" text,
  "emergency_contact_name" text,
  "emergency_contact_phone" text,
  "account_status" text default 'ACTIVE'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."profiles" enable row level security;

create table public."registrations" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "user_id" uuid,
  "team_id" uuid,
  "registration_type" text not null,
  "registration_status" text default 'DRAFT'::text not null,
  "waiver_status" text default 'PENDING'::text not null,
  "payment_status" text default 'PENDING'::text not null,
  "amount_due" numeric(10,2) default 0 not null,
  "amount_paid" numeric(10,2) default 0 not null,
  "registered_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."registrations" enable row level security;

create table public."sports" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "sport_type" text,
  "participation_type" text not null,
  "scoring_type" text,
  "active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

alter table public."sports" enable row level security;

create table public."standings" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid not null,
  "team_id" uuid not null,
  "played" integer default 0 not null,
  "won" integer default 0 not null,
  "lost" integer default 0 not null,
  "tied" integer default 0 not null,
  "no_result" integer default 0 not null,
  "points" numeric(10,2) default 0 not null,
  "runs_for" integer default 0 not null,
  "balls_faced" integer default 0 not null,
  "runs_against" integer default 0 not null,
  "balls_bowled" integer default 0 not null,
  "net_run_rate" numeric(10,4) default 0 not null,
  "rank" integer,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."standings" enable row level security;

create table public."team_members" (
  "id" uuid default gen_random_uuid() not null,
  "team_id" uuid not null,
  "user_id" uuid not null,
  "team_role" text default 'PLAYER'::text not null,
  "jersey_number" text,
  "playing_role" text,
  "status" text default 'ACTIVE'::text not null,
  "invitation_status" text default 'PENDING'::text not null,
  "waiver_status" text default 'PENDING'::text not null,
  "joined_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."team_members" enable row level security;

create table public."teams" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "team_name" text not null,
  "team_code" text,
  "identity_type" text,
  "identity_name" text,
  "logo_url" text,
  "captain_user_id" uuid,
  "manager_user_id" uuid,
  "registration_status" text default 'DRAFT'::text not null,
  "payment_status" text default 'NOT_REQUIRED'::text not null,
  "approval_status" text default 'PENDING'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."teams" enable row level security;

create table public."user_roles" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "organization_id" uuid not null,
  "role" text not null,
  "status" text default 'ACTIVE'::text not null,
  "assigned_at" timestamp with time zone default now() not null,
  "event_id" uuid,
  "team_id" uuid
);

alter table public."user_roles" enable row level security;

create table public."venues" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "name" text not null,
  "address_line1" text,
  "address_line2" text,
  "city" text,
  "state" text,
  "postal_code" text,
  "country" text default 'USA'::text not null,
  "latitude" numeric(9,6),
  "longitude" numeric(9,6),
  "timezone" text default 'America/Chicago'::text not null,
  "contact_name" text,
  "contact_phone" text,
  "active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

alter table public."venues" enable row level security;

create table public."waiver_acceptances" (
  "id" uuid default gen_random_uuid() not null,
  "waiver_id" uuid not null,
  "user_id" uuid not null,
  "registration_id" uuid,
  "accepted_at" timestamp with time zone default now() not null,
  "ip_address" inet,
  "user_agent" text
);

alter table public."waiver_acceptances" enable row level security;

create table public."waivers" (
  "id" uuid default gen_random_uuid() not null,
  "event_id" uuid not null,
  "version" integer default 1 not null,
  "title" text not null,
  "waiver_text" text not null,
  "effective_at" timestamp with time zone default now() not null,
  "active" boolean default true not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);

alter table public."waivers" enable row level security;

alter table public."cricket_innings" add constraint "cricket_innings_balls_faced_check" CHECK (balls_faced > 0);

alter table public."cricket_innings" add constraint "cricket_innings_innings_number_check" CHECK (innings_number = ANY (ARRAY[1, 2]));

alter table public."cricket_innings" add constraint "cricket_innings_match_id_innings_number_key" UNIQUE (match_id, innings_number);

alter table public."cricket_innings" add constraint "cricket_innings_match_id_team_id_key" UNIQUE (match_id, team_id);

alter table public."cricket_innings" add constraint "cricket_innings_max_balls_check" CHECK (max_balls > 0);

alter table public."cricket_innings" add constraint "cricket_innings_pkey" PRIMARY KEY (id);

alter table public."cricket_innings" add constraint "cricket_innings_runs_check" CHECK (runs >= 0);

alter table public."cricket_innings" add constraint "cricket_innings_wickets_check" CHECK (wickets >= 0 AND wickets <= 10);

alter table public."matches" add constraint "different_match_teams" CHECK (home_team_id IS NULL OR away_team_id IS NULL OR home_team_id <> away_team_id);

alter table public."match_results" add constraint "different_result_teams" CHECK (winner_team_id IS NULL OR loser_team_id IS NULL OR winner_team_id <> loser_team_id);

alter table public."divisions" add constraint "divisions_competition_type_check" CHECK (competition_type = ANY (ARRAY['TEAM'::text, 'INDIVIDUAL'::text]));

alter table public."divisions" add constraint "divisions_event_id_name_key" UNIQUE (event_id, name);

alter table public."divisions" add constraint "divisions_max_participants_check" CHECK (max_participants IS NULL OR max_participants >= 1);

alter table public."divisions" add constraint "divisions_min_participants_check" CHECK (min_participants IS NULL OR min_participants >= 1);

alter table public."divisions" add constraint "divisions_pkey" PRIMARY KEY (id);

alter table public."divisions" add constraint "divisions_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text]));

alter table public."event_staff_assignments" add constraint "event_staff_assignments_event_id_user_id_staff_role_key" UNIQUE (event_id, user_id, staff_role);

alter table public."event_staff_assignments" add constraint "event_staff_assignments_pkey" PRIMARY KEY (id);

alter table public."event_staff_assignments" add constraint "event_staff_assignments_staff_role_check" CHECK (staff_role = ANY (ARRAY['UMPIRE'::text, 'REFEREE'::text, 'SCORER'::text, 'ARBITER'::text, 'MARSHAL'::text, 'CHECK_IN'::text, 'VOLUNTEER'::text, 'EVENT_MANAGER'::text, 'OTHER'::text]));

alter table public."event_staff_assignments" add constraint "event_staff_assignments_status_check" CHECK (status = ANY (ARRAY['ASSIGNED'::text, 'CONFIRMED'::text, 'DECLINED'::text, 'COMPLETED'::text, 'CANCELLED'::text]));

alter table public."events" add constraint "events_event_type_check" CHECK (event_type = ANY (ARRAY['TOURNAMENT'::text, 'LEAGUE'::text, 'SOCIAL'::text, 'OTHER'::text]));

alter table public."events" add constraint "events_pkey" PRIMARY KEY (id);

alter table public."events" add constraint "events_pricing_model_check" CHECK (pricing_model = ANY (ARRAY['PER_TEAM'::text, 'PER_PLAYER'::text, 'FREE'::text]));

alter table public."events" add constraint "events_registration_type_check" CHECK (registration_type = ANY (ARRAY['TEAM'::text, 'INDIVIDUAL'::text, 'BOTH'::text]));

alter table public."events" add constraint "events_status_check" CHECK (status = ANY (ARRAY['DRAFT'::text, 'PUBLISHED'::text, 'REGISTRATION_OPEN'::text, 'REGISTRATION_CLOSED'::text, 'IN_PROGRESS'::text, 'COMPLETED'::text, 'CANCELLED'::text]));

alter table public."group_members" add constraint "group_members_group_id_team_id_key" UNIQUE (group_id, team_id);

alter table public."group_members" add constraint "group_members_pkey" PRIMARY KEY (id);

alter table public."group_members" add constraint "group_members_position_check" CHECK ("position" IS NULL OR "position" > 0);

alter table public."group_members" add constraint "group_members_seed_number_check" CHECK (seed_number IS NULL OR seed_number > 0);

alter table public."group_members" add constraint "group_members_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'WITHDRAWN'::text, 'DISQUALIFIED'::text]));

alter table public."groups" add constraint "groups_division_id_name_key" UNIQUE (division_id, name);

alter table public."groups" add constraint "groups_group_type_check" CHECK (group_type = ANY (ARRAY['ROUND_ROBIN'::text, 'POOL'::text, 'KNOCKOUT'::text, 'OTHER'::text]));

alter table public."groups" add constraint "groups_pkey" PRIMARY KEY (id);

alter table public."groups" add constraint "groups_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'COMPLETED'::text]));

alter table public."match_assignments" add constraint "match_assignments_assignment_role_check" CHECK (assignment_role = ANY (ARRAY['UMPIRE'::text, 'REFEREE'::text, 'SCORER'::text, 'ARBITER'::text, 'MARSHAL'::text, 'CHECK_IN'::text, 'VOLUNTEER'::text, 'OTHER'::text]));

alter table public."match_assignments" add constraint "match_assignments_match_id_user_id_assignment_role_key" UNIQUE (match_id, user_id, assignment_role);

alter table public."match_assignments" add constraint "match_assignments_pkey" PRIMARY KEY (id);

alter table public."match_assignments" add constraint "match_assignments_status_check" CHECK (status = ANY (ARRAY['ASSIGNED'::text, 'CONFIRMED'::text, 'DECLINED'::text, 'COMPLETED'::text, 'CANCELLED'::text]));

alter table public."match_results" add constraint "match_results_match_id_key" UNIQUE (match_id);

alter table public."match_results" add constraint "match_results_pkey" PRIMARY KEY (id);

alter table public."match_results" add constraint "match_results_result_type_check" CHECK (result_type = ANY (ARRAY['WIN'::text, 'DRAW'::text, 'TIE'::text, 'NO_RESULT'::text, 'FORFEIT'::text, 'WALKOVER'::text, 'CANCELLED'::text]));

alter table public."matches" add constraint "matches_away_source_type_check" CHECK (away_source_type IS NULL OR (away_source_type = ANY (ARRAY['GROUP_POSITION'::text, 'MATCH_WINNER'::text, 'MATCH_LOSER'::text, 'MANUAL'::text])));

alter table public."matches" add constraint "matches_event_id_match_number_key" UNIQUE (event_id, match_number);

alter table public."matches" add constraint "matches_home_source_type_check" CHECK (home_source_type IS NULL OR (home_source_type = ANY (ARRAY['GROUP_POSITION'::text, 'MATCH_WINNER'::text, 'MATCH_LOSER'::text, 'MANUAL'::text])));

alter table public."matches" add constraint "matches_pkey" PRIMARY KEY (id);

alter table public."matches" add constraint "matches_result_status_check" CHECK (result_status = ANY (ARRAY['PENDING'::text, 'PROVISIONAL'::text, 'CONFIRMED'::text, 'DISPUTED'::text, 'VOID'::text]));

alter table public."matches" add constraint "matches_round_number_check" CHECK (round_number IS NULL OR round_number > 0);

alter table public."matches" add constraint "matches_stage_check" CHECK (stage = ANY (ARRAY['GROUP'::text, 'ROUND_OF_32'::text, 'ROUND_OF_16'::text, 'QUARTERFINAL'::text, 'SEMIFINAL'::text, 'FINAL'::text, 'THIRD_PLACE'::text, 'FRIENDLY'::text, 'OTHER'::text]));

alter table public."matches" add constraint "matches_status_check" CHECK (status = ANY (ARRAY['DRAFT'::text, 'SCHEDULED'::text, 'READY'::text, 'IN_PROGRESS'::text, 'COMPLETED'::text, 'POSTPONED'::text, 'CANCELLED'::text, 'FORFEITED'::text]));

alter table public."organizations" add constraint "organizations_pkey" PRIMARY KEY (id);

alter table public."organizations" add constraint "organizations_slug_key" UNIQUE (slug);

alter table public."organizations" add constraint "organizations_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text]));

alter table public."payments" add constraint "payments_amount_check" CHECK (amount >= 0::numeric);

alter table public."payments" add constraint "payments_payment_status_check" CHECK (payment_status = ANY (ARRAY['PENDING'::text, 'PROCESSING'::text, 'PAID'::text, 'FAILED'::text, 'REFUNDED'::text, 'PARTIALLY_REFUNDED'::text, 'CANCELLED'::text]));

alter table public."payments" add constraint "payments_payment_type_check" CHECK (payment_type = ANY (ARRAY['REGISTRATION'::text, 'ADDITIONAL_FEE'::text, 'REFUND'::text, 'OTHER'::text]));

alter table public."payments" add constraint "payments_pkey" PRIMARY KEY (id);

alter table public."playing_areas" add constraint "playing_areas_area_type_check" CHECK (area_type = ANY (ARRAY['COURT'::text, 'FIELD'::text, 'LANE'::text, 'HALL'::text, 'TABLE'::text, 'OTHER'::text]));

alter table public."playing_areas" add constraint "playing_areas_pkey" PRIMARY KEY (id);

alter table public."playing_areas" add constraint "playing_areas_venue_id_name_key" UNIQUE (venue_id, name);

alter table public."profiles" add constraint "profiles_account_status_check" CHECK (account_status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'SUSPENDED'::text]));

alter table public."profiles" add constraint "profiles_pkey" PRIMARY KEY (id);

alter table public."registrations" add constraint "registrations_amount_due_check" CHECK (amount_due >= 0::numeric);

alter table public."registrations" add constraint "registrations_amount_paid_check" CHECK (amount_paid >= 0::numeric);

alter table public."registrations" add constraint "registrations_payment_status_check" CHECK (payment_status = ANY (ARRAY['PENDING'::text, 'NOT_REQUIRED'::text, 'PAID'::text, 'PARTIALLY_PAID'::text, 'REFUNDED'::text, 'FAILED'::text]));

alter table public."registrations" add constraint "registrations_pkey" PRIMARY KEY (id);

alter table public."registrations" add constraint "registrations_registration_status_check" CHECK (registration_status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text, 'WAITLISTED'::text, 'CANCELLED'::text]));

alter table public."registrations" add constraint "registrations_registration_type_check" CHECK (registration_type = ANY (ARRAY['INDIVIDUAL'::text, 'TEAM'::text]));

alter table public."registrations" add constraint "registrations_waiver_status_check" CHECK (waiver_status = ANY (ARRAY['PENDING'::text, 'ACCEPTED'::text, 'NOT_REQUIRED'::text]));

alter table public."sports" add constraint "sports_name_key" UNIQUE (name);

alter table public."sports" add constraint "sports_participation_type_check" CHECK (participation_type = ANY (ARRAY['TEAM'::text, 'INDIVIDUAL'::text, 'BOTH'::text]));

alter table public."sports" add constraint "sports_pkey" PRIMARY KEY (id);

alter table public."standings" add constraint "standings_group_id_team_id_key" UNIQUE (group_id, team_id);

alter table public."standings" add constraint "standings_lost_check" CHECK (lost >= 0);

alter table public."standings" add constraint "standings_no_result_check" CHECK (no_result >= 0);

alter table public."standings" add constraint "standings_pkey" PRIMARY KEY (id);

alter table public."standings" add constraint "standings_played_check" CHECK (played >= 0);

alter table public."standings" add constraint "standings_rank_check" CHECK (rank IS NULL OR rank > 0);

alter table public."standings" add constraint "standings_tied_check" CHECK (tied >= 0);

alter table public."standings" add constraint "standings_won_check" CHECK (won >= 0);

alter table public."team_members" add constraint "team_members_invitation_status_check" CHECK (invitation_status = ANY (ARRAY['PENDING'::text, 'ACCEPTED'::text, 'DECLINED'::text, 'CANCELLED'::text]));

alter table public."team_members" add constraint "team_members_pkey" PRIMARY KEY (id);

alter table public."team_members" add constraint "team_members_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'REMOVED'::text]));

alter table public."team_members" add constraint "team_members_team_id_user_id_key" UNIQUE (team_id, user_id);

alter table public."team_members" add constraint "team_members_team_role_check" CHECK (team_role = ANY (ARRAY['CAPTAIN'::text, 'VICE_CAPTAIN'::text, 'PLAYER'::text, 'MANAGER'::text]));

alter table public."team_members" add constraint "team_members_waiver_status_check" CHECK (waiver_status = ANY (ARRAY['PENDING'::text, 'ACCEPTED'::text]));

alter table public."teams" add constraint "teams_approval_status_check" CHECK (approval_status = ANY (ARRAY['PENDING'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public."teams" add constraint "teams_event_id_team_name_key" UNIQUE (event_id, team_name);

alter table public."teams" add constraint "teams_identity_type_check" CHECK (identity_type = ANY (ARRAY['STATE'::text, 'COUNTRY'::text, 'CITY'::text, 'CLUB'::text, 'COMMUNITY'::text, 'OTHER'::text]));

alter table public."teams" add constraint "teams_payment_status_check" CHECK (payment_status = ANY (ARRAY['NOT_REQUIRED'::text, 'PENDING'::text, 'PAID'::text, 'PARTIALLY_PAID'::text, 'REFUNDED'::text]));

alter table public."teams" add constraint "teams_pkey" PRIMARY KEY (id);

alter table public."teams" add constraint "teams_registration_status_check" CHECK (registration_status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text, 'WAITLISTED'::text]));

alter table public."user_roles" add constraint "user_roles_pkey" PRIMARY KEY (id);

alter table public."user_roles" add constraint "user_roles_role_check" CHECK (role = ANY (ARRAY['SUPER_ADMIN'::text, 'ORGANIZER'::text, 'EVENT_STAFF'::text, 'CAPTAIN'::text, 'PARTICIPANT'::text]));

alter table public."user_roles" add constraint "user_roles_status_check" CHECK (status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text]));

alter table public."matches" add constraint "valid_actual_times" CHECK (actual_start IS NULL OR actual_end IS NULL OR actual_end >= actual_start);

alter table public."cricket_innings" add constraint "valid_cricket_balls" CHECK (balls_faced <= max_balls);

alter table public."divisions" add constraint "valid_division_participant_range" CHECK (min_participants IS NULL OR max_participants IS NULL OR min_participants <= max_participants);

alter table public."events" add constraint "valid_event_dates" CHECK (end_date >= start_date);

alter table public."registrations" add constraint "valid_registration_owner" CHECK (registration_type = 'INDIVIDUAL'::text AND user_id IS NOT NULL AND team_id IS NULL OR registration_type = 'TEAM'::text AND team_id IS NOT NULL);

alter table public."matches" add constraint "valid_scheduled_times" CHECK (scheduled_start IS NULL OR scheduled_end IS NULL OR scheduled_end > scheduled_start);

alter table public."events" add constraint "valid_team_size" CHECK (max_team_size IS NULL OR min_team_size IS NULL OR max_team_size >= min_team_size);

alter table public."venues" add constraint "venues_pkey" PRIMARY KEY (id);

alter table public."waiver_acceptances" add constraint "waiver_acceptances_pkey" PRIMARY KEY (id);

alter table public."waiver_acceptances" add constraint "waiver_acceptances_waiver_id_user_id_key" UNIQUE (waiver_id, user_id);

alter table public."waivers" add constraint "waivers_event_id_version_key" UNIQUE (event_id, version);

alter table public."waivers" add constraint "waivers_pkey" PRIMARY KEY (id);

alter table public."waivers" add constraint "waivers_version_check" CHECK (version > 0);

alter table public."cricket_innings" add constraint "cricket_innings_match_id_fkey" FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;

alter table public."cricket_innings" add constraint "cricket_innings_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."divisions" add constraint "divisions_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."event_staff_assignments" add constraint "event_staff_assignments_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."event_staff_assignments" add constraint "event_staff_assignments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."events" add constraint "events_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public."events" add constraint "events_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table public."events" add constraint "events_sport_id_fkey" FOREIGN KEY (sport_id) REFERENCES sports(id);

alter table public."events" add constraint "events_venue_id_fkey" FOREIGN KEY (venue_id) REFERENCES venues(id);

alter table public."group_members" add constraint "group_members_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;

alter table public."group_members" add constraint "group_members_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."groups" add constraint "groups_division_id_fkey" FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE CASCADE;

alter table public."match_assignments" add constraint "match_assignments_match_id_fkey" FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;

alter table public."match_assignments" add constraint "match_assignments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."match_results" add constraint "match_results_loser_team_id_fkey" FOREIGN KEY (loser_team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."match_results" add constraint "match_results_match_id_fkey" FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;

alter table public."match_results" add constraint "match_results_verified_by_fkey" FOREIGN KEY (verified_by) REFERENCES profiles(id) ON DELETE SET NULL;

alter table public."match_results" add constraint "match_results_winner_team_id_fkey" FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_away_team_id_fkey" FOREIGN KEY (away_team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_division_id_fkey" FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."matches" add constraint "matches_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_home_team_id_fkey" FOREIGN KEY (home_team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_playing_area_id_fkey" FOREIGN KEY (playing_area_id) REFERENCES playing_areas(id) ON DELETE SET NULL;

alter table public."matches" add constraint "matches_winner_team_id_fkey" FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."payments" add constraint "payments_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."payments" add constraint "payments_registration_id_fkey" FOREIGN KEY (registration_id) REFERENCES registrations(id) ON DELETE SET NULL;

alter table public."payments" add constraint "payments_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;

alter table public."payments" add constraint "payments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL;

alter table public."playing_areas" add constraint "playing_areas_venue_id_fkey" FOREIGN KEY (venue_id) REFERENCES venues(id) ON DELETE CASCADE;

alter table public."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table public."registrations" add constraint "registrations_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."registrations" add constraint "registrations_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."registrations" add constraint "registrations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."standings" add constraint "standings_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;

alter table public."standings" add constraint "standings_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."team_members" add constraint "team_members_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."team_members" add constraint "team_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."teams" add constraint "teams_captain_user_id_fkey" FOREIGN KEY (captain_user_id) REFERENCES profiles(id);

alter table public."teams" add constraint "teams_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."teams" add constraint "teams_manager_user_id_fkey" FOREIGN KEY (manager_user_id) REFERENCES profiles(id);

alter table public."user_roles" add constraint "user_roles_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

alter table public."user_roles" add constraint "user_roles_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table public."user_roles" add constraint "user_roles_team_id_fkey" FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

alter table public."user_roles" add constraint "user_roles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."venues" add constraint "venues_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table public."waiver_acceptances" add constraint "waiver_acceptances_registration_id_fkey" FOREIGN KEY (registration_id) REFERENCES registrations(id) ON DELETE SET NULL;

alter table public."waiver_acceptances" add constraint "waiver_acceptances_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

alter table public."waiver_acceptances" add constraint "waiver_acceptances_waiver_id_fkey" FOREIGN KEY (waiver_id) REFERENCES waivers(id) ON DELETE CASCADE;

alter table public."waivers" add constraint "waivers_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public."waivers" add constraint "waivers_event_id_fkey" FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

CREATE INDEX idx_team_members_team ON public.team_members USING btree (team_id);

CREATE INDEX idx_user_roles_user ON public.user_roles USING btree (user_id);

CREATE INDEX idx_registrations_team ON public.registrations USING btree (team_id);

CREATE INDEX idx_payments_event ON public.payments USING btree (event_id);

CREATE INDEX idx_groups_division ON public.groups USING btree (division_id);

CREATE INDEX idx_cricket_innings_match ON public.cricket_innings USING btree (match_id);

CREATE INDEX idx_playing_areas_venue ON public.playing_areas USING btree (venue_id);

CREATE UNIQUE INDEX uq_user_event_role ON public.user_roles USING btree (user_id, organization_id, event_id, role) WHERE ((event_id IS NOT NULL) AND (team_id IS NULL));

CREATE INDEX idx_venues_org ON public.venues USING btree (organization_id);

CREATE INDEX idx_cricket_innings_team ON public.cricket_innings USING btree (team_id);

CREATE INDEX idx_group_members_group ON public.group_members USING btree (group_id);

CREATE INDEX idx_registrations_user ON public.registrations USING btree (user_id);

CREATE INDEX idx_match_results_winner ON public.match_results USING btree (winner_team_id);

CREATE INDEX idx_event_staff_role ON public.event_staff_assignments USING btree (event_id, staff_role);

CREATE UNIQUE INDEX uq_individual_event_registration ON public.registrations USING btree (event_id, user_id) WHERE ((registration_type = 'INDIVIDUAL'::text) AND (registration_status <> 'CANCELLED'::text));

CREATE UNIQUE INDEX uq_payment_provider_transaction ON public.payments USING btree (provider, provider_transaction_id) WHERE (provider_transaction_id IS NOT NULL);

CREATE INDEX idx_user_roles_team ON public.user_roles USING btree (team_id);

CREATE INDEX idx_user_roles_event ON public.user_roles USING btree (event_id);

CREATE INDEX idx_user_roles_org ON public.user_roles USING btree (organization_id);

CREATE INDEX idx_event_staff_user ON public.event_staff_assignments USING btree (user_id);

CREATE UNIQUE INDEX uq_user_org_role ON public.user_roles USING btree (user_id, organization_id, role) WHERE ((event_id IS NULL) AND (team_id IS NULL));

CREATE INDEX idx_matches_event ON public.matches USING btree (event_id);

CREATE INDEX idx_waiver_acceptances_registration ON public.waiver_acceptances USING btree (registration_id);

CREATE INDEX idx_events_org ON public.events USING btree (organization_id);

CREATE INDEX idx_standings_team ON public.standings USING btree (team_id);

CREATE INDEX idx_events_status ON public.events USING btree (status);

CREATE INDEX idx_registrations_status ON public.registrations USING btree (registration_status);

CREATE INDEX idx_matches_home_team ON public.matches USING btree (home_team_id);

CREATE INDEX idx_matches_group ON public.matches USING btree (group_id);

CREATE INDEX idx_match_assignments_user ON public.match_assignments USING btree (user_id);

CREATE INDEX idx_matches_playing_area ON public.matches USING btree (playing_area_id);

CREATE INDEX idx_event_staff_event ON public.event_staff_assignments USING btree (event_id);

CREATE INDEX idx_registrations_event ON public.registrations USING btree (event_id);

CREATE INDEX idx_match_assignments_match ON public.match_assignments USING btree (match_id);

CREATE INDEX idx_divisions_event ON public.divisions USING btree (event_id);

CREATE INDEX idx_matches_schedule ON public.matches USING btree (event_id, scheduled_start);

CREATE INDEX idx_payments_user ON public.payments USING btree (user_id);

CREATE INDEX idx_standings_group ON public.standings USING btree (group_id);

CREATE INDEX idx_waiver_acceptances_user ON public.waiver_acceptances USING btree (user_id);

CREATE INDEX idx_teams_captain ON public.teams USING btree (captain_user_id);

CREATE INDEX idx_teams_event ON public.teams USING btree (event_id);

CREATE INDEX idx_team_members_user ON public.team_members USING btree (user_id);

CREATE INDEX idx_events_dates ON public.events USING btree (start_date, end_date);

CREATE INDEX idx_waivers_event ON public.waivers USING btree (event_id);

CREATE INDEX idx_group_members_team ON public.group_members USING btree (team_id);

CREATE UNIQUE INDEX uq_match_code_per_event ON public.matches USING btree (event_id, match_code) WHERE (match_code IS NOT NULL);

CREATE INDEX idx_matches_away_team ON public.matches USING btree (away_team_id);

CREATE INDEX idx_payments_registration ON public.payments USING btree (registration_id);

CREATE INDEX idx_matches_division ON public.matches USING btree (division_id);

CREATE UNIQUE INDEX uq_team_event_registration ON public.registrations USING btree (event_id, team_id) WHERE ((registration_type = 'TEAM'::text) AND (registration_status <> 'CANCELLED'::text));

CREATE INDEX idx_payments_team ON public.payments USING btree (team_id);

CREATE UNIQUE INDEX uq_user_team_role ON public.user_roles USING btree (user_id, organization_id, event_id, team_id, role) WHERE ((event_id IS NOT NULL) AND (team_id IS NOT NULL));

CREATE INDEX idx_events_sport ON public.events USING btree (sport_id);

CREATE OR REPLACE FUNCTION public.is_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    select exists (
        select 1
        from public.user_roles ur
        where ur.user_id = auth.uid()
          and ur.role = 'SUPER_ADMIN'
          and ur.status = 'ACTIVE'
    );
$function$;

CREATE OR REPLACE FUNCTION public.is_organizer(p_organization_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    select
        public.is_super_admin()
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.organization_id = p_organization_id
              and ur.role = 'ORGANIZER'
              and ur.status = 'ACTIVE'
        );
$function$;

CREATE OR REPLACE FUNCTION public.has_event_role(p_event_id uuid, p_role text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    select
        public.is_super_admin()
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.event_id = p_event_id
              and ur.role = p_role
              and ur.status = 'ACTIVE'
        );
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_event(p_event_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    select
        public.is_super_admin()
        or exists (
            select 1
            from public.events e
            join public.user_roles ur
              on ur.organization_id = e.organization_id
            where e.id = p_event_id
              and ur.user_id = auth.uid()
              and ur.role = 'ORGANIZER'
              and ur.status = 'ACTIVE'
        );
$function$;

CREATE OR REPLACE FUNCTION public.is_team_captain(p_team_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    select
        public.is_super_admin()
        or exists (
            select 1
            from public.teams t
            where t.id = p_team_id
              and t.captain_user_id = auth.uid()
        )
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.team_id = p_team_id
              and ur.role = 'CAPTAIN'
              and ur.status = 'ACTIVE'
        );
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin

    insert into public.profiles (
        id,
        first_name,
        last_name
    )
    values (
        new.id,
        new.raw_user_meta_data ->> 'first_name',
        new.raw_user_meta_data ->> 'last_name'
    )
    on conflict (id) do nothing;

    return new;

end;
$function$;

CREATE OR REPLACE FUNCTION public.validate_match_schedule()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    minimum_rest interval := interval '60 minutes';
begin

    if new.scheduled_start is null
       or new.scheduled_end is null then
        return new;
    end if;


    if new.scheduled_end <= new.scheduled_start then
        raise exception
            'Match scheduled_end must be after scheduled_start';
    end if;


    -- ========================================================
    -- PLAYING AREA CONFLICT
    -- ========================================================

    if new.playing_area_id is not null
       and exists (
            select 1
            from public.matches m
            where m.id <> new.id
              and m.playing_area_id = new.playing_area_id
              and m.status not in ('CANCELLED', 'POSTPONED')
              and m.scheduled_start is not null
              and m.scheduled_end is not null
              and new.scheduled_start < m.scheduled_end
              and new.scheduled_end > m.scheduled_start
       )
    then
        raise exception
            'Scheduling conflict: playing area is already booked during this time';
    end if;


    -- ========================================================
    -- HOME TEAM REST / OVERLAP CHECK
    -- ========================================================

    if new.home_team_id is not null
       and exists (
            select 1
            from public.matches m
            where m.id <> new.id
              and m.status not in ('CANCELLED', 'POSTPONED')
              and m.scheduled_start is not null
              and m.scheduled_end is not null

              and (
                    m.home_team_id = new.home_team_id
                    or
                    m.away_team_id = new.home_team_id
              )

              and new.scheduled_start
                    < m.scheduled_end + minimum_rest

              and new.scheduled_end
                    > m.scheduled_start - minimum_rest
       )
    then
        raise exception
            'Scheduling conflict: home team does not have the required 60-minute rest period';
    end if;


    -- ========================================================
    -- AWAY TEAM REST / OVERLAP CHECK
    -- ========================================================

    if new.away_team_id is not null
       and exists (
            select 1
            from public.matches m
            where m.id <> new.id
              and m.status not in ('CANCELLED', 'POSTPONED')
              and m.scheduled_start is not null
              and m.scheduled_end is not null

              and (
                    m.home_team_id = new.away_team_id
                    or
                    m.away_team_id = new.away_team_id
              )

              and new.scheduled_start
                    < m.scheduled_end + minimum_rest

              and new.scheduled_end
                    > m.scheduled_start - minimum_rest
       )
    then
        raise exception
            'Scheduling conflict: away team does not have the required 60-minute rest period';
    end if;


    return new;

end;
$function$;

CREATE OR REPLACE FUNCTION public.recalculate_cricket_standings(p_group_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin

    -- --------------------------------------------------------
    -- Reset current standings
    -- --------------------------------------------------------

    update public.standings
    set
        played = 0,
        won = 0,
        lost = 0,
        tied = 0,
        no_result = 0,
        points = 0,

        runs_for = 0,
        balls_faced = 0,

        runs_against = 0,
        balls_bowled = 0,

        net_run_rate = 0,
        rank = null,

        updated_at = now()

    where group_id = p_group_id;


    -- --------------------------------------------------------
    -- Rebuild standings from CONFIRMED results
    -- --------------------------------------------------------

    with completed_matches as (

        select
            m.id as match_id,
            m.home_team_id,
            m.away_team_id,

            mr.result_type,
            mr.winner_team_id,
            mr.loser_team_id

        from public.matches m

        join public.match_results mr
            on mr.match_id = m.id

        where m.group_id = p_group_id
          and m.stage = 'GROUP'
          and m.status = 'COMPLETED'
          and mr.verified = true
    ),

    team_results as (

        -- HOME TEAM VIEW
        select
            cm.match_id,
            cm.home_team_id as team_id,

            case
                when cm.result_type in ('WIN', 'FORFEIT', 'WALKOVER')
                     and cm.winner_team_id = cm.home_team_id
                    then 1
                else 0
            end as won,

            case
                when cm.result_type in ('WIN', 'FORFEIT', 'WALKOVER')
                     and cm.loser_team_id = cm.home_team_id
                    then 1
                else 0
            end as lost,

            case
                when cm.result_type = 'TIE'
                    then 1
                else 0
            end as tied,

            case
                when cm.result_type = 'NO_RESULT'
                    then 1
                else 0
            end as no_result

        from completed_matches cm

        union all

        -- AWAY TEAM VIEW
        select
            cm.match_id,
            cm.away_team_id,

            case
                when cm.result_type in ('WIN', 'FORFEIT', 'WALKOVER')
                     and cm.winner_team_id = cm.away_team_id
                    then 1
                else 0
            end,

            case
                when cm.result_type in ('WIN', 'FORFEIT', 'WALKOVER')
                     and cm.loser_team_id = cm.away_team_id
                    then 1
                else 0
            end,

            case
                when cm.result_type = 'TIE'
                    then 1
                else 0
            end,

            case
                when cm.result_type = 'NO_RESULT'
                    then 1
                else 0
            end

        from completed_matches cm
    ),

    aggregated_results as (

        select
            team_id,

            count(*) as played,

            sum(won) as won,
            sum(lost) as lost,
            sum(tied) as tied,
            sum(no_result) as no_result,

            (
                sum(won) * 2
                +
                sum(tied)
                +
                sum(no_result)
            )::numeric as points

        from team_results

        group by team_id
    )

    update public.standings s

    set
        played = ar.played,
        won = ar.won,
        lost = ar.lost,
        tied = ar.tied,
        no_result = ar.no_result,
        points = ar.points,
        updated_at = now()

    from aggregated_results ar

    where s.group_id = p_group_id
      and s.team_id = ar.team_id;


    -- ========================================================
    -- 2. CALCULATE CRICKET RUN / BALL TOTALS
    --
    -- NRR uses:
    --
    -- runs scored / overs faced
    -- MINUS
    -- runs conceded / overs bowled
    --
    -- We store balls, therefore:
    --
    -- run rate = runs * 6 / balls
    -- ========================================================

    with valid_matches as (

        select m.id

        from public.matches m

        join public.match_results mr
            on mr.match_id = m.id

        where m.group_id = p_group_id
          and m.stage = 'GROUP'
          and m.status = 'COMPLETED'
          and mr.verified = true

          -- Only innings-based results affect NRR
          and mr.result_type in ('WIN', 'TIE')
    ),

    batting_totals as (

        select
            ci.team_id,

            sum(ci.runs) as runs_for,

            sum(
                case
                    when ci.all_out = true
                        then ci.max_balls
                    else ci.balls_faced
                end
            ) as balls_faced

        from public.cricket_innings ci

        join valid_matches vm
            on vm.id = ci.match_id

        group by ci.team_id
    ),

    bowling_totals as (

        select
            opponent.team_id,

            sum(ci.runs) as runs_against,

            sum(
                case
                    when ci.all_out = true
                        then ci.max_balls
                    else ci.balls_faced
                end
            ) as balls_bowled

        from public.cricket_innings ci

        join valid_matches vm
            on vm.id = ci.match_id

        join public.matches m
            on m.id = ci.match_id

        cross join lateral (

            select
                case
                    when ci.team_id = m.home_team_id
                        then m.away_team_id
                    else m.home_team_id
                end as team_id

        ) opponent

        group by opponent.team_id
    )

    update public.standings s

    set
        runs_for =
            coalesce(bt.runs_for, 0),

        balls_faced =
            coalesce(bt.balls_faced, 0),

        runs_against =
            coalesce(bwt.runs_against, 0),

        balls_bowled =
            coalesce(bwt.balls_bowled, 0),

        net_run_rate =
            case

                when coalesce(bt.balls_faced, 0) > 0
                 and coalesce(bwt.balls_bowled, 0) > 0

                then round(

                    (
                        (
                            bt.runs_for::numeric * 6
                            /
                            bt.balls_faced
                        )

                        -

                        (
                            bwt.runs_against::numeric * 6
                            /
                            bwt.balls_bowled
                        )

                    ),

                    4
                )

                else 0

            end,

        updated_at = now()

    from batting_totals bt

    join bowling_totals bwt
        on bwt.team_id = bt.team_id

    where s.group_id = p_group_id
      and s.team_id = bt.team_id;


    -- ========================================================
    -- 3. RANK GROUP
    --
    -- V1:
    -- 1. Points
    -- 2. Net Run Rate
    -- 3. Wins
    -- 4. Team name (deterministic fallback)
    --
    -- Head-to-head can be added later.
    -- ========================================================

    with ranked as (

        select
            s.id,

            row_number() over (

                order by
                    s.points desc,
                    s.net_run_rate desc,
                    s.won desc,
                    t.team_name asc

            ) as calculated_rank

        from public.standings s

        join public.teams t
            on t.id = s.team_id

        where s.group_id = p_group_id
    )

    update public.standings s

    set
        rank = r.calculated_rank,
        updated_at = now()

    from ranked r

    where s.id = r.id;

end;
$function$;

CREATE OR REPLACE FUNCTION public.record_cricket_result(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer DEFAULT 48)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

declare

    v_match public.matches%rowtype;

    v_winner uuid;
    v_loser uuid;

    v_result_type text;
    v_result_summary text;

begin

    -- ========================================================
    -- LOAD MATCH
    -- ========================================================

    select *
    into v_match

    from public.matches

    where id = p_match_id;


    if not found then
        raise exception 'Match not found';
    end if;


    -- ========================================================
    -- AUTHORIZATION
    -- ========================================================

    if not public.can_manage_event(v_match.event_id) then
        raise exception
            'Not authorized to record this match result';
    end if;


    -- ========================================================
    -- SUPPORTED CRICKET STAGES
    -- ========================================================

    if v_match.stage not in (
        'GROUP',
        'SEMIFINAL',
        'FINAL',
        'THIRD_PLACE'
    ) then

        raise exception
            'Cricket result entry is not supported for stage %',
            v_match.stage;

    end if;


    -- ========================================================
    -- VALIDATE TEAMS
    -- ========================================================

    if v_match.home_team_id is null
       or v_match.away_team_id is null then

        raise exception
            'Match participants have not been resolved';

    end if;


    -- ========================================================
    -- VALIDATE SCORE
    -- ========================================================

    if p_home_runs < 0
       or p_away_runs < 0 then

        raise exception 'Runs cannot be negative';

    end if;


    if p_home_wickets < 0
       or p_home_wickets > 10
       or p_away_wickets < 0
       or p_away_wickets > 10 then

        raise exception
            'Wickets must be between 0 and 10';

    end if;


    if p_home_balls <= 0
       or p_away_balls <= 0
       or p_max_balls <= 0 then

        raise exception
            'Ball counts must be greater than zero';

    end if;


    if p_home_balls > p_max_balls
       or p_away_balls > p_max_balls then

        raise exception
            'Balls faced cannot exceed maximum balls';

    end if;


    -- ========================================================
    -- DETERMINE RESULT
    -- ========================================================

    if p_home_runs > p_away_runs then

        v_winner := v_match.home_team_id;
        v_loser  := v_match.away_team_id;

        v_result_type := 'WIN';

        v_result_summary :=
            format(
                'Home team won by %s runs',
                p_home_runs - p_away_runs
            );


    elsif p_away_runs > p_home_runs then

        v_winner := v_match.away_team_id;
        v_loser  := v_match.home_team_id;

        v_result_type := 'WIN';

        v_result_summary :=
            format(
                'Away team won with %s wickets remaining',
                10 - p_away_wickets
            );


    else

        -- Knockout cricket must produce a winner.
        -- Super-over / tie-break support will be added later.

        if v_match.stage <> 'GROUP' then

            raise exception
                'Knockout match cannot end in an unresolved tie';

        end if;

        v_winner := null;
        v_loser  := null;

        v_result_type := 'TIE';
        v_result_summary := 'Match tied';

    end if;


    -- ========================================================
    -- HOME INNINGS
    -- ========================================================

    insert into public.cricket_innings (
        match_id,
        team_id,
        innings_number,
        runs,
        wickets,
        balls_faced,
        max_balls,
        all_out
    )

    values (
        p_match_id,
        v_match.home_team_id,
        1,
        p_home_runs,
        p_home_wickets,
        p_home_balls,
        p_max_balls,
        p_home_wickets = 10
    )

    on conflict (match_id, innings_number)

    do update set

        team_id = excluded.team_id,
        runs = excluded.runs,
        wickets = excluded.wickets,
        balls_faced = excluded.balls_faced,
        max_balls = excluded.max_balls,
        all_out = excluded.all_out,
        updated_at = now();


    -- ========================================================
    -- AWAY INNINGS
    -- ========================================================

    insert into public.cricket_innings (
        match_id,
        team_id,
        innings_number,
        runs,
        wickets,
        balls_faced,
        max_balls,
        all_out
    )

    values (
        p_match_id,
        v_match.away_team_id,
        2,
        p_away_runs,
        p_away_wickets,
        p_away_balls,
        p_max_balls,
        p_away_wickets = 10
    )

    on conflict (match_id, innings_number)

    do update set

        team_id = excluded.team_id,
        runs = excluded.runs,
        wickets = excluded.wickets,
        balls_faced = excluded.balls_faced,
        max_balls = excluded.max_balls,
        all_out = excluded.all_out,
        updated_at = now();


    -- ========================================================
    -- MATCH RESULT
    -- ========================================================

    insert into public.match_results (
        match_id,
        winner_team_id,
        loser_team_id,
        result_type,
        result_summary,
        home_points,
        away_points,
        verified,
        verified_by,
        verified_at
    )

    values (
        p_match_id,
        v_winner,
        v_loser,
        v_result_type,
        v_result_summary,
        p_home_runs,
        p_away_runs,
        true,
        auth.uid(),
        now()
    )

    on conflict (match_id)

    do update set

        winner_team_id = excluded.winner_team_id,
        loser_team_id = excluded.loser_team_id,
        result_type = excluded.result_type,
        result_summary = excluded.result_summary,
        home_points = excluded.home_points,
        away_points = excluded.away_points,
        verified = true,
        verified_by = auth.uid(),
        verified_at = now(),
        updated_at = now();


    -- ========================================================
    -- COMPLETE MATCH
    -- ========================================================

    update public.matches

    set
        status = 'COMPLETED',
        result_status = 'CONFIRMED',
        winner_team_id = v_winner,
        actual_end = now(),
        updated_at = now()

    where id = p_match_id;


    -- ========================================================
    -- GROUP STANDINGS ONLY
    -- ========================================================

    if v_match.stage = 'GROUP'
       and v_match.group_id is not null then

        perform public.recalculate_cricket_standings(
            v_match.group_id
        );

    end if;

end;

$function$;

CREATE OR REPLACE FUNCTION public.resolve_semifinalists(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

declare

    v_group_a uuid;
    v_group_b uuid;

    v_a1 uuid;
    v_a2 uuid;

    v_b1 uuid;
    v_b2 uuid;

    v_sf1 uuid;
    v_sf2 uuid;

    v_incomplete_count integer;

begin

    -- ========================================================
    -- AUTHORIZATION
    -- ========================================================

    if not public.can_manage_event(p_event_id) then
        raise exception
            'Not authorized to resolve semifinalists';
    end if;


    -- ========================================================
    -- FIND GROUPS
    -- ========================================================

    select g.id
    into v_group_a

    from public.groups g

    join public.divisions d
        on d.id = g.division_id

    where d.event_id = p_event_id
      and g.name = 'Group A';


    select g.id
    into v_group_b

    from public.groups g

    join public.divisions d
        on d.id = g.division_id

    where d.event_id = p_event_id
      and g.name = 'Group B';


    if v_group_a is null
       or v_group_b is null then

        raise exception
            'Group A or Group B not found';

    end if;


    -- ========================================================
    -- VERIFY ALL GROUP MATCHES ARE COMPLETED
    -- ========================================================

    select count(*)
    into v_incomplete_count

    from public.matches m

    where m.event_id = p_event_id
      and m.stage = 'GROUP'

      and (
            m.status <> 'COMPLETED'
            or
            m.result_status <> 'CONFIRMED'
          );


    if v_incomplete_count > 0 then

        raise exception
            'Cannot resolve semifinalists: % group matches are incomplete',
            v_incomplete_count;

    end if;


    -- ========================================================
    -- GET GROUP A #1 AND #2
    -- ========================================================

    select s.team_id
    into v_a1

    from public.standings s

    where s.group_id = v_group_a
      and s.rank = 1;


    select s.team_id
    into v_a2

    from public.standings s

    where s.group_id = v_group_a
      and s.rank = 2;


    -- ========================================================
    -- GET GROUP B #1 AND #2
    -- ========================================================

    select s.team_id
    into v_b1

    from public.standings s

    where s.group_id = v_group_b
      and s.rank = 1;


    select s.team_id
    into v_b2

    from public.standings s

    where s.group_id = v_group_b
      and s.rank = 2;


    if v_a1 is null
       or v_a2 is null
       or v_b1 is null
       or v_b2 is null then

        raise exception
            'Final group rankings are incomplete';

    end if;


    -- ========================================================
    -- FIND SEMIFINAL MATCHES
    -- ========================================================

    select id
    into v_sf1

    from public.matches

    where event_id = p_event_id
      and match_code = 'SF1';


    select id
    into v_sf2

    from public.matches

    where event_id = p_event_id
      and match_code = 'SF2';


    if v_sf1 is null
       or v_sf2 is null then

        raise exception
            'Semifinal fixtures not found';

    end if;


    -- ========================================================
    -- RESOLVE SF1
    --
    -- A1 vs B2
    -- ========================================================

    update public.matches

    set
        home_team_id = v_a1,
        away_team_id = v_b2,

        status = 'DRAFT',

        result_status = 'PENDING',

        updated_at = now()

    where id = v_sf1;


    -- ========================================================
    -- RESOLVE SF2
    --
    -- B1 vs A2
    -- ========================================================

    update public.matches

    set
        home_team_id = v_b1,
        away_team_id = v_a2,

        status = 'DRAFT',

        result_status = 'PENDING',

        updated_at = now()

    where id = v_sf2;

end;

$function$;

CREATE OR REPLACE FUNCTION public.resolve_finalists(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

declare

    v_sf1_id uuid;
    v_sf2_id uuid;
    v_final_id uuid;

    v_sf1_winner uuid;
    v_sf2_winner uuid;

begin

    -- ========================================================
    -- AUTHORIZATION
    -- ========================================================

    if not public.can_manage_event(p_event_id) then
        raise exception
            'Not authorized to resolve finalists';
    end if;


    -- ========================================================
    -- FIND SF1
    -- ========================================================

    select
        id,
        winner_team_id

    into
        v_sf1_id,
        v_sf1_winner

    from public.matches

    where event_id = p_event_id
      and match_code = 'SF1'
      and stage = 'SEMIFINAL';


    -- ========================================================
    -- FIND SF2
    -- ========================================================

    select
        id,
        winner_team_id

    into
        v_sf2_id,
        v_sf2_winner

    from public.matches

    where event_id = p_event_id
      and match_code = 'SF2'
      and stage = 'SEMIFINAL';


    if v_sf1_id is null
       or v_sf2_id is null then

        raise exception
            'Semifinal matches not found';

    end if;


    -- ========================================================
    -- BOTH SEMIFINALS MUST BE COMPLETED
    -- ========================================================

    if not exists (
        select 1
        from public.matches
        where id = v_sf1_id
          and status = 'COMPLETED'
          and result_status = 'CONFIRMED'
    ) then

        raise exception
            'SF1 is not completed and confirmed';

    end if;


    if not exists (
        select 1
        from public.matches
        where id = v_sf2_id
          and status = 'COMPLETED'
          and result_status = 'CONFIRMED'
    ) then

        raise exception
            'SF2 is not completed and confirmed';

    end if;


    -- ========================================================
    -- BOTH SEMIFINALS MUST HAVE WINNERS
    -- ========================================================

    if v_sf1_winner is null
       or v_sf2_winner is null then

        raise exception
            'Both semifinals must have a winner';

    end if;


    if v_sf1_winner = v_sf2_winner then

        raise exception
            'Invalid knockout state: same team won both semifinals';

    end if;


    -- ========================================================
    -- FIND FINAL
    -- ========================================================

    select id
    into v_final_id

    from public.matches

    where event_id = p_event_id
      and match_code = 'FINAL'
      and stage = 'FINAL';


    if v_final_id is null then

        raise exception
            'Final match not found';

    end if;


    -- ========================================================
    -- PROTECT AN ALREADY COMPLETED FINAL
    -- ========================================================

    if exists (
        select 1
        from public.matches
        where id = v_final_id
          and status = 'COMPLETED'
    ) then

        raise exception
            'Final is already completed';

    end if;


    -- ========================================================
    -- RESOLVE FINAL
    --
    -- Home = SF1 winner
    -- Away = SF2 winner
    -- ========================================================

    update public.matches

    set
        home_team_id = v_sf1_winner,
        away_team_id = v_sf2_winner,

        home_source_type = 'MATCH_WINNER',
        home_source_ref = 'SF1',

        away_source_type = 'MATCH_WINNER',
        away_source_ref = 'SF2',

        status = 'DRAFT',
        result_status = 'PENDING',

        updated_at = now()

    where id = v_final_id;

end;

$function$;

CREATE OR REPLACE FUNCTION public.handle_knockout_advancement()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

declare
    v_sf_count integer;
    v_completed_sf_count integer;

begin

    -- Only process confirmed completed knockout matches.
    if new.status <> 'COMPLETED'
       or new.result_status <> 'CONFIRMED'
       or new.winner_team_id is null then

        return new;

    end if;


    -- ========================================================
    -- SEMIFINAL ADVANCEMENT
    -- ========================================================

    if new.stage = 'SEMIFINAL' then

        -- Count semifinals belonging to this event.
        select count(*)
        into v_sf_count
        from public.matches
        where event_id = new.event_id
          and stage = 'SEMIFINAL';


        -- Count completed/confirmed semifinals with winners.
        select count(*)
        into v_completed_sf_count
        from public.matches
        where event_id = new.event_id
          and stage = 'SEMIFINAL'
          and status = 'COMPLETED'
          and result_status = 'CONFIRMED'
          and winner_team_id is not null;


        -- Only resolve the Final after ALL semifinals
        -- have produced confirmed winners.
        if v_sf_count > 0
           and v_sf_count = v_completed_sf_count then

            perform public.resolve_finalists(new.event_id);

        end if;

    end if;


    return new;

end;

$function$;

CREATE OR REPLACE FUNCTION public.complete_tournament(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

declare

    v_final public.matches%rowtype;
    v_unfinished_matches integer;

begin

    -- ========================================================
    -- AUTHORIZATION
    -- ========================================================

    if not public.can_manage_event(p_event_id) then

        raise exception
            'Not authorized to complete this tournament';

    end if;


    -- ========================================================
    -- FIND FINAL
    -- ========================================================

    select *
    into v_final

    from public.matches

    where event_id = p_event_id
      and stage = 'FINAL';


    if not found then

        raise exception
            'Tournament Final not found';

    end if;


    -- ========================================================
    -- FINAL MUST BE COMPLETE
    -- ========================================================

    if v_final.status <> 'COMPLETED'
       or v_final.result_status <> 'CONFIRMED'
       or v_final.winner_team_id is null then

        raise exception
            'Tournament cannot be completed until the Final has a confirmed winner';

    end if;


    -- ========================================================
    -- CHECK FOR UNFINISHED COMPETITION MATCHES
    -- ========================================================

    select count(*)
    into v_unfinished_matches

    from public.matches

    where event_id = p_event_id

      and stage in (
          'GROUP',
          'ROUND_OF_32',
          'ROUND_OF_16',
          'QUARTERFINAL',
          'SEMIFINAL',
          'FINAL',
          'THIRD_PLACE'
      )

      and status not in (
          'COMPLETED',
          'CANCELLED',
          'FORFEITED'
      );


    if v_unfinished_matches > 0 then

        raise exception
            'Tournament still has % unfinished competition matches',
            v_unfinished_matches;

    end if;


    -- ========================================================
    -- COMPLETE EVENT
    -- ========================================================

    update public.events

    set
        status = 'COMPLETED',
        updated_at = now()

    where id = p_event_id;

end;

$function$;

CREATE OR REPLACE FUNCTION public.is_event_staff(p_event_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

    select
        public.is_super_admin()

        or exists (

            select 1

            from public.event_staff_assignments esa

            where esa.event_id = p_event_id

              and esa.user_id = auth.uid()

              and esa.status in (
                  'ASSIGNED',
                  'CONFIRMED'
              )
        );

$function$;

CREATE OR REPLACE FUNCTION public.has_event_staff_role(p_event_id uuid, p_staff_role text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

    select
        public.is_super_admin()

        or exists (

            select 1

            from public.event_staff_assignments esa

            where esa.event_id = p_event_id

              and esa.user_id = auth.uid()

              and esa.staff_role = p_staff_role

              and esa.status in (
                  'ASSIGNED',
                  'CONFIRMED'
              )
        );

$function$;

create policy "Users can view own profile" on public."profiles" as PERMISSIVE for SELECT to "authenticated" using ((id = auth.uid()));

create policy "Users can update own profile" on public."profiles" as PERMISSIVE for UPDATE to "authenticated" using ((id = auth.uid())) with check ((id = auth.uid()));

create policy "Authenticated users can view active sports" on public."sports" as PERMISSIVE for SELECT to "authenticated" using ((active = true));

create policy "Users can view own roles" on public."user_roles" as PERMISSIVE for SELECT to "authenticated" using ((user_id = auth.uid()));

create policy "Members can view organizations" on public."organizations" as PERMISSIVE for SELECT to "authenticated" using ((is_super_admin() OR (EXISTS ( SELECT 1
   FROM user_roles ur
  WHERE ((ur.organization_id = organizations.id) AND (ur.user_id = auth.uid()) AND (ur.status = 'ACTIVE'::text))))));

create policy "Super admins can manage organizations" on public."organizations" as PERMISSIVE for ALL to "authenticated" using (is_super_admin()) with check (is_super_admin());

create policy "Users can view available events" on public."events" as PERMISSIVE for SELECT to "authenticated" using (((status = ANY (ARRAY['PUBLISHED'::text, 'REGISTRATION_OPEN'::text, 'REGISTRATION_CLOSED'::text, 'IN_PROGRESS'::text, 'COMPLETED'::text])) OR can_manage_event(id)));

create policy "Organizers can create events" on public."events" as PERMISSIVE for INSERT to "authenticated" with check (is_organizer(organization_id));

create policy "Organizers can update events" on public."events" as PERMISSIVE for UPDATE to "authenticated" using (is_organizer(organization_id)) with check (is_organizer(organization_id));

create policy "Organizers can delete events" on public."events" as PERMISSIVE for DELETE to "authenticated" using (is_organizer(organization_id));

create policy "Users can view event teams" on public."teams" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM events e
  WHERE ((e.id = teams.event_id) AND ((e.status = ANY (ARRAY['PUBLISHED'::text, 'REGISTRATION_OPEN'::text, 'REGISTRATION_CLOSED'::text, 'IN_PROGRESS'::text, 'COMPLETED'::text])) OR can_manage_event(e.id))))));

create policy "Authorized users can update teams" on public."teams" as PERMISSIVE for UPDATE to "authenticated" using ((can_manage_event(event_id) OR is_team_captain(id))) with check ((can_manage_event(event_id) OR is_team_captain(id)));

create policy "Users can view team members" on public."team_members" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM teams t
  WHERE (t.id = team_members.team_id))));

create policy "Authorized users can add team members" on public."team_members" as PERMISSIVE for INSERT to "authenticated" with check ((is_team_captain(team_id) OR (EXISTS ( SELECT 1
   FROM teams t
  WHERE ((t.id = team_members.team_id) AND can_manage_event(t.event_id))))));

create policy "Authorized users can update team members" on public."team_members" as PERMISSIVE for UPDATE to "authenticated" using ((is_team_captain(team_id) OR (EXISTS ( SELECT 1
   FROM teams t
  WHERE ((t.id = team_members.team_id) AND can_manage_event(t.event_id)))))) with check ((is_team_captain(team_id) OR (EXISTS ( SELECT 1
   FROM teams t
  WHERE ((t.id = team_members.team_id) AND can_manage_event(t.event_id))))));

create policy "Authorized users can remove team members" on public."team_members" as PERMISSIVE for DELETE to "authenticated" using ((is_team_captain(team_id) OR (EXISTS ( SELECT 1
   FROM teams t
  WHERE ((t.id = team_members.team_id) AND can_manage_event(t.event_id))))));

create policy "Authenticated users can view venues" on public."venues" as PERMISSIVE for SELECT to "authenticated" using (((active = true) OR is_super_admin()));

create policy "Organizers can manage venues" on public."venues" as PERMISSIVE for ALL to "authenticated" using (is_organizer(organization_id)) with check (is_organizer(organization_id));

create policy "Authenticated users can view playing areas" on public."playing_areas" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM venues v
  WHERE (v.id = playing_areas.venue_id))));

create policy "Organizers can manage playing areas" on public."playing_areas" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM venues v
  WHERE ((v.id = playing_areas.venue_id) AND is_organizer(v.organization_id))))) with check ((EXISTS ( SELECT 1
   FROM venues v
  WHERE ((v.id = playing_areas.venue_id) AND is_organizer(v.organization_id)))));

create policy "Authorized users can view registrations" on public."registrations" as PERMISSIVE for SELECT to "authenticated" using (((user_id = auth.uid()) OR ((team_id IS NOT NULL) AND is_team_captain(team_id)) OR can_manage_event(event_id)));

create policy "Users can create own individual registration" on public."registrations" as PERMISSIVE for INSERT to "authenticated" with check (((registration_type = 'INDIVIDUAL'::text) AND (user_id = auth.uid()) AND (team_id IS NULL) AND (EXISTS ( SELECT 1
   FROM events e
  WHERE ((e.id = registrations.event_id) AND (e.registration_type = ANY (ARRAY['INDIVIDUAL'::text, 'BOTH'::text])) AND (e.status = 'REGISTRATION_OPEN'::text))))));

create policy "Captains can create team registrations" on public."registrations" as PERMISSIVE for INSERT to "authenticated" with check (((registration_type = 'TEAM'::text) AND (team_id IS NOT NULL) AND (is_team_captain(team_id) OR can_manage_event(event_id)) AND (EXISTS ( SELECT 1
   FROM teams t
  WHERE ((t.id = registrations.team_id) AND (t.event_id = registrations.event_id)))) AND (EXISTS ( SELECT 1
   FROM events e
  WHERE ((e.id = registrations.event_id) AND (e.registration_type = ANY (ARRAY['TEAM'::text, 'BOTH'::text])) AND ((e.status = 'REGISTRATION_OPEN'::text) OR can_manage_event(e.id)))))));

create policy "Owners can update registrations" on public."registrations" as PERMISSIVE for UPDATE to "authenticated" using (((user_id = auth.uid()) OR ((team_id IS NOT NULL) AND is_team_captain(team_id)) OR can_manage_event(event_id))) with check (((user_id = auth.uid()) OR ((team_id IS NOT NULL) AND is_team_captain(team_id)) OR can_manage_event(event_id)));

create policy "Users can view active event waivers" on public."waivers" as PERMISSIVE for SELECT to "authenticated" using (((active = true) OR can_manage_event(event_id)));

create policy "Organizers can manage waivers" on public."waivers" as PERMISSIVE for ALL to "authenticated" using (can_manage_event(event_id)) with check (can_manage_event(event_id));

create policy "Users can view own waiver acceptances" on public."waiver_acceptances" as PERMISSIVE for SELECT to "authenticated" using (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM waivers w
  WHERE ((w.id = waiver_acceptances.waiver_id) AND can_manage_event(w.event_id))))));

create policy "Users can accept own waivers" on public."waiver_acceptances" as PERMISSIVE for INSERT to "authenticated" with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM waivers w
  WHERE ((w.id = waiver_acceptances.waiver_id) AND (w.active = true))))));

create policy "Authorized users can view payments" on public."payments" as PERMISSIVE for SELECT to "authenticated" using (((user_id = auth.uid()) OR ((team_id IS NOT NULL) AND is_team_captain(team_id)) OR can_manage_event(event_id)));

create policy "Users can view divisions" on public."divisions" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM events e
  WHERE (e.id = divisions.event_id))));

create policy "Organizers can manage divisions" on public."divisions" as PERMISSIVE for ALL to "authenticated" using (can_manage_event(event_id)) with check (can_manage_event(event_id));

create policy "Users can view groups" on public."groups" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM divisions d
  WHERE (d.id = groups.division_id))));

create policy "Organizers can manage groups" on public."groups" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM divisions d
  WHERE ((d.id = groups.division_id) AND can_manage_event(d.event_id))))) with check ((EXISTS ( SELECT 1
   FROM divisions d
  WHERE ((d.id = groups.division_id) AND can_manage_event(d.event_id)))));

create policy "Users can view group members" on public."group_members" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE (g.id = group_members.group_id))));

create policy "Organizers can manage group members" on public."group_members" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE ((g.id = group_members.group_id) AND can_manage_event(d.event_id))))) with check ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE ((g.id = group_members.group_id) AND can_manage_event(d.event_id)))));

create policy "Users can view matches" on public."matches" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM events e
  WHERE (e.id = matches.event_id))));

create policy "Organizers can manage matches" on public."matches" as PERMISSIVE for ALL to "authenticated" using (can_manage_event(event_id)) with check (can_manage_event(event_id));

create policy "Staff can view own match assignments" on public."match_assignments" as PERMISSIVE for SELECT to "authenticated" using (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = match_assignments.match_id) AND can_manage_event(m.event_id))))));

create policy "Organizers can manage match assignments" on public."match_assignments" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = match_assignments.match_id) AND can_manage_event(m.event_id))))) with check ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = match_assignments.match_id) AND can_manage_event(m.event_id)))));

create policy "Users can view match results" on public."match_results" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM matches m
  WHERE (m.id = match_results.match_id))));

create policy "Organizers can manage match results" on public."match_results" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = match_results.match_id) AND can_manage_event(m.event_id))))) with check ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = match_results.match_id) AND can_manage_event(m.event_id)))));

create policy "Users can view cricket innings" on public."cricket_innings" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM matches m
  WHERE (m.id = cricket_innings.match_id))));

create policy "Organizers can manage cricket innings" on public."cricket_innings" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = cricket_innings.match_id) AND can_manage_event(m.event_id))))) with check ((EXISTS ( SELECT 1
   FROM matches m
  WHERE ((m.id = cricket_innings.match_id) AND can_manage_event(m.event_id)))));

create policy "Users can view standings" on public."standings" as PERMISSIVE for SELECT to "authenticated" using ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE (g.id = standings.group_id))));

create policy "Organizers can manage standings" on public."standings" as PERMISSIVE for ALL to "authenticated" using ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE ((g.id = standings.group_id) AND can_manage_event(d.event_id))))) with check ((EXISTS ( SELECT 1
   FROM (groups g
     JOIN divisions d ON ((d.id = g.division_id)))
  WHERE ((g.id = standings.group_id) AND can_manage_event(d.event_id)))));

create policy "Staff can view own event assignments" on public."event_staff_assignments" as PERMISSIVE for SELECT to "authenticated" using ((user_id = auth.uid()));

create policy "Event managers can view event staff" on public."event_staff_assignments" as PERMISSIVE for SELECT to "authenticated" using (can_manage_event(event_id));

create policy "Event managers can add event staff" on public."event_staff_assignments" as PERMISSIVE for INSERT to "authenticated" with check (can_manage_event(event_id));

create policy "Event managers can update event staff" on public."event_staff_assignments" as PERMISSIVE for UPDATE to "authenticated" using (can_manage_event(event_id)) with check (can_manage_event(event_id));

create policy "Event managers can remove event staff" on public."event_staff_assignments" as PERMISSIVE for DELETE to "authenticated" using (can_manage_event(event_id));

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER trg_knockout_advancement AFTER UPDATE OF status, result_status, winner_team_id ON matches FOR EACH ROW WHEN (new.stage = ANY (ARRAY['SEMIFINAL'::text, 'FINAL'::text])) EXECUTE FUNCTION handle_knockout_advancement();

revoke all on public."group_members" from public, anon, authenticated, service_role;

revoke all on public."match_results" from public, anon, authenticated, service_role;

revoke all on public."venues" from public, anon, authenticated, service_role;

revoke all on public."standings" from public, anon, authenticated, service_role;

revoke all on public."sports" from public, anon, authenticated, service_role;

revoke all on public."profiles" from public, anon, authenticated, service_role;

revoke all on public."playing_areas" from public, anon, authenticated, service_role;

revoke all on public."organizations" from public, anon, authenticated, service_role;

revoke all on public."cricket_innings" from public, anon, authenticated, service_role;

revoke all on public."waiver_acceptances" from public, anon, authenticated, service_role;

revoke all on public."team_members" from public, anon, authenticated, service_role;

revoke all on public."matches" from public, anon, authenticated, service_role;

revoke all on public."groups" from public, anon, authenticated, service_role;

revoke all on public."user_roles" from public, anon, authenticated, service_role;

revoke all on public."match_assignments" from public, anon, authenticated, service_role;

revoke all on public."registrations" from public, anon, authenticated, service_role;

revoke all on public."event_staff_assignments" from public, anon, authenticated, service_role;

revoke all on public."teams" from public, anon, authenticated, service_role;

revoke all on public."events" from public, anon, authenticated, service_role;

revoke all on public."divisions" from public, anon, authenticated, service_role;

revoke all on public."waivers" from public, anon, authenticated, service_role;

revoke all on public."payments" from public, anon, authenticated, service_role;

grant INSERT on public."organizations" to "anon";

grant SELECT on public."organizations" to "anon";

grant UPDATE on public."organizations" to "anon";

grant DELETE on public."organizations" to "anon";

grant TRUNCATE on public."organizations" to "anon";

grant REFERENCES on public."organizations" to "anon";

grant TRIGGER on public."organizations" to "anon";

grant INSERT on public."organizations" to "authenticated";

grant SELECT on public."organizations" to "authenticated";

grant UPDATE on public."organizations" to "authenticated";

grant DELETE on public."organizations" to "authenticated";

grant TRUNCATE on public."organizations" to "authenticated";

grant REFERENCES on public."organizations" to "authenticated";

grant TRIGGER on public."organizations" to "authenticated";

grant INSERT on public."organizations" to "service_role";

grant SELECT on public."organizations" to "service_role";

grant UPDATE on public."organizations" to "service_role";

grant DELETE on public."organizations" to "service_role";

grant TRUNCATE on public."organizations" to "service_role";

grant REFERENCES on public."organizations" to "service_role";

grant TRIGGER on public."organizations" to "service_role";

grant INSERT on public."profiles" to "anon";

grant SELECT on public."profiles" to "anon";

grant UPDATE on public."profiles" to "anon";

grant DELETE on public."profiles" to "anon";

grant TRUNCATE on public."profiles" to "anon";

grant REFERENCES on public."profiles" to "anon";

grant TRIGGER on public."profiles" to "anon";

grant INSERT on public."profiles" to "authenticated";

grant SELECT on public."profiles" to "authenticated";

grant UPDATE on public."profiles" to "authenticated";

grant DELETE on public."profiles" to "authenticated";

grant TRUNCATE on public."profiles" to "authenticated";

grant REFERENCES on public."profiles" to "authenticated";

grant TRIGGER on public."profiles" to "authenticated";

grant INSERT on public."profiles" to "service_role";

grant SELECT on public."profiles" to "service_role";

grant UPDATE on public."profiles" to "service_role";

grant DELETE on public."profiles" to "service_role";

grant TRUNCATE on public."profiles" to "service_role";

grant REFERENCES on public."profiles" to "service_role";

grant TRIGGER on public."profiles" to "service_role";

grant INSERT on public."user_roles" to "anon";

grant SELECT on public."user_roles" to "anon";

grant UPDATE on public."user_roles" to "anon";

grant DELETE on public."user_roles" to "anon";

grant TRUNCATE on public."user_roles" to "anon";

grant REFERENCES on public."user_roles" to "anon";

grant TRIGGER on public."user_roles" to "anon";

grant INSERT on public."user_roles" to "authenticated";

grant SELECT on public."user_roles" to "authenticated";

grant UPDATE on public."user_roles" to "authenticated";

grant DELETE on public."user_roles" to "authenticated";

grant TRUNCATE on public."user_roles" to "authenticated";

grant REFERENCES on public."user_roles" to "authenticated";

grant TRIGGER on public."user_roles" to "authenticated";

grant INSERT on public."user_roles" to "service_role";

grant SELECT on public."user_roles" to "service_role";

grant UPDATE on public."user_roles" to "service_role";

grant DELETE on public."user_roles" to "service_role";

grant TRUNCATE on public."user_roles" to "service_role";

grant REFERENCES on public."user_roles" to "service_role";

grant TRIGGER on public."user_roles" to "service_role";

grant INSERT on public."sports" to "anon";

grant SELECT on public."sports" to "anon";

grant UPDATE on public."sports" to "anon";

grant DELETE on public."sports" to "anon";

grant TRUNCATE on public."sports" to "anon";

grant REFERENCES on public."sports" to "anon";

grant TRIGGER on public."sports" to "anon";

grant INSERT on public."sports" to "authenticated";

grant SELECT on public."sports" to "authenticated";

grant UPDATE on public."sports" to "authenticated";

grant DELETE on public."sports" to "authenticated";

grant TRUNCATE on public."sports" to "authenticated";

grant REFERENCES on public."sports" to "authenticated";

grant TRIGGER on public."sports" to "authenticated";

grant INSERT on public."sports" to "service_role";

grant SELECT on public."sports" to "service_role";

grant UPDATE on public."sports" to "service_role";

grant DELETE on public."sports" to "service_role";

grant TRUNCATE on public."sports" to "service_role";

grant REFERENCES on public."sports" to "service_role";

grant TRIGGER on public."sports" to "service_role";

grant INSERT on public."venues" to "anon";

grant SELECT on public."venues" to "anon";

grant UPDATE on public."venues" to "anon";

grant DELETE on public."venues" to "anon";

grant TRUNCATE on public."venues" to "anon";

grant REFERENCES on public."venues" to "anon";

grant TRIGGER on public."venues" to "anon";

grant INSERT on public."venues" to "authenticated";

grant SELECT on public."venues" to "authenticated";

grant UPDATE on public."venues" to "authenticated";

grant DELETE on public."venues" to "authenticated";

grant TRUNCATE on public."venues" to "authenticated";

grant REFERENCES on public."venues" to "authenticated";

grant TRIGGER on public."venues" to "authenticated";

grant INSERT on public."venues" to "service_role";

grant SELECT on public."venues" to "service_role";

grant UPDATE on public."venues" to "service_role";

grant DELETE on public."venues" to "service_role";

grant TRUNCATE on public."venues" to "service_role";

grant REFERENCES on public."venues" to "service_role";

grant TRIGGER on public."venues" to "service_role";

grant INSERT on public."playing_areas" to "anon";

grant SELECT on public."playing_areas" to "anon";

grant UPDATE on public."playing_areas" to "anon";

grant DELETE on public."playing_areas" to "anon";

grant TRUNCATE on public."playing_areas" to "anon";

grant REFERENCES on public."playing_areas" to "anon";

grant TRIGGER on public."playing_areas" to "anon";

grant INSERT on public."playing_areas" to "authenticated";

grant SELECT on public."playing_areas" to "authenticated";

grant UPDATE on public."playing_areas" to "authenticated";

grant DELETE on public."playing_areas" to "authenticated";

grant TRUNCATE on public."playing_areas" to "authenticated";

grant REFERENCES on public."playing_areas" to "authenticated";

grant TRIGGER on public."playing_areas" to "authenticated";

grant INSERT on public."playing_areas" to "service_role";

grant SELECT on public."playing_areas" to "service_role";

grant UPDATE on public."playing_areas" to "service_role";

grant DELETE on public."playing_areas" to "service_role";

grant TRUNCATE on public."playing_areas" to "service_role";

grant REFERENCES on public."playing_areas" to "service_role";

grant TRIGGER on public."playing_areas" to "service_role";

grant INSERT on public."events" to "anon";

grant SELECT on public."events" to "anon";

grant UPDATE on public."events" to "anon";

grant DELETE on public."events" to "anon";

grant TRUNCATE on public."events" to "anon";

grant REFERENCES on public."events" to "anon";

grant TRIGGER on public."events" to "anon";

grant INSERT on public."events" to "authenticated";

grant SELECT on public."events" to "authenticated";

grant UPDATE on public."events" to "authenticated";

grant DELETE on public."events" to "authenticated";

grant TRUNCATE on public."events" to "authenticated";

grant REFERENCES on public."events" to "authenticated";

grant TRIGGER on public."events" to "authenticated";

grant INSERT on public."events" to "service_role";

grant SELECT on public."events" to "service_role";

grant UPDATE on public."events" to "service_role";

grant DELETE on public."events" to "service_role";

grant TRUNCATE on public."events" to "service_role";

grant REFERENCES on public."events" to "service_role";

grant TRIGGER on public."events" to "service_role";

grant INSERT on public."teams" to "anon";

grant SELECT on public."teams" to "anon";

grant UPDATE on public."teams" to "anon";

grant DELETE on public."teams" to "anon";

grant TRUNCATE on public."teams" to "anon";

grant REFERENCES on public."teams" to "anon";

grant TRIGGER on public."teams" to "anon";

grant INSERT on public."teams" to "authenticated";

grant SELECT on public."teams" to "authenticated";

grant UPDATE on public."teams" to "authenticated";

grant DELETE on public."teams" to "authenticated";

grant TRUNCATE on public."teams" to "authenticated";

grant REFERENCES on public."teams" to "authenticated";

grant TRIGGER on public."teams" to "authenticated";

grant INSERT on public."teams" to "service_role";

grant SELECT on public."teams" to "service_role";

grant UPDATE on public."teams" to "service_role";

grant DELETE on public."teams" to "service_role";

grant TRUNCATE on public."teams" to "service_role";

grant REFERENCES on public."teams" to "service_role";

grant TRIGGER on public."teams" to "service_role";

grant INSERT on public."team_members" to "anon";

grant SELECT on public."team_members" to "anon";

grant UPDATE on public."team_members" to "anon";

grant DELETE on public."team_members" to "anon";

grant TRUNCATE on public."team_members" to "anon";

grant REFERENCES on public."team_members" to "anon";

grant TRIGGER on public."team_members" to "anon";

grant INSERT on public."team_members" to "authenticated";

grant SELECT on public."team_members" to "authenticated";

grant UPDATE on public."team_members" to "authenticated";

grant DELETE on public."team_members" to "authenticated";

grant TRUNCATE on public."team_members" to "authenticated";

grant REFERENCES on public."team_members" to "authenticated";

grant TRIGGER on public."team_members" to "authenticated";

grant INSERT on public."team_members" to "service_role";

grant SELECT on public."team_members" to "service_role";

grant UPDATE on public."team_members" to "service_role";

grant DELETE on public."team_members" to "service_role";

grant TRUNCATE on public."team_members" to "service_role";

grant REFERENCES on public."team_members" to "service_role";

grant TRIGGER on public."team_members" to "service_role";

grant INSERT on public."registrations" to "anon";

grant SELECT on public."registrations" to "anon";

grant UPDATE on public."registrations" to "anon";

grant DELETE on public."registrations" to "anon";

grant TRUNCATE on public."registrations" to "anon";

grant REFERENCES on public."registrations" to "anon";

grant TRIGGER on public."registrations" to "anon";

grant INSERT on public."registrations" to "authenticated";

grant SELECT on public."registrations" to "authenticated";

grant UPDATE on public."registrations" to "authenticated";

grant DELETE on public."registrations" to "authenticated";

grant TRUNCATE on public."registrations" to "authenticated";

grant REFERENCES on public."registrations" to "authenticated";

grant TRIGGER on public."registrations" to "authenticated";

grant INSERT on public."registrations" to "service_role";

grant SELECT on public."registrations" to "service_role";

grant UPDATE on public."registrations" to "service_role";

grant DELETE on public."registrations" to "service_role";

grant TRUNCATE on public."registrations" to "service_role";

grant REFERENCES on public."registrations" to "service_role";

grant TRIGGER on public."registrations" to "service_role";

grant INSERT on public."waivers" to "anon";

grant SELECT on public."waivers" to "anon";

grant UPDATE on public."waivers" to "anon";

grant DELETE on public."waivers" to "anon";

grant TRUNCATE on public."waivers" to "anon";

grant REFERENCES on public."waivers" to "anon";

grant TRIGGER on public."waivers" to "anon";

grant INSERT on public."waivers" to "authenticated";

grant SELECT on public."waivers" to "authenticated";

grant UPDATE on public."waivers" to "authenticated";

grant DELETE on public."waivers" to "authenticated";

grant TRUNCATE on public."waivers" to "authenticated";

grant REFERENCES on public."waivers" to "authenticated";

grant TRIGGER on public."waivers" to "authenticated";

grant INSERT on public."waivers" to "service_role";

grant SELECT on public."waivers" to "service_role";

grant UPDATE on public."waivers" to "service_role";

grant DELETE on public."waivers" to "service_role";

grant TRUNCATE on public."waivers" to "service_role";

grant REFERENCES on public."waivers" to "service_role";

grant TRIGGER on public."waivers" to "service_role";

grant INSERT on public."waiver_acceptances" to "anon";

grant SELECT on public."waiver_acceptances" to "anon";

grant UPDATE on public."waiver_acceptances" to "anon";

grant DELETE on public."waiver_acceptances" to "anon";

grant TRUNCATE on public."waiver_acceptances" to "anon";

grant REFERENCES on public."waiver_acceptances" to "anon";

grant TRIGGER on public."waiver_acceptances" to "anon";

grant INSERT on public."waiver_acceptances" to "authenticated";

grant SELECT on public."waiver_acceptances" to "authenticated";

grant UPDATE on public."waiver_acceptances" to "authenticated";

grant DELETE on public."waiver_acceptances" to "authenticated";

grant TRUNCATE on public."waiver_acceptances" to "authenticated";

grant REFERENCES on public."waiver_acceptances" to "authenticated";

grant TRIGGER on public."waiver_acceptances" to "authenticated";

grant INSERT on public."waiver_acceptances" to "service_role";

grant SELECT on public."waiver_acceptances" to "service_role";

grant UPDATE on public."waiver_acceptances" to "service_role";

grant DELETE on public."waiver_acceptances" to "service_role";

grant TRUNCATE on public."waiver_acceptances" to "service_role";

grant REFERENCES on public."waiver_acceptances" to "service_role";

grant TRIGGER on public."waiver_acceptances" to "service_role";

grant INSERT on public."payments" to "anon";

grant SELECT on public."payments" to "anon";

grant UPDATE on public."payments" to "anon";

grant DELETE on public."payments" to "anon";

grant TRUNCATE on public."payments" to "anon";

grant REFERENCES on public."payments" to "anon";

grant TRIGGER on public."payments" to "anon";

grant INSERT on public."payments" to "authenticated";

grant SELECT on public."payments" to "authenticated";

grant UPDATE on public."payments" to "authenticated";

grant DELETE on public."payments" to "authenticated";

grant TRUNCATE on public."payments" to "authenticated";

grant REFERENCES on public."payments" to "authenticated";

grant TRIGGER on public."payments" to "authenticated";

grant INSERT on public."payments" to "service_role";

grant SELECT on public."payments" to "service_role";

grant UPDATE on public."payments" to "service_role";

grant DELETE on public."payments" to "service_role";

grant TRUNCATE on public."payments" to "service_role";

grant REFERENCES on public."payments" to "service_role";

grant TRIGGER on public."payments" to "service_role";

grant INSERT on public."divisions" to "anon";

grant SELECT on public."divisions" to "anon";

grant UPDATE on public."divisions" to "anon";

grant DELETE on public."divisions" to "anon";

grant TRUNCATE on public."divisions" to "anon";

grant REFERENCES on public."divisions" to "anon";

grant TRIGGER on public."divisions" to "anon";

grant INSERT on public."divisions" to "authenticated";

grant SELECT on public."divisions" to "authenticated";

grant UPDATE on public."divisions" to "authenticated";

grant DELETE on public."divisions" to "authenticated";

grant TRUNCATE on public."divisions" to "authenticated";

grant REFERENCES on public."divisions" to "authenticated";

grant TRIGGER on public."divisions" to "authenticated";

grant INSERT on public."divisions" to "service_role";

grant SELECT on public."divisions" to "service_role";

grant UPDATE on public."divisions" to "service_role";

grant DELETE on public."divisions" to "service_role";

grant TRUNCATE on public."divisions" to "service_role";

grant REFERENCES on public."divisions" to "service_role";

grant TRIGGER on public."divisions" to "service_role";

grant INSERT on public."groups" to "anon";

grant SELECT on public."groups" to "anon";

grant UPDATE on public."groups" to "anon";

grant DELETE on public."groups" to "anon";

grant TRUNCATE on public."groups" to "anon";

grant REFERENCES on public."groups" to "anon";

grant TRIGGER on public."groups" to "anon";

grant INSERT on public."groups" to "authenticated";

grant SELECT on public."groups" to "authenticated";

grant UPDATE on public."groups" to "authenticated";

grant DELETE on public."groups" to "authenticated";

grant TRUNCATE on public."groups" to "authenticated";

grant REFERENCES on public."groups" to "authenticated";

grant TRIGGER on public."groups" to "authenticated";

grant INSERT on public."groups" to "service_role";

grant SELECT on public."groups" to "service_role";

grant UPDATE on public."groups" to "service_role";

grant DELETE on public."groups" to "service_role";

grant TRUNCATE on public."groups" to "service_role";

grant REFERENCES on public."groups" to "service_role";

grant TRIGGER on public."groups" to "service_role";

grant INSERT on public."group_members" to "anon";

grant SELECT on public."group_members" to "anon";

grant UPDATE on public."group_members" to "anon";

grant DELETE on public."group_members" to "anon";

grant TRUNCATE on public."group_members" to "anon";

grant REFERENCES on public."group_members" to "anon";

grant TRIGGER on public."group_members" to "anon";

grant INSERT on public."group_members" to "authenticated";

grant SELECT on public."group_members" to "authenticated";

grant UPDATE on public."group_members" to "authenticated";

grant DELETE on public."group_members" to "authenticated";

grant TRUNCATE on public."group_members" to "authenticated";

grant REFERENCES on public."group_members" to "authenticated";

grant TRIGGER on public."group_members" to "authenticated";

grant INSERT on public."group_members" to "service_role";

grant SELECT on public."group_members" to "service_role";

grant UPDATE on public."group_members" to "service_role";

grant DELETE on public."group_members" to "service_role";

grant TRUNCATE on public."group_members" to "service_role";

grant REFERENCES on public."group_members" to "service_role";

grant TRIGGER on public."group_members" to "service_role";

grant INSERT on public."match_assignments" to "anon";

grant SELECT on public."match_assignments" to "anon";

grant UPDATE on public."match_assignments" to "anon";

grant DELETE on public."match_assignments" to "anon";

grant TRUNCATE on public."match_assignments" to "anon";

grant REFERENCES on public."match_assignments" to "anon";

grant TRIGGER on public."match_assignments" to "anon";

grant INSERT on public."match_assignments" to "authenticated";

grant SELECT on public."match_assignments" to "authenticated";

grant UPDATE on public."match_assignments" to "authenticated";

grant DELETE on public."match_assignments" to "authenticated";

grant TRUNCATE on public."match_assignments" to "authenticated";

grant REFERENCES on public."match_assignments" to "authenticated";

grant TRIGGER on public."match_assignments" to "authenticated";

grant INSERT on public."match_assignments" to "service_role";

grant SELECT on public."match_assignments" to "service_role";

grant UPDATE on public."match_assignments" to "service_role";

grant DELETE on public."match_assignments" to "service_role";

grant TRUNCATE on public."match_assignments" to "service_role";

grant REFERENCES on public."match_assignments" to "service_role";

grant TRIGGER on public."match_assignments" to "service_role";

grant INSERT on public."match_results" to "anon";

grant SELECT on public."match_results" to "anon";

grant UPDATE on public."match_results" to "anon";

grant DELETE on public."match_results" to "anon";

grant TRUNCATE on public."match_results" to "anon";

grant REFERENCES on public."match_results" to "anon";

grant TRIGGER on public."match_results" to "anon";

grant INSERT on public."match_results" to "authenticated";

grant SELECT on public."match_results" to "authenticated";

grant UPDATE on public."match_results" to "authenticated";

grant DELETE on public."match_results" to "authenticated";

grant TRUNCATE on public."match_results" to "authenticated";

grant REFERENCES on public."match_results" to "authenticated";

grant TRIGGER on public."match_results" to "authenticated";

grant INSERT on public."match_results" to "service_role";

grant SELECT on public."match_results" to "service_role";

grant UPDATE on public."match_results" to "service_role";

grant DELETE on public."match_results" to "service_role";

grant TRUNCATE on public."match_results" to "service_role";

grant REFERENCES on public."match_results" to "service_role";

grant TRIGGER on public."match_results" to "service_role";

grant INSERT on public."cricket_innings" to "anon";

grant SELECT on public."cricket_innings" to "anon";

grant UPDATE on public."cricket_innings" to "anon";

grant DELETE on public."cricket_innings" to "anon";

grant TRUNCATE on public."cricket_innings" to "anon";

grant REFERENCES on public."cricket_innings" to "anon";

grant TRIGGER on public."cricket_innings" to "anon";

grant INSERT on public."cricket_innings" to "authenticated";

grant SELECT on public."cricket_innings" to "authenticated";

grant UPDATE on public."cricket_innings" to "authenticated";

grant DELETE on public."cricket_innings" to "authenticated";

grant TRUNCATE on public."cricket_innings" to "authenticated";

grant REFERENCES on public."cricket_innings" to "authenticated";

grant TRIGGER on public."cricket_innings" to "authenticated";

grant INSERT on public."cricket_innings" to "service_role";

grant SELECT on public."cricket_innings" to "service_role";

grant UPDATE on public."cricket_innings" to "service_role";

grant DELETE on public."cricket_innings" to "service_role";

grant TRUNCATE on public."cricket_innings" to "service_role";

grant REFERENCES on public."cricket_innings" to "service_role";

grant TRIGGER on public."cricket_innings" to "service_role";

grant INSERT on public."standings" to "anon";

grant SELECT on public."standings" to "anon";

grant UPDATE on public."standings" to "anon";

grant DELETE on public."standings" to "anon";

grant TRUNCATE on public."standings" to "anon";

grant REFERENCES on public."standings" to "anon";

grant TRIGGER on public."standings" to "anon";

grant INSERT on public."standings" to "authenticated";

grant SELECT on public."standings" to "authenticated";

grant UPDATE on public."standings" to "authenticated";

grant DELETE on public."standings" to "authenticated";

grant TRUNCATE on public."standings" to "authenticated";

grant REFERENCES on public."standings" to "authenticated";

grant TRIGGER on public."standings" to "authenticated";

grant INSERT on public."standings" to "service_role";

grant SELECT on public."standings" to "service_role";

grant UPDATE on public."standings" to "service_role";

grant DELETE on public."standings" to "service_role";

grant TRUNCATE on public."standings" to "service_role";

grant REFERENCES on public."standings" to "service_role";

grant TRIGGER on public."standings" to "service_role";

grant INSERT on public."matches" to "anon";

grant SELECT on public."matches" to "anon";

grant UPDATE on public."matches" to "anon";

grant DELETE on public."matches" to "anon";

grant TRUNCATE on public."matches" to "anon";

grant REFERENCES on public."matches" to "anon";

grant TRIGGER on public."matches" to "anon";

grant INSERT on public."matches" to "authenticated";

grant SELECT on public."matches" to "authenticated";

grant UPDATE on public."matches" to "authenticated";

grant DELETE on public."matches" to "authenticated";

grant TRUNCATE on public."matches" to "authenticated";

grant REFERENCES on public."matches" to "authenticated";

grant TRIGGER on public."matches" to "authenticated";

grant INSERT on public."matches" to "service_role";

grant SELECT on public."matches" to "service_role";

grant UPDATE on public."matches" to "service_role";

grant DELETE on public."matches" to "service_role";

grant TRUNCATE on public."matches" to "service_role";

grant REFERENCES on public."matches" to "service_role";

grant TRIGGER on public."matches" to "service_role";

grant INSERT on public."event_staff_assignments" to "anon";

grant SELECT on public."event_staff_assignments" to "anon";

grant UPDATE on public."event_staff_assignments" to "anon";

grant DELETE on public."event_staff_assignments" to "anon";

grant TRUNCATE on public."event_staff_assignments" to "anon";

grant REFERENCES on public."event_staff_assignments" to "anon";

grant TRIGGER on public."event_staff_assignments" to "anon";

grant INSERT on public."event_staff_assignments" to "authenticated";

grant SELECT on public."event_staff_assignments" to "authenticated";

grant UPDATE on public."event_staff_assignments" to "authenticated";

grant DELETE on public."event_staff_assignments" to "authenticated";

grant TRUNCATE on public."event_staff_assignments" to "authenticated";

grant REFERENCES on public."event_staff_assignments" to "authenticated";

grant TRIGGER on public."event_staff_assignments" to "authenticated";

grant INSERT on public."event_staff_assignments" to "service_role";

grant SELECT on public."event_staff_assignments" to "service_role";

grant UPDATE on public."event_staff_assignments" to "service_role";

grant DELETE on public."event_staff_assignments" to "service_role";

grant TRUNCATE on public."event_staff_assignments" to "service_role";

grant REFERENCES on public."event_staff_assignments" to "service_role";

grant TRIGGER on public."event_staff_assignments" to "service_role";

revoke all on function public."is_super_admin"() from public, anon, authenticated, service_role;

grant execute on function public."is_super_admin"() to "anon";

grant execute on function public."is_super_admin"() to "authenticated";

grant execute on function public."is_super_admin"() to "service_role";

revoke all on function public."is_organizer"(p_organization_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."is_organizer"(p_organization_id uuid) to "anon";

grant execute on function public."is_organizer"(p_organization_id uuid) to "authenticated";

grant execute on function public."is_organizer"(p_organization_id uuid) to "service_role";

revoke all on function public."has_event_role"(p_event_id uuid, p_role text) from public, anon, authenticated, service_role;

grant execute on function public."has_event_role"(p_event_id uuid, p_role text) to "anon";

grant execute on function public."has_event_role"(p_event_id uuid, p_role text) to "authenticated";

grant execute on function public."has_event_role"(p_event_id uuid, p_role text) to "service_role";

revoke all on function public."can_manage_event"(p_event_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."can_manage_event"(p_event_id uuid) to "anon";

grant execute on function public."can_manage_event"(p_event_id uuid) to "authenticated";

grant execute on function public."can_manage_event"(p_event_id uuid) to "service_role";

revoke all on function public."is_team_captain"(p_team_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."is_team_captain"(p_team_id uuid) to "anon";

grant execute on function public."is_team_captain"(p_team_id uuid) to "authenticated";

grant execute on function public."is_team_captain"(p_team_id uuid) to "service_role";

revoke all on function public."handle_new_user"() from public, anon, authenticated, service_role;

grant execute on function public."handle_new_user"() to public;

grant execute on function public."handle_new_user"() to "anon";

grant execute on function public."handle_new_user"() to "authenticated";

grant execute on function public."handle_new_user"() to "service_role";

revoke all on function public."validate_match_schedule"() from public, anon, authenticated, service_role;

grant execute on function public."validate_match_schedule"() to public;

grant execute on function public."validate_match_schedule"() to "anon";

grant execute on function public."validate_match_schedule"() to "authenticated";

grant execute on function public."validate_match_schedule"() to "service_role";

revoke all on function public."recalculate_cricket_standings"(p_group_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."recalculate_cricket_standings"(p_group_id uuid) to "anon";

grant execute on function public."recalculate_cricket_standings"(p_group_id uuid) to "authenticated";

grant execute on function public."recalculate_cricket_standings"(p_group_id uuid) to "service_role";

revoke all on function public."record_cricket_result"(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer) from public, anon, authenticated, service_role;

grant execute on function public."record_cricket_result"(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer) to "anon";

grant execute on function public."record_cricket_result"(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer) to "authenticated";

grant execute on function public."record_cricket_result"(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer) to "service_role";

revoke all on function public."resolve_semifinalists"(p_event_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."resolve_semifinalists"(p_event_id uuid) to "anon";

grant execute on function public."resolve_semifinalists"(p_event_id uuid) to "authenticated";

grant execute on function public."resolve_semifinalists"(p_event_id uuid) to "service_role";

revoke all on function public."resolve_finalists"(p_event_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."resolve_finalists"(p_event_id uuid) to "anon";

grant execute on function public."resolve_finalists"(p_event_id uuid) to "authenticated";

grant execute on function public."resolve_finalists"(p_event_id uuid) to "service_role";

revoke all on function public."handle_knockout_advancement"() from public, anon, authenticated, service_role;

grant execute on function public."handle_knockout_advancement"() to "anon";

grant execute on function public."handle_knockout_advancement"() to "authenticated";

grant execute on function public."handle_knockout_advancement"() to "service_role";

revoke all on function public."complete_tournament"(p_event_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."complete_tournament"(p_event_id uuid) to "anon";

grant execute on function public."complete_tournament"(p_event_id uuid) to "authenticated";

grant execute on function public."complete_tournament"(p_event_id uuid) to "service_role";

revoke all on function public."is_event_staff"(p_event_id uuid) from public, anon, authenticated, service_role;

grant execute on function public."is_event_staff"(p_event_id uuid) to "anon";

grant execute on function public."is_event_staff"(p_event_id uuid) to "authenticated";

grant execute on function public."is_event_staff"(p_event_id uuid) to "service_role";

revoke all on function public."has_event_staff_role"(p_event_id uuid, p_staff_role text) from public, anon, authenticated, service_role;

grant execute on function public."has_event_staff_role"(p_event_id uuid, p_staff_role text) to "anon";

grant execute on function public."has_event_staff_role"(p_event_id uuid, p_staff_role text) to "authenticated";

grant execute on function public."has_event_staff_role"(p_event_id uuid, p_staff_role text) to "service_role";

grant usage on schema public to anon, authenticated, service_role;

commit;

