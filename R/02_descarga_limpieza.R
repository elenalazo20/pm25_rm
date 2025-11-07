# R/02_descarga_limpieza.R -------------------------------------------------
suppressPackageStartupMessages({
  library(here); here::i_am("R/02_descarga_limpieza.R")
  library(dplyr); library(readr); library(purrr)
  library(lubridate); library(janitor); library(fs); library(stringr)
  library(AtmChile)
})

options(readr.show_col_types = FALSE, dplyr.summarise.inform = FALSE)


# 0) Catálogo RM y diccionario de estaciones ------------------------------
cat_est <- AtmChile::ChileAirQuality()  # catálogo general (metadatos)
stopifnot(all(c("Region","Ciudad","Estacion","Latitud","Longitud") %in% names(cat_est)))

dicc_rm <- cat_est %>%
  filter(Region == "RM") %>%
  transmute(
    site     = Ciudad,
    estacion = Estacion,
    # ¡OJO! En el catálogo algunos campos vienen cruzados:
    lon      = Latitud,   # -70.x (longitud real)
    lat      = Longitud   # -33.x (latitud real)
  ) %>%
  distinct() %>%
  arrange(estacion)

dir_create(here("output"))
write_csv(dicc_rm, here("output","diccionario_estaciones_RM.csv"))
message("Estaciones RM detectadas: ", nrow(dicc_rm))


# 1) Descarga PM2.5 horario (todas las estaciones) ------------------------
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

  # Normaliza nombres y TIPOS ANTES de unir
  out <- janitor::clean_names(out)

  # fuerza status s_pm25 (y cualquier s_*) a character
  stat_cols <- grep("^s_", names(out), value = TRUE)
  if (length(stat_cols)) out[stat_cols] <- lapply(out[stat_cols], as.character)

  # detecta columna PM25 y la fuerza a numeric (por si viene como texto)
  pm_col <- names(out)[stringr::str_detect(names(out), "(^pm2?5$|pm25)")]
  pm_col <- pm_col[1]
  out[[pm_col]] <- suppressWarnings(as.numeric(out[[pm_col]]))

  # añade etiqueta de estación (por si no vino)
  out$estacion <- est

  out
}, otherwise = tibble(), quiet = TRUE)

message("Descargando PM2.5 horario para todas las estaciones de la RM…")
pm_h_list <- purrr::map(dicc_rm$estacion, trae_pm25)

# usa bind_rows (combina columnas aunque falten en algunas)
pm_h <- dplyr::bind_rows(pm_h_list)


# 2) Limpieza mínima y agregado diario/anual ------------------------------
pm_h <- pm_h %>% clean_names()

# Detecta columnas clave con tolerancia
col_fecha <- intersect(c("fecha_hora","datetime","date","fecha"), names(pm_h))[1]
stopifnot(!is.na(col_fecha))
col_pm    <- names(pm_h)[str_detect(names(pm_h), regex("^pm\\s*2?5$", ignore_case = TRUE))][1]
if (is.na(col_pm)) {
  col_pm <- names(pm_h)[str_detect(names(pm_h), regex("pm25", ignore_case = TRUE))][1]
}
stopifnot(!is.na(col_pm))
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
  filter(!is.na(date), !is.na(pm25), pm25 >= 0, pm25 <= 500)

# Agregado diario por estación
pm_d <- pm_h %>%
  mutate(fecha = as_date(date)) %>%
  group_by(estacion, fecha) %>%
  summarise(pm25_diario = mean(pm25, na.rm = TRUE), .groups = "drop")

# Agregado anual por estación (con n_dias para referencia)
pm_anual_est <- pm_d %>%
  mutate(anio = year(fecha)) %>%
  group_by(estacion, anio) %>%
  summarise(pm25_media = mean(pm25_diario, na.rm = TRUE),
            n_dias     = n(),
            .groups = "drop")

dir_create(here("datos_procesados"))
write_csv(pm_d,         here("datos_procesados","pm25_diario.csv"))
write_csv(pm_anual_est, here("datos_procesados","pm25_anual_estacion.csv"))

message("Listo: datos_procesados/pm25_diario.csv y pm25_anual_estacion.csv")


