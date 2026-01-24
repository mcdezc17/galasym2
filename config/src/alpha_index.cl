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
    string expr, ellip_expr
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
    string obs_area

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
    # temporal variables:
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_outfile

    # nombre de imagenes:
    string observed_img[999], obs_setmask_img[999]
    string bgrms_img[999]
    string mod_setmask_img[999]
    string residual_img[999], res_setmask_img[999]

    # carpetas prinicpales:
    string alpha_dir, cache_dir
    string alphaimg_dir, area_dir, asymm_area_dir, frames_dir
    string file_dir, ds9_dir, cat_dir

    # otras carpetas:
    string datafiles_dir
    string folder_sky
    string outsex_dir

    # direcciones de imagenes:
    string observed_dir, bckgrnd_dir
    string model_dir, residual_dir

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

    alphaimg_dir   = alpha_dir//"/"//"images"
    frames_dir     = alphaimg_dir//"/"//"small_frames"
    area_dir       = alphaimg_dir//"/"//"area_pixels"
    asymm_area_dir = alphaimg_dir//"/"//"asymm_area_pixels"

    cache_dir = alpha_dir//"/"//"cache"

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    bckgrnd_dir  = "data/data_images/background"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"

    print("\n------------------------------------------")
    print(" START TASK: alpha_index")

    # ==================================================
    # Leer lista de parametros de los SEx-modelos:
    # ==================================================

    # listas heredadas exactamente de 'find_objs' task:
    params_list = outsex_dir//"/"//"params_to_index.ascii"
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
        center_rot_list = datafiles_dir//"/"//"rms_mincenter.ascii"
    }else if(strlwr(center_rot) == "abs"){
        center_rot_list = datafiles_dir//"/"//"abs_mincenter.ascii"
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

    # string areaglxy_img

    # Observed area for N total pixels:
    # printf(cache_dir//"/"//"area_%.1f_obs_"//"\n", low_clip) | scan(areaglxy_img)
    # Extended CENTER MASK for measure index (source + noise annulus):
    # centermodmask_img = cache_dir//"/"//"centermodelmask_"

    # name of image observed area without bulge:
    if(strlwr(bulge_clip) == "off"){
        printf("_obs_area_%.1f_nn", low_sigma) | scan(obs_area)
    }else{
        printf("_obs_area_%.1f_%.1f", low_sigma, hiblg_clip) | scan(obs_area)
    }

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"

    for(i=1;i<=n_list;i+=1){

        # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
        # De igual tamaño para todos los objetos:
        A_outer = scale_r[56] * petro_r[i] * a_img[i] + 10
        B_outer = scale_r[56] * petro_r[i] * b_img[i] + 10
        xlen_min[i] = 2 * sqrt((A_outer * cos(theta_rad[i]))**2 + (B_outer * sin(theta_rad[i]))**2)
        ylen_min[i] = 2 * sqrt((A_outer * sin(theta_rad[i]))**2 + (B_outer * cos(theta_rad[i]))**2)
        # asegurar len_min entero impar:
        if(xlen_min[i] % 2 == 0){xlen_min[i] = xlen_min[i] + 1}
        if(ylen_min[i] % 2 == 0){ylen_min[i] = ylen_min[i] + 1}

        # Recortar la imagen alrededor del centro temporal:
        # Vertices
        px1 = x0_rot[i] - int((xlen_min[i] - 1) / 2)
        px2 = x0_rot[i] + int((xlen_min[i] - 1) / 2)
        py1 = y0_rot[i] - int((ylen_min[i] - 1) / 2)
        py2 = y0_rot[i] + int((ylen_min[i] - 1) / 2)
        # Seccion a recortar:
        trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"

        force_obj = "data/force_"//id_obj[i]//".reg"
        if(access(force_obj)){
            # conservar el tamaño original de la imagen:
            trimsection = ""

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
            print("# ID A_IMG B_IMG THETA_IMG", > "data"//"/"//id_obj[i]//"_force_params.ascii")
            print(id_obj[i], " ", a_img[i], " ", b_img[i], " ", theta_img[i], >> "data"//"/"//id_obj[i]//"_force_params.ascii")
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

            # SEGUIMIENTO:
            # print("\n ro_ann_force: ", ro_ann_force)
            # print("")

        }

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

        # recorta tamaño optimo (LOW AREA 180 rot):
        tmp_infile = cache_dir//"/"//id_obj[i]//obs_area//".fits"//trimsection
        tmp_outfile = cache_dir//"/"//id_obj[i]//obs_area//".fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # recorta tamaño optimo (LOW AREA):
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"//trimsection
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)
        # recorta tamaño optimo (LOW AREA 180 rot):
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

        # Progress bar proccess:
        printf("\r Process (cutting images): %d%%", (i*100/n_list))
    }

    # ===============================================================
    #
    # ===============================================================
    print("\n\n--------- Computing alpha index ----------\n")

    string cat_dir
    if(!access(cat_dir)){mkdir(cat_dir)}

    # CATALOGS:
    for(i=1;i<=30;i+=1){
        if(j == 1){
                #        %ID  %fr %Nt %Nasymm_1 (I. N asymm. pixels SET: first)
                printf("#%31s %6s %6s N_%4.2frp", "ID_OBJ", "3/rp", "Nttl", scale_r[i], > cat_dir//"/"//"asymmpix_set.cat")

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

            }else if(j == 30){
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


    # ===============================================================
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

    printf(" OUTPUT FOLDER: ./%s\n", alpha_dir)
    print(" END TASK: alpha_index")
    print("\n------------------------------------------")
    print("")
    beep

end
