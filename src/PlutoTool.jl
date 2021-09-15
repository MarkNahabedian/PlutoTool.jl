module PlutoTool

using Printf: @printf

import Pluto

# include("burst.jl")  # Still under development

############################################################
# Contest

#=
For testing, we want to capture output.  Julia doesn't appear to have
a way to dynamically bind Base.stderr analogous to CommonLisp's
dynamic binding of *STANDARD-OUTPUT*.

We define Context as a way to pass in the streams to be used for
standard input and standard output.
=#

struct Context
  stdout::IO
  stderr::IO
end

function interactive_context()::Context
  return Context(Base.stdout, Base.stderr)
end

function test_context()::Context
  return Context(IOBuffer(write=true), IOBuffer(write=true))
end


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


struct CellNotEmpty <: CommandException
  notebook::String
  cell_id::String  
end

function show(io::IO, e::CellNotEmpty)
  @printf(io, "Cell %s of %s is not empty.", e.cell_id, e.notebook)
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
function help(ctx::Context)
  for cmd in commands
    @printf(ctx.stdout, "%s\n", Base.doc(cmd))
  end
end

ensure_command(help)


"""    new_notebook path
  Create a new Pluto notebook.
  """
function new_notebook(ctx::Context, path::String)
  notebook = Pluto.Notebook(Pluto.Cell[Pluto.Cell("")], path)
  Pluto.save_notebook(notebook)
  @printf(ctx.stdout, "Created %s\n", notebook.path)
  return notebook.path
end

ensure_command(new_notebook)


"""    new_cell before/after notebook_path relative_to_cell_id
  Insert a new, enpty cell before or after the cell specified by existing_cell_id.
  The id of the new cell is returned.
  """
function new_cell(ctx::Context, before_after::String, notebook_path::String, relative_to_cell_id::String)::String
  notebook = get_notebook(notebook_path)
  rel = validate_option(before_after, :before, :after)
  index = find_cell(notebook, relative_to_cell_id)
  @assert index >= 1
  @assert index <= length(notebook.cells)
  if rel == :after
    index = index + 1
  end
  cell = Pluto.Cell()
  notebook.cells_dict[cell.cell_id] = cell
  insert!(notebook.cell_order, index, cell.cell_id)
  Pluto.save_notebook(notebook)
  @printf(ctx.stdout, "Inserted new cell %s\n", string(cell.cell_id))
  return string(cell.cell_id)
end

ensure_command(new_cell)


"""    find_empty notebook_path [-w]
  List the unique ids of empty cells.  With -w find_empty will include cells that contain only whitespace.
  """
function find_empty(ctx::Context, notebook_path::String, flag::String="")::Vector{String}
  found = String[]
  allow_whitespace = flag == "-w"
  notebook = get_notebook(notebook_path)
  for cell in notebook.cells
    if isempty(cell.code)
      push!(found, string(cell.cell_id))
      show_id(ctx.stdout, cell)
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
        show_id(ctx.stdout, cell)
      end
    end
  end
  return found
end

ensure_command(find_empty)


"""    find notebook_path match...
  Lists the ids of any cells that contain any of the match strings.
  """
function find(ctx::Context, notebook_path::String, match::String...)
  found = String[]
  notebook = get_notebook(notebook_path)
  for cell in notebook.cells
    for m in match
      if occursin(m, cell.code)
        push!(found, string(cell.cell_id))
        show_id(ctx.stdout, cell)
        break
      end
    end
  end
  return found
end

ensure_command(find)


"""    delete notebook cell_id
  Delete the cell with the specified id from the notebook.
  """
function delete(ctx::Context, notebook_path::String, cell_id::String)
  notebook = get_notebook(notebook_path)
  index = find_cell(notebook, cell_id)
  cell = notebook.cells[index]
  if cell.code != ""
    throw(CellNotEmpty(path, cell_id))
  end
  deleteat!(notebook.cell_order, index)
  delete!(notebook.cells_dict, cell.cell_id)
  Pluto.save_notebook(notebook)
end

ensure_command(delete)


"""    set_contents notebook cell_id contents
  Set the contents of the specified Cell to contents.
  The cell must previously have been empty.
  """
function set_contents(ctx::Context, notebook_path::String, cell_id::String, contents::String)
  notebook = get_notebook(notebook_path)
  index = find_cell(notebook, cell_id)
  cell = notebook.cells[index]
  if cell.code != ""
    throw(CellNotEmpty(path, cell_id))
  end
  cell.code = contents
  Pluto.save_notebook(notebook)  
end

ensure_command(set_contents)

#=
"""
    burst notebook_file
The burst command is under development.
"""
function burst(ctx::Context, notebook_path::String)
  notebook = get_notebook_readonly(notebook_path)
  extract_doc(notebook, ctx.stdout)
end

ensure_command(burst)
=#


############################################################
# Utility functions:


"""Print the unique id of the Cell to stdout.
  """
function show_id(io::IO, cell)
  @printf(io, "%s\n", cell.cell_id)
end


"""Read and return the Pluto.Notebook from the specified file."""
function get_notebook(path::String)::Pluto.Notebook
  return Pluto.load_notebook(path)
end

function get_notebook_readonly(path::String)::Pluto.Notebook
  return Pluto.load_notebook(path; disable_writing_notebook_files=true)
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
function validate_option(input::String, allowed::Symbol...)::Symbol
  for s in allowed
    if input == string(s)
      return s
    end
  end
  throw(BadOption(input, allowed))
end


############################################################
## main


function plutotool(ctx::Context, args::String...)
  if length(ARGS) < 1
    @printf(ctx.stdout, "%s command ...\n", "plutotool")   # PROGRAM_NAME
    help(ctx)
    return
  end
  cmd_name = ARGS[1]
  cmd = lookup_command(cmd_name)
  if cmd == nothing
    @printf(ctx.stderr, "Unknown command: %s.\n", cmd_name)
    help(ctx)
    return
  end
  try
    cmd(ctx, ARGS[2:end]...)
  catch e
    if isa(e, CommandException)
      @printf(ctx.stderr, "%s\n", string(e))
    elseif isa(e, MethodError)
      @printf(ctx.stderr, "Wrong arguments:\n%s\n", Base.doc(cmd))
      showerror(stx.stderr, e)
    else
      rethrow(e)
    end
  end
end


# Do our thing if being run from the command line:
if lowercase(split(basename(PROGRAM_FILE), ".")[1]) == "plutotool"
  plutotool(interactive_context(), ARGS...)
end


end    # module PlutoTool
