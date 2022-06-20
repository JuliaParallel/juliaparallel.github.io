<!--
Add here global page variables to use throughout your website.
-->
+++

author = "JuliaParallel"
mintoclevel = 2

# Author badges
using DelimitedFiles
author_badges_mat = readdlm("_assets/author-badges.dat", ':')
author_badges = Dict()
[author_badges[author_badges_mat[i]] = rstrip.(lstrip.(split(author_badges_mat[i,2], ",")))
 for i in 1:size(author_badges_mat,1) ]

+++
