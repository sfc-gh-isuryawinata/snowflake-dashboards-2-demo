#!/usr/bin/env bash
# One-command deploy: creates demo data and uploads the dashboard to your Snowsight "My Workspace".
# Usage: ./deploy.sh <snowflake-connection-name> [viewer_role]
# Requires the Snowflake CLI (`snow`) with a connection configured in ~/.snowflake/connections.toml.
set -euo pipefail

CONN="${1:?usage: ./deploy.sh <connection-name> [viewer_role]}"
VIEWER_ROLE="${2:-PUBLIC}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Creating DASH_DEMO data (viewer role: $VIEWER_ROLE)"
sed "s/SET VIEWER_ROLE = 'PUBLIC';/SET VIEWER_ROLE = '${VIEWER_ROLE}';/" "$DIR/sql/01_setup.sql" \
  | snow sql -c "$CONN" --stdin

echo "==> Uploading dashboard to My Workspace (USER\$.PUBLIC.DEFAULT\$)"
snow sql -c "$CONN" -q "PUT 'file://$DIR/dashboard/Global_Sales_Performance.dash' 'snow://workspace/USER\$.PUBLIC.DEFAULT\$/versions/live/dashboards-demo/' AUTO_COMPRESS=FALSE OVERWRITE=TRUE"

echo "==> Done. In Snowsight: Projects > Workspaces > My Workspace > dashboards-demo/Global_Sales_Performance.dash"
