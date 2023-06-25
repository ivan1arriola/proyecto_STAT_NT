library(sf)

transformarCoord <- function(lat, lon, mvd_map){
  puntos_lat_lng <- data.frame(lng = lon, lat = lat)
  puntos_sf <- st_as_sf(puntos_lat_lng,
                        coords = c("lng", "lat"),
                        crs = 4326)
  puntos_transformados <- st_transform(puntos_sf,
                                       crs = st_crs(mvd_map))
  return(puntos_transformados)
}
print("transformarCoord loaded")


encontrar_barrio <- function(lat, lon, mvd_map) {
  # Convertir las coordenadas geográficas a un objeto espacial sf
  puntos_transformados <- transformarCoord(lat, lon, mvd_map)
  
  # Encontrar el barrio que contiene el punto
  ls_contains <- st_contains(mvd_map$the_geom,
                             puntos_transformados$geometry)
  indice_barrio <- which(as.logical(ls_contains))[1]
  matching_barrios <- mvd_map[indice_barrio, ]
  
  # Obtener el nombre del barrio
  barrio <- matching_barrios$nombbarr
  
  # Retornar el nombre del barrio
  return(barrio)
}
print("encontrar_barrio loaded")

# Cargar las bibliotecas spdep y leaflet
library(spdep)

# Definir una función personalizada para colorear polígonos
nacol <- function(spdf) {
  resample <- function(x, ...) x[sample.int(length(x), ...)]
  nunique <- function(x) {unique(x[!is.na(x)])}
  np = nrow(spdf)
  adjl = spdep::poly2nb(spdf)
  cols = rep(NA, np)
  cols[1]=1
  nextColour = 2
  for (k in 2:np) {
    adjcolours = nunique(cols[adjl[[k]]])
    if (length(adjcolours)==0) {
      cols[k]=resample(cols[!is.na(cols)],1)
    }else {
      avail = setdiff(nunique(cols), nunique(adjcolours))
      if (length(avail)==0) {
        cols[k]=nextColour
        nextColour=nextColour+1
      }else {
        cols[k]=resample(avail,size=1)
      }
    }
  }
  return(cols)
}
print("nacol loaded")