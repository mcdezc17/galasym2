procedure config_files()

struct *list

begin

    struct line
    string tmp_infile, tmp_outfile
    string psf_name
    real aperture_ref

    # temporal:
    string tmp_string
    real aper_1, aper_2, aper_3

    string key_word
    # Declaracion de variables para pset 'datapar'
    bool   single_data
    string pathname_data
    # Declaracion de variables para pset 'photimg'
    struct n_apert_phot
    real   saturlev_phot
    string saturkey_phot
    real   mag_zero_phot
    real   gain_lev_phot
    string gain_key_phot
    real   pix_scal_phot
    real   seeingfw_phot
    # Declaracion de variables para pset 'sexpar'
    int    minarea_se
    real   dthresh_se, athresh_se
    bool   bfilter_se
    string namefilt_se
    string weightty_se, weightim_se
    int    backsize_se, bckfilsz_se
    string verbotyp_se
    # Declaracion de variables para pset 'psfexp'
    bool   defaultf_psf
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
            if(key_word == "DETECT_THRESH"){print(line) | scan(key_word, dthresh_se)}
            # lectura de
            if(key_word == "ANALYSIS_THRESH"){print(line) | scan(key_word, athresh_se)}
            # lectura de
            if(key_word == "FILTER"){print(line) | scan(key_word, bfilter_se)}
            # lectura de
            if(key_word == "FILTER_NAME"){print(line) | scan(key_word, namefilt_se)}
            # lectura de
            if(key_word == "WEIGHT_TYPE"){print(line) | scan(key_word, weightty_se)}
            # lectura de
            if(key_word == "WEIGHT_IMAGE"){print(line) | scan(key_word, weightim_se)}
            # lectura de
            if(key_word == "BACK_SIZE"){print(line) | scan(key_word, backsize_se)}
            # lectura de
            if(key_word == "BACK_FILTERSIZE"){print(line) | scan(key_word, bckfilsz_se)}
            # lectura de
            if(key_word == "VERBOSE_TYPE"){print(line) | scan(key_word, verbotyp_se)}
            # ================================================
            # OBTENER VALORES DE PSET: psfex
            # ================================================
            # lectura de
            if(key_word == "DFLT_PSF"){print(line) | scan(key_word, defaultf_psf)}
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
        print("DETECT_THRESH    4", >> tmp_outfile)
        print("ANALYSIS_THRESH  4", >> tmp_outfile)

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
    tmp_outfile = "config/sextractor/my_default.sex"

    print("# Default configuration file for SExtractor 2.28.0", > tmp_outfile)
    printf("# FOR GALASYM ANALYSIS IMG: %s\n", pathname_data, >> tmp_outfile)

    print("\n#-------------------------------- Catalog ------------------------------------", >> tmp_outfile)

    print("\nCATALOG_NAME data/results_sex/test.cat", >> tmp_outfile)
    print("CATALOG_TYPE ASCII_HEAD", >> tmp_outfile)

    print("\nPARAMETERS_NAME config/sextractor/default.param", >> tmp_outfile)

    print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

    print("\nDETECT_TYPE CCD", >> tmp_outfile)
    printf("DETECT_MINAREA %s\n", minarea_se, >> tmp_outfile)
    print("DETECT_MAXAREA 0", >> tmp_outfile)
    print("THRESH_TYPE RELATIVE", >> tmp_outfile)

    printf("\nDETECT_THRESH %s\n", dthresh_se, >> tmp_outfile)
    printf("ANALYSIS_THRESH %s\n", athresh_se, >> tmp_outfile)

    if(bfilter_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nFILTER %s\n", tmp_string, >> tmp_outfile)

    printf("FILTER_NAME config/sextractor/%s\n", namefilt_se, >> tmp_outfile)
    print("FILTER_THRESH", >> tmp_outfile)

    print("\nDEBLEND_NTHRESH 32", >> tmp_outfile)
    print("DEBLEND_MINCONT 0.005", >> tmp_outfile)

    print("\nCLEAN Y", >> tmp_outfile)
    print("CLEAN_PARAM 1.0", >> tmp_outfile)

    print("\nMASK_TYPE CORRECT", >> tmp_outfile)

    print("\n#-------------------------------- WEIGHTing ----------------------------------", >> tmp_outfile)

    printf("\nWEIGHT_TYPE %s\n", weightty_se, >> tmp_outfile)

    print("\nRESCALE_WEIGHTS Y", >> tmp_outfile)
    printf("WEIGHT_IMAGE %s\n", weightim_se, >> tmp_outfile)
    print("WEIGHT_GAIN Y", >> tmp_outfile)
    print("WEIGHT_THRESH", >> tmp_outfile)

    print("\n#-------------------------------- FLAGging -----------------------------------", >> tmp_outfile)

    print("\nFLAG_IMAGE flag.fits", >> tmp_outfile)
    print("FLAG_TYPE OR", >> tmp_outfile)

    print("\n#----------------------- Differential Geometry Map ---------------------------", >> tmp_outfile)

    print("\nDGEO_TYPE NONE", >> tmp_outfile)
    print("DGEO_IMAGE dgeo.fits", >> tmp_outfile)

    print("\n#------------------------------ Photometry -----------------------------------", >> tmp_outfile)

    line = n_apert_phot
    print(line) | scan (aper_1, aper_2, aper_3)
    aper_1 = aper_1 / pix_scal_phot
    aper_2 = aper_2 / pix_scal_phot
    aper_3 = aper_3 / pix_scal_phot

    printf("%.2f, %.2f, %.2f", aper_1, aper_2, aper_3) | scan(n_apert_phot)

    printf("\nPHOT_APERTURES %s\n", n_apert_phot, >> tmp_outfile)
    print("PHOT_AUTOPARAMS 2.5, 3.5", >> tmp_outfile)
    print("PHOT_PETROPARAMS 2.0, 3.5", >> tmp_outfile)

    print("\nPHOT_AUTOAPERS 0.0,0.0", >> tmp_outfile)

    print("\nPHOT_FLUXFRAC 0.2 0.5 0.8", >> tmp_outfile)

    printf("\nSATUR_LEVEL %s\n", saturlev_phot, >> tmp_outfile)
    printf("SATUR_KEY %s\n", saturkey_phot, >> tmp_outfile)

    printf("\nMAG_ZEROPOINT %s\n", mag_zero_phot, >> tmp_outfile)
    print("MAG_GAMMA 4.0", >> tmp_outfile)
    printf("GAIN %s\n", gain_lev_phot, >> tmp_outfile)
    printf("GAIN_KEY %s\n", gain_key_phot, >> tmp_outfile)
    printf("PIXEL_SCALE %s\n", pix_scal_phot, >> tmp_outfile)

    print("\n#------------------------- Star/Galaxy Separation ----------------------------", >> tmp_outfile)

    printf("\nSEEING_FWHM %s\n", seeingfw_phot, >> tmp_outfile)
    print("STARNNW_NAME config/sextractor/default.nnw", >> tmp_outfile)

    print("\n#------------------------------ Background -----------------------------------", >> tmp_outfile)

    print("\nBACK_TYPE AUTO", >> tmp_outfile)
    print("BACK_VALUE 0.0", >> tmp_outfile)
    print("BACK_PEARSON 2.5", >> tmp_outfile)

    printf("\nBACK_SIZE %s\n", backsize_se, >> tmp_outfile)
    printf("BACK_FILTERSIZE %s\n", bckfilsz_se, >> tmp_outfile)

    print("\nBACKPHOTO_TYPE GLOBAL", >> tmp_outfile)
    print("BACKPHOTO_THICK 24", >> tmp_outfile)
    print("BACK_FILTTHRESH 0.0", >> tmp_outfile)

    print("\n#------------------------------ Check Image ----------------------------------", >> tmp_outfile)

    print("\nCHECKIMAGE_TYPE BACKGROUND, BACKGROUND_RMS, MODELS, -MODELS, SEGMENTATION, FILTERED, -OBJECTS", >> tmp_outfile)

    print("\nCHECKIMAGE_NAME data/results_sex/check_bg.fits, data/results_sex/check_bgrms.fits, data/results_sex/check_mod.fits, data/results_sex/check_res.fits, data/results_sex/check_seg.fits, data/results_sex/check_fil.fits, data/results_sex/check_no_objs.fits", >> tmp_outfile)

    print("\n#--------------------- Memory (change with caution!) -------------------------", >> tmp_outfile)

    print("\nMEMORY_OBJSTACK 3000", >> tmp_outfile)
    print("MEMORY_PIXSTACK 300000", >> tmp_outfile)
    print("MEMORY_BUFSIZE 1024", >> tmp_outfile)

    print("\n#------------------------------- ASSOCiation ---------------------------------", >> tmp_outfile)

    print("\nASSOC_NAME sky.list", >> tmp_outfile)
    print("ASSOC_DATA 2,3,4", >> tmp_outfile)
    print("ASSOC_PARAMS 2,3,4", >> tmp_outfile)
    print("ASSOCCOORD_TYPE PIXEL", >> tmp_outfile)
    print("ASSOC_RADIUS 2.0", >> tmp_outfile)
    print("ASSOC_TYPE NEAREST", >> tmp_outfile)

    print("\nASSOCSELEC_TYPE MATCHED", >> tmp_outfile)

    print("\n#----------------------------- Miscellaneous ---------------------------------", >> tmp_outfile)

    printf("\nVERBOSE_TYPE %s\n", verbotyp_se, >> tmp_outfile)
    print("HEADER_SUFFIX .head", >> tmp_outfile)
    print("WRITE_XML N", >> tmp_outfile)
    print("XML_NAME data/results_sex/sex.xml", >> tmp_outfile)
    print("XSL_URL file:///usr/local/share/sextractor/sextractor.xsl", >> tmp_outfile)

    print("\nNTHREADS 1", >> tmp_outfile)

    print("\nFITS_UNSIGNED N", >> tmp_outfile)
    print("INTERP_MAXXLAG 16", >> tmp_outfile)
    print("INTERP_MAXYLAG 16", >> tmp_outfile)
    print("INTERP_TYPE ALL", >> tmp_outfile)

    print("\n#--------------------------- Experimental Stuff -----------------------------", >> tmp_outfile)

    printf("\nPSF_NAME %s\n", psf_name, >> tmp_outfile)
    print("PSF_NMAX 1", >> tmp_outfile)
    print("PATTERN_TYPE RINGS-HARMONIC", >> tmp_outfile)

    print("\nSOM_NAME default.som", >> tmp_outfile)

    flpr
    flpr
end
