<!--
Add here global page variables to use throughout your website.
-->
+++
author = "JuliaParallel"
mintoclevel = 2

# Add here files or directories that should be ignored by Franklin, otherwise
# these files might be copied and, if markdown, processed by Franklin which
# you might not want. Indicate directories by ending the name with a `/`.
# Base files such as LICENSE.md and README.md are ignored by default.
ignore = ["node_modules/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "JuliaParallel"
website_descr = "JuliaParallel"
website_url   = "https://juliaparallel.org/"

# Author badges
using DelimitedFiles
author_badges_mat = readdlm("_assets/author-badges.dat", ':')
author_badges = Dict()
for i = 1:size(author_badges_mat,1)
   author_badges[author_badges_mat[i]] =
    rstrip.(lstrip.(split(author_badges_mat[i,2], ",")))
end

+++

<!--
Add here global latex commands to use throughout your pages.
-->
\newcommand{\R}{\mathbb R}
\newcommand{\scal}[1]{\langle #1 \rangle}
