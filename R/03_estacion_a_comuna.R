# R/03_estacion_a_comuna.R -------------------------------------------------
suppressPackageStartupMessages({
  library(here);      here::i_am("R/03_estacion_a_comuna.R")
  library(fs)
  library(dplyr)
  library(readr)
  library(janitor)
  library(sf)
  library(stringi)
  library(stringr)
  library(rlang)
  library(chilemapas)   # ya instalada
})

# Rutas --------------------------------------------------------------------
ruta_dicc       <- here("output", "diccionario_estaciones_RM.csv")
ruta_poly       <- here("datos_crudos", "comunas_rm.geojson")
ruta_anual_cal  <- here("datos_procesados", "pm25_anual_estacion.csv")         # calendario
ruta_anual_24h  <- here("datos_procesados", "pm25_anual_estacion_24h.csv")     # opcional
ruta_out_cal    <- here("datos_procesados", "pm25_anual_comuna.csv")
ruta_out_24h    <- here("datos_procesados", "pm25_anual_comuna_24h.csv")

# Normalizador de nombres de comuna ---------------------------------------
norm_comuna <- function(x) {
  x |> as.character() |> toupper() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_squish()
}

# Fallback: crear comunas_rm.geojson si no existe --------------------------
if (!file_exists(ruta_poly)) {
  message("No encuentro comunas_rm.geojson. Generando desde {chilemapas}…")
  dir_create(here("datos_crudos"))
  comunas_rm <- chilemapas::mapa_comunas %>% dplyr::filter(codigo_region == 13)
  sf::st_write(comunas_rm, ruta_poly, delete_dsn = TRUE, quiet = TRUE)
  message("GeoJSON creado en datos_crudos/comunas_rm.geojson ✅")
}

# Chequeos básicos ---------------------------------------------------------
stopifnot(file_exists(ruta_dicc), file_exists(ruta_poly))
if (!file_exists(ruta_anual_cal) && !file_exists(ruta_anual_24h)) {
  stop("Faltan entradas: corre el 02 primero. No existe ni pm25_anual_estacion.csv ni pm25_anual_estacion_24h.csv")
}

# 1) Estaciones (lon/lat) -> puntos ---------------------------------------
dicc <- read_csv(
  ruta_dicc,
  col_types = cols(
    .default = col_guess(),
    estacion = col_character(),
    lon      = col_double(),
    lat      = col_double()
  ),
  show_col_types = FALSE
) %>% clean_names()

req_cols <- c("estacion","lon","lat")
if (!all(req_cols %in% names(dicc))) {
  abort(paste0("El diccionario no tiene columnas: ", paste(setdiff(req_cols, names(dicc)), collapse=", ")))
}

dicc <- dicc %>% filter(is.finite(lon), is.finite(lat))
est_sf <- st_as_sf(dicc, coords = c("lon","lat"), crs = 4326)

# 2) Comunas RM (sf) -------------------------------------------------------
comunas <- sf::read_sf(ruta_poly) %>% sf::st_make_valid()
if (is.na(sf::st_crs(comunas))) sf::st_crs(comunas) <- 4326
comunas <- sf::st_transform(comunas, 4326)

# detectar campo de nombre de comuna y normalizar
candidatos <- c("NOM_COM", "NOM_COMUNA", "Comuna", "comuna", "NOMBRE", "name")
campo <- intersect(candidatos, names(comunas))
if (length(campo) == 0) campo <- setdiff(names(comunas), attr(comunas, "sf_column"))[1]

comunas <- comunas %>%
  dplyr::rename(comuna_raw = !!sym(campo[1])) %>%
  dplyr::mutate(comuna = norm_comuna(comuna_raw)) %>%
  dplyr::select(comuna, geometry)

# 3) Join espacial estación→comuna (con rescate) ---------------------------
# punto dentro de polígono
est_join <- sf::st_join(est_sf, comunas["comuna"], join = sf::st_within)

# si alguna quedó NA (borde), asignar comuna más cercana
faltan <- which(is.na(est_join$comuna))
if (length(faltan)) {
  nearest <- sf::st_nearest_feature(est_sf[faltan,], comunas)
  est_join$comuna[faltan] <- comunas$comuna[nearest]
}
est_join <- sf::st_drop_geometry(est_join) %>% dplyr::select(estacion, comuna)

# Helper: estación→comuna con coerción de tipos ---------------------------
est_to_comuna <- function(df_est, col_media, out_path) {
  df_est <- df_est %>%
    mutate(
      anio = as.integer(anio),
      # forzar a numérico por si llegó como texto
      across(all_of(col_media), ~ suppressWarnings(readr::parse_number(as.character(.))))
    )

  stopifnot(all(c("estacion","anio", col_media) %in% names(df_est)))

  out <- df_est %>%
    left_join(est_join, by = "estacion") %>%
    group_by(comuna, anio) %>%
    summarise(!!col_media := mean(.data[[col_media]], na.rm = TRUE), .groups = "drop") %>%
    arrange(comuna, anio)

  fs::dir_create(fs::path_dir(out_path))
  readr::write_csv(out, out_path)
  out
}

# 4) Versión calendario ----------------------------------------------------
if (file_exists(ruta_anual_cal)) {
  anual_est <- readr::read_csv(
    ruta_anual_cal,
    col_types = readr::cols(
      estacion   = readr::col_character(),
      anio       = readr::col_integer(),
      pm25_media = readr::col_double()
    ),
    show_col_types = FALSE
  ) %>% janitor::clean_names()

  stopifnot(all(c("estacion","anio","pm25_media") %in% names(anual_est)))

  anual_comuna_cal <- est_to_comuna(anual_est, "pm25_media", ruta_out_cal)

  msg_cal <- anual_comuna_cal %>%
    summarise(a = paste(sort(unique(anio)), collapse=", "),
              n = dplyr::n_distinct(comuna)) %>% as.list()

  message("03 (calendario) listo: pm25_anual_comuna.csv — años: ",
          msg_cal$a, " | comunas: ", msg_cal$n)
}

# 5) Versión 24 h (opcional) ----------------------------------------------
if (file_exists(ruta_anual_24h)) {
  anual_est_24 <- readr::read_csv(
    ruta_anual_24h,
    col_types = readr::cols(
      estacion        = readr::col_character(),
      anio            = readr::col_integer(),
      pm25_media_24h  = readr::col_double()
    ),
    show_col_types = FALSE
  ) %>% janitor::clean_names()

  stopifnot(all(c("estacion","anio","pm25_media_24h") %in% names(anual_est_24)))

  anual_comuna_24 <- est_to_comuna(anual_est_24, "pm25_media_24h", ruta_out_24h)

  msg_24 <- anual_comuna_24 %>%
    summarise(a = paste(sort(unique(anio)), collapse=", "),
              n = dplyr::n_distinct(comuna)) %>% as.list()

  message("03 (24h) listo: pm25_anual_comuna_24h.csv — años: ",
          msg_24$a, " | comunas: ", msg_24$n)
}

message("03 COMPLETADO ✅")
