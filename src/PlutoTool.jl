module PlutoTool


using Printf: @printf

import Pluto


############################################################
# To facilitate testing, we define a set of exceptions which command functions
# might throw.  All such exceptions inherit from CommandException.

abstract type CommandException <: Exception end


struct CommandNotFound <: CommandException
  command::String
end

function show(io::IO, e::CommandNotFound)
  write(io, "command not found: ")
  write(io, e.command)
end


struct CellNotFound <: CommandException
  notebook::String
  cell_id::String
end

function show(io::IO, e::CellNotFound)
  @printf("Notebook %s has no cell with id %s", e.notebook, e.cell_id)
end


struct BadOption <: CommandException
  input::String
  valid::Vector{String}
end

function show(io::IO, e::BadOption)
  @printf("Bad option %s.  Valid options are %s",
          e.input,
          join(e.valid, ", "))
end


############################################################
# Commands:

"""Each element of commands is a function that implements a PlutoTool subcommand.

The function should have a doc string appropriate to an end user of the command line
tool.

Each command should throw an exception (subtype of CommandException) if it fails.
To facilitate testing the command should return a value appropriate to its function.
"""
commands = []


"""Add or replace cmd in commands.
"""
function ensure_command(cmd)
  name = Base.nameof(cmd)
  for index = 1:length(commands)
    f = commands[index]
    if Base.nameof(f) == name
      commands[index] = cmd
      return nothing
    end
  end
  push!(commands, cmd)
  return nothing
end


"""Find a command with the specified name in commands or throw CommandNotFound.
"""
function lookup_command(name::String)
  for cmd in commands
    if string(Base.nameof(cmd)) == name
       return cmd
    end
  end
  throw(CommandNotFound(name))
end


"""    help
Print documentation to standard output.
"""
function help()
  for cmd in commands
    @printf("%s\n", Base.doc(cmd))
  end
end

ensure_command(help)


"""    new_notebook path
Create a new Pluto notebook.
"""
function new_notebook(path::String)
  notebook = Pluto.Notebook(Pluto.Cell[Pluto.Cell("")], path)
  Pluto.save_notebook(notebook)
  @printf("Created %s\n", notebook.path)
  return notebook.path
end

ensure_command(new_notebook)


"""    new_cell before/after notebook_path relative_to_cell_id
Insert a new, enpty cell before or after the cell specified by existing_cell_id
"""
function new_cell(before_after::String, notebook_path::String, relative_to_cell_id::String)
  notebook = get_notebook(notebook_path)
  index = find_cell(notebook, relative_to_cell_id)
  rel = validate_option(before_after, :before, :after)
  if rel == :after
    index = index + 1
  end
  new_cell = Pluto.Cell()
  insert!(notebook.cells, index, new_cell)
  Pluto.save_notebook(notebook)
  @printf("Inserted new cell %s\n", string(new_cell.cell_id))
  return true
end

ensure_command(new_cell)


"""    find_empty notebook_path [-w]
List the unique ids of empty cells.  With -w find_empty will include cells that contain only whitespace.
"""
function find_empty(notebook_path::String, flag::String="")::Vector{String}
  found = String[]
  allow_whitespace = flag == "-w"
  notebook = get_notebook(notebook_path)
  for cell in notebook.cells
    if isempty(cell.code)
      push!(found, string(cell.cell_id))
      show_id(cell)
      continue
    end
    if allow_whitespace
      skip = false
      for char in cell.code
        if !isspace(char)
          skip = true
          break
        end
      end
      if !skip
        push!(found, string(cell.cell_id))
        show_id(cell)
      end
    end
  end
  return found
end

ensure_command(find_empty)


"""    find notebook_path match...
Lists the ids of any cells that contain any of the match strings.
"""
function find(notebook_path::String, match::Vector{String}...)
  notebook = get_notebook(notebook_path)
  for cell in notebook.cells
    for m in match
      if occursin(m, cell.code)
        show_id(cell)
        break
      end
    end
  end
  return true
end

ensure_command(find)


"""    delete cell_id
Delete the cell with the specified id from the notebook.
"""
function delete(path::String, cell_id::String)
  notebook = get_notebook(notebook_path)
  index = find_cell(notebook, cell_id)
  deleteat!(notebook.cells, index)
  Pluto.save_notebook(notebook)
end

ensure_command(delete)


############################################################
# Utility functions:


"""Print the unique id of the Cell to stdout.
"""
function show_id(cell)
  @printf("%s\n", cell.cell_id)
end


"""Read and return the Pluto.Notebook from the specified file."""
function get_notebook(path::String)
  return Pluto.load_notebook(path, false)
end


"""find_cell looks for a Cell with the specified id in the Notebook and returns that cells index.
Throws CellNotFound if not found."""
function find_cell(notebook::Pluto.Notebook, id::String)::Int
  for index = 1:length(notebook.cells)
    cell = notebook.cells[index]
    if string(cell.cell_id) == id
      return index
    end
  end
  throw(CellNotFound(notebook.path, id))
end


"""return the symbol that input matches, or throw BadOption."""
function validate_option(input::String, allowed::Vector{Symbol})::Symbol
  for s in allowed
    if input == string(s)
      return s
    end
  end
  throw(BadOption(input, allowed))
end


############################################################
## main


function plutotool(args::Vector{String})
  if length(ARGS) < 1
    @printf(Base.stderr, "%s command ...\n", "plutotool")   # PROGRAM_NAME
    help()
    return
  end
  cmd_name = ARGS[1]
  cmd = lookup_command(cmd_name)
  if cmd == nothing
    @printf(Base.stderr, "Unknown command: %s.\n", cmd_name)
    help()
    return
  end
  try
    cmd(ARGS[2:length(ARGS)]...)
  catch e
    if isa(e, CommandException)
      @printf(Base.stderr, "%s\n", string(e))
    elseif isa(e, MethodError)
      @printf(Base.stderr, "Wrong arguments:\n%s\n", Base.doc(cmd))
    else
      rethrow(e)
    end
  end
end


# Do our thing if being run from the command line:
if lowercase(split(basename(PROGRAM_FILE), ".")[1]) == "plutotool"
  plutotool(ARGS)
end


end    # module PlutoTool
