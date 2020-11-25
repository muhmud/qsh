# qsh
Query SHell - improved database querying for your terminal

![QSH](https://github.com/muhmud/qsh/blob/main/images/qsh.png)

## Pre-requisites

You'll need to install & use [tmux](https://github.com/tmux/tmux), which is needed to manage the split panes. It should be available from your package manager.

For better viewing of SQL results, the [pspg](https://github.com/okbob/pspg) pager is recommended, however, you could also use `less -SinFX`.

## Setup

Clone this repository to your home:

```bash
$ git clone git@github.com:muhmud/qsh.git ~/.qsh
```

Then ensure that qsh is the `$EDITOR` being used by your SQL client. To simplify this, you could setup the following alias:

```
alias mysql='EDITOR=~/.qsh/scripts/qsh mysql --pager="pspg"'
```

For postgresql, the `$QSH_EDITOR_COMMAND` option will need changing, as the defaults work for mysql:

```
export PSQL_PAGER="pspg"
export PSQL_EDITOR=~/.qsh/scripts/qsh

alias psql='QSH_EDITOR_COMMAND="\\e" psql'
```

Finally, set `$QSH_EDITOR`, or `$VISUAL`, in your shell environment to the editor you want to use. Currently this can either be vim or [micro](https://micro-editor.github.io).

### Vim

You can install the vim plugin using `vim-plug` by adding the following line to your `~/.vimrc`:

```
Plug 'muhmud/qsh', { 'dir': '~/.qsh/editors/vim' }
```

Add the following key mapping to trigger query execution from the editor:

```
nnoremap <silent> <C-Enter> :call QshExecute()<CR>
nnoremap <silent> <C-S-Enter> :call QshExecute("---", 0)<CR>
vnoremap <silent> <F5> :call QshExecuteSelection()<CR>
nnoremap <silent> <F7> :call QshExecuteAll()<CR>
```

You may need to change the keys used based on your terminal environment.

### Micro

The micro plugin can be installed by executing the following:

```bash
$ mkdir -p ~/.config/micro/plug && cp -r ~/.qsh/editors/micro ~/.config/micro/plug/qsh
```

The following key mapping should be added to `~/.config/micro/bindings.json`:

```
"CtrlEnter": "command:QshExecute",
"CtrlShiftEnter": "command:QshExecute '---' 0",
"F5": "command:QshExecuteSelection",
"F7": "command:QshExecuteAll",
```

You may need to change the keys used based on your terminal environment.

## Usage

From within a tmux session, start your SQL client, i.e. `mysql` or `psql`.

Once started, trigger the editor using the command for your environment. For mysql, this would be `\e;`, and for psql, `\e`. You should see the editor pane created, where you can now type in queries. A default file is created for you, however, you could open up any other file you need to.

Queries can be executed in a variety of ways:

* Highlight a query and press `F5`, or whichever key you have bound; the selected query will be executed
* Press `Ctrl+Enter` within the document; the query between the previous semi-colon to the cursor and the following one will be executed
* Press `Ctrl+Shift+Enter` within the document; performs a variation of the previous command (see below for details)
* Press `F7` to execute all SQL within the current file

### QshExecute (Ctrl+Shift+Enter)

The `QshExecute` editor command can take two optional parameters: `delimiter` and `includeDelimiter`. These values are used to change the delimiter that determines the SQL in the file to execute (defaults to `;`) and whether or not the delimiter should be included in the output (defaults to `1`). This makes it easier to work with procedure and function definitions by allowing you to execute them without having to select the whole definition, which can often be lengthy.

This following provides an example:

```sql
create procedure test(a int)
begin
  update test
    set a = 1;                  /* <- If the cursor is here, Ctrl+Shift+Enter will create procedure test only */
end;

---                             /* <- This is the customizable delimiter defined in the key binding */

create procedure test2(a int)
begin
  update test
    set a = 2;                  /* <- If the cursor is here, Ctrl+Shift+Enter will create procedure test2 only */
end;
```

## Options

The following environment variables can be changed if required:

* `QSH_PAGER` - The pager you will be using, which defaults to `pspg`. This is used to check whether results are currently being displayed in the SQL client pane, and if they are, then qsh will exit out of the pager before sending over the next query
* `QSH_EDITOR_COMMAND` - The command used by your SQL client to trigger the editor. This can be changed in order to work with other SQL clients not detailed here
* `QSH_SWITCH_ON_EXECUTE` - Whether we should switch to the SQL client pane after triggering the execution of a query. By default, you will remain in the editor
* `QSH_EDITOR` - The editor you are going to be using, which defaults to `$VISUAL`
* `QSH_EXECUTE_DELAY` - Artificial delay put in to allow the SQL client to accept new queries; defaults to 0.1 seconds. Shouldn't need changing, unless you experience issues with query execution

## Using SSH

To work with database servers over SSH, you should install qsh on your remote host and start tmux in your SSH session. You won't, however, be able to get qsh to work when the editor is running locally and the SQL client is on a remote server, i.e. running within an SSH connection.

If possible, it might be easier to simply provide host and port connection details to the SQL client on your workstation and run everything locally.

## Exit

To clean up any temporary files & go back to normal, simply exit the editor. If you exit accidentally, just trigger the editor again, and it should go back to how it was.



