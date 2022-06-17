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

using Random

const UpperCases = 65:90
const LowerCases = 97:122
const Digits = 48:57
const Hyphen = 45
const Underscore = 95
const DefaultAlloweds = UInt8[UpperCases; LowerCases; Digits; Hyphen; Underscore]

gen_passwd(length::Integer=12, symbols::Vector{<:Integer}=DefaultAlloweds) =
    String(rand(Random.RandomDevice(), symbols, length))
