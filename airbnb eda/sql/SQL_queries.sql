-- Airbnb SQL Analysis
-- Advanced queries for business insights


---------------------------------------------------
-- 1. Top Revenue-Generating Neighborhoods
---------------------------------------------------
SELECT neighbourhood, 
       ROUND(SUM(price * minimum_nights * availability_365), 2) AS potential_revenue
FROM listing
GROUP BY neighbourhood
ORDER BY potential_revenue DESC
LIMIT 10;

---------------------------------------------------
-- 2. Occupancy Rate by Room Type
---------------------------------------------------
SELECT room_type,
       ROUND(AVG(availability_365 / 365.0 * 100), 2) AS avg_occupancy_rate
FROM listing
GROUP BY room_type
ORDER BY avg_occupancy_rate DESC;

---------------------------------------------------
-- 3. Host Performance (Top Hosts)
---------------------------------------------------
SELECT host_id,
       COUNT(id) AS total_listings,
       ROUND(AVG(price), 2) AS avg_price,
       ROUND(AVG(reviews_per_month), 2) AS avg_reviews
FROM listing
GROUP BY host_id
HAVING COUNT(id) > 5
ORDER BY avg_reviews DESC
LIMIT 10;

---------------------------------------------------
-- 4. Seasonal Trends (Monthly Availability)
---------------------------------------------------
SELECT DATE_TRUNC('month', last_review) AS month,
       COUNT(id) AS active_listings,
       ROUND(AVG(price), 2) AS avg_price
FROM listing
WHERE last_review IS NOT NULL
GROUP BY month
ORDER BY month;

---------------------------------------------------
-- 5. Luxury vs Budget Listings
---------------------------------------------------
WITH price_stats AS (
    SELECT 
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS luxury_threshold,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS budget_threshold
    FROM listing
)
SELECT 
    CASE 
        WHEN price >= (SELECT luxury_threshold FROM price_stats) THEN 'Luxury'
        WHEN price <= (SELECT budget_threshold FROM price_stats) THEN 'Budget'
        ELSE 'Mid-Range'
    END AS segment,
    COUNT(*) AS total_listings,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews
FROM listing, price_stats
GROUP BY segment
ORDER BY total_listings DESC;

---------------------------------------------------
-- 6. Review Trends (Engagement)
---------------------------------------------------
SELECT neighbourhood, 
       ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month
FROM listing
WHERE reviews_per_month IS NOT NULL
GROUP BY neighbourhood
ORDER BY avg_reviews_per_month DESC
LIMIT 10;

---------------------------------------------------
-- 7. Price Anomaly Detection
---------------------------------------------------
SELECT id, neighbourhood, room_type, price
FROM listing
WHERE price > (SELECT AVG(price) + 3 * STDDEV(price) FROM listing)
ORDER BY price DESC;

---------------------------------------------------
-- 8. Ranking Top Listings per Neighborhood
---------------------------------------------------
SELECT neighbourhood,
       id AS listing_id,
       price,
       RANK() OVER (PARTITION BY neighbourhood ORDER BY price DESC) AS rank_in_neighbourhood
FROM listing
WHERE price > 0
ORDER BY neighbourhood, rank_in_neighbourhood
LIMIT 50;

---------------------------------------------------
-- 9. Host Retention & Repeat Hosts
---------------------------------------------------
WITH host_activity AS (
    SELECT host_id,
           MIN(last_review) AS first_active,
           MAX(last_review) AS last_active,
           COUNT(id) AS total_listings
    FROM listing
    WHERE last_review IS NOT NULL
    GROUP BY host_id
)
SELECT 
    COUNT(CASE WHEN EXTRACT(YEAR FROM last_active) - EXTRACT(YEAR FROM first_active) >= 2 THEN 1 END) AS retained_hosts,
    COUNT(*) AS total_hosts,
    ROUND(
        COUNT(CASE WHEN EXTRACT(YEAR FROM last_active) - EXTRACT(YEAR FROM first_active) >= 2 THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS retention_rate
FROM host_activity;

---------------------------------------------------
-- 10. Geospatial Price Hotspots
---------------------------------------------------
SELECT neighbourhood, 
       ROUND(AVG(price), 2) AS avg_price,
       COUNT(id) AS total_listings
FROM listing
GROUP BY neighbourhood
ORDER BY avg_price DESC
LIMIT 15;
