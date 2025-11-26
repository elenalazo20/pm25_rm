# R/01_configuracion.R ----------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(fs)
  library(ggplot2)
  library(tidyverse)
})

# 1) Fijar raíz del proyecto ----------------------------------------------
here::i_am("R/01_configuracion.R")
#cat("Raíz del proyecto:", here::here(), "\n")

# 2) Crear carpetas base ---------------------------------------------------
carpetas <- c("datos_crudos",
              "datos_procesados",
              "figuras",
              "resultados",
              "reportes")

fs::dir_create(here::here(carpetas))

# 3) Función para guardar figuras -----------------------------------------
guardar_fig <- function(p, file, w = 10, h = 6, dpi = 300) {

  tiene_carpeta <- fs::path_dir(file) != "." # Verifica si el archivo incluye un direct, sino devuelve un .

  ruta <- if (tiene_carpeta) {
    here::here(file) # Si tiene carpeta, usa la ruta tal cual, partiendo del inicio del proyecto
  } else {
    here::here("figuras", file) # Si NO tiene carpeta, añade a la carpeta figuras al inicio de la ruta
  }

  fs::dir_create(fs::path_dir(ruta)) # # Crea la carpeta necesaria (por ejemplo "figuras/") si aún no existe.

  ggplot2::ggsave(
    filename = ruta,
    plot = p,
    width = w,
    height = h,
    dpi = dpi
  )

  message("Figura guardada en: ", ruta)
  invisible(ruta)
}

# 4) Helper para snapshot del árbol de carpetas ---------------------------
# Solo se define; se llama a mano cuando lo necesite
snapshot_arbol <- function(niveles = 3,
                           base = here::here("resultados", "estructura_proyecto")) {

  fs::dir_create(fs::path_dir(base))

  arbol <- capture.output(
    fs::dir_tree(here::here(), recurse = niveles)
  )

  # .txt
  writeLines(arbol, paste0(base, ".txt"))

  # .md con bloque de código
  writeLines(
    c("```", arbol, "```"),
    paste0(base, ".md")
  )

  message("Árbol actualizado en: ",
          paste0(base, ".txt"), " y ",
          paste0(base, ".md"))
  invisible(arbol)
}

