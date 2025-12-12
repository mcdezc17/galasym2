procedure prfl_galasym2_96()

# FOR ABELL 496 TEST / default cl script name: galasym2_96_prf.cl
# CUMULATIVE ALPHA INDEX PER APERTURES alpha(in r/rp) = N_asymm(in r) / N_ttl(in r)
# Other forms are:
#                   - cumulative by all galaxy (alpha(r/rp) = N_asymm(in r) / N_ttl)
#                   - by annulus apertures (alpha(r/rp) = N_asymm(in [r-r_delta, r]) / N_ttl(in [r-r_delta, r])

# GALASYM2 ROTATIONAL-INDEX ALPHA
# GALASYM2 (MAC OS) ALL COMMENTS IHERITED

string measure_img = "A496J.fits"                   {prompt = "FITS observed data"}
string radec_list  = "tables/members_A496J.ascii"   {prompt = "[deg] members list [ascii] to match"}
string detect_img  = "no"                           {prompt = "Detection image for SExtractor"}
real   low_clip    = 1.00                           {prompt = "Low limit (relative to rms_bg)"}
string hicntr_clip = "10.0"                         {prompt = "Upper clip center (int or 'off')"}
string hioutr_clip = "10.0"                         {prompt = "Upper clip outer (int or 'off')"}
real   pix_scale   = 0.3                            {prompt = "Pixel scale (arcsec/pixel)"}
string obj_center  = "71"                           {prompt = "Center obj. (integer radeclist or string 'no','ch')"}
real   clredshift  = 0.033                          {prompt = "Cluster redshift (e.g. 0.033"}
bool   edit_mode   = no                             {prompt = "Edit objects to recompute indexes"}
string key_sex     = "sex"                          {prompt = "Keyword to run SExtractor"}
string key_psfex   = "psfex"                        {prompt = "Keyword to run PSFEx"}
string key_ds9     = "ds9"                          {prompt = "Keyword to run DS9 viewer"}
bool   index_calc  = yes                            {prompt = "To skyp index calculation"}
#string input_list  = "no"                          {prompt = "List of objects to analyze (ascii)"}
#real   gbl_index  = 2.00                           {prompt = "Aperture for index (in petrosian radius)"}
# bool   model_fit   = yes                          {prompt = "Run PSFEx + SExtractor?"}


begin

    # Movidas del prompt ultimamente / chechk the definitions later:

    string input_list
    bool model_fit
    real hicen_clip, hiout_clip
    real nx, ny
    string areaglxy_img, centermodmask_img, areaglxy_cntrmsk_img, areacntr_img
    string areaglxy_cntrmsk_maxaper_img
    real SNR_total[999], SNR_ann_total[999]
    real S_total, noise_total
    real average_SNR_aper, n_pixels_avrg_snr, sum_n_snr_pixels
    real average_SNR_ann, n_ann_pixels_avrg_snr, sum_n_ann_snr_pixels


    # DEFINICIÓN DE VARIABLES  ALPHA --------------------------

    real const_pi

    string config_dir, psfex_dir, prepsfex_dir, outpsfex_dir, sex_dir, outsex_dir

    string config_prepsfex, param_prepsfex, conv_prepsfex, cat_prepsfex

    string config_psfex

    string config_sex, param_sex, conv_sex, cat_sex

    bool scndimg_bool, objcenter_bool, tmp_bool, tmp_exit_distance

    string alpha_dir, data_dir, alphaimg_dir, dataimg_dir
    string seg_dir, obs_dir, mod_dir, bg_dir, res_dir, asymm_dir
    string file_dir, ds9_dir, cat_dir, tmp_dir

    string seg_img, mod_img, res_img, asymmpixel_img, bg_img, bgrms_img, psf_fit

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

    real min1_bgdensity, min2_bgdensity, min3_bgdensity, min4_bgdensity, tmp_current

    int min1_pos, min2_pos, min3_pos, min4_pos

    real min_densitybg, ttl_rho

    real area_ann[4], n_noisepix[4], density_noise[4]

    real delta_area, nbg_noisepix, n_asymmpix, ap_n_areattl, n_areattl[999], prfl_index_alpha, cum_index_alpha

    # LOCAL VARIABLES DEFINITION ROTATED-ALPHA

    string rot_asymm_dir, img_to_rot, img_out_rot

    bool rot_alpha

    string asymmpixel_head, rot_cat_dir, out_cat, out_ds9_cat

    real tmp_real, tmp_info[199]


    # Conversiones de tipos de variable (hicen_clip) ================================================
    # -
    if(strlwr(hicntr_clip) == "off" && strlwr(hioutr_clip) != "off"){
        # Lee directorio como p.ej.: alpha_2.0_nn_10.0
        # NOTA: verificacion mas robusta del tipo de variable:
        hicen_clip = 1.0e6                                           # Evita crear mas codigo abajo, pero no es lo mejor!
        hiout_clip = real(hioutr_clip)
        # -
        if(hiout_clip > 0 && hiout_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_nn_%.1f\n", low_clip, hiout_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'hioutr_clip' out of range!")}

    }else if(strlwr(hicntr_clip) != "off" && strlwr(hioutr_clip) == "off"){
        # Lee directorio como p.ej.: alpha_2.5_8.0_nn
        hicen_clip = real(hicntr_clip)
        hiout_clip = 1.0e6                                            # Evita crear mas codigo abajo, pero no es lo mejor!
        # -
        if(hicen_clip > 0 && hicen_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_%.1f_nn\n", low_clip, hicen_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'hicntr_clip' out of range!")}

    }else if(strlwr(hicntr_clip) == "off" && strlwr(hioutr_clip) == "off"){
        # -
        hicen_clip = 1.0e6
        hiout_clip = 1.0e6
        # lee directorio:
        printf("alpha_%.1f_nn_nn\n", low_clip) | scan(alpha_dir)
        # -
    }else{
        # -
        hicen_clip = real(hicntr_clip)
        hiout_clip = real(hioutr_clip)
        #-
        # lee directorio:
        printf("alpha_%.1f_%.1f_%.1f\n", low_clip, hicen_clip, hiout_clip) | scan(alpha_dir)
    }
    #alpha_dir = "alpha_"//str(low_clip)
    # ./alpha/images:
    alphaimg_dir = alpha_dir//"/"//"images"
    # ./alpha/images/asymmpix
    asymm_dir = alphaimg_dir//"/"//"asymmpix"
    # ./alpha/images/rot_asymmpix
    rot_asymm_dir = alphaimg_dir//"/"//"rot_asymmpix"
    # =================================================================================================

    # ASIGNACIÓN DE DIRECTORIOS -------------------------
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
    #
    seg_dir = dataimg_dir//"/"//"segmentation"
    # ./alpha/images/observed
    obs_dir = dataimg_dir//"/"//"observed"
    # ./alpha/images/model
    mod_dir = dataimg_dir//"/"//"model"
    # ./alpha/images/residual
    res_dir = dataimg_dir//"/"//"residual"
    #
    bg_dir = dataimg_dir//"/"//"background"

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

    seg_img = outsex_dir//"/"//"check_seg.fits"
    bgrms_img = outsex_dir//"/"//"check_bgrms.fits"
    bg_img = outsex_dir//"/"//"check_bg.fits"
    mod_img = outsex_dir//"/"//"check_mod.fits"
    res_img = outsex_dir//"/"//"check_res.fits"
    psf_fit = outpsfex_dir//"/"//"prepsfex.psf"
    cat_sex = outsex_dir//"/"//"test.cat"

    const_pi = 3.1415926535897932385

    scndimg_bool = no

    model_fit = yes

    objcenter_bool = no

    rot_alpha = no

    tmp_exit_distance = no

    ri_ann = 2.00
    ro_ann = 3.00

    petro_factor = 2.0

    # vector of scale r/rp
    scale_r[1]=0.25
    scale_r[2]=0.30; scale_r[3]=0.35; scale_r[4]=0.40; scale_r[5]=0.45; scale_r[6]=0.50; scale_r[7]=0.55; scale_r[8]=0.60; scale_r[9]=0.65; scale_r[10]=0.70; scale_r[11]=0.75; scale_r[12]=0.80; scale_r[13]=0.85; scale_r[14]=0.90; scale_r[15]=0.95; scale_r[16]=1.00; scale_r[17]=1.05; scale_r[18]=1.10; scale_r[19]=1.15; scale_r[20]=1.20; scale_r[21]=1.25; scale_r[22]=1.30; scale_r[23]=1.35; scale_r[24]=1.40; scale_r[25]=1.45; scale_r[26]=1.50; scale_r[27]=1.55; scale_r[28]=1.60; scale_r[29]=1.65; scale_r[30]=1.70; scale_r[31]=1.75; scale_r[32]=1.80; scale_r[33]=1.85; scale_r[34]=1.90; scale_r[35]=1.95; scale_r[36]=2.00; scale_r[37]=2.05; scale_r[38]=2.10; scale_r[39]=2.15; scale_r[40]=2.20; scale_r[41]=2.25; scale_r[42]=2.30; scale_r[43]=2.35; scale_r[44]=2.40; scale_r[45]=2.45; scale_r[46]=2.50; scale_r[47]=2.55; scale_r[48]=2.60; scale_r[49]=2.65; scale_r[50]=2.70; scale_r[51]=2.75; scale_r[52]=2.80; scale_r[53]=2.85; scale_r[54]=2.90; scale_r[55]=2.95; scale_r[56]=3.00; scale_r[57]=3.05; scale_r[58]=3.10; scale_r[59]=3.15; scale_r[60]=3.20; scale_r[61]=3.25; scale_r[62]=3.30; scale_r[63]=3.35; scale_r[64]=3.40; scale_r[65]=3.45; scale_r[66]=3.50; scale_r[67]=3.55; scale_r[68]=3.60; scale_r[69]=3.65; scale_r[70]=3.70; scale_r[71]=3.75; scale_r[72]=3.80; scale_r[73]=3.85; scale_r[74]=3.90; scale_r[75]=3.95; scale_r[76]=4.00; scale_r[77]=4.05; scale_r[78]=4.10; scale_r[79]=4.15; scale_r[80]=4.20; scale_r[81]=4.25; scale_r[82]=4.30; scale_r[83]=4.35; scale_r[84]=4.40; scale_r[85]=4.45; scale_r[86]=4.50; scale_r[87]=4.55; scale_r[88]=4.60; scale_r[89]=4.65; scale_r[90]=4.70; scale_r[91]=4.75; scale_r[92]=4.80; scale_r[93]=4.85; scale_r[94]=4.90; scale_r[95]=4.95; scale_r[96]=5.00

    tmp_string = tmp_dir//"/"//"tmp_info_process.txt"
    if(access(tmp_string)){

        list = tmp_string
        i = 0
        while(fscan(list,line) != EOF){
            line_info = substr(line, 1, 1)
            if(line_info != "#"){
                i = i + 1

                # measure_img (prompt) = tmp_info[1]
                # radec_list  (prompt) = tmp_info[2]
                # detect_img  (prompt) = tmp_info[3]
                # low_clip    (prompt) = tmp_info[4]
                # hicen_clip  (prompt) = tmp_info[5]
                # hiout_clip  (prompt) = tmp_info[6]
                # pix_scale   (prompt) = tmp_info[7]
                # obj_center  (prompt) = tmp_info[8]
                # clredshift  (prompt) = tmp_info[9]
                # edit_mode   (prompt) = tmp_info[10]
                # key_sex     (prompt) = tmp_info[11]
                # key_psfex   (prompt) = tmp_info[12]
                # key_ds9     (prompt) = tmp_info[13]
                print(line) | scan(tmp_info[i])
            }
        }
        list = ""

        if(strlwr(obj_center) != "no" && strlwr(obj_center) != "n"){

            i_center = int(obj_center)

            if(i_center != tmp_info[8]){

                input_list = alpha_dir//"/"//"inputlist.cat"
                tmp_exit_distance = yes

                delete(tmp_dir//"/"//"tmp_change_distance.cat", ver-, >& "dev$null" )
                printf("#%31s %11s %11s %7s\n", "col1", "col2", "col3", "col4", >> tmp_dir//"/"//"tmp_change_distance.cat")

                goto to_distance
            }else{
                print(" ERR: center object is the same!")
                print(" If you want rerun galasym2, then")
                print(" delete the following file:")
                printf("  :%s\n", tmp_dir//"/"//"tmp_info_process.txt")
                goto exit_task
            }
        }else{
            goto exit_task
        }
    }

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

    # Lee el tamaño de la imagen


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
    if(!access(alpha_dir)){mkdir(alpha_dir)}     # main output: ./alpha
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

            delete(".alpha_dir/sextracted_list.cat", ver-, >& "dev$null")
            copy(cat_sex, alpha_dir//"/"//"sextracted_list.cat")

            # print("\n Output catalog from SEx has been copied in local directory:")
            # print("   as ./'sextractor_to_inputlist'\n")

            # print(" Please select input objects to compute indexes in an (e.g.) 'inputlist.cat'")

        }

        print(" SExtractor results (check_images) exist!")
        print("")

    }

    # FOLDER VERIFICATION OR CREATION ----------------------------
    if(!access(alpha_dir)){mkdir(alpha_dir)}     # main output: ./alpha
    if(!access(tmp_dir)){mkdir(tmp_dir)}     # temporal folder: ./alpha/temp:

    # MATCH BETWEEN RA-DEC_LIST & SEXtracted_OBJECTS: stilts app -------
    print("")
    print("--------------- START STILTS MATCH -------------------------\n")
    print("stilts-tskymatch2 - Crossmatches 2 tables on sky position\n")

    tmp_string = alpha_dir//"/"//"sextracted_list.cat"
    if(!access(tmp_string)){
        copy(cat_sex, tmp_string)
    }

    delete(tmp_dir//"/"//"match_list.cat", ver-, >& "dev$null")
    expre = "! stilts tskymatch2 in1=%s ifmt1=ascii in2=%s ifmt2=ascii ra1=RA dec1=DEC ra2=col2 dec2=col3 error=4 find=best ofmt=ascii out=%s/match_list.cat\n"
    printf(expre, radec_list, tmp_string, tmp_dir) | cl

    print("")
    print("stilts-tpipe - Performs pipeline processing on a table")
    print("")
    delete(alpha_dir//"/"//"inputlist.cat", ver-, >& "dev$null")
    expre ="! stilts tpipe cmd='delcols \"RA DEC col1\"' in=%s/match_list.cat ifmt=ascii ofmt=ascii out=%s/inputlist.cat\n"
    printf(expre, tmp_dir, alpha_dir) | cl
    delete(tmp_dir//"/"//"match_list.cat", ver-, >& "dev$null")

    print("")
    print("------------------ END STILTS MATCH -------------------------\n")
    print("Output information")
    print("Table 1:", radec_list)
    print("Table 2: alpha_dir/sextracted_list.cat")
    print("Table 1&2 match: alpha_dir/inputlist.cat")
    print("-------------------------------------------------------------")

    # inputlist for galasym2 process ----------------------------------
    input_list = alpha_dir//"/"//"inputlist.cat"

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
    if(!access(alphaimg_dir)){mkdir(alphaimg_dir)}     # images folder:      ./alpha/images:
    if(!access(dataimg_dir)){mkdir(dataimg_dir)}       # images folder:      ./data/images:
    if(!access(seg_dir)){mkdir(seg_dir)}
    if(!access(obs_dir)){mkdir(obs_dir)}               # observed images:    ./alpha/images/observed
    if(!access(mod_dir)){mkdir(mod_dir)}               # model images:       ./alpha/images/model
    if(!access(res_dir)){mkdir(res_dir)}               # residual images:    ./alpha/images/residual
    if(!access(bg_dir)){mkdir(bg_dir)}
    if(!access(asymm_dir)){mkdir(asymm_dir)}           # alpha asymm images: ./alpha/images/asymmpix
    if(!access(rot_asymm_dir)){mkdir(rot_asymm_dir)}   # alpha rot_asymm images: ./alpha/images/rot_asymmpix

    if(!access(file_dir)){mkdir(file_dir)}         # files folder:    ./alpha/files:
    if(!access(ds9_dir)){mkdir(ds9_dir)}           # ds9_files:       ./alpha/files/ds9_files
    if(!access(cat_dir)){mkdir(cat_dir)}           # catalogs_files:  ./alpha/files/catalogs
    if(!access(rot_cat_dir)){mkdir(rot_cat_dir)}   # rotational_cataloogs: ./alpha/files/rot_catalogs

    # Enviado para solo calcular otra distancia (center cluster):
    to_distance:

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

    #__________________________________________________________________________
    #___________ Distance of objects to galaxy center _________________________|
    if(strlwr(obj_center) != "no" && strlwr(obj_center) != "n"){

        i_center = int(obj_center)

        if(i_center < 1 || i_center > n_list){
            print(" ERR: Parameter value is out of range must be an integer (within the inputlist)")
            print("      OR a string 'no'")
            goto exit_task
        }

        # objcenter_bool = yes           # line to delete?

        if(access(config_dir//"/"//"ned_calc.py")){
            print("! python3 "//config_dir//"/"//"ned_calc.py ", clredshift, " 70 0.3 0.7") | cl | scan(kp_DA)
        }else{
            print(" erratum: center cluster in arseconds not in Mpc!")
        }

        for(i=1; i<=n_list; i+=1){

            ccdistance_pix[i] = sqrt((xwin_img[i_center] - xwin_img[i])**2 + (ywin_img[i_center] - ywin_img[i])**2)
            ccdistance[i] = ccdistance_pix[i]

            if(pix_scale >= 0){

                ccdistance_arsec[i] = ccdistance_pix[i] * pix_scale
                ccdistance[i] = ccdistance_arsec[i]

                if(access(config_dir//"/"//"ned_calc.py")){

                    ccdistance_Mpc[i] = (ccdistance_arsec[i] * kp_DA) / 1000
                    ccdistance[i] = ccdistance_Mpc[i]
                }

                if(tmp_exit_distance == yes){
                    printf("%32s %11.8f %11.8f %7.3f\n", id_obj[i], ra_j00[i], dec_j00[i], ccdistance[i], >> tmp_dir//"/"//"tmp_change_distance.cat")
                }
            }
        }

        if(tmp_exit_distance == yes){
            # match between two ascii files (STILTS):

            goto exit_task
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
    # -
    # Observed area frame for N total pixels:
    printf(tmp_dir//"/"//"area_%.1f_obs_"//"\n", low_clip) | scan(areaglxy_img)
    # Extended CENTER MASK frame for measure index (source + noise annulus):
    centermodmask_img = tmp_dir//"/"//"centermodelmask_"
    # Center Areas:
    areacntr_img = tmp_dir//"/"//"areacenter_"
    # Observed area without center:
    if(strlwr(hicntr_clip) == "off"){
        printf(tmp_dir//"/"//"area_%.1f_nn_obs_"//"\n", low_clip) | scan(areaglxy_cntrmsk_img)
    }else{
        printf(tmp_dir//"/"//"area_%.1f_%.1f_obs_"//"\n", low_clip, hicen_clip) | scan(areaglxy_cntrmsk_img)
    }
    # Observed maximum area (without center) for cumulative denominator index:
    areaglxy_cntrmsk_maxaper_img = areaglxy_cntrmsk_img//"maxaper_"

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

        # Extended OBSERVED frame for measure index (source + noise annulus)
        tmp_string = obs_dir//"/"//"observed_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save frames observed:
            imcopy(measure_img//trimsection, obs_dir//"/"//"observed_"//id_obj[obj_pos], verb-)
        }

        # Extended MODEL frame for measure index (source + noise annulus):
        tmp_string = mod_dir//"/"//"modmeasure_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended model frames:
            imcopy(mod_img//trimsection, mod_dir//"/"//"modmeasure_"//id_obj[obj_pos], verb-)

        }

        # Extenden RESIDUAL frame for measure index (source + noise annulus):
        tmp_string = res_dir//"/"//"residmeasure_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended residuals frames:
            imcopy(res_img//trimsection, res_dir//"/"//"residmeasure_"//id_obj[obj_pos], verb-)
        }

        # Extenden BACKGROUND_RMS for residual:
        tmp_string = bg_dir//"/"//"bgrms_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended residuals frames:
            imcopy(bgrms_img//trimsection, bg_dir//"/"//"bgrms_"//id_obj[obj_pos], verb-)
        }

        # Extenden BACKGROUND for residual:
        tmp_string = bg_dir//"/"//"bg_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended residuals frames:
            imcopy(bg_img//trimsection, bg_dir//"/"//"bg_"//id_obj[obj_pos], verb-)
        }

        # TO DEFINE SEGMENTATION IMAGE CUTOUTS
        # string seg_dir
        # string seg_img
        # seg_dir =
        # seg_img =

        # Extended SEGMENTATION image:
        tmp_string = seg_dir//"/"//"seg_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended residuals frames:
            imcopy(seg_img//trimsection, seg_dir//"/"//"seg_"//id_obj[obj_pos], verb-)
        }

        # Observed area frame for N total pixels:
        if(!imaccess(areaglxy_img//id_obj[obj_pos])){
            # Save frames observed:
            imexpr("a >= b*c", areaglxy_img//id_obj[obj_pos], obs_dir//"/"//"observed_"//id_obj[obj_pos], low_clip, bg_dir//"/"//"bgrms_"//id_obj[obj_pos], verb-)
        }

        # Extended CENTER MASK frame for measure index (source + noise annulus):
        if(!imaccess(centermodmask_img//id_obj[obj_pos])){
            # Center mask from model:
            imexpr("a <= b*c", centermodmask_img//id_obj[obj_pos], mod_dir//"/"//"modmeasure_"//id_obj[obj_pos], hicen_clip, bg_dir//"/"//"bgrms_"//id_obj[obj_pos], verb-)
        }

        # Center Areas:
        if(!imaccess(areacntr_img//id_obj[obj_pos])){
            # Center area count:
            expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1 && f == 0"
            imexpr(expre, areacntr_img//id_obj[obj_pos], side_frame[obj_pos]/2, side_frame[obj_pos]/2, petro_r[obj_pos]*a_img[obj_pos], petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, centermodmask_img//id_obj[obj_pos], verb-)
        }
        imstat(areacntr_img//id_obj[obj_pos], fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        inner_area[obj_pos] = meanpix * ttlpix
        meanpix = 0
        ttlpix = 0

        # Observed area frame without center:
        if(!imaccess(areaglxy_cntrmsk_img//id_obj[obj_pos])){
            # Save frames observed:
            # imdelete(areaglxy_cntrmsk_img//id_obj[obj_pos], >& "dev$null")
            imexpr("a*b", areaglxy_cntrmsk_img//id_obj[obj_pos], areaglxy_img//id_obj[obj_pos], centermodmask_img//id_obj[obj_pos], verb-)
        }

        # Observed maximum area for cumulative denominator  alpha index:
        if(!imaccess(areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos])){

            imdelete(tmp_dir//"/"//"max_aper_"//id_obj[obj_pos], >& "dev$null")
            expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
            imexpr(expre, tmp_dir//"/"//"max_aper_"//id_obj[obj_pos], side_frame[obj_pos]/2, side_frame[obj_pos]/2, scale_r[26]*petro_r[obj_pos]*a_img[obj_pos], scale_r[26]*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)

            imexpr("a*b", areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos], areaglxy_cntrmsk_img//id_obj[obj_pos], tmp_dir//"/"//"max_aper_"//id_obj[obj_pos], verb-)
        }
        imstat(areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos], fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_areattl[obj_pos] = meanpix * ttlpix
        meanpix = 0
        ttlpix = 0

        # Extended asymmetrical pixels for measure index:
        tmp_string = asymm_dir//"/"//"asymmpix_"//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # From BACKGROUND_RMS:
            imexpr("a*b >= c*e && a*b <= d*e", asymm_dir//"/"//"asymmpix_"//id_obj[obj_pos], res_dir//"/"//"residmeasure_"//id_obj[obj_pos], centermodmask_img//id_obj[obj_pos], low_clip, hiout_clip, bg_dir//"/"//"bgrms_"//id_obj[obj_pos], verb-)
        }

        # Extended rotated asymmetrical pixels for measure rot-index alpha
        tmp_string = img_out_rot//id_obj[obj_pos]
        if(!imaccess(tmp_string)){
            # Save extended rotated asymmpix frames:

            imtranspose(img_to_rot//id_obj[obj_pos]//".fits[*,-*]", rot_asymm_dir//"/"//"tmp_90")
            imtranspose(rot_asymm_dir//"/"//"tmp_90"//".fits[*,-*]", rot_asymm_dir//"/"//"tmp_180")
            imexpr("(a-b)>0", img_out_rot//id_obj[obj_pos], img_to_rot//id_obj[obj_pos], rot_asymm_dir//"/"//"tmp_180", verb-)

            imdelete(rot_asymm_dir//"/"//"tmp_90", >& "dev$null")
            imdelete(rot_asymm_dir//"/"//"tmp_180", >& "dev$null")
        }

        printf("\r - Preparing images: %d%%", (i*100/n_list))
    }
    #_____________________________ END CUT FRAMES __________________________________|

    # To skyp index
    if(index_calc == no){
        print("\n Skyp the index calculations!")
        goto exit_task
    }

    #_______________________________________________________________________________
    #__________________________ AREA ASYMMETRICAL INDEX ____________________________|
    print("\n\n------------------------ ALPHA INDEX ------------------------\n")

    # EDIT MODE: OVERWRITE THE CATALOGS:
    if(edit_mode == no){

        # ASYMMETRY INDEX (output) CATALOGS HEADERS ()*.cat)
        delete(cat_dir//"/"//"asymmpix_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"noisepix_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"prfl_index_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"cum_index_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"SNR_set.cat", >& "dev$null")
        delete(cat_dir//"/"//"SNR_ann_set.cat", >& "dev$null")

        for(j=1; j<=57; j+=1){
            if(j == 1){
                #        %ID  %fr %Nt %Nasymm_1 (I. N asymm. pixels SET: first)
                printf("#%31s %6s %6s N_%4.2frp", "ID_OBJ", "3/rp", "Nttl", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                #        %ID  %Nb %db %fr %Nt %Areacorr_1 (II. Noise pixels SET: first)
                printf("#%31s %6s %7s %6s %6s d_%4.2frp", "ID_OBJ", "Nbg", "rho_bg", "3/rp", "Nttl", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III. PROFILE Asymmetry area SET: first
                printf("#%31s prfl_%4.2frp", "ID_OBJ", scale_r[j], >> cat_dir//"/"//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: first
                printf("#%31s cum_%4.2frp", "ID_OBJ", scale_r[j], >> cat_dir//"/"//"cum_index_set.cat")

                # V. NORMAL SNR CATALOG
                printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[j], >> cat_dir//"/"//"SNR_set.cat")

                # VI. ANULLAR SNR CATALOG
                print("# NOTE: SNR_set for annular if hicen(ter)_clip != 'off'", >> cat_dir//"/"//"SNR_ann_set.cat")
                printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[j], >> cat_dir//"/"//"SNR_ann_set.cat")

            }else if(j == 57){
                #        %Nasymm_last (I. N asymm. pixels SET: last)
                printf(" N_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                # II. Noise pixel SET: last
                printf(" d_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III. PROFILE Asymmetry area SET: first
                printf(" prfl_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: first
                printf(" cum_%4.2frp\n", scale_r[j], >> cat_dir//"/"//"cum_index_set.cat")

                # V. SNR CATALOG
                printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[j], "SNR_ttl_1rp", >> cat_dir//"/"//"SNR_set.cat")

                # VI. ANULLAR SNR CATALOG
                printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[j], "SNR_ttl_1rp", >> cat_dir//"/"//"SNR_ann_set.cat")

            }else{
                #        %Nasymm_i (All parameters catalog:)
                printf(" N_%4.2frp", scale_r[j], >> cat_dir//"/"//"asymmpix_set.cat")

                # II. Noise pixel SET: mid
                printf(" d_%4.2frp", scale_r[j], >> cat_dir//"/"//"noisepix_set.cat")

                # III. PROFILE Asymmetry area SET: mid
                printf(" prfl_%4.2frp", scale_r[j], >> cat_dir//"/"//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: mid
                printf(" cum_%4.2frp", scale_r[j], >> cat_dir//"/"//"cum_index_set.cat")

                # V. SNR CATALOG
                printf(" ⟨SNR⟩_%4.2frp", scale_r[j], >> cat_dir//"/"//"SNR_set.cat")

                # VI. ANULLAR SNR CATALOG
                printf(" ⟨SNR⟩_%4.2frp", scale_r[j], >> cat_dir//"/"//"SNR_ann_set.cat")

            }
        }

        # HEADER of rotated alpha-set catalogs = alpha-set catalogs => copy:
        delete(rot_cat_dir//"/"//"rot_asymmpix_set.cat", >& "dev$null")
        delete(rot_cat_dir//"/"//"rot_noisepix_set.cat", >& "dev$null")
        delete(rot_cat_dir//"/"//"rot_prfl_index_set.cat", >& "dev$null")
        copy(cat_dir//"/"//"asymmpix_set.cat", rot_cat_dir//"/"//"rot_asymmpix_set.cat")
        copy(cat_dir//"/"//"noisepix_set.cat", rot_cat_dir//"/"//"rot_noisepix_set.cat")
        copy(cat_dir//"/"//"prfl_index_set.cat", rot_cat_dir//"/"//"rot_prfl_index_set.cat")
        copy(cat_dir//"/"//"cum_index_set.cat", rot_cat_dir//"/"//"rot_cum_index_set.cat")

        # PROFILE RESIDUAL HEADER CATALOG: MAIN -----------------------------------------------------------
        delete(cat_dir//"/"//"prfl_index_main.cat",  >& "dev$null")
        # IV. Asymetry area global with center distance
        printf("#%31s %11s %11s %11s %11s %7s prf%3.1f_1.0rp prfl%3.1f_1.5rp prfl%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_clip, low_clip, low_clip, >> cat_dir//"/"//"prfl_index_main.cat")

        # PROFILE ROTATIONAL RESIDUAL HEADER CATALOG: MAIN
        delete(rot_cat_dir//"/"//"rot_prfl_index_main.cat",  >& "dev$null")
        printf("#%31s %11s %11s %11s %11s %7s prfl%3.1f_1.0rp prfl%3.1f_1.5rp prfl%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_clip, low_clip, low_clip, low_clip, low_clip, low_clip, >> rot_cat_dir//"/"//"rot_prfl_index_main.cat")

        # CUMULATIVE HEADER CATALOG: MAIN -----------------------------------------------------------------
        delete(cat_dir//"/"//"cum_index_main.cat",  >& "dev$null")
        # IV. Asymetry area global with center distance
        printf("#%31s %11s %11s %11s %11s %7s cum%3.1f_1.0rp cum%3.1f_1.5rp cum%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_clip, low_clip, low_clip, >> cat_dir//"/"//"cum_index_main.cat")

        # CUMULATIVE ROTATIONAL RESIDUAL HEADER CATALOG: MAIN
        delete(rot_cat_dir//"/"//"rot_cum_index_main.cat",  >& "dev$null")
        printf("#%31s %11s %11s %11s %11s %7s cum%3.1f_1.0rp cum%3.1f_1.5rp cum%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_clip, low_clip, low_clip, low_clip, low_clip, low_clip, >> rot_cat_dir//"/"//"rot_cum_index_main.cat")
        #--------------------------------------------------------------------------------------------------

        # HEADER CATALOG: density noise catalog -----------------------------------------------------------
        delete(cat_dir//"/"//"patch_bg_set.cat",  >& "dev$null")
        printf("#%31s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "ID_OBJ", "min_rho", "ttl_rho", "A1_ann", "N1_ann", "rho1", "A2_ann", "N2_ann", "rho2", "A3_ann", "N3_ann", "rho3", "A4_ann", "N4_ann", "rho4", >> cat_dir//"/"//"patch_bg_set.cat")

        # HEADER CATALOG: rotated-alpha density noise catalog
        delete(rot_cat_dir//"/"//"rot_patch_bg_set.cat",  >& "dev$null")
        copy(cat_dir//"/"//"patch_bg_set.cat", rot_cat_dir//"/"//"rot_patch_bg_set.cat")
        #--------------------------------------------------------------------------------------------------

        # HEADER ACATALOG: DS9 regions asymmetry index
        delete(ds9_dir//"/"//"prfl_index.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"prfl_index.reg")
        print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"prfl_index.reg")
        print("fk5", >> ds9_dir//"/"//"prfl_index.reg")
        # copy rotational
        copy(ds9_dir//"/"//"prfl_index.reg", ds9_dir//"/"//"rot_prfl_index.reg")

        # HEADER ACATALOG: DS9 regions asymmetry index
        delete(ds9_dir//"/"//"cum_index.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"cum_index.reg")
        print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"cum_index.reg")
        print("fk5", >> ds9_dir//"/"//"cum_index.reg")
        # copy rotational
        copy(ds9_dir//"/"//"cum_index.reg", ds9_dir//"/"//"rot_cum_index.reg")
        # -------------------------------------------------------------------------- END OF HEADERS of catalogs
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

        out_ds9_cat = ds9_dir//"/"//"rot_"

    }else{

        if(edit_mode == yes){
            asymmpixel_head = asymm_dir//"/"//"edit_asymmpix_"
        }else{
            asymmpixel_head = asymm_dir//"/"//"asymmpix_"
        }

        out_cat = cat_dir//"/"

        out_ds9_cat = ds9_dir//"/"
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

        # Take the four parts ordered by background density (min to max)
        min1_bgdensity = 1.0e6
        min1_pos = -1
        min2_bgdensity = 1.0e6
        min2_pos = -1
        min3_bgdensity = 1.0e6
        min3_pos = -1
        min4_bgdensity = 1.0e6
        min4_pos = -1

        for(k = 1; k <= 4; k += 1){
            tmp_current = density_noise[k]

            if(tmp_current < min1_bgdensity){
                # Shift all values down
                min4_bgdensity = min3_bgdensity
                min4_pos = min3_pos
                min3_bgdensity = min2_bgdensity
                min3_pos = min2_pos
                min2_bgdensity = min1_bgdensity
                min2_pos = min1_pos
                min1_bgdensity = tmp_current
                min1_pos = k
            }else if(tmp_current < min2_bgdensity){
                # Shift values 2, 3 down
                min4_bgdensity = min3_bgdensity
                min4_pos = min3_pos
                min3_bgdensity = min2_bgdensity
                min3_pos = min2_pos
                min2_bgdensity = tmp_current
                min2_pos = k
            }else if(tmp_current < min3_bgdensity){
                # Shift value 3 down
                min4_bgdensity = min3_bgdensity
                min4_pos = min3_pos
                min3_bgdensity = tmp_current
                min3_pos = k
            }else if(tmp_current < min4_bgdensity){
                min4_bgdensity = tmp_current
                min4_pos = k
            }
        }

        # Handle uninitialized positions (shouldn't happen with 4 iterations over 4 elements)
        if(min2_pos == -1){min2_pos = min1_pos}
        if(min3_pos == -1){min3_pos = min2_pos}
        if(min4_pos == -1){min4_pos = min3_pos}

        # min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos]) / (area_ann[min1_pos] + area_ann[min2_pos])
        # min_densitybg = (n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min2_pos] + area_ann[min3_pos])
        min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min1_pos] + area_ann[min2_pos] + area_ann[min3_pos])
        # min_densitybg = ttl_rho

        # Print catalog density noise -------------------------------------------------------------------
        if(edit_mode == yes){
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", "edit_"//id_obj[obj_pos], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")
        }else{
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", id_obj[obj_pos], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")
        }
        # END BG ESTIMATION -----------------------------------------------------------------------------
        printf("\r")
        printf("\r - Analyzing object: %d / %d", i, obj_f)


        # For the aperture size:
        for(j=1; j<=57; j+=1){

            # Measurement apperture (binary area):
            imdelete(tmp_dir//"/"//"tmp_aperture", >& "dev$null")
            imexpr(expre1//" ? 1 : 0", tmp_dir//"/"//"tmp_aperture", side_frame[obj_pos]/2, side_frame[obj_pos]/2, scale_r[j]*petro_r[obj_pos]*a_img[obj_pos], scale_r[j]*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)


            # ******************* TO DEFINE SNR TOTAL ********************************************************
            # real SNR_total[999], SNR_ann_total[999]
            # real S_total, noise_total
            # SNR total: De acuerdo a Rodriguez-Gomez et al. (2019), comprobamos que SNR_Lotz+04 is aprox. SNR(1rp)=I/BGMRS_map
            if(scale_r[j] == scale_r[16] && rot_alpha == no){

                imexpr("(b > 0) && (c > 0) ? a : 0", tmp_dir//"/"//"tmp_obs_to_SNRttl", obs_dir//"/"//"observed_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], ver-)
                imstat(tmp_dir//"/"//"tmp_obs_to_SNRttl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                S_total = (meanpix * ttlpix)

                imexpr("(a > 0) && (b > 0) ? (a**2) : 0", tmp_dir//"/"//"tmp_bgrms_to_SNRttl", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", ver-)
                imstat(tmp_dir//"/"//"tmp_bgrms_to_SNRttl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                noise_total = sqrt(meanpix * ttlpix)

                SNR_total[obj_pos] = S_total / noise_total
                # print("\n    SNR total = ", SNR_total[obj_pos])

                imdelete(tmp_dir//"/"//"tmp_obs_to_SNRttl", >& "dev$null")
                imdelete(tmp_dir//"/"//"tmp_bgrms_to_SNRttl", >& "dev$null")

                # TOTAL SNR for annular aperture
                if(strlwr(hicntr_clip) != "off"){

                    imexpr("(b > 0) && (c > 0) && (d > 0) ? a : 0", tmp_dir//"/"//"tmp_obs_to_SNRttl", obs_dir//"/"//"observed_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], centermodmask_img//id_obj[obj_pos], ver-)
                    imstat(tmp_dir//"/"//"tmp_obs_to_SNRttl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    S_total = (meanpix * ttlpix)

                    imexpr("(a > 0) && (b > 0) && (c > 0) ? (a**2) : 0", tmp_dir//"/"//"tmp_bgrms_to_SNRttl", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", centermodmask_img//id_obj[obj_pos], ver-)
                    imstat(tmp_dir//"/"//"tmp_bgrms_to_SNRttl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    noise_total = sqrt(meanpix * ttlpix)

                    SNR_ann_total[obj_pos] = S_total / noise_total
                    # print("\n    SNR annulus total = ", SNR_ann_total[obj_pos])

                    imdelete(tmp_dir//"/"//"tmp_obs_to_SNRttl", >& "dev$null")
                    imdelete(tmp_dir//"/"//"tmp_bgrms_to_SNRttl", >& "dev$null")
                }
            }
            #
            # *************** TO DEFINE AVERAGE SNR or ⟨SNR⟩ *************************************************
            # real average_SNR_aper, n_pixels_avrg_snr, sum_n_snr_pixels
            # real average_SNR_ann, n_ann_pixels_avrg_snr, sum_n_ann_snr_pixels
            # Definir los RMS_i validos
            if(rot_alpha == no){

                imexpr("(a > 0) && (b > 0) ? 1 : 0", tmp_dir//"/"//"tmp_n_pixels", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", ver-)
                imstat(tmp_dir//"/"//"tmp_n_pixels", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                n_pixels_avrg_snr = (meanpix * ttlpix)

                imexpr("(c > 0) ? (a/b) : 0", tmp_dir//"/"//"tmp_snr_per_pixel", obs_dir//"/"//"observed_"//id_obj[obj_pos], bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_n_pixels", ver-)
                imstat(tmp_dir//"/"//"tmp_snr_per_pixel", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                sum_n_snr_pixels = (meanpix * ttlpix)

                average_SNR_aper = (sum_n_snr_pixels / n_pixels_avrg_snr)

                imdelete(tmp_dir//"/"//"tmp_n_pixels", >& "dev$null")
                imdelete(tmp_dir//"/"//"tmp_snr_per_pixel", >& "dev$null")

                # AVERAGE SNR for annular aperture
                if(strlwr(hicntr_clip) != "off"){

                    imexpr("(a > 0) && (b > 0) && (c > 0) ? 1 : 0", tmp_dir//"/"//"tmp_n_ann_pixels", bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", centermodmask_img//id_obj[obj_pos], ver-)
                    imstat(tmp_dir//"/"//"tmp_n_ann_pixels", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    n_ann_pixels_avrg_snr = (meanpix * ttlpix)

                    if(n_ann_pixels_avrg_snr > 0){

                        imexpr("(c > 0) ? (a/b) : 0", tmp_dir//"/"//"tmp_snr_ann_per_pixel", obs_dir//"/"//"observed_"//id_obj[obj_pos], bg_dir//"/"//"bgrms_"//id_obj[obj_pos], tmp_dir//"/"//"tmp_n_ann_pixels", ver-)
                        imstat(tmp_dir//"/"//"tmp_snr_ann_per_pixel", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                        sum_n_ann_snr_pixels = (meanpix * ttlpix)

                        average_SNR_ann = (sum_n_ann_snr_pixels / n_ann_pixels_avrg_snr)
                        imdelete(tmp_dir//"/"//"tmp_snr_ann_per_pixel", >& "dev$null")

                    }else{
                        average_SNR_ann = 0
                    }

                    imdelete(tmp_dir//"/"//"tmp_n_ann_pixels", >& "dev$null")

                }
            }
            # ************************************************************************************************

            # Asymmetrical pixel image in aperture[obj_pos]
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_asymmpix_ap", asymmpixel_img, tmp_dir//"/"//"tmp_aperture", verb-)
            # Asymmetrical pixels counting:
            imstat(tmp_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_asymmpix = meanpix * ttlpix

            # aper. Total pixels (N_tot) alpha = n_asymmpix / N_tot(in aperture)
            imdelete(tmp_dir//"/"//"tmp_areattl_ap", >& "dev$null")
            # imexpr("a*b", tmp_dir//"/"//"tmp_areattl_ap", areaglxy_cntrmsk_img//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", verb-)
            imexpr("a*b", tmp_dir//"/"//"tmp_areattl_ap", areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos], tmp_dir//"/"//"tmp_aperture", verb-)
            imstat(tmp_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            ap_n_areattl = meanpix * ttlpix

            # ALPHA ASYMETRRY INDEX CALCULATION: ==========================================
            # area_delta: área donde se aplica o escala la (densidad) de correction
            # delta_area = const_pi * (a_img[obj_pos] * b_img[obj_pos]) * (scale_r[j] * petro_r[obj_pos])**2
            # delta_area = delta_area - inner_area[obj_pos]
            # if(delta_area <= 0){ delta_area = 0 }

            # alpha Asymmetry index calculation:
            if(scale_r[j] * petro_r[obj_pos] <= 0.0){  # --> If change 3.0 to 0.0, then uncomment the '# (<= 0.0)' lines:
                delta_area = 0
                if(ap_n_areattl <= 1){
                    prfl_index_alpha = 0
                }else{
                    prfl_index_alpha = n_asymmpix / ap_n_areattl
                }
                cum_index_alpha = n_asymmpix / n_areattl[obj_pos]
            }else{

                # (<= 0.0):
                delta_area = const_pi * (a_img[obj_pos] * b_img[obj_pos]) * ((scale_r[j] * petro_r[obj_pos])**2) - inner_area[obj_pos]
                # (<= 0.0):
                if(delta_area <= 0){ delta_area = 0 }

                # -> Comment the following line only #if uncomment past '# (<= 0.0)' lines.
                # delta_area = const_pi * (a_img[obj_pos] * b_img[obj_pos]) * ((scale_r[j] * petro_r[obj_pos])**2 - 9.0)

                if(ap_n_areattl <= 1){
                    prfl_index_alpha = 0
                }else{
                    prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / ap_n_areattl
                }
                cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / n_areattl[obj_pos]
            }

            # if(ap_n_areattl <= 1){
            #     prfl_index_alpha = 0
            # }else{
            #     # PROFILE:
            #     prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / ap_n_areattl
            # }
            # CUMULATIVE:
            # cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / (iso_areaf[obj_pos] - inner_area[obj_pos])
            # cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / n_areattl[obj_pos]
            # ====================================================================================

            # ====================================================================================
            # PRINT CATALOGS
            # ====================================================================================
            #
            if(j == 1){
                # Edit Mode = YES overwrite like "edit_ID_OBJT"
                if(edit_mode != no){
                    # EDIT MODE       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: EDIT MODE)
                    printf("%32s %6.3f %6d %8d", "edit_"//id_obj[obj_pos], (3/petro_r[obj_pos]), iso_area[obj_pos], n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    # EDIT MODE      %ID  %Nb %db   %fr   %Nt %Areacorr_1 (II. Noise pixel SET: EDIT MODE)
                    printf("%32s %6d %7.4f %6.3f %6d %8.2f", "edit_"//id_obj[obj_pos], nbg_noisepix, min_densitybg, (3/petro_r[obj_pos]), iso_area[obj_pos], delta_area, >> out_cat//"noisepix_set.cat")

                    # EDIT MODE III. PROFILE Asymmetry area SET: EDIT MODE
                    printf("%32s %11.4f", "edit_"//id_obj[obj_pos], prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                    # EDIT MODE IV. CUMULATIVE Asymmetry area SET: EDIT MODE
                    printf("%32s %11.4f", "edit_"//id_obj[obj_pos], cum_index_alpha, >> out_cat//"cum_index_set.cat")

                    # EDIT MODE V. NORMAL SNR CATALOG: EDIT MODE

                    # EDIT MODE VI. ANNULAR SNR CATALOG: EDIT MODE

                }else{
                    #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: first)
                    printf("%32s %6.3f %6d %8d", id_obj[obj_pos], (3/petro_r[obj_pos]), iso_area[obj_pos], n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    #       %ID  %Nb %db   %fr   %Nt %Areacorr_1 (II. Noise pixel SET: first)
                    printf("%32s %6d %7.4f %6.3f %6d %8.2f", id_obj[obj_pos], nbg_noisepix, min_densitybg, (3/petro_r[obj_pos]), iso_area[obj_pos], delta_area, >> out_cat//"noisepix_set.cat")

                    # III. Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[obj_pos], prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[obj_pos], cum_index_alpha, >> out_cat//"cum_index_set.cat")

                    # SNR CATALOG's
                    if(rot_alpha == no){

                        # V. NORMAL SNR CATALOG
                        printf("%32s %11.4f", id_obj[obj_pos], average_SNR_aper, >> cat_dir//"/"//"SNR_set.cat")

                        if(strlwr(hicntr_clip) != "off"){
                            # VI. ANNULAR SNR CATALOG
                            printf("%32s %11.4f", id_obj[obj_pos], average_SNR_ann, >> cat_dir//"/"//"SNR_ann_set.cat")
                        }
                    }

                }

            }else if(j == 57){
                # I. Asymmetrical pixel SET: last
                printf(" %8d\n", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                # II. Noise pixel SET: last
                printf(" %8.2f\n", delta_area, >> out_cat//"noisepix_set.cat")

                # III. PROFILE Asymmetry area SET: last
                printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: last
                printf(" %11.4f\n", cum_index_alpha, >> out_cat//"cum_index_set.cat")

                # SNR CATALOG's
                if(rot_alpha == no){

                    # V. NORMAL SNR CATALOG
                    printf(" %11.4f\n", SNR_total[obj_pos], >> cat_dir//"/"//"SNR_set.cat")

                    if(strlwr(hicntr_clip) != "off"){
                        # VI. ANNULAR SNR CATALOG
                        printf(" %11.4f\n", SNR_ann_total[obj_pos], >> cat_dir//"/"//"SNR_ann_set.cat")
                    }
                }

            }else{
                # I. Asymetrical pixel SET: mid
                printf(" %8d", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                # II. Noise pixel SET: mid
                printf(" %8.2f", delta_area, >> out_cat//"noisepix_set.cat")

                # III. PROFILE Asymmetry area SET: mid
                printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: mid
                printf(" %11.4f", cum_index_alpha, >> out_cat//"cum_index_set.cat")

                # SNR CATALOG's
                if(rot_alpha == no){

                    # V. NORMAL SNR CATALOG
                    printf(" %11.4f", average_SNR_aper, >> cat_dir//"/"//"SNR_set.cat")

                    if(strlwr(hicntr_clip) != "off"){
                        # VI. ANNULAR SNR CATALOG
                        printf(" %11.4f", average_SNR_ann, >> cat_dir//"/"//"SNR_ann_set.cat")
                    }
                }
            }

            # ====================================================================================
            # PRINT CATALOGS: Tree fixed apertures
            # ====================================================================================
            #
            # 1.05, 1.55 and 2.05 Petrosian radius output catalog (Fix apertures)
            if(j == 16){
                # MAIN CATALOG: 1.0xRp (Overwrite catalogs if edit_mode = yes)
                if(edit_mode == yes){
                    # PROFILE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", "edit_"//id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                    # CUMULATIVE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", "edit_"//id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], cum_index_alpha, >> out_cat//"cum_index_main.cat")

                }else{
                    # PROFILE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                    # CUMULATIVE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], ccdistance[obj_pos], cum_index_alpha, >> out_cat//"cum_index_main.cat")
                }

                # PROFILE INDEX DS9 REGION: refrence (Rp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(1.05rp): '//str(prfl_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"prfl_index.reg")

                # CUMULATIVE INDEX DS9 REGION: refrence (Rp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(1.05rp): '//str(cum_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"cum_index.reg")

            }else if(j == 26){

                # PROFILE MAIN catalog Asymmetry
                printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %11.4f", cum_index_alpha, >> out_cat//"cum_index_main.cat")

                # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(1.5 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(1.5 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={'//id_obj[obj_pos]//', (1.55rp): '//str(prfl_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"prfl_index.reg")

                # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(1.5 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(1.5 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={'//id_obj[obj_pos]//', (1.55rp): '//str(cum_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"cum_index.reg")

            }else if(j == 36){

                # PROFILE MAIN catalog Asymmetry
                printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %11.4f\n", cum_index_alpha, >> out_cat//"cum_index_main.cat")

                # PROFILE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(2 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(2 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(1rp): '//str(prfl_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"prfl_index.reg")

                # CUMULATIVE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(2 * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(2 * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color=red dash=1 text={(1rp): '//str(cum_index_alpha)//'}'
                print(expre, >> out_ds9_cat//"cum_index.reg")

            }
            # END PRINT CATALOGS ------------------------------------------------

            imdelete(tmp_dir//"/"//"tmp_aperture", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_areattl_ap", >& "dev$null")

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







