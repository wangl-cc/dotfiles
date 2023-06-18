using Base.Meta

"""
    @safe_using Pkg Pkg = UUID ...

Simmilar to `using`, but you can specify the package UUID.
Besides if given pacakges is not installed,
install them into `@v#.#` environment.
"""
macro safe_using(pkgs...)
    return _safe_using(pkgs...)
end

function _safe_using(pkgs...)
    using_pkgs = Expr(:using)
    missing_pkgs = Expr(:vect)
    for pkg in pkgs
        if pkg isa Symbol
            name = pkg
            uuid = nothing
        elseif isexpr(pkg, :(=), 2)
            name = pkg.args[1]::Symbol
            uuid = Base.UUID(pkg.args[2]::String)
        else
            throw(ArgumentError("Pkg must be defined as NAME or NAME = UUID"))
        end
        push!(using_pkgs.args, Expr(:., name))
        name_s = String(name)
        installed = false
        for env in Base.load_path()
            found = Base.project_deps_get(env, name_s)
            if found !== nothing && (uuid === nothing || found.uuid == uuid)
                installed = true
                break
            end
        end
        installed || push!(missing_pkgs.args, :(Pkg.PackageSpec(; name=$name_s, uuid=$uuid)))
    end
    if !isempty(missing_pkgs.args)
        ex = quote
            @info "Installing missing pacakges"
            import Pkg
            current_project = Base.active_project()
            Pkg.activate()
            Pkg.add($missing_pkgs)
            Pkg.activate(current_project)
            $using_pkgs
        end
    else
        ex = using_pkgs
    end
    return esc(ex)
end

using REPL
@safe_using LazyStartup

# This a temporary fix for JuliaLang/julia#49319
# should be removed when #50064 is merged
@static if isdefined(REPL, :Numbered)
    function REPL.Numbered.get_usings!(usings, ex)
        ex isa Expr || return usings
        # get all `using` and `import` statements which are at the top level
        for (i, arg) in enumerate(ex.args)
            if Base.isexpr(arg, :toplevel)
                REPL.Numbered.get_usings!(usings, arg)
            elseif Base.isexpr(arg, [:using, :import])
                push!(usings, popat!(ex.args, i))
            end
        end
        return usings
    end
end

atreplinit() do repl
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    if isdefined(REPL, :ipython_mode!)
        REPL.ipython_mode!(repl)
    elseif isdefined(REPL, :numbered_prompt!)
        REPL.numbered_prompt!(repl)
    end
    lazy_startup_init!()
end

@lazy_startup @safe_using(Revise) import * using * include(*) includet(*)

@lazy_startup @safe_using(BenchmarkTools) @btime() @benchmark()

@lazy_startup @safe_using(Cthulhu) @descend() @descend_code_typed() @descend_code_warntyp()

ENV["__JULIA_LSP_DISABLE"] = "true"

dump1(arg) = dump(arg; maxdepth=1)
dumpi(arg, i::Integer) = dump(arg; maxdepth=i)
dumpi(i::Integer) = Base.Fix2(dumpi, i)

using InteractiveUtils

InteractiveUtils.define_editor("nvr"; wait=false) do cmd, path, line, column
    cmd = line == 0 ? `$cmd $path` :
          column == 0 ? `$cmd +$line $path` :
          `$cmd "+normal $(line)G$(column)|" $path`
end
