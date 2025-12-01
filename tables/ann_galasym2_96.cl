procedure galasym2_96_ann()

# FOR ABELL 496 TEST / default cl script name: galasym2_96_ann.cl
# ANNULUS APERTUTRES alpha(r/rp) = N_asymm(in [r-r_delta, r]) / N_ttl(in [r-r_delta, r]
# Other forms are:
#                   - cumulative per apertures alpha(in r/rp) = N_asymm(in r) / N_ttl(in r)
#                   - cumulative by all glxy (alpha(r/rp) = N_asymm(in r) / N_ttl)


# GALASYM2 ROTATIONAL-INDEX ALPHA
# GALASYM2 (MAC OS) ALL COMMENTS IHERITED

#string input_list  = "no"        {prompt = "List of objects to analyze (ascii)"}
string radec_list  = "tables/members_A496J.ascii"        {prompt = "[deg] members list [ascii] to match"}
string measure_img = "A496J.fits"      {prompt = "FITS observed data"}
string detect_img  = "no"        {prompt = "Detection image for SExtractor"}
real   low_clip    = 1.00        {prompt = "Low limit (relative to rms_bg)"}
real   hicen_clip  = 10.0        {prompt = "Upper clip center (clip*rms_bg)"}
real   hiout_clip  = 10.0        {prompt = "Upper clip outer (clip*rms_bg)"}
#real   gbl_index   = 2.00        {prompt = "Aperture for index (in petrosian radius)"}
real   pix_scale   = 0.3      {prompt = "Pixel scale (arcsec/pixel)"}
string obj_center  = "71"        {prompt = "Index list center object (integer)"}
real   clredshift  = 0.033       {prompt = "Cluster redshift (e.g. 0.033"}
bool   model_fit   = yes          {prompt = "Run PSFEx + SExtractor?"}
string key_sex     = "sex"       {prompt = "Keyword to run SExtractor"}
string key_psfex   = "psfex"     {prompt = "Keyword to run PSFEx"}
bool   edit_mode   = no          {prompt = "Edit objects to recompute indexes"}
#string key_ds9     = "ds9"       {prompt = "Keyword to run DS9 viewer"}


begin

    # Movidas del prompt ultimamente

    string input_list

    # DEFINICIÓN DE VARIABLES  ALPHA --------------------------

    real const_pi

    string config_dir, psfex_dir, prepsfex_dir, outpsfex_dir, sex_dir, outsex_dir

    string config_prepsfex, param_prepsfex, conv_prepsfex, cat_prepsfex

    string config_psfex

    string config_sex, param_sex, conv_sex, cat_sex

    bool scndimg_bool, objcenter_bool, tmp_bool

    string alpha_dir, data_dir, alphaimg_dir, dataimg_dir, obs_dir, mod_dir, res_dir, asymm_dir, file_dir, ds9_dir, cat_dir, tmp_dir

    string mod_img, res_img, asymmpixel_img, bgrms_img, psf_fit

    string my_date, my_time

    struct line

    string line_info
    string id_obj[999]
    real ra_j00[999], dec_j00[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], kron_r[999], petro_r[999], eff_r[999], iso_area[999], iso_areaf[999]
    int n_list, n_edit

    string tmp_string, tmp_wait

    real rms_bg

    int i_center
    real kp_DA
    real ccdistance[999], ccdistance_pix[999], ccdistance_arsec[999], ccdistance_Mpc[999]

    string expre, expre1, expre2

    real pseudo_r, petro_factor

    int obj_i, obj_f, obj_pos

    real inner_area[999]

    int poss_edit[999]

    real scale_r[100]

    real ri_ann, ro_ann

    int px1, px2, py1, py2, l_frame, side_frame[999]

    string trimsection

    real meanpix, ttlpix

    real min1_bgdensity, min2_bgdensity, tmp_current

    int min1_pos, min2_pos

    real min_densitybg, ttl_rho

    real area_ann[4], n_noisepix[4], density_noise[4]

    real delta_area, nbg_noisepix, n_asymmpix, n_total, asymm_area

    # LOCAL VARIABLES DEFINITION ROTATED-ALPHA

    string rot_asymm_dir, img_to_rot, img_out_rot

    bool rot_alpha

    string asymmpixel_head, rot_cat_dir, out_cat, out_ds9_cat

    # ASIGNACIÓN DE DIRECTORIOS --------------------------

    # ./data: main output cut frames
    data_dir = "data"

    # ./config
    config_dir = "config"

    # ./config/psfex
    psfex_dir = config_dir//"/"//"psfex"
    # ./config/psfex/prepsfex
    prepsfex_dir = psfex_dir//"/"//"prepsfex"
    # ./config/psfex/results_psfex
    #outpsfex_dir = psfex_dir//"/"//"results_psfex"
    outpsfex_dir = data_dir//"/"//"results_psfex"

    # ./config/sextractor
    sex_dir = config_dir//"/"//"sextractor"
    # ./config/sextractor/results_sex
    #outsex_dir = sex_dir//"/"//"results_sex"
    outsex_dir = data_dir//"/"//"results_sex"

    # ./data/images:
    dataimg_dir = data_dir//"/"//"data_images"
    # ./alpha/images/observed
    obs_dir = dataimg_dir//"/"//"observed"
    # ./alpha/images/model
    mod_dir = dataimg_dir//"/"//"model"
    # ./alpha/images/residual
    res_dir = dataimg_dir//"/"//"residual"

    # ./alpha: main output index alpha folder
    alpha_dir = "alpha_"//str(low_clip)
    # ./alpha/images:
    alphaimg_dir = alpha_dir//"/"//"images"
    # ./alpha/images/asymmpix
    asymm_dir = alphaimg_dir//"/"//"asymmpix"
    # ./alpha/images/rot_asymmpix
    rot_asymm_dir = alphaimg_dir//"/"//"rot_asymmpix"

    # ./alpha/files(catalogs o plain text):
    file_dir = alpha_dir//"/"//"files"
    # ./alpha/files/ds9_files
    ds9_dir = file_dir//"/"//"ds9_files"
    # ./alpha/files/catalogs
    cat_dir = file_dir//"/"//"catalogs"
    # ./alpha/files/rotational_catalogs
    rot_cat_dir = cat_dir//"/"//"rotated_alpha"

    # ./alpha/temporal:
    tmp_dir = alpha_dir//"/"//"cache"

    # ASIGNACIÓN DE VARIABLES --------------------------

    config_prepsfex = prepsfex_dir//"/"//"prepsfex.sex"
    param_prepsfex = prepsfex_dir//"/"//"prepsfex.param"
    conv_prepsfex = prepsfex_dir//"/"//"default.conv"
    cat_prepsfex = outpsfex_dir//"/"//"prepsfex.cat"

    config_psfex = psfex_dir//"/"//"default.psfex"

    config_sex = sex_dir//"/"//"default.sex"
    param_sex = sex_dir//"/"//"default.param"
    conv_sex = sex_dir//"/"//"filter.conv"

    bgrms_img = outsex_dir//"/"//"check_bgrms.fits"
    mod_img = outsex_dir//"/"//"check_mod.fits"
    res_img = outsex_dir//"/"//"check_res.fits"
    psf_fit = outpsfex_dir//"/"//"prepsfex.psf"
    cat_sex = outsex_dir//"/"//"test.cat"

    const_pi = 3.1415926535897932385

    scndimg_bool = no

    objcenter_bool = no

    rot_alpha = no

    ri_ann = 3
    ro_ann = 4

    petro_factor = 2.0

    # vector of scale r/rp
    scale_r[1]=0.25
    scale_r[2]=0.30; scale_r[3]=0.35; scale_r[4]=0.40; scale_r[5]=0.45; scale_r[6]=0.50; scale_r[7]=0.55; scale_r[8]=0.60; scale_r[9]=0.65; scale_r[10]=0.70; scale_r[11]=0.75; scale_r[12]=0.80; scale_r[13]=0.85; scale_r[14]=0.90; scale_r[15]=0.95; scale_r[16]=1.00; scale_r[17]=1.05; scale_r[18]=1.10; scale_r[19]=1.15; scale_r[20]=1.20; scale_r[21]=1.25; scale_r[22]=1.30; scale_r[23]=1.35; scale_r[24]=1.40; scale_r[25]=1.45; scale_r[26]=1.50; scale_r[27]=1.55; scale_r[28]=1.60; scale_r[29]=1.65; scale_r[30]=1.70; scale_r[31]=1.75; scale_r[32]=1.80; scale_r[33]=1.85; scale_r[34]=1.90; scale_r[35]=1.95; scale_r[36]=2.00; scale_r[37]=2.05; scale_r[38]=2.10; scale_r[39]=2.15; scale_r[40]=2.20; scale_r[41]=2.25; scale_r[42]=2.30; scale_r[43]=2.35; scale_r[44]=2.40; scale_r[45]=2.45; scale_r[46]=2.50; scale_r[47]=2.55; scale_r[48]=2.60; scale_r[49]=2.65; scale_r[50]=2.70; scale_r[51]=2.75; scale_r[52]=2.80; scale_r[53]=2.85; scale_r[54]=2.90; scale_r[55]=2.95; scale_r[56]=3.00; scale_r[57]=3.05; scale_r[58]=3.10; scale_r[59]=3.15; scale_r[60]=3.20; scale_r[61]=3.25; scale_r[62]=3.30; scale_r[63]=3.35; scale_r[64]=3.40; scale_r[65]=3.45; scale_r[66]=3.50; scale_r[67]=3.55; scale_r[68]=3.60; scale_r[69]=3.65; scale_r[70]=3.70; scale_r[71]=3.75; scale_r[72]=3.80; scale_r[73]=3.85; scale_r[74]=3.90; scale_r[75]=3.95; scale_r[76]=4.00; scale_r[77]=4.05; scale_r[78]=4.10; scale_r[79]=4.15; scale_r[80]=4.20; scale_r[81]=4.25; scale_r[82]=4.30; scale_r[83]=4.35; scale_r[84]=4.40; scale_r[85]=4.45; scale_r[86]=4.50; scale_r[87]=4.55; scale_r[88]=4.60; scale_r[89]=4.65; scale_r[90]=4.70; scale_r[91]=4.75; scale_r[92]=4.80; scale_r[93]=4.85; scale_r[94]=4.90; scale_r[95]=4.95; scale_r[96]=5.00


    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    # First terminal output
    print("")

    # If edit_mode=yes avoid model_fit mode and double image mode
    if(edit_mode != no){
        model_fit = no
        detect_img = "no"
        printf("--------- GALASYM2 started on %s at %s --------\n\n", my_date, my_time)
        print(" Edit mode for recompute asymmetry index from edit_list.cat")
    }else{
        printf("--------- GALASYM2 started on %s at %s --------\n\n", my_date, my_time)
    }
    # -----------------------------------------------------------

    # Check that the input FITS observed image exists or is named correctly:
    if(!access(measure_img)){
        # print("Warning: FITS observed image: ", measure_img, " not found!")
        # print("         Forgot it? --> Adding extension *.fits: ")
        tmp_string = measure_img//".fits"
        # print("New name: ", tmp_string, " ...check:")
        if(access(tmp_string)){
            print(" Observed image name... correct")
            measure_img = tmp_string
        }else{
            print(" ERR: Check the full file name of the observed image and try again!")
            print("      e.g. 'cluster_a85.fits'")
            goto exit_task
        }
    }
    # Check that input FITS detection image for SEx exists or is named correctly:
    if(strlwr(detect_img) != "no" && strlwr(detect_img) != "n"){

        if(!access(detect_img)){
            tmp_string = detect_img//".fits"
            if(access(tmp_string)){
                print(" Detection image name... correct")
                detect_img = tmp_string
                print(" Double image mode...\n")
                scndimg_bool = yes
            }else{
                printf("WARNING: Second FITS image doesn't exist:  %s or %s", detect_img, tmp_string)
                print("          Set prompt input 'detect_img = no' and try again!")
                goto exit_task
            }
        }
    }

    # .........................

    # FOLDER VERIFICATION OR CREATION ----------------------------
    if(!access(config_dir)){mkdir(config_dir)}       # main output:  ./config
    if(!access(data_dir)){mkdir(data_dir)}           # main output: ./data

    if(!access(psfex_dir)){mkdir(psfex_dir)}         # psfex folder: ./config/psfex
    if(!access(prepsfex_dir)){mkdir(prepsfex_dir)}   # prepsfex fol: ./config/psfex/prepsfex
    if(!access(outpsfex_dir)){mkdir(outpsfex_dir)}   # outpsfex fol: ./"data"/psfex/results_psfex

    if(!access(sex_dir)){mkdir(sex_dir)}             # sextrac. fol: ./config/sextractor
    if(!access(outsex_dir)){mkdir(outsex_dir)}       # outsext. fol: ./"data"/results_sex
    # END FOLDER VERIFICATION -----------------------------------


    # RUN PSFEx -------------------------------------------------
    if(model_fit == yes){

        if(!access(bgrms_img) && !access(mod_img) && !access(res_img)){

            # If access to psf model (prepsfex.psf) omit PrePSFEx (SEx-prior) and PSFEx, if not:
            if(!access(psf_fit)){

                # If access to prepsfex catalog (prepsfex.cat [FITS_LDAC]) omit PrePSFEx, if not:
                if(!access(cat_prepsfex)){

                    # Impossible to run PrePSFEx (SEx) prior to PSFEx if:
                    if(!access(config_prepsfex) || !access(param_prepsfex) || !access(conv_prepsfex)){
                        print("\n WARNING: config-files for running Pre-PSFEx are incomplete!")
                        print("         At least the following files must exist: ")
                        print("         - prepsfex.sex     (in ./config/psfex/prepsfex/)")
                        print("         - prepsfex.param   (in same dir)")
                        print("         - and default.conv (in same dir)")
                        print(" Verify and run again.")
                        goto exit_task
                    }

                    # Running PrePSFEx (pre-psfex) prior to PSFEx
                    print("-------------------------------------------------------------")
                    print(" RUNNING SExtractor PRIOR PSFEx:\n")
                    printf("! %s %s -c %s\n", key_sex, measure_img, config_prepsfex) | cl
                    sleep(2)
                    print("-------------------------------------------------------------")
                    print("\n Was PrePSFEx by SExtractor well execute (?)\n")

                }

                printf(" Exists PrePSFEx catalog (FITS_LDAC). Reading: %s\n\n", cat_prepsfex)

                # Impossible to run PSFEx if:
                if(!access(config_psfex)){
                    print("\n WARNING: config-files for running PSFEx are incomplete!")
                    print("         At least the following files must exist: ")
                    print("         - default.sex     (in ./config/psfex/)")
                }
                # Running PSFEx
                print("-------------------------------------------------------------")
                print(" RUNNING PSFEx:\n")
                printf("! %s %s -c %s\n", key_psfex, cat_prepsfex, config_psfex) | cl
                sleep(2)
                print("-------------------------------------------------------------")

                if(!access(psf_fit)){
                    # Was PSFEx well executed?
                    print(" PSFEx not well executed, *.psf wasn't created")
                    goto exit_task
                }
            }

            printf(" Exists PSF model (*.psf) from PSFEx: %s\n\n", psf_fit)

            # Impossible to run SEx if:
            if(!access(config_sex) || !access(param_sex) || !access(conv_sex)){
                print("\n WARNING: config-files for running SEx are incomplete!")
                print("         At least the following files must exist: ")
                print("         - default.sex     (in ./config/sextractor/)")
                print("         - default.param   (in same dir)")
                print("         - and filter.conv (in same dir)")
                print(" Verify and run again.")
                goto exit_task
            }

            # Running SEx:
            print("-------------------------------------------------------------")
            print(" RUNNING SExtractor to model-fitting:\n")
            if(scndimg_bool == yes){
                printf("! %s %s %s -c %s \n", key_sex, detect_img, measure_img, config_sex) | cl
            }else{
                print(" Single image mode...\n")
                printf("! %s %s -c %s \n", key_sex, measure_img, config_sex) | cl
            }
            sleep(2)
            print("-------------------------------------------------------------")
            print("\n Was Model-fit by SExtractor well execute (?)\n")
            print(" if yes: CHANGE prompt input 'model_fit = no' and run")
            print("        galasym2 again to compute indexes.")

            # printf("! cp %s ./sextracted_list.cat", cat_sex) | cl
            delete("./sextracted_list.cat", ver-, >& "dev$null")
            copy(cat_sex, "./sextracted_list.cat")

            print("\n Output catalog from SEx has been copied in local directory:")
            print("   as ./'sextractor_to_inputlist'\n")

            print(" Please select input objects to compute indexes in an (e.g.) 'inputlist.cat'")

            # edit: comment ===============================================================================================
            #goto exit_task
        }

        print(" SExtractor results (check_images) exist!")
        print("")
        # print("        > CHANGE prompt input 'model_fit = no' and")
        # print("        > run galasym2 again to compute indexes.")
        # print("")
        # print("        NOTE: must verify inputlist before!")
        # print("")
        # print("   Or if you want a new model-fit, DELETE")
        # print("      the following outputs of SEx (and PSFEx?):")
        # print("      - ./config/sextractor/results_sex folder")
        # print("      - [optional] ./config/sextractor/prepsfex.psf")

        # goto exit_task

    }

    # MATCH BETWEEN RA-DEC_LIST & SEXtracted_OBJECTS: stilts app -------
    print("")
    print("--------------- START STILTS MATCH -------------------------\n")
    print("stilts-tskymatch2 - Crossmatches 2 tables on sky position\n")

    tmp_string = outsex_dir//"/"//"sextracted_list.cat"
    if(!access(tmp_string)){
        copy(cat_sex, tmp_string)
    }

    delete("./match_list.cat", ver-, >& "dev$null")
    expre = "! stilts tskymatch2 in1=%s ifmt1=ascii in2=%s ifmt2=ascii ra1=RA dec1=DEC ra2=col2 dec2=col3 error=4 find=best ofmt=ascii out=./match_list.cat\n"
    printf(expre, radec_list, tmp_string) | cl

    print("")
    print("stilts-tpipe - Performs pipeline processing on a table")
    print("")
    delete("./inputlist.cat", ver-, >& "dev$null")
    expre ="! stilts tpipe cmd='delcols \"RA DEC col1\"' in=./match_list.cat ifmt=ascii ofmt=ascii out=./inputlist.cat\n"
    print(expre) | cl
    delete("./match_list.cat", ver-, >& "dev$null")

    print("")
    print("------------------ END STILTS MATCH -------------------------\n")
    print("Output information")
    print("Table 1:", radec_list)
    print("Table 2: sextracted_list.cat")
    print("Table 1&2 match: inputlist.cat")
    print("-------------------------------------------------------------")

    # inputlist for galasym2 process ----------------------------------
    input_list = "inputlist.cat"

    # INPUT PARAMETER VERIFICATION ------------------------------
    if (!access(input_list)){
        print("Warning: input list named ", input_list, " not found!")
        print("Enter correct filename with extension *.txt, *.ascii (etc) e.g. input_list.txt or input_list.ascii: ")
        scan(input_list)
        if(!access(input_list)){
            print("ERR: Second verification for ", input_list, " failed!")
            print("     Check the input list name and its existence in local directory.")
            print("")
            print("Analysis task aborted. Verify and try again!")
            goto exit_task
        }
    }
    # others verification here:

    # FOLDER VERIFICATION OR CREATION ----------------------------
    if(!access(alpha_dir)){mkdir(alpha_dir)}     # main output: ./alpha

    if(!access(alphaimg_dir)){mkdir(alphaimg_dir)}     # images folder:      ./alpha/images:
    if(!access(dataimg_dir)){mkdir(dataimg_dir)}       # images folder:      ./data/images:
    if(!access(obs_dir)){mkdir(obs_dir)}               # observed images:    ./alpha/images/observed
    if(!access(mod_dir)){mkdir(mod_dir)}               # model images:       ./alpha/images/model
    if(!access(res_dir)){mkdir(res_dir)}               # residual images:    ./alpha/images/residual
    if(!access(asymm_dir)){mkdir(asymm_dir)}           # alpha asymm images: ./alpha/images/asymmpix
    if(!access(rot_asymm_dir)){mkdir(rot_asymm_dir)}   # alpha rot_asymm images: ./alpha/images/rot_asymmpix

    if(!access(file_dir)){mkdir(file_dir)}         # files folder:    ./alpha/files:
    if(!access(ds9_dir)){mkdir(ds9_dir)}           # ds9_files:       ./alpha/files/ds9_files
    if(!access(cat_dir)){mkdir(cat_dir)}           # catalogs_files:  ./alpha/files/catalogs
    if(!access(rot_cat_dir)){mkdir(rot_cat_dir)}   # rotational_cataloogs: ./alpha/files/rot_catalogs

    if(!access(tmp_dir)){mkdir(tmp_dir)}     # temporal folder: ./alpha/temp:

    # READ INPUT LIST --------------------------------------------
    list = input_list
    i = 0
    while(fscan(list,line) != EOF){
        line_info = substr(line, 1, 1)
        if(line_info != "#"){

            i = i + 1

            # NOTE: The columns are readed in order to input.list
            #************************ USAR LAS SIGUIENTES VARIABLES ******************************
            # string id_obj[999]
            # real ra_j00[999], dec_j00[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], iso_area[999], iso_areaf[999]
            #****************************************************************************************

            print(line) | scan(id_obj[i], ra_j00[i], dec_j00[i], xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i])

            petro_r[i] = petro_r[i] / 2
        }
    }
    n_list = i

    # DEFINITION OF R-AXIS FOR A-aperture diagram
    # ------------------------------------------- (galasym 1)

    # BACKGROUND RMS: mid-point of check_background_rms.fits from SEx
    tmp_string = outsex_dir//"/"//"rms_bg.cat"
    if(!access(tmp_string)){
        imstat(bgrms_img, fields = "midpt", nclip = 0, format-) | scan(rms_bg)
        print(" ", rms_bg, >> tmp_string)
        print(" - RMS value from SEx = ", rms_bg)
        #_______________________________________
        #_______ borrar check_bgrms.fits ?______
    }else{
        list = tmp_string

        while(fscan(list, line) != EOF){
            line_info = substr(line, 1, 1)
            if(line_info != "#"){
                print(line) | scan(rms_bg)
            }
        }
        print(" - RMS value from SEx = ", rms_bg)
    }

    # OUTPUT OF ANALYSIS VALUES
    # ------------------------- (galasym 1)

    #__________________________________________________________________________
    #___________ Distance of objects to galaxy center _________________________|
    if(strlwr(obj_center) != "no" && strlwr(obj_center) != "n"){

        i_center = int(obj_center)
        if(i_center < 1 || i_center > n_list){
            print(" ERR: Parameter value is out of range must be an integer (within the inputlist)")
            print("      OR a string 'no'")
            goto exit_task
        }

        objcenter_bool = yes

        if(access(config_dir//"/"//"ned_calc.py")){

            print("! python3 "//config_dir//"/"//"ned_calc.py ", clredshift, " 70 0.3 0.7") | cl | scan(kp_DA)
        }

        for(i=1; i<=n_list; i+=1){

            ccdistance_pix[i] = sqrt((xwin_img[i_center] - xwin_img[i])**2 + (ywin_img[i_center] - ywin_img[i])**2)
            ccdistance[i] = ccdistance_pix[i]

            if(pix_scale != 0){

                ccdistance_arsec[i] = ccdistance_pix[i] * pix_scale
                ccdistance[i] = ccdistance_arsec[i]

                if(access(config_dir//"/"//"ned_calc.py")){

                    ccdistance_Mpc[i] = (ccdistance_arsec[i] * kp_DA) / 1000
                    ccdistance[i] = ccdistance_Mpc[i]
                }
            }
        }
    }

    # If avoid cut frames and go to asymmetry compute
    if(edit_mode == yes){
        goto edit_task
    }
    # -----------------------------------------------------------


    #_______________________________________________________________________________
    #____________________ CREATE REGION DS9 FILES  _________________________________|
    # FK5 coordinates format / The shape of apertures depends on ellipticity (SEx)
    # and determines the measurement aperture (growing in this shape)

    # Header: measurement apertures
    delete(ds9_dir//"/"//"apertures.reg", ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"apertures.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"apertures.reg")
    print("fk5", >> ds9_dir//"/"//"apertures.reg")

    # Header: Kron and Petrosian apertures
    delete(ds9_dir//"/"//"kron_petro_aper.reg", ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"kron_petro_aper.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"kron_petro_aper.reg")
    print("fk5", >> ds9_dir//"/"//"kron_petro_aper.reg")

    # Header: file for apertures account:
    delete(ds9_dir//"/"//"aper_sum.txt", ver-, >& "dev$null")
    print("", >> ds9_dir//"/"//"aper_sum.txt")
    print("# Sum of apertures: ", >> ds9_dir//"/"//"aper_sum.txt")
    print("", >> ds9_dir//"/"//"aper_sum.txt")

    for(i=1; i<=n_list; i+=1){
        # refrence (3A,3B) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(3 * a_img[i] * pix_scale)//'",'//str(3 * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=green text={SE fit}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # refrence (Rp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red text={Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # measurement (1.5xRp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(1.5 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={1.5Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # measurement (2xRp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={2Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # background aperture: eliptical annulus
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ri_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ri_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ro_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ro_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1 text={in:'//str(i)//', '//id_obj[i]//'}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # Elliptical petrosian aperture:
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=yellow'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
        # Elliptical total flux (2 x R_petro):
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=yellow dash=1 text={in:'//str(i)//', '//id_obj[i]//'}'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
        # Ell. kron aperture:
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(kron_r[i] * a_img[i] * pix_scale)//'",'//str(kron_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=white'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
    }
    #____________________ END CREATE REGION DS9 FILES  _____________________________|




edit_task:


    # Edit asymmetrical pixel image (?)
    if(edit_mode == yes){

        print("\n\n Editting mode: edit images to recompute asymmetry indices")
        print("                   from the .../catalogs/'edit_list.cat'\n")

        tmp_string = cat_dir//"/"//"edit_list.cat"
        if(!access(tmp_string)){
            print(" edit_mode = yes but edit_list.cat (catalog folder) not found... exit task!")
            goto exit_task
        }

        # Read edit list
        # READ INPUT LIST --------------------------------------------
        list = cat_dir//"/"//"edit_list.cat"
        i = 0

        while(fscan(list,line) != EOF){
            line_info = substr(line, 1, 1)
            if(line_info != "#"){

                i = i + 1

                print(line) | scan(poss_edit[i])
            }
        }
        n_edit = i

        obj_i = 1
        obj_f = n_edit

        img_to_rot = asymm_dir//"/"//"edit_asymmpix_"
        img_out_rot = rot_asymm_dir//"/"//"rot_edit_asymmpix_"

    }else{
        obj_i = 1
        obj_f = n_list

        img_to_rot = asymm_dir//"/"//"asymmpix_"
        img_out_rot = rot_asymm_dir//"/"//"rot_asymmpix_"
    }



    #_______________________________________________________________________________
    #____________________ CUT FRAMES: OBSERVED, MODEL, RESIDUAL ____________________|

    # Corte de marcos observed & models:
    for(i = obj_i; i <= obj_f; i += 1){

        if(edit_mode == yes){
            obj_pos = poss_edit[i]
        }else{
            obj_pos = i
        }

        # Tamaño del cuadrado a recortar: measure
        side_frame[obj_pos] = 2 * (ro_ann + 1) * (petro_r[obj_pos] * a_img[obj_pos])
        # Vertices del cuadrado:
        px1 = int(xwin_img[obj_pos] - (side_frame[obj_pos] / 2)) + 1
        px2 = int(xwin_img[obj_pos] + (side_frame[obj_pos] / 2))
        py1 = int(ywin_img[obj_pos] - (side_frame[obj_pos] / 2)) + 1
        py2 = int(ywin_img[obj_pos] + (side_frame[obj_pos] / 2))
        # Seccion a recortar:
        trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"
        #--------------------------------

        # Observed frame for measure index (source + noise annulus)
        tmp_string = obs_dir//"/"//"observed_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save frames observed:
            imdelete(obs_dir//"/"//"observed_"//id_obj[obj_pos], >& "dev$null")
            imcopy(measure_img//trimsection, obs_dir//"/"//"observed_"//id_obj[obj_pos], verb-)
        }

        # Residual frame for measure index (source + noise annulus):
        tmp_string = res_dir//"/"//"residmeasure_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended residuals frames:
            imdelete(res_dir//"/"//"residmeasure_"//id_obj[obj_pos], >& "dev$null")
            imcopy(res_img//trimsection, res_dir//"/"//"residmeasure_"//id_obj[obj_pos], verb-)
        }

        # Extended model frame for measure index (source + noise annulus):
        tmp_string = mod_dir//"/"//"modmeasure_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended model frames:
            imdelete(mod_dir//"/"//"modmeasure_"//id_obj[obj_pos], >& "dev$null")
            imcopy(mod_img//trimsection, mod_dir//"/"//"modmeasure_"//id_obj[obj_pos], verb-)
            # Center mask from model:
            imdelete(mod_dir//"/"//"centermodmask_"//id_obj[obj_pos] , >& "dev$null")
            imexpr("a <= b*c", mod_dir//"/"//"centermodmask_"//id_obj[obj_pos], mod_dir//"/"//"modmeasure_"//id_obj[obj_pos], hicen_clip, rms_bg, verb-)

        }

        # Center Areas for Segmentation Area:
        tmp_string = tmp_dir//"/"//"areacenter_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Center area count:
            expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1 && f == 0"
            imdelete(tmp_dir//"/"//"areacenter_"//id_obj[obj_pos], >& "dev$null")
            imexpr(expre, tmp_dir//"/"//"areacenter_"//id_obj[obj_pos], side_frame[obj_pos]/2, side_frame[obj_pos]/2, petro_r[obj_pos]*a_img[obj_pos], petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, mod_dir//"/"//"centermodmask_"//id_obj[obj_pos], verb-)

            imstat(tmp_dir//"/"//"areacenter_"//id_obj[obj_pos], fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            inner_area[obj_pos] = meanpix * ttlpix
        }

        # Extend asymmetrical pixels for measure index (source + noise annulus):
        tmp_string = asymm_dir//"/"//"asymmpix_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended asymmpix frames:
            imdelete(asymm_dir//"/"//"asymmpix_"//id_obj[obj_pos], >& "dev$null")
            imexpr("a*b >= c*e && a*b <= d*e", asymm_dir//"/"//"asymmpix_"//id_obj[obj_pos], res_dir//"/"//"residmeasure_"//id_obj[obj_pos], mod_dir//"/"//"centermodmask_"//id_obj[obj_pos], low_clip, hiout_clip, rms_bg, verb-)
        }

        # Extend rotated asymmetrical pixels for measure rot-index alpha
        tmp_string = img_out_rot//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended rotated asymmpix frames:
            imdelete(img_out_rot//id_obj[obj_pos], >& "dev$null")

            imtranspose(img_to_rot//id_obj[obj_pos]//".fits[*,-*]", rot_asymm_dir//"/"//"tmp_90")
            imtranspose(rot_asymm_dir//"/"//"tmp_90"//".fits[*,-*]", rot_asymm_dir//"/"//"tmp_180")
            imexpr("(a-b)>0", img_out_rot//id_obj[obj_pos], img_to_rot//id_obj[obj_pos], rot_asymm_dir//"/"//"tmp_180", verb-)

            imdelete(rot_asymm_dir//"/"//"tmp_90", >& "dev$null")
            imdelete(rot_asymm_dir//"/"//"tmp_180", >& "dev$null")
        }

        # Observed area frame for N total pixels
        tmp_string = obs_dir//"/"//"area_obs_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save frames observed:
            imdelete(tmp_string, >& "dev$null")
            imexpr("a*b >= c*d", obs_dir//"/"//"area_obs_"//id_obj[obj_pos], obs_dir//"/"//"observed_"//id_obj[obj_pos], mod_dir//"/"//"centermodmask_"//id_obj[obj_pos], low_clip, rms_bg, verb-)
        }

        printf("\r - Preparing images: %d%%", (i*100/n_list))
    }
    #_____________________________ END CUT FRAMES __________________________________|



    #_______________________________________________________________________________
    #__________________________ AREA ASYMMETRICAL INDEX ____________________________|
    print("\n\n------------------------ ALPHA INDEX ------------------------\n")

    # EDIT MODE: OVERWRITE THE CATALOGS:
    if(edit_mode == no){

        # ASYMMETRY INDEX (output) CATALOGS HEADERS ()*.cat) =================================================================
        delete(cat_dir//"/"//"asymmpix_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"noisepix_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"areaindex_set.cat", >& "dev$null")

        for(j=6; j<=76; j+=5){
            if(j == 6){
                #        %ID  %fr %Nt %Nasymm_1 (I. N asymm. pixels SET: first)
                printf("#%31s %6s %6s N_%4.2frp", "ID_OBJ", "3/rp", "Nttl", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                #        %ID  %Nb %db %fr %Nt %Areacorr_1 (II. Noise pixels SET: first)
                printf("#%31s %6s %7s %6s %6s d_%4.2frp", "ID_OBJ", "Nbg", "rho_bg", "3/rp", "Nttl", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III. Asymmetry area SET: first
                printf("#%31s A_%4.2frp", "ID_OBJ", scale_r[j], >> cat_dir//"/"//"areaindex_set.cat")

            }else if(j == 76){
                #        %Nasymm_last (I. N asymm. pixels SET: last)
                printf(" N_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                # II. Noise pixel SET: last
                printf(" d_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III. Asymmetry area SET: last
                printf(" A_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"areaindex_set.cat")

            }else{
                #        %Nasymm_i (All parameters catalog:)
                printf(" N_%4.2frp", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                # II. Noise pixel SET: mid
                printf(" d_%4.2frp", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III.Asymmetry area SET: mid
                printf(" A_%4.2frp", scale_r[j], >> cat_dir//"/"//"areaindex_set.cat")
            }
        }
        # ================================================================================================================

        # HEADER of rotated alpha-set catalogs = alpha-set catalogs => copy:
        delete(rot_cat_dir//"/"//"rot_asymmpix_set.cat", >& "dev$null")
        delete(rot_cat_dir//"/"//"rot_noisepix_set.cat", >& "dev$null")
        delete(rot_cat_dir//"/"//"rot_areaindex_set.cat", >& "dev$null")
        copy(cat_dir//"/"//"asymmpix_set.cat", rot_cat_dir//"/"//"rot_asymmpix_set.cat")
        copy(cat_dir//"/"//"noisepix_set.cat", rot_cat_dir//"/"//"rot_noisepix_set.cat")
        copy(cat_dir//"/"//"areaindex_set.cat", rot_cat_dir//"/"//"rot_areaindex_set.cat")

        # HEADER CATALOG: FIXED APERTURE ALPHA INDEX
        delete(cat_dir//"/"//"areaindex.cat",  >& "dev$null")
        # IV. Asymetry area global with center distance
        printf("#%31s %11s %11s %5s A%3.1f_1.0rp A%3.1f_1.5rp A%3.1f_2.0rp\n", "ID_OBJ", "RAJ00", "DECJ00", "Cc_dist", low_clip, low_clip, low_clip, >> cat_dir//"/"//"areaindex.cat")

        # HEADER MAIN CATALOG: FIXED APERTURE ROTATED-ALPHA INDEX (alpha index + rotated-alpha index)
        delete(rot_cat_dir//"/"//"rot_areaindex.cat",  >& "dev$null")
        printf("#%31s %11s %11s %5s R%3.1f_1.5rp R%3.1f_2.0rp R%3.1f_3.0rp\n", "ID_OBJ", "RAJ00", "DECJ00", "Cc_dist", low_clip, low_clip, low_clip, low_clip, low_clip, low_clip, >> rot_cat_dir//"/"//"rot_areaindex.cat")

        # HEADER CATALOG: density noise catalog
        delete(cat_dir//"/"//"patch_bg_set.cat",  >& "dev$null")
        printf("#%31s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "ID_OBJ", "min_rho", "ttl_rho", "A1_ann", "N1_ann", "rho1", "A2_ann", "N2_ann", "rho2", "A3_ann", "N3_ann", "rho3", "A4_ann", "N4_ann", "rho4", >> cat_dir//"/"//"patch_bg_set.cat")

        # HEADER CATALOG: rotated-alpha density noise catalog
        delete(rot_cat_dir//"/"//"rot_patch_bg_set.cat",  >& "dev$null")
        copy(cat_dir//"/"//"patch_bg_set.cat", rot_cat_dir//"/"//"rot_patch_bg_set.cat")

        # HEADER ACATALOG: DS9 regions asymmetry index
        delete(ds9_dir//"/"//"alpha_index.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"alpha_index.reg")
        print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"alpha_index.reg")
        print("fk5", >> ds9_dir//"/"//"alpha_index.reg")
        # copy rotational
        copy(ds9_dir//"/"//"alpha_index.reg", ds9_dir//"/"//"rot_alpha_index.reg")


        # END OF HEADERS (*.par) ---------------------------------------------------------------------------------
    }

rotated_index:

    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    if(rot_alpha == yes){

        if(edit_mode == yes){
            asymmpixel_head = rot_asymm_dir//"/"//"rot_edit_asymmpix_"
        }else{
            asymmpixel_head = rot_asymm_dir//"/"//"rot_asymmpix_"
        }

        out_cat = rot_cat_dir//"/"//"rot_"

        out_ds9_cat = ds9_dir//"/"//"rot_alpha_index.reg"

    }else{

        if(edit_mode == yes){
            asymmpixel_head = asymm_dir//"/"//"edit_asymmpix_"
        }else{
            asymmpixel_head = asymm_dir//"/"//"asymmpix_"
        }

        out_cat = cat_dir//"/"

        out_ds9_cat = ds9_dir//"/"//"alpha_index.reg"
    }

    # Create binary areas for extract noise and avoid center region
    for(i = obj_i; i <= obj_f; i += 1){

        if(edit_mode == yes){
            obj_pos = poss_edit[i]
        }else{
            obj_pos = i
        }
        asymmpixel_img = asymmpixel_head//id_obj[obj_pos]

        # BACKGROUND ESTIMATION -----------------------------------------------------------
        # Annulus 1
        imdelete(tmp_dir//"/"//"tmp_ann_1", >& "dev$null")
        imexpr(expre1//" && "//expre2//" && (I-a) > (J-b) && (I-a) >= -(J-b) ? 1 : 0", tmp_dir//"/"//"tmp_ann_1", side_frame[obj_pos]/2, side_frame[obj_pos]/2, ro_ann*petro_r[obj_pos]*a_img[obj_pos], ro_ann*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, ri_ann*petro_r[obj_pos]*a_img[obj_pos], ri_ann*petro_r[obj_pos]*b_img[obj_pos], dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
        # Area annulus 1
        imstat(tmp_dir//"/"//"tmp_ann_1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        area_ann[1] = meanpix * ttlpix
        # Asymmetrical pixel counting ann[1]
        imdelete(tmp_dir//"/"//"tmp_bgpix_ann1", >& "dev$null")
        imexpr("a*b", tmp_dir//"/"//"tmp_bgpix_ann1", asymmpixel_img, tmp_dir//"/"//"tmp_ann_1", verb-)
        imstat(tmp_dir//"/"//"tmp_bgpix_ann1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_noisepix[1] = meanpix * ttlpix
        # Noise density ann[1]
        density_noise[1] = n_noisepix[1] / area_ann[1]

        # Annulus 2
        imdelete(tmp_dir//"/"//"tmp_ann_2", >& "dev$null")
        imexpr(expre1//" && "//expre2//" && (I-a) <= (J-b) && (I-a) > -(J-b) ? 1 : 0", tmp_dir//"/"//"tmp_ann_2", side_frame[obj_pos]/2, side_frame[obj_pos]/2, ro_ann*petro_r[obj_pos]*a_img[obj_pos], ro_ann*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, ri_ann*petro_r[obj_pos]*a_img[obj_pos], ri_ann*petro_r[obj_pos]*b_img[obj_pos], dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
        # Area annulus 2
        imstat(tmp_dir//"/"//"tmp_ann_2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        area_ann[2] = meanpix * ttlpix
        imdelete(tmp_dir//"/"//"tmp_bgpix_ann2", >& "dev$null")
        imexpr("a*b", tmp_dir//"/"//"tmp_bgpix_ann2", asymmpixel_img, tmp_dir//"/"//"tmp_ann_2", verb-)
        imstat(tmp_dir//"/"//"tmp_bgpix_ann2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_noisepix[2] = meanpix * ttlpix
        # Noise density ann[1]
        density_noise[2] = n_noisepix[2] / area_ann[2]

        # Annulus 3
        imdelete(tmp_dir//"/"//"tmp_ann_3", >& "dev$null")
        imexpr(expre1//" && "//expre2//" && (I-a) < (J-b) && (I-a) <= -(J-b) ? 1 : 0", tmp_dir//"/"//"tmp_ann_3", side_frame[obj_pos]/2, side_frame[obj_pos]/2, ro_ann*petro_r[obj_pos]*a_img[obj_pos], ro_ann*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, ri_ann*petro_r[obj_pos]*a_img[obj_pos], ri_ann*petro_r[obj_pos]*b_img[obj_pos], dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
        # Area annulus 3
        imstat(tmp_dir//"/"//"tmp_ann_3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        area_ann[3] = meanpix * ttlpix
        # Asymmetrical pixel counting ann[1]
        imdelete(tmp_dir//"/"//"tmp_bgpix_ann3", >& "dev$null")
        imexpr("a*b", tmp_dir//"/"//"tmp_bgpix_ann3", asymmpixel_img, tmp_dir//"/"//"tmp_ann_3", verb-)
        imstat(tmp_dir//"/"//"tmp_bgpix_ann3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_noisepix[3] = meanpix * ttlpix
        # Noise density ann[3]
        density_noise[3] = n_noisepix[3] / area_ann[3]

        # Annulus 4
        imdelete(tmp_dir//"/"//"tmp_ann_4", >& "dev$null")
        imexpr(expre1//" && "//expre2//" && (I-a) >= (J-b) && (I-a) < -(J-b) ? 1 : 0", tmp_dir//"/"//"tmp_ann_4", side_frame[obj_pos]/2, side_frame[obj_pos]/2, ro_ann*petro_r[obj_pos]*a_img[obj_pos], ro_ann*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, ri_ann*petro_r[obj_pos]*a_img[obj_pos], ri_ann*petro_r[obj_pos]*b_img[obj_pos], dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
        # Area annulus 4
        imstat(tmp_dir//"/"//"tmp_ann_4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        area_ann[4] = meanpix * ttlpix
        # Asymmetrical pixel counting ann[1]
        imdelete(tmp_dir//"/"//"tmp_bgpix_ann4", >& "dev$null")
        imexpr("a*b", tmp_dir//"/"//"tmp_bgpix_ann4", asymmpixel_img, tmp_dir//"/"//"tmp_ann_4", verb-)
        imstat(tmp_dir//"/"//"tmp_bgpix_ann4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_noisepix[4] = meanpix * ttlpix
        # Noise density ann[4]
        density_noise[4] = n_noisepix[4] / area_ann[4]

        # Total area of ​​the noise ring
        nbg_noisepix = (n_noisepix[1] + n_noisepix[2] + n_noisepix[3] + n_noisepix[4])
        ttl_rho = nbg_noisepix / (area_ann[1] + area_ann[2] + area_ann[3] + area_ann[4])

        # Take the two consecutive minimums of background density
        min1_bgdensity = 1.0e6
        min1_pos = -1

        min2_bgdensity = 1.0e6
        min2_pos = -1

        for(k = 1;k <= 4;k += 1){

            tmp_current = density_noise[k]

            if(tmp_current < min1_bgdensity){

                if(tmp_current != min1_bgdensity){
                    min2_bgdensity = min1_bgdensity
                    min2_pos = min1_pos
                }
                min1_bgdensity = tmp_current
                min1_pos = k

            }else if(tmp_current > min1_bgdensity && tmp_current < min2_bgdensity){

                min2_bgdensity = tmp_current
                min2_pos = k
            }
        }

        if(min2_pos == -1){
            min2_pos = min1_pos + 1
            min2_bgdensity = density_noise[min2_pos]
        }

        min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos]) / (area_ann[min1_pos] + area_ann[min2_pos])

        # Print catalog density noise -------------------------------------------------------------------
        if(edit_mode == yes){
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", "edit_"//id_obj[obj_pos], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")
        }else{
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", id_obj[obj_pos], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")
        }
        # END BG ESTIMATION -----------------------------------------------------------------------------

        printf("\r - Analyzing object: %d / %d", i, obj_f)

        # For the aperture size: # (j=1 =>) scale_r[j]=0.25 : 0.05 : 5.0 (j=96) [default: j=1:46:+1]
        for(j=6; j<=76; j+=5){

            # Measurement apperture: ANILLO EXTERIOR (binary area): ---------------------
            imdelete(tmp_dir//"/"//"tmp_aperture_ext", >& "dev$null")
            imexpr(expre1//" ? 1 : 0", tmp_dir//"/"//"tmp_aperture_ext", side_frame[obj_pos]/2, side_frame[obj_pos]/2, scale_r[j]*petro_r[obj_pos]*a_img[obj_pos], scale_r[j]*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
            # Measurement apperture: ANILLO INTERIOR (binary area): ---------------------
            imdelete(tmp_dir//"/"//"tmp_aperture_int", >& "dev$null")
            # NOTE: expre1//" ? 0 : 1", former invert
            imexpr(expre1//" ? 0 : 1", tmp_dir//"/"//"tmp_aperture_int", side_frame[obj_pos]/2, side_frame[obj_pos]/2, scale_r[j-5]*petro_r[obj_pos]*a_img[obj_pos], scale_r[j-5]*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)
            # Measurement apperture: ANILLO ----------------------------------------------
            imdelete(tmp_dir//"/"//"tmp_aperture_ann", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_aperture_ann", tmp_dir//"/"//"tmp_aperture_ext", tmp_dir//"/"//"tmp_aperture_int", verb-)

            # Asymmetrical pixel image in aperture[obj_pos]
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_asymmpix_ap", asymmpixel_img, tmp_dir//"/"//"tmp_aperture_ann", verb-)
            # Asymmetrical pixels counting:
            imstat(tmp_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_asymmpix = meanpix * ttlpix

            # Total pixels (N_tot) alpha = n_asymmpix / N_tot
            imdelete(tmp_dir//"/"//"tmp_areattl_ap", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_areattl_ap", obs_dir//"/"//"area_obs_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture_ann", verb-)
            imstat(tmp_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_total = meanpix * ttlpix

            # CORRECTION NOISE ========================================================================================
            # Area (apertura de medida) para corregir el fondo: (exterior[j]**2 - interior[j-5]**2)
            delta_area = const_pi * a_img[obj_pos] * b_img[obj_pos] * petro_r[obj_pos]**2 * (scale_r[j]**2 - scale_r[j-5]**2)

            # ALPHA ASYMETRRY INDEX CALCULATION ///////////////////////////////////////////////////////////////////////
            if(n_total <= 1){
                asymm_area = 0
            }else{
                asymm_area = (n_asymmpix - (delta_area * min_densitybg)) / n_total
            }
            # /////////////////////////////////////////////////////////////////////////////////////////////////////////

            # PRINT CATALOGS ---------------------------------------------------------
            if(j == 6){
                # Edit Mode = YES overwrite like "edit_ID_OBJT"
                if(edit_mode != no){
                    #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: first)
                    printf("%32s %6.3f %6d %8d", "edit_"//id_obj[obj_pos], (3/petro_r[obj_pos]), n_total, n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    #       %ID  %Nb %db   %fr   %Nt %Areacorr_1 (II. Noise pixel SET: first)
                    printf("%32s %6d %7.4f %6.3f %6d %8.2f", "edit_"//id_obj[obj_pos], nbg_noisepix, min_densitybg, (3/petro_r[obj_pos]), n_total, delta_area, >> out_cat//"noisepix_set.cat")

                    # III. Asymmetry area SET: first
                    printf("%32s %8.4f", "edit_"//id_obj[obj_pos], asymm_area, >> out_cat//"areaindex_set.cat")
                }else{
                    #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: first)
                    printf("%32s %6.3f %6d %8d", id_obj[obj_pos], (3/petro_r[obj_pos]), n_total, n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    #       %ID  %Nb %db   %fr   %Nt %Areacorr_1 (II. Noise pixel SET: first)
                    printf("%32s %6d %7.4f %6.3f %6d %8.2f", id_obj[obj_pos], nbg_noisepix, min_densitybg, (3/petro_r[obj_pos]), n_total, delta_area, >> out_cat//"noisepix_set.cat")

                    # III. Asymmetry area SET: first
                    printf("%32s %8.4f", id_obj[obj_pos], asymm_area, >> out_cat//"areaindex_set.cat")
                }

            }else if(j == 76){
                # I. Asymmetrical pixel SET: last
                printf(" %8d\n", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                # II. Noise pixel SET: last
                printf(" %8.2f\n", delta_area, >> out_cat//"noisepix_set.cat")

                # III. Asymmetry area SET: last
                printf(" %8.4f\n", asymm_area, >> out_cat//"areaindex_set.cat")

            }else{
                # I. Asymetrical pixel SET: mid
                printf(" %8d", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                # II. Noise pixel SET: mid
                printf(" %8.2f", delta_area, >> out_cat//"noisepix_set.cat")

                # III. Asymmetry area SET: mid
                printf(" %8.4f", asymm_area, >> out_cat//"areaindex_set.cat")
            }

            # 1.5, 2 and 3 Petrosian radius output MAIN catalog (Fix apertures) ========================================
            # ID_OBJ RA DEC Dccl alpha_1.5 alpha_2.0 alpha_3.0
            if(j == 26){
                # MAIN CATALOG: 1.0xRp (Overwrite catalogs if edit_mode = yes)
                if(edit_mode == yes){
                    # IV. Asymetry area global with center distance
                    printf("%32s %11.8f %11.8f %5.3f %11.4f", "edit_"//id_obj[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], asymm_area, >> out_cat//"areaindex.cat")
                }else{
                    # IV. Asymetry area global with center distance
                    printf("%32s %11.8f %11.8f %5.3f %11.4f", id_obj[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], asymm_area, >> out_cat//"areaindex.cat")
                }

                # ALPHA INDEX DS9 REGION: refrence (Rp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(1.5 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(1.5 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(1.5rp): '//str(asymm_area)//'}'
                print(expre, >> out_ds9_cat)

            }else if(j == 36){

                # MAIN CATALOG: 1.5xRp
                printf(" %11.4f", asymm_area, >> out_cat//"areaindex.cat")

                # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(2 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(2 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={'//str(id_obj[obj_pos])//', (2.0rp): '//str(asymm_area)//'}'
                print(expre, >> out_ds9_cat)

            }else if(j == 56){

                # MAIN CATALOG: 2xRp
                printf(" %11.4f\n", asymm_area, >> out_cat//"areaindex.cat")

                # ALPHA INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(3 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(3 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(3rp): '//str(asymm_area)//'}'
                print(expre, >> out_ds9_cat)

            }
            # END PRINT CATALOGS ------------------------------------------------

            imdelete(tmp_dir//"/"//"tmp_aperture_ext", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_aperture_int", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_aperture_ann", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")

        }

        for(k=1;k <= 4; k += 1){
            imdelete(tmp_dir//"/"//"tmp_ann_"//str(k), >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_bgpix_ann"//str(k), >& "dev$null")
        }

    }

    if(rot_alpha == no){

        rot_alpha = yes
        print("\n\n-------------------- ROTATED ALPHA INDEX --------------------\n")

        goto rotated_index
    }

    if(edit_mode != no){
        print("\n - Releasing edit asymmetry catalogs... ok")
    }else{
        print("\n - Releasing asymmetry catalogs... ok")
    }
    print("")
    print("> All done (in x.x s) ")
    #_______________________ END AREA ASYMMETRICAL INDEX ___________________________|

exit_task:

    # print("Exit task.")
    print("-------------------------------------------------------------")
    print("")
    beep

end







