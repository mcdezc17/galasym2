procedure alpha_index()

string   center_rot = "rms"   {prompt = "'abs' or 'rms' minimization"}
real     low_sigma  = 2.0     {prompt = "low sigma clipping"}
string   bulge_clip = "10.0"  {prompt = "sigma-clip avoid bulge"}
string   disk_clip  = "10.0"  {prompt = "sigma-clip avoid disk"}
# Experimental stuff:
bool   sky_imgs    = no    {prompt = "'yes' usefull to experimental"}

# struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    real mean_val
    int n_pix
    # constants........
    real const_pi
    # patrameters......
    string key_word
    real pixel_scale
    real hiblg_clip, hidsk_clip
    real scale_r_offset, scale_r_step
    real scale_r[99]
    string expr, expre1, expre2, ellip_expr

    # list of objects:
    string params_list
    int n_list
    string id_obj[999]
    int  seg_number[999]
    real fit_ra_j00[999], fit_dec_j00[999]
    int fit_xc[999], fit_yc[999]
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999], eff_r[999]
    real kron_r[999], iso_area[999], iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # list of position to rotating images:
    string center_rot_list
    string tmp_id_obj
    real ra_rot[999], dec_rot[999]
    int x0_rot[999], y0_rot[999]

    # direcciones de imagenes:
    string observed_dir, bckgrnd_dir
    string model_dir, residual_dir

    # nombre de imagenes:
    string observed_img[999], obs_setmask_img[999]
    string bgrms_img[999]
    string mod_setmask_img[999]
    string residual_img[999], res_setmask_img[999]

    # recorte de imagenes:
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    int bulge_area[999]
    # forzar medida:
    string force_objs
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force
    # imagenes recortadas:
    string obs_area, area_glxy_img

    # carpetas prinicpales:
    string alpha_dir, cache_dir
    string alphaimg_dir, area_dir, asymm_area_dir, frames_dir
    string files_dir, ds9_dir, residual_alpha_dir, rotation_alpha_dir

    # otras carpetas:
    string datafiles_dir
    string folder_sky
    string outsex_dir

    # calculo de indices:
    real ccdistance[999]
    string measure_area_img
    int f_ri, f_ro
    real area_ann[4], n_noisepix[4], density_noise[4]
    real nbg_noisepix
    real ttl_rho
    real min1_bgdensity, min2_bgdensity, min3_bgdensity, min4_bgdensity
    int min1_pos, min2_pos, min3_pos, min4_pos
    real tmp_current, min_densitybg
    string out_cat, out_ds9_cat
    real n_asymmpix, ap_n_areattl
    real delta_area, delta_area_cum
    real cum_n_areattl[999]
    real prfl_index_alpha, cum_index_alpha

    # temporal variables:
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_outfile

    # ==================================================
    find_objs
    scan(tmp_wait)
    # ==================================================
    glxy_model
    scan(tmp_wait)
    # ==================================================
    find_center
    scan(tmp_wait)
    # ==================================================

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25
    scale_r_step = 0.05

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (scale_r_step * (i-1))
    }

    if(strlwr(bulge_clip) == "off" && strlwr(disk_clip) != "off"){
        # Lee directorio como p.ej.: alpha_2.0_nn_10.0
        # NOTA: verificacion mas robusta del tipo de variable:
        hiblg_clip = 1.0e6                                           # Evita crear mas codigo abajo, pero no es lo mejor!
        hidsk_clip = real(disk_clip)
        # -
        if(hidsk_clip > 0 && hidsk_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_nn_%.1f", low_sigma, hidsk_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'disk_clip' out of range!")}

    }else if(strlwr(bulge_clip) != "off" && strlwr(disk_clip) == "off"){
        # Lee directorio como p.ej.: alpha_2.5_8.0_nn
        hiblg_clip = real(bulge_clip)
        hidsk_clip = 1.0e6                                            # Evita crear mas codigo abajo, pero no es lo mejor!
        # -
        if(hiblg_clip > 0 && hiblg_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_%.1f_nn", low_sigma, hiblg_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'bulge_clip' out of range!")}

    }else if(strlwr(bulge_clip) == "off" && strlwr(disk_clip) == "off"){
        # -
        hiblg_clip = 1.0e6
        hidsk_clip = 1.0e6
        # lee directorio:
        printf("alpha_%.1f_nn_nn", low_sigma) | scan(alpha_dir)
        # -
    }else{
        # -
        hiblg_clip = real(bulge_clip)
        hidsk_clip = real(disk_clip)
        #-
        # lee directorio:
        printf("alpha_%.1f_%.1f_%.1f", low_sigma, hiblg_clip, hidsk_clip) | scan(alpha_dir)
    }

    # Folders alpha:
    alphaimg_dir   = alpha_dir//"/"//"images"
    frames_dir     = alphaimg_dir//"/"//"small_frames"
    area_dir       = alphaimg_dir//"/"//"area_pixels"
    asymm_area_dir = alphaimg_dir//"/"//"asymm_area_pixels"

    # Catalogs:
    files_dir = alpha_dir//"/"//"files"
    ds9_dir = files_dir//"/"//"ds9_regions"
    residual_alpha_dir = files_dir//"/"//"residual_area"
    rotation_alpha_dir = files_dir//"/"//"residual_rotation_area"

    cache_dir = alpha_dir//"/"//"cache"

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    bckgrnd_dir  = "data/data_images/background"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"
    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    print("\n------------------------------------------")
    print(" START TASK: alpha_index")

    # ==================================================
    # Leer lista de parametros de los SEx-modelos:
    # ==================================================

    # listas heredadas exactamente de 'find_objs' task:
    params_list = outsex_dir//"/"//"params_to_index.txt"
    # No existe archivo de entrada esperado:
    if(!access(params_list)){
        print("\n ERR(fatal): mandatory that it exist:")
        print(" - ", params_list)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        goto exit_task
    }

    list = params_list
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(id_obj[i], seg_number[i], fit_ra_j00[i], fit_dec_j00[i], fit_xc[i], fit_yc[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i], ri_ann[i], ro_ann[i], xlen_min[i], ylen_min[i])

            # TEMPORAL TAREA DISTANCIA:
            ccdistance[i] = 0

            # Correcciones:
            # petro_r[] ya fue corregido en 'glxy_model' task.
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[i] = theta_img[i] * const_pi / 180

            # Las imagenes existen como:
            bgrms_img[i] = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
            #seguimiento:
            if(!imaccess(bgrms_img[i])){print("\n ERR: not access to bgrms img!"); goto exit_task}

            observed_img[i] = observed_dir//"/"//id_obj[i]//".fits"
            #seguimiento:
            if(!imaccess(observed_img[i])){print("\n ERR: not access to observed img!"); goto exit_task}

            obs_setmask_img[i] = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"
            #seguimiento:
            if(!imaccess(obs_setmask_img[i])){print("\n ERR: not access to obs_setmask img!"); goto exit_task}

            mod_setmask_img[i] = model_dir//"/"//id_obj[i]//"_mod_setmask.fits"
            #seguimiento:
            if(!imaccess(mod_setmask_img[i] )){print("\n ERR: not access to setmask model img!"); goto exit_task}

            res_setmask_img[i] = residual_dir//"/"//id_obj[i]//"_res_setmask.fits"
            #seguimiento:
            if(!imaccess(res_setmask_img[i])){print("\n ERR: not access to observed img!"); goto exit_task}


        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""
    n_list = i

    # ==================================================
    # Leer lista de posicion de rotacion de imagen:
    # ==================================================

    # listas heredadas exactamente de 'find_center' task:
    if(strlwr(center_rot) == "rms"){
        center_rot_list = datafiles_dir//"/"//"rms_mincenter.txt"
    }else if(strlwr(center_rot) == "abs"){
        center_rot_list = datafiles_dir//"/"//"abs_mincenter.txt"
    }else{
        print("\n ERR: prompt 'center_rot' must be")
        print("      'abs' or 'rms' string!")
        print("\n Abort task!")
        goto exit_task
    }

    # No existe archivo de entrada esperado:
    if(!access(center_rot_list)){
        print("\n ERR(fatal): mandatory that it exist:")
        print(" - ", center_rot_list)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        goto exit_task
    }

    list = center_rot_list
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(tmp_id_obj, ra_rot[i], dec_rot[i], x0_rot[i], y0_rot[i])

            # seguimiento:
            if(tmp_id_obj != id_obj[i]){
                print("\n ERR: no matches between lists")
                print("       of objects and center rot-")
                print("       tation!")
                print("\n HINT: best run over again.")
                print("\n Abort task!")
                goto exit_task
            }

        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""

    # ===================================================
    # Obtener PIXEL_SCALE y SEEING_FWHM
    # ===================================================

    # Por ahoa obtener PIXEL_SCALE 'default.sex configuration' parametros:
    list = "config/sextractor/default.sex"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            if(key_word == "PIXEL_SCALE"){
                print(line) | scan(key_word, pixel_scale)
            }

        # END IF: lineas validas
        }
    # END WHILE: lectura lista
    }
    list = ""

    # ===============================================================
    # Recortar imagenes para realizar medida
    # ===============================================================

    print("\n------------ Cutting images --------------\n")
    if(!access(alpha_dir)){mkdir(alpha_dir)}
    if(!access(alphaimg_dir)){mkdir(alphaimg_dir)}
    if(!access(area_dir)){mkdir(area_dir)}
    if(!access(asymm_area_dir)){mkdir(asymm_area_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}

    # name of image observed area without bulge:
    if(strlwr(bulge_clip) == "off"){
        printf("_obs_area_%.1f_nn", low_sigma) | scan(obs_area)
    }else{
        printf("_obs_area_%.1f_%.1f", low_sigma, hiblg_clip) | scan(obs_area)
    }

    for(i=1;i<=n_list;i+=1){

        force_obj = "data/force_"//id_obj[i]//".reg"
        if(access(force_obj)){

            # extraer nuevos parametros de medida:
            expr = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
            print("\n  - Object to force measure: ", id_obj[i])
            printf(expr, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

            # SEGUIMIENTO:
            #print("\n Viejos parametros: ", a_img[i], b_img[i], theta_img[i])

            # Nuevos parametros:
            a_img[i] = a_int / (1.5 * petro_r[i])
            b_img[i] = b_int / (1.5 * petro_r[i])
            theta_img[i] = ell_angle
            theta_rad[i] = theta_img[i] * const_pi / 180
            print("# ID A_IMG B_IMG THETA_IMG", > "data"//"/"//id_obj[i]//"_force_params.txt")
            print(id_obj[i], " ", a_img[i], " ", b_img[i], " ", theta_img[i], >> "data"//"/"//id_obj[i]//"_force_params.txt")
            # SEGUIMIENTO:
            #print("\n Nuevos parametros: ", a_img[i], b_img[i], theta_img[i], petro_r[i])

            # Elipse exterior para extraer cielo:
            tmp_real = (((a_ext / (a_img[i] * petro_r[i])) - scale_r_offset) / scale_r_step) + 1
            ro_ann_force = int(tmp_real)
            # Asegurar entero proximo mas grande:
            if((tmp_real - ro_ann_force) >= 0.5){ro_ann_force += 1}
            # Actualizar nuevo parametro:
            ro_ann[i] = ro_ann_force
            # La elipse interior para extraer el cielo,
            # por definicion se toma como (1.7 r/rp):
            ri_ann[i] = 30

            # Recorta tamaño a la elipse exterior "forzada"
            A_outer = a_ext + 5
            B_outer = b_ext + 5
            xlen_min[i] = 2 * sqrt((A_outer * cos(theta_rad[i]))**2 + (B_outer * sin(theta_rad[i]))**2)
            ylen_min[i] = 2 * sqrt((A_outer * sin(theta_rad[i]))**2 + (B_outer * cos(theta_rad[i]))**2)
            # asegurar len_min entero impar:
            if(xlen_min[i] % 2 == 0){xlen_min[i] = xlen_min[i] + 1}
            if(ylen_min[i] % 2 == 0){ylen_min[i] = ylen_min[i] + 1}

            # SEGUIMIENTO:
            # print("\n ro_ann_force: ", ro_ann_force)
            # print("")

        }else{
            # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
            # De igual tamaño para todos los objetos:
            A_outer = scale_r[56] * petro_r[i] * a_img[i] + 10
            B_outer = scale_r[56] * petro_r[i] * b_img[i] + 10
            xlen_min[i] = 2 * sqrt((A_outer * cos(theta_rad[i]))**2 + (B_outer * sin(theta_rad[i]))**2)
            ylen_min[i] = 2 * sqrt((A_outer * sin(theta_rad[i]))**2 + (B_outer * cos(theta_rad[i]))**2)
            # asegurar len_min entero impar:
            if(xlen_min[i] % 2 == 0){xlen_min[i] = xlen_min[i] + 1}
            if(ylen_min[i] % 2 == 0){ylen_min[i] = ylen_min[i] + 1}
        }

        # Recortar la imagen alrededor del centro temporal:
        # Vertices
        px1 = x0_rot[i] - int((xlen_min[i] - 1) / 2)
        px2 = x0_rot[i] + int((xlen_min[i] - 1) / 2)
        py1 = y0_rot[i] - int((ylen_min[i] - 1) / 2)
        py2 = y0_rot[i] + int((ylen_min[i] - 1) / 2)
        # Seccion a recortar:
        trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"

        # BULBO GALACTIVO:
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("a >= b*c", tmp_outfile, mod_setmask_img[i], hiblg_clip, bgrms_img[i], verb-)

        # AREA DE LA GALAXIA (I_obs >= low_sigma)
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//obs_area//".fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("a >= b*c && d == 0", tmp_outfile, obs_setmask_img[i], low_sigma, bgrms_img[i], tmp_infile, verb-)

        # LOW AREA PIXELS:
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("a >= b*c && d == 0", tmp_outfile, res_setmask_img[i], low_sigma, bgrms_img[i], tmp_infile, verb-)

        # ASYMMETRYCAL AREA PIXELS 180° rotation:
        # transposicion = rotar 90 grados:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"//"[*,-*]"
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels_rot90.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # repetir transposicion = 180°:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels_rot90.fits"//"[*,-*]"
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # eliminar imagen a 90°:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels_rot90.fits"
        imdelete(tmp_infile, ver-, >& "dev$null")
        # Residuo asimetrico de area (N-N_180):
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        tmp_infile2 = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a-b) > 0", tmp_outfile, tmp_infile, tmp_infile2, verb-)
        # seguimiento:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        tmp_infile2 = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_negative_asymm_areapixels.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("a-b", tmp_outfile, tmp_infile, tmp_infile2, verb-)

        # recorta tamaño optimo (BULBO a evitar):
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"//trimsection
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # calcular area del bulbo a evitar:
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # area en pixeles del bulbo:
        bulge_area[i] = int(mean_val * n_pix)

        # recorta tamaño optimo (LOW AREA):
        tmp_infile = cache_dir//"/"//id_obj[i]//obs_area//".fits"//trimsection
        tmp_outfile = cache_dir//"/"//id_obj[i]//obs_area//".fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # Maxima area para indice acumulativo:
        tmp_infile = cache_dir//"/"//id_obj[i]//obs_area//".fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_area.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[30] * petro_r[i] * a_img[i], scale_r[30] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)
        # Counting maxima area para indice acumulativo:
        tmp_infile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_area.fits"
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # area en pixeles del bulbo:
        cum_n_areattl[i] = int(mean_val * n_pix)

        # recorta tamaño optimo (RES AREA):
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"//trimsection
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # recorta tamaño optimo (RES AREA 180 rot):
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"//trimsection
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # recorta tamaño optimo (ASYMMETRYCAL AREA PIXELS):
        tmp_infile = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"//trimsection
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # recorta tamaño optimo (NEGATIVE ASYMMETRYCAL AREA PIXELS):
        tmp_infile = asymm_area_dir//"/"//id_obj[i]//"_negative_asymm_areapixels.fits"//trimsection
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_negative_asymm_areapixels.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # (SEGUIMIENTO) observed_setmask:
        tmp_infile = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)

        # Progress bar proccess:
        printf("\r Process (cutting images): %d%%", (i*100/n_list))
    }

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================

    if(!access(files_dir)){mkdir(files_dir)}
    if(!access(residual_alpha_dir)){mkdir(residual_alpha_dir)}
    if(!access(rotation_alpha_dir)){mkdir(rotation_alpha_dir)}
    if(!access(ds9_dir)){mkdir(ds9_dir)}

    for(i=1;i<=30;i+=1){

        if(i == 1){

            # I.      %ID  %fr %Nt %Nasymm_1 (I. N asymm. pixels SET: first)
            printf("#%31s %6s %6s N_%4.2frp", "ID_OBJ", "3/rp", "Nttl", scale_r[i], > residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II.      %ID  %Nb %db %fr %Nt %Areacorr_1 (II. Noise pixels SET: first)
            printf("#%31s %6s %7s %6s %6s d_%4.2frp", "ID_OBJ", "Nbg", "rho_bg", "3/rp", "Nttl", scale_r[i], > residual_alpha_dir//"/"//"noisepix_set.cat")

            # III. PROFILE Asymmetry area SET: first
            printf("#%31s prfl_%4.2frp", "ID_OBJ", scale_r[i], > residual_alpha_dir//"/"//"prfl_index_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: first
            printf("#%31s cum_%4.2frp", "ID_OBJ", scale_r[i], > residual_alpha_dir//"/"//"cum_index_set.cat")

            # V. NORMAL SNR CATALOG
            printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[i], > files_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            print("# NOTE: SNR_set for annular if bulge_clip != 'off'", > files_dir//"/"//"SNR_ann_set.cat")
            printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[i], > files_dir//"/"//"SNR_ann_set.cat")

        }else if(i == 30){

            #  I.     %Nasymm_last (I. N asymm. pixels SET: last)
            printf(" N_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II. Noise pixel SET: last
            printf(" d_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"noisepix_set.cat")

            # III. PROFILE Asymmetry area SET: first
            printf(" prfl_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"prfl_index_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: first
            printf(" cum_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"cum_index_set.cat")

            # V. SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[i], "SNR_ttl_1rp", >> files_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[i], "SNR_ttl_1rp", >> files_dir//"/"//"SNR_ann_set.cat")

        }else{
            # I.     %Nasymm_i (All parameters catalog:)
            printf(" N_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II. Noise pixel SET: mid
            printf(" d_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"noisepix_set.cat")

            # III. PROFILE Asymmetry area SET: mid
            printf(" prfl_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"prfl_index_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: mid
            printf(" cum_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"cum_index_set.cat")

            # V. SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp", scale_r[i], >> files_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp", scale_r[i], >> files_dir//"/"//"SNR_ann_set.cat")

        }
    # END FOR: header catalogs
    }

    # ROTATED ALPHA INDEX USE THE SAME HEADER:
    delete(rotation_alpha_dir//"/"//"rot_asymmpix_set.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_noisepix_set.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_prfl_index_set.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_cum_index_set.cat", >& "dev$null")
    copy(residual_alpha_dir//"/"//"asymmpix_set.cat", rotation_alpha_dir//"/"//"rot_asymmpix_set.cat")
    copy(residual_alpha_dir//"/"//"noisepix_set.cat", rotation_alpha_dir//"/"//"rot_noisepix_set.cat")
    copy(residual_alpha_dir//"/"//"prfl_index_set.cat", rotation_alpha_dir//"/"//"rot_prfl_index_set.cat")
    copy(residual_alpha_dir//"/"//"cum_index_set.cat", rotation_alpha_dir//"/"//"rot_cum_index_set.cat")

    # COMPACT RESIDUAL AREA INDEX:

    # VII. Residual Area with center distance (PROFILE CURVE)
    printf("#%31s %11s %11s %11s %11s %7s prf%3.1f_1.0rp prfl%3.1f_1.5rp prfl%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_sigma, low_sigma, low_sigma, > residual_alpha_dir//"/"//"prfl_index_main.cat")

    # IV. Residual area with center distance (CUMMULATIVE CURVE)
    printf("#%31s %11s %11s %11s %11s %7s cum%3.1f_1.0rp cum%3.1f_1.5rp cum%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_sigma, low_sigma, low_sigma, > residual_alpha_dir//"/"//"cum_index_main.cat")

    # COMPACT RESIDUAL ROTATION AREA INDEX:

    # VIII. Residual Rotated Area with center distance (PROFILE CURVE)
    printf("#%31s %11s %11s %11s %11s %7s prfl%3.1f_1.0rp prfl%3.1f_1.5rp prfl%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_sigma, low_sigma, low_sigma, low_sigma, low_sigma, low_sigma, > rotation_alpha_dir//"/"//"rot_prfl_index_main.cat")

    # IX. Residual Rotated Area with center distance (CUMMULATIVE CURVE)
    printf("#%31s %11s %11s %11s %11s %7s cum%3.1f_1.0rp cum%3.1f_1.5rp cum%3.1f_2.0rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "D_Cc(Mpc)", low_sigma, low_sigma, low_sigma, low_sigma, low_sigma, low_sigma, > rotation_alpha_dir//"/"//"rot_cum_index_main.cat")

    # DENSITY NOISE CATALOG:
    printf("#%31s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "ID_OBJ", "min_rho", "ttl_rho", "A1_ann", "N1_ann", "rho1", "A2_ann", "N2_ann", "rho2", "A3_ann", "N3_ann", "rho3", "A4_ann", "N4_ann", "rho4", > residual_alpha_dir//"/"//"patch_bg_set.cat")
    # The same header for residual rotated area:
    delete(rotation_alpha_dir//"/"//"rot_patch_bg_set.cat",  >& "dev$null")
    copy(residual_alpha_dir//"/"//"patch_bg_set.cat", rotation_alpha_dir//"/"//"rot_patch_bg_set.cat")

    # DS9 HEADER ACATALOG INDEX VALUE (PROFILE CURVE):
    print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"prfl_index.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"prfl_index.reg")
    print("fk5", >> ds9_dir//"/"//"prfl_index.reg")
    # copy rotational
    delete(ds9_dir//"/"//"rot_prfl_index.reg",  >& "dev$null")
    copy(ds9_dir//"/"//"prfl_index.reg", ds9_dir//"/"//"rot_prfl_index.reg")

    # DS9 HEADER ACATALOG INDEX VALUE (CUMMULATIVE CURVE):
    delete(ds9_dir//"/"//"cum_index.reg",  >& "dev$null")
    print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"cum_index.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"cum_index.reg")
    print("fk5", >> ds9_dir//"/"//"cum_index.reg")
    # copy rotational
    delete(ds9_dir//"/"//"rot_cum_index.reg",  >& "dev$null")
    copy(ds9_dir//"/"//"cum_index.reg", ds9_dir//"/"//"rot_cum_index.reg")

    # ===============================================================
    # INDEX COMPUTATION
    # ===============================================================
    print("\n\n--------- Computing alpha index ----------\n")

    for(k=1;k<=2;k+=1){

        for(i=1;i<=n_list;i+=1){

            area_glxy_img = cache_dir//"/"//id_obj[i]//obs_area//".fits"

            # La primera ejecucion es para el indice de area residual:
            if(k==1){
                measure_area_img = area_dir//"/"//id_obj[i]//"_areapixels.fits"
                out_cat = residual_alpha_dir//"/"
                out_ds9_cat = ds9_dir//"/"
            # la segunda ejecucion es para el indice rotacional de residuo de area:
            }else{
                measure_area_img = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
                out_cat = rotation_alpha_dir//"/"//"rot_"
                out_ds9_cat = ds9_dir//"/"//"rot_"
            }

            # ESTIMACION DEL FONDO -----------------------------------------------------------

            f_ri = ri_ann[i]
            f_ro = ro_ann[i]

            # SEGUIMIENTO:
            # print("\n ", real(xlen_min[i])/2, real(ylen_min[i])/2)

            # Annulus 1
            imdelete(cache_dir//"/"//"tmp_ann_1", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) > (J-b) && (I-a) >= -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_1", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 1
            imstat(cache_dir//"/"//"tmp_ann_1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[1] = mean_val * n_pix
            # Asymmetrical pixel counting ann[1]
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", measure_area_img, cache_dir//"/"//"tmp_ann_1", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[1] = mean_val * n_pix
            # Noise density ann[1]
            density_noise[1] = n_noisepix[1] / area_ann[1]

            # Annulus 2
            imdelete(cache_dir//"/"//"tmp_ann_2", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) <= (J-b) && (I-a) > -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_2", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 2
            imstat(cache_dir//"/"//"tmp_ann_2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[2] = mean_val * n_pix
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", measure_area_img, cache_dir//"/"//"tmp_ann_2", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[2] = mean_val * n_pix
            # Noise density ann[1]
            density_noise[2] = n_noisepix[2] / area_ann[2]

            # Annulus 3
            imdelete(cache_dir//"/"//"tmp_ann_3", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) < (J-b) && (I-a) <= -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_3", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 3
            imstat(cache_dir//"/"//"tmp_ann_3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[3] = mean_val * n_pix
            # Asymmetrical pixel counting ann[1]
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", measure_area_img, cache_dir//"/"//"tmp_ann_3", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[3] = mean_val * n_pix
            # Noise density ann[3]
            density_noise[3] = n_noisepix[3] / area_ann[3]

            # Annulus 4
            imdelete(cache_dir//"/"//"tmp_ann_4", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) >= (J-b) && (I-a) < -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_4", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 4
            imstat(cache_dir//"/"//"tmp_ann_4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[4] = mean_val * n_pix
            # Asymmetrical pixel counting ann[1]
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", measure_area_img, cache_dir//"/"//"tmp_ann_4", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[4] = mean_val * n_pix
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

            for(j=1;j<=4;j+=1){
                tmp_current = density_noise[j]

                if(tmp_current < min1_bgdensity){
                    # Shift all values down
                    min4_bgdensity = min3_bgdensity
                    min4_pos = min3_pos
                    min3_bgdensity = min2_bgdensity
                    min3_pos = min2_pos
                    min2_bgdensity = min1_bgdensity
                    min2_pos = min1_pos
                    min1_bgdensity = tmp_current
                    min1_pos = j
                }else if(tmp_current < min2_bgdensity){
                    # Shift values 2, 3 down
                    min4_bgdensity = min3_bgdensity
                    min4_pos = min3_pos
                    min3_bgdensity = min2_bgdensity
                    min3_pos = min2_pos
                    min2_bgdensity = tmp_current
                    min2_pos = j
                }else if(tmp_current < min3_bgdensity){
                    # Shift value 3 down
                    min4_bgdensity = min3_bgdensity
                    min4_pos = min3_pos
                    min3_bgdensity = tmp_current
                    min3_pos = j
                }else if(tmp_current < min4_bgdensity){
                    min4_bgdensity = tmp_current
                    min4_pos = j
                }
            # END FOR (j): encontrar densidad minima de cielo
            }

            # PRUEBAS:
            # min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos]) / (area_ann[min1_pos] + area_ann[min2_pos])
            # min_densitybg = (n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min2_pos] + area_ann[min3_pos])
            min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min1_pos] + area_ann[min2_pos] + area_ann[min3_pos])
            # min_densitybg = ttl_rho

            # Print catalog density noise -------------------------------------------------------------------
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", id_obj[i], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")

            # END: ESTIMACION DEL FONDO -----------------------------------------------------------

            if(k == 1){
                printf("\r - Residual Area index (old alpha): %d / %d", i, n_list)
            }else{
                printf("\r - Rotated Residual Area index....: %d / %d", i, n_list)
            }

            # Para ampliar la apertura de medida:
            for(j=1;j<=30;j+=1){

                # Asymmetrical pixel image in aperture scale_r[]
                imdelete(cache_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
                imexpr(expre1//" ? f : 0", cache_dir//"/"//"tmp_asymmpix_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], measure_area_img, verb-)
                # Residual Area (rotated) pixels counting:
                imstat(cache_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                n_asymmpix = mean_val * n_pix

                # aper. Total pixels (N_tot) alpha = n_asymmpix / N_tot(in aperture)
                imdelete(cache_dir//"/"//"tmp_areattl_ap", >& "dev$null")
                imexpr(expre1//" ? f : 0", cache_dir//"/"//"tmp_areattl_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], area_glxy_img, verb-)
                # Area galaxy counting:
                imstat(cache_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                ap_n_areattl = mean_val * n_pix

                # ECUACION DEL INDICE ALPHA: ==========================================

                delta_area_cum = (const_pi * (a_img[i] * b_img[i]) * (scale_r[30] * petro_r[i])**2) - bulge_area[i]

                # Si utiliza '<= 3.0' asegurese de que las lineas despues de '##estas#' esten comentadas:
                # Si utiliza '<= 0.0' entonces descomente las lineas despues de '##estas#'
                if(scale_r[j] * petro_r[i] <= 3.0){

                    delta_area = 0

                    if(ap_n_areattl <= 1){
                        prfl_index_alpha = 0
                    }else{
                        prfl_index_alpha = n_asymmpix / ap_n_areattl
                    }

                    cum_index_alpha = n_asymmpix / (cum_n_areattl[i] - (delta_area_cum * min_densitybg))
                }else{

                    ##estas#:
                    # delta_area = const_pi * (a_img[i] * b_img[i]) * ((scale_r[j] * petro_r[i])**2) - bulge_area[i]
                    ##estas#:
                    # if(delta_area <= 0){ delta_area = 0 }

                    # Comentar la siguiente linea SI Y SOLO SI las lineas que preceden a '##estas#' fueron descomentadas:
                    delta_area = const_pi * (a_img[i] * b_img[i]) * ((scale_r[j] * petro_r[i])**2 - 9.0)

                    if(ap_n_areattl <= 1){
                        prfl_index_alpha = 0
                    }else{
                        prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / (ap_n_areattl - (delta_area * min_densitybg))
                    }

                    cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / (cum_n_areattl[i] - (delta_area_cum * min_densitybg))
                }

                # ====================================================================================
                # PRINT CATALOGS
                # ====================================================================================

                if(j == 1){
                    #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: first)
                    printf("%32s %6.3f %6d %8d", id_obj[i], (3/petro_r[i]), iso_area[i], n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    #       %ID  %Nb %db   %fr   %Nt %Areacorr_1 (II. Noise pixel SET: first)
                    printf("%32s %6d %7.4f %6.3f %6d %8.2f", id_obj[i], nbg_noisepix, min_densitybg, (3/petro_r[i]), iso_area[i], delta_area, >> out_cat//"noisepix_set.cat")

                    # III. Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[i], prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: first
                    printf("%32s %11.4f", id_obj[i], cum_index_alpha, >> out_cat//"cum_index_set.cat")

                }else if(j == 30){

                    # I. Asymmetrical pixel SET: last
                    printf(" %8d\n", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    # II. Noise pixel SET: last
                    printf(" %8.2f\n", delta_area, >> out_cat//"noisepix_set.cat")

                    # III. PROFILE Asymmetry area SET: last
                    printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: last
                    printf(" %11.4f\n", cum_index_alpha, >> out_cat//"cum_index_set.cat")

                }else{

                    # I. Asymetrical pixel SET: mid
                    printf(" %8d", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    # II. Noise pixel SET: mid
                    printf(" %8.2f", delta_area, >> out_cat//"noisepix_set.cat")

                    # III. PROFILE Asymmetry area SET: mid
                    printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: mid
                    printf(" %11.4f", cum_index_alpha, >> out_cat//"cum_index_set.cat")
                }

                # ====================================================================================
                # PRINT CATALOGS: Tree fixed apertures
                # ====================================================================================
                if(j == 16){

                    # PROFILE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], ccdistance[i], prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                    # CUMULATIVE Main catalog Asymetry
                    printf("%32s %11.4f %11.4f %11.8f %11.8f %7.3f %11.4f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], ccdistance[i], cum_index_alpha, >> out_cat//"cum_index_main.cat")

                }else if(j == 26){

                    # PROFILE MAIN catalog Asymmetry
                    printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                    # CUMULATIVE MAIN catalog Asymmetry
                    printf(" %11.4f", cum_index_alpha, >> out_cat//"cum_index_main.cat")

                    # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                    expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(1.5 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//', (1.55rp): '//str(prfl_index_alpha)//'}'
                    print(expr, >> out_ds9_cat//"prfl_index.reg")

                    # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                    expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(1.5 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//', (1.55rp): '//str(cum_index_alpha)//'}'
                    print(expr, >> out_ds9_cat//"cum_index.reg")

                }else if(j == 30){

                    # PROFILE MAIN catalog Asymmetry
                    printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_index_main.cat")

                    # CUMULATIVE MAIN catalog Asymmetry
                    printf(" %11.4f\n", cum_index_alpha, >> out_cat//"cum_index_main.cat")

                    # PROFILE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                    expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(2 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={(1rp): '//str(prfl_index_alpha)//'}'
                    print(expr, >> out_ds9_cat//"prfl_index.reg")

                    # CUMULATIVE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                    expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(2 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={(1rp): '//str(cum_index_alpha)//'}'
                    print(expr, >> out_ds9_cat//"cum_index.reg")

                }
                # END PRINT CATALOGS ===============================================================


            #END FOR (j): apertura de medida
            }

        # END FOR (i): lista de objetos
        }
        print("")
    # END FOR (k): indices alpha
    }

    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # ===============================================================
    # EXPERIMENTAL STUFF ============================================
    if(sky_imgs == yes){
        # Busca carpeta especifica:
        folder_sky = "sky_folder"
        # Verifica acceso:
        if(!access(folder_sky)){

            print("\n ERR: esta en un modo experimental.")
            print("   Se espera una lista de imagenes en")
            print("   una carpeta llamada 'sky_folder'.")
            print("\n Abort task!")
            goto exit_task
        }

        # Si accede: debe verificar que exista una imagen correspondiente
        # 'id_obj//"_sky.fits"' para cada imagen a analizar 'id_obj//".fits"'

    }
    # EXPERIMENTAL STUFF ============================================
    # ===============================================================

    exit_task:

    print("\n------------------------------------------")
    printf(" OUTPUT FOLDER: ./%s\n", alpha_dir)
    print(" END TASK: alpha_index")
    print("------------------------------------------")
    print("")
    beep

end
