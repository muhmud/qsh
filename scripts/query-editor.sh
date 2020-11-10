#!/bin/bash

# Store some basic information about our execution environment
QUERY_EDITOR=$BASH_SOURCE
PANE_ID=$(tmux display-message -p '#{pane_id}')
PID=$$

# Base directory for query editor tmp files
QUERY_EDITOR_BASE=/tmp/query-editor

# The client pane file, which hosts the SQL client session, and the editor pane file, which is
# running the editor, e.g. vim. Each file will store data related to the opposite pane, so that
# when that pane executes this script it can easily access the information for it's related pane
CLIENT_PANE_FILE=$QUERY_EDITOR_BASE/query-editor.${PANE_ID}.client.pane
EDITOR_PANE_FILE=$QUERY_EDITOR_BASE/query-editor.${PANE_ID}.editor.pane

# The query file that will be used to transport the single query batch to be executed to the
# SQL client
QUERY_EDITOR_EXECUTE_FILE=$QUERY_EDITOR_BASE/query-editor.${PANE_ID}.query.execute

# When invoked from the SQL client, this will contain the file it expects to contain the query
# to execute. The script can, however, also be involved by the editor, in which case this
# script parameter will be empty
OUTPUT_FILE=$1

# Query editor options & default values
QUERY_EDITOR_PAGER=${QUERY_EDITOR_PAGER:-pspg}
QUERY_EDITOR_COMMAND=${QUERY_EDITOR_COMMAND:-'\e\;'}
QUERY_EDITOR_SWITCH_ON_EXECUTE=${QUERY_EDITOR_SWITCH_ON_EXECUTE:-0}

# The editor to use
EDITOR=${VISUAL:-$EDITOR}

# If neither pane file exists, it must mean that this is the first time we are running in this
# window. In that case, perform one-time initialization
if [ ! -f "$CLIENT_PANE_FILE" ] && [ ! -f "$EDITOR_PANE_FILE" ]; then
  # Ensure the base directory exists
  mkdir -p $QUERY_EDITOR_BASE;

  # Store the parent PID
  PARENT_PID=$(ps -o ppid= -p $PID | sed 's/ //g');

  # Ensure we have an input file, even if one isn't setup
  if [[ -z "$EDITOR_FILE" ]]; then
    EDITOR_FILE=$QUERY_EDITOR_BASE/query-editor.${PARENT_PID}.query.sql
  fi;

  echo $EDITOR_FILE;

  # Create the editor pane, and pass all options and other values to it. Also ensure that if the
  # editor is closed, all pane files are cleaned up. This allows for the editor to be re-opened
  # again in the same tmux window without issue, and reduces the proliferation of tmp files
  EDITOR_PANE_ID=$(tmux split-window "export QUERY_EDITOR='$QUERY_EDITOR' \
                                             QUERY_EDITOR_EXECUTE_FILE='$QUERY_EDITOR_EXECUTE_FILE' \
                                             QUERY_EDITOR_PAGER='$QUERY_EDITOR_PAGER' \
                                             QUERY_EDITOR_COMMAND='$QUERY_EDITOR_COMMAND' \
                                             QUERY_EDITOR_SWITCH_ON_EXECUTE='$QUERY_EDITOR_SWITCH_ON_EXECUTE' \
                                             PANE_ID=$(tmux display-message -p '#{pane_id}');
                                      $EDITOR $EDITOR_FILE; \
                                      rm -f $QUERY_EDITOR_BASE/query-editor.$PANE_ID.editor.pane; \
                                      rm -f $CLIENT_PANE_FILE;" \; \
                   swap-pane -U \; \
                   display-message -p '#{pane_id}');

  # Store the pane for the editor in the client pane file
  echo $EDITOR_PANE_ID > $CLIENT_PANE_FILE;

  # Store this (the SQL client) pane ID and the parent PID in the editor pane file
  echo ${PANE_ID}.$PARENT_PID > $QUERY_EDITOR_BASE/query-editor.${EDITOR_PANE_ID}.editor.pane;

  # Put up a nice message up to let the user know we're good to go
  echo "select 'INITIALIZED' as "Query Editor";" > $OUTPUT_FILE;
  exit 0;
fi;

# If the $EDITOR_PANE_FILE exists, it must mean the editor is running this script, so perform
# editor-side processing. Normally this be the case when the editor wants to send a query to
# the SQL client
if [[ -f "$EDITOR_PANE_FILE" ]]; then
  # Capture details of the SQL client from the editor pane file
  CLIENT_PANE_ID=$(cat $EDITOR_PANE_FILE | cut -d . -f 1);
  CLIENT_PID=$(cat $EDITOR_PANE_FILE | cut -d . -f 2);

  # There may be results currently being displayed in the SQL client with a pager, so in that case
  # we'll need to exit out of the pager before sending over the new query
  if [[ ! -z "$(pstree $CLIENT_PID | grep $QUERY_EDITOR_PAGER)" ]]; then
    tmux send-keys -t $CLIENT_PANE_ID "C-c";
    tmux send-keys -t $CLIENT_PANE_ID "q";
  fi;

  # Switch over to the SQL client pane when executing a query, to ensure it becomes visible
  tmux select-pane -t $CLIENT_PANE_ID;

  # Finally, trigger the editor in the SQL client, which will cause it to re-enter this script. We
  # need that to happen so that it can pick up the query file and execute it
  tmux send-keys -t $CLIENT_PANE_ID "$QUERY_EDITOR_COMMAND";
  tmux send-keys -t $CLIENT_PANE_ID "C-m";

  # If configured to NOT switch to the client on query execute, switch back to the editor, after
  # a small artifical delay to ensure the SQL client pane starts executing the QUERY_EDITOR_COMMAND
  if [[ "$QUERY_EDITOR_SWITCH_ON_EXECUTE" != "1" ]]; then
    sleep 0.1 && tmux select-pane -l;
  fi;

  exit 0;
fi;

# If we are still here, this is being executed by the SQL client, and only in the case where there
# is a query to be executed, which should be stored in $QUERY_EDITOR_EXECUTE_FILE. All we need to 
# do is move this file to the location requested by the SQL client, i.e. $OUTPUT_FILE, which will
# then pick it up and execute it
mv $QUERY_EDITOR_EXECUTE_FILE $OUTPUT_FILE > /dev/null 2>&1;

