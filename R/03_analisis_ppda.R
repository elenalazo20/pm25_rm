# Script: 03_analisis_ppda.R
# Objetivo: Realizar todos los cálculos necesarios para la Tabla 1 y los 3 gráficos.

# --- 1. Cargar Librerías y Datos ---
library(tidyverse)
library(lubridate)
library(here)
library(gt) # Para la tabla profesional

# Cargamos el CSV que generó el script 02.
# Este es el flujo de trabajo de la profesora.
datos_rm_raw <- read_csv(here("resultados", "csv", "csv_rm.csv"))

# --- 2. Preparación Inicial y Creación de Períodos ---
datos_rm <- datos_rm_raw %>%
  # Aseguramos que la columna de concentración sea numérica
  mutate(concentration = as.numeric(concentration)) %>%
  drop_na(concentration) %>%
  # Convertir la fecha al formato correcto (dmy_hm)
  mutate(
    date = dmy_hm(date),
    year = year(date),
    month = month(date),
    is_winter = month %in% c(5, 6, 7, 8), # Mayo-Ago

    # --- La Columna Clave del Proyecto ---
    periodo_ppda = case_when(
      year < 2018 ~ "1. Pre-PPDA (2014-2017)",
      year >= 2018 ~ "2. Post-PPDA (2018-Actual)"
    )
  )

# --- 3. Función de Resumen (CI de la Profesora) ---
# Esta función calcula la media y el Intervalo de Confianza (CI)
ci_summary_pm25 <- function(datos, tiempo) {
  datos %>%
    group_by(across(all_of(tiempo)), site) %>%
    summarise(
      n = sum(!is.na(concentration)),
      mean = mean(concentration, na.rm = TRUE),
      sd   = sd(concentration,  na.rm = TRUE),
      se   = sd / sqrt(n), # Error Estándar
      ymin_ci = mean - 1.96 * se, # Límite inferior del CI
      ymax_ci = mean + 1.96 * se, # Límite superior del CI
      .groups = "drop"
    )
}

# --- 4. CÁLCULO PARA GRÁFICO 1: Tendencia Anual (Facet Plot) ---
datos_anuales <- datos_rm %>%
  group_by(year, site) %>%
  summarise(pm25_anual = mean(concentration, na.rm = TRUE), .groups = 'drop') %>%
  filter(pm25_anual > 0)

# --- 5. CÁLCULO PARA GRÁFICO 2: Frecuencia de Superación (Invierno) ---
datos_superacion <- datos_rm %>%
  filter(is_winter == TRUE) %>% # Solo Invierno
  mutate(supera_norma = concentration >= 50) %>% # Norma Diaria = 50 ug/m3
  group_by(periodo_ppda, site) %>%
  summarise(
    dias_totales = n(),
    dias_sobre_50 = sum(supera_norma, na.rm = TRUE),
    porcentaje_sobre_50 = (dias_sobre_50 / dias_totales) * 100,
    .groups = 'drop'
  ) %>%
  filter(dias_totales > 50) # Filtramos estaciones con pocos datos

# --- 6. CÁLCULO PARA TABLA 1 y GRÁFICO 3: Cambio Neto (Bivariado) ---
# Usamos la función CI para obtener los promedios Pre y Post
promedios_periodo <- datos_rm %>%
  group_by(site, periodo_ppda) %>%
  ci_summary_pm25(tiempo = c("periodo_ppda"))

# Pivotear para calcular la diferencia
datos_cambio <- promedios_periodo %>%
  select(site, periodo_ppda, mean, ymin_ci, ymax_ci) %>%
  pivot_wider(
    names_from = periodo_ppda,
    values_from = c(mean, ymin_ci, ymax_ci)
  ) %>%
  # Renombrar para claridad
  rename(
    mean_Pre = `mean_1. Pre-PPDA (2014-2017)`,
    mean_Post = `mean_2. Post-PPDA (2018-Actual)`,
    ymin_Pre = `ymin_ci_1. Pre-PPDA (2014-2017)`,
    ymax_Pre = `ymax_ci_1. Pre-PPDA (2014-2017)`,
    ymin_Post = `ymin_ci_2. Post-PPDA (2018-Actual)`,
    ymax_Post = `ymax_ci_2. Post-PPDA (2018-Actual)`
  ) %>%
  # Calcular la reducción (una resta positiva es una mejora)
  mutate(
    reduccion = mean_Pre - mean_Post
  ) %>%
  # Ordenar por la mayor mejora
  arrange(desc(reduccion))

# --- 7. Guardar los datos finales procesados ---
# Guardamos los 3 objetos que usará el reporte Quarto
save(datos_anuales, datos_superacion, datos_cambio,
     file = here("datos_procesados", "analisis_pm25_ppda.RData"))
