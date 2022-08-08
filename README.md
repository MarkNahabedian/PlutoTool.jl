<a href="https://github.com/MarkNahabedian/PlutoTool.jl/actions/workflows/ci.yml">
  <img
    src="https://github.com/MarkNahabedian/PlutoTool.jl/actions/workflows/ci.yml/badge.svg"
    alt="Build Status" />
</a>
<a href="https://codecov.io/gh/MarkNahabedian/PlutoTool.jl">
  <img
    src="https://codecov.io/gh/MarkNahabedian/PlutoTool.jl/branch/master/graph/badge.svg"
    alt="Test Coverage" />
</a>
<a href="https://marknahabedian.github.io/PlutoTool.jl/">
  <img
    src="https://img.shields.io/badge/docs-stable-blue.svg"
    alt="Docs Stable" />
</a>


# PlutoTool

PlutoTool is a command line utility for doing simple manipulations on
Pluto notebooks.

plutotool is designed to be easy to extend.

Run with no arguments for help.

**Warning**: Be sure that your notebook is not in use when applying plutotool.


## Motivation

I was working through an open courseware class where the lecture notes
were provided as interactive Pluto notebooks.  I tried to add a new
cell to my local copy of the notebook to work on one of the exercises,
but the Pluto keyboard gesture for that wasn't working.  The UI
buttons were invisible because I use a dark theme that the icon
library that Pluto uses is clueless about. I saw that the structure of
the notebook file was pretty simple and then observed that the Pluto
module had an interface that was pretty easy to figure out.  plutotool
is a command line tool for performing some simple operations on a
Pluto notebook file.


## PlutoTool Subcommands

A list of PlutoTool subcommands can be found [here](PlutoTool_Commands.md).

