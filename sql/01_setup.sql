-- Snowflake Dashboards 2.0 demo: data setup
-- Idempotent. Run as a role that can create databases (e.g. SYSADMIN).
-- Optional: set VIEWER_ROLE below to grant read access to the role that will open the dashboard.

SET VIEWER_ROLE = 'PUBLIC';

CREATE DATABASE IF NOT EXISTS DASH_DEMO;
CREATE SCHEMA IF NOT EXISTS DASH_DEMO.SALES;

-- 60k synthetic orders, Jan 2025 - Dec 2026, fixed seeds so every run gives the same data.
-- Planted story: Australia (APAC) revenue drops ~30% from mid-May 2026.
CREATE OR REPLACE TABLE DASH_DEMO.SALES.ORDERS AS
WITH r AS (
  SELECT seq4() AS id,
         uniform(0, 729, random(11)) AS d,
         uniform(1, 100, random(12)) AS p,
         uniform(1, 100, random(13)) AS g,
         uniform(1, 400, random(14)) AS c,
         uniform(1, 20,  random(15)) AS q
  FROM TABLE(GENERATOR(ROWCOUNT => 60000))
)
SELECT id AS order_id,
  DATEADD(day, d, '2025-01-01')::DATE AS order_date,
  CASE WHEN g <= 35 THEN 'AMER' WHEN g <= 65 THEN 'EMEA' ELSE 'APAC' END AS region,
  CASE WHEN g <= 20 THEN 'United States' WHEN g <= 35 THEN 'Canada'
       WHEN g <= 48 THEN 'Germany' WHEN g <= 58 THEN 'United Kingdom' WHEN g <= 65 THEN 'France'
       WHEN g <= 78 THEN 'Australia' WHEN g <= 88 THEN 'Singapore' WHEN g <= 95 THEN 'Japan'
       ELSE 'Indonesia' END AS country,
  CASE WHEN p <= 30 THEN 'Data Warehouse' WHEN p <= 55 THEN 'AI & ML' WHEN p <= 75 THEN 'Data Engineering'
       WHEN p <= 90 THEN 'Apps' ELSE 'Collaboration' END AS product_line,
  CASE WHEN c <= 60 THEN 'Enterprise' WHEN c <= 200 THEN 'Mid-Market' ELSE 'SMB' END AS segment,
  'Customer ' || LPAD(c, 3, '0') AS customer_name,
  CASE WHEN g <= 35 THEN 'Direct' WHEN q <= 8 THEN 'Partner' ELSE 'Direct' END AS channel,
  q AS units,
  ROUND(q * (CASE WHEN p <= 30 THEN 1200 WHEN p <= 55 THEN 1800 WHEN p <= 75 THEN 900 WHEN p <= 90 THEN 700 ELSE 500 END)
          * (1 + d / 1500)
          * (CASE WHEN g BETWEEN 66 AND 78 AND d > 500 THEN 0.7 ELSE 1 END), 2) AS revenue,
  ROUND(revenue * uniform(0.25, 0.6, random(16)), 2) AS cost
FROM r;

CREATE OR REPLACE SEMANTIC VIEW DASH_DEMO.SALES.SALES_SV
  TABLES (orders AS DASH_DEMO.SALES.ORDERS PRIMARY KEY (order_id) COMMENT = 'Order line facts')
  FACTS (orders.revenue_f AS revenue, orders.cost_f AS cost, orders.units_f AS units)
  DIMENSIONS (
    orders.order_date AS order_date,
    orders.order_month AS DATE_TRUNC('month', order_date),
    orders.region AS region, orders.country AS country,
    orders.product_line AS product_line, orders.segment AS segment,
    orders.channel AS channel, orders.customer_name AS customer_name)
  METRICS (
    orders.total_revenue AS SUM(revenue),
    orders.gross_margin AS SUM(revenue) - SUM(cost),
    orders.margin_pct AS DIV0(SUM(revenue) - SUM(cost), SUM(revenue)),
    orders.order_count AS COUNT(order_id),
    orders.total_units AS SUM(units))
  COMMENT = 'Sales demo semantic view for Dashboards 2.0';

GRANT USAGE ON DATABASE DASH_DEMO TO ROLE IDENTIFIER($VIEWER_ROLE);
GRANT USAGE ON SCHEMA DASH_DEMO.SALES TO ROLE IDENTIFIER($VIEWER_ROLE);
GRANT SELECT ON TABLE DASH_DEMO.SALES.ORDERS TO ROLE IDENTIFIER($VIEWER_ROLE);
GRANT SELECT ON SEMANTIC VIEW DASH_DEMO.SALES.SALES_SV TO ROLE IDENTIFIER($VIEWER_ROLE);

-- Sanity check: Australia revenue by quarter should fall from Q2 2026.
SELECT DATE_TRUNC('quarter', order_date) AS quarter, ROUND(SUM(revenue) / 1e6, 2) AS aus_revenue_m
FROM DASH_DEMO.SALES.ORDERS WHERE country = 'Australia' GROUP BY 1 ORDER BY 1;
