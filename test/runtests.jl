
using Test

import PlutoTool: plutotool, 
                  CommandException, CellNotFound, BadOption, BadOption, CellNotEmpty,
                  new_notebook, new_cell, find_empty, find, delete, set_contents



@testset "Build a sample notebook from scratch and test with it" begin
#  plutotool("help")
  let notebook_file = "SampleNotebook"
    rm(notebook_file, force=true)
    # Look for notebook that doesn't exist:
    @test_throws SystemError find_empty(notebook_file)
    # Create notebook:
    new_notebook(notebook_file)
    @test isfile(notebook_file)
    # Find empty cell
    empty = find_empty(notebook_file)
    @test length(empty) == 1
    # Set its content:
    original_cell = empty[1]
    set_contents(notebook_file, original_cell, "# This is a cell.")
    found = find(notebook_file, "This", "cell")
    @test length(found) == 1
    @test found[1] == original_cell
    # Add a cell before it:
    before = new_cell("before", notebook_file, found[1])

    # Add a cell after it:
    after = new_cell("after", notebook_file, found[1])

    # negative find cell test

    # negative find test

    # negative enpty test

  end

end
