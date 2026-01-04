#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == "test" ]]; then
  PSQL="psql -X --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql -X --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

$PSQL "TRUNCATE teams CASCADE" >/dev/null

while IFS="," read -r YEAR ROUND WINNER OPPONENT W_GOALS O_GOALS
do
  # skip header
  if [[ "$YEAR" == "year" ]]; then
    continue
  fi

  # insert teams if missing 
  $PSQL "INSERT INTO teams(name) VALUES('$WINNER') ON CONFLICT (name) DO NOTHING" >/dev/null
  $PSQL "INSERT INTO teams(name) VALUES('$OPPONENT') ON CONFLICT (name) DO NOTHING" >/dev/null

  # get ids
  WINNER_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
  OPPONENT_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")

  $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
         VALUES($YEAR, '$ROUND', $WINNER_TEAM_ID, $OPPONENT_TEAM_ID, $W_GOALS, $O_GOALS)" >/dev/null
done < games.csv
