push!(LOAD_PATH,"..")
using Pkg; Pkg.instantiate()
using Documenter, LTspice

# Build docs.
# ===========


const PAGES = [
  "Home" => "index.md",
  "Installation" => "install.md",
  "Quickstart" => "quickstart.md",
  "Examples" => "examples.md",
  "Public API" => "public_api.md",
  "Contents" => "contents.md",
]

makedocs(
  modules = [LTspice],
  clean = true,
  doctest   = "doctest" in ARGS,
  linkcheck = "linkcheck" in ARGS,
  format    = "pdf" in ARGS ? :latex : :html,
  build = "site",
  sitename = "LTspice",
  authors = "Chris Stook",
  pages = PAGES,
  html_prettyurls = "deploy" in ARGS,
)

if "deploy" in ARGS
  fake_travis = "C:/Users/Chris/fake_travis_LTspice.jl"
  if isfile(fake_travis)
    include(fake_travis)
  end
  deploydocs(
    repo = "github.com/cstook/LTspice.jl.git",
    target = "site",
    branch = "gh-pages",
    latest = "master",
    osname = "linux",
    julia  = "0.7",
    deps = nothing,
    make = nothing,
  )
end
