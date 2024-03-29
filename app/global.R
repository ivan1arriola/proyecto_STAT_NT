print("Loading global.R")

# Directorios -------------------------------------------------------------

dataDir <- "data"
moduleDir <- "modules"


# Paquetes ----------------------------------------------------------------
library(magrittr)
library(shiny)
library(leaflet)
library(bslib)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(sf)

source("utils.R")

# Variables globales ------------------------------------------------------

intervalos <- c(
  '00:00', '01:00', '02:00', '03:00', '04:00', '05:00',
  '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
  '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
  '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'
)

# Cargar datos ------------------------------------------------------------

### Coneccion a la Base de datos
print("Connecting to database")
con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("DB_HOST"),
  port = Sys.getenv("DB_PORT"),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASS"),
  dbname = Sys.getenv("DB_NAME")
)

## Cargar Mapa de Montevideo
mvd_map_fixed <- geouy::load_geouy("Barrios") %>% st_transform(crs = 4326) %>% st_make_valid()
print(names(mvd_map_fixed) %>% paste(collapse = ", "))

getColorsMVD <- colorFactor(
  palette = "Set1", 
  domain = nacol(sf::st_make_valid(sf::st_transform(mvd_map_fixed, crs = 4326)))
)

## Cargar datos de sensores

d_sensores <- obtener_registros_max2(
  "d_sensores.csv",
  con,
  "
  SELECT
    *
  FROM
    d_sensores
  "
)

puntos_sensores <- d_sensores %>% 
  dplyr::select(barrio, latitud, longitud) %>%
  dplyr::mutate(transformarCoord(latitud, longitud, mvd_map_fixed))


## Registros de sensores

registros_max_file <-  "registros_max_barrio_file.csv"

registros_max_barrioxdiaxhora <- obtener_registros_max(registros_max_file, con,
    "
      SELECT
        d_sensores.barrio,
        d_date.day_of_week,
        CASE
            WHEN fct_registros.id_hora >= 0 AND fct_registros.id_hora < 100 THEN '00:00'
            WHEN fct_registros.id_hora >= 100 AND fct_registros.id_hora < 200 THEN '01:00'
            WHEN fct_registros.id_hora >= 200 AND fct_registros.id_hora < 300 THEN '02:00'
            WHEN fct_registros.id_hora >= 300 AND fct_registros.id_hora < 400 THEN '03:00'
            WHEN fct_registros.id_hora >= 400 AND fct_registros.id_hora < 500 THEN '04:00'
            WHEN fct_registros.id_hora >= 500 AND fct_registros.id_hora < 600 THEN '05:00'
            WHEN fct_registros.id_hora >= 600 AND fct_registros.id_hora < 700 THEN '06:00'
            WHEN fct_registros.id_hora >= 700 AND fct_registros.id_hora < 800 THEN '07:00'
            WHEN fct_registros.id_hora >= 800 AND fct_registros.id_hora < 900 THEN '08:00'
            WHEN fct_registros.id_hora >= 900 AND fct_registros.id_hora < 1000 THEN '09:00'
            WHEN fct_registros.id_hora >= 1000 AND fct_registros.id_hora < 1100 THEN '10:00'
            WHEN fct_registros.id_hora >= 1100 AND fct_registros.id_hora < 1200 THEN '11:00'
            WHEN fct_registros.id_hora >= 1200 AND fct_registros.id_hora < 1300 THEN '12:00'
            WHEN fct_registros.id_hora >= 1300 AND fct_registros.id_hora < 1400 THEN '13:00'
            WHEN fct_registros.id_hora >= 1400 AND fct_registros.id_hora < 1500 THEN '14:00'
            WHEN fct_registros.id_hora >= 1500 AND fct_registros.id_hora < 1600 THEN '15:00'
            WHEN fct_registros.id_hora >= 1600 AND fct_registros.id_hora < 1700 THEN '16:00'
            WHEN fct_registros.id_hora >= 1700 AND fct_registros.id_hora < 1800 THEN '17:00'
            WHEN fct_registros.id_hora >= 1800 AND fct_registros.id_hora < 1900 THEN '18:00'
            WHEN fct_registros.id_hora >= 1900 AND fct_registros.id_hora < 2000 THEN '19:00'
            WHEN fct_registros.id_hora >= 2000 AND fct_registros.id_hora < 2100 THEN '20:00'
            WHEN fct_registros.id_hora >= 2100 AND fct_registros.id_hora < 2200 THEN '21:00'
            WHEN fct_registros.id_hora >= 2200 AND fct_registros.id_hora < 2300 THEN '22:00'
            WHEN fct_registros.id_hora >= 2300 AND fct_registros.id_hora < 2400 THEN '23:00'
            ELSE 'Unknown'
        END AS hora_rango,
        MAX(fct_registros.velocidad) AS max_velocidad,
        MAX(fct_registros.volume) AS max_volumen,
        AVG(fct_registros.velocidad) AS promedio_velocidad,
        AVG(fct_registros.volume) AS promedio_volumen,
        COUNT(fct_registros.velocidad) AS cant_registros
    FROM fct_registros
    INNER JOIN d_sensores ON fct_registros.id_detector = d_sensores.id_detector
    LEFT JOIN d_date ON fct_registros.id_fecha = d_date.id_fecha
    GROUP BY d_sensores.barrio, d_date.day_of_week, hora_rango
    "
  )



### registros maximos por rango hora, dia de la semana y sensor
registros_max_sensor_file <-"/registros__max_sensor__file.csv"
registros_max_barrioxdiaxhora_sensor <- obtener_registros_max(registros_max_sensor_file,
    con,
    "
      SELECT
        d_date.day_of_week,
        d_sensores.latitud,
        d_sensores.longitud,
        CASE
            WHEN fct_registros.id_hora >= 0 AND fct_registros.id_hora < 100 THEN '00:00'
            WHEN fct_registros.id_hora >= 100 AND fct_registros.id_hora < 200 THEN '01:00'
            WHEN fct_registros.id_hora >= 200 AND fct_registros.id_hora < 300 THEN '02:00'
            WHEN fct_registros.id_hora >= 300 AND fct_registros.id_hora < 400 THEN '03:00'
            WHEN fct_registros.id_hora >= 400 AND fct_registros.id_hora < 500 THEN '04:00'
            WHEN fct_registros.id_hora >= 500 AND fct_registros.id_hora < 600 THEN '05:00'
            WHEN fct_registros.id_hora >= 600 AND fct_registros.id_hora < 700 THEN '06:00'
            WHEN fct_registros.id_hora >= 700 AND fct_registros.id_hora < 800 THEN '07:00'
            WHEN fct_registros.id_hora >= 800 AND fct_registros.id_hora < 900 THEN '08:00'
            WHEN fct_registros.id_hora >= 900 AND fct_registros.id_hora < 1000 THEN '09:00'
            WHEN fct_registros.id_hora >= 1000 AND fct_registros.id_hora < 1100 THEN '10:00'
            WHEN fct_registros.id_hora >= 1100 AND fct_registros.id_hora < 1200 THEN '11:00'
            WHEN fct_registros.id_hora >= 1200 AND fct_registros.id_hora < 1300 THEN '12:00'
            WHEN fct_registros.id_hora >= 1300 AND fct_registros.id_hora < 1400 THEN '13:00'
            WHEN fct_registros.id_hora >= 1400 AND fct_registros.id_hora < 1500 THEN '14:00'
            WHEN fct_registros.id_hora >= 1500 AND fct_registros.id_hora < 1600 THEN '15:00'
            WHEN fct_registros.id_hora >= 1600 AND fct_registros.id_hora < 1700 THEN '16:00'
            WHEN fct_registros.id_hora >= 1700 AND fct_registros.id_hora < 1800 THEN '17:00'
            WHEN fct_registros.id_hora >= 1800 AND fct_registros.id_hora < 1900 THEN '18:00'
            WHEN fct_registros.id_hora >= 1900 AND fct_registros.id_hora < 2000 THEN '19:00'
            WHEN fct_registros.id_hora >= 2000 AND fct_registros.id_hora < 2100 THEN '20:00'
            WHEN fct_registros.id_hora >= 2100 AND fct_registros.id_hora < 2200 THEN '21:00'
            WHEN fct_registros.id_hora >= 2200 AND fct_registros.id_hora < 2300 THEN '22:00'
            WHEN fct_registros.id_hora >= 2300 AND fct_registros.id_hora < 2400 THEN '23:00'
            ELSE 'Unknown'
        END AS hora_rango,
        MAX(fct_registros.velocidad) AS max_velocidad,
        MAX(fct_registros.volume) AS max_volumen,
        AVG(fct_registros.velocidad) AS promedio_velocidad,
        AVG(fct_registros.volume) AS promedio_volumen
    FROM fct_registros
    INNER JOIN d_sensores ON fct_registros.id_detector = d_sensores.id_detector
    LEFT JOIN d_date ON fct_registros.id_fecha = d_date.id_fecha
    GROUP BY d_date.day_of_week, hora_rango, d_sensores.id_detector
    "
  )

  velocidad_volumen <- obtener_registros_max2('velocidad_volumen.csv',
  con,
  "
  SELECT
    fct_registros.velocidad,
    fct_registros.volume AS volumen
  FROM
    fct_registros TABLESAMPLE SYSTEM (1)
  WHERE
    fct_registros.velocidad > 0
  "
)

velocidad_calles <- obtener_registros_max2( "velocidad_sensores.csv",
  con,
  "
  SELECT
    d_sensores.latitud,
    d_sensores.longitud,
    AVG(fct_registros.velocidad) AS promedio_velocidad

FROM fct_registros
INNER JOIN d_sensores ON fct_registros.id_detector = d_sensores.id_detector
GROUP BY
    d_sensores.latitud,
    d_sensores.longitud;

  "
  )


# Cargar modulos ----------------------------------------------------------
lista_barrios <- d_sensores %>%
    select(barrio) %>%
    distinct() %>%
    arrange(barrio) %>%
    pull()

print("global.R loaded")