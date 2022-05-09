using DelimitedFiles

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
    # Author badges
    author_badges_mat = readdlm("_assets/author-badges.dat", ':')
    author_badges = Dict()
    for i = 1:size(author_badges_mat,1)
       author_badges[author_badges_mat[i]] =
        rstrip.(lstrip.(split(author_badges_mat[i,2], ",")))
    end
    
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
    {{recentnews}}

Input the 3 latest news posts.
"""
function hfun_recentnews()
    curyear = Dates.Year(Dates.today()).value
    ntofind = 12
    nfound  = 0
    recent  = Vector{Pair{String,Date}}(undef, ntofind)
    for year in curyear:-1:2019
        for month in 12:-1:1
            ms = "0"^(1-div(month, 10)) * "$month"
            base = joinpath("news", "$year", "$ms")
            isdir(base) || continue
            posts = filter!(p -> endswith(p, ".md"), readdir(base))
            days  = zeros(Int, length(posts))
            surls = Vector{String}(undef, length(posts))
            for (i, post) in enumerate(posts)
                ps       = splitext(post)[1]
                surl     = "news/$year/$ms/$ps"
                surls[i] = surl
                pubdate  = pagevar(surl, :published)
                days[i]  = isnothing(pubdate) ?
                                1 : day(Date(pubdate, dateformat"d U Y"))
            end
            # go over month post in antichronological orders
            sp = sortperm(days, rev=true)
            for (i, surl) in enumerate(surls[sp])
                recent[nfound + 1] = (surl => Date(year, month, days[sp[i]]))
                nfound += 1
                nfound == ntofind && break
            end
            nfound == ntofind && break
        end
        nfound == ntofind && break
    end
    resize!(recent, nfound)
    io = IOBuffer()
    for (surl, date) in recent
        url   = "/$surl/"
        title = pagevar(surl, :title)
        title === nothing && (title = "Untitled")
        sdate = "$(day(date)) $(monthname(date)) $(year(date))"
        blurb = pagevar(surl, :rss)
        short_descr = pagevar(surl, :short_descr)
        width = pagevar(surl, :width)
        #write(io, """
        #    <div class="col-lg-4 col-md-12 blog">
        #      <h3><a href="$url" class="title" data-proofer-ignore>$title</a>
        #      </h3><span class="article-date">$date</span>
        #      <p>$blurb</p>
        #    </div>
        #    """)
        write(io, """
            <a href="$url">
              <div style="width:$(width)px;font-family: nyt-cheltenham,georgia,'times new roman',times,serif;color:#5A5A5A;"">
              <h4 >
              $title</h3>
              <span style="font-size:15px;">$date</span>
              <p style="font-family: nyt-cheltenham,georgia,'times new roman',times,serif;font-size:15px;color:#5A5A5A;">
              $short_descr</p>
              </div>
            </a>
            """)
    end
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
