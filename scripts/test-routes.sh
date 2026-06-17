#!/usr/bin/env bash
set -euo pipefail

URL="${URL:-http://localhost:8080}"
MAX_RETRIES="${MAX_RETRIES:-20}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"

echo "Testing route: ${URL}"
echo

for i in $(seq 1 "$MAX_RETRIES"); do
  if RESPONSE="$(curl -sS -i --max-time 5 "$URL" 2>&1)"; then
    if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK"; then
      echo "$RESPONSE"
      exit 0
    fi

    echo "Attempt ${i}/${MAX_RETRIES}: route responded but not 200 yet"
    echo "$RESPONSE" | head -n 5
  else
    echo "Attempt ${i}/${MAX_RETRIES}: route not ready yet"
    echo "$RESPONSE"
  fi

  echo
  sleep "$SLEEP_SECONDS"
done

echo "Route did not become ready after ${MAX_RETRIES} attempts."
exit 1
