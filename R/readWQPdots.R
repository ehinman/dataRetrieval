#'
#' Format and organize WQP arguments that are passed in as \code{...}.
#'
#' @keywords internal
readWQPdots <- function(..., legacy = TRUE) {
  
  if (length(list(...)) == 0) {
    stop("No arguments supplied")
  }

  matchReturn <- convertLists(...)

  if ("service" %in% names(matchReturn)) {
    service <- matchReturn$service
    matchReturn$service <- NULL
  } else {
    if(legacy){
      service <- "Result"
    } else {
      service <- "ResultWQX3"
    }
    
  }
  
  if ("dataProfile" %in% names(matchReturn)) {
    profile <- matchReturn$dataProfile
    if (profile == "activityAll") {
      service <- "ActivityWQX3"
      matchReturn$service <- NULL
    } else if (profile %in% c("resultPhysChem","biological","narrowResult")) {
      service <- "Result"
      matchReturn$service <- NULL
    } else if(profile %in% c("fullPhysChem", "narrow", "basicPhysChem")){
      service <- "ResultWQX3"
      matchReturn$service <- NULL      
    } 
  } 
  
  match.arg(service, c(
    "Result", "Station", "Activity", "Organization",
    "ActivityMetric", "SiteSummary",
    "Project", "ProjectMonitoringLocationWeighting",
    "ResultDetectionQuantitationLimit", "BiologicalMetric",
    "ResultWQX3", "StationWQX3", "ActivityWQX3"
  ))
  
  names(matchReturn)[names(matchReturn) == "bbox"] <- "bBox"
    
  bbox <- "bBox" %in% names(matchReturn)
  if(bbox){
    values_bbox <- sapply(matchReturn["bBox"], function(x) as.character(paste0(eval(x), collapse = ",")))
    matchReturn <- matchReturn[names(matchReturn) != "bBox"]
  }
  
  if(!legacy){
    new_list <- rep(list(NA),length(unlist(matchReturn)))
    names_list <- c()
    i <- 1
    for(arg in names(matchReturn)){
      for(val in as.character(matchReturn[[arg]])) {
        new_list[[i]] <- val
        names_list <- c(names_list, arg)
        i <- i + 1
      }
    }
    names(new_list) <- names_list
    matchReturn <- new_list
  }
  
  values <- sapply(matchReturn, function(x) as.character(paste0(eval(x), collapse = ";")))
  
  if (bbox) {
    values <- c(values, values_bbox)
  }
  
  values <- checkWQPdates(values)

  names(values)[names(values) == "siteNumber"] <- "siteid"
  names(values)[names(values) == "siteNumbers"] <- "siteid"
  names(values)[names(values) == "parameterCd"] <- "pCode"
  names(values)[names(values) == "USGSPCode"] <- "pCode"
  

  names(values)[names(values) == "stateCd"] <- "statecode"
  if ("statecode" %in% names(values)) {
    stCd <- values["statecode"]
    stCdPrefix <- "US:"
    if (!grepl(stCdPrefix, stCd)) {
      values["statecode"] <- paste0(stCdPrefix, zeroPad(stateCdLookup(stCd, "id"), 2))
    }
  }

  names(values)[names(values) == "countyCd"] <- "countycode"
  if (all(c("countycode", "statecode") %in% names(values))) {
    stCd <- gsub("US:", "", values["statecode"])
    # This will error if more than 1 state is requested
    # It's possible that someone could request more than one state
    # in WQP, but if they also then request county codes,
    # it gets really confusing, and the WQP developers don't recommend.
    values["countycode"] <- paste(values["statecode"],
      countyCdLookup(stCd, values["countycode"], "id"),
      sep = ":"
    )
  }

  return(list(values = values, service = service))
}

