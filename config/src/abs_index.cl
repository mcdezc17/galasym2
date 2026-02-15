procedure abs_index()

string   center_rot = "abs"   {prompt = "'abs' or 'rms' minimization"}
bool     force      = yes      {prompt = "force measure with ds9 regions"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    string key_word
    real mean_val, n_pix
    # constants........
    real const_pi
    # patrameters......
    real scale_r_offset, scale_r_step
    real scale_r[99]
    string expr, expre1, expre2, ellip_expr

    # PSET: datapar
    string pathname_data
    # PSET: photmetry
    real pixel_scale

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



    # recorte de imagenes:
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    # forzar medida:
    string force_objs
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force

    # carpeta principal:
    string abs_dir, absimg_dir, cache_dir
    string frames_dir, residualimg_dir
    string files_dir, abscat_dir, ds9_dir
    # otras carpetas:
    string datafiles_dir
    string outsex_dir
    # direcciones de imagenes:
    string observed_dir

    # calculo de indices:
    real cum_flux_ttl[999]
    int f_ri, f_ro
    real denominator_cumm, numerator_corr
    real area_sky, numerator_aper
    real area_aper, denominator_prfl
    real area_prfl, numerator_prfl
    real abs_prfl_index, abs_cumm_index

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_outfile

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    abs_dir = "abs_index"
    cache_dir = abs_dir//"/"//"cache"
    # images:
    absimg_dir = abs_dir//"/"//"images"
    frames_dir = absimg_dir//"/"//"small_frames"
    residualimg_dir = absimg_dir//"/"//"abs_residual"
    # catalogs:
    files_dir = abs_dir//"/"//"catalogs"
    ds9_dir = files_dir//"/"//"ds9"
    abscat_dir = files_dir//"/"//"abs_index"
    # other:
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"

    # KEY_WORD requeridas para ejecutar programas
    list = "data/data_files/full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # DATAPAR PSET -----------------------------------------------------------

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            # PHOTOMETRY PSET ---------------------------------------------------------

            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pixel_scale)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    # ==================================================
    find_objs
    # ==================================================
    find_center
    # ==================================================

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25
    scale_r_step = 0.05

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (scale_r_step * (i-1))
    }

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"
    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    print(" ------------------------------------------")
    print(" =========== ABSOLUTE ROTATION ============")
    print(" ============ ASYMMETRY INDEX =============")

    print(" Classical  asymmetry  index,  known as A of")
    print(" CAS (Conselice et al., 2000). However, here")
    print(" it is  calculated as in (recently) Sazonova")
    print(" et. al. (2024).\n")

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
    # Salida de resultados:
    if(!access(abs_dir)){mkdir(abs_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}
    if(!access(absimg_dir)){mkdir(absimg_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(residualimg_dir)){mkdir(residualimg_dir)}

    for(i=1;i<=n_list;i+=1){

        force_obj = "force_"//id_obj[i]//".reg"
        if(access(force_obj) && force == yes){

            # extraer nuevos parametros de medida:
            expr = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
            print("\n  - Object to force measure: ", id_obj[i])
            printf(expr, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

            # Nuevos parametros:
            a_img[i] = a_int / (1.5 * petro_r[i])
            b_img[i] = b_int / (1.5 * petro_r[i])
            theta_img[i] = ell_angle
            theta_rad[i] = theta_img[i] * const_pi / 180

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

        # OBSERVED SET MASK:
        tmp_infile = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)

        # Apertura maxima para indice acumulativo:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_setmask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[30] * petro_r[i] * a_img[i], scale_r[30] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)

        # MINIMUM RESIDUAL (SET MASK) 180° rotation:
        # transposicion = rotar 90 grados:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"//"[*,-*]"
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_obs_setmask_rot90.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # repetir transposicion = 180°:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask_rot90.fits"//"[*,-*]"
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_obs_setmask_rot180.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # eliminar imagen a 90°:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask_rot90.fits"
        imdelete(tmp_infile, ver-, >& "dev$null")
        # Residuo asimetrico de area (N-N_180):
        tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
        tmp_infile2 = frames_dir//"/"//id_obj[i]//"_obs_setmask_rot180.fits"
        tmp_outfile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("abs(a-b)", tmp_outfile, tmp_infile, tmp_infile2, verb-)

        # Progress bar proccess:
        printf("\r - Process (cutting images): %d%%", (i*100/n_list))
    }

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================

    if(!access(files_dir)){mkdir(files_dir)}
    if(!access(abscat_dir)){mkdir(abscat_dir)}
    if(!access(ds9_dir)){mkdir(ds9_dir)}

    for(i=1;i<=30;i+=1){

        if(i == 1){

            # I.      %ID  %fr %Nt %Nasymm_1 (I. N asymm. pixels SET: first)
            printf("#%31s sumF_%4.2frp", "ID_OBJ", scale_r[i], > abscat_dir//"/"//"sum_flux_set.cat")

            # II. PROFILE Asymmetry area SET: first
            printf("#%31s prfl_%4.2frp", "ID_OBJ", scale_r[i], > abscat_dir//"/"//"prfl_index_set.cat")

            # III. CUMULATIVE Asymmetry area SET: first
            printf("#%31s cum_%4.2frp", "ID_OBJ", scale_r[i], > abscat_dir//"/"//"cum_index_set.cat")

        }else if(i == 30){

            #  I.     %Nasymm_last (I. N asymm. pixels SET: last)
            printf(" sumF_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"asymmpix_set.cat")

            # II. PROFILE Asymmetry area SET: first
            printf(" prfl_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"prfl_index_set.cat")

            # III. CUMULATIVE Asymmetry area SET: first
            printf(" cum_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"cum_index_set.cat")

        }else{
            # I.     %Nasymm_i (All parameters catalog:)
            printf(" sumF_%4.2frp", scale_r[i], >> abscat_dir//"/"//"asymmpix_set.cat")

            # II. PROFILE Asymmetry area SET: mid
            printf(" prfl_%4.2frp", scale_r[i], >> abscat_dir//"/"//"prfl_index_set.cat")

            # III. CUMULATIVE Asymmetry area SET: mid
            printf(" cum_%4.2frp", scale_r[i], >> abscat_dir//"/"//"cum_index_set.cat")

        }
    # END FOR: header catalogs
    }

    # COMPACT CATALOG ABS INDEX:
    # IV. (PROFILE CURVE)
    printf("#%31s %11s %11s %11s %11s prfl_1.0rp prfl_1.5rp prfl_1.7rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > abscat_dir//"/"//"prfl_index_main.cat")

    # V. (CUMMULATIVE CURVE)
    printf("#%31s %11s %11s %11s %11s cum_1.0rp cum_1.5rp cum_1.7rp\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > abscat_dir//"/"//"cum_index_main.cat")

    #   # DS9 HEADER ACATALOG INDEX VALUE (PROFILE CURVE):
    #   print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"prfl_index.reg")
    #   print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"prfl_index.reg")
    #   print("fk5", >> ds9_dir//"/"//"prfl_index.reg")
    #   # copy rotational
    #   delete(ds9_dir//"/"//"rot_prfl_index.reg",  >& "dev$null")
    #   copy(ds9_dir//"/"//"prfl_index.reg", ds9_dir//"/"//"rot_prfl_index.reg")

    #   # DS9 HEADER ACATALOG INDEX VALUE (CUMMULATIVE CURVE):
    #   delete(ds9_dir//"/"//"cum_index.reg",  >& "dev$null")
    #   print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"cum_index.reg")
    #   print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"cum_index.reg")
    #   print("fk5", >> ds9_dir//"/"//"cum_index.reg")
    #   # copy rotational
    #   delete(ds9_dir//"/"//"rot_cum_index.reg",  >& "dev$null")
    #   copy(ds9_dir//"/"//"cum_index.reg", ds9_dir//"/"//"rot_cum_index.reg")

    # ===============================================================
    # INDEX COMPUTATION
    # ===============================================================
    print("\n\n --------- Computing abs index ------------\n")

    for(i=1;i<=n_list;i+=1){

        # DENOMINADOR DEL INDICE CUMULATIVO (const.):
        tmp_infile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_setmask.fits"
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # denominador de indice cumulativo:
        denominator_cumm = mean_val * n_pix
        mean_val = 0
        n_pix = 0

        # ESTIMACION DEL FONDO -----------------------------------------------------------
        f_ri = ri_ann[i]
        f_ro = ro_ann[i]
        # Anillo eliptico del CIELO ASIMETRICO (blank patch)
        tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_blankpatch.fits"
        expr = expre1//" && "//expre2//" ? h : 0"
        imdelete(tmp_outfile, >& "dev$null")
        imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], tmp_infile, verb-)
        # numerador de la correccion de cielo:
        imstat(cache_dir//"/"//id_obj[i]//"_blankpatch.fits", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # numerador de sky correction:
        numerator_corr = mean_val * n_pix
        # area del anillo:
        area_sky = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[f_ro]**2) - (scale_r[f_ri]**2))

        printf("\r - Analysing object........: %d / %d", i, n_list)

        # AUMENTO DE APERTURAS:
        for(j=1;j<=30;j+=1){

            # Flujo residual dentro de apertura:
            tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
            tmp_outfile = cache_dir//"/"//"tmp_numerator_aper"
            imdelete(tmp_outfile, >& "dev$null")
            imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)
            # numerador del indice por apertura:
            imstat(cache_dir//"/"//"tmp_numerator_aper", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            numerator_aper = mean_val * n_pix
            # Area de la apertura:
            area_aper = const_pi * (scale_r[j] * petro_r[i])**2 * (a_img[i] * b_img[i])

            # =========== EXPERIMENTAL STUFF PROFILE INDEX =====================
            if(j==1){

                # NUMERADOR INDICE PERFIL (ELIPSE):
                numerator_prfl = numerator_aper

                # DENOMINADOR INDICE DE PERFIL (ELIPSE):
                tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
                tmp_outfile = cache_dir//"/"//"tmp_denominator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                expr = expre1//" ? f : 0"
                imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)
                # suma:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                denominator_prfl = mean_val * n_pix

                # AREA DE CORRECION DEL CIELO (ELIPSE):
                area_prfl = area_aper

            }else{

                # NUMERADOR INDICE PERFIL (ANILLOS):
                tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
                tmp_outfile = cache_dir//"/"//"tmp_numerator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                expr = expre1//" && "//expre2//" ? h : 0"
                imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-1] * petro_r[i] * a_img[i], scale_r[j-1] * petro_r[i] * b_img[i], tmp_infile, verb-)
                # suma:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                numerator_prfl = mean_val * n_pix

                # DENOMINADOR INDICE PERFIL (ANILLOS):
                tmp_infile = frames_dir//"/"//id_obj[i]//"_obs_setmask.fits"
                tmp_outfile = cache_dir//"/"//"tmp_denominator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                expr = expre1//" && "//expre2//" ? h : 0"
                imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-1] * petro_r[i] * a_img[i], scale_r[j-1] * petro_r[i] * b_img[i], tmp_infile, verb-)
                # numerador del indice por apertura:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                denominator_prfl = mean_val * n_pix

                # AREA DE CORRECCION DEL CIELO (ANILLOS):
                area_prfl = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[j]**2) - (scale_r[j-1]**2))
            }
            # =========== END EXPERIMENTAL STUFF PROFILE INDEX =====================

            # ECUACION DE INDICE DE PERFIL:
            abs_prfl_index = (numerator_aper - ((area_prfl / area_sky) * numerator_corr)) / denominator_prfl
            # Truncar indice de perfil:
            if(abs_prfl_index < 0){abs_prfl_index = 0}

            # ECUACION DE INDICE CUMULATIVO:
            abs_cumm_index = (numerator_aper - ((area_aper / area_sky) * numerator_corr)) / denominator_cumm

            #    if(j==26){
            #        print("")
            #        print((0.25+(0.05*(j-1))))
            #        print(" num_aper.....: ", numerator_aper)
            #        print(" num_corr.....: ", numerator_corr)
            #        print(" den_cum......: ", denominator_cumm)
            #        print(" den_prfl.....: ", denominator_prfl)
            #        print(" area aper/sky: ", area_aper, area_sky)
            #        print(" frac_aper....: ", area_aper / area_sky)
            #        print(" abs_cumm.....: ", abs_cumm_index)
            #    }

            # IMPRIMIR CATALOGOS:
            if(j == 1){

                #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: first)
                printf("%32s %11f", id_obj[i], numerator_aper, >> abscat_dir//"/"//"sum_flux_set.cat")

                # II. PROFILE index SET: first
                printf("%32s %11.4f", id_obj[i], abs_prfl_index, >> abscat_dir//"/"//"prfl_index_set.cat")

                # III. CUMULATIVE index SET: first
                printf("%32s %11.4f", id_obj[i], abs_cumm_index, >> abscat_dir//"/"//"cum_index_set.cat")

            }else if(j == 30){

                # I. Asymmetrical pixel SET: last
                printf(" %11f\n", numerator_aper, >> abscat_dir//"/"//"sum_flux_set.cat")

                # III. PROFILE Asymmetry area SET: last
                printf(" %11.4f\n", abs_prfl_index, >> abscat_dir//"/"//"prfl_index_set.cat")

                # IV. CUMULATIVE Asymmetry area SET: last
                printf(" %11.4f\n", abs_cumm_index, >> abscat_dir//"/"//"cum_index_set.cat")

            }else{

                # I. Asymetrical pixel SET: mid
                printf(" %11f", numerator_aper, >> abscat_dir//"/"//"sum_flux_set.cat")

                # III. PROFILE index SET: mid
                printf(" %11.4f", abs_prfl_index, >> abscat_dir//"/"//"prfl_index_set.cat")

                # IV. CUMULATIVE index SET: mid
                printf(" %11.4f", abs_cumm_index, >> abscat_dir//"/"//"cum_index_set.cat")

            }

            # ====================================================================================
            # PRINT CATALOGS: Tree fixed apertures
            # ====================================================================================
            if(j == 16){

                # PROFILE Main catalog Asymetry
                printf("%32s %11.4f %11.4f %11.8f %11.8f %11.4f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], abs_prfl_index, >> abscat_dir//"/"//"prfl_index_main.cat")

                # CUMULATIVE Main catalog Asymetry
                printf("%32s %11.4f %11.4f %11.8f %11.8f %11.4f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], abs_cumm_index, >> abscat_dir//"/"//"cum_index_main.cat")

            }else if(j == 26){

                # PROFILE MAIN catalog Asymmetry
                printf(" %11.4f", abs_prfl_index, >> abscat_dir//"/"//"prfl_index_main.cat")

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %11.4f", abs_cumm_index, >> abscat_dir//"/"//"cum_index_main.cat")

                #   # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                #   expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(1.5 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//', (1.55rp): '//str(prfl_index_alpha)//'}'
                #   print(expr, >> out_ds9_cat//"prfl_index.reg")
                #
                #   # ALPHA INDEX DS9 REGION: measurement (1.5xRp) aperture: eliptical
                #   expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(1.5 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//', (1.55rp): '//str(cum_index_alpha)//'}'
                #   print(expr, >> out_ds9_cat//"cum_index.reg")

            }else if(j == 30){

                # PROFILE MAIN catalog Asymmetry
                printf(" %11.4f\n", abs_prfl_index, >> abscat_dir//"/"//"prfl_index_main.cat")

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %11.4f\n", abs_cumm_index, >> abscat_dir//"/"//"cum_index_main.cat")

                #   # PROFILE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                #   expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(2 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={(1rp): '//str(prfl_index_alpha)//'}'
                #   print(expr, >> out_ds9_cat//"prfl_index.reg")
                #
                #   # CUMULATIVE INDEX DS9 REGION: measurement (2xRp) aperture: eliptical
                #   expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(2 * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={(1rp): '//str(cum_index_alpha)//'}'
                #   print(expr, >> out_ds9_cat//"cum_index.reg")

            }
            # END PRINT CATALOGS ===============================================================

        # END FOR: aumento de aperturas
        }

    # END FOR: recorrido de objetos
    }

    print("\n\n ------------------------------------------")
    print(" =========== ABSOLUTE ROTATION ============")
    print(" ============ ASYMMETRY INDEX =============")

    print(" Classical  asymmetry  index,  known as A of")
    print(" CAS (Conselice et al., 2000). However, here")
    print(" it is  calculated as in (recently) Sazonova")
    print(" et. al. (2024).\n")

    printf(" OUTPUT FOLDER: ./%s\n", abs_dir)
    print(" END TASK: abs_index")
    print(" ------------------------------------------")
    print("")

    flpr
    flpr
end
