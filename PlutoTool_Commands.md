plutotool command ...
```
help
```

Print documentation to standard output.

```
new_notebook path
```

Create a new Pluto notebook.

```
new_cell before/after notebook_path relative_to_cell_id
```

Insert a new, enpty cell before or after the cell specified by existing*cell*id. The id of the new cell is returned.

```
find_empty notebook_path [-w]
```

List the unique ids of empty cells.  With -w find_empty will include cells that contain only whitespace.

```
find notebook_path match...
```

Lists the ids of any cells that contain any of the match strings.

```
delete notebook cell_id
```

Delete the cell with the specified id from the notebook.

```
set_contents notebook cell_id contents
```

Set the contents of the specified Cell to contents. The cell must previously have been empty.

```
set_workspace notebook path_to_workspace_dir
```

The directory identified by path*to*workspace_dir should include   a Project.toml and a Manifest.toml file.  The contents of those   files will be included in the notebook for the Pluto package manager   to find.

