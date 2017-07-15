# Package

version       = "0.1.0"
author        = "Chris Watson"
description   = "Static site generator inspired by Middleman"
license       = "MIT"

bin = @["overlord"]
srcDir = "src"

# Dependencies

requires "nim >= 0.17.0"
requires "commandeer >= 0.11.0"