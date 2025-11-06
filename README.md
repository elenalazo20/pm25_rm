# PM2.5 – Región Metropolitana de Santiago (2018–2024): visualización y análisis
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
