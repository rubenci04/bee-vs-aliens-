# Poderes de polen

Un cartucho cuesta 7 granos. `scripts/game/bee_pollen_powers.gd` enumera los efectos que se aplican con Q o LT: cura 25, escudo 2,5 s y disparo doble 4 s. El disparo doble suma tiempo al gastar más cartuchos, hasta 12 s. Entre pulsaciones hay solo 0,25 s de espera para poder encadenarlas. Cada bala conserva el daño de la bala correspondiente del arma activa, incluido Spread. El polen no altera la recarga de las armas.

Para sumar un poder, agregá un diccionario con `id` y parámetros a `POWERS`, implementá ese `id` en `apply()` y agregá su temporizador o estado al dueño adecuado. Sumá su aviso en `bee_hud_notices.gd`, su indicador en el HUD si dura en el tiempo, y una prueba de consumo, duración y tope. Para un arma nueva, su perfil va en `bee_shooting_settings.gd`: el doble copia cada bala creada, su dirección y su daño.
