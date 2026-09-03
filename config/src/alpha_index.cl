procedure alpha_index()

string   center_rot = "abs" {prompt = "'abs' or 'rms' minimization"}
string   ctl_aper    = "2"  {prompt = "'all' (full loop, 1..36) or space-separated Rp list, e.g. '1 1.5 2'"}
real     low_sigma  = 1.0   {prompt = "low sigma clipping"}
string   bulge_clip = "off" {prompt = "sigma-clip avoid bulge"}
string   disk_clip  = "off" {prompt = "sigma-clip avoid disk"}
bool     res_filter = yes   {prompt = "Aply boxcar filter on residual image"}
# bool     den_seg    = yes   {prompt = "Total area segmented(yes) or obs(no)"}
bool     shape_in   = yes   {prompt = "compute alpha in region avoid for a_shape?"}
bool     both_alpha = no    {prompt = "compute both alpha indices, old+rotational (yes) or rotational only (no, default)"}
bool     force      = no    {prompt = "force measure with ds9 regions"}
bool     min_corr   = no    {prompt = "minimize the sky correction"}
# Experimental stuff:
# bool   sky_imgs    = no    {prompt = "'yes' usefull to experimental"}
struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k, k_start, count
    struct line
    string key_word
    string extract_img
    real mean_val
    int n_pix
    # constants........
    real const_pi
    # patrameters......
    real hiblg_clip, hidsk_clip
    real scale_r_offset, scale_r_step
    real scale_r[99]
    # PSET: ctl_aper (control de aperturas a calcular)
    int n_aper, aper_list[99]
    string remaining
    int sp_pos
    real tmp_rp
    string expr, expre1, expre2, ellip_expr
    int xlenght_data, ylenght_data

    # PSET: datapar
    string pathname_data
    # PSET: photmetry
    real pixel_scale
    # PSET sexpar
    string key_run_se
    # PSET psfex
    string key_run_psf
    bool defaultf_psf, same_img_psf
    string img_name_psf

    # list of objects:
    int n_list
    string id_obj[999]
    int  seg_number[999]
    real fit_ra_j00[999], fit_dec_j00[999]
    real fit_xc, fit_yc
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999]
    real iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # list of position to rotating images:
    string center_rot_list
    string tmp_id_obj
    real ra_rot[999], dec_rot[999]
    int x0_rot[999], y0_rot[999]

    # nombre de imagenes:
    string observed_img
    string bgrms_img
    string mod_img
    string residual_img

    # recorte de imagenes:
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    int bulge_area[999]
    real local_rms
    # forzar medida:
    string force_obj
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force
    # imagenes recortadas:
    string obs_area, area_glxy_img

    # carpetas prinicpales:
    string alpha_dir, cache_dir
    string alphaimg_dir, area_dir, asymm_area_dir, frames_dir
    string alphafiles_dir, ds9_dir, residual_alpha_dir, rotation_alpha_dir
    string pawlik_dir

    # otras carpetas:
    string datafiles_dir
    string folder_sky
    string outsex_dir

    # direcciones de imagenes:
    string observed_dir, bckgrnd_dir, segmen_dir
    string model_dir, residual_dir

    # calculo de indices:
    string totalarea_mask
    string skypatch_img
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
    real n_ttl_cum
    real delta_area, delta_area_cum
    real cum_n_areattl[999]
    real prfl_index_alpha, cum_index_alpha
    # Experimental stuff
    real num_prfl_index, den_prfl_index
    real delta_corr_prfl

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_infile3, tmp_outfile

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    bckgrnd_dir  = "data/data_images/background"
    segmen_dir   = "data/data_images/segmentation"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"
    pawlik_dir   = "pawlik"

    # Para correr este codigo (indice alpha) es necesario ejecutar antes el indice pawlik
    list = outsex_dir//"/"//"params_to_index.txt"
    i = 0
    while(fscan(list, line) != EOF){
        if(i==2){break}
        if(line !="" && substr(line,1,1)!="#"){
            print(line) | scan(tmp_id_obj)
            i += 1
        }
    }
    list = ""
    # Para correr este codigo (indice alpha) es necesario ejecutar antes el indice pawlik
    tmp_infile  = pawlik_dir//"/pawlik_1.0/binary_masks/"//tmp_id_obj//"_binarymask.fits"
    tmp_infile2 = pawlik_dir//"/pawlik_1.0/binary_masks/"//tmp_id_obj//"_avoidmask.fits"
    if(!imaccess(tmp_infile) && !imaccess(tmp_infile2)){
        print("\n - Attempting to access the images folder: ./pawlik/pawlik_1.0/)")
        print(" - Running pawlik index first is mandatory!")
        print(" Escaping of the task...\n")
        beep
        bye
    }
    # Para correr este codigo (indice alpha) es necesario ejecutar antes el indice pawlik

    # KEY_WORD requeridas para ejecutar programas
    list = "data/data_files/full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # DATAPAR PSET -----------------------------------------------------------

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            # PHOTOMETRY PSET ---------------------------------------------------------

            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pixel_scale)}

            # SEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_SE"){print(line) | scan(key_word, key_run_se)}

            # PSFEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_PSFEX"){print(line) | scan(key_word, key_run_psf)}

            if(key_word == "DFLT_PSF"){print(line) | scan(key_word, defaultf_psf)}

            if(key_word == "SAME_IMG"){print(line) | scan(key_word, same_img_psf)}

            if(key_word == "IMG_NAME"){print(line) | scan(key_word, img_name_psf)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

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

    if(res_filter == yes){
        alpha_dir = alpha_dir//"_boxcar"
    }

    if(shape_in == yes){
        alpha_dir = alpha_dir//"_inshape"
    }else{
        alpha_dir = alpha_dir//"_allseg"
    }

    # Folders alpha:
    alphaimg_dir   = alpha_dir//"/"//"images"
    frames_dir     = alphaimg_dir//"/"//"small_frames"
    area_dir       = alphaimg_dir//"/"//"area_pixels"
    asymm_area_dir = alphaimg_dir//"/"//"asymm_area_pixels"

    # Catalogs:
    alphafiles_dir = alpha_dir//"/"//"files"
    ds9_dir = alphafiles_dir//"/"//"ds9_regions"
    residual_alpha_dir = alphafiles_dir//"/"//"residual_area"
    rotation_alpha_dir = alphafiles_dir//"/"//"residual_rotation_area"

    cache_dir = alpha_dir//"/"//"cache"

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"
    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    print(" ------------------------------------------")
    print(" ============== ALPHA INDEX ===============")
    print(" ============== CALCULATION ===============")

    # ==================================================
    # Leer lista de parametros de los SEx-modelos:
    # ==================================================

    # listas heredadas exactamente de 'find_objs' task:
    tmp_infile = outsex_dir//"/"//"params_to_index.txt"
    # No existe archivo de entrada esperado:
    if(!access(tmp_infile)){
        print("\n ERR(fatal): mandatory that it exist:")
        print(" - ", tmp_infile)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        bye
    }

    list = outsex_dir//"/"//"params_to_index.txt"
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(id_obj[i], seg_number[i], fit_ra_j00[i], fit_dec_j00[i], fit_xc, fit_yc, a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], petro_r[i], iso_areaf[i], ri_ann[i], ro_ann[i], xlen_min[i], ylen_min[i])

            # Correcciones:
            # petro_r[] ya fue corregido en 'glxy_model' task.
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[i] = theta_img[i] * const_pi / 180

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
        bye
    }

    # No existe archivo de entrada esperado:
    if(!access(center_rot_list)){
        print("\n ERR(fatal): mandatory that it exist:")
        print(" - ", center_rot_list)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        bye
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
                bye
            }

        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""

    # ===============================================================
    # Recortar imagenes para realizar medida
    # ===============================================================

    print("\n ------------ Cutting images --------------\n")
    if(!access(alpha_dir)){mkdir(alpha_dir)}
    if(!access(alphaimg_dir)){mkdir(alphaimg_dir)}
    if(!access(area_dir)){mkdir(area_dir)}
    if(!access(asymm_area_dir)){mkdir(asymm_area_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}

    # ================================================
    # CTL_APER: resolver que aperturas (indices de scale_r[]) se calculan.
    # 'all' -> las 36 aperturas originales [1..36], tal como antes; si no,
    # se interpreta 'ctl_aper' como una lista de radios petrosianos (Rp)
    # separados por espacio (p.ej. "1 1.5 2") y se aproxima cada uno al
    # indice entero mas cercano en scale_r[] (Rp = scale_r_offset +
    # scale_r_step*(idx-1) => idx = ((Rp-scale_r_offset)/scale_r_step)+1).
    # ================================================
    if(strlwr(ctl_aper) == "all"){
        n_aper = 36
        for(count=1; count<=36; count+=1){
            aper_list[count] = count
        }
    }else{
        # Tokeniza 'ctl_aper' (separado por espacios) sin invocar shell:
        remaining = ctl_aper
        n_aper = 0

        while(remaining != ""){

            # Recortar espacios iniciales:
            while(remaining != "" && substr(remaining,1,1) == " "){
                remaining = substr(remaining, 2, 200)
            }

            if(remaining != ""){
                sp_pos = stridx(" ", remaining)

                if(sp_pos == 0){
                    tmp_rp = real(remaining)
                    remaining = ""
                }else{
                    tmp_rp = real(substr(remaining, 1, sp_pos-1))
                    remaining = substr(remaining, sp_pos+1, 200)
                }

                n_aper += 1
                aper_list[n_aper] = int(((tmp_rp - scale_r_offset) / scale_r_step) + 1 + 0.5)
            }
        }
    }


    # name of image observed area without bulge:
    if(strlwr(bulge_clip) == "off"){
        printf("_obs_area_%.1f_nn", low_sigma) | scan(obs_area)
    }else{
        printf("_obs_area_%.1f_%.1f", low_sigma, hiblg_clip) | scan(obs_area)
    }

    # Encabezado archivo: trimsection_mincenter.txt
    printf("#%31s %20s", "ID", "trimsection\n", > datafiles_dir//"/trimsection_mincenter.txt")

    for(i=1;i<=n_list;i+=1){

        force_obj = "force_reg/force_"//id_obj[i]//".reg"
        if(access(force_obj) && force == yes){

            # extraer nuevos parametros de medida:
            expr = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
            print("\n  - Object to force measure: ", id_obj[i])
            printf(expr, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

            # SEGUIMIENTO:
            #print("\n Viejos parametros: ", a_img[i], b_img[i], theta_img[i])

            # Nuevos parametros:
            a_img[i] = a_int / (2.0 * petro_r[i])
            b_img[i] = b_int / (2.0 * petro_r[i])
            theta_img[i] = ell_angle
            theta_rad[i] = theta_img[i] * const_pi / 180

            # SEGUIMIENTO:
            # print("# ID A_IMG B_IMG THETA_IMG", > "data"//"/"//id_obj[i]//"_force_params.txt")
            # print(id_obj[i], " ", a_img[i], " ", b_img[i], " ", theta_img[i], >> "data"//"/"//id_obj[i]//"_force_params.txt")
            # SEGUIMIENTO:
            #print("\n Nuevos parametros: ", a_img[i], b_img[i], theta_img[i], petro_r[i])

            # Elipse exterior para extraer cielo:
            tmp_real = (((a_ext / (a_img[i] * petro_r[i])) - scale_r_offset) / scale_r_step) + 1
            ro_ann_force = int(tmp_real)
            # Asegurar entero proximo mas grande:
            if((tmp_real - ro_ann_force) >= 0.5){ro_ann_force += 1}
            # Actualizar nuevo parametro:
            ro_ann[i] = ro_ann_force
            # # La elipse interior para extraer el cielo,
            # # por definicion se toma como (1.7 r/rp):
            # ri_ann[i] = 30
            # ---------- MODIFICACIÓN (SAT.23/05/26):
            # Elipse exterior para extraer cielo:
            tmp_real = (((a_int / (a_img[i] * petro_r[i])) - scale_r_offset) / scale_r_step) + 1
            ri_ann_force = int(tmp_real)
            # Asegurar entero proximo mas grande:
            if((tmp_real - ri_ann_force) >= 0.5){ri_ann_force += 1}
            # Actualizar nuevo parametro:
            ri_ann[i] = ri_ann_force + scale_r_step

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

            # A_outer = scale_r[56] * petro_r[i] * a_img[i] + 10
            # B_outer = scale_r[56] * petro_r[i] * b_img[i] + 10
            # xlen_min[i] = 2 * sqrt((A_outer * cos(theta_rad[i]))**2 + (B_outer * sin(theta_rad[i]))**2)
            # ylen_min[i] = 2 * sqrt((A_outer * sin(theta_rad[i]))**2 + (B_outer * cos(theta_rad[i]))**2)
            # # asegurar len_min entero impar:
            # if(xlen_min[i] % 2 == 0){xlen_min[i] = xlen_min[i] + 1}
            # if(ylen_min[i] % 2 == 0){ylen_min[i] = ylen_min[i] + 1}
        }

        # Recortar la imagen alrededor del centro temporal:
        # Vertices
        px1 = x0_rot[i] - int((xlen_min[i] - 1) / 2)
        px2 = x0_rot[i] + int((xlen_min[i] - 1) / 2)
        py1 = y0_rot[i] - int((ylen_min[i] - 1) / 2)
        py2 = y0_rot[i] + int((ylen_min[i] - 1) / 2)

        tmp_infile = observed_dir//"/"//id_obj[i]//"_obs_secondmask.fits"

        imgets(tmp_infile, "naxis1")
        xlenght_data = int(imgets.value)
        imgets(tmp_infile, "naxis2")
        ylenght_data = int(imgets.value)

        if(px1 < 1){
            printf("\n - %d / %s: supera límites de recorte \n", i, id_obj[i])
            print(" - se usa min x1")
            px1 = 1
        }
        if(py1 < 1){
            printf("\n - %d / %s: supera límites de recorte \n", i, id_obj[i])
            print(" - se usa min y1")
            py1 = 1
        }
        if(px2 > xlenght_data){
            printf("\n - %d / %s: supera límites de recorte \n", i, id_obj[i])
            print(" - se usa max x2")
            px2 = xlenght_data
        }
        if(py2 > ylenght_data){
            printf("\n - %d / %s: supera límites de recorte \n", i, id_obj[i])
            print(" - se usa max y2")
            py2 = ylenght_data
        }

        # Seccion a recortar:
        trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"
        printf("%32s %20s\n", id_obj[i], trimsection, >> datafiles_dir//"/trimsection_mincenter.txt")

        # IMAGENES DATA: -----------------------------------------------------------------------------
        # BGRMS (check-image SEx):
        bgrms_img = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
        if(!imaccess(bgrms_img)){print("\n ERR: not access to bgrms img!"); bye}
        # OJO: esta imagen no se recorta (trimsection) porque de ella se extrae un solo número
        #      que requiere todo el recorte!
        # Capturar el punto medio del mapa BGRMS (check-image) "=" rms del recorte
        imstat(bgrms_img, fields="midpt", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(local_rms)

        # OBSERVED SECODNMASK (IMEDIT PROCESS):
        observed_img = observed_dir//"/"//id_obj[i]//"_obs_secondmask.fits"
        if(!imaccess(observed_img)){print("\n ERR: not access to obs_setmask img!"); bye}
        observed_img = observed_dir//"/"//id_obj[i]//"_obs_secondmask.fits"//trimsection
        # MODEL (check-image SEx):
        mod_img = model_dir//"/"//id_obj[i]//"_mod.fits"
        if(!imaccess(mod_img)){print("\n ERR: not access to setmask model img!"); bye}
        mod_img = model_dir//"/"//id_obj[i]//"_mod.fits"//trimsection
        # RESIDUAL (check-image SEx):
        residual_img = residual_dir//"/"//id_obj[i]//"_res.fits"
        if(!imaccess(residual_img)){print("\n ERR: not access to residual setmask img!"); bye}
        residual_img = residual_dir//"/"//id_obj[i]//"_res.fits"//trimsection
        # --------------------------------------------------------------------------------------------

        # B-2.3 --------------------------------------------------------------------------------------------------
        # Definir el área total de la galaxia donde se realizará la medida:
        if(shape_in==yes){
            # Área total: segmentacion de pawlik/pawlik_1.0/*_avoidmask.fits
            tmp_infile = pawlik_dir//"/pawlik_1.0/binary_masks/"//id_obj[i]//"_avoidmask.fits"//trimsection
        }else{
            # Área total: segmentacion de pawlik/pawlik_1.0/*_binarymask.fits
            tmp_infile = pawlik_dir//"/pawlik_1.0/binary_masks/"//id_obj[i]//"_binarymask.fits"//trimsection
        }
        # Crear la mascara de area total (mascara - bulbo):
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_totalarea_mask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a <= b*c) ? d : 0", tmp_outfile, mod_img, hiblg_clip, local_rms, tmp_infile, ver-)
        # La suma de pixeles es el denominador del indice (totalarea_mask):
        imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        cum_n_areattl[i] = int(mean_val * n_pix)
        # Definir mascara total:
        totalarea_mask = tmp_outfile
        # B-2.3 --------------------------------------------------------------------------------------------------

        # La elección del bulbo es aún ambigua. No está excenta de incluir otros picos. Se espera que la imagen
        # observada y el modelo contengan un único bulbo.

        # B-2.4 --------------------------------------------------------------------------------------------------
        # Área del bulbo a evitar (ya se tuvo en cuenta implicitamente en B-2.3.):
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a >= b*c) && (d == 1) ? 1 : 0", tmp_outfile, mod_img, hiblg_clip, local_rms, totalarea_mask, ver-)
        # Suma del área del bulbo (pixeles):
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        bulge_area[i] = int(mean_val * n_pix)
        # B-2.4 --------------------------------------------------------------------------------------------------

        # B-2.5 --------------------------------------------------------------------------------------------------
        # Filtrado (?) de la imagen residual:
        if(res_filter == yes){
            tmp_infile = cache_dir//"/"//id_obj[i]//"_res_boxcar.fits"
            imdelete(tmp_infile, ver-, >& "dev$null")
            boxcar(input = residual_img, output = tmp_infile, xwindow = 3, ywindow = 3, boundary = "nearest")
        }else{
            tmp_infile = residual_img
        }
        # B-2.5 --------------------------------------------------------------------------------------------------

        # B-2.6 --------------------------------------------------------------------------------------------------
        # Levantamiento de los pixeles del residuo superiores a 'low_sigma'
        # Originalmente (V+17) llamados 'píxeles asimétricos'. Pero ojo, son
        # realmente PSEUDO-asimétricos! Pues su nombre se debe a que son es-
        # tructuras residuales a un modelo simétrico, no a una comparación de
        # rotación axial. Al índice (alpha) medido de estos lo llamamos
        # 'old-alpha'. Tambien calculamos el (nuevo-) alpha sustrayendo por
        # la rotación de 180º (mas adelante).
        tmp_outfile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a >= b*c) && (a <= d*c) ? 1 : 0", tmp_outfile, tmp_infile, low_sigma, local_rms, hidsk_clip, verb-)
        # Ahora si calculamos 'pixeles asimétricos' por rotacion (sustracción):
        # Rotacion de 180º (transposicion dos veces):
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
        # sustracción |N_areapix - N_areapix^(180º)|:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        tmp_infile2 = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a-b) > 0", tmp_outfile, tmp_infile, tmp_infile2, verb-)
        # eliminar imagen de 180°:
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels_rot180.fits"
        imdelete(tmp_infile, ver-, >& "dev$null")
        # B-2.6 --------------------------------------------------------------------------------------------------

        # B-2.7 --------------------------------------------------------------------------------------------------
        # Generar imagen con pixeles residuales dentro del area total (totalarea_mask)
        tmp_outfile = area_dir//"/"//id_obj[i]//"_respix_inareamask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        tmp_infile = area_dir//"/"//id_obj[i]//"_areapixels.fits"
        imexpr("(a == 1) ? b : 0", tmp_outfile, totalarea_mask, tmp_infile, ver-)
        # Generar imagen con pixeles asimetricos dentro del area total (totalarea_mask)
        tmp_outfile = asymm_area_dir//"/"//id_obj[i]//"_asymmpix_inareamask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        tmp_infile = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
        imexpr("(a == 1) ? b : 0", tmp_outfile, totalarea_mask, tmp_infile, ver-)
        # B-2.7 --------------------------------------------------------------------------------------------------

        # Progress bar proccess:
        printf("\r - Process (cutting images): %d%%", (i*100/n_list))
    }

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================

    if(!access(alphafiles_dir)){mkdir(alphafiles_dir)}
    if(!access(residual_alpha_dir)){mkdir(residual_alpha_dir)}
    if(!access(rotation_alpha_dir)){mkdir(rotation_alpha_dir)}
    if(!access(ds9_dir)){mkdir(ds9_dir)}

    for(count=1;count<=n_aper;count+=1){

        i = aper_list[count]

        # Prefijo (columna ID_OBJ, etc.): solo en la primer apertura de la lista.
        if(count == 1){

            # I.      %ID  %fr %Nt (I. N asymm. pixels SET: prefijo)
            printf("#%31s %6s %6s", "ID_OBJ", "3/rp", "Nttl", > residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II.      %ID  %Nb %db %fr %Nt (II. Noise pixels SET: prefijo)
            printf("#%31s %6s %7s %6s %6s", "ID_OBJ", "Nbg", "rho_bg", "3/rp", "Nttl", > residual_alpha_dir//"/"//"noisepix_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: prefijo
            printf("#%31s", "ID_OBJ", > residual_alpha_dir//"/"//"cum_index_set.cat")

            # COMPACT: prefijo con posicion del objeto (ID_OBJ + coordenadas):
            # printf("#%31s %11s %11s %11s %11s", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > residual_alpha_dir//"/"//"prfl_main_alpha.cat")
            printf("#%31s %11s %11s %11s %11s", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > residual_alpha_dir//"/"//"cum_main_alpha.cat")

        }

        # Etiqueta de columna de ESTA apertura: en cada iteracion, con o sin
        # salto de linea segun sea la ultima apertura seleccionada o no
        # (independiente de 'count==1', para que ambas ramas se ejecuten
        # cuando solo hay una apertura seleccionada, n_aper==1):
        if(count == n_aper){

            #  I.     %Nasymm_last (I. N asymm. pixels SET: last)
            printf(" N_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II. Noise pixel SET: last
            printf(" d_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"noisepix_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: last
            printf(" alpha_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"cum_index_set.cat")

            # COMPACT: ultima columna, con salto de linea:
            # printf(" prfl_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"prfl_main_alpha.cat")
            printf(" alpha_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"cum_main_alpha.cat")

        }else{
            # I.     %Nasymm_i (All parameters catalog:)
            printf(" N_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"asymmpix_set.cat")

            # II. Noise pixel SET: mid
            printf(" d_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"noisepix_set.cat")

            # IV. CUMULATIVE Asymmetry area SET: mid
            printf(" alpha_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"cum_index_set.cat")

            # COMPACT: columna intermedia, sin salto de linea:
            # printf(" prfl_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"prfl_main_alpha.cat")
            printf(" alpha_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"cum_main_alpha.cat")

        }

        # # EXPERIMENTAL ---------------------------
        # if(i%2==0 && i<36){
        #     if(i==2){
        #         printf("#%31s prfl_%4.2frp", "ID_OBJ", scale_r[i], > residual_alpha_dir//"/"//"prfl_index_set.cat")
        #     }else if(i>2){
        #         printf(" prfl_%4.2frp", scale_r[i], >> residual_alpha_dir//"/"//"prfl_index_set.cat")
        #     }
        # }else if(i==36){
        #     printf(" prfl_%4.2frp\n", scale_r[i], >> residual_alpha_dir//"/"//"prfl_index_set.cat")
        # }
        # # END EXPERIME ...........................


    # END FOR: header catalogs
    }

    # ROTATED ALPHA INDEX USE THE SAME HEADER:
    delete(rotation_alpha_dir//"/"//"rot_asymmpix_set.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_noisepix_set.cat", >& "dev$null")
    # delete(rotation_alpha_dir//"/"//"rot_prfl_index_set.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_cum_index_set.cat", >& "dev$null")
    # delete(rotation_alpha_dir//"/"//"rot_prfl_main_alpha.cat", >& "dev$null")
    delete(rotation_alpha_dir//"/"//"rot_cum_main_alpha.cat", >& "dev$null")
    copy(residual_alpha_dir//"/"//"asymmpix_set.cat", rotation_alpha_dir//"/"//"rot_asymmpix_set.cat")
    copy(residual_alpha_dir//"/"//"noisepix_set.cat", rotation_alpha_dir//"/"//"rot_noisepix_set.cat")
    # copy(residual_alpha_dir//"/"//"prfl_index_set.cat", rotation_alpha_dir//"/"//"rot_prfl_index_set.cat")
    copy(residual_alpha_dir//"/"//"cum_index_set.cat", rotation_alpha_dir//"/"//"rot_cum_index_set.cat")
    # copy(residual_alpha_dir//"/"//"prfl_main_alpha.cat", rotation_alpha_dir//"/"//"rot_prfl_main_alpha.cat")
    copy(residual_alpha_dir//"/"//"cum_main_alpha.cat", rotation_alpha_dir//"/"//"rot_cum_main_alpha.cat")

    # DENSITY NOISE CATALOG:
    printf("#%31s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n", "ID_OBJ", "min_rho", "ttl_rho", "A1_ann", "N1_ann", "rho1", "A2_ann", "N2_ann", "rho2", "A3_ann", "N3_ann", "rho3", "A4_ann", "N4_ann", "rho4", > residual_alpha_dir//"/"//"patch_bg_set.cat")
    # The same header for residual rotated area:
    delete(rotation_alpha_dir//"/"//"rot_patch_bg_set.cat",  >& "dev$null")
    copy(residual_alpha_dir//"/"//"patch_bg_set.cat", rotation_alpha_dir//"/"//"rot_patch_bg_set.cat")

    # DS9 HEADER ACATALOG INDEX VALUE (CUMMULATIVE CURVE):
    delete(ds9_dir//"/"//"alpha_index.reg",  >& "dev$null")
    print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"alpha_index.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"alpha_index.reg")
    print("fk5", >> ds9_dir//"/"//"alpha_index.reg")

    copy(ds9_dir//"/"//"alpha_index.reg", ds9_dir//"/"//"rot_alpha_index.reg")

    # ===============================================================
    # ALPHA INDEX COMPUTATION
    # ===============================================================
    print("\n\n --------- Computing alpha index ----------\n")

    # both_alpha=yes -> corre old(k=1) + rotational(k=2); both_alpha=no -> solo rotational(k=2):
    if(both_alpha == yes){
        k_start = 1
    }else{
        k_start = 2
    }

    for(k=k_start;k<=2;k+=1){

        for(i=1;i<=n_list;i+=1){

            # area_glxy_img = cache_dir//"/"//id_obj[i]//obs_area//".fits"

            # La primera ejecucion es para el indice de area residual:
            if(k==1){
                measure_area_img = area_dir//"/"//id_obj[i]//"_respix_inareamask.fits"
                # Imagen de donde toma el ruido de pixeles en area (esperado = 0)
                skypatch_img = area_dir//"/"//id_obj[i]//"_areapixels.fits"
                # Encabezado de archivos:
                out_cat = residual_alpha_dir//"/"
                out_ds9_cat = ds9_dir//"/"
            # la segunda ejecucion es para el indice rotacional de residuo de area:
            }else{

                measure_area_img = asymm_area_dir//"/"//id_obj[i]//"_asymmpix_inareamask.fits"
                # Imagen de donde toma el ruido de pixeles en area (esperado = 0)
                skypatch_img = asymm_area_dir//"/"//id_obj[i]//"_asymm_areapixels.fits"
                # Encabezado de archivos:
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
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", skypatch_img, cache_dir//"/"//"tmp_ann_1", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[1] = mean_val * n_pix
            # Noise density ann[1]
            density_noise[1] = n_noisepix[1] / area_ann[1]
            # Borrar imagen:
            imdelete(cache_dir//"/"//"tmp_ann_1", >& "dev$null")
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann1", >& "dev$null")

            # Annulus 2
            imdelete(cache_dir//"/"//"tmp_ann_2", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) <= (J-b) && (I-a) > -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_2", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 2
            imstat(cache_dir//"/"//"tmp_ann_2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[2] = mean_val * n_pix
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", skypatch_img, cache_dir//"/"//"tmp_ann_2", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[2] = mean_val * n_pix
            # Noise density ann[1]
            density_noise[2] = n_noisepix[2] / area_ann[2]
            # Borrar imagenes:
            imdelete(cache_dir//"/"//"tmp_ann_2", >& "dev$null")
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann2", >& "dev$null")

            # Annulus 3
            imdelete(cache_dir//"/"//"tmp_ann_3", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) < (J-b) && (I-a) <= -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_3", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 3
            imstat(cache_dir//"/"//"tmp_ann_3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[3] = mean_val * n_pix
            # Asymmetrical pixel counting ann[1]
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", skypatch_img, cache_dir//"/"//"tmp_ann_3", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[3] = mean_val * n_pix
            # Noise density ann[3]
            density_noise[3] = n_noisepix[3] / area_ann[3]
            # Borrar imagenes:
            imdelete(cache_dir//"/"//"tmp_ann_3", >& "dev$null")
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann3", >& "dev$null")

            # Annulus 4
            imdelete(cache_dir//"/"//"tmp_ann_4", >& "dev$null")
            imexpr(expre1//" && "//expre2//" && (I-a) >= (J-b) && (I-a) < -(J-b) ? 1 : 0", cache_dir//"/"//"tmp_ann_4", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], dims=str(xlen_min[i])//","//str(ylen_min[i]), verb-)
            # Area annulus 4
            imstat(cache_dir//"/"//"tmp_ann_4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            area_ann[4] = mean_val * n_pix
            # Asymmetrical pixel counting ann[1]
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", >& "dev$null")
            imexpr("a*b", cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", skypatch_img, cache_dir//"/"//"tmp_ann_4", verb-)
            imstat(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            n_noisepix[4] = mean_val * n_pix
            # Noise density ann[4]
            density_noise[4] = n_noisepix[4] / area_ann[4]
            # Borrar imagenes:
            imdelete(cache_dir//"/"//"tmp_ann_4", >& "dev$null")
            imdelete(cache_dir//"/"//id_obj[i]//"_tmp_bgpix_ann4", >& "dev$null")

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

            if(min_corr == yes){
                min_densitybg = (n_noisepix[min1_pos] + n_noisepix[min2_pos] + n_noisepix[min3_pos]) / (area_ann[min1_pos] + area_ann[min2_pos] + area_ann[min3_pos])
            }else{
                min_densitybg = ttl_rho
            }

            # Print catalog density noise -------------------------------------------------------------------
            printf("%32s %8.5f %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f %8.2f %8d %8.5f\n", id_obj[i], min_densitybg, ttl_rho, area_ann[1], n_noisepix[1], density_noise[1], area_ann[2], n_noisepix[2], density_noise[2], area_ann[3], n_noisepix[3], density_noise[3], area_ann[4], n_noisepix[4], density_noise[4], >> out_cat//"patch_bg_set.cat")

            # END: ESTIMACION DEL FONDO -----------------------------------------------------------

            if(k == 1){
                printf("\r - Residual Area index (old alpha): %d / %d", i, n_list)
            }else{
                printf("\r - Rotated Residual Area index....: %d / %d", i, n_list)
            }

            # Para ampliar la apertura de medida:
            for(count=1;count<=n_aper;count+=1){

                j = aper_list[count]

                # Asymmetrical pixel image in aperture scale_r[]
                imdelete(cache_dir//"/"//"tmp_asymmpix_ap", >& "dev$null")
                imexpr(expre1//" ? f : 0", cache_dir//"/"//"tmp_asymmpix_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], measure_area_img, verb-)
                # Suma de pixeles:
                imstat(cache_dir//"/"//"tmp_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                n_asymmpix = mean_val * n_pix

                #   # =========== START EXPERIMENTAL STUFF PROFILE INDEX =====================
                #   # Asymmetrical pixel image in annullus aperture scale_r[]
                #   if(j % 2 == 0 && j < 36){
                #
                #       if(j==2){
                #
                #           # # NUMERATOR PROFILE:
                #           num_prfl_index = n_asymmpix
                #
                #           # DENOMINATOR PROFILE:
                #           imdelete(cache_dir//"/"//"tmp_ann_areattl", >& "dev$null")
                #           imexpr(expre1//" ? f : 0", cache_dir//"/"//"tmp_ann_areattl", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], area_glxy_img, verb-)
                #           # Area galaxy counting:
                #           imstat(cache_dir//"/"//"tmp_ann_areattl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #           den_prfl_index = mean_val * n_pix
                #
                #           # AREA CORRECCION:
                #           delta_corr_prfl = const_pi * (scale_r[j] * petro_r[i])**2 * (a_img[i] * b_img[i])
                #
                #       }else if(j > 2){
                #
                #           # NUMERATOR PROFILE:
                #           imdelete(cache_dir//"/"//"tmp_ann_asymmpix_ap", >& "dev$null")
                #           expr = expre1//" && "//expre2//" ? h : 0"
                #           imexpr(expr, cache_dir//"/"//"tmp_ann_asymmpix_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-2] * petro_r[i] * a_img[i], scale_r[j-2] * petro_r[i] * b_img[i], measure_area_img, verb-)
                #           # Residual Area (rotated) pixels counting:
                #           imstat(cache_dir//"/"//"tmp_ann_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #           num_prfl_index = mean_val * n_pix
                #
                #           # DENOMINATOR PROFILE:
                #           imdelete(cache_dir//"/"//"tmp_ann_areattl", >& "dev$null")
                #           expr = expre1//" && "//expre2//" ? h : 0"
                #           imexpr(expr, cache_dir//"/"//"tmp_ann_areattl", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-2] * petro_r[i] * a_img[i], scale_r[j-2] * petro_r[i] * b_img[i], area_glxy_img, verb-)
                #           # Area galaxy counting:
                #           imstat(cache_dir//"/"//"tmp_ann_areattl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #           den_prfl_index = mean_val * n_pix
                #
                #           # AREA CORRECCION:
                #           delta_corr_prfl = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[j]**2) - (scale_r[j-2]**2))
                #
                #       }
                #
                #   }else if(j == 36){
                #
                #       # NUMERATOR PROFILE:
                #       imdelete(cache_dir//"/"//"tmp_ann_asymmpix_ap", >& "dev$null")
                #       expr = expre1//" && "//expre2//" ? h : 0"
                #       imexpr(expr, cache_dir//"/"//"tmp_ann_asymmpix_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-2] * petro_r[i] * a_img[i], scale_r[j-2] * petro_r[i] * b_img[i], measure_area_img, verb-)
                #       # Residual Area (rotated) pixels counting:
                #       imstat(cache_dir//"/"//"tmp_ann_asymmpix_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #       num_prfl_index = mean_val * n_pix
                #
                #       # DENOMINATOR PROFILE:
                #       imdelete(cache_dir//"/"//"tmp_ann_areattl", >& "dev$null")
                #       expr = expre1//" && "//expre2//" ? h : 0"
                #       imexpr(expr, cache_dir//"/"//"tmp_ann_areattl", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-2] * petro_r[i] * a_img[i], scale_r[j-2] * petro_r[i] * b_img[i], area_glxy_img, verb-)
                #       # Area galaxy counting:
                #       imstat(cache_dir//"/"//"tmp_ann_areattl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #       den_prfl_index = mean_val * n_pix
                #
                #       # AREA CORRECCION:
                #       delta_corr_prfl = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[j]**2) - (scale_r[j-2]**2))
                #
                #   }
                #   # =========== END EXPERIMENTAL STUFF PROFILE INDEX =====================

                #  # aper. Total pixels (N_tot) alpha = n_asymmpix / N_tot(in aperture)
                #  imdelete(cache_dir//"/"//"tmp_areattl_ap", >& "dev$null")
                #  imexpr(expre1//" ? f : 0", cache_dir//"/"//"tmp_areattl_ap", real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], area_glxy_img, verb-)
                #  # Area galaxy counting:
                #  imstat(cache_dir//"/"//"tmp_areattl_ap", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                #  ap_n_areattl = mean_val * n_pix

                # ECUACION DEL INDICE ALPHA: ==========================================

                # Denominador del indice alpha (calculado en recrte de imagenes)
                # es igual a "totalarea_mask - bulge_area":
                n_ttl_cum = cum_n_areattl[i]

                #   # Si utiliza '<= 3.0' asegurese de que las lineas despues de '##estas#' esten comentadas:
                #   # Si utiliza '<= 0.0' entonces descomente las lineas despues de '##estas#'
                #   if(scale_r[j] * petro_r[i] <= 3.0){
                #
                #       delta_area = 0
                #
                #       #   # ---- ESTA SECCION ERA ANTIGUO PROFILE INDICE DE PERFIL ACUMULATIVO, NO POR ANILLOS --------
                #       #   if(ap_n_areattl <= 0){
                #       #       prfl_index_alpha = 0
                #       #   }else{
                #       #       prfl_index_alpha = n_asymmpix / ap_n_areattl
                #       #   }
                #       #   # --------------------------------------------------------------------------------------------
                #
                #       cum_index_alpha = n_asymmpix / n_ttl_cum
                #   }else{
                #
                #       # *** ESTAS LINEAS NO SE BORRAN, SON CONDICIONES DE CALCULO ********************
                #       # delta_area = const_pi * (a_img[i] * b_img[i]) * ((scale_r[j] * petro_r[i])**2) - bulge_area[i]
                #       #
                #       # if(delta_area <= 0){ delta_area = 0 }
                #       # ******************************************************************************
                #
                #       # Comentar la siguiente linea SI Y SOLO SI las lineas que preceden a '##estas#' fueron descomentadas:
                #       delta_area = const_pi * (a_img[i] * b_img[i]) * ((scale_r[j] * petro_r[i])**2 - 9.0)
                #
                #       #   # ---- ESTA SECCION ERA ANTIGUO PROFILE INDICE DE PERFIL ACUMULATIVO, NO POR ANILLOS --------
                #       #   if(ap_n_areattl <= 0){
                #       #       prfl_index_alpha = 0
                #       #   }else{
                #       #       prfl_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / (ap_n_areattl - (delta_area * min_densitybg))
                #       #   }
                #       #   # --------------------------------------------------------------------------------------------
                #
                #       cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / n_ttl_cum
                #   }

                delta_area = const_pi * (a_img[i] * b_img[i]) * ((scale_r[j] * petro_r[i])**2 - bulge_area[i])
                if(delta_area <= 0){ delta_area = 0 }
                cum_index_alpha = (n_asymmpix - (delta_area * min_densitybg)) / n_ttl_cum

                #   # ======== START EXPERIMENTAL STUFF PROFILE INDEX ==========================================
                #   if(j%2==0){
                #
                #       if(scale_r[j] * petro_r[i] <= 3.0){
                #           if(den_prfl_index <= 0){
                #               prfl_index_alpha = 0
                #           }else{
                #               prfl_index_alpha = num_prfl_index / (den_prfl_index - (delta_corr_prfl * min_densitybg))
                #           }
                #       }else{
                #           if(den_prfl_index <= 0){
                #               prfl_index_alpha = 0
                #           }else{
                #               prfl_index_alpha = (num_prfl_index - (delta_corr_prfl * min_densitybg)) / (den_prfl_index - (delta_corr_prfl * min_densitybg))
                #           }
                #       }
                #   }
                #
                #   if(prfl_index_alpha < 0){
                #       prfl_index_alpha = 0
                #   }
                #   # ======== END EXPERIMENTAL STUFF PROFILE INDEX ==========================================

                # ====================================================================================
                # PRINT CATALOGS
                # ====================================================================================

                # Prefijo (ID_OBJ y columnas fijas): solo en la primer apertura de la lista.
                if(count == 1){
                    #       %ID  %fcor %Nt (# I. Asymmetrical pixel SET: prefijo)
                    printf("%32s %6.3f %6d", id_obj[i], (3/petro_r[i]), n_ttl_cum, >> out_cat//"asymmpix_set.cat")

                    #       %ID  %Nb %db   %fr   %Nt (II. Noise pixel SET: prefijo)
                    printf("%32s %6d %7.4f %6.3f %6d", id_obj[i], nbg_noisepix, min_densitybg, (3/petro_r[i]), n_ttl_cum, >> out_cat//"noisepix_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: prefijo
                    printf("%32s", id_obj[i], >> out_cat//"cum_index_set.cat")
                }

                # Valor de ESTA apertura: en cada iteracion, con o sin salto de
                # linea segun sea la ultima seleccionada o no (independiente de
                # 'count==1', para que ambas ramas corran si n_aper==1):
                if(count == n_aper){

                    # I. Asymmetrical pixel SET: last
                    printf(" %8d\n", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    # II. Noise pixel SET: last
                    printf(" %8.2f\n", delta_area, >> out_cat//"noisepix_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: last
                    printf(" %12.4f\n", cum_index_alpha, >> out_cat//"cum_index_set.cat")

                }else{

                    # I. Asymetrical pixel SET: mid
                    printf(" %8d", n_asymmpix, >> out_cat//"asymmpix_set.cat")

                    # II. Noise pixel SET: mid
                    printf(" %8.2f", delta_area, >> out_cat//"noisepix_set.cat")

                    # IV. CUMULATIVE Asymmetry area SET: mid
                    printf(" %12.4f", cum_index_alpha, >> out_cat//"cum_index_set.cat")
                }

                #   # EXPERIMENTAL ---------------------------
                #   if(j%2==0 && j<36){
                #       if(j==2){
                #           printf("%32s %11.4f", id_obj[i], prfl_index_alpha, >> out_cat//"prfl_index_set.cat")
                #       }else if(j>2){
                #           printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")
                #       }
                #   }else if(j==36){
                #       printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_index_set.cat")
                #   }
                #   # END EXPERIME ...........................

                # ====================================================================================
                # PRINT CATALOGS: main_alpha (ID_OBJ + coordenadas + una columna por apertura)
                # ====================================================================================

                # Prefijo (ID_OBJ + coordenadas): solo en la primer apertura de la lista.
                if(count == 1){
                    # printf("%32s %11.4f %11.4f %11.8f %11.8f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], >> out_cat//"prfl_main_alpha.cat")

                    printf("%32s %11.4f %11.4f %11.8f %11.8f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], >> out_cat//"cum_main_alpha.cat")
                }

                # Valor de ESTA apertura (con o sin salto de linea segun sea la ultima o no,
                # independiente de 'count==1' para que ambas ramas corran si n_aper==1):
                if(count == n_aper){
                    # printf(" %11.4f\n", prfl_index_alpha, >> out_cat//"prfl_main_alpha.cat")

                    printf(" %12.4f\n", cum_index_alpha, >> out_cat//"cum_main_alpha.cat")
                }else{
                    # printf(" %11.4f", prfl_index_alpha, >> out_cat//"prfl_main_alpha.cat")

                    printf(" %12.4f", cum_index_alpha, >> out_cat//"cum_main_alpha.cat")
                }

                # ALPHA INDEX DS9 REGION: una elipse por cada apertura seleccionada:
                expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(scale_r[j] * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(scale_r[j] * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//' cum_'//str(scale_r[j])//'rp: '//str(cum_index_alpha)//'}'
                print(expr, >> out_ds9_cat//"alpha_index.reg")

                # END PRINT CATALOGS ===============================================================


            #END FOR (j): apertura de medida
            }

        # END FOR (i): lista de objetos
        }
        print("")
    # END FOR (k): indices alpha
    }

    print("\n ------------------------------------------")
    printf(" OUTPUT FOLDER: ./%s\n", alpha_dir)
    print(" END TASK: alpha_index")
    print(" ------------------------------------------")
    print("")

    flpr
end
