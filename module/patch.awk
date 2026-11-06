# Transform only known Samsung stage effect assignment fields.
# No vendor file is distributed; caller must discard output on any nonzero exit.
function fail(s) { print "unsupported input at line " NR ": " s > "/dev/stderr"; bad=1; exit 2 }
BEGIN {
 n=split("DOLBY DOLBY_GAME DOLBY_SPATIALIZER DOLBY_PROXY SOUNDALIVE_PLUS SOUNDALIVE_PLUS_PROXY ADAPTSOUND ADAPTSOUND_PROXY",names," ")
 for(i=1;i<=n;i++) drop["STAGE_EFFECT_" names[i]]=1
 depth=0; removed=0; bad=0
}
{
 raw=$0; code=raw; sub(/[ \t]*(#|\/\/).*$/, "", code)
 if(code ~ /[{}]/) {
  if(code ~ /^[ \t]*[A-Za-z0-9_.-]+[ \t]+\{[ \t]*$/) depth++
  else if(code ~ /^[ \t]*}[ \t]*$/) { depth--; if(depth<0) fail("unmatched brace") }
  else fail("unsupported block syntax")
 }
 if(match(code,/^[ \t]*(prefx|postfx|integ-pre|integ-post)[ \t]+/)) {
  if(depth<1) fail("effect outside block")
  lead=substr(raw,1,RLENGTH); tail=substr(raw,RLENGTH+1)
  value=tail; sub(/[ \t].*$/, "",value)
  suffix=substr(tail,length(value)+1)
  if(suffix !~ /^[ \t]*((#|\/\/).*)?$/) fail("unexpected assignment suffix")
  if(value !~ /^STAGE_EFFECT_[A-Z0-9_]+(:lazy)?(\|STAGE_EFFECT_[A-Z0-9_]+(:lazy)?)*$/) fail("unsupported effect expression")
  count=split(value,items,"|"); result=""; changed=0
  for(i=1;i<=count;i++) {
   base=items[i]; sub(/:lazy$/, "",base)
   if(base in drop) { removed++; changed=1 }
   else result=result (result==""?"":"|") items[i]
  }
  if(changed) { if(result=="") result="STAGE_EFFECT_NONE"; raw=lead result suffix }
 }
 print raw
}
END {
 if(bad) exit 2
 if(depth!=0) { print "unsupported input: unbalanced braces" > "/dev/stderr"; exit 2 }
 print "removed effect references: " removed > "/dev/stderr"
}
