#!/bin/bash

# Check the most recent workflow run and display failure details

echo "Fetching most recent workflow run..."
echo ""

# Get the most recent workflow run
RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "No workflow runs found"
    exit 1
fi

# Get workflow run details
RUN_STATUS=$(gh run view "$RUN_ID" --json status,conclusion --jq '.status + " - " + .conclusion')
RUN_NAME=$(gh run view "$RUN_ID" --json name --jq '.name')

echo "Workflow: $RUN_NAME"
echo "Status: $RUN_STATUS"
echo ""

# Check if the run failed
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')

if [ "$CONCLUSION" != "failure" ]; then
    echo "The most recent workflow run did not fail (conclusion: $CONCLUSION)"
    echo ""
    gh run view "$RUN_ID"
    exit 0
fi

echo "=== FAILURE DETAILS ==="
echo ""

# Show the full run view
gh run view "$RUN_ID"

echo ""
echo "=== FAILED JOBS ==="
echo ""

# Get failed jobs
gh run view "$RUN_ID" --log-failed

echo ""
echo "Run URL: https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')/actions/runs/$RUN_ID"
