procedure uncertainty_96()

# FOR NGC_4088 J 2MASS folder
# ri_ann and ro_ann different!

    string radec_list  = "tables/members_4088.ascii"   {prompt = "[deg] members list [ascii] to match"}
    int    n_sim       = 100      {prompt = "Number of simulations"}
    int    start_obj   = 1        {prompt = "Object inputlist resume task"}
    real   frac_extra  = 0.05     {prompt = "Extra fraction sigma for half simulations"}
    real   low_clip    = 2.00     {prompt = "Low limit (relative to rms_bg)"}
    string hicntr_clip = "10.0"   {prompt = "Upper clip center (int or 'off')"}
    string hioutr_clip = "10.0"   {prompt = "Upper clip outer (int or 'off')"}
    string key_sex     = "sex"    {prompt = "Keyword to run SExtractor"}
    # real   pix_scale   = 0.3      {prompt = "Pixel scale (arcsec/pixel)"}
    # string obj_center  = "71"     {prompt = "Index list center object (integer)"}
    # real   clredshift  = 0.033    {prompt = "Cluster redshift (e.g. 0.033"}
    # bool   list_select = no       {prompt = "List to apply select radius"}

begin

    # Movidas del prompt ultimamente
    string input_list
    string radec_list
    real hicen_clip, hiout_clip
    real sky_err

    # DEFINICIÓN DE VARIABLES  ALPHA --------------------------
    real x, y, radio
    int wcs, key, stat
    string cmd
    string tmp_file
    string list_2
    bool ds9_access
    real nx, ny, x_0, y_0
    real radius, delta
    real rot_alpha_val[999], alpha_val[999]
    real select_obj[999]
    string tmp_id, tmp_color
    int tmp_obj
    real tmp_radius
    string ccdist_head, log_dir
    string areaglxy_img, areaglxy_img_edit
    bool edit_img
    int tmp_cont
    string areaglxy_cntrmsk_img, areaglxy_cntrmsk_maxaper_img
    #///////// DECLARAR: para uncertainty.cl ///////
    # Trasladada al prompt: int n_sim
    string image_sim, image_in
    string sexfile_sim
    string uncert_dir, uncert_file_dir, uncert_img_dir, uncert_cache_dir
    string out_check_img
    # duplicated: string tmp_id
    real tmp_ra, tmp_dec, tmp_xwin, tmp_ywin, tmp_aimg, tmp_bimg, tmp_ellip, tmp_pa, tmp_theta, tmp_kron, tmp_petro, tmp_reff, tmp_inner_area, tmp_n_areattl
    int r_aper
    string out_cat_sim
    string bg_dir
    int side_img
    # move to prompt: real frac_extra
    # ----------------------------------------------

    string color_reg

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

    real min1_bgdensity, min2_bgdensity, min3_bgdensity, min4_bgdensity, tmp_current

    int min1_pos, min2_pos, min3_pos, min4_pos

    real min_densitybg, ttl_rho

    real area_ann[4], n_noisepix[4], density_noise[4]

    real delta_area, nbg_noisepix, n_asymmpix, ap_n_areattl, n_areattl[999], prfl_index_alpha, cum_index_alpha

    # LOCAL VARIABLES DEFINITION ROTATED-ALPHA

    string rot_asymm_dir, img_to_rot, img_out_rot

    bool rot_alpha

    string asymmpixel_head, rot_cat_dir, out_cat, out_ds9_cat

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
            printf("alpha_%.1f_nn_%.1f", low_clip, hiout_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'hioutr_clip' out of range!")}

    }else if(strlwr(hicntr_clip) != "off" && strlwr(hioutr_clip) == "off"){
        # Lee directorio como p.ej.: alpha_2.5_8.0_nn
        hicen_clip = real(hicntr_clip)
        hiout_clip = 1.0e6                                            # Evita crear mas codigo abajo, pero no es lo mejor!
        # -
        if(hicen_clip > 0 && hicen_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_%.1f_nn", low_clip, hicen_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'hicntr_clip' out of range!")}

    }else if(strlwr(hicntr_clip) == "off" && strlwr(hioutr_clip) == "off"){
        # -
        hicen_clip = 1.0e6
        hiout_clip = 1.0e6
        # lee directorio:
        printf("alpha_%.1f_nn_nn", low_clip) | scan(alpha_dir)
        # -
    }else{
        # -
        hicen_clip = real(hicntr_clip)
        hiout_clip = real(hioutr_clip)
        #-
        # lee directorio:
        printf("alpha_%.1f_%.1f_%.1f", low_clip, hicen_clip, hiout_clip) | scan(alpha_dir)
    }
    # ./alpha/images:
    alphaimg_dir = alpha_dir//"/"//"images"
    # ./alpha/images/asymmpix
    asymm_dir = alphaimg_dir//"/"//"asymmpix"
    # ./alpha/images/rot_asymmpix
    rot_asymm_dir = alphaimg_dir//"/"//"rot_asymmpix"
    # =================================================================================================


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
    sexfile_sim = sex_dir//"/"//"for_simulation.sex"
    param_sex = sex_dir//"/"//"default.param"
    conv_sex = sex_dir//"/"//"filter.conv"

    bgrms_img = outsex_dir//"/"//"check_bgrms.fits"
    mod_img = outsex_dir//"/"//"check_mod.fits"
    res_img = outsex_dir//"/"//"check_res.fits"
    psf_fit = outpsfex_dir//"/"//"prepsfex.psf"
    cat_sex = outsex_dir//"/"//"test.cat"

    const_pi = 3.1415926535897932385

    log_dir = tmp_dir//"/"//"imedit"

    uncert_dir = alpha_dir//"/"//"uncertainty"
    uncert_img_dir = uncert_dir//"/"//"images"
    uncert_cache_dir = uncert_dir//"/"//"tmp_files"
    uncert_file_dir = uncert_dir//"/"//"files"

    obj_i = start_obj

    color_reg = "red"

    edit_img = no

    scndimg_bool = no

    objcenter_bool = no

    rot_alpha = no

    ri_ann = 2.05
    ro_ann = 2.5

    petro_factor = 2.0

    sky_err = 25

    # vector of scale r/rp
    scale_r[1]=0.25
    scale_r[2]=0.30; scale_r[3]=0.35; scale_r[4]=0.40; scale_r[5]=0.45; scale_r[6]=0.50; scale_r[7]=0.55; scale_r[8]=0.60; scale_r[9]=0.65; scale_r[10]=0.70; scale_r[11]=0.75; scale_r[12]=0.80; scale_r[13]=0.85; scale_r[14]=0.90; scale_r[15]=0.95; scale_r[16]=1.00; scale_r[17]=1.05; scale_r[18]=1.10; scale_r[19]=1.15; scale_r[20]=1.20; scale_r[21]=1.25; scale_r[22]=1.30; scale_r[23]=1.35; scale_r[24]=1.40; scale_r[25]=1.45; scale_r[26]=1.50; scale_r[27]=1.55; scale_r[28]=1.60; scale_r[29]=1.65; scale_r[30]=1.70; scale_r[31]=1.75; scale_r[32]=1.80; scale_r[33]=1.85; scale_r[34]=1.90; scale_r[35]=1.95; scale_r[36]=2.00; scale_r[37]=2.05; scale_r[38]=2.10; scale_r[39]=2.15; scale_r[40]=2.20; scale_r[41]=2.25; scale_r[42]=2.30; scale_r[43]=2.35; scale_r[44]=2.40; scale_r[45]=2.45; scale_r[46]=2.50; scale_r[47]=2.55; scale_r[48]=2.60; scale_r[49]=2.65; scale_r[50]=2.70; scale_r[51]=2.75; scale_r[52]=2.80; scale_r[53]=2.85; scale_r[54]=2.90; scale_r[55]=2.95; scale_r[56]=3.00; scale_r[57]=3.05; scale_r[58]=3.10; scale_r[59]=3.15; scale_r[60]=3.20; scale_r[61]=3.25; scale_r[62]=3.30; scale_r[63]=3.35; scale_r[64]=3.40; scale_r[65]=3.45; scale_r[66]=3.50; scale_r[67]=3.55; scale_r[68]=3.60; scale_r[69]=3.65; scale_r[70]=3.70; scale_r[71]=3.75; scale_r[72]=3.80; scale_r[73]=3.85; scale_r[74]=3.90; scale_r[75]=3.95; scale_r[76]=4.00; scale_r[77]=4.05; scale_r[78]=4.10; scale_r[79]=4.15; scale_r[80]=4.20; scale_r[81]=4.25; scale_r[82]=4.30; scale_r[83]=4.35; scale_r[84]=4.40; scale_r[85]=4.45; scale_r[86]=4.50; scale_r[87]=4.55; scale_r[88]=4.60; scale_r[89]=4.65; scale_r[90]=4.70; scale_r[91]=4.75; scale_r[92]=4.80; scale_r[93]=4.85; scale_r[94]=4.90; scale_r[95]=4.95; scale_r[96]=5.00


    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    # First terminal output
    print("")
    printf("--------- GALASYM2 started on %s at %s --------\n\n", my_date, my_time)

    print(" Task (DS9 interactive): select alpha index")
    print(" - select... \n\n")
    # -----------------------------------------------------------

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

    # FOLDER VERIFICATION OR CREATION ----------------------------
    if(!access(uncert_dir)){mkdir(uncert_dir)}
    if(!access(uncert_img_dir)){mkdir(uncert_img_dir)}
    if(!access(uncert_cache_dir)){mkdir(uncert_cache_dir)}
    if(!access(uncert_file_dir)){mkdir(uncert_file_dir)}



    # READ INPUT LIST --------------------------------------------
    list = input_list
    i = 0
    while(fscan(list,line) != EOF){

        if(substr(line, 1, 1) != "#"){

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
    list = ""


    # ============================================================
    # Para cada objeto de la input_list, hacer:

    # -------------------------------------------------------------------

    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    # Empieza objeto por objeto
    for(i=obj_i; i<=n_list; i+=1){

        print("clear") | cl
        print("\r ---------------------------------------")
        printf("\r - Analyzing object: %d / %d", i, n_list)
        print("\r ---------------------------------------")

        obj_pos = i

        # ============================================================================================
        # GENERAR SIMULACIONES =======================================================================
        # - "Usage: python3 sim_observation.py n_sim image_in alpha_dir frac_extra
        # image_in = id[obj_pos]//".fits"
        # printf("! python3 %s %f %s %s %f\n", config_dir//"/"//"sim_observation.py", n_sim, image_in, alpha_dir, frac_extra) | cl

        # leer tamaños de ejes XY de la imagen:
        imgets(obs_dir//"/"//"observed_"//id_obj[obj_pos], "naxis1")
        side_img = int(imgets.value)

        # Catalogo de salida *.set:
        out_cat_sim = uncert_dir//"/"//id_obj[obj_pos]

        # Catalogos
        if(obj_i == 1){

            # Borrar y crear encabezados:
            # HEADERS OUTPUTS CATALOGS -------------------------------------------------------
            delete(out_cat_sim//"_prfl_index_set.cat", >& "dev$null")
            delete(out_cat_sim//"_cum_index_set.cat", >& "dev$null")
            for(r_aper=1; r_aper<=46; r_aper+=1){
                if(r_aper == 1){

                    # III. PROFILE Asymmetry area SET: first
                    printf("#%31s prfl_%4.2frp", "ID_OBJ", scale_r[r_aper], >> out_cat_sim//"_prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: first
                    printf("#%31s cum_%4.2frp", "ID_OBJ", scale_r[r_aper], >> out_cat_sim//"_cum_index_set.cat")

                }else if(r_aper == 46){

                    # III. PROFILE Asymmetry area SET: first
                    printf(" prfl_%4.2frp\n", scale_r[r_aper], >> out_cat_sim//"_prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: first
                    printf(" cum_%4.2frp\n", scale_r[r_aper], >> out_cat_sim//"_cum_index_set.cat")

                }else{

                    # III. PROFILE Asymmetry area SET: mid
                    printf(" prfl_%4.2frp", scale_r[r_aper], >> out_cat_sim//"_prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: mid
                    printf(" cum_%4.2frp", scale_r[r_aper], >> out_cat_sim//"_cum_index_set.cat")

                }
            }

        }else if(obj_i<=0 && obj_i>n_list){

            # Verifica la entrada obj_i:
            print(" ERR: 'obj_i' must be in the inputlist!")
            goto exit_task
        }


        # Para este objeto_i, existen 'n_sim' simulaciones ======================================
        # =======================================================================================
        #-
        for(j=1; j<=n_sim; j+=1){

            print("\r \n=========================================")
            printf("\r - Analyzing simulation: %d / %d", j, n_sim)

            # imagen simulada (realizacion):
            printf("sim%d_%s.fits", j, id_obj[obj_pos]) | scan(image_sim)
            image_sim = uncert_img_dir//"/"//image_sim

            # Ejecutar SExtractor:
            print(" Single image mode...\n")
            printf("! %s %s -c %s \n", key_sex, image_sim, sexfile_sim) | cl
            #-

            # MAtch entre sextracted_list and input_list
            ## delete(uncert_cache_dir//"/"//"tmp_match_list.cat", ver-, >& "dev$null")
            ## expre = "! stilts tskymatch2 in1=%s ifmt1=ascii in2=%s ifmt2=ascii ra1=RA dec1=DEC ra2=col2 dec2=col3 error=4 find=best ofmt=ascii out=%s/tmp_match_list.cat\n"
            ## printf(expre, radec_list, outsex_dir//"/"//"tmp_simulation.cat", uncert_cache_dir) | cl
            ##
            ## delete(uncert_cache_dir//"/"//"tmp_inputlist.cat", ver-, >& "dev$null")
            ## expre ="! stilts tpipe cmd='delcols \"RA DEC col1\"' in=%s/tmp_match_list.cat ifmt=ascii ofmt=ascii out=%s/tmp_inputlist.cat\n"
            ## printf(expre, uncert_cache_dir, uncert_cache_dir) | cl
            #delete(uncert_cache_dir//"/"//"tmp_match_list.cat", ver-, >& "dev$null")
            ## list = uncert_cache_dir//"/"//"tmp_inputlist.cat"

            # Leer sextracted_list:
            list = outsex_dir//"/"//"tmp_simulation.cat"
            while(fscan(list,line) != EOF){

                if(substr(line, 1, 1) != "#"){

                    print(line) | scan(tmp_id, tmp_ra, tmp_dec, tmp_xwin, tmp_ywin, tmp_aimg, tmp_bimg, tmp_ellip, tmp_pa, tmp_theta, tmp_kron, tmp_petro, tmp_reff)
                    tmp_petro =  tmp_petro / 2

                    if(abs(tmp_xwin - xwin_img[obj_pos]) <= sky_err && abs(tmp_ywin - ywin_img[obj_pos]) <= sky_err){
                        break
                    }
                }
            }

            # Crear imagenes para calcular el indice: ----------------------------------------

            imdelete(uncert_img_dir//"/"//"area_ttl.fits", >& "dev$null")
            # Observed area frame for N total pixels:
            imexpr("a >= b*c", uncert_img_dir//"/"//"area_ttl.fits", image_sim, low_clip, outsex_dir//"/"//"tmp_bgrms.fits", verb-)

            imdelete(uncert_img_dir//"/"//"cntr_mask.fits", >& "dev$null")
            # Center mask from model:
            imexpr("a <= b*c", uncert_img_dir//"/"//"cntr_mask.fits", outsex_dir//"/"//"tmp_mod.fits", hicen_clip, outsex_dir//"/"//"tmp_bgrms.fits", verb-)

            imdelete(uncert_img_dir//"/"//"area_cntrmask.fits", >& "dev$null")
            # Center area count:
            expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1 && f == 0"
            imexpr(expre, uncert_img_dir//"/"//"area_cntrmask.fits", (side_img + 1)/2.0, (side_img + 1)/2.0, tmp_petro * tmp_aimg, tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), uncert_img_dir//"/"//"cntr_mask.fits", verb-)
            # Contar pixeles:
            imstat(uncert_img_dir//"/"//"area_cntrmask.fits", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            tmp_inner_area = meanpix * ttlpix
            meanpix = 0
            ttlpix = 0

            imdelete(uncert_img_dir//"/"//"area_glxy_cntrmask.fits", >& "dev$null")
            # Observed area frame without center:
            imexpr("a*b", uncert_img_dir//"/"//"area_glxy_cntrmask.fits", uncert_img_dir//"/"//"area_ttl.fits", uncert_img_dir//"/"//"cntr_mask.fits", verb-)

            imdelete(uncert_img_dir//"/"//"max_aper.fits", >& "dev$null")
            # Observed maximum area for cumulative denominator  alpha index:
            expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
            imexpr(expre, uncert_img_dir//"/"//"max_aper.fits", (side_img + 1)/2.0, (side_img + 1)/2.0, scale_r[27] * tmp_petro * tmp_aimg, scale_r[27] * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), dims=str(side_img)//","//str(side_img), verb-)
            imdelete(uncert_img_dir//"/"//"area_glxy_maxaper.fits", >& "dev$null")
            imexpr("a*b", uncert_img_dir//"/"//"area_glxy_maxaper.fits", uncert_img_dir//"/"//"area_glxy_cntrmask.fits", uncert_img_dir//"/"//"max_aper.fits", verb-)
            # Conteo de pixeles:
            imstat(uncert_img_dir//"/"//"area_glxy_maxaper.fits", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            tmp_n_areattl = meanpix * ttlpix
            meanpix = 0
            ttlpix = 0

            imdelete(uncert_img_dir//"/"//"asymm_pix.fits", >& "dev$null")
            # Extend asymmetrical pixels for measure index (source + noise annulus):
            imexpr("a*b >= c*e && a*b <= d*e", uncert_img_dir//"/"//"asymm_pix.fits", outsex_dir//"/"//"tmp_res.fits", uncert_img_dir//"/"//"cntr_mask.fits", low_clip, hiout_clip, outsex_dir//"/"//"tmp_bgrms.fits", verb-)

            imdelete(uncert_img_dir//"/"//"rot_asymm_pix.fits", >& "dev$null")
            imdelete(uncert_img_dir//"/"//"tmp_90.fits", >& "dev$null")
            imdelete(uncert_img_dir//"/"//"tmp_180.fits", >& "dev$null")
            # Extend rotated asymmetrical pixels for measure rot-index alpha
            imtranspose(uncert_img_dir//"/"//"asymm_pix.fits[*,-*]", uncert_img_dir//"/"//"tmp_90.fits")
            imtranspose(uncert_img_dir//"/"//"tmp_90.fits[*,-*]", uncert_img_dir//"/"//"tmp_180.fits")
            imexpr("(a-b)>0", uncert_img_dir//"/"//"rot_asymm_pix.fits", uncert_img_dir//"/"//"asymm_pix.fits", uncert_img_dir//"/"//"tmp_180.fits", verb-)
            #-
            # --------------------------------------------------------------------------------

            # ================================================================================
            # Calcular el indice de asimetria: ROT_ALPHA_INDEX
            #-
            asymmpixel_img = uncert_img_dir//"/"//"rot_asymm_pix.fits"
            # Estimar el fondo de la imagen (anillo o blank patch):
            # Annulus 1 ------------------------------------------------------------
            imdelete(uncert_img_dir//"/"//"tmp_ann_1", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) > (J-b) && (I-a) >= -(J-b) ? 1 : 0", uncert_img_dir//"/"//"tmp_ann_1", (side_img + 1)/2.0, (side_img + 1)/2.0, ro_ann * tmp_petro * tmp_aimg, ro_ann * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), ri_ann * tmp_petro * tmp_aimg, ri_ann * tmp_petro * tmp_bimg, dims=str(side_img)//","//str(side_img), verb-)
            # Area annulus 1
            imstat(uncert_img_dir//"/"//"tmp_ann_1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            area_ann[1] = meanpix * ttlpix
            # Asymmetrical pixel counting ann[1]
            imdelete(uncert_img_dir//"/"//"tmp_bgpix_ann1", >& "dev$null")
            imexpr("a*b", uncert_img_dir//"/"//"tmp_bgpix_ann1", asymmpixel_img, uncert_img_dir//"/"//"tmp_ann_1", verb-)
            imstat(uncert_img_dir//"/"//"tmp_bgpix_ann1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_noisepix[1] = meanpix * ttlpix
            # Noise density ann[1]
            density_noise[1] = n_noisepix[1] / area_ann[1]
            # Annulus 2 ------------------------------------------------------------
            imdelete(uncert_img_dir//"/"//"tmp_ann_2", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) <= (J-b) && (I-a) > -(J-b) ? 1 : 0", uncert_img_dir//"/"//"tmp_ann_2", (side_img + 1)/2.0, (side_img + 1)/2.0, ro_ann * tmp_petro * tmp_aimg, ro_ann * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), ri_ann * tmp_petro * tmp_aimg, ri_ann * tmp_petro * tmp_bimg, dims=str(side_img)//","//str(side_img), verb-)
            # Area annulus 2
            imstat(uncert_img_dir//"/"//"tmp_ann_2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            area_ann[2] = meanpix * ttlpix
            imdelete(uncert_img_dir//"/"//"tmp_bgpix_ann2", >& "dev$null")
            imexpr("a*b", uncert_img_dir//"/"//"tmp_bgpix_ann2", asymmpixel_img, uncert_img_dir//"/"//"tmp_ann_2", verb-)
            imstat(uncert_img_dir//"/"//"tmp_bgpix_ann2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_noisepix[2] = meanpix * ttlpix
            # Noise density ann[1]
            density_noise[2] = n_noisepix[2] / area_ann[2]
            # Annulus 3 ------------------------------------------------------------
            imdelete(uncert_img_dir//"/"//"tmp_ann_3", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) < (J-b) && (I-a) <= -(J-b) ? 1 : 0", uncert_img_dir//"/"//"tmp_ann_3", (side_img + 1)/2.0, (side_img + 1)/2.0, ro_ann * tmp_petro * tmp_aimg, ro_ann * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), ri_ann * tmp_petro * tmp_aimg, ri_ann * tmp_petro * tmp_bimg, dims=str(side_img)//","//str(side_img), verb-)
            # Area annulus 3
            imstat(uncert_img_dir//"/"//"tmp_ann_3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            area_ann[3] = meanpix * ttlpix
            # Asymmetrical pixel counting ann[1]
            imdelete(uncert_img_dir//"/"//"tmp_bgpix_ann3", >& "dev$null")
            imexpr("a*b", uncert_img_dir//"/"//"tmp_bgpix_ann3", asymmpixel_img, uncert_img_dir//"/"//"tmp_ann_3", verb-)
            imstat(uncert_img_dir//"/"//"tmp_bgpix_ann3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_noisepix[3] = meanpix * ttlpix
            # Noise density ann[3]
            density_noise[3] = n_noisepix[3] / area_ann[3]
            # Annulus 4 ------------------------------------------------------------
            imdelete(uncert_img_dir//"/"//"tmp_ann_4", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) >= (J-b) && (I-a) < -(J-b) ? 1 : 0", uncert_img_dir//"/"//"tmp_ann_4", (side_img + 1)/2.0, (side_img + 1)/2.0, ro_ann * tmp_petro * tmp_aimg, ro_ann * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), ri_ann * tmp_petro * tmp_aimg, ri_ann * tmp_petro * tmp_bimg, dims=str(side_img)//","//str(side_img), verb-)
            # Area annulus 4
            imstat(uncert_img_dir//"/"//"tmp_ann_4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            area_ann[4] = meanpix * ttlpix
            # Asymmetrical pixel counting ann[1]
            imdelete(uncert_img_dir//"/"//"tmp_bgpix_ann4", >& "dev$null")
            imexpr("a*b", uncert_img_dir//"/"//"tmp_bgpix_ann4", asymmpixel_img, uncert_img_dir//"/"//"tmp_ann_4", verb-)
            imstat(uncert_img_dir//"/"//"tmp_bgpix_ann4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_noisepix[4] = meanpix * ttlpix
            # Noise density ann[4]
            density_noise[4] = n_noisepix[4] / area_ann[4]
            # ---------------------------------------------------------------------
            # Elegir el mínimo del fondo (criterio libre. Aqui, las tres menores)
            # Total area of ​​the noise ring
            nbg_noisepix = (n_noisepix[1] + n_noisepix[2] + n_noisepix[3] + n_noisepix[4])
            ttl_rho = nbg_noisepix / (area_ann[1] + area_ann[2] + area_ann[3] + area_ann[4])
            #-
            # Take the four parts ordered by background density (min to max)
            min1_bgdensity = 1.0e6
            min1_pos = -1
            min2_bgdensity = 1.0e6
            min2_pos = -1
            min3_bgdensity = 1.0e6
            min3_pos = -1
            min4_bgdensity = 1.0e6
            min4_pos = -1
            #- found minimous
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
            #-
            # Handle uninitialized positions
            if(min2_pos == -1){min2_pos = min1_pos}
            if(min3_pos == -1){min3_pos = min2_pos}
            if(min4_pos == -1){min4_pos = min3_pos}
            #-
            # min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos]) / (area_ann[min1_pos] + area_ann[min2_pos])
            # min_densitybg = (n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min2_pos] + area_ann[min3_pos])
            min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min1_pos] + area_ann[min2_pos] + area_ann[min3_pos])
            #-
            k = 0
            #-

            #-
            # Asimetry vs. apertures:
            for(r_aper=1; r_aper<=46; r_aper+=1){

                # Measurement apperture (binary area):
                imdelete(uncert_img_dir//"/"//"tmp_aperture", >& "dev$null")
                imexpr(expre1//" ? 1 : 0", uncert_img_dir//"/"//"tmp_aperture", (side_img + 1)/2.0, (side_img + 1)/2.0, scale_r[r_aper] * tmp_petro * tmp_aimg, scale_r[r_aper] * tmp_petro * tmp_bimg, tmp_theta * (const_pi / 180), dims=str(side_img)//","//str(side_img), verb-)

                # Asymmetrical pixel image in aperture
                imdelete(uncert_img_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
                imexpr("a*b", uncert_img_dir//"/"//"tmp_asymmpix_ap", asymmpixel_img, uncert_img_dir//"/"//"tmp_aperture", verb-)
                # Asymmetrical pixels counting:
                imstat(uncert_img_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                n_asymmpix = meanpix * ttlpix

                # aper. Total pixels (N_tot) alpha = n_asymmpix / N_tot(in aperture)
                imdelete(uncert_img_dir//"/"//"tmp_areattl_ap", >& "dev$null")
                imexpr("a*b", uncert_img_dir//"/"//"tmp_areattl_ap", uncert_img_dir//"/"//"area_glxy_maxaper.fits", uncert_img_dir//"/"//"tmp_aperture", verb-)
                imstat(uncert_img_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                ap_n_areattl = meanpix * ttlpix

                # alpha Asymmetry index calculation:
                if(scale_r[r_aper] * tmp_petro <= 0){ # if change 0, check the rest of the conditional:
                    delta_area = 0
                    if(ap_n_areattl <= 1){
                        prfl_index_alpha = 0
                    }else{
                        prfl_index_alpha = n_asymmpix / ap_n_areattl
                    }
                    cum_index_alpha = n_asymmpix / tmp_n_areattl
                }else{

                    # Comment if (<=3.0):
                    delta_area = const_pi * (tmp_aimg * tmp_bimg) * ((scale_r[r_aper] * tmp_petro)**2) - tmp_inner_area
                    if(delta_area <= 0){ delta_area = 0 }

                    # -> Comment the following line only #if uncomment past '# (<= 0.0)' lines.
                    # delta_area = const_pi * (tmp_aimg * tmp_bimg) * ((scale_r[r_aper] * tmp_petro)**2 - 9.0)

                    prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / ap_n_areattl
                    cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / tmp_n_areattl
                }

                # PRINT CATALOGS =====================================================================
                if(r_aper == 1){

                    # III. Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[obj_pos], prfl_index_alpha, >> out_cat_sim//"_prfl_index_set.cat")

                    # III. Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[obj_pos], cum_index_alpha, >> out_cat_sim//"_cum_index_set.cat")

                }else if(r_aper == 46){

                    # III. PROFILE Asymmetry area SET: last
                    printf(" %11.4f\n", prfl_index_alpha, >> out_cat_sim//"_prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: last
                    printf(" %11.4f\n", cum_index_alpha, >> out_cat_sim//"_cum_index_set.cat")

                }else{

                    # III. PROFILE Asymmetry area SET: mid
                    printf(" %11.4f", prfl_index_alpha, >> out_cat_sim//"_prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: mid
                    printf(" %11.4f", cum_index_alpha, >> out_cat_sim//"_cum_index_set.cat")
                }

            } # Termina FOR apertures

        } # Termina FOR N_sim of ID_OBJ

        #-

    } # Termina FOR obj_i

    print("\n End task.")

    exit_task:

    print("-------------------------------------------------------------")
    print("")
    beep

end




