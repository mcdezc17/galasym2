procedure first_time()

pset datapar {prompt = "input data parameters (pset)"}
pset photimg {prompt = "photometry image par. (pset)"}
pset sexpar  {prompt = "SExtractor parameters (pset)"}
pset psfexp  {prompt = "PSFExtractor paramet. (pset)"}
pset exp_pst {prompt = "Experimental stuff    (pset)"}

begin

    # archivo de salida:
    string tmp_outfile

    # Declaracion de variables para pset 'datapar'
    bool   single_data
    string pathname_data, initpos_data, tformat_data, tcoord_data

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
    string key_run_se
    int    minarea_se
    real   dthresh_se, athresh_se
    bool   bfilter_se
    string namefilt_se
    string weightty_se, weightim_se
    int    backsize_se, bckfilsz_se
    string verbotyp_se

    # Declaracion de variables para pset 'psfexp'
    string key_run_psf
    bool   defaultf_psf, same_img_psf
    string img_name_psf

    # Declaracion de variables para pset 'exp_pst'
    string kw_ds9_exp

    # ARCHIVO DE SALIDA DE PARAMETROS:
    tmp_outfile = "tmp"

    # ================================================
    # OBTENER VALORES DE PSET: datapar
    # ================================================

    single_data   = datapar.single
    pathname_data = datapar.pathname
    initpos_data  = datapar.initpos
    tformat_data  = datapar.tformat
    tcoord_data   = datapar.tcoord
    # = datapar.sim_img
    # = datapar.path_sim

    # Verifica existencia de imagen:
    if(single_data == yes){
        if(!imaccess(pathname_data)){
            print("\n ERR: pset(datapar) variable(pathname).")
            print("       There is no access to the input image.")
            print("       Impossible to continue!")
            bye
        }
        # Verifica existencia de tabla de posiciones iniciales:
        if(!access(initpos_data)){
            print("\n ERR: pset(datapar) variable(initpos).")
            print("       There is no access to the initial posi-")
            print("       tion table.")
            print("       Impossible to continue!")
            bye
        }
        # Verifica formato de la tabla anterior:
        while(tformat_data != "ascii"){
            print("\n WRNNG: pset(datapar) variable(tformat).\n")
            print("   For now, only the following formats are valid")
            print("   for the initial position table:")
            print("   - 'ascii' (Space Separate Columns)\n")
            # futuros formatos disponibles... (agregar || en while)
            # ...
            # Leer la variable formato de tabla:
            printf(" Enter a valid format: ")
            scan(tformat_data)
        }
        # Verifica coordenadas de la tabla anterior:
        while(tcoord_data != "deg" && tcoord_data != "image"){
            print("\n WRNNG: pset(datapar) variable(tcoord).\n")
            print("   For now, only the following coords. are valid")
            print("   for the initial position table:")
            print("   - 'deg' (sexagesimal RA/DEC)")
            print("   - 'image'   (position XY in img)\n")
            # Leer la variable de coordenadas de tabla:
            printf(" Enter a valid coords.: ")
            scan(tcoord_data)
        }

    # Verifica existencia de carpeta:
    }else{
        if(imaccess(pathname_data)){
            print("\n ERR: pset(datapar) variable(pathname).")
            print("      It looks like an image; a folder is expected.")
            print("      Impossible to continue!")
            bye
        }

        if(!access(pathname_data)){
            print("\n ERR: pset(datapar) variable(pathname).")
            print("       There is no access to the image folder.")
            print("       Impossible to continue!")
            bye
        }
    }

    # Si la verificacion continua, imprime archivo full parametros:
    print("# Complete set of parameters required by GALASYM\n", > tmp_outfile)
    print("#------------------------------------------------------------")
    print("#--------------- PSET: config/src/datapar.par ---------------")
    printf("SINGLE_TYPE\t%b\n", single_data, >> tmp_outfile)
    printf("PATH_IMG\t%s\n", pathname_data, >> tmp_outfile)
    if(single_data == yes){
        printf("INIT_POS\t%s\n", initpos_data, >> tmp_outfile)
        printf("T_FORMAT\t%s\n", tformat_data, >> tmp_outfile)
        printf("T_COORD\t%s\n", tcoord_data, >> tmp_outfile)
    }else{
        print("INIT_POS\t0", >> tmp_outfile)
        print("T_FORMAT\t0", >> tmp_outfile)
        print("T_COORD\t0", >> tmp_outfile)
    }

    # ================================================
    # OBTENER VALORES DE PSET: photimg
    # ================================================

    n_apert_phot  = photimg.n_apert
    fluxfrac_phot = photimg.fluxfrac
    saturlev_phot = photimg.saturlev
    saturkey_phot = photimg.saturkey
    mag_zero_phot = photimg.mag_zero
    gain_lev_phot = photimg.gain_lev
    gain_key_phot = photimg.gain_key
    pix_scal_phot = photimg.pix_scal
    seeingfw_phot = photimg.seeingfw

    # Si la verificacion continua, imprime archivo full parametros:
    print("#------------------------------------------------------------")
    print("#--------------- PSET: config/src/photimg.par ---------------")
    printf("PHOT_APERTURES\t%s\n", n_apert_phot, >> tmp_outfile)
    printf("PHOT_FLUXFRAC\t%s\n", fluxfrac_phot, >> tmp_outfile)
    printf("SATUR_LEVEL\t%s\n", saturlev_phot, >> tmp_outfile)
    printf("SATUR_KEY\t%s\n", saturkey_phot, >> tmp_outfile)
    printf("MAG_ZEROPOINT\t%s\n", mag_zero_phot, >> tmp_outfile)
    printf("GAIN\t%s\n", gain_lev_phot, >> tmp_outfile)
    printf("GAIN_KEY\t%s\n", gain_key_phot, >> tmp_outfile)
    printf("PIXEL_SCALE\t%s\n", pix_scal_phot, >> tmp_outfile)
    printf("SEEING_FWHM\t%s\n", seeingfw_phot, >> tmp_outfile)

    # ================================================
    # OBTENER VALORES DE PSET: sexpar
    # ================================================

    key_run_se  = sexpar.key_run
    minarea_se  = sexpar.minarea
    dthresh_se  = sexpar.dthresh
    athresh_se  = sexpar.athresh
    bfilter_se  = sexpar.bfilter
    namefilt_se = sexpar.namefilt
    #  = sexpar.dnthresh
    #  = sexpar.dmincont
    #  = sexpar.cleanspu
    #  = sexpar.cleanpar
    #  = sexpar.masktype
    weightty_se = sexpar.weightty
    weightim_se = sexpar.weightim
    backsize_se = sexpar.backsize
    bckfilsz_se = sexpar.bckfilsz
    verbotyp_se = sexpar.verbotyp

    # Si la verificacion continua, imprime archivo full parametros:
    print("#------------------------------------------------------------")
    print("#--------------- PSET: config/src/sexpar.par ----------------")
    printf("KW_SE\t%s\n", key_run_se, >> tmp_outfile)
    printf("DETECT_MINAREA\t%s\n", minarea_se, >> tmp_outfile)
    printf("DETECT_THRESH\t%s\n", dthresh_se, >> tmp_outfile)
    printf("ANALYSIS_THRESH\t%s\n", athresh_se, >> tmp_outfile)
    printf("FILTER\t%s\n", bfilter_se, >> tmp_outfile)
    printf("FILTER_NAME\t%s\n", namefilt_se, >> tmp_outfile)
    # printf("DEBLEND_NTHRESH\t%s\n", , >> tmp_outfile)
    # printf("DEBLEND_MINCONT\t%s\n", , >> tmp_outfile)
    # printf("CLEAN\t%s\n", , >> tmp_outfile)
    # printf("CLEAN_PARAM\t%s\n", , >> tmp_outfile)
    # printf("MASK_TYPE\t%s\n", , >> tmp_outfile)
    printf("WEIGHT_TYPE\t%s\n", weightty_se, >> tmp_outfile)
    printf("WEIGHT_IMAGE\t%s\n", weightim_se, >> tmp_outfile)
    printf("BACK_SIZE\t%s\n", backsize_se, >> tmp_outfile)
    printf("BACK_FILTERSIZE\t%s\n", bckfilsz_se, >> tmp_outfile)
    printf("VERBOSE_TYPE\t%s\n", verbotyp_se, >> tmp_outfile)

    # ================================================
    # OBTENER VALORES DE PSET: psfex
    # ================================================

    key_run_psf  = psfexp.key_run
    defaultf_psf = psfexp.defaultf
    same_img_psf  = psfexp.same_img
    img_name_psf = psfexp.img_name

    # Si la verificacion continua, imprime archivo full parametros:
    print("#------------------------------------------------------------")
    print("#--------------- PSET: config/src/psfexp.par ----------------")
    printf("KW_PSFEX\t%s\n", key_run_psf, >> tmp_outfile)
    printf("DFLT_PSF\t%s\n", defaultf_psf, >> tmp_outfile)
    printf("SAME_IMG\t%s\n", same_img_psf, >> tmp_outfile)
    printf("IMG_NAME\t%s\n", img_name_psf, >> tmp_outfile)

    # ================================================
    # OBTENER VALORES DE PSET: exp_pst
    # ================================================

    kw_ds9_exp  = exp_pst.kw_ds9

    # Si la verificacion continua, imprime archivo full parametros:
    print("#------------------------------------------------------------")
    print("#--------------- PSET: config/src/exp_pst.par ----------------")
    printf("KW_DS9\t%s\n", kw_ds9_exp, >> tmp_outfile)

    # find_objs

    # config_files

end
