# Spotify Advanced SQL Project & Query Optimization 🎵

<img width="1082" height="607" alt="image" src="https://github.com/user-attachments/assets/896a27f0-f6fe-4f6e-b8f1-db0829dbc204" />


A comprehensive SQL analysis of 20,000+ Spotify tracks using PostgreSQL — solving 15 business problems across 3 difficulty levels with advanced query optimization techniques.

---

## 📌 Project Overview

| Detail | Info |
|--------|------|
| **Title** | Spotify Advanced SQL & Query Optimization |
| **Level** | Easy → Medium → Advanced |
| **Database** | PostgreSQL (pgAdmin 4) |
| **Dataset** | 20,000+ Spotify tracks |
| **Source** | [Kaggle — Spotify Dataset](https://www.kaggle.com/datasets/sanjanchaudhari/spotify-dataset) |

---

## 🗂️ Table Schema

```sql
CREATE TABLE spotify (
    artist            VARCHAR(255),
    track             VARCHAR(255),
    album             VARCHAR(255),
    album_type        VARCHAR(50),
    danceability      FLOAT,
    energy            FLOAT,
    loudness          FLOAT,
    speechiness       FLOAT,
    acousticness      FLOAT,
    instrumentalness  FLOAT,
    liveness          FLOAT,
    valence           FLOAT,
    tempo             FLOAT,
    duration_min      FLOAT,
    title             VARCHAR(255),
    channel           VARCHAR(255),
    views             FLOAT,
    likes             BIGINT,
    comments          BIGINT,
    licensed          BOOLEAN,
    official_video    BOOLEAN,
    stream            BIGINT,
    energy_liveness   FLOAT,
    most_played_on    VARCHAR(50)
);
```

---

## 🎯 15 Business Problems & Solutions

### 🟢 Easy Level

**Q1. Tracks with more than 1 billion streams**
```sql
SELECT *
FROM spotify
WHERE stream > 1000000000;
```

---

**Q2. All albums with their respective artists**
```sql
SELECT DISTINCT
    album,
    artist
FROM spotify
ORDER BY album;
```

---

**Q3. Total comments for licensed tracks**
```sql
SELECT
    SUM(comments) AS total_comments
FROM spotify
WHERE licensed = TRUE;
```

---

**Q4. All tracks belonging to album type 'single'**
```sql
SELECT *
FROM spotify
WHERE album_type = 'single';
```

---

**Q5. Total number of tracks by each artist**
```sql
SELECT
    artist,
    COUNT(*) AS total_tracks
FROM spotify
GROUP BY artist
ORDER BY total_tracks DESC;
```

---

### 🟡 Medium Level

**Q6. Average danceability per album**
```sql
SELECT
    album,
    ROUND(AVG(danceability)::NUMERIC, 4) AS avg_danceability
FROM spotify
GROUP BY album
ORDER BY avg_danceability DESC;
```

---

**Q7. Top 5 tracks with the highest energy values**
```sql
SELECT
    track,
    MAX(energy) AS max_energy
FROM spotify
GROUP BY track
ORDER BY max_energy DESC
LIMIT 5;
```

---

**Q8. Tracks with views and likes where official_video = TRUE**
```sql
SELECT
    track,
    SUM(views) AS total_views,
    SUM(likes) AS total_likes
FROM spotify
WHERE official_video = TRUE
GROUP BY track
ORDER BY total_views DESC;
```

---

**Q9. Total views per album and track**
```sql
SELECT
    album,
    track,
    SUM(views) AS total_views
FROM spotify
GROUP BY album, track
ORDER BY total_views DESC;
```

---

**Q10. Tracks streamed more on Spotify than YouTube**
```sql
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
WHERE streamed_on_spotify > streamed_on_youtube
  AND streamed_on_youtube <> 0
ORDER BY streamed_on_spotify DESC;
```

---

### 🔴 Advanced Level

**Q11. Top 3 most-viewed tracks per artist using window functions**
```sql
WITH cte AS (
    SELECT
        artist,
        track,
        SUM(views) AS total_views,
        DENSE_RANK() OVER (
            PARTITION BY artist
            ORDER BY SUM(views) DESC
        ) AS rnk
    FROM spotify
    GROUP BY artist, track
)
SELECT *
FROM cte
WHERE rnk <= 3
ORDER BY artist, total_views DESC;
```

---

**Q12. Tracks where liveness score is above average**
```sql
SELECT
    track,
    artist,
    liveness
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify)
ORDER BY liveness DESC;
```

---

**Q13. Energy difference (highest vs lowest) per album**
```sql
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
    ROUND(CAST(highest_energy - lowest_energy AS NUMERIC), 2) AS energy_difference
FROM cte
ORDER BY energy_difference DESC;
```

---

**Q14. Tracks where energy-to-liveness ratio > 1.2**
```sql
SELECT
    track,
    energy,
    liveness,
    ROUND(CAST(energy / liveness AS NUMERIC), 2) AS energy_liveness_ratio
FROM spotify
WHERE liveness > 0
  AND energy / liveness > 1.2
ORDER BY energy_liveness_ratio DESC;
```

---

**Q15. Cumulative sum of likes ordered by views**
```sql
SELECT
    track,
    views,
    likes,
    SUM(likes) OVER (
        ORDER BY views DESC
    ) AS cumulative_likes
FROM spotify
ORDER BY views DESC;
```

---

## ⚡ Query Optimization Technique

To improve query performance, we carried out the following optimization process:

- **Initial Query Performance Analysis Using `EXPLAIN`**
  - We began by analyzing the performance of a query using the `EXPLAIN` function.
  - The query retrieved tracks based on the `artist` column, and the performance metrics were as follows:
    - Execution time (E.T.): **7 ms**
    - Planning time (P.T.): **0.17 ms**
  - Below is the screenshot of the `EXPLAIN` result before optimization:

<img width="758" height="470" alt="image" src="https://github.com/user-attachments/assets/8a0361b2-7316-401d-a4fa-5da52f45b598" />


---

- **Index Creation on the `artist` Column**
  - To optimize the query performance, we created an index on the `artist` column. This ensures faster retrieval of rows where the artist is queried.
  - SQL command for creating the index:

```sql
CREATE INDEX idx_artist ON spotify(artist);
```

---

- **Performance Analysis After Index Creation**
  - After creating the index, we ran the same query again and observed significant improvements in performance:
    - Execution time (E.T.): **0.153 ms**
    - Planning time (P.T.): **0.152 ms**
  - Below is the screenshot of the `EXPLAIN` result after index creation:

<img width="833" height="528" alt="image" src="https://github.com/user-attachments/assets/e3d812a4-c1be-46d8-be0e-bd2cf0afaef1" />


---

- **Graphical Performance Comparison**
  - A graph illustrating the comparison between the initial query execution time and the optimized query execution time after index creation.
  - Graph view shows the significant drop in both execution and planning times:

<img width="773" height="608" alt="image" src="https://github.com/user-attachments/assets/607b0cd8-a2f5-45a0-a907-cb5d3b46674c" />


> This optimization shows how indexing can drastically reduce query time, improving the overall performance of our database operations in the Spotify project.

---

## 🛠️ Technology Stack

- **Database:** PostgreSQL
- **SQL Queries:** DDL, DML, Aggregations, Joins, Subqueries, Window Functions
- **Tools:** pgAdmin 4 (or any SQL editor), PostgreSQL (via Homebrew, Docker, or direct installation)

---

## 🚀 How to Run the Project

1. Install PostgreSQL and pgAdmin (if not already installed).
2. Set up the database schema and tables using the provided normalization structure.
3. Insert the sample data into the respective tables.
4. Execute SQL queries to solve the listed problems.
5. Explore query optimization techniques for large datasets.

---

## 📁 Project Structure

```
spotify-sql-project/
│
├── schema.sql          # Table creation script
├── analysis.sql        # All 15 business queries
├── optimization.sql    # Index creation + EXPLAIN ANALYZE
├── dataset/            # Raw CSV from Kaggle
└── README.md           # Project documentation
```

---

## 📌 Conclusion

This project goes beyond standard SQL — applying advanced techniques like Window Functions, CTEs, COALESCE, and Query Optimization on a real-world dataset of 20,000+ tracks. Every query was built around a business question a music streaming analyst would actually ask. The indexing exercise alone demonstrated a 45x improvement in query speed — a critical skill for working with production-scale databases.

---

## 🔮 Next Steps

- **Visualize the Data:** Use a data visualization tool like Tableau or Power BI to create dashboards based on the query results.
- **Expand Dataset:** Add more rows to the dataset for broader analysis and scalability testing.
- **Advanced Querying:** Dive deeper into query optimization and explore the performance of SQL queries on larger datasets.

---

## 📜 License

This project is open source and available under the [MIT License](LICENSE).
