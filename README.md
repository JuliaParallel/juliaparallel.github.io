# https://juliaparallel.org

## For contributors

Clone the repository and `cd` to the new directory. Edit the files as you need.  To test the
website locally, start julia with `julia --project` and do

```julia
julia> import Pkg

julia> Pkg.instantiate()

julia> import Xranklin

julia> Xranklin.serve()
  Activating project at `~/repo/juliaparallel.github.io`
[ Info: 📓 de-serializing global context...
[ Info: ⌛ processing config.md
[ Info: ... [config.md] ✔ (δt = 2.1s)
[ Info: 📓 de-serializing 0 local contexts...
[ Info: 💡 de-serialization done (δt = 2.7s)

[ Info: 💡 starting the full pass

[ Info: > Full Pass [MD/1]
[ Info: > Full Pass [MD/I]
[ Info: > Full Pass [MD/2]
[ Info: > Full Pass [O]
[ Info: 🧵 loop (n=1) over 121 items

[ Info: 💡 full pass done (δt = 5.9s)

[ Info: Listening on: 127.0.0.1:8000
✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

Navigate to `localhost:8000` in a browser and you should see a preview of any modifications
you make locally.
