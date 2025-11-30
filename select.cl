procedure select_alpha_96()

    int    start_obj   = 81       {prompt = "Object inputlist resume task"}
    real   low_clip    = 2.00     {prompt = "Low limit (relative to rms_bg)"}
    string hicntr_clip = "10.0"   {prompt = "Upper clip center (int or 'off')"}
    string hioutr_clip = "10.0"   {prompt = "Upper clip outer (int or 'off')"}
    real   pix_scale   = 0.3      {prompt = "Pixel scale (arcsec/pixel)"}
    string obj_center  = "71"     {prompt = "Index list center object (integer)"}
    real   clredshift  = 0.033    {prompt = "Cluster redshift (e.g. 0.033"}
    string keyw_ds9    = "ds9"    {prompt = "Keyword to run DS9 viewer"}
    bool   list_select = no       {prompt = "List to apply select radius"}

begin

    # Movidas del prompt ultimamente
    string input_list
    real hicen_clip, hiout_clip
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

    real min1_bgdensity, min2_bgdensity, tmp_current

    int min1_pos, min2_pos

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

    log_dir = tmp_dir//"/"//"imedit"

    obj_i = start_obj

    color_reg = "red"

    edit_img = no

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

                ccdist_head = "Cc_dist(arcsec)"

                if(access(config_dir//"/"//"ned_calc.py")){

                    ccdistance_Mpc[i] = (ccdistance_arsec[i] * kp_DA) / 1000
                    ccdistance[i] = ccdistance_Mpc[i]

                    ccdist_head = "Cc_dist(Mpc)"
                }
            }
        }
    }


    # ================================================================================
    # LOS OBJETOS YA FUERON SELECCIONADOS: APLICAR EN OTRA CARPETA
    # ================================================================================

    if(list_select == yes){

        tmp_string = data_dir//"/"//"select_apertures.cat"
        if(!access(tmp_string)){
            print(" ERR: 'select_list' doesn't exist!")
            goto exit_task
        }else if(!access(alpha_dir)){
            print(" ERR: ", alpha_dir, "doesn't exists!")
            goto exit_task
        }

        # HEADER (nuevo): Apertura seleccionada
        delete(rot_cat_dir//"/"//"select_rot_index.cat", ver-, >& "dev$null")
        printf("#%31s %11s %11s %11s %11s %7s %12s alpha_%3.1f\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "(r/rp)", ccdist_head, low_clip, >> rot_cat_dir//"/"//"select_rot_index.cat")

        # HEADER CATALOG: DS9 regions asymmetry index
        delete(ds9_dir//"/"//"select_rot_index.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"select_rot_index.reg")
        print('global dashlist=8 3 width=1 font="helvetica 14 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"select_rot_index.reg")
        print("fk5", >> ds9_dir//"/"//"select_rot_index.reg")

        delete(tmp_dir//"/"//"tmp_rotalpha", ver-, >& "dev$null")
        tmp_file = rot_cat_dir//"/"//"rot_prfl_index_set.cat"
        list = data_dir//"/"//"select_apertures.cat"
        list_2 = tmp_dir//"/"//"tmp_rotalpha"

        while(fscan(list, line) != EOF){

            if(substr(line, 1, 1) != "#"){

                print(line) | scan(tmp_id, tmp_obj, tmp_radius, tmp_color)

                # leer catalogo y crear archivo 'tmp_rotalpha'
                print("!awk 'NR=="//(tmp_obj + 1)//" {for(i=2; i<=NF; i++) print $i}' "//tmp_file//" > "//tmp_dir//"/"//"tmp_rotalpha") | cl
                #
                j = 1
                while(fscan(list_2, line) != EOF){
                    if(substr(line, 1, 1) != "#"){
                        print(line) | scan(rot_alpha_val[j])
                         j = j + 1

                    }
                }
                delete(tmp_dir//"/"//"tmp_rotalpha", ver-, >& "dev$null")

                # Imprime objeto en la lista seleccionada:
                printf("%32s %11.4f %11.4f %11.8f %11.8f %12.2f %5.3f %11.4f\n", tmp_id, xwin_img[tmp_obj], ywin_img[tmp_obj], ra_j00[tmp_obj], dec_j00[tmp_obj], scale_r[tmp_radius], ccdistance[tmp_obj], rot_alpha_val[tmp_radius], >> rot_cat_dir//"/"//"select_rot_index.cat")

                # Crea la region ds9 para ese objeto con valor alpha:
                expre = 'ellipse('//str(ra_j00[tmp_obj])//','//str(dec_j00[tmp_obj])//','//str(scale_r[tmp_radius] * petro_r[tmp_obj] * a_img[tmp_obj] * pix_scale)//'",'//str(scale_r[tmp_radius] * petro_r[tmp_obj] * b_img[tmp_obj] * pix_scale)//'",'//str(theta_img[tmp_obj])//') # color='//tmp_color//' text={Size:'//str(scale_r[tmp_radius])//'*Rp, alpha= %.4f}\n'
                printf(expre, rot_alpha_val[tmp_radius], >> ds9_dir//"/"//"select_rot_index.reg")

            }
        }
        list = ""
        list_2 = ""
    }

    # ================================================================================
    # ABRIR DS9
    # ================================================================================
    print("! xpaaccess ds9") | cl | scan(ds9_access)

    if(ds9_access == no){
        print("! "//keyw_ds9//" -tile -frame 1 -frame 2 -lock frame image &") | cl
        print("-------------------------------------------------------------")
        print(" Oppening DS9")
        sleep(5)
        print(" wait... will continue automatically")
        sleep(7)

    }else{
        print("! xpaset -p ds9 frame delete all") | cl
        print("! xpaset -p ds9 frame new") | cl
        print("! xpaset -p ds9 tile yes") | cl
        print("! xpaset -p ds9 lock frame image") | cl
    }

    # ==================== ciclo de objetos a mostrar =================================

    if(obj_i == 1){

        # HEADER (nuevo): Apertura seleccionada
        delete(rot_cat_dir//"/"//"select_rot_index.cat", ver-, >& "dev$null")
        printf("#%31s %11s %11s %11s %11s %12s %5s alpha_%3.1f\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "(r/rp)", ccdist_head, low_clip, >> rot_cat_dir//"/"//"select_rot_index.cat")

        # HEADER CATALOG: DS9 regions asymmetry index
        delete(ds9_dir//"/"//"select_rot_index.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"select_rot_index.reg")
        print('global dashlist=8 3 width=1 font="helvetica 14 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"select_rot_index.reg")
        print("fk5", >> ds9_dir//"/"//"select_rot_index.reg")

        # HEADER (nuevo): Objetos rechazados
        delete(rot_cat_dir//"/"//"reject_objects.cat", ver-, >& "dev$null")
        printf("#%31s %11s %11s %11s %11s %12s %5s alpha_%3.1f\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "(r/rp)", ccdist_head, low_clip, >> data_dir//"/"//"reject_objects.cat")

        # HEADER ACATALOG: DS9 objetos rechazados
        delete(ds9_dir//"/"//"reject_objects.reg",  >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"reject_objects.reg")
        print('global dashlist=8 3 width=1 font="helvetica 14 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"reject_objects.reg")
        print("fk5", >> data_dir//"/"//"reject_objects.reg")

        # HEADER: list_select
        delete(data_dir//"/"//"select_apertures.cat", ver-, >& "dev$null")
        printf("#%31s %7s %7s %7s %7s\n", "ID_OBJ[n_obj]", "n_obj", "aper_n", "aper_rp", "color_reg", >> data_dir//"/"//"select_apertures.cat")

    }else if(obj_i<=0 && obj_i>n_list){

        print(" ERR: 'obj_i' must be in the inputlist!")
        goto exit_task
    }

    next_obj:

    # Observed area without center:
    if(strlwr(hicntr_clip) == "off"){
        printf(tmp_dir//"/"//"area_%.1f_nn_obs_", low_clip) | scan(areaglxy_cntrmsk_img)
    }else{
        printf(tmp_dir//"/"//"area_%.1f_%.1f_obs_", low_clip, hicen_clip) | scan(areaglxy_cntrmsk_img)
    }
    # Observed maximum area (without center) for cumulative denominator index:
    areaglxy_cntrmsk_maxaper_img = areaglxy_cntrmsk_img//"maxaper_"

    for(i=obj_i; i<=n_list; i+=1){

        obj_pos = i

        radius = 17 # inicial
        delta = 1 # inicial

        if(edit_img == yes){
            # Leer rot_alpha original y pasar a 'alpha_val[k]'
            # tmp_string = cat_dir//"/"//"prfl_index_set.cat"
            tmp_string = tmp_dir//"/"//"edit_rot_cum_index_set.cat"
            # delete(tmp_dir//"/tmp_alpha", ver-, >& "dev$null")
            delete(tmp_dir//"/tmp_cumulative", ver-, >& "dev$null")
            print("!awk 'NR=="//(2)//" {for(i=2; i<=NF; i++) print $i}' "//tmp_string//" > "//tmp_dir//"/"//"tmp_cumulative") | cl
            # leer archivo temporal con valores alpha del objeto:
            # list = tmp_dir//"/"//"tmp_alpha"
        }else{
            # Leer rot_alpha original y pasar a 'alpha_val[k]'
            # tmp_string = cat_dir//"/"//"prfl_index_set.cat"
            tmp_string = rot_cat_dir//"/"//"rot_cum_index_set.cat"
            # delete(tmp_dir//"/tmp_alpha", ver-, >& "dev$null")
            delete(tmp_dir//"/tmp_cumulative", ver-, >& "dev$null")
            print("!awk 'NR=="//(obj_pos+1)//" {for(i=2; i<=NF; i++) print $i}' "//tmp_string//" > "//tmp_dir//"/"//"tmp_cumulative") | cl
            # leer archivo temporal con valores alpha del objeto:
            # list = tmp_dir//"/"//"tmp_alpha"
        }
        list = tmp_dir//"/"//"tmp_cumulative"
        j = 1
        while(fscan(list, line) != EOF){

            if(substr(line, 1, 1) != "#"){

                print(line) | scan(alpha_val[j])

                 j = j + 1

            }
        }
        list = ""


        # Verifica para saber que rot_alpha ctalogo tomar:
        if(edit_img == yes){

            # Leer rot_alpha editado y pasar a 'rot_alpha__val[k]' objetos editados:
            tmp_string = tmp_dir//"/"//"edit_rot_prfl_index_set.cat"
            delete(tmp_dir//"/tmp_rotalpha", ver-, >& "dev$null")
            print("!awk 'NR=="//(2)//" {for(i=2; i<=NF; i++) print $i}' "//tmp_string//" > "//tmp_dir//"/"//"tmp_rotalpha") | cl

        }else{

            # Leer rot_alpha original y pasar a 'rot_alpha_val[k]'
            tmp_string = rot_cat_dir//"/"//"rot_prfl_index_set.cat"
            delete(tmp_dir//"/tmp_rotalpha", ver-, >& "dev$null")
            print("!awk 'NR=="//(obj_pos+1)//" {for(i=2; i<=NF; i++) print $i}' "//tmp_string//" > "//tmp_dir//"/"//"tmp_rotalpha") | cl
        }
        # leer archivo temporal con valores alpha del objeto:
        list = tmp_dir//"/"//"tmp_rotalpha"
        j = 1
        while(fscan(list, line) != EOF){

            if(substr(line, 1, 1) != "#"){

                print(line) | scan(rot_alpha_val[j])

                 j = j + 1

            }
        }
        list = ""

        # s1 = tmp_dir//"/"//"tmp_alpha"
        s1 = tmp_dir//"/"//"tmp_cumulative"
        s2 = tmp_dir//"/"//"tmp_rotalpha"
        s3 = config_dir//"/"//"graf.py"
        if(access(s1) && access(s2) && access(s3)){
            #printf("! conda activate") | cl
            printf("! python3 %s %s %s & \n", s3, s1, s2) | cl
        }

        # Limpiar los marcos 1 y 2:
        print("!xpaset -p ds9 frame 1") | cl
        print("!xpaset -p ds9 regions delete all") | cl
        print("!xpaset -p ds9 frame 2") | cl
        print("!xpaset -p ds9 regions delete all") | cl

        # Desplegar las imagenes en los marcos 1 y 2:
        if(edit_img == yes){

            display(image=rot_asymm_dir//"/"//"edit_rot_asymmpix_"//id_obj[obj_pos], frame=1, erase=yes, >& "dev$null")

            edit_img = no

        }else{
            display(image=rot_asymm_dir//"/"//"rot_asymmpix_"//id_obj[obj_pos], frame=1, erase=yes, >& "dev$null")
        }
        # display(image=rot_asymm_dir//"/"//"rot_bg_asymmpix_"//id_obj[obj_pos], frame=2, erase=yes, >& "dev$null")
        display(image=areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos], frame=2, erase=yes, >& "dev$null")

        # Temporal ds9 region file: initial conditions
        delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
        print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
        print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
        print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
        # refrence (Rp) aperture: eliptical
        print("! xpaget ds9 fits size") | cl | scan(nx, ny)
        x_0 = (nx + 1) / 2
        y_0 = (ny + 1) / 2
        # color region:
        if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
        else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
        else if(alpha_val[radius] > 0.15){ color_reg = "red"}
        # crear region:
        expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//'  text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
        printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
        # Desplegar la elipse (region ds9) inicial o r = 1*rp:
        tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
        print("! xpaset -p ds9 region load all ", tmp_string) | cl

        key = 0  # Inicializar ---------------------------
        # key == 43   # '+'
        # key == 45   # '-'
        # key == 115  # 's' (select & next obj)
        # key == 112  # 'd' (reject_obj)
        # key == 113  # '+' (radius+step)
        # key == 115  # '-' (radius-step)
        # key == 97   # 'b/m/t' (aperture min/half/max)
        # ------------------------------------------------
        print("clear") | cl
        print("")
        print(" =========== Interactive Cursor ds9 ============")
        print(" The CURSOR should! point IN DS9 window")
        print(" Avalaible inputs:")
        print("      - '+' (radius+step)")
        print("      - '-' (radius-step)")
        print("      - 's' (select & next obj.)")
        print("      - 'd' (reject obj.)")
        print("      - 'b'/'m'/'t' (min./half/max. radius)")

        print(" --------------------------------------------")
        printf(" (%d/%d) Galaxy: <<%s>>\n", obj_pos, n_list, id_obj[obj_pos])
        print("")
        print("     |  Size (r/rp) | alpha_index |")
        print("     |==============|=============|")


        # Loop principal
        while (key != 100 && key != 115){

            printf("\r     |  %11.2f | %11.4f |", scale_r[radius], alpha_val[radius])

            # Resetea valores
            # x = 0.; y = 0.; wcs = 0; key = 0; cmd = ""

            # Lee cursor (con timeout implícito)
            stat = fscan(imcur, x, y, wcs, key, cmd)

            if (stat == EOF) {
                print("EOF detectado, saliendo...")
                break
            }

            # Solo procesa si hay input válido
            if (x > 0 || y > 0 || key > 0) {

                if (key == 43){

                    # Update radius:
                    radius = radius + delta
                    # color region:
                    if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
                    else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
                    else if(alpha_val[radius] > 0.15){ color_reg = "red"}

                    # Temporal ds9 region file: initial conditions
                    delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
                    print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # refrence (Rp) aperture: eliptical
                    expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
                    printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # Desplegar la elipse (region ds9) inicial o r = 1*rp:
                    print("!xpaset -p ds9 frame 1") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    print("!xpaset -p ds9 frame 2") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
                    print("! xpaset -p ds9 region load all ", tmp_string) | cl

                }else if(key == 45){

                    # update radius:
                    radius = radius - delta
                    # color region:
                    if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
                    else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
                    else if(alpha_val[radius] > 0.15){ color_reg = "red"}

                    # Temporal ds9 region file: initial conditions
                    delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
                    print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # refrence (Rp) aperture: eliptical
                    expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
                    printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # Desplegar la elipse (region ds9) inicial o r = 1*rp:
                    print("!xpaset -p ds9 frame 1") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    print("!xpaset -p ds9 frame 2") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
                    print("! xpaset -p ds9 region load all ", tmp_string) | cl

                }else if (key == 116){ # 't' ascii

                    # update radius:
                    radius = 57
                    # color region:
                    if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
                    else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
                    else if(alpha_val[radius] > 0.15){ color_reg = "red"}

                    # Temporal ds9 region file: initial conditions
                    delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
                    print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # refrence (Rp) aperture: eliptical
                    expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
                    printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # Desplegar la elipse (region ds9) inicial o r = 1*rp:
                    print("!xpaset -p ds9 frame 1") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    print("!xpaset -p ds9 frame 2") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
                    print("! xpaset -p ds9 region load all ", tmp_string) | cl


                }else if (key == 109){ # 'm' ascii

                    # update radius:
                    radius = 27
                    # color region:
                    if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
                    else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
                    else if(alpha_val[radius] > 0.15){ color_reg = "red"}

                    # Temporal ds9 region file: initial conditions
                    delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
                    print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # refrence (Rp) aperture: eliptical
                    expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
                    printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # Desplegar la elipse (region ds9) inicial o r = 1*rp:
                    print("!xpaset -p ds9 frame 1") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    print("!xpaset -p ds9 frame 2") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
                    print("! xpaset -p ds9 region load all ", tmp_string) | cl

                }else if (key == 98){ # 'b' ascii

                    # update radius:
                    radius = 17
                    # color region:
                    if(alpha_val[radius] <= 0.095){ color_reg = "blue"}
                    else if(alpha_val[radius] > 0.095 && alpha_val[radius] <= 0.15){ color_reg = "yellow"}
                    else if(alpha_val[radius] > 0.15){ color_reg = "red"}

                    # Temporal ds9 region file: initial conditions
                    delete(tmp_dir//"/"//"tmp_ellipse_draw.reg", ver-, >& "dev$null")
                    print("# Region file format: DS9 version 4.1", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print('global color=red dashlist=8 3 width=2 font="helvetica 14 normal roman" select=1 highlite=1 dash=2 fixed=0 edit=0 move=0 delete=1 include=1 source=1', >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    print("image", >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # refrence (Rp) aperture: eliptical
                    expre = 'ellipse('//str(x_0)//','//str(y_0)//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos])//','//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size: '//str(scale_r[radius])//'Rp, alpha_val = %7.4f}\n'
                    printf(expre, alpha_val[radius], >> tmp_dir//"/"//"tmp_ellipse_draw.reg")
                    # Desplegar la elipse (region ds9) inicial o r = 1*rp:
                    print("!xpaset -p ds9 frame 1") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    print("!xpaset -p ds9 frame 2") | cl
                    print("!xpaset -p ds9 regions delete all") | cl
                    tmp_string = tmp_dir//"/"//"tmp_ellipse_draw.reg"
                    print("! xpaset -p ds9 region load all ", tmp_string) | cl

                }else if (key == 115){ # 's' key

                    # Imprime objeto en la lista seleccionada:
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %12.2f %5.3f %11.4f\n", id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], scale_r[radius], ccdistance[obj_pos], alpha_val[radius], >> rot_cat_dir//"/"//"select_rot_index.cat")

                    # Crea la region ds9 para ese objeto con valor alpha:
                    expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size:'//str(scale_r[radius])//'*Rp, alpha= %.4f}\n'
                    printf(expre, alpha_val[radius], >> ds9_dir//"/"//"select_rot_index.reg")

                    # Imprime objeto en lista de aperturas
                    printf(" %32s %7d %7d %7.2f %7s\n", id_obj[obj_pos], obj_pos, radius, scale_r[radius], color_reg, >> data_dir//"/"//"select_apertures.cat")

                }else if (key == 100){ # 'd' key (reject, discard, delete obj)

                    # Imprime objeto en la lista seleccionada:
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %12.2f %5.3f %11.4f\n", id_obj[obj_pos], xwin_img[obj_pos], ywin_img[obj_pos], ra_j00[obj_pos], dec_j00[obj_pos], scale_r[radius], ccdistance[obj_pos], alpha_val[radius], >> data_dir//"/"//"reject_objects.cat")

                    # Crea la region ds9 para objeto descartado:
                    expre = 'ellipse('//str(ra_j00[obj_pos])//','//str(dec_j00[obj_pos])//','//str(scale_r[radius] * petro_r[obj_pos] * a_img[obj_pos] * pix_scale)//'",'//str(scale_r[radius] * petro_r[obj_pos] * b_img[obj_pos] * pix_scale)//'",'//str(theta_img[obj_pos])//') # color='//color_reg//' text={Size:'//str(scale_r[radius])//'*Rp, alpha= %.4f}\n'
                    printf(expre, alpha_val[radius], >> data_dir//"/"//"reject_objects.reg")

                }else if(key == 101){  # 'e' ascii (edit obj)

                    edit_img = yes
                    # limpiar DS9:
                    # print("! xpa -p ds9 frame delete all") | cl
                    break

                }else if(key == 113){ # 'q' ascii (Exit task)

                    # 'q' salir guardar ultimo ?
                    printf("\n\n The last object not saved!\n (n:%d ID:%s)\n", obj_pos, id_obj[obj_pos])
                    goto exit_task

                }
            } # END if(valid imcursor)
        } # END while

        if(edit_img == yes){
            print("\n ------------------------------------------")
            print("\n Go to 'imedit' task: ")
            goto to_edit
        }

    } # END FOR obj_pos

    # TO SELECT IF LIST EXISTS:
    to_edit:

    if(edit_img == yes){

        if(!access(log_dir)){mkdir(log_dir)}

        # Abre un nuevo marco:
        # print("! xpa -p ds9 frame new") | cl

        print("clear") | cl
        print("")
        print(" =========== 'imedit' task ============")
        print(" The CURSOR should! point IN DS9 window")
        print(" Avalaible inputs:\n")

        print("     - 'q' (Exit & Save)")
        print("     - 'r' (redraw: restart)")
        print("     - 'a' (replacement bg. rectangle.)")
        print("     - 'b' (replacement bg. aperture)")
        print("     - '+' (radius+step aperture)")
        print("     - '-' (radius-step aperture)")
        sleep(2)

        log_dir = log_dir//"/"//"cursor_area_"

        delete(log_dir//id_obj[obj_pos]//".logfile", ver-, >& "dev$null")

        printf(tmp_dir//"/"//"area_%.1f_obs_"//id_obj[obj_pos], low_clip) | scan(areaglxy_img)

        printf(tmp_dir//"/"//"imedit"//"/"//"edit_area_%.1f_obs_"//id_obj[obj_pos], low_clip) | scan(areaglxy_img_edit)

        if(list_select == yes){
            # 'imedit' task: ** QUIET **
            imdelete(areaglxy_img_edit, >& "dev$null")
            imedit(areaglxy_img, areaglxy_img_edit, cursor=log_dir//id_obj[obj_pos]//".logfile", display=no)
        }else{
            # 'imedit' task: ** INTERACTIVE **
            imdelete(areaglxy_img_edit, >& "dev$null")
            imedit(areaglxy_img, areaglxy_img_edit, logfile=log_dir//id_obj[obj_pos]//".logfile", command = "display $image 1 erase=$erase fill=no zscale=no order=0 >& dev$null")
        }

        # Editar el resto de imagenes:
        imdelete(rot_asymm_dir//"/"//"edit_rot_asymmpix_"//id_obj[obj_pos], >& "dev$null")
        imedit(rot_asymm_dir//"/"//"rot_asymmpix_"//id_obj[obj_pos], rot_asymm_dir//"/"//"edit_rot_asymmpix_"//id_obj[obj_pos], cursor=log_dir//id_obj[obj_pos]//".logfile", display=no)
        # Aplicar a residual asymmetrical pixels?:

        # =======================================================================================
        #  CALCULO DE INDICE DE ASIMETRIA PARA OBJETOS EDITADOS (todas las aperturas)           #
        # =======================================================================================

        # ASYMMETRY INDEX (output) CATALOGS HEADERS ()*.cat)
        #if(obj_pos == 1){
        delete(tmp_dir//"/"//"edit_rot_prfl_index_set.cat", ver-, >& "dev$null")
        delete(tmp_dir//"/"//"edit_rot_cum_index_set.cat", ver-, >& "dev$null")
        #}
        # Ciclo para crear HEADER anterior:
        for(j=1; j<=95; j+=2){
            if(j == 1){

                # III. Asymmetry area SET: first
                printf("#%31s A_%4.2frp", "ID_OBJ", scale_r[j], >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: first
                printf("#%31s cum_%4.2frp", "ID_OBJ", scale_r[j], >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")

            }else if(j == 95){
                # III. Asymmetry area SET: last
                printf(" A_%4.2frp\n", scale_r[j], >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: first
                printf(" cum_%4.2frp\n", scale_r[j], >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")

            }else{
                # III.Asymmetry area SET: mid
                printf(" A_%4.2frp", scale_r[j], >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: mid
                printf(" cum_%4.2frp", scale_r[j], >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")
            }
        }

        # Leer valores ya calculados: densidad_de_fondo_minima; ----------------------------------
        # Center Areas:
        imstat(tmp_dir//"/"//"areacenter_"//id_obj[obj_pos], fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        inner_area[obj_pos] = meanpix * ttlpix

        # Observed maximum area for cumulative denominator  alpha index:
        imstat(areaglxy_cntrmsk_maxaper_img//id_obj[obj_pos], fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
        n_areattl[obj_pos] = meanpix * ttlpix


        # Leer 'min_densitybg' para obj_pos:
        list = rot_cat_dir//"/"//"rot_patch_bg_set.cat"
        tmp_cont = 0
        while(fscan(list, line) != EOF){

            if(substr(line, 1, 1) != "#"){

                tmp_cont = tmp_cont + 1

                if(tmp_cont == obj_pos){
                    print(line) | scan(tmp_id, min_densitybg)
                    print(line)
                    break
                }
            }
        }
        list = ""
        tmp_cont = 1

        # Tamaño del cuadrado a recortar: measure
        side_frame[obj_pos] = 2 * (ro_ann + 1) * (petro_r[obj_pos] * a_img[obj_pos])

        # Expression for annulus patch of bg estimation: outer
        expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
        # ----------------------------------------------------------------------------------------

        #
        asymmpixel_img = rot_asymm_dir//"/"//"edit_rot_asymmpix_"//id_obj[obj_pos]
        areaglxy_img = areaglxy_img_edit

        # CICLO para aumentar la apertura:
        for(j=1; j<=95; j+=2){

            # Measurement apperture (binary area):
            imdelete(tmp_dir//"/"//"tmp_aperture", >& "dev$null")
            imexpr(expre1//" ? 1 : 0", tmp_dir//"/"//"tmp_aperture", side_frame[obj_pos]/2, side_frame[obj_pos]/2, scale_r[j]*petro_r[obj_pos]*a_img[obj_pos], scale_r[j]*petro_r[obj_pos]*b_img[obj_pos], theta_img[obj_pos]*const_pi/180, dims=str(side_frame[obj_pos])//","//str(side_frame[obj_pos]), verb-)

            # Asymmetrical pixel image in aperture[obj_pos]
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_asymmpix_ap", asymmpixel_img, tmp_dir//"/"//"tmp_aperture", verb-)
            # Asymmetrical pixels counting:
            imstat(tmp_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_asymmpix = meanpix * ttlpix

            # Total pixels (N_tot) alpha = n_asymmpix / N_tot
            imdelete(tmp_dir//"/"//"tmp_areattl_ap", >& "dev$null")
            imexpr("a*b", tmp_dir//"/"//"tmp_areattl_ap", areaglxy_img, tmp_dir//"/"//"tmp_aperture", verb-)
            imstat(tmp_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            ap_n_areattl = meanpix * ttlpix

            # ALPHA ASYMETRRY INDEX CALCULATION: ==========================================
            # area_delta: área donde se aplica o escala la (densidad) de correction
            delta_area = const_pi * (a_img[obj_pos] * b_img[obj_pos]) * (scale_r[j] * petro_r[obj_pos])**2
            delta_area = delta_area - inner_area[obj_pos]
            if(delta_area <= 0){ delta_area = 0 }

            if(ap_n_areattl <= 1){
                prfl_index_alpha = 0
            }else{
                prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / ap_n_areattl
            }

            cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / (n_areattl[obj_pos])

            # PRINT CATALOGS ====================================================
            if(j == 1){

                # III. Asymmetry area SET: first
                printf("%32s %8.4f", "edit_"//id_obj[obj_pos], prfl_index_alpha, >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: first
                printf("%32s %11.4f", id_obj[obj_pos], cum_index_alpha, >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")

            }else if(j == 95){

                # III. Asymmetry area SET: last
                printf(" %8.4f\n", prfl_index_alpha, >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: last
                printf(" %11.4f\n", cum_index_alpha, >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")

            }else{

                # III. Asymmetry area SET: mid
                printf(" %8.4f", prfl_index_alpha, >> tmp_dir//"/"//"edit_rot_prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: mid
                printf(" %11.4f", cum_index_alpha, >> tmp_dir//"/"//"edit_rot_cum_index_set.cat")
            }


            imdelete(tmp_dir//"/"//"tmp_aperture", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
            imdelete(tmp_dir//"/"//"tmp_areattl_ap", >& "dev$null")

        } # END FOR



        # Imprime catálogos:

        obj_i = obj_pos
        log_dir = obs_dir//"/"//"imedit"
        # edit_img = no
        goto next_obj

    }



    print("\n End task.")

    exit_task:

    # print("Exit task.")
    print("-------------------------------------------------------------")
    print("")
    beep

end
