# 04_iterar_reportes.R
# Generar PDFs suplementarios por estación y guardarlos en /reportes/suplementario

suppressPackageStartupMessages({
  library(quarto)
  library(purrr)
  library(here)
  library(fs)
  library(glue)
})

here::i_am("R/04_iterar_reportes.R")

# 1. Cargar datos para obtener lista de estaciones
load(here::here("datos_procesados", "analisis_pm25_ppda.RData"))

estaciones_todas <- sort(unique(datos_cambio$site))

cat("Se generarán reportes suplementarios para las siguientes estaciones:\n")
print(estaciones_todas)

# 2. Rutas
input_qmd <- here::here("reportes", "reporte_estacion.qmd")
out_dir   <- here::here("reportes", "suplementario")
fs::dir_create(out_dir)

# 3. Función de renderizado a PDF
render_reporte_estacion <- function(codigo_estacion) {

  cat("\n--- Renderizando reporte para:", codigo_estacion, "---\n")

  archivo_pdf <- glue::glue("suplementario_{codigo_estacion}.pdf")

  quarto::quarto_render(
    input          = input_qmd,
    output_format  = "pdf",
    output_file    = archivo_pdf,
    execute_params = list(est_codigo = codigo_estacion))

  fs::file_move(
    path     = here::here("reportes", archivo_pdf),
    new_path = fs::path(out_dir, archivo_pdf))}

# 4. Ejecutar para todas las estaciones
walk(estaciones_todas, render_reporte_estacion)

cat("\n--- ¡Iteración de reportes suplementarios completada! ---\n")

