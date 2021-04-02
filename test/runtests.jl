
using Test

import PlutoTool: plutotool, commands, test_context,
                  CommandException, CellNotFound, BadOption, BadOption, CellNotEmpty,
                  new_notebook, new_cell, find_empty, find, delete, set_contents


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
end


@testset "Build a sample notebook from scratch and test with it" begin
  ctx = test_context()
  let notebook_file = "SampleNotebook"
    rm(notebook_file, force=true)
    # Look for notebook that doesn't exist:
    @test_throws SystemError find_empty(ctx, notebook_file)
    # Create notebook:
    new_notebook(ctx, notebook_file)
    @test isfile(notebook_file)
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
    before = new_cell(ctx, "before", notebook_file, found[1])

    # Add a cell after it:
    after = new_cell(ctx, "after", notebook_file, found[1])

    # negative find cell test

    # negative find test

    # negative enpty test

  end

end
