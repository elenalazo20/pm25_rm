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

# 0) Catálogo RM -> diccionario de estaciones ------------------------------
cat_est <- AtmChile::ChileAirQuality()
req <- c("Region","Ciudad","Estacion","Latitud","Longitud")
stopifnot(all(req %in% names(cat_est)))

dicc_rm <- cat_est %>%
  filter(Region == "RM") %>%
  transmute(
    site     = Ciudad,
    estacion = Estacion,
    # OJO: en el catálogo Latitud/Longitud vienen cruzados para RM
    lon      = Latitud,   # -70.x (longitud real)
    lat      = Longitud   # -33.x (latitud real)
  ) %>% distinct() %>% arrange(estacion)

dir_create(here("output"))
write_csv(dicc_rm, here("output","diccionario_estaciones_RM.csv"))
message("Estaciones RM detectadas: ", nrow(dicc_rm))

# 1) Descarga PM2.5 horario (todas las estaciones) ------------------------
ini <- "01/01/2018"   # dd/mm/yyyy
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

  # Fuerza s_* a character (evita choque de tipos al unir)
  stat_cols <- grep("^s_", names(out), value = TRUE)
  if (length(stat_cols)) out[stat_cols] <- lapply(out[stat_cols], as.character)

  # Detecta columna PM2.5 y la fuerza a numeric
  cand_pm <- names(out)[str_detect(names(out), "(^pm\\s*2?5$|pm25|pm_2_5)")]
  stopifnot(length(cand_pm) > 0)
  pm_col <- cand_pm[1]
  out[[pm_col]] <- suppressWarnings(as.numeric(out[[pm_col]]))

  # Asegura etiqueta de estación
  if (!"estacion" %in% names(out)) out$estacion <- est
  out
}, otherwise = tibble(), quiet = TRUE)

message("Descargando PM2.5 horario para todas las estaciones de la RM…")
pm_h <- map(dicc_rm$estacion, trae_pm25) %>% bind_rows()
stopifnot(nrow(pm_h) > 0)

dir_create(here("datos_crudos"))
write_csv(pm_h, here("datos_crudos","pm25_rm_horario.csv"))
message("Guardado crudo: datos_crudos/pm25_rm_horario.csv (", nrow(pm_h), " filas)")

# 2) Limpieza mínima y dataset horario estándar ---------------------------
pm_h <- pm_h %>% clean_names()

col_fecha <- intersect(c("fecha_hora","date_time","datetime","date","fecha","fechahora"), names(pm_h))[1]
stopifnot(!is.na(col_fecha))
cand_pm   <- names(pm_h)[str_detect(names(pm_h), "(^pm\\s*2?5$|pm25|pm_2_5)")]
col_pm    <- cand_pm[1]; stopifnot(!is.na(col_pm))
col_est   <- intersect(c("estacion","station","site","ciudad","nombre_estacion"), names(pm_h))[1]
stopifnot(!is.na(col_est))

pm_h <- pm_h %>%
  transmute(
    estacion = .data[[col_est]],
    date     = parse_date_time(.data[[col_fecha]],
                               orders = c("dmy HMS","dmy HM","ymd HMS","ymd HM"),
                               tz = "America/Santiago"),
    pm25     = suppressWarnings(as.numeric(.data[[col_pm]]))
  ) %>%
  filter(!is.na(date), !is.na(pm25), pm25 >= 0, pm25 <= 500) %>%
  arrange(estacion, date)

# 3) Agregado diario y anual (calendario) ---------------------------------
pm_d <- pm_h %>%
  mutate(fecha = as.Date(date)) %>%
  group_by(estacion, fecha) %>%
  summarise(pm25_diario = mean(pm25, na.rm = TRUE), .groups = "drop")

pm_anual_est <- pm_d %>%
  mutate(anio = year(fecha)) %>%
  group_by(estacion, anio) %>%
  summarise(pm25_media = mean(pm25_diario, na.rm = TRUE),
            n_dias     = n(), .groups = "drop")

dir_create(here("datos_procesados"))
write_csv(pm_d,         here("datos_procesados","pm25_diario.csv"))
write_csv(pm_anual_est, here("datos_procesados","pm25_anual_estacion.csv"))
message("02 listo ✅ — salidas: pm25_diario.csv y pm25_anual_estacion.csv")

