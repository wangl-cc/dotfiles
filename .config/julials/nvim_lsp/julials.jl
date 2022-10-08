pushfirst!(LOAD_PATH, @__DIR__)
using LanguageServer
popfirst!(LOAD_PATH)
project_path = dirname(something(
    # current activated project, false to avoid search LOAD_PATH
    Base.active_project(false),
    # look Project.toml in the current working directory,
    # or parent directories, with $HOME as an upper boundary
    Base.current_project(),
    # current actived project, but search LOAD_PATH
    Base.active_project(),
    # use julia's default project
    ""
))
depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
symserver_store_path = joinpath(homedir(), ".config", "julials", "symbolstore")
isdir(symserver_store_path) || mkpath(symserver_store_path)
server = LanguageServer.LanguageServerInstance(
    stdin, stdout, project_path, depot_path, nothing, symserver_store_path, false
)
run(server)
