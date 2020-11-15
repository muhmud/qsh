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

Ensure that `$QSH_EDITOR`, or `$VISUAL`, in your shell environment is set to the editor you want to use. Currently this either be vim or [micro](https://micro-editor.github.io).

### Vim

You can install the vim plugin using `vim-plug` by adding the following line to your `~/.vimrc`:

```
Plug 'muhmud/qsh', { 'dir': '~/.qsh/editors/vim' }
```

Add the following key mapping to trigger query execution from the editor:

```
vnoremap <silent> <F5> :call QshExecuteSelection()<CR>
```

### Micro

The micro plugin can be installed by executing the following:

```bash
$ mkdir -p ~/.config/micro/plug && cp -r ~/.qsh/editors/micro ~/.config/micro/plug/qsh
```

The following key mapping should be added to `~/.config/micro/bindings.json`:

```
"F5": "lua:qsh.ExecuteSelection"
```

## Usage

From within a tmux session, start your SQL client, i.e. `mysql` or `psql`, using qsh as the `$EDITOR`. To simplify this, you could setup the following alias:

```
alias mysql='EDITOR=~/.qsh/scripts/qsh mysql --pager="pspg"'
```

For postgresql, the `$QSH_EDITOR_COMMAND` option will need changing, as the defaults work for mysql:

```
export PSQL_PAGER="pspg"
export PSQL_EDITOR=~/.qsh/scripts/qsh

alias psql='QSH_EDITOR_COMMAND="\\e" psql'
```

Once started, trigger the editor using the command for your environment. For mysql, this would be `\e;`, and for psql, `\e`. You should see the editor pane created, where you can now type in queries. A default file is created for you, however, you could open up any other file you need to. To execute a query, simply highlight it and press `F5`. The results should appear in the SQL client pane below.

## Options

The following environment variables can be changed if required:

* `QSH_PAGER` - The pager you will be using, which defaults to `pspg`. This is used to check whether results are currently being displayed in the SQL client pane, and if they are, then exit out of the pager before sending over the next query
* `QSH_EDITOR_COMMAND` - The command used by your SQL client to trigger the editor. This can be changed in order to work with other SQL clients not detailed here
* `QSH_SWITCH_ON_EXECUTE` - Whether we should switch to the SQL client pane after triggering the execution of a query. By default, you will remain in the editor
* `QSH_EDITOR` - The editor you are going to be using, which defaults to `$VISUAL`
* `QSH_EXECUTE_DELAY` - Artificial delay put in to allow the SQL client to accept new queries; defaults to 0.1 seconds. Shouldn't need changing, unless you experience issues with query execution

## Using SSH

To work with servers over SSH, you should install qsh on your remote host and start tmux in your SSH session. You won't, however, be able to get qsh to work when the editor is running locally and the SQL client is on a remote server, i.e. running within an SSH connection.

## Exit

To clean up any temporary files & go back to normal, simply exit the editor. If you exit accidentally, just trigger the editor again, and it should go back to how it was.

