BEGIN{FS="\t"}
{
  p=$1; tris=$2; users=$6
  n=split(p,a,"/"); file=a[n]; stem=file; sub(/\.glb$/,"",stem); cat=a[n-1]
  dir=p; sub(/\/[^\/]*$/,"",dir); bdir=dir; sub(/^assets\/models/,"art_source/blender",bdir)
  bs=stem; sub(/_liberado$/,"",bs); blend=bdir "/" bs ".blend"
  cmd="test -f \"" blend "\""; if (system(cmd)!=0) blend="—"
  if (p ~ /\/levels\/level_0[1-7]/) { lv=substr(p, index(p,"level_0")+7,1); lvname="N" lv } else if (p ~ /\/shared\//) { lvname="shared" } else { lvname="_unassigned" }
  est = (users!="") ? "en juego" : "laboratorio"
  uso = (users!="") ? "sí — " users : "no"
  printf("| %s | %s | `%s` | %s | `%s` | %s | %d | %s |\n", lvname, cat, stem, (blend=="—"?"—":"`" blend "`"), p, uso, tris, est)
}
