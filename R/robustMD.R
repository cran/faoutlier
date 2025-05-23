#' Robust Mahalanobis
#'
#' Obtain Mahalanobis distances using the robust
#' computing methods found in the \code{MASS} package. This function is generally only applicable
#' to models with continuous variables.
#'
#' @aliases robustMD
#' @param data matrix or data.frame
#' @param method type of estimation for robust means and covariance
#'   (see \code{\link[MASS]{cov.rob}})
#' @param digits number of digits to round in the final result
#' @author Phil Chalmers \email{rphilip.chalmers@@gmail.com}
#' @seealso
#'   \code{\link{gCD}}, \code{\link{obs.resid}}, \code{\link{LD}}
#' @references
#'
#' Chalmers, R. P. & Flora, D. B. (2015). faoutlier: An R Package for Detecting
#'   Influential Cases in Exploratory and Confirmatory Factor Analysis.
#'   \emph{Applied Psychological Measurement, 39}, 573-574. \doi{10.1177/0146621615597894}
#'
#' Flora, D. B., LaBrish, C. & Chalmers, R. P. (2012). Old and new ideas for data
#' screening and assumption testing for exploratory and confirmatory factor analysis.
#'  \emph{Frontiers in Psychology, 3}, 1-21. \doi{10.3389/fpsyg.2012.00055}
#' @keywords covariance
#' @export robustMD
#' @examples
#'
#' \dontrun{
#' data(holzinger)
#' output <- robustMD(holzinger)
#' output
#' plot(output)
#' plot(output, type = 'qqplot')
#' }
robustMD <- function(data, method = 'mve', ...)
{
	ret <- list()
	id <- 1:nrow(data)
	rownames(data) <- id
	rob <- MASS::cov.rob(data, method = method, ...)
	ret$ID <- id
	ret$mah <- mahalanobis(data, rob$center, rob$cov)
	ret$mah_p <- pchisq(ret$mah, ncol(data), lower.tail = FALSE)
	ret$normmah <- mahalanobis(data, colMeans(data), cov(data))
	ret$normmah_p <- pchisq(ret$normmah, ncol(data),
		lower.tail = FALSE)
	ret$J <- ncol(data)
	class(ret) <- 'robmah'
	ret
}

#' @rdname robustMD
#' @param x an object of class \code{robmah}
#' @param ncases number of extreme cases to print
#' @param ... additional arguments to pass to \code{MASS::cov.rob()}
#' @export
print.robmah <- function(x, ncases = 10, digits = 5, ...)
{
    object <- x
    p <- object$mah_p
    t0 <- ifelse(p < .0001, 1,0)
    t1 <- ifelse(p < .001, 1, 0)
    t2 <- ifelse(p < .01, 1, 0)
    t3 <- ifelse(p < .05, 1, 0)
    nstar <- t0 + t1 + t2 + t3
    nstar[nstar == 0] <- "."
    nstar[nstar == 1] <- "*"
    nstar[nstar == 2] <- "**"
    nstar[nstar == 3] <- "***"
    nstar[nstar == 4] <- "****"
    ret <- data.frame(mah=round(object$mah, digits), p=round(object$mah_p, digits), sig=nstar)
    ret <- ret[order(ret$mah, decreasing = TRUE), ]
    ret <- ret[1:ncases, ]
    print(ret, quote = FALSE)
    invisible(ret)
}

#' @param y empty parameter passed to \code{plot}
#' @param type type of plot to display, can be either \code{'qqplot'} or \code{'xyplot'}
#' @param main title for plot. If missing titles will be generated automatically
#' @rdname robustMD
#' @export
plot.robmah <- function(x, y = NULL, type = 'xyplot', main, ...){
	mah <- x$mah
	N <- length(mah)
	J <- x$J
    if(missing(main))
        main <- ifelse(type == 'qqplot', 'QQ plot', 'Robust MD')
    if(type == 'qqplot'){
        dat <- data.frame(theoryQQ = qchisq(ppoints(N),df=J), mah=mah)
        return(lattice::qqmath(~mah, data=dat, prepanel = prepanel.qqmathline, main = main,
               panel = function(x, ...) {
                   panel.qqmathline(x, ...)
                   panel.qqmath(x, ...)
               }, ...))
    }
    if(type == 'xyplot'){
        dat <- data.frame(mah=mah, ID=x$ID)
        return(lattice::xyplot(mah~ID, dat, main = main, type = c('p', 'h'), ...))
    }
}
