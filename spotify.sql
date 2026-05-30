-- ============================================================= 
-- Advanced SQL Project | Spotify Dataset Analysis
-- =============================================================
-- Description  : End-to-end SQL analysis of Spotify streaming data
-- Tool         : PostgreSQL (PG Admin 4)
-- Dataset      : ~20,000+ track records from Kaggle
-- Difficulty   : Easy | Medium | Advanced
-- Total Queries: 15 Business Problems
-- =============================================================


-- =============================================================
-- SECTION 1: TABLE SETUP
-- =============================================================

-- Drop the table if it already exists to allow a clean re-run
DROP TABLE IF EXISTS spotify;

-- Create the main Spotify table with appropriate data types
CREATE TABLE spotify (
    artist            VARCHAR(255),   -- Name of the artist
    track             VARCHAR(255),   -- Song/track name
    album             VARCHAR(255),   -- Album the track belongs to
    album_type        VARCHAR(50),    -- Type: 'album', 'single', or 'compilation'
    danceability      FLOAT,          -- Danceability score        (0.0 - 1.0)
    energy            FLOAT,          -- Energy level              (0.0 - 1.0)
    loudness          FLOAT,          -- Loudness in decibels
    speechiness       FLOAT,          -- Presence of spoken words  (0.0 - 1.0)
    acousticness      FLOAT,          -- Acoustic quality score    (0.0 - 1.0)
    instrumentalness  FLOAT,          -- Instrumental content      (0.0 - 1.0)
    liveness          FLOAT,          -- Live performance score    (0.0 - 1.0)
    valence           FLOAT,          -- Musical positivity score  (0.0 - 1.0)
    tempo             FLOAT,          -- Beats per minute (BPM)
    duration_min      FLOAT,          -- Track duration in minutes
    title             VARCHAR(255),   -- Title of associated video/content
    channel           VARCHAR(255),   -- Publishing channel name
    views             FLOAT,          -- Total YouTube views
    likes             BIGINT,         -- Total likes on YouTube
    comments          BIGINT,         -- Total comments on YouTube
    licensed          BOOLEAN,        -- Track is licensed         (TRUE/FALSE)
    official_video    BOOLEAN,        -- Official video exists     (TRUE/FALSE)
    stream            BIGINT,         -- Total Spotify streams
    energy_liveness   FLOAT,          -- Combined energy-liveness metric
    most_played_on    VARCHAR(50)     -- Primary platform: 'Spotify' or 'Youtube'
);


-- =============================================================
-- SECTION 2: QUICK LOOK AT THE DATA
-- =============================================================

-- Preview the first 100 rows to verify import was successful
SELECT *
FROM spotify
LIMIT 100;


-- =============================================================
-- SECTION 3: EXPLORATORY DATA ANALYSIS (EDA)
-- =============================================================

-- -------------------------------------------------------------
-- 3.1 Row & Cardinality Counts
-- -------------------------------------------------------------

-- Total number of records in the dataset
SELECT COUNT(*)                  AS total_records    FROM spotify;

-- Number of unique artists
SELECT COUNT(DISTINCT artist)    AS unique_artists   FROM spotify;

-- Number of unique albums
SELECT COUNT(DISTINCT album)     AS unique_albums    FROM spotify;

-- Number of unique publishing channels
SELECT COUNT(DISTINCT channel)   AS unique_channels  FROM spotify;

-- All distinct album types (album / single / compilation)
SELECT DISTINCT album_type       FROM spotify;

-- All distinct streaming platforms (Spotify / Youtube)
SELECT DISTINCT most_played_on   FROM spotify;


-- -------------------------------------------------------------
-- 3.2 Duration Analysis
-- -------------------------------------------------------------

-- Longest track in the dataset (in minutes)
SELECT MAX(duration_min) AS max_duration_min FROM spotify;

-- Shortest track in the dataset (in minutes)
SELECT MIN(duration_min) AS min_duration_min FROM spotify;


-- -------------------------------------------------------------
-- 3.3 Data Quality Check & Cleaning
-- -------------------------------------------------------------

-- Identify tracks with zero duration — these are invalid records
SELECT *
FROM spotify
WHERE duration_min = 0;

-- Delete invalid tracks with zero duration
DELETE FROM spotify
WHERE duration_min = 0;

-- Confirm deletion — this should return 0 rows
SELECT *
FROM spotify
WHERE duration_min = 0;


-- =============================================================
-- SECTION 4: BUSINESS PROBLEMS — EASY LEVEL (Q1 to Q5)
-- =============================================================
-- Concepts Used: WHERE, DISTINCT, SUM, COUNT, GROUP BY, ORDER BY
-- =============================================================

-- -------------------------------------------------------------
-- Q1. Retrieve the names of all tracks that have more than
--     1 billion streams.
-- -------------------------------------------------------------

SELECT *
FROM spotify
WHERE stream > 1000000000;


-- -------------------------------------------------------------
-- Q2. List all albums along with their respective artists.
-- -------------------------------------------------------------

SELECT DISTINCT
    album,
    artist
FROM spotify
ORDER BY album;


-- -------------------------------------------------------------
-- Q3. Get the total number of comments for tracks
--     where licensed = TRUE.
-- -------------------------------------------------------------

SELECT 
    SUM(comments) AS total_comments
FROM spotify
WHERE licensed = TRUE;


-- -------------------------------------------------------------
-- Q4. Find all tracks that belong to the album type 'single'.
-- -------------------------------------------------------------

SELECT *
FROM spotify
WHERE album_type = 'single';


-- -------------------------------------------------------------
-- Q5. Count the total number of tracks by each artist.
-- -------------------------------------------------------------

SELECT 
    artist,
    COUNT(*)  AS total_tracks
FROM spotify
GROUP BY artist
ORDER BY total_tracks DESC;


-- =============================================================
-- SECTION 5: BUSINESS PROBLEMS — MEDIUM LEVEL (Q6 to Q10)
-- =============================================================
-- Concepts Used: AVG, GROUP BY, HAVING, CASE, CTE, Subquery
-- =============================================================

-- -------------------------------------------------------------
-- Q6. Calculate the average danceability of tracks
--     in each album.
-- -------------------------------------------------------------

SELECT 
    album,
    ROUND(AVG(danceability)::NUMERIC, 4) AS avg_danceability
FROM spotify
GROUP BY album
ORDER BY avg_danceability DESC;


-- -------------------------------------------------------------
-- Q7. Find the top 5 tracks with the highest energy values.
-- -------------------------------------------------------------

SELECT 
    track,
    MAX(energy) AS max_energy
FROM spotify
GROUP BY track
ORDER BY max_energy DESC
LIMIT 5;


-- -------------------------------------------------------------
-- Q8. List all tracks along with their views and likes
--     where official_video = TRUE.
-- -------------------------------------------------------------

SELECT 
    track,
    SUM(views) AS total_views,
    SUM(likes) AS total_likes
FROM spotify
WHERE official_video = TRUE
GROUP BY track
ORDER BY total_views DESC;


-- -------------------------------------------------------------
-- Q9. For each album, calculate the total views of all
--     associated tracks.
-- -------------------------------------------------------------

SELECT 
    album,
    track,
    SUM(views) AS total_views
FROM spotify
GROUP BY album, track
ORDER BY total_views DESC;


-- -------------------------------------------------------------
-- Q10. Retrieve the track names that have been streamed
--      on Spotify more than YouTube.
-- -------------------------------------------------------------
-- Approach : Pivot stream counts per platform using CASE,
--            then filter where Spotify > YouTube.
-- Note     : COALESCE handles NULL when a track exists on
--            only one platform — replaces NULL with 0.
-- -------------------------------------------------------------

WITH cte AS (
    SELECT 
        track,
        COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END), 0) AS streamed_on_youtube,
        COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END), 0) AS streamed_on_spotify
    FROM spotify
    GROUP BY track
)
SELECT *
FROM cte
WHERE streamed_on_spotify  > streamed_on_youtube
  AND streamed_on_youtube <> 0       -- exclude tracks absent from YouTube
ORDER BY streamed_on_spotify DESC;


-- =============================================================
-- SECTION 6: BUSINESS PROBLEMS — ADVANCED LEVEL (Q11 to Q15)
-- =============================================================
-- Concepts Used: Window Functions, CTE, DENSE_RANK,
--                SUM OVER, Subquery, ROUND, CAST
-- =============================================================

-- -------------------------------------------------------------
-- Q11. Find the top 3 most-viewed tracks for each artist
--      using window functions.
-- -------------------------------------------------------------
-- Approach  : Aggregate views per artist-track, then rank using
--             DENSE_RANK so tied view counts share the same rank
--             with no gaps (unlike RANK which skips numbers).
-- -------------------------------------------------------------

WITH cte AS (
    SELECT 
        artist,
        track,
        SUM(views) AS total_views,
        DENSE_RANK() OVER (
            PARTITION BY artist
            ORDER BY SUM(views) DESC
        )          AS rnk
    FROM spotify
    GROUP BY artist, track
)
SELECT *
FROM cte
WHERE rnk <= 3
ORDER BY artist, total_views DESC;


-- -------------------------------------------------------------
-- Q12. Find tracks where the liveness score is above average.
-- -------------------------------------------------------------
-- Approach  : Use a subquery in WHERE to dynamically calculate
--             the average — avoids hardcoding the value.
-- -------------------------------------------------------------

SELECT 
    track,
    artist,
    liveness
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify)
ORDER BY liveness DESC;


-- -------------------------------------------------------------
-- Q13. Calculate the difference between the highest and lowest
--      energy values for tracks in each album.
-- -------------------------------------------------------------
-- Approach  : CTE aggregates MAX and MIN energy per album,
--             outer query computes and rounds the difference.
-- Note      : CAST to NUMERIC required because PostgreSQL's
--             ROUND() does not accept FLOAT directly.
-- -------------------------------------------------------------

WITH cte AS (
    SELECT 
        album,
        MAX(energy) AS highest_energy,
        MIN(energy) AS lowest_energy
    FROM spotify
    GROUP BY album
)
SELECT 
    album,
    ROUND(
        CAST(highest_energy - lowest_energy AS NUMERIC), 2
    ) AS energy_difference
FROM cte
ORDER BY energy_difference DESC;


-- -------------------------------------------------------------
-- Q14. Find tracks where the energy-to-liveness ratio
--      is greater than 1.2.
-- -------------------------------------------------------------
-- Note : liveness > 0 guard prevents division-by-zero errors.
-- -------------------------------------------------------------

SELECT 
    track,
    energy,
    liveness,
    ROUND(
        CAST(energy / liveness AS NUMERIC), 2
    ) AS energy_liveness_ratio
FROM spotify
WHERE liveness      > 0
  AND energy / liveness > 1.2
ORDER BY energy_liveness_ratio DESC;


-- -------------------------------------------------------------
-- Q15. Calculate the cumulative sum of likes for tracks
--      ordered by the number of views, using window functions.
-- -------------------------------------------------------------
-- Approach  : SUM(...) OVER (ORDER BY views DESC) accumulates
--             likes from the most-viewed track downward.
--             Both the window ORDER BY and final ORDER BY use
--             DESC so the cumulative sum and row order match.
-- -------------------------------------------------------------

SELECT 
    track,
    views,
    likes,
    SUM(likes) OVER (
        ORDER BY views DESC
    ) AS cumulative_likes
FROM spotify
ORDER BY views DESC;


-- =============================================================
-- END OF PROJECT
-- =============================================================