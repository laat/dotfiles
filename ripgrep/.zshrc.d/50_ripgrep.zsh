# completealiases is set, so the ag alias needs its own completion mapping.
# Only map when rg's own completion (_rg) was picked up by compinit.
(( ${+_comps[rg]} )) && compdef ag=rg
