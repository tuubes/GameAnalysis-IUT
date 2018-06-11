# Utilitaires pour la visualisation de déplacements 3D par tronçons
# (c) Guillaume Raffin 2018
#
library(rgl)
library(data.table)

#' Itérateur sur les lignes, version optimisée par Ł Łaniewski-Wołłk.
#' Tiré de https://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
#' Utilisation :
#' for(row in rowsItr(dataFrame)) { }
rowsItr = function(x) lapply(seq_len(nrow(x)), function(i) lapply(x,"[",i))

#' Visualisation 3D de voxels XYZ colorés selon un quatrième paramètre N avec la fonction colorFunction.
#' 
#' @param data data.table contenant les données
#' @param xi numéro de la colonne contenant les coordonnées X horizontale
#' @param yi numéro de la colonne contenant les coordonnées Y horizontale
#' @param zi numéro de la colonne contenant les coordonnées Z verticale
#' @param xlab label de l'axe X horizontal
#' @param ylab label de l'axe Y horizontal
#' @param zlab label de l'axe Z vertical
#' @param title titre à afficher au dessus de la visualisation 3D
#' @param colorFunction fonction(n, nMin, nMax) -> as.character(couleur) qui définit la couleur des cubes
#' @param notifyProgressFunction fonction(x,y,z) -> () appellée après chaque affichage de cube
rgl3D <- function(data, xi=1, yi=2, zi=3, ni=4,
                        xfactor=1, yfactor=1, zfactor=1, colorFunction,
                        xlab="X", ylab="Y", zlab="Z", title="XYZ", subtitle="",
                        viewTheta=0, viewPhi=0,
                        light=FALSE, cubeOpacity=1.0,
                        borders=TRUE, bordersColor=rgb(0,0,0),
                        notifyProgressFunction=function(x,y,z){}) {
  nMin <- min(data[,..ni])
  nMax <- max(data[,..ni])
  
  open3d()
  view3d(theta=viewTheta, phi=viewPhi)
  rgl.pop("lights")
  light3d(theta=viewTheta, phi=viewPhi, viewpoint.rel=TRUE, ambient="white")
  bg3d("white")
  
  cube0 <- cube3d(lit=light, alpha=cubeOpacity, fog=FALSE, smooth=FALSE) # paramètres et optimisation : pas besoin de smooth et fog pour des voxels
  cube0$vb[cube0$vb == -1] <- 0
  for(row in rowsItr(data)) {
    x<-row[[xi]]*xfactor
    y<-row[[yi]]*yfactor
    z<-row[[zi]]*zfactor
    n<-row[[ni]]
    cube <- translate3d(cube0, x, y, z)
    cube$material$col <- colorFunction(n, nMin, nMax)
    if(borders) {
      wire3d(cube, add=TRUE, color=bordersColor)
    }
    shade3d(cube, add=TRUE, override=FALSE)
    notifyProgressFunction(x,y,z)
  }
  
  title3d(title, sub=subtitle, xlab=xlab, ylab=ylab, zlab=zlab)
  axes3d("x")
  axes3d("y")
  axes3d("z")
}

scatterPlot3D <- function(data, xi=1, yi=2, zi=3, ni=4, colorFunction,
                          viewTheta=0, viewPhi=0,
                          xlab="X", ylab="Y", zlab="Z", title="XYZ") {
  #plot_ly(data, x = data[,..xi], y = data[,..yi], z = data[,..zi],
  #plot_ly(data, x=~X, y=~Z, z=~Y,
  #        marker = list(color = data[,..ni], colorscale = c('#3182bd', '#de2d26'),
  #                      showscale = TRUE, size=3)) %>%
  #  add_markers() %>%
  #  layout(scene = list(xaxis = list(title = xlab),
  #                      yaxis = list(title = ylab),
  #                      zaxis = list(title = zlab)),
  #         annotations = list(
  #           x = 1.13,
  #           y = 1.05,
  #           text = 'Occurences',
  #           showarrow = FALSE
  #         ))
  #
  nMin<-min(data[,..ni])
  nMax<-max(data[,..ni])
  vColors <- lapply(data$N, function(n) colorFunction(n, nMin, nMax))
  dataX<-apply(data[,..xi], 1, as.numeric)
  dataY<-apply(data[,..yi], 1, as.numeric)
  dataZ<-apply(data[,..zi], 1, as.numeric)
  open3d()
  view3d(theta=viewTheta, phi=viewPhi)
  plot3d(x=dataX, y=dataY, z=dataZ, col=vColors, type="s", radius=0.5,
         xlab=xlab, ylab=ylab, zlab=zlab)
  title3d(title)
}

image2D <- function(data, xi=1, yi=2, ni=4, colorFunction, defaultN=0, xlab="X", ylab="Y",title="XY",
                    xMin=min(data[,..xi]), xMax=max(data[,..xi]),
                    yMin=min(data[,..yi]), yMax=max(data[,..yi]),
                    nMin=min(data[,..ni]), nMax=max(data[,..ni])) {
  zMatrix <- matrix(data = defaultN, nrow = xMax-xMin+1, ncol=yMax-yMin+1)
  for(row in rowsItr(data)) {
    x<-row[[xi]]
    y<-row[[yi]]
    n<-row[[ni]]
    zMatrix[x-xMin, y-yMin] <- n
  }
  nValues <- c(0)
  nValues <- c(nValues, min(data[,..ni]):max(data[,..ni]))
  vColors <- sapply(nValues, function(n) colorFunction(n, nMin, nMax))
  #vColors <- c(colorFunction(nMin,nMin,nMax), colorFunction(nMax,nMin,nMax))
  # image(x, y, zMatrix, col=vColors, xlab, ylab, zlim = c(nMin, nMax))
  graphics::image(xMin:xMax, yMin:yMax, zMatrix, col=vColors, xlab=xlab, ylab=ylab)
  graphics::title(title)
}

table2D <- function(data, defaultN=0, xi=1, yi=2, ni=4, xName="X", yName="Y", nName="N",
                          xMin=min(data[,..xi]), xMax=max(data[,..xi]),
                          yMin=min(data[,..yi]), yMax=max(data[,..yi])) {
  zMatrix <- matrix(data = defaultN, nrow = xMax-xMin+1, ncol=yMax-yMin+1)
  for(row in rowsItr(data)) {
    x<-row[[xi]]
    y<-row[[yi]]
    n<-row[[ni]]
    zMatrix[x-xMin, y-yMin] <- n
  }
  s<-structure(zMatrix, .Dimnames=list(xMin:xMax, yMin:yMax))
  t<-data.table(as.data.frame(as.table(s)))
  setnames(t, "Var1", xName)
  setnames(t, "Var2", yName)
  setnames(t, "Freq", nName)
  return(t)
}

colorMin <- "#3182bd"
colorMid <- "#addd8e"
colorMax <- "#fe2d26"
colorDefault <- "#ffffff"
colorGradient <- scales::gradient_n_pal(c(colorMin, colorMid, colorMax))

#' Génère une couleur correspondant à la valeur n donnée avec un gradient de couleur interne.
#' Le gradient peut être modifé avec la fonction `regenColorGradient(min, mid, max)`.
#' La couleur est retournée par interpolation linéaire des couleurs min, mid, max, en fonction
#' de p=(n-nMin)/(nMax-nMin) qui est entre 0 et 1.
#' Si p=0 alors getColor = min
#' Si p=0.5 alors getColor = mid
#' Si p=1 alors getColor = max
#' 
#' @param n la valeur à convertir en couleur
#' @param nMin min des n
#' @param nMax max des n
getColor <- function(n, nMin, nMax) {
  if(n == 0) {
    colorDefault
  } else {
    colorGradient((n-nMin)/(nMax-nMin))
  }
}
regenColorGradient <- function(min=colorMin, mid=colorMid, max=colorMax) {
  colorGradient <<- scales::gradient_n_pal(c(colorMin, colorMid, colorMax))
}
