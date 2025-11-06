# PM2.5 - Región Metropolitana (2018–2024): visualización y análisis
**Proyecto Final del Curso Visualización y Análisis de Datos Medioambientales (AGP3141)**  
Docente: **@Saryace** · Autora: **@elenalazo20** · Licencia: MIT

## Sobre este README
Este documento es un **reporte vivo**: aquí registro la historia del proyecto (cómo lo fui creando), describo los métodos y, más adelante, incorporaré resultados y figuras. También dejo abierta la opción de un informe en **Quarto** (`reports/PM25_RM.qmd`). Además, iré agregando recordatorios prácticos (pasos, comandos y decisiones) que me sirvan como guía para futuros proyectos. La idea es que se vea el progreso: desde no saber casi nada de GitHub ni de su integración con R, hasta avanzar con buenas prácticas y control de versiones (sé que aún me falta mucho).

> [TIP!] **Guía exprés: creación del proyecto (R + GitHub Desktop)**
>
> **1) Crear repo en GitHub Desktop**
> - `File → New repository…` → **Name:** `pm25_rm` (o el que toque)
> - **Local path:** carpeta de proyectos 
> - ✅ Initialize with **README** · **Git ignore:** R · **License:** MIT
> - **Publish repository** (Public/Private según necesidad)
>
> **2) Convertirlo en proyecto de RStudio**
> - `RStudio → File → New Project… → Existing Directory →` seleccionar la carpeta del repo
> - Se crea `NOMBRE.Rproj` → **abrir siempre** con este archivo
> - _Chequeo rápido:_
>   ```r
>   here::here(); usethis::proj_get()
>   ```
>
> **Archivos creados**
> - `.Rproj`, `README.md`, `LICENSE`, `.gitignore` y la carpeta oculta `.git/`.

## ❓ Pregunta de investigación
**¿Cómo varían los niveles de material particulado fino (PM2.5) en la Región Metropolitana (RM) entre 2018–2024, tanto en el espacio (entre comunas) como en el tiempo (tendencias y estacionalidad), y en qué medida superan los umbrales de la norma chilena (25 µg/m³) y de la Organización Mundial de la Salud (OMS, 15 µg/m³)?**

## 💡 Hipótesis
1) **Espacial (gradiente):** existe un gradiente territorial, con comunas del poniente/sur mostrando niveles medios de PM2.5 más altos que las del oriente, y con bolsones persistentes de alta concentración.
2) **Temporal (tendencia):** la media anual de PM2.5 muestra una caída general en 2018–2024, con estacionalidad invernal marcada (picos en junio–julio–agosto) y diferencias en la velocidad de descenso entre comunas.
3) **Excedencias:** el porcentaje de días por sobre los umbrales Chile 25 y OMS 15 disminuye en el período, aunque varias comunas no convergen al estándar OMS.

> **Definición operativa de excedencia:** día en que el promedio diario de PM2.5 supera el umbral (Chile 25 µg/m³; OMS 15 µg/m³).

