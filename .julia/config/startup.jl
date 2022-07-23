using Base.Meta: isexpr

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
            import Pkg
            current_project = Base.active_project()
            Pkg.active()
            Pkg.add($missing_pkgs)
            Pkg.active(; current_project)
            $using_pkgs
        end
    else
        ex = using_pkgs
    end
    return esc(ex)
end

@safe_using LazyStartup

@lazy_startup @safe_using(Revise) import * using * include(*)

ENV["JULIA_COC_NVIM_DISABLE"] = "false"

dump1(arg) = dump(arg; maxdepth=1)
dumpi(arg, i::Integer) = dump(arg; maxdepth=i)
dumpi(i::Integer) = Base.Fix2(dumpi, i)

@lazy_startup begin
    using Random

    const UpperCases = 65:90
    const LowerCases = 97:122
    const Digits = 48:57
    const Hyphen = 45
    const Underscore = 95
    const DefaultAlloweds = UInt8[UpperCases; LowerCases; Digits; Hyphen; Underscore]

    gen_passwd(length::Integer=12, symbols::Vector{<:Integer}=DefaultAlloweds) =
        String(rand(Random.RandomDevice(), symbols, length))
end gen_passwd
