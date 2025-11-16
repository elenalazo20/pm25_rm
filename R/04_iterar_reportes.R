# 04_iterar_reportes.R
# Generar PDFs suplementarios por estación y guardarlos en /reportes/suplementario

library(quarto)
library(purrr)
library(here)
library(fs)
library(glue)

here::i_am("R/04_iterar_reportes.R")

# 1. Cargar datos para obtener lista de estaciones
load(here("datos_procesados", "analisis_pm25_ppda.RData"))

estaciones_todas <- sort(unique(datos_cambio$site))

cat("Se generarán reportes suplementarios para las siguientes estaciones:\n")
print(estaciones_todas)

# 2. Rutas
input_qmd <- here("reportes", "reporte_estacion.qmd")
out_dir   <- here("reportes", "suplementario")
dir_create(out_dir)

# 3. Función que renderiza y mueve el PDF
render_reporte_estacion <- function(est) {
  cat("\n--- Renderizando reporte para:", est, "---\n")

  archivo_pdf <- glue("suplementario_{est}.pdf")

  # Render: el PDF se crea en /reportes/
  quarto::quarto_render(
    input         = input_qmd,
    execute_params = list(est_codigo = est),
    output_file    = archivo_pdf
  )

  # Mover a /reportes/suplementario/
  file_move(
    path     = here("reportes", archivo_pdf),
    new_path = path(out_dir, archivo_pdf)
  )
}

# 4. Ejecutar para todas las estaciones
walk(estaciones_todas, render_reporte_estacion)

cat("\n--- ¡Iteración de reportes suplementarios completada! ---\n")
