try
    using Revise, OhMyREPL
catch e
    if e isa ArgumentError
        import Pkg
        Pkg.add("Revise")
        Pkg.add("OhMyREPL")
        using Revise, OhMyREPL
    else
        rethrow()
    end
end
