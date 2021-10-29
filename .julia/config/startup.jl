try
    using Revise
catch e
    if e isa ArgumentError
        import Pkg
        Pkg.add("Revise")
    else
        rethrow()
    end
end
