# Spotify SQL Portfolio Project 🎵

## Project Overview
This project involves analyzing music metrics and streaming trends using SQL. The dataset includes attributes like artist, track, album, and metrics such as danceability, energy, and views.

## Features
- **Schema Creation**: Scripts to create the database table.
- **Basic Queries**: EDA and foundational SQL queries.
- **Complex Queries**: Advanced insights like weighted metrics, clustering, and window functions.

## File Structure
- `schema/`: SQL script for table creation.
- `queries/`: SQL scripts for both basic and advanced queries.
- `data/`: Example CSV file of the data used.

## Example Queries
### 1. Find Top 10 Tracks by Weighted Metrics
```sql
WITH track_scores AS (
    SELECT 
        track,
        artist,
        views,
        danceability,
        energy,
        (danceability * 0.4 + energy * 0.4 + (views / (SELECT MAX(views) FROM spotify)) * 0.2) AS weighted_score
    FROM spotify
)
SELECT 
    track,
    artist,
    ROUND(weighted_score::NUMERIC, 2) AS score
FROM track_scores
ORDER BY weighted_score DESC
LIMIT 10;

