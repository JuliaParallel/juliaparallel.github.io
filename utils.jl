using Dates

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
        year < curyear
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
                post_title = pagevar(surl, :post_title)
                short_descr = pagevar(surl, :short_descr)
                post_author = pagevar(surl, :post_author)
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
                lines[i] *= """<a href="$url">$post_title</a> $date<br>"""
                lines[i] *= """<p>$short_descr</p>"""
                lines[i] *= """$post_author"""
                for b in author_badges[post_author]
                      lines[i] *= """<img src="/assets/$b.png"/>"""
                end
                lines[i] *= """</div>"""
            end
            # sort by day
            foreach(line -> write(io, line), lines[sortperm(days, rev=false)])
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
