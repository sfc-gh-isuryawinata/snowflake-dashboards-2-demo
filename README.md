# Snowflake Dashboards 2.0 (AI/BI) Demo

A repeatable, ~10-minute demo of [Snowflake Dashboards](https://docs.snowflake.com/en/user-guide/snowflake-dashboards):
AI-first creation with Cortex Code, interactive filters and chart actions, caller's-rights governance,
and conversational follow-ups in Snowflake CoWork.

> Dashboards is a preview feature. Behaviour may change.

## What you get
| Path | Purpose |
| --- | --- |
| `sql/01_setup.sql` | Creates `DASH_DEMO.SALES.ORDERS` (60k synthetic orders, 2025–2026, deterministic) and semantic view `DASH_DEMO.SALES.SALES_SV` |
| `dashboard/Global_Sales_Performance.dash` | Prebuilt 3-tab dashboard (Overview / Regional / Product), used as a starting point or fallback |
| `deploy.sh` | One command: runs setup and uploads the dashboard to your Snowsight **My Workspace** |
| `sql/99_teardown.sql` | Drops everything |

**Planted story:** Australia (APAC) revenue drops about 30% from mid-May 2026. This sets up the
"why did APAC drop?" moment in CoWork.

## Quick start
Prerequisites: [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`), a connection with a role that can create a database, and Dashboards enabled in Snowsight.

```bash
git clone <this repo> && cd <repo>
./deploy.sh <connection-name> [viewer_role]   # viewer_role defaults to PUBLIC
```

Then open **Snowsight › Projects › Workspaces › My Workspace › `dashboards-demo/Global_Sales_Performance.dash`**.

No CLI? Run `sql/01_setup.sql` in a worksheet, then upload the `.dash` file into a workspace with Snowsight's upload button.

Teardown: `snow sql -c <connection-name> -f sql/99_teardown.sql`

## Running the demo
You have two options: open the prebuilt dashboard and go straight to Step 2, or build it live in Step 1 (more impressive).

### Story arc
| # | Capability | What you show |
| --- | --- | --- |
| 1 | AI‑first creation | One prompt builds a multi-tab dashboard |
| 2 | Iteration | Change charts and add tiles conversationally |
| 3 | Filters | Date / region / cascading geo filters (`{{ filter('x') }}`) |
| 4 | Chart actions | Click a region and the other tiles filter |
| 5 | Hierarchy drill | Region → Country → Customer |
| 6 | Governance | Caller's rights, RBAC sharing, no extracts |
| 7 | Conversational consumption | Ask "why did APAC drop?" in CoWork |

### Step 1 – Build (Snowsight › Projects › Workspaces › Create › Dashboard, then CoCo `/dashboard`)
Paste:
> Build a "Global Sales Performance" dashboard on semantic view DASH_DEMO.SALES.SALES_SV with
> Overview, Regional and Product tabs. Overview: scorecards for Total Revenue, Gross Margin %,
> Order Count and Units, each with a sparkline and delta vs prior period; a monthly revenue trend
> line by region; revenue by product line bar chart; top 10 customers table. Regional: revenue by
> region bar chart and a revenue-by-country heatmap by month. Product: stacked area of revenue by
> product line over time and margin % by product line. Add a date range filter defaulting to the
> last 12 months, plus region, segment and channel filters.

### Step 2 – Iterate (show it's conversational)
- "Change the trend to weekly and add a reference line at the average."
- "Add a markdown header tile on Overview explaining the data source."
- "Make the top customers table show margin % with conditional color."

### Step 3 – Interactivity
- "When someone clicks a region in Revenue by region, filter the other tiles to it."
- "Let people drag across the revenue trend to pick a date range."
- "Add a cascading Region → Country filter."
- "Add a revenue bar chart that drills from region to country to customer, and a table that expands the same way."
- Demo it: click **APAC**, then drill into **Australia**. The dip is visible.

### Step 4 – Governance talking points
- Every tile query runs live with the **viewer's** privileges (caller's rights). There are no extracts and no BI license.
- Filter values are bound as parameters, so a viewer can't inject SQL.
- Create artifact → share to a role (e.g. `SALES_ANALYST`). Optional: grant a role APAC-only access
  through a row access policy and show the same dashboard returning different numbers.

### Step 5 – Consume in CoWork
Open the shared link (it opens in CoWork) and ask:
- "Why did APAC revenue drop in the second half of 2026?" (should surface Australia)
- On the trend tile: "Which product lines drove the decline?"
- "Filter to Enterprise segment only." (affects only your view)

### Optional – Legacy upgrade
Snowsight › Dashboards › **Upgrade to v2** converts a legacy dashboard into a `.dash` file.

## Notes
- The prebuilt `.dash` file contains tiles and tabs only. Filters, chart actions and hierarchies are meant to be added live with CoCo in Step 3.
- If the prebuilt file doesn't render in your account version, open it and ask Workspace CoCo to "fix this dashboard", or build it from the Step 1 prompt.
- Tile queries run as the viewer (caller's rights), so viewers need `SELECT` on `DASH_DEMO`. Use the `viewer_role` argument to grant it.
