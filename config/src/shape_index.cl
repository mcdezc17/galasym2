procedure shape_index()

string   center_rot = "abs"   {prompt = "'abs' or 'rms' minimization"}
real dthresh_se     = 1.0     {prompt = "threshold detected source (sigmas)"}
real minarea_se     = 0       {prompt = "minimun area to segmentation"}
real dmincont_se    = 1.0     {prompt = "deblending (0 agresive)"}
real clean_se       = 0.1     {prompt = "clean spurious sources"}
bool force          = yes     {prompt = "force measure with ds9 regions"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j
    struct line
    string key_word
    real mean_val, n_pix
    # constants........
    real const_pi
    # patrameters......
    real scale_r_offset, scale_r_step
    real scale_r[99]
    string expre_txt, expre1, expre2, ellip_expr
    real fit_xc, fit_yc
    real xlenght_data, ylenght_data

    # PSET: datapar
    string pathname_data
    # PSET sexpar
    string key_run_se
    # --- local params SEx ---
    string extract_img
    # PSET: photmetry
    real pixel_scale

    # list of objects:
    int n_objs
    string id_obj[999]
    int  seg_number[999]
    real ra_j00[999], dec_j00[999]
    real x_pos[999], y_pos[999]
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
    string force_obj
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force

    # carpeta principal:
    string index_dir, indeximg_dir, cache_dir
    string frames_dir, residualimg_dir
    string files_dir, indexcat_dir, ds9_dir
    string sexfiles_dir
    # otras carpetas:
    string datafiles_dir
    string outsex_dir
    # direcciones de imagenes:
    string segmen_dir, observed_dir

    # calculo del indice:
    real shape_asymm
    real numerator_aper, denominator_aper
    real a_scale_aper, b_scale_aper

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_infile3, tmp_outfile

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    index_dir = "shape_index"
    cache_dir = index_dir//"/"//"cache"
    # images:
    indeximg_dir = index_dir//"/"//"images"
    frames_dir = indeximg_dir//"/"//"small_frames"
    residualimg_dir = indeximg_dir//"/"//"shape_residual"
    # catalogs:
    files_dir = index_dir//"/"//"catalogs"
    ds9_dir = files_dir//"/"//"ds9"
    indexcat_dir = files_dir//"/"//"shape_index"
    sexfiles_dir = files_dir//"/"//"sex_files"
    # other:
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    segmen_dir   = "data/data_images/segmentation"

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
    print(" ================= SHAPE ==================")
    print(" ============ ASYMMETRY INDEX =============")

    print(" Shape Asymmetry index (A_S) by Pawlik et al.")
    print(" (2016).\n")

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

    # Salida de resultados:
    if(!access(index_dir)){mkdir(index_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}
    if(!access(indeximg_dir)){mkdir(indeximg_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(residualimg_dir)){mkdir(residualimg_dir)}
    if(!access(files_dir)){mkdir(files_dir)}
    if(!access(sexfiles_dir)){mkdir(sexfiles_dir)}

    if(minarea_se > 1){

    # ===============================================================
    # EJECUTAR SEXTRACTOR PARA CREAR IMAGEN SEGMENTADA (IMAGEN CLEAN)
    # ===============================================================
    # Por ahora, aqui no se ejecuta PSFEX:
    tmp_infile = "data/results_psfex/my_prepsfex.psf"
    if(!access(tmp_infile)){
        print("\n PSF data doesn't exist!\n")
        print(" - Execute other index before.")
        print(" - Exit.\n")
        bye
    }
    # ============== COMPLETAR ARCHIVO my_shape.sex ==================
    delete("config/sextractor/my_shape.sex")
    copy("config/sextractor/tmp_shape.sex","config/sextractor/my_shape.sex")
    tmp_infile = "config/sextractor/my_shape.sex"

    print("\n#-------------------------------- Catalog ------------------------------------", >> tmp_infile)

    print("\nCATALOG_NAME shape_index/catalogs/sex_files/test.cat", >> tmp_infile)
    print("CATALOG_TYPE ASCII_HEAD", >> tmp_infile)

    print("\nPARAMETERS_NAME config/sextractor/default.param", >> tmp_infile)

    #------------------------------- Extraction ----------------------------------
    printf("FILTER_NAME config/sextractor/%s\n", "block_3x3.conv", >> tmp_infile)

    printf("DETECT_MINAREA %d\n", minarea_se, >> tmp_infile)
    print("DETECT_MAXAREA 0", >> tmp_infile)
    printf("\nDETECT_THRESH %.2f\n", dthresh_se, >> tmp_infile)
    printf("DEBLEND_MINCONT   %f\n", dmincont_se, >> tmp_infile)
    printf("CLEAN_PARAM %s\n", clean_se, >> tmp_infile)

    print("\n#------------------------------ Check Image ----------------------------------", >> tmp_infile)

    print("\nCHECKIMAGE_TYPE FILTERED, SEGMENTATION", >> tmp_infile)

    print("\nCHECKIMAGE_NAME shape_index/catalogs/sex_files/check_filt.fits, shape_index/catalogs/sex_files/check_seg.fits", >> tmp_infile)
    # ===============================================================


    # LISTA A LEER POR WHILE:
    list = "data/data_files/accepted_imgs.txt"
    #list = outsex_dir//"/"//"params_to_index.txt"
    i = 0
    # archivo de configuracion de SEx para shape index:
    tmp_infile = "config/sextractor/my_shape.sex"

    while(fscan(list, line) != EOF){

        if (line != "" && substr(line, 1, 1) != "#") {
            i += 1
            print(line) | scan(id_obj[i])

            tmp_infile3 = sexfiles_dir//"/"//id_obj[i]//"_sextracted.cat"

            if(!access(tmp_infile3)){

                extract_img = observed_dir//"/"//id_obj[i]//"_obs_secondmask.fits"

                # captura el centro de la imagen:
                imgets(extract_img, "naxis1")
                fit_xc = real(imgets.value) / 2
                imgets(extract_img, "naxis2")
                fit_yc = real(imgets.value) / 2

                # ========= RUNNING SEXTRACTOR ======================
                print(" ------------------------------------------")
                print(" RUNNING SExtractor to shape_index:")
                printf(" - img: %4d | OBJ: %s \n", i, id_obj[i])
                printf("! %s %s -c %s \n", key_run_se, extract_img, tmp_infile) | cl

                # Renombrar catalogo (SEx) de salida:
                tmp_infile2 = sexfiles_dir//"/"//"test.cat"
                tmp_outfile = sexfiles_dir//"/"//id_obj[i]//"_shape_test.cat"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                rename(tmp_infile2, tmp_outfile)

                # Renombrar la imagen 'check_seg':
                tmp_infile2 = sexfiles_dir//"/"//"check_seg.fits"
                tmp_outfile = sexfiles_dir//"/"//id_obj[i]//"_segmen.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                rename(tmp_infile2, tmp_outfile)

                # Renombrar la imagen 'check_filt':
                tmp_infile2 = sexfiles_dir//"/"//"check_filt.fits"
                tmp_outfile = sexfiles_dir//"/"//id_obj[i]//"_filt.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                rename(tmp_infile2, tmp_outfile)

                print(" - identifying object...", id_obj[i])

                # columna para identificador (# ID):
                printf("# ID\n %s\n", id_obj[i], > sexfiles_dir//"/"//"tmp_col_id.cat")

                # STILTS > obj in center of image:
                expre_txt = "! stilts tpipe ifmt=ascii ofmt=ascii cmd='addcol dist \"sqrt(($4-%.2f)*($4-%.2f) + ($5-%.2f)*($5-%.2f))\"; sorthead 1 dist' in=%s > %s/tmp_line.cat"
                tmp_infile2 = sexfiles_dir//"/"//id_obj[i]//"_shape_test.cat"
                printf(expre_txt, fit_xc, fit_xc, fit_yc, fit_yc, tmp_infile2, sexfiles_dir, id_obj[i]) | cl

                # Agrega columna ID(col1_1):
                expre_txt = "! stilts tjoin nin=2 ifmt1=ascii ifmt2=ascii in1=%s/tmp_col_id.cat in2=%s/tmp_line.cat ofmt=ascii out=%s/%s_sextracted.cat"
                printf(expre_txt, sexfiles_dir, sexfiles_dir, sexfiles_dir, id_obj[i]) | cl

                # Imprime archivo que contiene LA LINEA DEL OBJETO en una lista de (directorios) archivos
                printf("%s/%s_sextracted.cat\n", sexfiles_dir, id_obj[i], >> sexfiles_dir//"/"//"inlist.lis")

                delete(sexfiles_dir//"/"//"tmp_col_id.cat", ver-, >& "dev$null")
                delete(sexfiles_dir//"/"//"tmp_line.cat", ver-, >& "dev$null")
                delete(sexfiles_dir//"/"//"check_seg.fits", ver-, >& "dev$null")

            # END IF: si ya existe la sextraccion
            }else{
                print(" ------------------------------------------")
                print(" This object has already been SExtracted!")
                printf(" - img: %4d | OBJ: %s \n", i, id_obj[i])
            }

        # END IF: VALID LINE
        }
    # END WHILE: lectura lista 'accepted_imgs.txt'
    }
    list = ""
    n_objs = i
    print(" ------------------------------------------")

    printf("\r - Concatenating SExtractions...")

    # CONCATENACION
    delete(sexfiles_dir//"/"//"sextracted.cat", ver-, >& "dev$null")
    expre_txt = "! awk 'FNR==1 && NR==1 {print; next} /^#/ {next} {print}' $(<%s/inlist.lis) > %s/sextracted.cat"
    printf(expre_txt, sexfiles_dir, sexfiles_dir) | cl

    printf("\r - Concatenating SExtractions... Ok.")


    # END IF: (MIN_AREA > 0) = Ejecuta sextractor
    }

    # ===================================================================================
    # Leer lista de posicion de rotacion de imagen:
    # ==================================================
    # listas heredadas exactamente de 'find_center' task:
    print("\n - reading 'asymetry centers'...")
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

    if(minarea_se == 0){
        list = outsex_dir//"/"//"params_to_index.txt"
        i = 0
        while(fscan(list,line) != EOF){
            if(line != "" && substr(line,1,1) != "#" ){
                i += 1

                print(line) | scan(id_obj[i])
            }
        }
        list = ""
        n_objs = i
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
    # END: Leer lista de posicion de rotacion de imagen
    # ===================================================================================

    # leer resultados de SEx:

    if(minarea_se > 1){
        list = sexfiles_dir//"/"//"sextracted.cat"
    }else{
        list = outsex_dir//"/"//"params_to_index.txt"
    }

    i = 0
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#" ){
            i += 1

            print(line) | scan(id_obj[i], seg_number[i], ra_j00[i], dec_j00[i], x_pos[i], y_pos[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], petro_r[i], iso_areaf[i])

            petro_r[i] = (petro_r[i] / 2)
            theta_rad[i] = theta_img[i] * const_pi / 180

            if(minarea_se > 1){
                # ----------- binarizar el area del objeto ---------------
                tmp_infile2 = sexfiles_dir//"/"//id_obj[i]//"_segmen.fits"
            }else{
                tmp_infile2 = segmen_dir//"/"//id_obj[i]//"_third_seg.fits"
            }
            tmp_outfile = sexfiles_dir//"/"//id_obj[i]//"_binary.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("a==b", tmp_outfile, tmp_infile2, seg_number[i], ver-)

            # capturar tamaño:
            imgets(tmp_infile2, "naxis1")
            xlenght_data = int(imgets.value)
            imgets(tmp_infile2, "naxis2")
            ylenght_data = int(imgets.value)
            # --------------------------------------------------------

            force_obj = "force_reg/force_"//id_obj[i]//".reg"
            if(access(force_obj) && force == yes){
                # extraer nuevos parametros de medida:
                expre_txt = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
                print("\n  - Object to force measure: ", id_obj[i])
                printf(expre_txt, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

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

            # Recortar la imagen alrededor del centro:
            # Vertices
            px1 = x0_rot[i] - int((xlen_min[i] - 1) / 2)
            px2 = x0_rot[i] + int((xlen_min[i] - 1) / 2)
            py1 = y0_rot[i] - int((ylen_min[i] - 1) / 2)
            py2 = y0_rot[i] + int((ylen_min[i] - 1) / 2)
            # Seccion a recortar:
            trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"

            # Recortar la imagen binaria en el centro de asimetria (abs or rms):
            tmp_infile = sexfiles_dir//"/"//id_obj[i]//"_binary.fits"//trimsection
            tmp_outfile = frames_dir//"/"//id_obj[i]//"_binary.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imcopy(tmp_infile, tmp_outfile, ver-)

            # Rotar la imagen binaria:
            # MINIMUM RESIDUAL (SET MASK) 180° rotation:
            # transposicion = rotar 90 grados:
            tmp_infile = frames_dir//"/"//id_obj[i]//"_binary.fits"//"[*,-*]"
            tmp_outfile = frames_dir//"/"//id_obj[i]//"_binary_rot90.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imtranspose(tmp_infile, tmp_outfile)
            # repetir transposicion = 180°:
            tmp_infile = frames_dir//"/"//id_obj[i]//"_binary_rot90.fits"//"[*,-*]"
            tmp_outfile = frames_dir//"/"//id_obj[i]//"_binary_rot180.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imtranspose(tmp_infile, tmp_outfile)
            # eliminar imagen a 90°:
            tmp_infile = frames_dir//"/"//id_obj[i]//"_binary_rot90.fits"
            imdelete(tmp_infile, ver-, >& "dev$null")
            # Residuo asimetrico de area (N-N_180):
            tmp_infile = frames_dir//"/"//id_obj[i]//"_binary.fits"
            tmp_infile2 = frames_dir//"/"//id_obj[i]//"_binary_rot180.fits"
            tmp_outfile = residualimg_dir//"/"//id_obj[i]//"_shape_area_residual.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("(a-b) > 0", tmp_outfile, tmp_infile, tmp_infile2, verb-)

            # END if: lines no comentadas no vacias
        }

        # Progress bar proccess:
        printf("\r - Process (cutting images): %d%%", (i*100/n_objs))

    #ENd WHILE: Lectura lista SEx
    }
    list = ""

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================
    if(!access(indexcat_dir)){mkdir(indexcat_dir)}
    if(!access(ds9_dir)){mkdir(ds9_dir)}

    # DS9 regions: APERTURES
    print("# Region file format: DS9 version 4.1", > ds9_dir//"/"//"shape_aper.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"shape_aper.reg")
    print("fk5", >> ds9_dir//"/"//"shape_aper.reg")

    # CATALOG: Asymmetry index
    printf("#%31s %11s %11s %11s %11s %9s %9s %9s\n", "ID_OBJ", "X_IMG", "Y_IMG", "RAJ00", "DECJ00", "ap_foot", "ap_1.5rp", "ap_2.0rp", > indexcat_dir//"/"//"main_shape.cat")

    # ===============================================================
    # INDEX COMPUTATION
    # ===============================================================
    print("\n\n ----- Computing shape asymmetry index ---------\n")

    for(i=1;i<=n_objs;i+=1){

        printf("\r - Analysing object........: %d / %d", i, n_objs)

        # AUMENTO DE APERTURAS:
        for(j=1;j<=3;j+=1){

            if(j==1){
                a_scale_aper = (3 * a_img[i])
                b_scale_aper = (3 * b_img[i])
            }else if(j==2){
                a_scale_aper = 2 * (3 * a_img[i]) # scale_r[26] * petro_r[i] * a_img[i]
                b_scale_aper = 2 * (3 * b_img[i]) # scale_r[26] * petro_r[i] * b_img[i]
            }else{
                a_scale_aper = 3 * (3 * a_img[i]) # scale_r[36] * petro_r[i] * a_img[i]
                b_scale_aper = 3 * (3 * b_img[i]) # scale_r[36] * petro_r[i] * b_img[i]
            }

            # Area residual dentro de apertura:
            tmp_infile = residualimg_dir//"/"//id_obj[i]//"_shape_area_residual.fits"
            tmp_outfile = cache_dir//"/"//"tmp_numerator_aper"
            imdelete(tmp_outfile, >& "dev$null")
            imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, a_scale_aper, b_scale_aper, theta_rad[i], tmp_infile, verb-)
            # numerador del indice por apertura:
            imstat(cache_dir//"/"//"tmp_numerator_aper", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            numerator_aper = mean_val * n_pix

            # Denominador (area segmentada):
            tmp_infile = frames_dir//"/"//id_obj[i]//"_binary.fits"
            tmp_outfile = cache_dir//"/"//"tmp_denominator_aper"
            imdelete(tmp_outfile, >& "dev$null")
            imexpr(expre1//" ? f : 0", tmp_outfile, real(xlen_min[i])/2, real(ylen_min[i])/2, a_scale_aper, b_scale_aper, theta_rad[i], tmp_infile, verb-)
            # numerador del indice por apertura:
            imstat(cache_dir//"/"//"tmp_denominator_aper", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
            denominator_aper = mean_val * n_pix

            # =========== INDEX VALUE =======================
            shape_asymm = (numerator_aper / denominator_aper)

            # IMPRIMIR CATALOGOS:
            if(j==1){
                # a_scale_aper = (3 * a_img[i]) + 5
                # b_scale_aper = (3 * b_img[i]) + 5

                # CUMULATIVE Main catalog Asymetry
                printf("%32s %11.4f %11.4f %11.8f %11.8f %9.4f", id_obj[i], x0_rot[i], y0_rot[i], ra_rot[i], dec_rot[i], shape_asymm, >> indexcat_dir//"/"//"main_shape.cat")

            }else if(j==2){
                # a_scale_aper = scale_r[26] * petro_r[i] * a_img[i]
                # b_scale_aper = scale_r[26] * petro_r[i] * b_img[i]

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %9.4f", shape_asymm, >> indexcat_dir//"/"//"main_shape.cat")

                # apertures DS9 regions:
                expre_txt = 'ellipse('//ra_rot[i]//','//dec_rot[i]//','//(a_scale_aper * pixel_scale)//'",'//(b_scale_aper * pixel_scale)//'",'//theta_img[i]//') # color=red dash=1 text={'//id_obj[i]//', (1.5rp): '//str(shape_asymm)//'}'
                print(expre_txt, >> ds9_dir//"/"//"shape_aper.reg")

            }else{
                # a_scale_aper = scale_r[36] * petro_r[i] * a_img[i]
                # b_scale_aper = scale_r[36] * petro_r[i] * b_img[i]

                # CUMULATIVE MAIN catalog Asymmetry
                printf(" %9.4f\n", shape_asymm, >> indexcat_dir//"/"//"main_shape.cat")

                # apertures DS9 regions:
                expre_txt = 'ellipse('//ra_rot[i]//','//dec_rot[i]//','//(a_scale_aper * pixel_scale)//'",'//(b_scale_aper * pixel_scale)//'",'//theta_img[i]//') # color=red dash=1 text={'//id_obj[i]//', (2.0rp): '//str(shape_asymm)//'}'
                print(expre_txt, >> ds9_dir//"/"//"shape_aper.reg")
            }


        # END FOR: apertures
        }
    #END FOR: obj_list
    }

    print("\n\n ------------------------------------------")
    print(" ================= SHAPE ==================")
    print(" ============ ASYMMETRY INDEX =============")


    printf(" OUTPUT FOLDER: ./%s\n", index_dir)
    print(" END TASK: shape_index")
    print(" ------------------------------------------")
    print("")

    flpr
    flpr
end
