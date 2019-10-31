abstract type AbstractHead end
struct MacroCall <: AbstractHead end
struct Func <: AbstractHead end
struct Macro <: AbstractHead end
struct Abstract <: AbstractHead end
struct Struct <: AbstractHead end
struct Call <: AbstractHead end
struct KW <: AbstractHead end
struct Where <: AbstractHead end
struct Curly <: AbstractHead end
struct Subtype <: AbstractHead end
struct Instance <: AbstractHead end
struct Splat <: AbstractHead end

const HEADDICT = Dict(
                      :macrocall => MacroCall(),
                      :function => Func(),
                      :(=) => Func(),
                      :macro => Macro(),
                      :abstract => Abstract(),
                      :struct => Struct(),
                      :call => Call(),
                      :kw => KW(),
                      :where => Where(),
                      :curly => Curly(),
                      :<: => Subtype(),
                      :(::) => Instance(),
                      :... => Splat()
                     )

parseexpr(ex::Expr) = parseexpr(HEADDICT[ex.head], ex.args...)
parseexpr(::MacroCall, macrosymbol::Symbol, line::LineNumberNode, ex::Expr) = parseexpr(ex)

# function and macro

parseexpr(::Func, head, block) = Func(), _parsefunc(head)
parseexpr(::Func, head, block) = Func(), _parsefunc(head)
parseexpr(::Macro, head, block) = Macro(), _parsefunc(head)

_parsefunc(ex::Expr) = ex, parsefunc(ex)

parsefunc(ex::Expr) = parsefunc(HEADDICT[ex.head], ex.args...)
function parsefunc(::Call, funcname::Symbol, args...)
    posargs = Tuple{Symbol, Union{Symbol, Expr}, Bool, Any}[]
    kwargs = Tuple{Symbol, Union{Symbol, Expr}, Bool, Any}[]
    for arg in args
        if isa(arg, Expr) && arg.head == :parameters
            append!(kwargs, parsekwarg(arg.args))
        else
            push!(posargs, parsearg(arg))
        end
    end
    funcname, posargs, kwargs
end
function parsefunc(::Where, funcex::Expr, typeexs...)
    funcname, posargs, kwargs = parsefunc(funcex)
    typesubdic = Dict(parsetypeex(ex) for ex in typeexs)
    #  posargs = [(argname, typesub(typesubdic, argtype), var, value) for (argname, argtype, var, value) in posargs]
    #  kwargs = [(argname, typesub(typesubdic, argtype), var, value) for (argname, argtype, var, value) in kwargs]
    funcname, posargs, kwargs
end

typesub(typesubdic::Dict{Symbol, Symbol}, type::Symbol) = get(typesubdic, type, type)
function typesub(typesubdic::Dict{Symbol, Symbol}, type::Expr)
    paras = [typesub(typesubdic, para) for para in type.args[2:end]]
    type.args[2:end] = paras
    type
end

parsetypeex(ex::Expr) = ex.args[1] => ex.args[2]
parsetypeex(s::Symbol) = s => :Any

parsearg(ex::Expr) = parsearg(HEADDICT[ex.head], ex.args...)
parsearg(s::Symbol) = s, :Any, false, nothing
function parsearg(::Splat, ex)
    argname, argtype, _, value = parsearg(ex)
    argname, argtype, true, value
end
parsearg(::KW, arg, value) = (parsearg(arg)[1:3]..., value)
parsearg(::Instance, argname::Symbol, argtype) = argname, argtype, false, nothing

parsekwarg(args)= [parsearg(arg) for arg in args]

# struct

parseexpr(::Struct, mut::Bool, head, block::Expr) = Struct(), parsestruct(head, block)

function parsestruct(head, block::Expr)
    structname, supertypename, typesubdic = parsehead(head)
    #  fields = [(name, typesub(typesubdic, type)) for (name, type) in parsefield.(block.args[2:2:end])]
    fields = [(name, type) for (name, type) in parsefield.(block.args[2:2:end])]
    head, (structname, supertypename, fields)
end

parsehead(s::Symbol) = s, :Any ,Dict{Symbol, Symbol}()
parsehead(ex::Expr) = parsehead(HEADDICT[ex.head], ex.args...)
function parsehead(::Subtype, type, supertype)
    structname, _, typesubdic = parsehead(type)
    supertypename, _, _ = parsehead(supertype)
    structname, supertypename, typesubdic
end
function parsehead(::Curly, name::Symbol, typeexs...)
    typesubdic = Dict(parsetypeex(ex) for ex in typeexs)
    name, :Any, typesubdic
end

parsefield(s::Symbol) = s, :Any
parsefield(ex::Expr) = ex.args[1], ex.args[2]

# abstract type

parseexpr(::Abstract, head) = Abstract(), parsehead(head)[1:3]

# gendoc

gendoc(str::AbstractString; withargs::Bool=true) = gendoc(Meta.parse(str), withargs=withargs)
function gendoc(ex::Expr; withargs::Bool=true)
    type, (exhead, info)  = parseexpr(ex)
    nameline = "\"\"\"\n    $exhead\n"
    description = "\ndescription\n\n"
    if withargs
        typespclines = gendoc(type, info)
    else
        typespclines = ""
    end
    testline = """
    # Example
    ```jldoctest
    ```
    \"\"\"
    """
    nameline * description * typespclines * testline
end
function gendoc(::Union{Func, Macro}, info)
    lines = "# Arguments\n"
    name, posargs, kwargs = info
    length(posargs) == 0 && length(kwargs) == 0 && return ""
    for args in (posargs, kwargs)
        for (name, type, var, value) in args
            if isnothing(value)
                str = "- `$name::$type`:\n"
            else
                str = "- `$name::$type=$value`:\n"
            end
            lines *= str
        end
    end
    lines * '\n'
end
function gendoc(::Struct, info)
    lines = "# Fields\n"
    name, supertypename, fields = info
    length(fields) == 0 && return ""
    for (name, type) in fields
        lines *= "- `$name::$type`:\n"
    end
    lines * '\n'
end
gendoc(::AbstractHead, info) = "\n"

# cli
Base.@ccallable function julia_main(args::Vector{String})::Cint
    if length(args) == 2
        flag, str = args
    elseif length(args) == 1
        str = args[1]
        flag = ""
    else
        error("ARGS Numbers error: $(length(args))")
    end
    print(gendoc(str, withargs = 'p' in flag))
    return 0
end
