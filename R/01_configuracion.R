# R/01_configuracion.R ----------------------------------------------------
suppressPackageStartupMessages({
  library(here);
  library(fs);
  library(tidyverse)})

#  Fijar raíz del proyecto ------------------------------------------------
here::i_am("R/01_configuracion.R")
cat("Raíz del proyecto:", here::here(), "\n")

# 1) Carpetas base -----------------------------------------------------------
dirs <- c("datos_crudos","datos_procesados","figs","output","reports")
dir_create(here(dirs))

# 2) Helper para guardar figuras con carpeta asegurada -----------------------
guardar_fig <- function(p, file, w=10, h=6, dpi=300){
  dir_create(path_dir(file))
  ggplot2::ggsave(file, p, width = w, height = h, dpi = dpi)}

# 3) Gráfico del árbol inicial de carpetas con fs::dir_tree() -------------
snapshot_arbol <- function(niveles = 2){
  dir_create(here("output"))
  tree <- capture.output(dir_tree(here(), recurse = niveles))
  writeLines(tree, here("output/estructura_proyecto.txt"))
  writeLines(c("```", tree, "```"), here("output/estructura_proyecto.md"))
  message("Árbol actualizado en output/estructura_proyecto.{txt,md}")
  invisible(tree)}

