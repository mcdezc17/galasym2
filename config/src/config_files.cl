procedure config_files()

struct *list

begin

    struct line
    string tmp_infile, tmp_outfile
    string first_config, second_config, third_config
    string psf_name
    string cfg
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
    # --- first mode ---
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
    # --- second mode ---
    int    sc_minarea_se
    real   sc_dthresh_se
    real   sc_dmincont_se
    real   sc_cleanpar_se

    # -------- Declaracion de variables para pset 'psfexp' --------
    bool   defaultf_psf
    real   dthresh_psf, athresh_psf
    string img_name_psf

    cfg = envget("gconf")

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

            # ------------ SECOND MODE DEXTRACTIONS --------------
            # lectura de
            if(key_word == "SC_DETECT_MINAREA"){print(line) | scan(key_word, sc_minarea_se)}
            # lectura de
            if(key_word == "SC_DETECT_THRESH"){print(line) | scan(key_word, sc_dthresh_se)}
            # lectura de
            if(key_word == "SC_DEBLEND_MINCONT"){print(line) | scan(key_word, sc_dmincont_se)}
            # lectura de
            if(key_word == "SC_CLEAN_PARAM"){print(line) | scan(key_word, sc_cleanpar_se)}

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
        if(!access("data")){mkdir("data")}
        if(!access("data/results_psfex")){mkdir("data/results_psfex")}

        # ==============================================================================================
        # SEXTRACTOR PRE-PSFEX CONFIG FILE
        # ==============================================================================================

        tmp_outfile = "data/results_psfex/my_prepsfex.sex"

        print("# Simple configuration file for SExtractor prior to PSFEx use", > tmp_outfile)
        print("# only non-default parameters are present.", >> tmp_outfile)
        printf("# FOR GALASYM2 ANALYSIS IMG: %s\n", pathname_data, >> tmp_outfile)
        print("# DATE 190925", >> tmp_outfile)

        print("\n#-------------------------------- Catalog ------------------------------------", >> tmp_outfile)

        print("\nCATALOG_NAME    data/results_psfex/my_prepsfex.cat", >> tmp_outfile)
        print("CATALOG_TYPE     FITS_LDAC", >> tmp_outfile)
        print("PARAMETERS_NAME  "//cfg//"psfex/prepsfex/prepsfex.param", >> tmp_outfile)

        print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

        print("\nDETECT_MINAREA   3", >> tmp_outfile)
        printf("DETECT_THRESH    %s\n", dthresh_psf, >> tmp_outfile)
        printf("ANALYSIS_THRESH  %s\n", athresh_psf, >> tmp_outfile)

        print("\nFILTER           Y", >> tmp_outfile)
        print("FILTER_NAME      "//cfg//"psfex/prepsfex/default.conv", >> tmp_outfile)

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
        tmp_outfile = "data/results_psfex/my_default.psfex"

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
        psf_name = cfg//"sextractor/default.psf"
    }

    # ==============================================================================================
    # SEXTRACTOR CONFIG FILE
    # ==============================================================================================

    if(!access("data")){mkdir("data")}
    if(!access("data/results_sex")){mkdir("data/results_sex")}

    first_config = "data/results_sex/first_default.sex"

    print("# Default configuration file for SExtractor 2.28.0", > first_config)
    printf("# FOR GALASYM ANALYSIS IMG: %s\n", pathname_data, >> first_config)

    print("\n#-------------------------------- FLAGging -----------------------------------", >> first_config)

    print("\nFLAG_IMAGE flag.fits", >> first_config)
    print("FLAG_TYPE OR", >> first_config)

    print("\n#----------------------- Differential Geometry Map ---------------------------", >> first_config)

    print("\nDGEO_TYPE NONE", >> first_config)
    print("DGEO_IMAGE dgeo.fits", >> first_config)

    print("\n#------------------------------ Photometry -----------------------------------", >> first_config)

    line = n_apert_phot
    print(line) | scan (aper_1, aper_2, aper_3)
    aper_1 = aper_1 / pix_scal_phot
    aper_2 = aper_2 / pix_scal_phot
    aper_3 = aper_3 / pix_scal_phot

    printf("%.2f, %.2f, %.2f", aper_1, aper_2, aper_3) | scan(n_apert_phot)

    printf("\nPHOT_APERTURES %s\n", n_apert_phot, >> first_config)
    print("PHOT_AUTOPARAMS 2.5, 3.5", >> first_config)
    print("PHOT_PETROPARAMS 2.0, 3.5", >> first_config)

    print("\nPHOT_AUTOAPERS 0.0,0.0", >> first_config)

    print("\nPHOT_FLUXFRAC 0.2 0.5 0.8", >> first_config)

    printf("\nSATUR_LEVEL %s\n", saturlev_phot, >> first_config)
    printf("SATUR_KEY %s\n", saturkey_phot, >> first_config)

    printf("\nMAG_ZEROPOINT %s\n", mag_zero_phot, >> first_config)
    print("MAG_GAMMA 4.0", >> first_config)
    printf("GAIN %s\n", gain_lev_phot, >> first_config)
    printf("GAIN_KEY %s\n", gain_key_phot, >> first_config)
    printf("PIXEL_SCALE %s\n", pix_scal_phot, >> first_config)

    print("\n#------------------------- Star/Galaxy Separation ----------------------------", >> first_config)

    printf("\nSEEING_FWHM %s\n", seeingfw_phot, >> first_config)
    print("STARNNW_NAME "//cfg//"sextractor/default.nnw", >> first_config)

    print("\n#------------------------------ Background -----------------------------------", >> first_config)

    print("\nBACK_TYPE MANUAL", >> first_config) # def=AUTO
    print("BACK_VALUE 0.0", >> first_config)
    print("BACK_PEARSON 2.5", >> first_config)

    printf("\nBACK_SIZE %s\n", backsize_se, >> first_config)
    printf("BACK_FILTERSIZE %s\n", bckfilsz_se, >> first_config)

    print("\nBACKPHOTO_TYPE GLOBAL", >> first_config)
    print("BACKPHOTO_THICK 24", >> first_config)
    print("BACK_FILTTHRESH 0.0", >> first_config)

    print("\n#--------------------- Memory (change with caution!) -------------------------", >> first_config)

    print("\nMEMORY_OBJSTACK 3000", >> first_config)
    print("MEMORY_PIXSTACK 300000", >> first_config)
    print("MEMORY_BUFSIZE 1024", >> first_config)

    print("\n#------------------------------- ASSOCiation ---------------------------------", >> first_config)

    print("\nASSOC_NAME sky.list", >> first_config)
    print("ASSOC_DATA 2,3,4", >> first_config)
    print("ASSOC_PARAMS 2,3,4", >> first_config)
    print("ASSOCCOORD_TYPE PIXEL", >> first_config)
    print("ASSOC_RADIUS 2.0", >> first_config)
    print("ASSOC_TYPE NEAREST", >> first_config)

    print("\nASSOCSELEC_TYPE MATCHED", >> first_config)

    print("\n#----------------------------- Miscellaneous ---------------------------------", >> first_config)

    printf("\nVERBOSE_TYPE %s\n", verbotyp_se, >> first_config)
    print("HEADER_SUFFIX .head", >> first_config)
    print("WRITE_XML N", >> first_config)
    print("XML_NAME data/results_sex/sex.xml", >> first_config)
    print("XSL_URL file:///usr/local/share/sextractor/sextractor.xsl", >> first_config)

    print("\nNTHREADS 1", >> first_config)

    print("\nFITS_UNSIGNED N", >> first_config)
    print("INTERP_MAXXLAG 16", >> first_config)
    print("INTERP_TYPE ALL", >> first_config)

    print("\n#--------------------------- Experimental Stuff -----------------------------", >> first_config)

    printf("\nPSF_NAME %s\n", psf_name, >> first_config)
    print("PSF_NMAX 1", >> first_config)
    print("PATTERN_TYPE RINGS-HARMONIC", >> first_config)

    print("\nSOM_NAME default.som", >> first_config)

    print("\n#------------------------------- Extraction ----------------------------------", >> first_config)

    print("\nDETECT_TYPE CCD", >> first_config)
    print("THRESH_TYPE RELATIVE", >> first_config)

    # (TRASLADADO A OTROS .CL A DEFINIR) printf("\nDETECT_THRESH %s\n", dthresh_se, >> first_config)
    printf("ANALYSIS_THRESH %.4f\n", athresh_se, >> first_config)

    if(bfilter_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nFILTER %s\n", tmp_string, >> first_config)

    print("FILTER_THRESH", >> first_config)

    print("\nDEBLEND_NTHRESH 32", >> first_config)

    if(cleanspu_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nCLEAN %s\n", "Y", >> first_config)

    print("\nMASK_TYPE CORRECT", >> first_config)

    print("\n#---------------------------- DIFERENCIA DE CONFIGURACION -------------------------------", >> first_config)

    # ******************************************************************************************************************
    # ********************* SECOND SEXTRACTION CONFIGURATION-FILE ******************************************************
    # ******************************************************************************************************************

    second_config = "data/results_sex/second_default.sex"
    copy(first_config, second_config)

    print("\n#-------------------------------- Catalog ------------------------------------", >> second_config)

    print("\nCATALOG_NAME data/results_sex/second_test.cat", >> second_config)
    print("CATALOG_TYPE ASCII_HEAD", >> second_config)

    print("\nPARAMETERS_NAME "//cfg//"sextractor/default.param", >> second_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME %s\n", cfg//"sextractor/"//namefilt_se, >> second_config)

    printf("DETECT_MINAREA %d\n", sc_minarea_se, >> second_config)
    print("DETECT_MAXAREA 0", >> second_config)
    printf("\nDETECT_THRESH %.4f\n", sc_dthresh_se, >> second_config)
    printf("DEBLEND_MINCONT   %.6f\n", sc_dmincont_se, >> second_config)
    printf("CLEAN_PARAM %.3f\n", sc_cleanpar_se, >> second_config)

    print("\n#------------------------------ Check Image ----------------------------------", >> second_config)

    print("\nCHECKIMAGE_TYPE SEGMENTATION", >> second_config)

    print("\nCHECKIMAGE_NAME data/results_sex/second_seg.fits", >> second_config)

    # ******************************************************************************************************************

    # ******************************************************************************************************************
    # ********************** THIRD SEXTRACTION CONFIGURATION-FILE ******************************************************
    # ******************************************************************************************************************

    third_config = "data/results_sex/third_config.sex"
    copy(first_config, third_config)

    print("\n#-------------------------------- Catalog ------------------------------------", >> third_config)

    print("\nCATALOG_NAME data/results_sex/third_test.cat", >> third_config)
    print("CATALOG_TYPE ASCII_HEAD", >> third_config)

    print("\nPARAMETERS_NAME "//cfg//"sextractor/default.param", >> third_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME %s\n", cfg//"sextractor/gauss_4.0_7x7.conv", >> third_config)

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

    print("\n#-------------------------------- Catalog ------------------------------------", >> first_config)

    print("\nCATALOG_NAME data/results_sex/first_test.cat", >> first_config)
    print("CATALOG_TYPE ASCII_HEAD", >> first_config)

    print("\nPARAMETERS_NAME "//cfg//"sextractor/default.param", >> first_config)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME %s\n", cfg//"sextractor/"//namefilt_se, >> first_config)

    printf("DETECT_MINAREA %d\n", minarea_se, >> first_config)
    printf("DETECT_MAXAREA %d\n", maxarea_se, >> first_config)
    printf("\nDETECT_THRESH %.4f\n", dthresh_se, >> first_config)
    printf("DEBLEND_MINCONT   %.6f\n", dmincont_se, >> first_config)
    printf("CLEAN_PARAM %.3f\n", cleanpar_se, >> first_config)

    print("\n#------------------------------ Check Image ----------------------------------", >> first_config)

    print("\nCHECKIMAGE_TYPE SEGMENTATION", >> first_config)

    print("\nCHECKIMAGE_NAME data/data_images/segmentation/first_segmen.fits", >> first_config)

    # ejecutar find_objs:
    print(" - ejecutando find_objs...")
    find_objs

    flpr
end
