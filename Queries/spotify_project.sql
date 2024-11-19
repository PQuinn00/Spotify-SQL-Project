-- Spotify Portfolio Project

-- Create table
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

-- EDA
SELECT COUNT(*)
FROM spotify;

SELECT COUNT(DISTINCT artist)
FROM spotify;


SELECT COUNT(DISTINCT album)
FROM spotify;


SELECT DISTINCT album_type
FROM spotify;

SELECT DISTINCT channel
FROM spotify;


SELECT DISTINCT most_played_on
FROM spotify;

SELECT MAX(duration_min)
FROM spotify;

SELECT MIN(duration_min)
FROM spotify;
-- Above query returns zero so I want to check the value because 
-- it is impossible for a song to have duration 0

SELECT * FROM spotify
WHERE duration_min = 0;
-- The query returns two songs  with missing records so I am going to remove them from the table

DELETE FROM spotify
WHERE duration_min = 0;

SELECT * FROM spotify
WHERE duration_min = 0;
-- Now we see no songs have a duration of 0 minutes 

-- Questions To Be Answered
/*
1.) Retrieve the names of all tracks that have more than 1 billion streams.
2.) List all albums along with their respective artists.
3.) Get the total number of comments for tracks where licensed = TRUE.
4.) Find all tracks that belong to the album type single.
5.) Count the total number of tracks by each artist.
6.) Calculate the average danceability of tracks in each album.
7.) Find the top 5 tracks with the highest energy values.
8.) List all tracks along with their views and likes where official_video = TRUE.
9.) For each album, calculate the total views of all associated tracks.
10.) Retrieve the track names that have been streamed on Spotify more than YouTube.
11.) Find the top 3 most-viewed tracks for each artist using window functions.
12.) Write a query to find tracks where the liveness score is above the average.
13.) Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
14.) Find tracks where the energy-to-liveness ratio is greater than 1.2.
15.) Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.
16.) Cluster tracks into tempo-energy categories (e.g., high energy, low energy) based on their tempo and energy values.
17.) Find the top 5 artists with the highest average views per track, considering only tracks with more than 100,000 views.
18.) Rank tracks based on their energy-to-liveness ratio within each album and return the top-ranked track for each album.
19.) Identify artists whose tracks tend to have higher engagement (likes + comments) when they are licensed and are official videos.
20.) Find the top 10 tracks with a balance of high danceability, energy, and views.
*/

-- 1
SELECT 
	track, stream 
FROM spotify 
WHERE stream>1000000000;

-- 2
SELECT DISTINCT
	album
FROM spotify
ORDER BY 1;

-- 3

SELECT SUM(comments) as total_comments
FROM spotify
WHERE licensed = TRUE;

-- 4
SELECT *
FROM spotify
WHERE album_type = 'single';

-- 5 
SELECT 
	artist,
	COUNT(*) as total_num_songs
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;

-- 6 
SELECT 
	album,
	AVG(danceability) AS avg_danceability 
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- 7 
SELECT 
	track, 
	MAX(energy) AS max_energy
FROM spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- 8 
SELECT
	track,
	SUM(views) AS total_views,
	SUM(likes) AS total_likes
FROM spotify
WHERE official_video = 'true'
GROUP BY 1
ORDER BY 2 DESC;

-- 9 
SELECT
	album,
	track,
	SUM(views) AS total_view
FROM spotify
GROUP BY 1,2
ORDER BY 3 DESC;

-- 10
SELECT * FROM
(SELECT
	track,
	COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) AS streamed_on_youtube,
	COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS streamed_on_spotify
FROM spotify
GROUP BY 1)
as t1
WHERE streamed_on_spotify > streamed_on_youtube
AND streamed_on_youtube <> 0;

-- 11
WITH ranking_artist
AS
(SELECT
	artist,
	track,
	SUM(views) as total_view,
	DENSE_RANK() OVER (PARTITION BY artist ORDER BY SUM(views) DESC) as rank
FROM spotify
GROUP BY 1,2
ORDER BY 1,3 DESC)
SELECT * FROM;

-- 12
SELECT
	track,
	artist,
	liveness
FROM spotify 
WHERE liveness > (SELECT AVG(liveness) as avg_liveness FROM spotify);

-- 13
WITH cte
AS
(SELECT
	album,
	MAX(energy) AS highest_energy,
	MIN(energy) AS lowest_energy
FROM spotify
GROUP BY 1)
SELECT
	album,
	highest_energy - lowest_energy AS energy_diff
FROM cte
ORDER BY 2 DESC;

-- 14
SELECT 
    track,
    artist,
    energy / liveness AS energy_to_liveness_ratio
FROM spotify
WHERE liveness > 0 -- To avoid division by zero
AND energy / liveness > 1.2;

-- 15
SELECT 
    track,
    SUM(likes) OVER (ORDER BY views ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_likes
FROM spotify
ORDER BY views DESC;

--16
SELECT 
    track,
    artist,
    CASE 
        WHEN tempo > 120 AND energy > 0.7 THEN 'High Energy, Fast Tempo'
        WHEN tempo > 120 AND energy <= 0.7 THEN 'Low Energy, Fast Tempo'
        WHEN tempo <= 120 AND energy > 0.7 THEN 'High Energy, Slow Tempo'
        ELSE 'Low Energy, Slow Tempo'
    END AS tempo_energy_category
FROM spotify
ORDER BY tempo_energy_category;

-- 17 
WITH artist_avg_views AS (
    SELECT 
        artist,
        AVG(views) AS avg_views
    FROM spotify
    WHERE views > 100000
    GROUP BY artist
)
SELECT 
    artist,
    avg_views
FROM artist_avg_views
ORDER BY avg_views DESC
LIMIT 5;

-- 18 
WITH track_rankings AS (
    SELECT 
        album,
        track,
        energy_liveness,
        RANK() OVER (PARTITION BY album ORDER BY energy_liveness DESC) AS rank
    FROM spotify
)
SELECT 
    album,
    track,
    energy_liveness
FROM track_rankings
WHERE rank = 1
ORDER BY energy_liveness DESC;

-- 19 
WITH artist_engagement AS (
    SELECT 
        artist,
        SUM(likes + comments) AS total_engagement,
        COUNT(*) AS total_tracks
    FROM spotify
    WHERE licensed = TRUE AND official_video = TRUE
    GROUP BY artist
)
SELECT 
    artist,
    total_engagement,
    total_tracks,
    ROUND(total_engagement / total_tracks, 2) AS avg_engagement_per_track
FROM artist_engagement
ORDER BY avg_engagement_per_track DESC
LIMIT 10;

-- 20 
WITH track_scores AS (
    SELECT 
        track,
        artist,
        views,
        danceability,
        energy,
        -- Weighted score combining danceability, energy, and normalized views
        (danceability * 0.4 + energy * 0.4 + (views / (SELECT MAX(views) FROM spotify)) * 0.2) AS weighted_score
    FROM spotify
)
SELECT 
    track,
    artist,
    views,
    danceability,
    energy,
    ROUND(weighted_score::NUMERIC, 2) AS score
FROM track_scores
ORDER BY weighted_score DESC
LIMIT 10;