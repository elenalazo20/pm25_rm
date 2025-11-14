# R/02_descarga_limpieza.R -------------------------------------------------
suppressPackageStartupMessages({
  library(here);    here::i_am("R/02_descarga_limpieza.R")
  library(dplyr);   library(readr);   library(purrr)
  library(lubridate); library(janitor); library(fs); library(stringr)
  library(sf)
  library(AtmChile)
})

options(readr.show_col_types = FALSE, dplyr.summarise.inform = FALSE)

# ------------ helpers ------------
info <- function(...) cat("[INFO]", sprintf(...), "\n")
stop_if_empty <- function(df, msg) if (nrow(df) == 0) stop(msg, call. = FALSE)
parse_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- as.character(x)
  y <- readr::parse_number(x, locale = readr::locale(decimal_mark = ".", grouping_mark = ","))
  if (all(is.na(y))) {
    y <- readr::parse_number(x, locale = readr::locale(decimal_mark = ",", grouping_mark = "."))
  }
  y
}

# ------------ 0) Catálogo RM + diccionario robusto (lon/lat) ------------
cat_est <- AtmChile::ChileAirQuality()
stopifnot(all(c("Region","Ciudad","Estacion","Latitud","Longitud") %in% names(cat_est)))

dicc_rm <- cat_est %>%
  filter(Region == "RM") %>%
  transmute(
    estacion = Estacion,
    lon = parse_num(Longitud),
    lat = parse_num(Latitud)
  )

# bbox de la RM para detectar lon/lat cruzados (robusto)
if (!requireNamespace("chilemapas", quietly = TRUE)) install.packages("chilemapas")
rm_geo_bbox <- {
  g <- chilemapas::mapa_comunas %>% dplyr::filter(codigo_region == 13)
  if (!inherits(g, "sf")) g <- sf::st_as_sf(g)
  crs_g <- sf::st_crs(g)
  if (!is.na(crs_g) && (is.na(crs_g$epsg) || crs_g$epsg != 4326)) {
    g <- sf::st_transform(g, 4326)
  }
  sf::st_bbox(g)
}

inside_current <- with(dicc_rm, lon >= rm_geo_bbox["xmin"] & lon <= rm_geo_bbox["xmax"] &
                         lat >= rm_geo_bbox["ymin"] & lat <= rm_geo_bbox["ymax"])
inside_swapped <- with(dicc_rm, lat >= rm_geo_bbox["xmin"] & lat <= rm_geo_bbox["xmax"] &
                         lon >= rm_geo_bbox["ymin"] & lon <= rm_geo_bbox["ymax"])

if (sum(inside_swapped, na.rm = TRUE) > sum(inside_current, na.rm = TRUE)) {
  dicc_rm <- dicc_rm %>% mutate(tmp = lon, lon = lat, lat = tmp, tmp = NULL)
  info("Diccionario: detectado lon/lat cruzados → corregido.")
}

dicc_rm <- dicc_rm %>%
  filter(is.finite(lon), is.finite(lat)) %>%
  distinct(estacion, .keep_all = TRUE) %>%
  arrange(estacion)

dir_create(here("output"))
write_csv(dicc_rm %>% select(estacion, lon, lat),
          here("output","diccionario_estaciones_RM.csv"))
info("Diccionario RM guardado: %s (n=%d)", here("output","diccionario_estaciones_RM.csv"), nrow(dicc_rm))

# ------------ 1) Descarga PM2.5 horario (todas las estaciones) ------------
ini <- "01/01/2018"  # dd/mm/yyyy
fin <- "31/12/2024"

trae_pm25 <- purrr::possibly(function(est){
  out <- AtmChile::ChileAirQuality(
    Comunas        = est,
    Parametros     = "PM25",
    fechadeInicio  = ini,
    fechadeTermino = fin,
    Curar          = TRUE,
    st             = TRUE
  )
  out <- janitor::clean_names(out)

  # Fuerza status s_* a character (evita choques al unir)
  stat_cols <- grep("^s_", names(out), value = TRUE)
  if (length(stat_cols)) out[stat_cols] <- lapply(out[stat_cols], as.character)

  # Detecta columna PM y la hace numérica
  pm_col <- names(out)[stringr::str_detect(names(out), "(^pm2?5$|pm25)")][1]
  out[[pm_col]] <- suppressWarnings(as.numeric(out[[pm_col]]))

  out$estacion <- est
  out
}, otherwise = tibble(), quiet = TRUE)

info("Descargando PM2.5 horario para estaciones de la RM…")
pm_h_list <- purrr::map(dicc_rm$estacion, trae_pm25)
pm_h <- dplyr::bind_rows(pm_h_list)
stop_if_empty(pm_h, "Descarga vacía: no se obtuvieron datos horarios.")

# ------------ 2) Limpieza mínima y agregado diario/anual -----------------
pm_h <- pm_h %>% clean_names()

# Detecta columnas clave (tolerante)
col_fecha <- intersect(c("fecha_hora","date","datetime","fecha"), names(pm_h))[1]
stopifnot(!is.na(col_fecha))
col_pm <- names(pm_h)[str_detect(names(pm_h), regex("^pm\\s*2?5$", ignore_case = TRUE))][1]
if (is.na(col_pm)) col_pm <- names(pm_h)[str_detect(names(pm_h), regex("pm25", ignore_case = TRUE))][1]
stopifnot(!is.na(col_pm))
col_est <- intersect(c("estacion","station","site","ciudad","nombre_estacion"), names(pm_h))[1]
stopifnot(!is.na(col_est))

pm_h <- pm_h %>%
  transmute(
    estacion = .data[[col_est]],
    date     = parse_date_time(.data[[col_fecha]],
                               orders = c("dmy HMS","dmy HM","ymd HMS","ymd HM","dmy","ymd"),
                               tz = "America/Santiago"),
    pm25     = suppressWarnings(as.numeric(.data[[col_pm]]))
  ) %>%
  filter(!is.na(date), !is.na(pm25), pm25 >= 0, pm25 <= 500)

stop_if_empty(pm_h, "Tras limpieza, no quedan datos horarios válidos.")

# Agregado diario por estación
pm_d <- pm_h %>%
  mutate(fecha = as_date(date)) %>%
  group_by(estacion, fecha) %>%
  summarise(pm25_diario = mean(pm25, na.rm = TRUE), .groups = "drop")

stop_if_empty(pm_d, "Agregado diario vacío.")

# Agregado anual por estación
pm_anual_est <- pm_d %>%
  mutate(anio = year(fecha)) %>%
  group_by(estacion, anio) %>%
  summarise(pm25_media = mean(pm25_diario, na.rm = TRUE),
            n_dias     = n(),
            .groups    = "drop") %>%
  mutate(
    anio       = as.integer(anio),
    pm25_media = as.numeric(pm25_media)
  ) %>%
  filter(is.finite(pm25_media), n_dias > 0)

stop_if_empty(pm_anual_est, "Agregado anual por estación vacío.")

# Guardar salidas
dir_create(here("datos_crudos"))
dir_create(here("datos_procesados"))

write_csv(pm_h,          here("datos_crudos","pm25_rm_horario.csv"))
info("Guardado crudo: %s (n=%d)", here("datos_crudos","pm25_rm_horario.csv"), nrow(pm_h))

write_csv(pm_d,          here("datos_procesados","pm25_diario.csv"))
write_csv(pm_anual_est,  here("datos_procesados","pm25_anual_estacion.csv"))
info("Guardado (calendario): pm25_diario.csv (n=%d días) y pm25_anual_estacion.csv (n=%d filas)",
     nrow(pm_d), nrow(pm_anual_est))

