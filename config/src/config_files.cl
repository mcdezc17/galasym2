procedure config_files()

struct *list

begin

    struct line
    string tmp_infile, tmp_outfile
    string cold_config, hot_config, third_config
    string psf_name
    real aperture_ref

    # temporal:
    string tmp_string
    real aper_1, aper_2, aper_3

    string key_word
    # -------- Declaracion de variables para pset 'datapar' -----------
    bool   single_data
    string pathname_data

    # -------- Declaracion de variables para pset 'photimg' --------
    struct n_apert_phot
    real   saturlev_phot
    string saturkey_phot
    real   mag_zero_phot
    real   gain_lev_phot
    string gain_key_phot
    real   pix_scal_phot
    real   seeingfw_phot

    # -------- Declaracion de variables para pset 'sexpar' --------
    # --- cold mode ---
    int    minarea_se, maxarea_se
    real   dthresh_se, athresh_se
    bool   bfilter_se
    string namefilt_se
    real   dmincont_se
    bool   cleanspu_se
    real   cleanpar_se
    string weightty_se, weightim_se
    int    backsize_se, bckfilsz_se
    string verbotyp_se
    # --- hot mode ---
    int    ht_minarea_se
    real   ht_dthresh_se
    real   ht_dmincont_se
    real   ht_cleanpar_se

    # -------- Declaracion de variables para pset 'psfexp' --------
    bool   defaultf_psf
    real   dthresh_psf, athresh_psf
    string img_name_psf

    # Lectura de parametros:
    list = "data/data_files/full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            # Captura primer valor de la linea
            print(line) | scan(key_word)

            # ================================================
            # OBTENER VALORES DE PSET: datapar
            # ================================================
            # lectura del tipo de entrada de imagen:
            if(key_word == "SINGLE_TYPE"){print(line) | scan(key_word, single_data)}
            # lectura de
            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            # ================================================
            # OBTENER VALORES DE PSET: photimg
            # ================================================
            # lectura de
            if(key_word == "PHOT_APERTURES"){print(line) | scan(key_word, n_apert_phot)}
            # lectura de
            if(key_word == "SATUR_LEVEL"){print(line) | scan(key_word, saturlev_phot)}
            # lectura de
            if(key_word == "SATUR_KEY"){print(line) | scan(key_word, saturkey_phot)}
            # lectura de
            if(key_word == "MAG_ZEROPOINT"){print(line) | scan(key_word, mag_zero_phot)}
            # lectura de
            if(key_word == "GAIN"){print(line) | scan(key_word, gain_lev_phot)}
            # lectura de
            if(key_word == "GAIN_KEY"){print(line) | scan(key_word, gain_key_phot)}
            # lectura de
            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pix_scal_phot)}
            # lectura de
            if(key_word == "SEEING_FWHM"){print(line) | scan(key_word, seeingfw_phot)}

            # ================================================
            # OBTENER VALORES DE PSET: sexpar
            # ================================================
            # lectura de
            if(key_word == "DETECT_MINAREA"){print(line) | scan(key_word, minarea_se)}
            # lectura de
            if(key_word == "DETECT_MAXAREA"){print(line) | scan(key_word, maxarea_se)}
            # lectura de
            if(key_word == "DETECT_THRESH"){print(line) | scan(key_word, dthresh_se)}
            # lectura de
            if(key_word == "ANALYSIS_THRESH"){print(line) | scan(key_word, athresh_se)}
            # lectura de
            if(key_word == "FILTER"){print(line) | scan(key_word, bfilter_se)}
            # lectura de
            if(key_word == "FILTER_NAME"){print(line) | scan(key_word, namefilt_se)}
            # lectura de
            if(key_word == "DEBLEND_MINCONT"){print(line) | scan(key_word, dmincont_se)}
            # lectura de
            if(key_word == "CLEAN"){print(line) | scan(key_word, cleanspu_se)}
            # lectura de
            if(key_word == "CLEAN_PARAM"){print(line) | scan(key_word, cleanpar_se)}
            # lectura de
            # if(key_word == "WEIGHT_TYPE"){print(line) | scan(key_word, weightty_se)}
            # lectura de
            # if(key_word == "WEIGHT_IMAGE"){print(line) | scan(key_word, weightim_se)}
            # lectura de
            if(key_word == "BACK_SIZE"){print(line) | scan(key_word, backsize_se)}
            # lectura de
            if(key_word == "BACK_FILTERSIZE"){print(line) | scan(key_word, bckfilsz_se)}
            # lectura de
            if(key_word == "VERBOSE_TYPE"){print(line) | scan(key_word, verbotyp_se)}

            # ------------ HOT MODE DEXTRACTIONS --------------
            # lectura de
            if(key_word == "HT_DETECT_MINAREA"){print(line) | scan(key_word, ht_minarea_se)}
            # lectura de
            if(key_word == "HT_DETECT_THRESH"){print(line) | scan(key_word, ht_dthresh_se)}
            # lectura de
            if(key_word == "HT_DEBLEND_MINCONT"){print(line) | scan(key_word, ht_dmincont_se)}
            # lectura de
            if(key_word == "HT_CLEAN_PARAM"){print(line) | scan(key_word, ht_cleanpar_se)}

            # ================================================
            # OBTENER VALORES DE PSET: psfex
            # ================================================
            # lectura de
            if(key_word == "DFLT_PSF"){print(line) | scan(key_word, defaultf_psf)}
            # lectura de
            if(key_word == "DTHRESH_PSF"){print(line) | scan(key_word, dthresh_psf)}
            # lectura de
            if(key_word == "ATHRES_PSF"){print(line) | scan(key_word, athresh_psf)}
            # lectura de
            if(key_word == "IMG_NAME"){print(line) | scan(key_word, img_name_psf)}

        #END IF: lineas validas
        }
    # END WHILE: lecture list
    }
    list = ""

    # Nombre de imagen o carpeta de imagenes:
    if(single_data == no){
            pathname_data = "images_folder: "//pathname_data
    }

    # ==============================================================================================
    # ESCRITURA DE CATALOGOS:
    # ==============================================================================================
    if(defaultf_psf == no){

        # DIRECTORO SALIDA DE PSFEX:
        # if(!access("data")){mkdir("data")}
        # if(!access("data/results_psfex")){mkdir("data/results_psfex")}

        # ==============================================================================================
        # SEXTRACTOR PRE-PSFEX CONFIG FILE
        # ==============================================================================================

        tmp_outfile = "config/psfex/prepsfex/my_prepsfex.sex"

        print("# Simple configuration file for SExtractor prior to PSFEx use", > tmp_outfile)
        print("# only non-default parameters are present.", >> tmp_outfile)
        printf("# FOR GALASYM2 ANALYSIS IMG: %s\n", pathname_data, >> tmp_outfile)
        print("# DATE 190925", >> tmp_outfile)

        print("\n#-------------------------------- Catalog ------------------------------------", >> tmp_outfile)

        print("\nCATALOG_NAME    data/results_psfex/my_prepsfex.cat", >> tmp_outfile)
        print("CATALOG_TYPE     FITS_LDAC", >> tmp_outfile)
        print("PARAMETERS_NAME  config/psfex/prepsfex/prepsfex.param", >> tmp_outfile)

        print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

        print("\nDETECT_MINAREA   3", >> tmp_outfile)
        printf("DETECT_THRESH    %s\n", dthresh_psf, >> tmp_outfile)
        printf("ANALYSIS_THRESH  %s\n", athresh_psf, >> tmp_outfile)

        print("\nFILTER           Y", >> tmp_outfile)
        print("FILTER_NAME      config/psfex/prepsfex/default.conv", >> tmp_outfile)

        print("\n#-------------------------------- WEIGHTing ----------------------------------", >> tmp_outfile)
        print("#-------------------------------- FLAGging -----------------------------------", >> tmp_outfile)
        print("#------------------------------ Photometry -----------------------------------", >> tmp_outfile)

        print("\nPHOT_FLUXFRAC  0.5", >> tmp_outfile)

        aperture_ref = (5 + 0.1) / pix_scal_phot

        printf("\nPHOT_APERTURES  %s\n", aperture_ref, >> tmp_outfile)
        printf("SATUR_LEVEL     %s\n", saturlev_phot, >> tmp_outfile)
        printf("MAG_ZEROPOINT   %s\n", mag_zero_phot, >> tmp_outfile)
        printf("GAIN            %s\n", gain_lev_phot, >> tmp_outfile)
        printf("\nVERBOSE_TYPE %s\n", verbotyp_se, >> tmp_outfile)

        # ==============================================================================================
        # PSFEX CONFIG FILE
        # ==============================================================================================
        tmp_outfile = "config/psfex/my_default.psfex"

        print("# Default configuration file for PSFEx 3.9.0", > tmp_outfile)
        printf("# FOR GALASYM ANALYSIS IMG: %s\n", pathname_data, >> tmp_outfile)
        print("# DATE 190925", >> tmp_outfile)

        print("\n#-------------------------------- PSF model ----------------------------------", >> tmp_outfile)

        print("\nBASIS_TYPE      PIXEL_AUTO", >> tmp_outfile)
        print("BASIS_NUMBER    20", >> tmp_outfile)
        print("PSF_SAMPLING    0.0", >> tmp_outfile)
        print("PSF_ACCURACY    0.01", >> tmp_outfile)
        print("PSF_SIZE        25,25", >> tmp_outfile)
        print("CENTER_KEYS     X_IMAGE,Y_IMAGE", >> tmp_outfile)
        print("PHOTFLUX_KEY    FLUX_APER(1)", >> tmp_outfile)
        print("PHOTFLUXERR_KEY FLUXERR_APER(1)", >> tmp_outfile)

        print("\n#----------------------------- PSF variability -----------------------------", >> tmp_outfile)

        print("\nPSFVAR_KEYS     X_IMAGE,Y_IMAGE", >> tmp_outfile)
        print("PSFVAR_GROUPS   1,1", >> tmp_outfile)
        print("PSFVAR_DEGREES  2", >> tmp_outfile)

        print("\n#----------------------------- Sample selection ------------------------------", >> tmp_outfile)

        print("\nSAMPLE_AUTOSELECT    Y", >> tmp_outfile)
        print("SAMPLEVAR_TYPE       SEEING", >> tmp_outfile)
        print("SAMPLE_FWHMRANGE     2.0,10.0", >> tmp_outfile)
        print("SAMPLE_VARIABILITY   0.2", >> tmp_outfile)
        print("SAMPLE_MINSN         20", >> tmp_outfile)
        print("SAMPLE_MAXELLIP      0.3", >> tmp_outfile)

        print("\n#------------------------------- Check-plots ----------------------------------", >> tmp_outfile)

        print("\nCHECKPLOT_DEV       PNG", >> tmp_outfile)

        print("\nCHECKPLOT_RES       0", >> tmp_outfile)
        print("CHECKPLOT_ANTIALIAS Y", >> tmp_outfile)
        print("CHECKPLOT_TYPE      FWHM,ELLIPTICITY,COUNTS,COUNT_FRACTION,CHI2,RESIDUALS # or NONE", >> tmp_outfile)
        print("CHECKPLOT_NAME      data/results_psfex/fwhm.png, data/results_psfex/ellipticity.png, data/results_psfex/counts.png, data/results_psfex/countfrac.png, data/results_psfex/chi2.png, data/results_psfex/resi.png", >> tmp_outfile)

        print("\n#------------------------------ Check-Images ---------------------------------", >> tmp_outfile)

        print("\nCHECKIMAGE_TYPE CHI,PROTOTYPES,SAMPLES,RESIDUALS,SNAPSHOTS,MOFFAT,-MOFFAT,-SYMMETRICAL", >> tmp_outfile)

        print("\nCHECKIMAGE_NAME data/results_psfex/chi.fits, data/results_psfex/proto.fits, data/results_psfex/samp.fits, data/results_psfex/resi.fits, data/results_psfex/snap.fits, data/results_psfex/moffat.fits, data/results_psfex/submoffat.fits, data/results_psfex/subsym.fits", >> tmp_outfile)

        print("\n#----------------------------- Miscellaneous ---------------------------------", >> tmp_outfile)

        print("\nPSF_DIR         data/results_psfex", >> tmp_outfile)
        print("PSF_SUFFIX      .psf", >> tmp_outfile)
        print("VERBOSE_TYPE    NORMAL", >> tmp_outfile)
        print("WRITE_XML       Y", >> tmp_outfile)
        print("XML_NAME        data/results_psfex/psfex.xml", >> tmp_outfile)
        print("NTHREADS        0", >> tmp_outfile)

        psf_name = "data/results_psfex/my_prepsfex.psf"


    # END  IF (default_psf==no)
    }else{

        # SI USA ('default.psf') PSF POR DEFECTO, ESCRIBIR EN SEXTRACTOR CONFIG FILE:
        psf_name = "config/sextractor/default.psf"
    }

    # ==============================================================================================
    # SEXTRACTOR CONFIG FILE
    # ==============================================================================================

    cold_config = "config/sextractor/cold_default.sex"

    print("# Default configuration file for SExtractor 2.28.0", > cold_config)
    printf("# FOR GALASYM ANALYSIS IMG: %s\n", pathname_data, >> cold_config)

    print("\n#-------------------------------- FLAGging -----------------------------------", >> cold_config)

    print("\nFLAG_IMAGE flag.fits", >> cold_config)
    print("FLAG_TYPE OR", >> cold_config)

    print("\n#----------------------- Differential Geometry Map ---------------------------", >> cold_config)

    print("\nDGEO_TYPE NONE", >> cold_config)
    print("DGEO_IMAGE dgeo.fits", >> cold_config)

    print("\n#------------------------------ Photometry -----------------------------------", >> cold_config)

    line = n_apert_phot
    print(line) | scan (aper_1, aper_2, aper_3)
    aper_1 = aper_1 / pix_scal_phot
    aper_2 = aper_2 / pix_scal_phot
    aper_3 = aper_3 / pix_scal_phot

    printf("%.2f, %.2f, %.2f", aper_1, aper_2, aper_3) | scan(n_apert_phot)

    printf("\nPHOT_APERTURES %s\n", n_apert_phot, >> cold_config)
    print("PHOT_AUTOPARAMS 2.5, 3.5", >> cold_config)
    print("PHOT_PETROPARAMS 2.0, 3.5", >> cold_config)

    print("\nPHOT_AUTOAPERS 0.0,0.0", >> cold_config)

    print("\nPHOT_FLUXFRAC 0.2 0.5 0.8", >> cold_config)

    printf("\nSATUR_LEVEL %s\n", saturlev_phot, >> cold_config)
    printf("SATUR_KEY %s\n", saturkey_phot, >> cold_config)

    printf("\nMAG_ZEROPOINT %s\n", mag_zero_phot, >> cold_config)
    print("MAG_GAMMA 4.0", >> cold_config)
    printf("GAIN %s\n", gain_lev_phot, >> cold_config)
    printf("GAIN_KEY %s\n", gain_key_phot, >> cold_config)
    printf("PIXEL_SCALE %s\n", pix_scal_phot, >> cold_config)

    print("\n#------------------------- Star/Galaxy Separation ----------------------------", >> cold_config)

    printf("\nSEEING_FWHM %s\n", seeingfw_phot, >> cold_config)
    print("STARNNW_NAME config/sextractor/default.nnw", >> cold_config)

    print("\n#------------------------------ Background -----------------------------------", >> cold_config)

    print("\nBACK_TYPE MANUAL", >> cold_config) # def=AUTO
    print("BACK_VALUE 0.0", >> cold_config)
    print("BACK_PEARSON 2.5", >> cold_config)

    printf("\nBACK_SIZE %s\n", backsize_se, >> cold_config)
    printf("BACK_FILTERSIZE %s\n", bckfilsz_se, >> cold_config)

    print("\nBACKPHOTO_TYPE GLOBAL", >> cold_config)
    print("BACKPHOTO_THICK 24", >> cold_config)
    print("BACK_FILTTHRESH 0.0", >> cold_config)

    print("\n#--------------------- Memory (change with caution!) -------------------------", >> cold_config)

    print("\nMEMORY_OBJSTACK 3000", >> cold_config)
    print("MEMORY_PIXSTACK 300000", >> cold_config)
    print("MEMORY_BUFSIZE 1024", >> cold_config)

    print("\n#------------------------------- ASSOCiation ---------------------------------", >> cold_config)

    print("\nASSOC_NAME sky.list", >> cold_config)
    print("ASSOC_DATA 2,3,4", >> cold_config)
    print("ASSOC_PARAMS 2,3,4", >> cold_config)
    print("ASSOCCOORD_TYPE PIXEL", >> cold_config)
    print("ASSOC_RADIUS 2.0", >> cold_config)
    print("ASSOC_TYPE NEAREST", >> cold_config)

    print("\nASSOCSELEC_TYPE MATCHED", >> cold_config)

    print("\n#----------------------------- Miscellaneous ---------------------------------", >> cold_config)

    printf("\nVERBOSE_TYPE %s\n", verbotyp_se, >> cold_config)
    print("HEADER_SUFFIX .head", >> cold_config)
    print("WRITE_XML N", >> cold_config)
    print("XML_NAME data/results_sex/sex.xml", >> cold_config)
    print("XSL_URL file:///usr/local/share/sextractor/sextractor.xsl", >> cold_config)

    print("\nNTHREADS 1", >> cold_config)

    print("\nFITS_UNSIGNED N", >> cold_config)
    print("INTERP_MAXXLAG 16", >> cold_config)
    print("INTERP_TYPE ALL", >> cold_config)

    print("\n#--------------------------- Experimental Stuff -----------------------------", >> cold_config)

    printf("\nPSF_NAME %s\n", psf_name, >> cold_config)
    print("PSF_NMAX 1", >> cold_config)
    print("PATTERN_TYPE RINGS-HARMONIC", >> cold_config)

    print("\nSOM_NAME default.som", >> cold_config)

    print("\n#------------------------------- Extraction ----------------------------------", >> cold_config)

    print("\nDETECT_TYPE CCD", >> cold_config)
    print("THRESH_TYPE RELATIVE", >> cold_config)

    # (TRASLADADO A OTROS .CL A DEFINIR) printf("\nDETECT_THRESH %s\n", dthresh_se, >> cold_config)
    printf("ANALYSIS_THRESH %.4f\n", athresh_se, >> cold_config)

    if(bfilter_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nFILTER %s\n", tmp_string, >> cold_config)

    print("FILTER_THRESH", >> cold_config)

    print("\nDEBLEND_NTHRESH 32", >> cold_config)

    if(cleanspu_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nCLEAN %s\n", "Y", >> cold_config)

    print("\nMASK_TYPE CORRECT", >> cold_config)

    print("\n#---------------------------- DIFERENCIA DE CONFIGURACION -------------------------------", >> cold_config)

    # ******************************************************************************************************************
    # ********************* TO SAHPE INDEX  ****************************************************************************
    # ******************************************************************************************************************
    copy(cold_config, "config/sextractor/my_shape.sex")

    # ******************************************************************************************************************
    # ********************* SECOND SEXTRACTION CONFIGURATION-FILE ******************************************************
    # ******************************************************************************************************************

    hot_config = "config/sextractor/hot_default.sex"
    copy(cold_config, hot_config)

    print("\n#-------------------------------- Catalog ------------------------------------", >> hot_config)

    print("\nCATALOG_NAME data/results_sex/hot_test.cat", >> hot_config)
    print("CATALOG_TYPE ASCII_HEAD", >> hot_config)

    print("\nPARAMETERS_NAME config/sextractor/default.param", >> hot_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME config/sextractor/%s\n", namefilt_se, >> hot_config)

    printf("DETECT_MINAREA %d\n", ht_minarea_se, >> hot_config)
    print("DETECT_MAXAREA 0", >> hot_config)
    printf("\nDETECT_THRESH %.4f\n", ht_dthresh_se, >> hot_config)
    printf("DEBLEND_MINCONT   %.6f\n", ht_dmincont_se, >> hot_config)
    printf("CLEAN_PARAM %.3f\n", ht_cleanpar_se, >> hot_config)

    print("\n#------------------------------ Check Image ----------------------------------", >> hot_config)

    print("\nCHECKIMAGE_TYPE SEGMENTATION", >> hot_config)

    print("\nCHECKIMAGE_NAME data/results_sex/hot_seg.fits", >> hot_config)

    # ******************************************************************************************************************

    # ******************************************************************************************************************
    # ********************** THIRD SEXTRACTION CONFIGURATION-FILE ******************************************************
    # ******************************************************************************************************************

    third_config = "config/sextractor/third_config.sex"
    copy(cold_config, third_config)

    print("\n#-------------------------------- Catalog ------------------------------------", >> third_config)

    print("\nCATALOG_NAME data/results_sex/third_test.cat", >> third_config)
    print("CATALOG_TYPE ASCII_HEAD", >> third_config)

    print("\nPARAMETERS_NAME config/sextractor/default.param", >> third_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME config/sextractor/%s\n", "gauss_4.0_7x7.conv", >> third_config)

    # printf("DETECT_MINAREA %d\n", 100, >> third_config)
    print("DETECT_MAXAREA 0", >> third_config)
    printf("\nDETECT_THRESH %.2f\n", 1.0, >> third_config)
    printf("DEBLEND_MINCONT   %.6f\n", 1.0, >> third_config)
    printf("CLEAN_PARAM %.3f\n", 0.1, >> third_config)

    print("\n#------------------------------ Check Image ----------------------------------", >> third_config)

    print("\nCHECKIMAGE_TYPE BACKGROUND, BACKGROUND_RMS, FILTERED, SEGMENTATION, MODELS, -MODELS", >> third_config)

    print("\nCHECKIMAGE_NAME data/results_sex/third_bg.fits, data/results_sex/third_bgrms.fits, data/results_sex/third_filt.fits, data/results_sex/third_seg.fits, data/results_sex/third_mod.fits, data/results_sex/third_res.fits", >> third_config)

    # ******************************************************************************************************************

    # ******************************************************************************************************************
    # ********************** FIRST SEXTRACTION CONFIGURATION-FILE ******************************************************
    # ******************************************************************************************************************

    print("\n#-------------------------------- Catalog ------------------------------------", >> cold_config)

    print("\nCATALOG_NAME data/results_sex/cold_test.cat", >> cold_config)
    print("CATALOG_TYPE ASCII_HEAD", >> cold_config)

    print("\nPARAMETERS_NAME config/sextractor/default.param", >> cold_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME config/sextractor/%s\n", namefilt_se, >> cold_config)

    printf("DETECT_MINAREA %d\n", minarea_se, >> cold_config)
    printf("DETECT_MAXAREA %d\n", maxarea_se, >> cold_config)
    printf("\nDETECT_THRESH %.4f\n", dthresh_se, >> cold_config)
    printf("DEBLEND_MINCONT   %.6f\n", dmincont_se, >> cold_config)
    printf("CLEAN_PARAM %.3f\n", cleanpar_se, >> cold_config)

    print("\n#------------------------------ Check Image ----------------------------------", >> cold_config)

    print("\nCHECKIMAGE_TYPE SEGMENTATION", >> cold_config)

    print("\nCHECKIMAGE_NAME data/data_images/segmentation/cold_segmen.fits", >> cold_config)

    # ejecutar find_objs:
    print(" - ejecutando find_objs...")
    find_objs

    flpr
end
