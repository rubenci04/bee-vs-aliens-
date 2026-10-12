#!/bin/bash
# usage: move_assets.sh <mapfile> [--reverse]
# Map lines: batch/stem|dest|newstem  (dest relative to assets/models and art_source/blender). Moves glb(+.import) and blend,
# git mv for tracked files, mv for untracked, then rewrites every textual reference (old path -> new path).
cd /d/proyectos/bee_alien_3d
MAP=$1; REV=$2
PAIRS=dev/lote12/_pairs.tsv
if [[ "$MAP" == *.tsv ]]; then cp "$MAP" $PAIRS; else
: > $PAIRS
while IFS='|' read -r src dest new; do
  [[ -z "$src" || "$src" == \#* ]] && continue
  batch=${src%%/*}; stem=${src#*/}; [ -z "$new" ] && new=$stem
  for kind in "assets/models|glb" "art_source/blender|blend"; do
    root=${kind%%|*}; ext=${kind##*|}
    from="$root/$batch/$stem.$ext"; to="$root/$dest/$new.$ext"
    [ "$REV" = "--reverse" ] && { t=$from; from=$to; to=$t; }
    if [ -f "$from" ]; then
      printf '%s\t%s\n' "$from" "$to" >> $PAIRS
      [ "$ext" = glb ] && [ -f "$from.import" ] && printf '%s\t%s\n' "$from.import" "$to.import" >> $PAIRS
    fi
  done
done < "$MAP"
fi
while IFS=$'\t' read -r from to; do
  mkdir -p "$(dirname "$to")"
  if git ls-files --error-unmatch "$from" > /dev/null 2>&1; then git mv "$from" "$to"; else mv "$from" "$to"; fi
done < $PAIRS
# .gdignore for blend destinations
for d in $(awk -F'\t' '$2 ~ /^art_source\// {print $2}' $PAIRS | xargs -n1 dirname | sort -u); do [ -f "$d/.gdignore" ] || : > "$d/.gdignore"; done
# reference rewrite (glb/blend base paths only; the .import entries are covered as prefixes)
awk -F'\t' '$1 !~ /\.import$/' $PAIRS > dev/lote12/_replace.tsv
{ git ls-files; git ls-files -o --exclude-standard; } | sort -u | grep -E '\.(tscn|tres|gd|json|md|py|cfg|import|godot|gdshader|txt)$' | grep -v -E '^(dev/|addons/|\.godot/|docs/INFORME_)' > dev/lote12/_candidates.txt
perl -e '
open(M,"<","dev/lote12/_replace.tsv"); my %m; while(<M>){chomp; my($a,$b)=split(/\t/); $m{$a}=$b;} close M;
my $re=join("|", map {quotemeta} sort {length($b)<=>length($a)} keys %m); $re=qr/($re)/;
open(C,"<","dev/lote12/_candidates.txt"); my $n=0;
while(my $f=<C>){ chomp $f; next unless -f $f; open(F,"<:raw",$f); local $/; my $t=<F>; close F;
  my $c = ($t =~ s/$re/$m{$1}/g); if($c){ open(O,">:raw",$f); print O $t; close O; $n++; print "  rewrote $f ($c)\n"; } }
print "files rewritten: $n\n";' | tail -400 > dev/lote12/last_rewrite.log
tail -1 dev/lote12/last_rewrite.log
echo "moved $(wc -l < $PAIRS) files"
