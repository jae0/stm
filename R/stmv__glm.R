
stmv__glm = function(p=NULL, dat=NULL, pa=NULL, variablelist=FALSE, ... ) {
  #\\ this is the core engine of stmv .. localised space-time modelling interpolation and prediction
  #\\ simple GAM with spatial weights (inverse distance squared) and ts harmonics 
  if (variablelist)  return( c() )

  sdTotal=sd(dat[,p$variable$Y], na.rm=T)

  if ( exists("stmv_local_model_distanceweighted", p) ) {
    if (p$stmv_local_model_distanceweighted) {
      hmod = try( glm( p$stmv_local_modelformula, data=dat, weights=Y_wgt  ) ) 
    } else {
      hmod = try( glm( p$stmv_local_modelformula, data=dat ) ) 
    }
  } else {
      hmod = try( glm( p$stmv_local_modelformula, data=dat ) ) 
  } 

  if ( "try-error" %in% class(hmod) ) return( NULL )

  ss = summary(hmod)
  rsq = 1 - (ss$deviance/ss$null.deviance)
  if ( rsq < p$stmv_rsquared_threshold ) return(NULL)
  
  out = try( predict( hmod, newdata=pa, type="link", se.fit=TRUE ) )  # return on link scale

  if ( "try-error" %in% class( out ) ) return( NULL )

  pa$mean = as.vector(out$fit)
  pa$sd = as.vector(out$se.fit) # this is correct: se.fit== stdev of the mean fit: eg:  https://stat.ethz.ch/pipermail/r-help/2005-July/075856.html

  stmv_stats = list( sdTotal=sdTotal, rsquared=rsq, ndata=nrow(dat) ) # must be same order as p$statsvars .. pseudo rsquared for logistic .. for poisson {1- logLik(mod) / logLik(mod_saturated)} might be better
  
  # lattice::levelplot( mean ~ plon + plat, data=pa[pa$tiyr==2012.05,], col.regions=heat.colors(100), scale=list(draw=FALSE) , aspect="iso" )
  
  return( list( predictions=pa, stmv_stats=stmv_stats ) )  
}