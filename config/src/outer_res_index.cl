procedure outer_res_index()

string center_rot = "abs"   {prompt = "'abs' or 'rms' minimization"}
string bulge_clip = "10.0"  {prompt = "sigma-clip avoid bulge ('off' to disable)"}
bool   force      = yes      {prompt = "force measure with ds9 regions"}
string ctl_aper    = "2"  {prompt = "'all' (full loop, 1..36) or space-separated Rp list, e.g. '1 1.5 2'"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k, count
    struct line
    string key_word
    real mean_val, n_pix
    # constants........
    real const_pi
    # patrameters......
    real hiblg_clip
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
    real local_rms
    # forzar medida:
    string force_obj
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force

    # carpeta principal:
    string outer_res_dir, absimg_dir, cache_dir
    string frames_dir, residualimg_dir
    string files_dir, abscat_dir, ds9_dir
    # otras carpetas:
    string datafiles_dir
    string outsex_dir
    # direcciones de imagenes:
    string observed_dir, segmen_dir, bckgrnd_dir
    string model_dir, residual_dir

    # calculo de indices:
    real cum_flux_ttl[999]
    int f_ri, f_ro
    real bulge_area, denominator_cumm, numerator_corr
    real area_sky, numerator_aper
    real area_prfl, numerator_prfl
    real area_aper, denominator_prfl
    real outer_res_prfl_index, outer_res_cumm_index

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_infile3, tmp_outfile

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    if(strlwr(bulge_clip) == "off"){
        # 'off' -> no crea hueco (clip "infinito"):
        hiblg_clip = 1.0e6
        printf("outer_res_index_nn") | scan(outer_res_dir)
    }else{
        hiblg_clip = real(bulge_clip)
        printf("outer_res_index_%.1f", hiblg_clip) | scan(outer_res_dir)
    }
    cache_dir = outer_res_dir//"/"//"cache"
    # images:
    absimg_dir = outer_res_dir//"/"//"images"
    frames_dir = absimg_dir//"/"//"small_frames"
    residualimg_dir = absimg_dir//"/"//"abs_residual"
    # catalogs:
    files_dir = outer_res_dir//"/"//"catalogs"
    ds9_dir = files_dir//"/"//"ds9"
    abscat_dir = files_dir//"/"//"outer_residual_index"
    # other:
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    segmen_dir   = "data/data_images/segmentation"
    bckgrnd_dir  = "data/data_images/background"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"

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
    print(" ============= OUTER RESIDUAL ROTATION ===========")
    print(" ================ ASYMMETRY INDEX ================")

    print(" The first asymmetry index proposed in literature ")
    print(" by  Schade et al. (1995), known  as Residual Asy-")
    print(" mmetry (R_A).")

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
    if(!access(outer_res_dir)){mkdir(outer_res_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}
    if(!access(absimg_dir)){mkdir(absimg_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(residualimg_dir)){mkdir(residualimg_dir)}

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

    for(i=1;i<=n_list;i+=1){

        force_obj = "force_reg/force_"//id_obj[i]//".reg"
        if(access(force_obj) && force == yes){

            # extraer nuevos parametros de medida:
            expr = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
            print("\n  - Object to force measure: ", id_obj[i])
            printf(expr, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

            # Nuevos parametros:
            a_img[i] = a_int / (2.0 * petro_r[i])
            b_img[i] = b_int / (2.0 * petro_r[i])
            theta_img[i] = ell_angle
            theta_rad[i] = theta_img[i] * const_pi / 180

            # Elipse exterior para extraer cielo:
            tmp_real = (((a_ext / (a_img[i] * petro_r[i])) - scale_r_offset) / scale_r_step) + 1
            ro_ann_force = int(tmp_real)
            # Asegurar entero proximo mas grande:
            if((tmp_real - ro_ann_force) >= 0.5){ro_ann_force += 1}
            # Actualizar nuevo parametro:
            ro_ann[i] = ro_ann_force
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

        }else{
            # # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
            # # De igual tamaño para todos los objetos:
            # A_outer = scale_r[56] * petro_r[i] * a_img[i] + 10
            # B_outer = scale_r[56] * petro_r[i] * b_img[i] + 10
            # xlen_min[i] = 2 * sqrt((A_outer * cos(theta_rad[i]))**2 + (B_outer * sin(theta_rad[i]))**2)
            # ylen_min[i] = 2 * sqrt((A_outer * sin(theta_rad[i]))**2 + (B_outer * cos(theta_rad[i]))**2)
            # # asegurar len_min entero impar:
            # if(xlen_min[i] % 2 == 0){xlen_min[i] = xlen_min[i] + 1}
            # if(ylen_min[i] % 2 == 0){ylen_min[i] = ylen_min[i] + 1}
        }

        # Recortar la imagen alrededor del centro:
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

        # BULBO GALACTIVO:
        tmp_infile = model_dir//"/"//id_obj[i]//"_mod.fits"
        tmp_infile2 = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
        tmp_infile3 = segmen_dir//"/"//id_obj[i]//"_third_seg.fits"
        imstat(tmp_infile2, fields="midpt", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(local_rms)
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("(a >= b*c) && (d == e)", tmp_outfile, tmp_infile, hiblg_clip, local_rms, tmp_infile3, seg_number[i], verb-)

        # recorta tamaño optimo (BULBO a evitar):
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"//trimsection
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imcopy(tmp_infile, tmp_outfile, ver-)

        # recorta tamaño optimo (OBSSERVED OUTER SETMASK):
        tmp_infile = observed_dir//"/"//id_obj[i]//"_obs_secondmask.fits"//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_obs_secondmask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)
        # -------- MODIFICACION de outer abs a outer residual ----------------------
        tmp_infile = residual_dir//"/"//id_obj[i]//"_res.fits"//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_res.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)
        # --------------------------------------------------------------------------

        # Apertura maxima para indice acumulativo:
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        tmp_infile2 = frames_dir//"/"//id_obj[i]//"_obs_secondmask.fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_out_setmask.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr(expre1//" && f == 0 ? g : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[30] * petro_r[i] * a_img[i], scale_r[30] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, tmp_infile2, verb-)

        # MINIMUM RESIDUAL (SET MASK) 180° rotation:
        # transposicion = rotar 90 grados:
        # -------- MODIFICACION ('_obs_' por '_res_') ----------------------
        tmp_infile = frames_dir//"/"//id_obj[i]//"_res.fits"//"[*,-*]"
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_res_rot90.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # repetir transposicion = 180°:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_res_rot90.fits"//"[*,-*]"
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_res_rot180.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imtranspose(tmp_infile, tmp_outfile)
        # eliminar imagen a 90°:
        tmp_infile = frames_dir//"/"//id_obj[i]//"_res_rot90.fits"
        imdelete(tmp_infile, ver-, >& "dev$null")
        # Residuo asimetrico de area (N-N_180):
        tmp_infile = frames_dir//"/"//id_obj[i]//"_res.fits"
        tmp_infile2 = frames_dir//"/"//id_obj[i]//"_res_rot180.fits"
        tmp_outfile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imexpr("c == 0 ? abs(a-b) : 0", tmp_outfile, tmp_infile, tmp_infile2, cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits", verb-)

        # Progress bar proccess:
        printf("\r - Process (cutting images): %d%%", (i*100/n_list))
    }

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================

    if(!access(files_dir)){mkdir(files_dir)}
    if(!access(abscat_dir)){mkdir(abscat_dir)}
    if(!access(ds9_dir)){mkdir(ds9_dir)}

    for(count=1;count<=n_aper;count+=1){

        i = aper_list[count]

        # Prefijo (columna ID_OBJ): solo en la primer apertura de la lista.
        if(count == 1){

            # I. Flux SET: prefijo
            printf("#%31s", "ID_OBJ", > abscat_dir//"/"//"set_flux_outer_res.cat")

            # II. PROFILE index SET: prefijo
            printf("#%31s", "ID_OBJ", > abscat_dir//"/"//"prfl_set_outer_res.cat")

            # III. CUMULATIVE index SET: prefijo
            printf("#%31s", "ID_OBJ", > abscat_dir//"/"//"cum_set_outer_res.cat")

            # COMPACT: prefijo con posicion del objeto (ID_OBJ + coordenadas):
            printf("#%31s %11s %11s %11s %11s", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > abscat_dir//"/"//"prfl_main_outer_res.cat")
            printf("#%31s %11s %11s %11s %11s", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", > abscat_dir//"/"//"cum_main_outer_res.cat")

        }

        # Etiqueta de columna de ESTA apertura: en cada iteracion, con o sin
        # salto de linea segun sea la ultima apertura seleccionada o no
        # (independiente de 'count==1', para que ambas ramas se ejecuten
        # cuando solo hay una apertura seleccionada, n_aper==1):
        if(count == n_aper){

            # I. Flux SET: last
            printf(" sumF_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"set_flux_outer_res.cat")

            # II. PROFILE index SET: last
            printf(" prfl_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"prfl_set_outer_res.cat")

            # III. CUMULATIVE index SET: last
            printf(" cum_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"cum_set_outer_res.cat")

            # COMPACT: ultima columna, con salto de linea:
            printf(" prfl_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"prfl_main_outer_res.cat")
            printf(" R_A_%4.2frp\n", scale_r[i], >> abscat_dir//"/"//"cum_main_outer_res.cat")

        }else{

            # I. Flux SET: mid
            printf(" sumF_%4.2frp", scale_r[i], >> abscat_dir//"/"//"set_flux_outer_res.cat")

            # II. PROFILE index SET: mid
            printf(" prfl_%4.2frp", scale_r[i], >> abscat_dir//"/"//"prfl_set_outer_res.cat")

            # III. CUMULATIVE index SET: mid
            printf(" cum_%4.2frp", scale_r[i], >> abscat_dir//"/"//"cum_set_outer_res.cat")

            # COMPACT: columna intermedia, sin salto de linea:
            printf(" prfl_%4.2frp", scale_r[i], >> abscat_dir//"/"//"prfl_main_outer_res.cat")
            printf(" R_A_%4.2frp", scale_r[i], >> abscat_dir//"/"//"cum_main_outer_res.cat")

        }
    # END FOR: header catalogs
    }

    # DS9 HEADER ACATALOG INDEX VALUE (CUMMULATIVE CURVE):
    delete(ds9_dir//"/"//"cum_outer_res.reg",  >& "dev$null")
    print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"cum_outer_res.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"cum_outer_res.reg")
    print("fk5", >> ds9_dir//"/"//"cum_outer_res.reg")

    # ===============================================================
    # INDEX COMPUTATION
    # ===============================================================
    print("\n\n --------- Computing outer residual index ------------\n")

    for(i=1;i<=n_list;i+=1){

        # AREA DEL BULBO A EVITAR
        tmp_infile = cache_dir//"/"//id_obj[i]//"_avoid_bulgemodel.fits"
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # area del bulbo a evitar:
        bulge_area = mean_val * n_pix

        # DENOMINADOR DEL INDICE CUMULATIVO (const.):
        tmp_infile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_out_setmask.fits"
        imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # denominador de indice cumulativo:
        denominator_cumm = mean_val * n_pix

        # ESTIMACION DEL FONDO -----------------------------------------------------------
        f_ri = ri_ann[i]
        f_ro = ro_ann[i]
        # Anillo eliptico del CIELO ASIMETRICO (blank patch)
        tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
        tmp_outfile = cache_dir//"/"//id_obj[i]//"_blankpatch.fits"
        expr = expre1//" && "//expre2//" ? h : 0"
        imdelete(tmp_outfile, >& "dev$null")
        imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[f_ro]*petro_r[i]*a_img[i], scale_r[f_ro]*petro_r[i]*b_img[i], theta_rad[i], scale_r[f_ri]*petro_r[i]*a_img[i], scale_r[f_ri]*petro_r[i]*b_img[i], tmp_infile, verb-)
        # suma[abs(I_sky - I_sky,180)]
        imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
        # numerador de sky correction:
        numerator_corr = mean_val * n_pix
        # area del anillo:
        area_sky = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[f_ro]**2) - (scale_r[f_ri]**2))

        printf("\r - Analysing object........: %d / %d", i, n_list)

        # AUMENTO DE APERTURAS:
        for(count=1;count<=n_aper;count+=1){

            j = aper_list[count]

            # Flujo residual dentro de apertura:
            tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
            tmp_outfile = cache_dir//"/"//"tmp_numerator_aper"
            imdelete(tmp_outfile, >& "dev$null")
            imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)
            # numerador del indice por apertura:
            imstat(cache_dir//"/"//"tmp_numerator_aper", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            numerator_aper = mean_val * n_pix

            # Area de la apertura:
            area_aper = (const_pi * (scale_r[j] * petro_r[i])**2 * (a_img[i] * b_img[i])) - bulge_area
            # Verificar que 'area_aper' sea valido:
            if(area_aper < 0){
                area_aper = 0
            }

            # =========== EXPERIMENTAL STUFF PROFILE INDEX =====================
            if(j==1){

                # NUMERADOR INDICE PERFIL (ELIPSE):
                numerator_prfl = numerator_aper

                # DENOMINADOR INDICE DE PERFIL (ELIPSE):
                tmp_infile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_out_setmask.fits"
                tmp_outfile = cache_dir//"/"//"tmp_denominator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, verb-)
                # numerador del indice por apertura:
                imstat(cache_dir//"/"//"tmp_denominator_prfl", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                denominator_prfl = mean_val * n_pix

                # AREA DE CORRECION DEL CIELO (ELIPSE):
                area_prfl = area_aper

            }else{

                # NUMERADOR INDICE PERFIL (ELIPSE):
                tmp_infile = residualimg_dir//"/"//id_obj[i]//"_min_abs_residual.fits"
                tmp_outfile = cache_dir//"/"//"tmp_numerator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                expr = expre1//" && "//expre2//" ? h : 0"
                imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-1] * petro_r[i] * a_img[i], scale_r[j-1] * petro_r[i] * b_img[i], tmp_infile, verb-)
                # suma:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                numerator_prfl = mean_val * n_pix

                # DENOMINADOR INDICE DE PERFIL (ELIPSE):
                tmp_infile = cache_dir//"/"//id_obj[i]//"_maxaper_obs_out_setmask.fits"
                tmp_outfile = cache_dir//"/"//"tmp_denominator_prfl"
                imdelete(tmp_outfile, >& "dev$null")
                expr = expre1//" && "//expre2//" ? h : 0"
                imexpr(expr, tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], scale_r[j-1] * petro_r[i] * a_img[i], scale_r[j-1] * petro_r[i] * b_img[i], tmp_infile, verb-)
                # numerador del indice por apertura:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                denominator_prfl = mean_val * n_pix

                # AREA DE CORRECION DEL CIELO (ELIPSE):
                area_prfl = const_pi * (petro_r[i]**2) * (a_img[i] * b_img[i]) * ((scale_r[j]**2) - (scale_r[j-1]**2))

            }

            # ECUACION DEL INDICE DE PERFIL VALIDADA!
            if(denominator_prfl <= 0){
                outer_res_prfl_index = 0
            }else{
                outer_res_prfl_index = (numerator_prfl - ((area_prfl / area_sky) * numerator_corr)) / (2*denominator_prfl)
            }
            # Truncar indice de perfil:
            if(outer_res_prfl_index <= 0){outer_res_prfl_index = 0}

            # ECUACION DEL INDICE CUMULATIVO:
            outer_res_cumm_index = (numerator_aper - ((area_aper / area_sky) * numerator_corr)) / (2*denominator_cumm)

            #    if(j==26){
            #        print("")
            #        print((0.25+(0.05*(j-1))))
            #        print(" num_aper.....: ", numerator_aper)
            #        print(" num_corr.....: ", numerator_corr)
            #        print(" den_cum......: ", denominator_cumm)
            #        print(" den_prfl.....: ", denominator_prfl)
            #        print(" area aper/sky: ", area_aper, area_sky)
            #        print(" frac_aper....: ", area_aper / area_sky)
            #        print(" abs_cumm.....: ", outer_res_cumm_index)
            #    }

            # IMPRIMIR CATALOGOS:
            if(count == 1){

                #       %ID  %fcor %Nt %Nasymm_1 (# I. Asymmetrical pixel SET: prefijo)
                printf("%32s %11f", id_obj[i], numerator_aper, >> abscat_dir//"/"//"set_flux_outer_res.cat")

                # II. PROFILE index SET: prefijo
                printf("%32s %11.4f", id_obj[i], outer_res_prfl_index, >> abscat_dir//"/"//"prfl_set_outer_res.cat")

                # III. CUMULATIVE index SET: prefijo
                printf("%32s %11.4f", id_obj[i], outer_res_cumm_index, >> abscat_dir//"/"//"cum_set_outer_res.cat")

            }

            # Valor de ESTA apertura: en cada iteracion, con o sin salto de
            # linea segun sea la ultima seleccionada o no (independiente de
            # 'count==1', para que ambas ramas corran si n_aper==1):
            if(count == n_aper){

                # I. Asymmetrical pixel SET: last
                printf(" %11f\n", numerator_aper, >> abscat_dir//"/"//"set_flux_outer_res.cat")

                # III. PROFILE Asymmetry area SET: last
                printf(" %11.4f\n", outer_res_prfl_index, >> abscat_dir//"/"//"prfl_set_outer_res.cat")

                # IV. CUMULATIVE Asymmetry area SET: last
                printf(" %11.4f\n", outer_res_cumm_index, >> abscat_dir//"/"//"cum_set_outer_res.cat")

            }else{

                # I. Asymetrical pixel SET: mid
                printf(" %11f", numerator_aper, >> abscat_dir//"/"//"set_flux_outer_res.cat")

                # III. PROFILE index SET: mid
                printf(" %11.4f", outer_res_prfl_index, >> abscat_dir//"/"//"prfl_set_outer_res.cat")

                # IV. CUMULATIVE index SET: mid
                printf(" %11.4f", outer_res_cumm_index, >> abscat_dir//"/"//"cum_set_outer_res.cat")

            }

            # ====================================================================================
            # PRINT CATALOGS: main_outer_res (ID_OBJ + coordenadas + una columna por apertura)
            # ====================================================================================

            # Prefijo (ID_OBJ + coordenadas): solo en la primer apertura de la lista.
            if(count == 1){
                printf("%32s %11.4f %11.4f %11.8f %11.8f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], >> abscat_dir//"/"//"prfl_main_outer_res.cat")
                printf("%32s %11.4f %11.4f %11.8f %11.8f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], >> abscat_dir//"/"//"cum_main_outer_res.cat")
            }

            # Valor de ESTA apertura (con o sin salto de linea segun sea la ultima o no,
            # independiente de 'count==1' para que ambas ramas corran si n_aper==1):
            if(count == n_aper){
                printf(" %11.4f\n", outer_res_prfl_index, >> abscat_dir//"/"//"prfl_main_outer_res.cat")
                printf(" %11.4f\n", outer_res_cumm_index, >> abscat_dir//"/"//"cum_main_outer_res.cat")
            }else{
                printf(" %11.4f", outer_res_prfl_index, >> abscat_dir//"/"//"prfl_main_outer_res.cat")
                printf(" %11.4f", outer_res_cumm_index, >> abscat_dir//"/"//"cum_main_outer_res.cat")
            }

            # OUTER RESIDUAL INDEX DS9 REGION: una elipse por cada apertura seleccionada:
            expr = 'ellipse('//str(ra_rot[i])//','//str(dec_rot[i])//','//str(scale_r[j] * petro_r[i] * a_img[i] * pixel_scale)//'",'//str(scale_r[j] * petro_r[i] * b_img[i] * pixel_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={'//id_obj[i]//' R_A_'//str(scale_r[j])//'rp: '//str(outer_res_cumm_index)//'}'
            print(expr, >> ds9_dir//"/"//"cum_outer_res.reg")

            # END PRINT CATALOGS ===============================================================

        # END FOR: aumento de aperturas
        }

    # END FOR: recorrido de objetos
    }

    print("\n\n ------------------------------------------")
    print(" ============= OUTER RESIDUAL ROTATION ===========")
    print(" ================ ASYMMETRY INDEX ================")



    printf(" OUTPUT FOLDER: ./%s\n", outer_res_dir)
    print(" END TASK: outer_residual_index")
    print(" ------------------------------------------")
    print("")

    flpr
end
