#=
This file should execute with project which contains LanguageServer,
with precompile_execution_file at given project directory.
the image file will be saved at this __DIR__.

Example:
```bash
julia --project=@nvim_lsp ./compile.jl
```
=#
import Pkg, Libdl

const project = dirname(Base.active_project())
Pkg.activate(@__DIR__)
Pkg.instantiate()
using PackageCompiler
Pkg.activate(project)

function compile_sysimg()
    sysimage_path = joinpath(@__DIR__, "sys.$(Libdl.dlext)")
    create_sysimage(:LanguageServer; sysimage_path, project,
        precompile_execution_file=joinpath(project, "exec.jl"))
end

if abspath(PROGRAM_FILE) == @__FILE__
    compile_sysimg()
end
