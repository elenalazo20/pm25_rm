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

# 2) Crear carpetas base (nombres en español) ------------------------------
carpetas <- c("datos_crudos",
              "datos_procesados",
              "figuras",
              "resultados",
              "reportes")

fs::dir_create(here::here(carpetas))

# 3) Helper para guardar figuras ------------------------------------------
# Uso:
#   guardar_fig(g, "mi_grafico.png")
#   guardar_fig(g, "reportes/figuras/fig1.pdf", w = 8, h = 5)
guardar_fig <- function(p, file, w = 10, h = 6, dpi = 300) {

  # Si solo se pasa el nombre del archivo, se guarda en "figuras"
  ruta <- if (fs::path_has_parent(file)) {
    here::here(file)
  } else {
    here::here("figuras", file)
  }

  fs::dir_create(fs::path_dir(ruta))

  ggplot2::ggsave(
    filename = ruta,
    plot     = p,
    width    = w,
    height   = h,
    dpi      = dpi
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

