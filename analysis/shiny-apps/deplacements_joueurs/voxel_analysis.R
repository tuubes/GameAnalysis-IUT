# Utilitaires pour la visualisation de déplacements 3D par tronçons
# (c) Guillaume Raffin 2018
#
library(rgl)
library(plot3D)

#' Itérateur sur les lignes, version optimisée par Ł Łaniewski-Wołłk.
#' Tiré de https://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
#' Utilisation :
#' for(row in rowsItr(dataFrame)) { }
rowsItr = function(x) lapply(seq_len(nrow(x)), function(i) lapply(x,"[",i))

rgl3D <- function(data, xi=1, yi=2, zi=3, ni=4,
                        xfactor=1, yfactor=1, zfactor=1, colorFunction,
                        xlab="X", ylab="Y", zlab="Z",
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
  
  title3d("Déplacements des joueurs", xlab, ylab, zlab)
  axes3d("x")
  axes3d("y")
  axes3d("z")
}

scatterPlot3D <- function(data, xi=1, yi=2, zi=3, ni=4, colorFunction,
                                 xlab="X", ylab="Y", zlab="Z") {
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
  plot3d(x=dataX, y=dataY, z=dataZ, col=vColors, type="s", radius=0.5,
         xlab=xlab, ylab=ylab, zlab=zlab)
}

image2D <- function(data, xi=1, yi=2, ni=4, colorFunction, defaultN=0, xlab="X", ylab="Y",
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
  image(xMin:xMax, yMin:yMax, zMatrix, col=vColors, xlab=xlab, ylab=ylab)
}
