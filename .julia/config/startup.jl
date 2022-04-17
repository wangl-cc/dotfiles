try
    using Revise, OhMyREPL
catch e
    if e isa ArgumentError
        import Pkg
        current_project = Pkg.project().path
        Pkg.activate()
        Pkg.add(["Revise", "OhMyREPL"])
        Pkg.activate(current_project)
        using Revise, OhMyREPL
    else
        rethrow()
    end
end
