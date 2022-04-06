@def title = "Preferences"
@def hascode = true

# Preferences

Since Julia 1.6 [`Preferences.jl`](https://github.com/JuliaPackaging/Preferences.jl)
allows packages to declare options/preferences that the user can set on a per project
level.

Preferences are read and written from Julia with the Preferences.jl package.

```julia
module MyPackage

using Preferences

const favorite_icecream = @load_preference("icecream", "vanilla")

function change_mind!(flavor)
    @set_preferences!("icecream"=>flavor)
end

end
```
When a preference is set it is stored in a file called `LocalPreferences.toml`
next to your current `Project.toml`.

#### LocalPreferences.toml

```toml
[MyPackage]
icecream = "chocolate"
```

Note how the `LocalPreferences.toml` is scoped by package name, and thus each
package has it's own namespace.

## Setting preferences of dependencies

A common use-case of preferences is to configure the library path of libraries
provided through `_jll` packages.

As an example let's add `UCX.jl` as a dependency to a package.

```sh
> cat Project.toml
[deps]
Preferences = "21216c6a-2e73-6563-6e65-726566657250"
UCX = "6b349878-927d-5bd5-ab28-bc3aa4175a33"
```

and we can see that it currently uses the `libucp.so` from `UCX_jll`.

```julia-repl
julia> using UCX
julia> UCX.API.libucp
/home/vchuravy/.julia/artifacts/33301dce3561b1e57216ae5a4fc16d847e066a1d/lib/libucp.so
```

Now if I want to change the library used we have two options. Firstly the manual
one where we directly manipulate the `LocalPreferences.toml`, and secondly using
Prefrences `set_preference(UCX.UCX_jll, "libucp_path"=>"...")`.

### Manual approach

The `LocalPreferences.toml` we create next to our `Project.toml` will look like:

```sh
> cat LocalPreferences.toml
[UCX_jll]
libucp_path="/home/vchuravy/builds/ucx/lib/libucp.so"
```

Running the same commands as before:

```julia-repl
julia> using UCX
julia> UCX.API.libucp
/home/vchuravy/.julia/artifacts/33301dce3561b1e57216ae5a4fc16d847e066a1d/lib/libucp.so
```

We see that nothing has changed. Why? Julia internally referers to packages by UUIDs
so if you take another look at the `Project.toml` you can see that in `[deps]` we
declare a mapping from name to UUID, and the `LocalPreferences.toml` needs exactly
this mapping to know what package owns the namespace. We could add `UCX_jll` to our
`[deps]` section in our package but that would unecessarily polute our dependency set.
Instead the right solution is to add `UCX_jll` to the `[extras]` section.

```sh
> cat Project.toml
[deps]
Preferences = "21216c6a-2e73-6563-6e65-726566657250"
UCX = "6b349878-927d-5bd5-ab28-bc3aa4175a33"

[extras]
UCX_jll = "16e4e860-d6b8-5056-a518-93e88b6392ae"
```

Loading UCX now delightfully fails since of course we haven't done the work of placing
a library in that location.

```julia-repl
julia> using UCX
ERROR: InitError: could not load library "/home/vchuravy/builds/ucx/lib/libucp.so"
/home/vchuravy/builds/ucx/lib/libucp.so: cannot open shared object file: No such file or directory
```

Keep this in mind if you are ever wondering why settings in `LocalPreferences.toml`
don't seem to take effect.

### The "proper" way

Let's reset our environment to the state it was before:

```sh
> cat Project.toml
[deps]
Preferences = "21216c6a-2e73-6563-6e65-726566657250"
UCX = "6b349878-927d-5bd5-ab28-bc3aa4175a33"
```

```julia-repl
julia> using UCX
julia> @eval UCX using UCX_jll
julia> using Preferences
julia> set_preferences!(UCX.UCX_jll, "libucp_path" => "/home/vchuravy/builds/ucx/lib/libucp.so")
julia> UCX.UCX_jll.libucp_path
"/home/vchuravy/.julia/artifacts/33301dce3561b1e57216ae5a4fc16d847e066a1d/lib/libucp.so"
```

As we can see the preference has not yet taken effect, and it will require a
restart of Julia. This is because the preference lookup is cached during package
precompilation.

Inspecting our `Project.toml` and `LocalPreferences.toml` we see that `Preferences.jl`
automatically added `UCX_jll` to the `[extras]` section.

```sh
> cat Project.toml
[deps]
Preferences = "21216c6a-2e73-6563-6e65-726566657250"
UCX = "6b349878-927d-5bd5-ab28-bc3aa4175a33"

[extras]
UCX_jll = "16e4e860-d6b8-5056-a518-93e88b6392ae"
```

```sh
> cat example/LocalPreferences.toml
[UCX_jll]
libucp_path = "/home/vchuravy/builds/ucx/lib/libucp.so"
```

After restarting we see the expected behavior.

```julia-repl
julia> using UCX
ERROR: InitError: could not load library "/home/vchuravy/builds/ucx/lib/libucp.so"
/home/vchuravy/builds/ucx/lib/libucp.so: cannot open shared object file: No such file or directory
```

## Interactions with the `JULIA_LOAD_PATH`

Preferences are merged across the entire `JULIA_LOAD_PATH` to illustrate this
let's create a new directory `preferences` and mv over our current `LocalPreferences.toml`.

```sh
mkdir preferences
mv example/LocalPreferences.toml preferences/
printf "[extras]\nUCX_jll = \"16e4e860-d6b8-5056-a518-93e88b6392ae\"" > preferences/Project.toml
```

and remove `UCX_jll` from `Project.toml` in the current directory.

```sh
> JULIA_LOAD_PATH="@:./preferences" julia --project=.
julia> using UCX
ERROR: InitError: could not load library "/home/vchuravy/builds/ucx/lib/libucp.so"
```
