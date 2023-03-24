using Arrow, DataFrames, DataFramesMeta, Dates
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

LTS(T1000, T700) = T700 * (1000/700)^0.286 - T1000 * (1000/1000)^0.286  #### Lower tropospheric Stability #####

function EIS(T1000, T700, RH=0.8) ### Estimated inversion strenght from WOOD and BRETHERTON, 2006 ####
    # T700: temperature at 700 hpa, in K
    # T1000: temperature at 1000 hpa, in K
    # RH is assumed to be approx 0.8 over the oceans between 60NS, from wood and bretherton
    g  = 9.81       # m s−2
    cp = 1.005e3    # J/kg K
    Ra = 287.04     # J/kg/K 
    Rv = 461        # J/kg/K 
    Lv = 2.26e6     # J/kg

    ### 700 hpa height and lifting condensation level height
    z700 = Ra * T1000/g * log( 1000 / 700 )
    zLCL = (20 + ( (T1000 - 273.15) / 5) ) * ( 100 - RH * 10 )        # From Lawerence, 2005, BAMS

    # moist adiabat at 850 hpa to apprimate the full profile
    p    = 850    # hpa
    T850 = ( T1000 + T700 ) / 2                                   # approximate the 850 temp
    es   = 6.11exp( 17.269 * (T850 - 273.15) / (T850 - 35.86) )   # Murray, F. W. 1967.
    qs   = 621.97 * es / (p - es)
    Γ850 = (g / cp) * ( 1 -  ( 1 + Lv * qs / ( Ra * T850 ) ) / ( 1 + Lv^2 * qs / ( cp * Rv * T850^2 )  ) )

    return LTS(T1000,T700) - Γ850 * (z700 - zLCL)
end