
using Test 

import PlutoTool: plutotool, commands, lookup_command, get_notebook, test_context, interactive_context,
                  CommandException, CommandNotFound, BadOption, BadOption, CellNotEmpty,
                  new_notebook, new_cell, find_empty, find, delete, set_contents, set_workspace

HELP_DOC_FILE = "../PlutoTool_Commands.md"

@testset "Verify help documentation" begin
  ctx = test_context()
  plutotool(ctx, "help")
  out = String(take!(ctx.stdout))
  err = String(take!(ctx.stderr))
  @test length(err) == 0
  # At least two lines of output per command
  @test length(split(out, "\n")) >= 2 * length(commands)
  # Every command is documented:
  for cmd in commands
    @test occursin(string(cmd), out)
  end
  open(f -> write(f, out),
       HELP_DOC_FILE; truncate=true)
end


@testset "Build a sample notebook from scratch and test with it" begin
  ctx = test_context()
  # Missing command detection:
  @test_throws CommandNotFound lookup_command("no-such-command")
  let notebook_file = "SampleNotebook"
    rm(notebook_file, force=true)
    # Look for notebook that doesn't exist:
    @test_throws SystemError find_empty(ctx, notebook_file)
    # Create notebook:
    new_notebook(ctx, notebook_file)
    @test isfile(notebook_file)
    @test length(get_notebook(notebook_file).cells) == 1
    # Find empty cell
    empty = find_empty(ctx, notebook_file)
    @test length(empty) == 1
    # Set its content:
    original_cell = empty[1]
    set_contents(ctx, notebook_file, original_cell, "# This is a cell.")
    found = find(ctx, notebook_file, "This", "cell")
    @test length(found) == 1
    @test found[1] == original_cell
    # Add a cell before it:
    before = new_cell(ctx, "before", notebook_file, original_cell)
    # Add a cell after it:
    after = new_cell(ctx, "after", notebook_file, original_cell)
    @test length(get_notebook(notebook_file).cells) == 3
    # Did they get added?
    set_contents(ctx, notebook_file, before, "# Before.")
    set_contents(ctx, notebook_file, after, "# After.")
    # negative find cell test
    found = find(ctx, notebook_file, "notfound")
    @test length(found) == 0
    # negative enpty test
    @test length(find_empty(ctx, notebook_file)) == 0
    # Deletion:
    @test length(find_empty(ctx, notebook_file)) == 0
    delete_me = new_cell(ctx, "after", notebook_file, original_cell)
    @test length(find_empty(ctx, notebook_file)) == 1    
    delete(ctx, notebook_file, delete_me)
    @test length(find_empty(ctx, notebook_file)) == 0
  end
end


@testset "test set_workspace" begin
    ctx = test_context()
    let notebook_file = "NotebookWithWorkspace"
        rm(notebook_file, force=true)
        # Create notebook:
        new_notebook(ctx, notebook_file)
        set_workspace(ctx, notebook_file, "..")
    end    
end
