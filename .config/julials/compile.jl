#=
This file should execute with project which contains LanguageServer,
and PackageCompiler should be installed at ~/.julia/environments/compiler,
the image file will be saved at this __DIR__ by default.

Example:
```bash
julia --project=@nvim_lsp ./compile.jl
```
=#

pushfirst!(LOAD_PATH, "@compiler") # load PackageCompiler
using PackageCompiler
popfirst!(LOAD_PATH)
import Pkg, Libdl

function compile_sysimg(args::Vector{<:AbstractString})
    img_path = get(args, 1, @__DIR__)

    project = Base.active_project() |> dirname
    sysimage_path = joinpath(img_path, "sys.$(Libdl.dlext)")

    create_sysimage(:LanguageServer; sysimage_path, project,
        precompile_execution_file=joinpath(@__DIR__, "exec.jl"))
end


if abspath(PROGRAM_FILE) == @__FILE__
    compile_sysimg(ARGS)
end
