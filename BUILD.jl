# How to build an executable

using PackageCompiler

PackageCompiler.create_app(
    ".",
    "plutotool";
    # app_name="plutotool",
    include_transitive_dependencies=true,
    force=true)

# The did somethinbg but I have no clue what to do with the result.

#=

I ran it like this:

plutotool\bin\plutotool.exe help

and it printed out the help.

I expect it needs all of the files that it put there.

=#

