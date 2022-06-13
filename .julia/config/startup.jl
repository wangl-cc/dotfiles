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

ENV["JULIA_COC_NVIM_DISABLE"] = "false"

dump1(arg) = dump(arg; maxdepth=1)
dumpi(arg, i::Integer) = dump(arg; maxdepth=i)
dumpi(i::Integer) = arg -> dump(arg; maxdepth=i)
