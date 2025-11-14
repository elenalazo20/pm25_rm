# R/02_descarga_limpieza.R -------------------------------------------------
suppressPackageStartupMessages({
  library(here);      here::i_am("R/02_descarga_limpieza.R")
  library(fs)
  library(dplyr)
  library(readr)
  library(purrr)
  library(lubridate)
  library(janitor)
  library(stringr)
  library(AtmChile)
})

options(readr.show_col_types = FALSE, dplyr.summarise.inform = FALSE)

# ------------------ 0) Catálogo RM y diccionario de estaciones -----------
suppressPackageStartupMessages({
  library(AtmChile); library(dplyr); library(readr); library(janitor)
  library(stringr);  library(here);   library(fs)
})

to_num <- function(x) {
  if (is.numeric(x)) return(x)
  x <- as.character(x)
  # admite coma o punto decimal
  if (any(grepl(",\\d+$", x))) {
    readr::parse_number(x, locale = readr::locale(decimal_mark = ",", grouping_mark = "."))
  } else {
    readr::parse_number(x, locale = readr::locale(decimal_mark = ".", grouping_mark = ","))
  }
}

# Catálogo general (metadatos)
cat_est <- AtmChile::ChileAirQuality() %>% janitor::clean_names()

# Filtrar RM (tolerante a nombres de columna)
if ("codigo_region" %in% names(cat_est)) {
  cat_rm <- dplyr::filter(cat_est, codigo_region == 13)
} else if ("region" %in% names(cat_est)) {
  cat_rm <- dplyr::filter(cat_est, region %in% c("RM", "Metropolitana", "Región Metropolitana"))
} else {
  stop("No encuentro columna de región en el catálogo de AtmChile.")
}

# Elegir columna de nombre de estación (tolerante)
est_col <- intersect(c("estacion","ciudad","site","nombre_estacion","estacion_nombre"), names(cat_rm))
stopifnot(length(est_col) >= 1)

# Candidatas a lon/lat en el catálogo
lon_cand <- intersect(c("lon","longitud","longitude","x"), names(cat_rm))
lat_cand <- intersect(c("lat","latitud","latitude","y"), names(cat_rm))

# Si no aparecen lon/lat explícitas, usar el par latitud/longitud (algunos catálogos vienen cruzados)
if (length(lon_cand) == 0 && all(c("latitud","longitud") %in% names(cat_rm))) {
  lon_cand <- "latitud"
  lat_cand <- "longitud"
}

stopifnot(length(lon_cand) >= 1, length(lat_cand) >= 1)

dicc_rm_raw <- cat_rm %>%
  transmute(
    estacion_raw = .data[[est_col[1]]],
    lon_raw      = to_num(.data[[lon_cand[1]]]),
    lat_raw      = to_num(.data[[lat_cand[1]]])
  ) %>%
  filter(is.finite(lon_raw), is.finite(lat_raw))

# Heurística para detectar cruce lat/lon y corregir a lon/lat válidos de la RM
# RM esperada: lon ~ [-75, -69], lat ~ [-34.5, -32]
med_lon <- median(dicc_rm_raw$lon_raw, na.rm = TRUE)
med_lat <- median(dicc_rm_raw$lat_raw, na.rm = TRUE)

swap <- (abs(med_lon) < 65) || (abs(med_lat) > 65) || (med_lon > -60) || (med_lon < -90)
if (swap) {
  tmp <- dicc_rm_raw$lon_raw
  dicc_rm_raw$lon_raw <- dicc_rm_raw$lat_raw
  dicc_rm_raw$lat_raw <- tmp
}

dicc_rm <- dicc_rm_raw %>%
  transmute(
    estacion = as.character(estacion_raw),
    lon = lon_raw,
    lat = lat_raw
  ) %>%
  distinct(estacion, lon, lat) %>%
  arrange(estacion)

# Validaciones de rango (básicas para RM)
stopifnot(all(dicc_rm$lon < -60 & dicc_rm$lon > -80),
          all(dicc_rm$lat < -30 & dicc_rm$lat > -40))

fs::dir_create(here("output"))
readr::write_csv(dicc_rm, here("output","diccionario_estaciones_RM.csv"))
message("Diccionario RM creado: output/diccionario_estaciones_RM.csv  (cols: estacion, lon, lat)")
