``` md
---
editor_options: 
  markdown: 
    wrap: 72
---

# PM2.5 - Región Metropolitana (2018-2024): visualización y análisis 🌁

**Proyecto Final del Curso Visualización y Análisis de Datos
Medioambientales (AGP3141)**  
Docente: @Saryace · Autora: @elenalazo20 · Licencia: MIT

---

## 🧩 Descripción general

Este repositorio contiene el proyecto final del curso **Visualización y
Análisis de Datos Medioambientales (AGP3141)**. El objetivo principal es
explorar, de manera descriptiva y reproducible, el impacto del **Plan de
Prevención y Descontaminación Atmosférica (PPDA, D.S. 31/2016)** sobre
las concentraciones de **material particulado fino (PM₂.₅)** en la
**Región Metropolitana de Santiago (RM)**.

El análisis se basa en datos horarios de PM₂.₅ obtenidos desde la red
oficial de monitoreo (SINCA) a través del paquete `AtmChile`. Se
considera el período **2014–2024**, comparando dos momentos:

- **Pre-PPDA:** 2014–2017  
- **Post-PPDA:** 2018–2024

La comparación se realiza a nivel de estaciones y comunas, utilizando
tanto indicadores anuales como métricas de riesgo agudo (porcentaje de
días de invierno con PM₂.₅ ≥ 50 µg/m³).

---

## 🎯 Objetivos del proyecto

- **Descargar, limpiar y organizar** datos horarios de PM₂.₅ de la RM
  con un flujo de trabajo reproducible en R.
- **Caracterizar la evolución temporal** de PM₂.₅ antes y después de la
  implementación del PPDA.
- **Visualizar resultados clave** mediante gráficos y mapas
  reproducibles en Quarto.
- **Generar un informe principal** en formato HTML (Quarto + lumo) y
  **reportes suplementarios en PDF** por estación de monitoreo.

---

## 📊 Datos

### 🗂️ Fuente

Los datos se obtienen mediante el paquete `AtmChile`:

- Función utilizada: `ChileAirQuality()`
- Parámetros:
  - Contaminante: `PM25`
  - Período: 2014-01-01 a 2024-12-31
  - Comunas seleccionadas: estaciones urbanas representativas de la RM
    (por ejemplo, Cerrillos, Cerro Navia, El Bosque, Independencia, Las
    Condes, Pudahuel, Puente Alto, Quilicura, Talagante, etc.).

### 📁 Productos intermedios

Tras la descarga y limpieza se generan:

- `resultados/csv/csv_rm.csv`:  
  serie horaria depurada de PM₂.₅ (fecha, estación, concentración).
- `datos_procesados/analisis_pm25_ppda.RData`:  
  objetos ya agregados para el análisis y las figuras del informe:
  - `datos_anuales`
  - `datos_superacion`
  - `datos_cambio`

---

## 🗺️ Estructura del proyecto

La estructura relevante del repositorio es la siguiente:

```txt
.
├── datos_crudos
│   ├── comunas_rm.geojson
│   └── pm25_rm_horario.csv
├── datos_procesados
│   └── analisis_pm25_ppda.RData
├── figuras
│   ├── fig01_mapa_pre_post.png
│   ├── fig02_tendencia_facet.png
│   └── fig03_dumbbell_50.png
├── R
│   ├── 01_configuracion.R
│   ├── 02_descarga_limpieza.R
│   ├── 03_analisis_ppda.R
│   └── 04_iterar_reportes.R
├── reportes
│   ├── reporte_final.qmd          # Informe principal (lumo-html)
│   ├── reporte_final.html         # Salida HTML
│   ├── reporte_estacion.qmd       # Reportes por estación (PDF)
│   ├── style_ppda.css             # Estilos personalizados
│   ├── footer.html                # Pie de página HTML
│   └── suplementario/             # PDFs por estación
│       ├── suplementario_CEI.pdf
│       ├── suplementario_CEII.pdf
│       ├── suplementario_CN.pdf
│       ├── suplementario_EB.pdf
│       ├── suplementario_IN.pdf
│       ├── suplementario_LC.pdf
│       ├── suplementario_LF.pdf
│       ├── suplementario_PA.pdf
│       ├── suplementario_PU.pdf
│       ├── suplementario_QU.pdf
│       └── suplementario_TALI.pdf
├── resultados
│   └── csv
│       └── csv_rm.csv
├── LICENSE
└── pm25_rm.Rproj
```

> 💡 Nota: Quarto también genera carpetas auxiliares como `reportes/reporte_final_files/` y `reportes/reporte_final_cache/` que contienen recursos internos del HTML y archivos de caché. No forman parte del flujo lógico del proyecto, pero son esperables en una compilación de Quarto.

------------------------------------------------------------------------

## 🔁 Flujo de trabajo / Cómo reproducir el análisis

A continuación se describe el flujo típico para reproducir el análisis completo desde cero.

### 1️⃣ Clonar el repositorio y abrir el proyecto

``` bash
git clone https://github.com/elenalazo20/pm25_rm.git
cd pm25_rm
```

Luego, abrir `pm25_rm.Rproj` en RStudio (o en tu IDE preferido).

### 2️⃣ Configuración del proyecto

En R:

``` r
source("R/01_configuracion.R")
```

Este script:

-   Fija correctamente la raíz del proyecto usando `here::i_am()`.
-   Crea las carpetas base (`datos_crudos/`, `datos_procesados/`, `figuras/`, `resultados/`, `reportes/`) si no existen.
-   Define funciones auxiliares como `guardar_fig()` y `snapshot_arbol()`.

### 3️⃣ Descarga y limpieza de datos

``` r
source("R/02_descarga_limpieza.R")
```

Este script:

-   Descarga los datos horarios de PM₂.₅ para las estaciones seleccionadas usando `AtmChile::ChileAirQuality()`.
-   Limpia y estandariza las variables.
-   Guarda un CSV depurado en: `resultados/csv/csv_rm.csv`.

> ⚠️ Advertencia: la descarga puede tomar algo de tiempo, dependiendo de la conexión y del período solicitado.

### 4️⃣ Análisis y generación de objetos para el informe

``` r
source("R/03_analisis_ppda.R")
```

Este script:

-   Carga `resultados/csv/csv_rm.csv`.

-   Crea variables derivadas (año, invierno, periodo Pre/Post PPDA).

-   Calcula:

    -   Promedios anuales por estación (`datos_anuales`).
    -   Porcentaje de días de invierno con PM₂.₅ ≥ 50 µg/m³ (`datos_superacion`).
    -   Cambio neto Pre vs. Post por estación, con IC95% (`datos_cambio`).

-   Guarda estos objetos en: `datos_procesados/analisis_pm25_ppda.RData`.

### 5️⃣ Renderizar el informe principal (Quarto)

``` r
quarto::quarto_render("reportes/reporte_final.qmd")
```

Esto genera el archivo:

-   `reportes/reporte_final.html`

El informe incluye:

-   Tabla resumen de PM₂.₅ anual Pre y Post PPDA por estación.
-   Mapa comparando el promedio de PM₂.₅ por comuna en ambos períodos.
-   Gráfico de tendencias anuales por estación.
-   Gráfico tipo “dumbbell” con el porcentaje de días críticos de invierno (PM₂.₅ ≥ 50 µg/m³).
-   Tabla con enlaces a los PDFs suplementarios por estación.

### 6️⃣ Generar reportes suplementarios por estación (PDF)

Opcionalmente, se pueden generar reportes detallados (perfil horario y distribución diaria) para cada estación:

``` r
source("R/04_iterar_reportes.R")
```

Este script:

-   Carga `datos_procesados/analisis_pm25_ppda.RData`.
-   Identifica las estaciones disponibles en `datos_cambio`.
-   Llama iterativamente a `quarto::quarto_render()` sobre `reportes/reporte_estacion.qmd`, pasando cada código de estación como parámetro.
-   Guarda un PDF por estación en: `reportes/suplementario/`.

------------------------------------------------------------------------

## 📌 Productos principales

-   **Informe HTML principal** `reportes/reporte_final.html` Contiene el análisis descriptivo completo, figuras y enlaces a material suplementario.

-   **Figuras finales para uso en otros contextos**

    -   `figuras/fig01_mapa_pre_post.png`
    -   `figuras/fig02_tendencia_facet.png`
    -   `figuras/fig03_dumbbell_50.png`

-   **Reportes suplementarios en PDF por estación** Carpeta `reportes/suplementario/`, un PDF por estación con:

    -   Perfil horario Pre/Post PPDA.
    -   Distribución diaria de PM₂.₅ por período.

------------------------------------------------------------------------

## 📦 Dependencias principales

El proyecto fue desarrollado y probado en **R 4.5.2** e incluye, entre otros, los siguientes paquetes:

-   Estructura y utilidades:

    -   `here`
    -   `fs`
    -   `tidyverse`
    -   `lubridate`
    -   `janitor`

-   Datos ambientales y mapas:

    -   `AtmChile`
    -   `chilemapas`
    -   `sf`
    -   `mapview`
    -   `patchwork`

-   Tablas y reporte:

    -   `gt`
    -   `knitr`
    -   `kableExtra`

-   Quarto:

    -   `quarto` (para `quarto_render()`)

Las dependencias pueden instalarse con:

``` r
install.packages(c(
  "here", "fs", "tidyverse", "lubridate", "janitor",
  "AtmChile", "chilemapas", "sf", "mapview", "patchwork",
  "gt", "knitr", "kableExtra", "quarto"
))
```

------------------------------------------------------------------------

## ⚖️ Licencia

El código de este repositorio se distribuye bajo licencia **MIT**. Ver el archivo `LICENSE` para más detalles.

```         

Si querés, después vemos juntos si el título y el subtítulo del README y del `reporte_final.qmd` están diciendo exactamente lo mismo, o si conviene afinar una frase para que quede ultra coherente ✨
::contentReference[oaicite:0]{index=0}
```
