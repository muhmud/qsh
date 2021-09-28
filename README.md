# qsh
Query SHell - improved database querying from your terminal

![QSH](images/qsh.png)

Currently supports `mysql`, `postgresql`, and `monetdb`.

## Pre-requisites

You'll need to install & use [tmux](https://github.com/tmux/tmux), which is needed to manage the split panes. It should be available from your package manager. Installing [jq](https://github.com/stedolan/jq) and `tree` would also be a good idea.

For better viewing of SQL results, the [pspg](https://github.com/okbob/pspg) pager is recommended, however, you could also use `less -SinFX`. When displaying results, qsh will try to make a sensible choice, however, you can instead explicitly choose a pager.

To format SQL statements, you will need python 3 and [sqlparse](https://github.com/andialbrecht/sqlparse).

## Setup

Clone this repository to your home:

```bash
$ git clone https://github.com/muhmud/qsh.git ~/.qsh
```

And then add the `~/.qsh/bin` directory to your `PATH`.

You now just need to setup the editor you want to use for writing SQL statements, which will be triggered from your SQL client tool. If you want to, you can setup keyboard shortcuts for this in `~/.inputrc`. The following example does this for `Alt-q`:

```
$if mysql
  "\eq": '\\e;\C-m'
$endif

$if psql
  "\eq": '\\e\C-m'
$endif
```

You can currently use either `vim`/`nvim` or `micro`.

### vim/nvim

#### vim-plug

```
Plug 'muhmud/qsh', { 'dir': '~/.qsh', 'branch': 'main', 'rtp': 'editors/vim' }
```

#### packer

```
{ "~/.qsh", rtp = "editors/vim" }
```

These are the default key mappings, which can be disabled by setting `g:qsh_enable_key_mappings` to `0`:

```
" Alt+e (for execute)
vnoremap <silent> <buffer> <unique> <Esc>e :call QshExecuteSelection()<CR>
vnoremap <silent> <buffer> <unique> <M-e> :call QshExecuteSelection()<CR>
vnoremap <silent> <buffer> <unique> <F5> :call QshExecuteSelection()<CR>

" Alt+y
inoremap <silent> <buffer> <unique> <Esc>y <C-O>:call QshExecuteAll()<CR>
inoremap <silent> <buffer> <unique> <M-y> <C-O>:call QshExecuteAll()<CR>
nnoremap <silent> <buffer> <unique> <Esc>y :call QshExecuteAll()<CR>
nnoremap <silent> <buffer> <unique> <M-y> :call QshExecuteAll()<CR>

" Alt+g (for go)
inoremap <silent> <buffer> <unique> <Esc>g <C-O>:call QshExecute()<CR>
inoremap <silent> <buffer> <unique> <M-g> <C-O>:call QshExecute()<CR>
nnoremap <silent> <buffer> <unique> <Esc>g :call QshExecute()<CR>
nnoremap <silent> <buffer> <unique> <M-g> :call QshExecute()<CR>

" Alt+G
inoremap <silent> <buffer> <unique> <Esc>G <C-O>:call QshExecute("^---$" 0)<CR>
inoremap <silent> <buffer> <unique> <M-G> <C-O>:call QshExecute("^---$", 0)<CR>
nnoremap <silent> <buffer> <unique> <Esc>G :call QshExecute("^---$", 0)<CR>
nnoremap <silent> <buffer> <unique> <M-G> :call QshExecute("^---$", 0)<CR>

" Alt+d (for describe)
vnoremap <silent> <buffer> <unique> <Esc>d :call QshExecuteNamedScriptVisually("describe")<CR>
vnoremap <silent> <buffer> <unique> <M-d> :call QshExecuteNamedScriptVisually("describe")<CR>
nnoremap <silent> <buffer> <unique> <Esc>d :call QshExecuteNamedScript("describe")<CR>
nnoremap <silent> <buffer> <unique> <M-d> :call QshExecuteNamedScript("describe")<CR>
inoremap <silent> <buffer> <unique> <Esc>d <C-O>:call QshExecuteNamedScript("describe")<CR>
inoremap <silent> <buffer> <unique> <M-d> <C-O>:call QshExecuteNamedScript("describe")<CR>

" Alt+r (for rows)
vnoremap <silent> <buffer> <unique> <Esc>r :call QshExecuteNamedScriptVisually("select-some")<CR>
vnoremap <silent> <buffer> <unique> <M-r> :call QshExecuteNamedScriptVisually("select-some")<CR>
nnoremap <silent> <buffer> <unique> <Esc>r :call QshExecuteNamedScript("select-some")<CR>
nnoremap <silent> <buffer> <unique> <M-r> :call QshExecuteNamedScript("select-some")<CR>
inoremap <silent> <buffer> <unique> <Esc>r <C-O>:call QshExecuteNamedScript("select-some")<CR>
inoremap <silent> <buffer> <unique> <M-r> <C-O>:call QshExecuteNamedScript("select-some")<CR>

" Alt+t (for tidy)
vnoremap <silent> <buffer> <unique> <Esc>t :call QshExecuteNamedSnippetVisually("format")<CR>
vnoremap <silent> <buffer> <unique> <M-t> :call QshExecuteNamedSnippetVisually("format")<CR>

" Alt+v
vnoremap <silent> <buffer> <unique> <Esc>v :call QshExecuteScriptVisually()<CR>
vnoremap <silent> <buffer> <unique> <M-v> :call QshExecuteScriptVisually()<CR>
nnoremap <silent> <buffer> <unique> <Esc>v :call QshExecuteScript()<CR>
nnoremap <silent> <buffer> <unique> <M-v> :call QshExecuteScript()<CR>
inoremap <silent> <buffer> <unique> <Esc>v <C-O>:call QshExecuteScript()<CR>
inoremap <silent> <buffer> <unique> <M-v> <C-O>:call QshExecuteScript()<CR>

" Alt+Space
vnoremap <silent> <buffer> <unique> <Esc><Space> :call QshExecuteSnippetVisually()<CR>
vnoremap <silent> <buffer> <unique> <M-Space> :call QshExecuteSnippetVisually()<CR>
nnoremap <silent> <buffer> <unique> <Esc><Space> :call QshExecuteSnippet()<CR>
nnoremap <silent> <buffer> <unique> <M-Space> :call QshExecuteSnippet()<CR>
inoremap <silent> <buffer> <unique> <Esc><Space> <C-O>:call QshExecuteSnippet()<CR>
inoremap <silent> <buffer> <unique> <M-Space> <C-O>:call QshExecuteSnippet()<CR>
```

You can add custom key mappings like this:

```
autocmd Filetype sql call QshCustomSqlKeyMappings()
function QshCustomSqlKeyMappings() 
   ...
endfunction
```

### Micro

The [micro](https://micro-editor.github.io/) plugin can be installed by executing the following:

```bash
$ mkdir -p ~/.config/micro/plug && cp -r ~/.qsh/editors/micro ~/.config/micro/plug/qsh
```

The following key mappings, or similar, can be added to `~/.config/micro/bindings.json`:

```
"Alt-g": "command:QshExecute",
"Alt-G": "command:QshExecute '^---$' 0",
"Alt-e": "command:QshExecuteSelection",
"Alt-y": "command:QshExecuteAll",
"Alt-d": "command:QshExecuteNamedScript 'describe'",
"Alt-r": "command:QshExecuteNamedScript 'select-some'",
"Alt-v": "command:QshExecuteScript",
"Alt-Space": "command:QshExecuteSnippet",
"Alt-t": "command:QshExecuteNamedSnippet 'format'"
```

## Usage

From within a `tmux` session, prefix the invocation of your SQL client with `qsh`:

```
$ qsh psql
```

This will setup your SQL client environment appropriately for `qsh`. Now, trigger the editor using the command for your environment. For `mysql`, this would be `\e;`, and for `psql`, `\e`, or if you setup a keyboard shortcut, as described above, you could use that also.

You should see the editor pane created, where you can now type in queries. A default SQL file is created for you, however, you could open up any other file you need to.

### Executing Queries

* `Alt-e` - Highlight a query to run and execute it
* `Alt-g` - Execute a query without needing to highlight it
* `Alt-G` - Execute multiple statements or function/procedure definitions without needing to highlight
* `Alt-y` - Execute everything in the editor buffer

For `Alt-g`, `qsh` will look for a statement delimited on either side by a semi-colon. This makes it easier to execute a large SQL statement without needing to highlight it every time.

Alternatively, using `Alt-G` does the same thing but changes the delimiter to be the string `---`, which must be the only thing on a line. You can change this to what you like, this is simply the default as defined in the key mapping.

The following provides an example:

```sql
create procedure test(a int)
begin
  update test
    set a = 1;                  /* <- If the cursor is here, Alt-G will create procedure test only */
end;

---                             /* <- This is the customizable delimiter defined in the key binding */

create procedure test2(a int)
begin
  update test
    set a = 2;                  /* <- If the cursor is here, Alt-G will create procedure test2 only */
end;
```

### Scripts

* `Alt-v` - Execute a script, which can be done with or without highlighting

Scripts are shortcuts for SQL statements that return a consistent data set across different database servers. For example, to get a list of tables in the current database, whether `mysql` or `postgresql`, execute the following script:

```
tables
```

You can also apply additional filtering to scripts (you must highlight the query for this to work):

```
tables
where table_schema = 'public'
```

There are quite a few scripts available. You can see what they are by executing the `scripts` script. You can also add you own custom scripts to `~/.qsh/clients/psql/scripts` or `~/.qsh/clients/mysql/scripts`, depending on the database platform you are targeting.

For reference, here is an example of the kinds of scripts available:

```
$ ls ~/.qsh/clients/psql/scripts
all-columns     all-references  all-sessions  columns    procedures  scripts      tables
all-databases   all-routines    all-tables    databases  references  select       triggers
all-functions   all-schemas     all-triggers  describe   routines    select-some  views
all-procedures  all-select      all-views     functions  schemas     sessions

```

#### Named Scripts

* `Alt-d` - Describe a particular table, which may or may not be highlighted
* `Alt-r` - Select some of the data for a particular table

Named scripts take information from the editor as a payload, which is used to provide context. The scripts mentioned above are created by default, however, you can also add your own.

You can either highlight the name of the table to be used with these scripts, however, it's also OK for the cursor to simply be on the table name.

### Snippets

* `Alt-Space` - Execute a snippet, which may or may not be highlighted

Snippets are similar to scripts, however, the results are injected into the editor instead of being displayed as query results. You can also add your own custom snippets to `~/.qsh/clients/psql/snippets` for `postgresql`, for example.

The only snippet currently available is:

* `columns(<table-name>)` - Get a comma-separated list of column names for a particular table

#### Named Snippets

* `Alt-t` - Format a SQL statement, which must be highlighted

Similar to named scripts, these snippets take a payload from the editor. Currently, this feature can be used to format a SQL statement.

### Registering Connections

You can register connections for database servers that you access frequently. This can also be used to store the password for the connection using the native mechanism of each SQL client. This is achieved using the `qsh-reg` tool.

For example:

```
$ qsh-reg -p dev-server psql -hmy-dev-server -Uroot -ddevdb
```

This will register a connection called `dev-server` using the provided `psql` invocation. The `-p` option means that a password is to be stored, which the script will prompt you for.

Once the connection is registered, you can connect like this:

```
$ qsh dev-server
```

You can also execute other tools using the connection info, such as `pg_dump`:

```
$ qsh -c pg_dump dev-server --table=public.some_table -s
```

Execute `qsh-reg` without any arguments to see all the available options.

## Options

The following environment variables can be changed if required:

* `QSH_EDITOR` - The editor you are going to be using, which defaults to `$VISUAL`
* `QSH_PAGER` - The pager you will be using, which by default will try `pspg`, `less`, and `cat` in that order. 

## Using SSH

To work with database servers over SSH, you should install `qsh` on your remote host and start `tmux` in your SSH session. You won't, however, be able to get `qsh` to work when the editor is running locally and the SQL client is on a remote server, i.e. running within an SSH connection.

If possible, it might be easier to simply provide host and port connection details to the SQL client on your workstation and run everything locally.

## Exit

To clean up any temporary files & go back to normal, simply exit the editor. If you exit accidentally, just trigger the editor again, and it should go back to how it was.

You can also explicitly cleanup temporary files created by `qsh` by executing:

```
$ qsh-cleanup
```

