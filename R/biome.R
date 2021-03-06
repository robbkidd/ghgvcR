#' Get biome data from netcdf and json files and return and/or write a config 
#' file.
#' 
#' @export
#' @importFrom jsonlite toJSON fromJSON
#'
#' @param latitude the selected latitude.
#' @param longitude the selected longitude.
#' @param biome_defaults_file full path of the name-indexed ecosystem json file.
#' @param netcdf_dir full path to the directory containing the netcdf data files.
#' @param output_dir full path of the directory to write results to.
#' @param output_filename name of file to write (without extension).
#' @param output_format format to save data in.
#' @param write boolean whether to write the data.
#' @return JSON of biome data. 
get_biome <- function(latitude, 
                      longitude,
                      biome_defaults_file,
                      netcdf_dir,
                      mapdata_dir,
                      output_dir, 
                      output_filename = "biome",
                      output_format = c("json", "cvs"),
                      write_data = TRUE) {
  if (write_data== TRUE && missing(output_dir)) 
    stop("'output_dir' cannot be missing if write_data is TRUE.")
 
  output_format <- match.arg(output_format)
  
  #convert lat/lon to floats if they are strings
  if(typeof(latitude)=="character") latitude <- as.numeric(latitude)
  if(typeof(longitude)=="character") longitude <- as.numeric(longitude)
  
  #results are a list
  res <- list()
  
  #list of data sources
  variable_query_list <- list(
    "saatchi_agb_num" = list(
      ncdir = "",
      ncfile = "saatchi.nc",
      variable = "agb_1km"
    ),
    "saatchi_bgb_num" = list(
      ncdir = "",
      ncfile = "saatchi.nc",
      variable = "bgb_1km"
    ),
    "nbcd_num" = list(
      ncdir = "",
      ncfile = "nbcd.nc",
      variable = "reprojx1"
    ),
    "soc_num" = list(
      ncdir = "",
      ncfile = "SoilCarbonDataS.nc",
      variable = "HWSDa_OC_Dens_Sub_5min.rst"
    ),
    "global_bare_latent_heat_flux_num" = list(
      ncdir = "GCS/PotVeg/Bare/",
      ncfile = "global_bare_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "global_bare_net_radiation_num" = list(
      ncdir = "GCS/PotVeg/Bare/",
      ncfile = "global_bare_rnet_10yr_avg.nc",
      variable = "rnet"
    ),
    "us_corn_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/US/Corn/",
      ncfile = "us_corn_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "us_corn_net_radiation_num" = list(
      ncdir = "GCS/Crops/US/Corn/",
      ncfile = "us_corn_rnet_10yr_avg.nc",
      variable = "netrad"
    ),
    "us_misc_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/US/MXG/",
      ncfile = "us_mxg_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "us_misc_net_radiation_num" = list(
      ncdir = "GCS/Crops/US/MXG/",
      ncfile = "us_mxg_rnet_10yr_avg.nc",
      variable = "netrad"
    ),
    "us_soy_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/US/Soybean/",
      ncfile = "us_soyb_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "us_switch_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/US/Switch/",
      ncfile = "us_switch_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "us_soybean_num" = list(
      ncdir = "GCS/Crops/US/Soybean/fractioncover/",
      ncfile = "fsoy_2.7_us.0.5deg.nc",
      variable = "fsoy"
    ),
    "us_corn_num" = list(
      ncdir = "GCS/Crops/US/Corn/fractioncover/",
      ncfile = "fcorn_2.7_us.0.5deg.nc",
      variable = "fcorn"
    ),
    "br_sugc_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/Brazil/Sugarcane/",
      ncfile = "brazil_sugc_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "br_bare_sugc_net_radiation_num" = list(
      ncdir = "GCS/Crops/Brazil/Bare/",
      ncfile = "brazil_bare_sugc_rnet_10yr_avg.nc",
      variable = "rn"
    ),
    "br_bare_sugc_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/Brazil/Bare/",
      ncfile = "brazil_bare_sugc_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "br_sugc_latent_heat_flux_num" = list(
      ncdir = "GCS/Crops/Brazil/Sugarcane/",
      ncfile = "brazil_sugc_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "braz_fractional_soybean_num" = list(
      ncdir = "GCS/Crops/Brazil/Soybean/",
      ncfile = "brazil_soyb_fractional_10yr_avg.nc",
      variable = "brzsoyrast"
    ),
    "braz_soybean_num" = list( 
      #note there was an error in previous code that pointed this to sugarcane
      ncdir = "GCS/Crops/Brazil/Soybean/",
      ncfile = "brazil_soyb_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "braz_fractional_sugarcane_num" = list(
      ncdir = "GCS/Crops/Brazil/Sugarcane/",
      ncfile = "brazil_sugc_fractional_10yr_avg.nc",
      variable = "brzSGrast"
    ),
    "braz_sugarcane_num" = list(
      ncdir = "GCS/Crops/Brazil/Sugarcane/",
      ncfile = "brazil_sugc_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "global_pasture_num" = list(
      ncdir = "GCS/",
      ncfile = "Pasture2000_5min.nc",
      variable = "farea"
    ),
    "global_cropland_num" = list(
      ncdir = "GCS/",
      ncfile = "Cropland2000_5min.nc",
      variable = "farea"
    ),
    "global_potVeg_latent_num" = list(
      ncdir = "GCS/PotVeg/PotentialVeg/",
      ncfile = "global_veg_latent_10yr_avg.nc",
      variable = "latent"
    ),
    "global_potVeg_rnet_num" = list(
      ncdir = "GCS/PotVeg/PotentialVeg/",
      ncfile = "global_veg_rnet_10yr_avg.nc",
      variable = "rnet"
    ),
    "hwsd_toc" = list(
      ncdir = "GCS/Maps/",
      ncfile = "hwsd.nc",
      variable = "t_oc"
    ),
    "hwsd_trefbulk" = list(
      ncdir = "GCS/Maps/",
      ncfile = "hwsd.nc",
      variable = "t_ref_bulk"
    ),
    "hwsd_soc" = list(
      ncdir = "GCS/Maps/",
      ncfile = "hwsd.nc",
      variable = "s_oc"
    ),
    "hwsd_srefbulk" = list(
      ncdir = "GCS/Maps/",
      ncfile = "hwsd.nc",
      variable = "s_ref_bulk"
    ),
    #Disabled per request in ruby code
    # "us_springwheat_num" = list(
    #   ncdir = "GCS/Crops/US/SpringWheat/fractioncover/",
    #   ncfile = "fswh_2.7_us.0.5deg.nc",
    #   variable = "fswh"
    # ),
    "synmap" = list(
      ncdir = "GCS/Maps/",
      ncfile = "Hurtt_SYNMAP_Global_HD_2010.nc",
      variable = "biome_type"
    ),
    "koppen" = list(
      ncdir = "GCS/Maps/",
      ncfile = "koppen_geiger.nc",
      variable = "Band1"
    ),
    "fao" = list(
      ncdir = "GCS/Maps/",
      ncfile = "gez_2010_wgs84.nc",
      variable = "gez_abbrev"
    ),
    # "ramankutty" = list(
    #   ncdir = "GCS/Maps/",
    #   ncfile = "ramankutty.nc",
    #   variable = ""
    # ),
    "ibis" = list(
      ncdir = "GCS/Maps/",
      ncfile = "vegtype.nc",
      variable = "vegtype"
    ),
    "IPCC_AGB__Mg_ha" = list(
      ncdir = "",
      ncfile = "IPCC_AGB_Mg_ha.nc",
      variable = "ipcc"
    ),
    "NACP_FI_AGB_US" = list(
      ncdir = "",
      ncfile = "NACP_FI_AGB_US.nc",
      variable = "biomass"
    ),
    "NACP_LiDAR_Boreal_AGB" = list(
      ncdir = "",
      ncfile = "NACP_LiDAR_Boreal_AGB.nc",
      variable = "AGB_Mg_ha"
    ),
    "US_Forest biomass data" = list(
      ncdir = "",
      ncfile = "US_Forest_biomass_data.nc",
      variable = "biomass"
    ),
    "SOC" = list(
      ncdir = "",
      ncfile = "SOC.nc",
      variable = "soc"
    ),
    "LiDAR_AGB_Boreal_Eurasia" = list(
      ncdir = "",
      ncfile = "LiDAR_AGB_Boreal_Eurasia.nc",
      variable = "AGB_Mg_ha"
    )
  )
  
  #iterate through the list of data sources and 
  #load the data for the lat/lon pair.
  res <- lapply(variable_query_list, function(x) { 
    get_ncdf(paste0(netcdf_dir, x$ncdir), x$ncfile, latitude, longitude, x$variable)[[x$variable]][[1]]
  })
  
  ### specific calculations based on loaded data
  # US Latent (LE)
  res$us_switch_latent_heat_flux_diff <- res$us_switch_latent_heat_flux_num - 
    res$global_bare_latent_heat_flux_num
  res$us_corn_latent_heat_flux_diff <- res$us_corn_latent_heat_flux_num  - 
    res$global_bare_latent_heat_flux_num
  res$us_soy_latent_heat_flux_diff <- res$us_soy_latent_heat_flux_num - 
    res$global_bare_latent_heat_flux_num
  res$us_misc_latent_heat_flux_diff <- res$us_misc_latent_heat_flux_num  - 
    res$global_bare_latent_heat_flux_num
  
  # US Net (Rnet)
  res$us_misc_net_radiation_diff <- res$us_misc_net_radiation_num - 
    res$global_bare_net_radiation_num
  res$us_soy_net_radiation_diff <- res$us_soy_net_radiation_num - 
    res$global_bare_net_radiation_num
  res$us_switch_net_radiation_diff <- res$us_switch_net_radiation_num - 
    res$global_bare_net_radiation_num
  res$us_corn_net_radiation_diff <- res$us_corn_net_radiation_num - 
    res$global_bare_net_radiation_num
  
  # BR Latent
  res$br_sugc_latent_heat_flux_diff <- res$br_sugc_latent_heat_flux_num  - 
    res$br_bare_sugc_latent_heat_flux_num
  
  # BR Net
  res$br_sugc_net_radiation_diff <- res$br_sugc_net_radiation_num - 
    res$br_bare_sugc_net_radiation_num 
  
  ###### Get the appropriate biome (new method)
  #read in the map data
  map_vegtypes <- read.csv(paste0(mapdata_dir, "map_vegtypes.csv"), stringsAsFactors = FALSE) 
  koppen_biomes <- read.csv(paste0(mapdata_dir, "koppen_biomes.csv"), stringsAsFactors = FALSE) 
  fao_biomes <- read.csv(paste0(mapdata_dir, "fao_biomes.csv"), stringsAsFactors = FALSE) 
  biome_defaults <- read.csv(paste0(mapdata_dir, "biome_defaults.csv"), stringsAsFactors = FALSE) 
  
  vegtype_names <- names(map_vegtypes)[4:14]
  
  #Get vegtypes based on map values
  synmap_vegtypes_df <- subset(map_vegtypes, Value == res$synmap & Map == "SYNMAP")
  koppen_vegtypes_df <- subset(map_vegtypes, Value == res$koppen & Map == "KOPPEN")
  fao_vegtypes_df <- subset(map_vegtypes, Value == tolower(res$fao) & Map == "FAO")
  ibis_vegtypes_df <- subset(map_vegtypes, Value == res$ibis & Map == "IBIS")
  #ramankutty_vegtypes <- subset(map_vegtypes, Value == res$ramankutty & Map == "RAMANKUTTY")
  
  koppen_code <- koppen_vegtypes_df$Category
  synmap_category <- synmap_vegtypes_df$Category
  
  # 1. get vegtypes for each map
  synmap_vegtypes <- vegtype_names[as.logical(array(synmap_vegtypes_df[4:14]))]
  koppen_vegtypes <- vegtype_names[as.logical(array(koppen_vegtypes_df[4:14]))]
  fao_vegtypes <- vegtype_names[as.logical(array(fao_vegtypes_df[4:14]))]
  ibis_vegtypes <- vegtype_names[as.logical(array(ibis_vegtypes_df[4:14]))]
  #ramankutty_vegtypes <- vegtype_names[as.logical(array(ramankutty_vegtypes_df[4:14]))]
  vegtypes <- na.omit(unique(c(synmap_vegtypes, koppen_vegtypes, fao_vegtypes, ibis_vegtypes)))
  
  biome_codes <- subset(koppen_biomes, Zone == koppen_code)[vegtypes]
  
  ### GET BIOME DATA
  biome_data <- list(
    "native_eco" = list(),
    "agroecosystem_eco" = list()
  )
  
  #Iterate through each biome code to load the default biome data and apply
  #other logic as needed according to:
  #"Overview of biomes mapping & assignment of default values.docx"
  for(i in 1:length(biome_codes)) {
    biome_code <- biome_codes[[i]]
    vegtype <- gsub("\\.", " ", vegtypes[[i]])
    biome <- gsub(" ", "_", vegtype)
    
    #Use FAO for Grass/Pasture Types
    if(biome_code %in% c("APX", "GX")) {
      biome_code <- subset(fao_biomes, CODE == tolower(res$fao))[[biome_code]]
    }
     
    #biome default data, depending on above selected code
    biome_default <- as.list(as.character(biome_defaults[[biome_code]])) #values

    #fix for blank biomes that are selected - hopefully remove
    if(length(biome_default) == 0) biome_default <- as.list(rep(0, nrow(biome_defaults))) 
    
    #continue on...
    names(biome_default) <- biome_defaults[['variable']] #keys
    biome_default$code <- biome_code      #keep code name for posterity
    biome_default$vegtype <- vegtype  #keep vegetation type name for posterity
    biome_default$name <- biome
    
    #Calculate OM
    hwsd_soc <- ((res$hwsd_toc/100) * 0.3 * res$hwsd_trefbulk + 
                   (res$hwsd_soc/100) * 0.7 * res$hwsd_srefbulk) * 10000
    if(biome == "Cropland") {
      biome_default$OM_SOM <- 0.43*hwsd_soc
    }
    else {
      biome_default$OM_SOM <- 0.3*hwsd_soc
      biome_default$IPCC_AGB_Mg_ha <- res$IPCC_AGB_Mg_ha
      biome_default$NACP_FI_AGB_US <- res$NACP_FI_AGB_US * 0.1736111111
      biome_default$NACP_LiDAR_Boreal_AGB <- res$NACP_LiDAR_Boreal_AGB
      biome_default$US_Forest_biomass_data <- res$US_Forest_biomass_data * 2.241244
      biome_default$LiDAR_AGB_Boreal_Eurasia <- res$LiDAR_AGB_Boreal_Eurasia
      biome_default$SOC <- res$SOC * 17.2413793103448
    }
    
    #SW Radiative Forcing
    ### Biophysical
    # If ibis_vegtypes is the same length as synmap_vegtypes, so for that vegtype
    # 
    if(vegtypes[[i]] %in% ibis_vegtypes) {
      biome_default$sw_radiative_forcing <- (res$global_potVeg_rnet_num - 
                                               res$global_bare_net_radiation_num) / 51007200000*1000000000
      biome_default$latent <- (res$global_potVeg_latent_num - 
                                 res$global_bare_latent_heat_flux_num) / 51007200000*1000000000
      biome_default$biophysical_net <- biome_default$latent 
    } 
    else {
      biome_default$sw_radiative_forcing <- 0
      biome_default$latent <- 0
      biome_default$biophysical_net <- 0
    }
    
    #Set biome type
    if(biome %in% c("Pasture", "Cropland")) {
      biome_type <- "agroecosystem_eco"
      biome_default$sw_radiative_forcing <- 0
      biome_default$latent <- 0
    } 
    else { 
      biome_type <- "native_eco"
    }
    
    ### Various fixes
    # naming
    if(biome == "Pasture") biome <- "Grassland_Pasture"
    
    # add synmap flag
    biome_default$in_synmap <- (vegtypes[[i]] %in% synmap_vegtypes)
    
    ### Add to our list of biome data
    # Add to the list of exclusions here if needed. If all exclusions don't 
    # apply, the biome is added to the biome_data.
    if(biome_default$vegtype == "Savanna" && biome_default$code != "S1") {
      #dont include if savannah and not S1 since we don't have data.
    } else {
      biome_data[[biome_type]][[biome]] <- biome_default
    }
  }
  
  ### ADD "OTHER" biomes if needed
  # TODO - note that in this line:
  # if(synmap_vegtypes$Other == 1) { stuff here... }
  
  
  ### Agricultural ecosystems
  name_indexed_ecosystems <- fromJSON(file(biome_defaults_file))
  if (!is.na(res$us_corn_num) && res$us_corn_num > 0.01) {
    biome_data$agroecosystem_eco["Maize"] <- name_indexed_ecosystems["US corn"]
  }
  if (!is.na(res$us_soybean_num) && res$us_soybean_num > 0.01) {
    biome_data$agroecosystem_eco["Soybean"] <- name_indexed_ecosystems["US soy"]
  }
  if (res$braz_fractional_soybean_num == 1 & 
      !is.na(res$br_sugc_latent_heat_flux_diff)) {
    biome_data$agroecosystem_eco["Soybean"] <- name_indexed_ecosystems["BR soy"]
  }
  if (!is.na(res$braz_sugarcane_num) & 
      res$braz_sugarcane_num > 0.01 & 
      res$braz_sugarcane_num < 110.0) {
    biome_data$agroecosystem_eco["Sugarcane"] <- name_indexed_ecosystems["BR sugarcane"]
  }
  if (res$braz_fractional_sugarcane_num == 1 & 
      !is.na(res$br_sugc_latent_heat_flux_diff)) {
    biome_data$agroecosystem_eco["Sugarcane"] <- name_indexed_ecosystems["BR sugarcane"]
  }
  if (!is.na(res$us_misc_latent_heat_flux_diff) == 1) {
    biome_data$agroecosystem_eco["Miscanthus"] <- name_indexed_ecosystems["miscanthus"]
    biome_data$biofuel_eco["Miscanthus"] <- name_indexed_ecosystems["miscanthus"]
  } 
  if (!is.na(res$us_switch_latent_heat_flux_diff) == 1) {
    biome_data$agroecosystem_eco["Switchgrass"] <- name_indexed_ecosystems["switchgrass"]
    biome_data$biofuel_eco["Switchgrass"] <- name_indexed_ecosystems["switchgrass"]
  } 
   
  # Set 0 values
  for(eco in names(biome_data$agroecosystem_eco)) {
    biome_data$agroecosystem_eco[[eco]]$OM_SOM <- 0
    biome_data$agroecosystem_eco[[eco]]$latent <- 0
    biome_data$agroecosystem_eco[[eco]]$sw_radiative_forcing <- 0
  }
  
  #write the data to a file if specified
  if (write_data == TRUE) { 
    write_ghgv(toJSON(biome_data), 
               output_dir, 
               output_filename, 
               format = output_format)
  }

  return(biome_data)
}



