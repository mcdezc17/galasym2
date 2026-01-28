procedure config_files()

struct *list

begin

    struct line
    string tmp_infile, tmp_outfile
    string psf_name
    real aperture_ref

    # temporal:
    string tmp_string

    string key_word
    # Declaracion de variables para pset 'datapar'
    bool   single_data
    string pathname_data
    # Declaracion de variables para pset 'photimg'
    string n_apert_phot, fluxfrac_phot
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
    list = "full_params.txt"
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
            if(key_word == "PHOT_FLUXFRAC"){print(line) | scan(key_word, fluxfrac_phot)}
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

        print("\nCATALOG_NAME     data/results_psfex/prepsfex.cat            # (BEST DEFAULT) Catalog filename", >> tmp_outfile)
        print("CATALOG_TYPE     FITS_LDAC                     # (MANDATORY FITS_LDAC) FITS_LDAC format", >> tmp_outfile)
        print("PARAMETERS_NAME  config/psfex/prepsfex/prepsfex.param # name of the file containing catalog contents", >> tmp_outfile)

        print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

        print("\nDETECT_MINAREA 3    # (BEST DEFAULT) minimum number of pixels above threshold", >> tmp_outfile)
        print("DETECT_THRESH    4    # (BEST DEFAULT) a fairly conservative threshold", >> tmp_outfile)
        print("ANALYSIS_THRESH  4    # idem", >> tmp_outfile)

        print("\nFILTER         Y    # (MANDATORY YES) apply filter for detection (Y or N)?", >> tmp_outfile)
        print("FILTER_NAME      config/psfex/prepsfex/default.conv   # (MANATORY default.conv) name of the file containing the filter", >> tmp_outfile)

        print("\n#-------------------------------- WEIGHTing ----------------------------------", >> tmp_outfile)
        print("#-------------------------------- FLAGging -----------------------------------", >> tmp_outfile)
        print("#------------------------------ Photometry -----------------------------------", >> tmp_outfile)

        print("\nPHOT_FLUXFRAC   0.5", >> tmp_outfile)

        aperture_ref = (5 + 0.1) / pix_scal_phot

        printf("\nPHOT_APERTURES  %s        # put the referrence aperture diameter here: 5arsec diameter in pixels\n", aperture_ref, >> tmp_outfile)
        printf("SATUR_LEVEL       %s        # put the right saturation threshold here\n", saturlev_phot, >> tmp_outfile)
        printf("MAG_ZEROPOINT     %s        # magnitude zero-point\n", mag_zero_phot, >> tmp_outfile)
        printf("GAIN              %s        # put the right detector gain in e-/ADU here\n", gain_lev_phot, >> tmp_outfile)

        # ==============================================================================================
        # PSFEX CONFIG FILE
        # ==============================================================================================
        tmp_outfile = "config/psfex/my_default.psfex"

        print("# Default configuration file for PSFEx 3.9.0", > tmp_outfile)
        printf("# FOR GALASYM ANALYSIS IMG: %s\n", pathname_data, >> tmp_outfile)
        print("# DATE 190925", >> tmp_outfile)

        print("\n#-------------------------------- PSF model ----------------------------------", >> tmp_outfile)

        print("\nBASIS_TYPE      PIXEL_AUTO      # NONE, PIXEL, GAUSS-LAGUERRE or FILE", >> tmp_outfile)
        print("BASIS_NUMBER    20              # Basis number or parameter", >> tmp_outfile)
        print("PSF_SAMPLING    0.0             # Sampling step in pixel units (0.0 = auto)", >> tmp_outfile)
        print("PSF_ACCURACY    0.01            # Accuracy to expect from PSF pixel values", >> tmp_outfile)
        print("PSF_SIZE        25,25           # Image size of the PSF model", >> tmp_outfile)
        print("CENTER_KEYS     X_IMAGE,Y_IMAGE # Catalogue parameters for source pre-centering", >> tmp_outfile)
        print("PHOTFLUX_KEY    FLUX_APER(1)    # Catalogue parameter for photometric norm.", >> tmp_outfile)
        print("PHOTFLUXERR_KEY FLUXERR_APER(1) # Catalogue parameter for photometric error", >> tmp_outfile)

        print("\n#----------------------------- PSF variability -----------------------------", >> tmp_outfile)

        print("\nPSFVAR_KEYS     X_IMAGE,Y_IMAGE # Catalogue or FITS (preceded by :) params", >> tmp_outfile)
        print("PSFVAR_GROUPS   1,1             # Group tag for each context key", >> tmp_outfile)
        print("PSFVAR_DEGREES  2               # Polynom degree for each group", >> tmp_outfile)

        print("\n#----------------------------- Sample selection ------------------------------", >> tmp_outfile)

        print("\nSAMPLE_AUTOSELECT  Y            # Automatically select the FWHM (Y/N) ?", >> tmp_outfile)
        print("SAMPLEVAR_TYPE     SEEING       # File-to-file PSF variability: NONE or SEEING", >> tmp_outfile)
        print("SAMPLE_FWHMRANGE   2.0,10.0     # Allowed FWHM range", >> tmp_outfile)
        print("SAMPLE_VARIABILITY 0.2          # Allowed FWHM variability (1.0 = 100%)", >> tmp_outfile)
        print("SAMPLE_MINSN       20           # Minimum S/N for a source to be used", >> tmp_outfile)
        print("SAMPLE_MAXELLIP    0.3          # Maximum (A-B)/(A+B) for a source to be used", >> tmp_outfile)

        print("\n#------------------------------- Check-plots ----------------------------------", >> tmp_outfile)

        print("\nCHECKPLOT_DEV       PNG         # NULL, XWIN, TK, PS, PSC, XFIG, PNG, JPEG, AQT, PDF or SVG", >> tmp_outfile)

        print("\nCHECKPLOT_RES       0           # Check-plot resolution (0 = default)", >> tmp_outfile)
        print("CHECKPLOT_ANTIALIAS Y           # Anti-aliasing using convert (Y/N) ?", >> tmp_outfile)
        print("CHECKPLOT_TYPE      FWHM,ELLIPTICITY,COUNTS,COUNT_FRACTION,CHI2,RESIDUALS # or NONE", >> tmp_outfile)
        print("CHECKPLOT_NAME      data/results_psfex/fwhm.png, data/results_psfex/ellipticity.png, data/results_psfex/counts.png, data/results_psfex/countfrac.png, data/results_psfex/chi2.png, data/results_psfex/resi.png", >> tmp_outfile)

        print("\n#------------------------------ Check-Images ---------------------------------", >> tmp_outfile)

        print("\nCHECKIMAGE_TYPE CHI,PROTOTYPES,SAMPLES,RESIDUALS,SNAPSHOTS,MOFFAT,-MOFFAT,-SYMMETRICAL    # Check-image types", >> tmp_outfile)

        print("\nCHECKIMAGE_NAME data/results_psfex/chi.fits, data/results_psfex/proto.fits, data/results_psfex/samp.fits, data/results_psfex/resi.fits, data/results_psfex/snap.fits, data/results_psfex/moffat.fits, data/results_psfex/submoffat.fits, data/results_psfex/subsym.fits    # Check-image filenames", >> tmp_outfile)

        print("\n#----------------------------- Miscellaneous ---------------------------------", >> tmp_outfile)

        print("\nPSF_DIR         data/results_psfex               # Where to write PSFs (empty=same as input)", >> tmp_outfile)
        print("PSF_SUFFIX      .psf            # Filename extension for output PSF filename", >> tmp_outfile)
        print("VERBOSE_TYPE    NORMAL          # can be QUIET,NORMAL,LOG or FULL", >> tmp_outfile)
        print("WRITE_XML       Y               # Write XML file (Y/N)?", >> tmp_outfile)
        print("XML_NAME        data/results_psfex/psfex.xml       # Filename for XML output", >> tmp_outfile)
        print("NTHREADS        0               # Num. simult. threads for SMP.ver of PSFEx; 0 = automatic", >> tmp_outfile)

        psf_name = "config/sextractor/my_prepsfex.psf"


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

    print("\nCATALOG_NAME     data/results_sex/test.cat       # name of the output catalog", >> tmp_outfile)
    print("CATALOG_TYPE     ASCII_HEAD     # NONE,ASCII,ASCII_HEAD, ASCII_SKYCAT, ASCII_VOTABLE, FITS_1.0 or FITS_LDAC", >> tmp_outfile)

    print("\nPARAMETERS_NAME  config/sextractor/default.param  # name of the file containing catalog contents", >> tmp_outfile)

    print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

    print("\nDETECT_TYPE     CCD            # CCD (linear) or PHOTO (with gamma correction)", >> tmp_outfile)
    printf("DETECT_MINAREA   %s             # min. # of pixels above threshold\n", minarea_se, >> tmp_outfile)
    print("DETECT_MAXAREA    0              # max. # of pixels above threshold (0=unlimited)", >> tmp_outfile)
    print("THRESH_TYPE       RELATIVE       # threshold type: RELATIVE (in sigmas) or ABSOLUTE (in ADUs)", >> tmp_outfile)

    printf("\nDETECT_THRESH  %s            # <sigmas> or <threshold>,<ZP> in mag.arcsec-2\n", dthresh_se, >> tmp_outfile)
    printf("ANALYSIS_THRESH  %s            # <sigmas> or <threshold>,<ZP> in mag.arcsec-2\n", athresh_se, >> tmp_outfile)

    if(bfilter_se == yes){tmp_string = "Y"}else{tmp_string = "N"}
    printf("\nFILTER          %s              # apply filter for detection (Y or N)?\n", tmp_string, >> tmp_outfile)

    printf("FILTER_NAME      config/sextractor/%s   # name of the file containing the filter\n", namefilt_se, >> tmp_outfile)
    print("FILTER_THRESH                   # Threshold[s] for retina filtering", >> tmp_outfile)

    print("\nDEBLEND_NTHRESH  32             # Number of deblending sub-thresholds", >> tmp_outfile)
    print("DEBLEND_MINCONT  0.005          # Minimum contrast parameter for deblending", >> tmp_outfile)

    print("\nCLEAN            Y              # Clean spurious detections? (Y or N)?", >> tmp_outfile)
    print("CLEAN_PARAM      1.0            # Cleaning efficiency", >> tmp_outfile)

    print("\nMASK_TYPE        CORRECT        # type of detection MASKing: can be one of  NONE, BLANK or CORRECT", >> tmp_outfile)

    print("\n#-------------------------------- WEIGHTing ----------------------------------", >> tmp_outfile)

    printf("\nWEIGHT_TYPE   %s          # type of WEIGHTing: NONE, BACKGROUND,  MAP_RMS, MAP_VAR or MAP_WEIGHT\n", weightty_se, >> tmp_outfile)

    print("\nRESCALE_WEIGHTS  Y         # Rescale input weights/variances (Y/N)?", >> tmp_outfile)
    printf("WEIGHT_IMAGE    %s          # weight-map filename\n", weightim_se, >> tmp_outfile)
    print("WEIGHT_GAIN      Y              # modulate gain (E/ADU) with weights? (Y/N)", >> tmp_outfile)
    print("WEIGHT_THRESH                   # weight threshold[s] for bad pixels", >> tmp_outfile)

    print("\n#-------------------------------- FLAGging -----------------------------------", >> tmp_outfile)

    print("\nFLAG_IMAGE       flag.fits      # filename for an input FLAG-image", >> tmp_outfile)
    print("FLAG_TYPE        OR             # flag pixel combination: OR, AND, MIN, MAX or MOST", >> tmp_outfile)

    print("\n#----------------------- Differential Geometry Map ---------------------------", >> tmp_outfile)

    print("\nDGEO_TYPE        NONE           # Differential geometry map type: NONE or PIXEL", >> tmp_outfile)
    print("DGEO_IMAGE       dgeo.fits      # Filename for input differential geometry image", >> tmp_outfile)

    print("\n#------------------------------ Photometry -----------------------------------", >> tmp_outfile)

    printf("\nPHOT_APERTURES   %s              # MAG_APER aperture diameter(s) in pixels\n", n_apert_phot, >> tmp_outfile)
    print("PHOT_AUTOPARAMS  2.5, 3.5       # MAG_AUTO parameters: <Kron_fact>,<min_radius>", >> tmp_outfile)
    print("PHOT_PETROPARAMS 2.0, 3.5       # MAG_PETRO parameters: <Petrosian_fact>, <min_radius>", >> tmp_outfile)

    print("\nPHOT_AUTOAPERS   0.0,0.0        # <estimation>,<measurement> minimum apertures for MAG_AUTO and MAG_PETRO", >> tmp_outfile)

    print("\nPHOT_FLUXFRAC    0.2, 0.5, 0.8            # flux fraction[s] used for FLUX_RADIUS", >> tmp_outfile)

    printf("\nSATUR_LEVEL    %s       # level (in ADUs) at which arises saturation\n", saturlev_phot, >> tmp_outfile)
    printf("SATUR_KEY        %s       # keyword for saturation level (in ADUs)\n", saturkey_phot, >> tmp_outfile)

    printf("\nMAG_ZEROPOINT   %s      # magnitude zero-point\n", mag_zero_phot, >> tmp_outfile)
    print("MAG_GAMMA        4.0       # gamma of emulsion (for photographic scans)", >> tmp_outfile)
    printf("GAIN             %s       # detector gain in e-/ADU\n", gain_lev_phot, >> tmp_outfile)
    printf("GAIN_KEY         %s       # keyword for detector gain in e-/ADU\n", gain_key_phot, >> tmp_outfile)
    printf("PIXEL_SCALE      %s       # size of pixel in arcsec (0=use FITS WCS info)\n", pix_scal_phot, >> tmp_outfile)

    print("\n#------------------------- Star/Galaxy Separation ----------------------------", >> tmp_outfile)

    printf("\nSEEING_FWHM      %s      # stellar FWHM in arcsec\n", seeingfw_phot, >> tmp_outfile)
    print("STARNNW_NAME     config/sextractor/default.nnw    # Neural-Network_Weight table filename", >> tmp_outfile)

    print("\n#------------------------------ Background -----------------------------------", >> tmp_outfile)

    print("\nBACK_TYPE        AUTO           # AUTO or MANUAL", >> tmp_outfile)
    print("BACK_VALUE       0.0            # Default background value in MANUAL mode", >> tmp_outfile)
    print("BACK_PEARSON     2.5            # Pearson's factor Legacy value is 2.5, but 3.5 is more accurate", >> tmp_outfile)

    printf("\nBACK_SIZE      %s              # Background mesh: <size> or <width>,<height>\n", backsize_se, >> tmp_outfile)
    printf("BACK_FILTERSIZE  %s              # Background filter: <size> or <width>,<height>\n", bckfilsz_se, >> tmp_outfile)

    print("\nBACKPHOTO_TYPE   GLOBAL        # can be GLOBAL or LOCAL", >> tmp_outfile)
    print("BACKPHOTO_THICK  24             # thickness of the background LOCAL annulus", >> tmp_outfile)
    print("BACK_FILTTHRESH  0.0            # Threshold above which the backgroundmap filter operates", >> tmp_outfile)

    print("\n#------------------------------ Check Image ----------------------------------", >> tmp_outfile)

    print("\nCHECKIMAGE_TYPE  BACKGROUND, BACKGROUND_RMS, MODELS, -MODELS, SEGMENTATION, FILTERED, -OBJECTS", >> tmp_outfile)

    print("\nCHECKIMAGE_NAME  data/results_sex/check_bg.fits, data/results_sex/check_bgrms.fits, data/results_sex/check_mod.fits, data/results_sex/check_res.fits, data/results_sex/check_seg.fits, data/results_sex/check_fil.fits, data/results_sex/check_no_objs.fits", >> tmp_outfile)

    print("\n#--------------------- Memory (change with caution!) -------------------------", >> tmp_outfile)

    print("\nMEMORY_OBJSTACK  3000           # number of objects in stack", >> tmp_outfile)
    print("MEMORY_PIXSTACK  300000         # number of pixels in stack", >> tmp_outfile)
    print("MEMORY_BUFSIZE   1024           # number of lines in buffer", >> tmp_outfile)

    print("\n#------------------------------- ASSOCiation ---------------------------------", >> tmp_outfile)

    print("\nASSOC_NAME       sky.list       # name of the ASCII file to ASSOCiate", >> tmp_outfile)
    print("ASSOC_DATA       2,3,4          # columns of the data to replicate (0=all)", >> tmp_outfile)
    print("ASSOC_PARAMS     2,3,4          # columns of xpos,ypos[,mag]", >> tmp_outfile)
    print("ASSOCCOORD_TYPE  PIXEL          # ASSOC coordinates: PIXEL or WORLD", >> tmp_outfile)
    print("ASSOC_RADIUS     2.0            # cross-matching radius (pixels)", >> tmp_outfile)
    print("ASSOC_TYPE       NEAREST        # ASSOCiation method: FIRST, NEAREST, MEAN, MAG_MEAN, SUM, MAG_SUM, MIN or MAX", >> tmp_outfile)

    print("\nASSOCSELEC_TYPE  MATCHED        # ASSOC selection type: ALL, MATCHED or -MATCHED ", >> tmp_outfile)

    print("\n#----------------------------- Miscellaneous ---------------------------------", >> tmp_outfile)

    printf("\nVERBOSE_TYPE    %s         # can be QUIET, NORMAL or FULL", verbotyp_se, >> tmp_outfile)
    print("HEADER_SUFFIX    .head          # Filename extension for additional headers", >> tmp_outfile)
    print("WRITE_XML        N              # Write XML file (Y/N)?", >> tmp_outfile)
    print("XML_NAME         data/results_sex/sex.xml        # Filename for XML output", >> tmp_outfile)
    print("XSL_URL          file:///usr/local/share/sextractor/sextractor.xsl # Filename for XSL style-sheet", >> tmp_outfile)

    print("\nNTHREADS         1     # 1 single thread", >> tmp_outfile)

    print("\nFITS_UNSIGNED    N     # Treat FITS integer values as unsigned (Y/N)?", >> tmp_outfile)
    print("INTERP_MAXXLAG   16             # Max. lag along X for 0-weight interpolation", >> tmp_outfile)
    print("INTERP_MAXYLAG   16             # Max. lag along Y for 0-weight interpolation", >> tmp_outfile)
    print("INTERP_TYPE      ALL            # Interpolation type: NONE, VAR_ONLY or ALL", >> tmp_outfile)

    print("\n#--------------------------- Experimental Stuff -----------------------------", >> tmp_outfile)

    printf("\nPSF_NAME      %s             # File containing the PSF model\n", psf_name, >> tmp_outfile)
    print("PSF_NMAX         1              # Max.number of PSFs fitted simultaneously", >> tmp_outfile)
    print("PATTERN_TYPE     RINGS-HARMONIC # can RINGS-QUADPOLE, RINGS-OCTOPOLE, RINGS-HARMONICS or GAUSS-LAGUERRE", >> tmp_outfile)

    print("\nSOM_NAME         default.som    # File containing Self-Organizing Map weights", >> tmp_outfile)


end
