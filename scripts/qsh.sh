#!/bin/bash

# Store some basic information about our execution environment
QSH=$BASH_SOURCE
PANE_ID=$(tmux display-message -p '#{pane_id}')
PID=$$

# Base directory for query editor tmp files
QSH_TMP=/tmp/qsh

# The client pane file, which hosts the SQL client session, and the editor pane file, which is
# running the editor, e.g. vim. Each file will store data related to the opposite pane, so that
# when that pane executes this script it can easily access the information for it's related pane
CLIENT_PANE=$QSH_TMP/client.${PANE_ID}
EDITOR_PANE=$QSH_TMP/editor.${PANE_ID}

# The query file that will be used to transport the single query batch to be executed to the
# SQL client
QSH_EXECUTE_QUERY=$QSH_TMP/execute.${PANE_ID}.sql

# When invoked from the SQL client, this will contain the file it expects to contain the query
# to execute. The script can, however, also be involved by the editor, in which case this
# script parameter will be empty
OUTPUT_FILE=$1

# Query editor options & default values
QSH_PAGER=${QUERY_EDITOR_PAGER:-pspg}
QSH_EDITOR_COMMAND=${QUERY_EDITOR_COMMAND:-'\e\;'}
QSH_SWITCH_ON_EXECUTE=${QUERY_EDITOR_SWITCH_ON_EXECUTE:-0}

# The editor to use
EDITOR=${VISUAL:-$EDITOR}

# If neither pane file exists, it must mean that this is the first time we are running in this
# window. In that case, perform one-time initialization. We can safely assume this is running from
# the SQL client pane
if [ ! -f "$CLIENT_PANE" ] && [ ! -f "$EDITOR_PANE" ]; then
  # Ensure the base directory exists
  mkdir -p $QSH_TMP;

  # Ensure we have an input file, even if one isn't setup
  if [[ -z "$EDITOR_FILE" ]]; then
    EDITOR_FILE=$QSH_TMP/query.${PANE_ID}.sql
  fi;

  # Create the editor pane, and pass all options and other values to it. Also ensure that if the
  # editor is closed, all pane files are cleaned up. This allows for the editor to be re-opened
  # again in the same tmux window without issue, and reduces the proliferation of tmp files
  EDITOR_PANE_ID=$(tmux split-window "export QSH='$QSH' \
                                             QSH_EXECUTE_QUERY='$QSH_EXECUTE_QUERY' \
                                             QSH_PAGER='$QSH_PAGER' \
                                             QSH_EDITOR_COMMAND='$QSH_EDITOR_COMMAND' \
                                             QSH_SWITCH_ON_EXECUTE='$QSH_SWITCH_ON_EXECUTE' \
                                             PANE_ID=$(tmux display-message -p '#{pane_id}');
                                      $EDITOR $EDITOR_FILE; \
                                      rm -f $QSH_TMP/editor.$PANE_ID; \
                                      rm -f $CLIENT_PANE;" \; \
                   swap-pane -U \; \
                   display-message -p '#{pane_id}');

  # Store the pane for the editor in the client pane file
  echo $EDITOR_PANE_ID > $CLIENT_PANE;

  # Store this (the SQL client) pane ID in the editor pane file
  echo ${PANE_ID} > $QSH_TMP/editor.${EDITOR_PANE_ID};

  # Put up a nice message up to let the user know we're good to go
  echo "select 'INITIALIZED' as \"Query Editor\";" > $OUTPUT_FILE;
  exit 0;
fi;

# If the $EDITOR_PANE file exists, it must mean the editor is running this script, so perform
# editor-side processing. Normally this be the case when the editor wants to send a query to
# the SQL client
if [[ -f "$EDITOR_PANE" ]]; then
  # Capture details of the SQL client from the editor pane file
  CLIENT_PANE_ID=$(cat $EDITOR_PANE);
  CLIENT_PID=$(tmux list-panes -F '#{pane_id}.#{pane_pid}' | grep "^${CLIENT_PANE_ID}[.]" \
               | cut -d . -f 2);

  # There may be results currently being displayed in the SQL client with a pager, so in that case
  # we'll need to exit out of the pager before sending over the new query
  if [[ ! -z "$(pstree $CLIENT_PID | grep $QSH_PAGER)" ]]; then
    tmux send-keys -t $CLIENT_PANE_ID "C-m";
    tmux send-keys -t $CLIENT_PANE_ID "q";

    # If there are a lot of results, sometimes it can take a little while for the pager to exit,
    # so loop until we can be sure it has stopped
    while [[ ! -z "$(pstree $CLIENT_PID | grep $QSH_PAGER)" ]]; do
      sleep 0.5;
    done;
  fi;

  # Switch over to the SQL client pane when executing a query, to ensure it becomes visible
  tmux select-pane -t $CLIENT_PANE_ID;

  # Finally, trigger the editor in the SQL client, which will cause it to re-enter this script. We
  # need that to happen so that it can pick up the query file and execute it
  tmux send-keys -t $CLIENT_PANE_ID "$QSH_EDITOR_COMMAND";
  tmux send-keys -t $CLIENT_PANE_ID "C-m";

  # If configured to NOT switch to the client on query execute, switch back to the editor, after
  # a small artifical delay to ensure the SQL client pane starts executing the $QSH_EDITOR_COMMAND
  if [[ "$QSH_SWITCH_ON_EXECUTE" != "1" ]]; then
    sleep 0.1 && tmux select-pane -l;
  fi;

  exit 0;
fi;

# If we are still here, this is being executed by the SQL client, and only in the case where there
# is a query to be executed, which should be stored in $QSH_EXECUTE_QUERY. All we need to 
# do is move this file to the location requested by the SQL client, i.e. $OUTPUT_FILE, which will
# then pick it up and execute it
mv $QSH_EXECUTE_QUERY $OUTPUT_FILE > /dev/null 2>&1;

