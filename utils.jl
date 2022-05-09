function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

"""
    {{news}}

Plug in the list of news contained in the `/news/` folder.
"""
function hfun_news()
    author_badges = globvar("author_badges")

    # Changing page width in "News" section 
    io = IOBuffer()
    write(io, """<style>
                    @media (min-width: 1024px) {
                      .franklin-content {
                         width: 100%;
                         padding-left: 0%;
                         padding-right: 0%;
                      }
                    }
                 </style>""")
    
    # Add news
    curyear = year(Dates.today())
    write(io, """<div class="news-container">""")
    for year in curyear:-1:2022
        ys = "$year"
        year < curyear && write(io, "\n**$year**\n")
        for month in 12:-1:1
            ms = "0"^(month < 10) * "$month"
            base = joinpath("news", ys, ms)
            isdir(base) || continue
            posts = filter!(p -> endswith(p, ".md"), readdir(base))
            days  = zeros(Int, length(posts))
            lines = Vector{String}(undef, length(posts))
            for (i, post) in enumerate(posts)
                ps  = splitext(post)[1]
                url = "/news/$ys/$ms/$ps/"
                surl = strip(url, '/')
                title = pagevar(surl, :title)
                short_descr = pagevar(surl, :short_descr)
                author = pagevar(surl, :author)
                width = rand(250:290)
                pubdate = pagevar(surl, :published)
                if isnothing(pubdate)
                    date    = "$ys-$ms-01"
                    days[i] = 1
                else
                    date    = Date(pubdate, dateformat"d U Y")
                    days[i] = day(date)
                end
                lines[i] = """"""
                lines[i] *= """<div class="news-block" style="width:$(width)px;margin:-5px;">"""
                lines[i] *= """<a href="$url">$title</a> $date<br>"""
                lines[i] *= """<p>$short_descr</p>"""
                lines[i] *= """$author"""
                for b in author_badges[author]
                      lines[i] *= """<img src="/assets/$b.png"/>"""
                end
                lines[i] *= """</div>"""
            end
            # sort by day
            foreach(line -> write(io, line), lines[sortperm(days, rev=true)])
        end
    end
    write(io, """</div>""")
    return String(take!(io))
end


"""
    {{ addcomments }}

Add a comment widget, managed by utterances <https://utteranc.es>.
"""
function hfun_addcomments()
    html_str = """
        <script src="https://utteranc.es/client.js"
            repo="JuliaParallel/juliaparallel.github.io"
            issue-term="pathname"
            theme="github-light"
            crossorigin="anonymous"
            async>
        </script>
    """
    return html_str
end
