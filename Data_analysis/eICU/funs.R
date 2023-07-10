#Let us first define functions to visualize the GAM fits.

plot_width <- 17.2 * 0.393701 # The textwidth of our Word manuscript in inches.
#plot_width <- 4.2126 # The Lancet asks for plots to have a width of 107mm.
font <- "Times" # Text in figures should be Times New Roman according to the Lancet.
point_size <- 10 # Per Lancet instructions


logistic <- function(x) 1/(1+exp(-x))





# Function that adds labels to subfigures, edited from:
# https://logfc.wordpress.com/2017/03/15/adding-figure-labels-a-b-c-in-the-top-left-corner-of-the-plotting-region/
fig_label <- function(label) {
  cex <- 2
  ds <- dev.size("in")
  # xy coordinates of device corners in user coordinates
  x <- grconvertX(c(0, ds[1]), from="in", to="user")
  y <- grconvertY(c(0, ds[2]), from="in", to="user")
  
  # fragment of the device we use to plot
  # account for the fragment of the device that 
  # the figure is using
  fig <- par("fig")
  dx <- (x[2] - x[1])
  dy <- (y[2] - y[1])
  x <- x[1] + dx * fig[1:2]
  y <- y[1] + dy * fig[3:4]
  
  
  sw <- strwidth(label, cex=cex) * 60/100
  sh <- strheight(label, cex=cex) * 60/100
  
  x1 <- x[1] + sw
  
  y1 <- y[2] - sh
  
  old.par <- par(xpd=NA)
  on.exit(par(old.par))
  
  text(x1, y1, label, cex=cex)
}






gam_plotMed <- function(
    gamfitMed,
    main = "Median of measurements",
    xRange = c(92, 100),
    yRange = c(0, .6),
    label
) {
  print(paste("Number of cases:", summary(gamfitMed)$n))
  
  
  if(colnames(gamfitMed$model)[1] == "mortality_in_Hospt") {
    ylab <- "Probability of hospital mortality"
  } else {
    ylab <- "Probability of ICU mortality"
  }
  
  xName <- colnames(gamfitMed$model)[grep("med", colnames(gamfitMed$model))][1]
  
  
  
  xlab <- expression("Median oxygen saturation (SpO"[2]*")")
  
  
  
  xRange <- range(lares::winsorize(gamfitMed$model[,xName], thresh = c(0.01, 0.99)))
  
  # Color for dotted line
  colD <- "black"
  
  plot(1, type = 'n', xlim = xRange, ylim = yRange, col = colD,
       ylab = ylab,
       xlab = xlab, main = main, yaxs = 'i', xaxs = 'i', yaxt = 'n', xaxt = 'n')
  
  att <- pretty(yRange)
  if(!isTRUE(all.equal(att, round(att, digits = 2)))) {
    axis(2, at = att, lab = paste0(sprintf('%.1f', att*100), '%'), las = TRUE)
  } else axis(2, at = att, lab = paste0(att*100, '%'), las = TRUE)
  
  att <- pretty(xRange)
  axis(1, at = att, lab = paste0(att, '%'), las = TRUE)
  
  
  eval(parse(text = paste(c('predictionsPlusCI <- predict(gamfitMed, newdata = data.frame(',
                            xName, ' = gamfitMed$model$', xName, ", gender = 'F', age = median(gamfitMed$model$age), ",
                            ifelse(
                              "prop" %in% colnames(gamfitMed$model),
                              "prop = median(gamfitMed$model$prop),",
                              ""
                            ),
                            ifelse(
                              "pCO2" %in% colnames(gamfitMed$model),
                              "pCO2 = median(gamfitMed$model$pCO2),",
                              ""
                            ),
                            ifelse(
                              "median_FiO2" %in% colnames(gamfitMed$model),
                              "median_FiO2 = median(gamfitMed$model$median_FiO2),",
                              ""
                            ),
                            ifelse(
                              "bmi" %in% colnames(gamfitMed$model),
                              "bmi = median(gamfitMed$model$bmi),",
                              ""
                            ),
                            ifelse(
                              "prop100" %in% colnames(gamfitMed$model),
                              "prop100 = median(gamfitMed$model$prop100),",
                              ""
                            ),
                            ifelse(
                              "Ab" %in% colnames(gamfitMed$model),
                              "Ab = median(gamfitMed$model$Ab),",
                              ""
                            ),
                            ifelse(
                              "Min" %in% colnames(gamfitMed$model),
                              "Min = median(gamfitMed$model$Min),",
                              ""
                            ),
                            ifelse(
                              "sd" %in% colnames(gamfitMed$model),
                              "sd = median(gamfitMed$model$sd),",
                              ""
                            ),
                            ifelse(
                              "high_vent_proportion" %in% colnames(gamfitMed$model),
                              "high_vent_proportion = median(gamfitMed$model$high_vent_proportion),",
                              ""
                            ),
                            ifelse(
                              "apsiii" %in% colnames(gamfitMed$model),
                              "apsiii = median(gamfitMed$model$apsiii),",
                              "sofatotal = median(gamfitMed$model$sofatotal),"
                            ),
                            ifelse(
                              "vent_duration" %in% colnames(gamfitMed$model),
                              "vent_duration = median(gamfitMed$model$vent_duration),",
                              ""
                            ),
                            "hospital_id = 264), type = 'link', se.fit = T)"), collapse = "")))
  
  
  # We have to use the data on which GAM was fit for confidence region as the GAM does not provide standard errors for 'new' input
  eval(parse(text = paste0('xx <- gamfitMed$model$', xName)))
  ord.index <- order(xx)
  xx <- xx[ord.index]
  
  if(gamfitMed$family$link == 'logit') {
    lcl <- logistic(predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index])
    ucl <- logistic(predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index])
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, logistic(predictionsPlusCI$fit[ord.index]), lwd = 1.2, col = colD)
  } else {
    lcl <- predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index]
    ucl <- predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index]
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, predictionsPlusCI$fit[ord.index], lwd = 1.2, col = colD)
  }
  
  if(!missing(label)) fig_label(label)
}


gam_plotpCO2 <- function(
    gamfitpCO2,
    main = "pCO2",
    xRange,
    yRange = c(0, .6),
    label
) {
  print(paste("Number of cases:", summary(gamfitpCO2)$n))
  
  
  if(colnames(gamfitpCO2$model)[1] == "mortality_in_Hospt") {
    ylab <- "Probability of hospital mortality"
  } else {
    ylab <- "Probability of ICU mortality"
  }
  
  xName <- colnames(gamfitpCO2$model)[grep("pCO2", colnames(gamfitpCO2$model))][1]
  
  
  
  xlab <- expression("Medain of pCO"[2]*"")
  
  
  
  xRange <- range(lares::winsorize(gamfitpCO2$model[,xName], thresh = c(0.01, 0.99)))
  
  # Color for dotted line
  colD <- "black"
  
  plot(1, type = 'n', xlim = xRange, ylim = yRange, col = colD,
       ylab = ylab,
       xlab = xlab, main = main, yaxs = 'i', xaxs = 'i', yaxt = 'n', xaxt = 'n')
  
  att <- pretty(yRange)
  if(!isTRUE(all.equal(att, round(att, digits = 2)))) {
    axis(2, at = att, lab = paste0(sprintf('%.1f', att*100), '%'), las = TRUE)
  } else axis(2, at = att, lab = paste0(att*100, '%'), las = TRUE)
  
  
  att <- pretty(xRange)
  axis(1, at = att, lab = paste0(att, 'mmHg'),las = TRUE)
  
  eval(parse(text = paste(c('predictionsPlusCI <- predict(gamfitpCO2, newdata = data.frame(',
                            xName, ' = gamfitpCO2$model$', xName, ", gender = 'F', age = median(gamfitpCO2$model$age), ",
                            ifelse(
                              "prop" %in% colnames(gamfitpCO2$model),
                              "prop = median(gamfitpCO2$model$prop),",
                              ""
                            ),
                            ifelse(
                              "pCO2" %in% colnames(gamfitpCO2$model),
                              "pCO2 = median(gamfitpCO2$model$pCO2),",
                              ""
                            ),
                            ifelse(
                              "median" %in% colnames(gamfitpCO2$model),
                              "median = median(gamfitpCO2$model$median),",
                              ""
                            ),
                            ifelse(
                              "median_FiO2" %in% colnames(gamfitpCO2$model),
                              "median_FiO2 = median(gamfitpCO2$model$median_FiO2),",
                              ""
                            ),
                            ifelse(
                              "bmi" %in% colnames(gamfitpCO2$model),
                              "bmi = median(gamfitpCO2$model$bmi),",
                              ""
                            ),
                            ifelse(
                              "prop100" %in% colnames(gamfitpCO2$model),
                              "prop100 = median(gamfitpCO2$model$prop100),",
                              ""
                            ),
                            ifelse(
                              "high_vent_proportion" %in% colnames(gamfitpCO2$model),
                              "high_vent_proportion = median(gamfitpCO2$model$high_vent_proportion),",
                              ""
                            ),
                            ifelse(
                              "apsiii" %in% colnames(gamfitpCO2$model),
                              "apsiii = median(gamfitpCO2$model$apsiii),",
                              "sofatotal = median(gamfitpCO2$model$sofatotal),"
                            ),
                            ifelse(
                              "vent_duration" %in% colnames(gamfitpCO2$model),
                              "vent_duration = median(gamfitpCO2$model$vent_duration),",
                              ""
                            ),
                            "hospital_id = 264), type = 'link', se.fit = T)"), collapse = "")))
  
  
  # We have to use the data on which GAM was fit for confidence region as the GAM does not provide standard errors for 'new' input
  eval(parse(text = paste0('xx <- gamfitpCO2$model$', xName)))
  ord.index <- order(xx)
  xx <- xx[ord.index]
  
  if(gamfitpCO2$family$link == 'logit') {
    lcl <- logistic(predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index])
    ucl <- logistic(predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index])
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, logistic(predictionsPlusCI$fit[ord.index]), lwd = 1.2, col = colD)
  } else {
    lcl <- predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index]
    ucl <- predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index]
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, predictionsPlusCI$fit[ord.index], lwd = 1.2, col = colD)
  }
  
  if(!missing(label)) fig_label(label)
}


gam_plotMedpCO2 <- function(
    gamfitpCO2,
    main = "pCO2",
    xRange,
    yRange = c(0, .6),
    label
) {
  print(paste("Number of cases:", summary(gamfitpCO2)$n))
  
  
  if(colnames(gamfitpCO2$model)[1] == "mortality_in_Hospt") {
    ylab <- "Probability of hospital mortality"
  } else {
    ylab <- "Probability of ICU mortality"
  }
  
  xName <- colnames(gamfitpCO2$model)[1]
  
  
  
  xlab <- expression("Interaction term of SpO"[2]*", pCO"[2]*"")
  
  
  xRange <- range(lares::winsorize(gamfitpCO2$model[,xName], thresh = c(0.01, 0.99)))
  
  # Color for dotted line
  colD <- "black"
  
  plot(1, type = 'n', xlim = xRange, ylim = yRange, col = colD,
       ylab = ylab,
       xlab = xlab, main = main, yaxs = 'i', xaxs = 'i', yaxt = 'n', xaxt = 'n')
  
  att <- pretty(yRange)
  if(!isTRUE(all.equal(att, round(att, digits = 2)))) {
    axis(2, at = att, lab = paste0(sprintf('%.1f', att*100), '%'), las = TRUE)
  } else axis(2, at = att, lab = paste0(att*100, '%'), las = TRUE)
  
  
  att <- pretty(xRange)
  axis(1, at = att, las = TRUE)
  
  eval(parse(text = paste(c('predictionsPlusCI <- predict(gamfitpCO2, newdata = data.frame(',
                            xName, ' = gamfitpCO2$model$', xName, ", gender = 'F', age = median(gamfitpCO2$model$age), ",
                            ifelse(
                              "prop" %in% colnames(gamfitpCO2$model),
                              "prop = median(gamfitpCO2$model$prop),",
                              ""
                            ),
                            ifelse(
                              "pCO2" %in% colnames(gamfitpCO2$model),
                              "pCO2 = median(gamfitpCO2$model$pCO2),",
                              ""
                            ),
                            ifelse(
                              "median" %in% colnames(gamfitpCO2$model),
                              "median = median(gamfitpCO2$model$median),",
                              ""
                            ),
                            ifelse(
                              "median_FiO2" %in% colnames(gamfitpCO2$model),
                              "median_FiO2 = median(gamfitpCO2$model$median_FiO2),",
                              ""
                            ),
                            ifelse(
                              "bmi" %in% colnames(gamfitpCO2$model),
                              "bmi = median(gamfitpCO2$model$bmi),",
                              ""
                            ),
                            ifelse(
                              "prop100" %in% colnames(gamfitpCO2$model),
                              "prop100 = median(gamfitpCO2$model$prop100),",
                              ""
                            ),
                            ifelse(
                              "high_vent_proportion" %in% colnames(gamfitpCO2$model),
                              "high_vent_proportion = median(gamfitpCO2$model$high_vent_proportion),",
                              ""
                            ),
                            ifelse(
                              "apsiii" %in% colnames(gamfitpCO2$model),
                              "apsiii = median(gamfitpCO2$model$apsiii),",
                              "sofatotal = median(gamfitpCO2$model$sofatotal),"
                            ),
                            ifelse(
                              "vent_duration" %in% colnames(gamfitpCO2$model),
                              "vent_duration = median(gamfitpCO2$model$vent_duration),",
                              ""
                            ),
                            "hospital_id = 264), type = 'link', se.fit = T)"), collapse = "")))
  
  
  # We have to use the data on which GAM was fit for confidence region as the GAM does not provide standard errors for 'new' input
  eval(parse(text = paste0('xx <- gamfitpCO2$model$', xName)))
  ord.index <- order(xx)
  xx <- xx[ord.index]
  
  if(gamfitpCO2$family$link == 'logit') {
    lcl <- logistic(predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index])
    ucl <- logistic(predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index])
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, logistic(predictionsPlusCI$fit[ord.index]), lwd = 1.2, col = colD)
  } else {
    lcl <- predictionsPlusCI$fit[ord.index] - 1.96*predictionsPlusCI$se.fit[ord.index]
    ucl <- predictionsPlusCI$fit[ord.index] + 1.96*predictionsPlusCI$se.fit[ord.index]
    
    lines(x = xx, y = lcl, lty = 2, lwd = 1, col = colD)
    lines(x = xx, y = ucl, lty = 2, lwd = 1, col = colD)
    lines(xx, predictionsPlusCI$fit[ord.index], lwd = 1.2, col = colD)
  }
  
  if(!missing(label)) fig_label(label)
}








##CI function-----
CI_fun <- function(x){
  
  z <- qnorm(0.975) 
  
  coef_se <- sqrt(diag(vcov(x)))
  
  log_ci_lower <- coef(x) - z * coef_se
  log_ci_upper <- coef(x) + z * coef_se
  
  return(rbind(exp(0.1*log_ci_lower)[2], exp(0.1*coef(x))[2],  exp(0.1*log_ci_upper)[2]))
  
  
  
}
##Function for GAM proportion adjusted model 

GAM_proportion <- function(Data){
  
  z <- qnorm(0.975) 
  
  COPD_adj_model_list <- list()
  
  for (i in 0:8) {
    
    var_name <- paste0("prop", i)
    
    formula_str <- paste("mortality_in_Hospt ~ ", var_name, " + gender + s(age) + s(vent_duration) + s(sofatotal)")
    
    formula_obj <- as.formula(formula_str)
    
    COPD_adj_model_list[[i+1]] <- gamm(formula_obj,  data = Data, family = binomial, 
                                       random = list(hospital_id = ~ 1), niterPQL=50)$gam
    
    
    ##Fit models and calculate 95% CI
    
    Re <- t(sapply(COPD_adj_model_list, CI_fun))
    
  }
  
  colnames(Re) <- c("lower", "estimation", "upper")
  
  return(Re)
  
}



##CI plot
plot_CI <- function(x, CI, lty = 1, col = 1) {
  
  # Draw the credible interval
  lines(x = rep(x, 2), y = CI[-2], lty = lty, lwd = 2, col = col)
  
  # Add horizontal delimters to both end of the credible interval
  for (y in CI[-2]) lines(
    x = c(x - x_offset / 4, x + x_offset / 4),
    y = rep(y, 2),
    lwd = 2,
    col = col
  )
  
  # Add a dot at the posterior mean
  points(x = x, y = CI[2], col = col, pch = 19)
  
}



