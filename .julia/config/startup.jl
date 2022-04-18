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

macro vim(file, line)
    edit(file, line)
end
