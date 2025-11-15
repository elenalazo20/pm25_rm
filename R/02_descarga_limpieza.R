# Script: 02_descarga_limpieza.R

# Cargamos librerías necesarias
library(here)
library(tidyverse)
library(AtmChile)
library(janitor)
library(fs)

# 1. Definición de Parámetros y Carga de Datos (2014-2024) ----------------
# Las estaciones:
comunas_rm <- c("P.O'Higgins","Cerrillos 1","Cerrillos","Cerro Navia",
                "El Bosque","Independencia","La Florida","Las Condes",
                "Pudahuel","Puente Alto","Quilicura", "Quilicura 1")

# Descargamos los datos de PM25
datos_descargados <- AtmChile::ChileAirQuality(
  Comunas = comunas_rm,
  Parametros = c("PM25"),
  fechadeInicio = "01/01/2014",
  fechadeTermino = "31/12/2024",
  Curar = TRUE,
  Site = FALSE
)

# 2. Limpieza y Guardado --------------------------------------------------
datos_rm <- datos_descargados %>%
  janitor::clean_names() %>%
  rename(concentration = pm25) %>%
  select(date, site, concentration)

# Creamos la carpeta de resultados si no existe
dir_create(here("resultados", "csv"))

# Guardamos el archivo que el script 03 leerá
write_csv(datos_rm, here("resultados", "csv", "csv_rm.csv"))
