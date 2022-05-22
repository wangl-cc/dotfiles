try
    using Revise
catch e
    if e isa ArgumentError
        import Pkg
        current_project = Pkg.project().path
        Pkg.activate()
        Pkg.add(["Revise"])
        Pkg.activate(current_project)
        using Revise
    else
        rethrow()
    end
end

dumpi(arg, i::Integer=1) = dump(arg; maxdepth=i)
