BEGIN{FS="\t";
 r["wasp_mid_poly"]="Avispa";r["wasp_enemy_visual"]="Avispa";r["controlled_hanging_spider"]="Araña colgante";r["controlled_stag_beetle"]="Escarabajo ciervo";
 r["controlled_woodland_snail"]="Caracol";r["controlled_flying_ladybird"]="Mariquita";r["controlled_flying_ladybird_lite"]="Mariquita";r["controlled_ant"]="Hormiga";r["controlled_ant_lite"]="Hormiga";
 r["controlled_mushroom_cannon"]="Hongo cañón";r["lvl01_enemy_fly_common_v01"]="Mosca común";r["lvl01_enemy_fly_common_v01_liberado"]="Mosca común (liberada)";
 r["lvl01_enemy_fly_green_v01"]="Mosca verde";r["lvl01_enemy_fly_green_v01_liberado"]="Mosca verde (liberada)";r["lvl01_enemy_fly_swarm_v01"]="Nube de moscas";r["lvl01_enemy_fly_swarm_v01_liberado"]="Nube de moscas (liberada)";
 r["lvl01_enemy_worm_rose_v01"]="Gusano A";r["lvl01_enemy_worm_rose_v01_liberado"]="Gusano A (liberado)";r["lvl01_enemy_worm_compost_v01"]="Gusano B";r["lvl01_enemy_worm_compost_v01_liberado"]="Gusano B (liberado)";
 r["lvl01_environment_mushroom_button_v01"]="Hongo de jardín";r["lvl01_environment_mushroom_spotted_v01"]="Hongo de jardín";r["lvl01_environment_mushroom_umbrella_v01"]="Hongo de jardín";
 r["lvl01_boss_giant_spider_v01"]="Tarántula (jefe)";r["lvl01_boss_giant_spider_v01_liberado"]="Tarántula (liberada)";
}
{ p=$1; tris=$2; mats=$3; white=$4; impl=$5; users=$6; haslite=$7; islite=$8
  n=split(p,a,"/"); file=a[n]; stem=file; sub(/\.glb$/,"",stem); cat=a[n-1];
  if (p ~ /\/levels\/level_0[1-7]/) { lv=substr(p, index(p,"level_0")+7,1); lvname="Nivel " lv } else if (p ~ /\/shared\//) { lvname="shared/" cat } else { lvname="_unassigned" }
  budget=""; if (cat=="enemies" || cat=="alien_tech" || (cat=="coastal" && stem ~ /^controlled_/)) { if (tris>5000 && stem !~ /kit/) budget="enemigo " tris " > 5.000" } if (cat=="bosses" && tris>12000) budget="jefe " tris " > 12.000"; if ((cat=="environment"||cat=="props") && tris>12000) budget="entorno " tris " > 12.000";
  if (stem ~ /kit/) budget="kit " tris " (referencia, no es un modelo de juego)";
  prob=""; if (white>0) prob=prob "material casi blanco (" white "); ";
  if (stem ~ /^controlled_/ && impl==0) prob=prob "sin implante separado; ";
  if (budget!="") { prob=prob "sobre presupuesto: " budget; if (haslite=="si") prob=prob " (tiene _lite)"; else if (islite=="no" && cat=="enemies") prob=prob " (sin _lite)"; prob=prob "; " }
  if (prob=="") prob="—";
  uso = (users!="") ? "sí: " users : "no (solo laboratorio)";
  ro = (stem in r) ? r[stem] : "—";
  printf("| %s | %s | %s | %s | %s | %d | %s | %s | %s |\n", lvname, cat, "`" p "`", ro, uso, tris, (islite=="si"?"es lite":(haslite=="si"?"tiene":"no")), (impl>0?"sí (" impl ")":"no"), prob);
}
