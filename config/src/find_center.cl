procedure find_center()

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k, i_aux
    struct line
    real mean_val
    int n_pix
    # constants........
    real const_pi
    # Parameters:
    string key_word
    real pixel_scale, seeing_arc, seeing_pix
    int delta_pix
    int n_grid, min_abs_ngrid, min_rms_ngrid
    int i_grid[100], j_grid[100]
    int x0_grid[100], y0_grid[100]
    real tmp_xc, tmp_yc
    int tmp_x0, tmp_y0
    real min_sum_abs
    real min_sum_rms
    real scale_r_offset
    real scale_r[99]
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    string ellip_expr
    # output parameters:
    int min_i_abs, min_j_abs
    int min_x0_abs[999], min_y0_abs[999]
    real min_ra_abs, min_dec_abs
    int min_i_rms, min_j_rms
    int min_x0_rms[999], min_y0_rms[999]
    real min_ra_rms, min_dec_rms
    real sum_abs[100], sum_rms[100]
    # list of objects:
    string params_list, images_list
    int n_list
    string observed_img[999], segmen_img[999], setmask_img[999]
    string id_obj[999]
    int  seg_number[999]
    real ra_j00[999], dec_j00[999]
    int xc[999], yc[999]
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999], eff_r[999]
    real kron_r[999], iso_area[999], iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # temporals:
    string tmp_id_obj, tmp_infile, tmp_infile2, tmp_outfile
    string measure_img[999]
    string measure_img_180

    # Folder variables:
    string outsex_dir
    string datafiles_dir
    string cache_dir
    string observed_dir
    string segmen_dir

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (0.05 * (i-1))
    }

    # ASIGNACIÓN DE DIRECTORIOS -------------------------
    # ./config/sextractor/results_sex
    outsex_dir = "data/results_sex"
    datafiles_dir = "data/data_files"
    cache_dir = "data/cache"
    observed_dir = "data/data_images/observed"
    segmen_dir = "data/data_images/segmentation"

    # carpeta de uso temporal para este tarea:
    if(!access(cache_dir)){mkdir(cache_dir)}

    print("\n TASK: center_min")

    # listas heredadas exactamente de 'find_objs' y 'glxy_model' task:
    params_list = outsex_dir//"/"//"params_to_index.ascii"
    images_list = datafiles_dir//"/"//"accepted_imgs.ascii"

    # No existe archivo de entrada esperado:
    if(!access(params_list) || !access(images_list)){
        print(" ERR(fatal): mandatory that it exist:")
        print(" - ", images_list)
        print(" - ", params_list)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        goto exit_task
    }

    # ==================================================
    # Leer lista de parametros de los SEx-modelos:
    # ==================================================
    list = params_list
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(id_obj[i], seg_number[i], ra_j00[i], dec_j00[i], xc[i], yc[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i], ri_ann[i], ro_ann[i], xlen_min[i], ylen_min[i])

            # Correcciones:
            # petro_r[] ya fue corregido en 'glxy_model' task.
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[i] = theta_img[i] * const_pi / 180

            # La imagen de partida es la observada con MASKING!
            setmask_img[i] = observed_dir//"/"//id_obj[i]//"_setmask.fits"

        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""
    n_list = i

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
                # print("\n", key_word, ": ", pixel_scale)
            }

            if(key_word == "SEEING_FWHM"){
                # SEEING_VAL en arcosegundos:
                print(line) | scan(key_word, seeing_arc)
                #SEEING_VAL en pixels (+1 asegura tomar el pixel entero mas alejado):
                seeing_pix = (seeing_arc / pixel_scale)
                # print("\n", key_word, " arc: ", seeing_arc, " pix: ", seeing_pix)
            }
        # END IF: lineas validas
        }
    # END WHILE: lectura lista
    }
    list = ""

    # ===================================================
    #
    # ===================================================

    # SEGUIMIENTO:
    print("# SEGUIMIENTO: REGISTRO DE CORRECCION DE CENTRO", > datafiles_dir//"/"//"history_center_corr.txt")
    print("# Busqueda del pixel que minimiza la suma del residuo abs(I-I_180) y (I-I_180)**2", >> datafiles_dir//"/"//"history_center_corr.txt")
    print("\n# Los valores x0/y0 son respecto a los recortes:", >> datafiles_dir//"/"//"history_center_corr.txt")
    print("# PATH_IMG: 'data/data_images/observed/ID_OBJ.fits", >> datafiles_dir//"/"//"history_center_corr.txt")
    print("# o las imagenes de entrada si son una lista de imagenes!", >> datafiles_dir//"/"//"history_center_corr.txt")

    # La busqueda de centro dentro de una caja del tamaño del SEEING_FWHM
    delta_pix = seeing_pix
    # Asegurar una caja cuadrada:
    if(delta_pix % 2 == 0){delta_pix += 1}
    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"

    for(k=1;k<=n_list;k+=1){

        # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
        # De igual tamaño para todos los objetos:
        A_outer = scale_r[26] * petro_r[k] * a_img[k] + 0.5
        B_outer = scale_r[26] * petro_r[k] * b_img[k] + 0.5
        xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
        ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
        # asegurar len_min entero impar:
        if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
        if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

        # Primer centro de busqueda:
        tmp_x0 = xc[k] - int(delta_pix / 2)
        tmp_y0 = yc[k] - int(delta_pix / 2)

        # Centro de la elipse_expr:
        tmp_xc = real(xlen_min[k]) / 2
        tmp_yc = real(ylen_min[k]) / 2

        # SEGUIMIENTO:
        print("\n ------------------------------------------------", >> datafiles_dir//"/"//"history_center_corr.txt")
        print("\n ID_OBJ: ", id_obj[k], >> datafiles_dir//"/"//"history_center_corr.txt")
        printf(" x0: %4d | y0: %4d\n", xc[k], yc[k], >> datafiles_dir//"/"//"history_center_corr.txt")
        printf(" Lx: %4d | Ly: %4d\n", xlen_min[k], ylen_min[k], >> datafiles_dir//"/"//"history_center_corr.txt")
        printf(" matriz de busqueda: %dx%d pix.\n", delta_pix, delta_pix, >> datafiles_dir//"/"//"history_center_corr.txt")

        # Cabecera
        printf("\n %6s %4s %4s %10s %10s\n", "n_grid", "x0", "y0", "sum_abs", "sum_rms", >> datafiles_dir//"/"//"history_center_corr.txt")

        n_grid = 0

        # Empieza la iteracion d eposibles centros:
        for(i=1;i<=delta_pix;i+=1){

            # Reiniciar la posicion en y-j para cada x-i:
            tmp_y0 = yc[k] - int(delta_pix / 2)

            # Para recorrer los j-pixeles en Y:
            for(j=1;j<=delta_pix;j+=1){

                # posicion total en el espacio de busqueda:
                n_grid += 1
                # en el recorrido i-j:
                i_grid[n_grid] = i
                j_grid[n_grid] = j
                # en valores de pixel en la imagen origen:
                x0_grid[n_grid] = tmp_x0
                y0_grid[n_grid] = tmp_y0

                # Recortar la imagen alrededor del centro temporal:
                # Vertices del frame
                px1 = tmp_x0 - int((xlen_min[k] - 1) / 2)
                px2 = tmp_x0 + int((xlen_min[k] - 1) / 2)
                py1 = tmp_y0 - int((ylen_min[k] - 1) / 2)
                py2 = tmp_y0 + int((ylen_min[k] - 1) / 2)
                # Seccion a recortar:
                trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"

                # recortar la imagen:
                tmp_infile = setmask_img[k]//trimsection
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_measurebox"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imcopy(tmp_infile, tmp_outfile, ver-)
                # enlistar imagen creada:
                measure_img[k] = tmp_outfile//".fits"

                # EXPERIMENTO MUESTRA QUE IMACCES DEBE TENER LA EXTENSION DE LA IMAGEN!
                if(!access(measure_img[k])){
                    print("\n ERR: the image is expected to")
                    print("      have '*.fits' extension.")
                    print("      Try 'imaccess' to:")
                    print(" - ", measure_img[k])
                    print("\n Abort task!")
                    goto exit_task
                }

                # Una transposicion = rotar 90 grados:
                tmp_infile = measure_img[k]//"[*,-*]"
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imtranspose(tmp_infile, tmp_outfile)
                # Segunda transposicion = 180 grados:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"//"[*,-*]"
                measure_img_180 = cache_dir//"/"//id_obj[k]//"_"//i//j//"_180.fits"
                imdelete(measure_img_180, ver-, >& "dev$null")
                imtranspose(tmp_infile, measure_img_180)
                # Borrar la imagen a 90 grados:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"
                imdelete(tmp_infile, ver-, >& "dev$null")

                # Imagen residual abs(I-I_180) dentro de apertura (1.5rp):
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_abs_res.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imexpr((ellip_expr + " <=1 ? abs(f-g) : 0"), tmp_outfile, tmp_xc, tmp_yc, (scale_r[16] * a_img[k] * petro_r[k]), (scale_r[16] * b_img[k] * petro_r[k]), theta_rad[k], measure_img[k], measure_img_180, verb-)

                # Imagen residual (I-I_180)**2 (rms) dentro de apertura (1.5rp):
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_rms_res.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imexpr((ellip_expr + " <=1 ? (f-g)**2 : 0"), tmp_outfile, tmp_xc, tmp_yc, (scale_r[16] * a_img[k] * petro_r[k]), (scale_r[16] * b_img[k] * petro_r[k]), theta_rad[k], measure_img[k], measure_img_180, verb-)

                # Tomar la suma de los abs(Flux) pixeles:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_abs_res.fits"
                imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                # suma abs(F):
                sum_abs[n_grid] = mean_val * n_pix

                # Tomar la suma de los (Flux)**2 pixeles:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_rms_res.fits"
                imstat(tmp_infile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(mean_val, n_pix)
                # suma (F)**2:
                sum_rms[n_grid] = mean_val * n_pix

                # SEGUIMIENTO:
                printf(" %6d %4d %4d %10f %10f\n", n_grid, tmp_x0, tmp_y0, sum_abs[n_grid], sum_rms[n_grid], >> datafiles_dir//"/"//"history_center_corr.txt")

                # Liberar espacio (?):
                imdelete(measure_img[k], ver-, >& "dev$null")
                imdelete(measure_img_180, ver-, >& "dev$null")
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_abs_res.fits"
                imdelete(tmp_infile, ver-, >& "dev$null")
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_rot_rms_res.fits"
                imdelete(tmp_infile, ver-, >& "dev$null")

                # siguiente y-pixel:
                tmp_y0 +=1

            #END FOR: y-pixels
            }

            # siguiente x-pixel:
            tmp_x0 +=1

        # END FOR: x-pixels
        }

        # Iniciar valores minimos abs():
        min_abs_ngrid = 1
        min_i_abs = i_grid[1]
        min_j_abs = j_grid[1]
        min_x0_abs[k] = x0_grid[1]
        min_y0_abs[k] = y0_grid[1]
        min_sum_abs = sum_abs[1]
        # Iniciar valores minimos rms():
        min_rms_ngrid = 1
        min_i_rms = i_grid[1]
        min_j_rms = j_grid[1]
        min_x0_rms[k] = x0_grid[1]
        min_y0_rms[k] = y0_grid[1]
        min_sum_rms = sum_rms[1]

        # tomar minimo:
        for(i_aux=1;i_aux<=(delta_pix**2);i_aux+=1){
            # Para abs():
            if(sum_abs[i_aux] < min_sum_abs){
                min_sum_abs = sum_abs[i_aux]
                min_i_abs = i_grid[i_aux]
                min_j_abs = j_grid[i_aux]
                min_x0_abs[k] = x0_grid[i_aux]
                min_y0_abs[k] = y0_grid[i_aux]
                min_abs_ngrid = i_aux
            }
            # Para rms():
            if(sum_rms[i_aux] < min_sum_rms){
                min_sum_rms = sum_rms[i_aux]
                min_i_rms = i_grid[i_aux]
                min_j_rms = j_grid[i_aux]
                min_x0_rms[k] = x0_grid[i_aux]
                min_y0_rms[k] = y0_grid[i_aux]
                min_rms_ngrid = i_aux
            }
        # END FOR: tomar minimo
        }

        # lista abs() para wcstran:
        printf("%32s %5d %5d\n", id_obj[k], min_x0_abs[k], min_y0_abs[k], > cache_dir//"/"//k//"_abs_pixmincenter.ascii")

        # lista rms() para wcstran:
        printf("%32s %5d %5d\n", id_obj[k], min_x0_rms[k], min_y0_rms[k], > cache_dir//"/"//k//"_rms_pixmincenter.ascii")

        # SEGUIMIENTO:
        print("\n ABS center correction:", >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" n_grid: ", min_abs_ngrid, >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" i_grid: ", min_i_abs, " j_grid: ", min_j_abs, >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" min sum: ", min_sum_abs, >> datafiles_dir//"/"//"history_center_corr.txt")
        # SEGUIMIENTO:
        print("\n RMS center correction:", >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" n_grid: ", min_rms_ngrid, >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" i_grid: ", min_i_rms, " j_grid: ", min_j_rms, >> datafiles_dir//"/"//"history_center_corr.txt")
        print(" min sum: ", min_sum_rms, >> datafiles_dir//"/"//"history_center_corr.txt")

    # END FOR: k-objects list
    }

    # ===================================================
    #
    # ===================================================

    for(k=1;k<=n_list;k+=1){

        # Imagen para transformacion:
        observed_img[k] = observed_dir//"/"//id_obj[k]//".fits"

        # Centro que miinimiza sum_abs():
        tmp_infile = cache_dir//"/"//k//"_abs_pixmincenter.ascii"
        tmp_outfile = cache_dir//"/"//k//"_abs_skymincenter.ascii"
        # Convertir valores minimos de pixel a sky_coord:
        printf("wcsctran(input='%s', output='%s', image='%s', inwcs='logical', outwcs='world', columns='2,3')\n", tmp_infile, tmp_outfile, observed_img[k]) | cl

        # Centro que miinimiza sum_rms():
        tmp_infile = cache_dir//"/"//k//"_rms_pixmincenter.ascii"
        tmp_outfile = cache_dir//"/"//k//"_rms_skymincenter.ascii"
        # Convertir valores minimos de pixel a sky_coord:
        printf("wcsctran(input='%s', output='%s', image='%s', inwcs='logical', outwcs='world', columns='2,3')\n", tmp_infile, tmp_outfile, observed_img[k]) | cl

    }

    # ===================================================
    # Leer la lista de coordenadas transformadas:
    # ===================================================

    # Cabecera: lista de centros que minimizan abs():
    print("# Lista de centros (en pixeles) que minimizan la suma de ABS(I-I_180)", > datafiles_dir//"/"//"abs_mincenter.ascii")
    printf("#%31s %14s %14s %5s %5s\n", "ID", "RAmin", "DECmin", "Xmin", "Ymin", >> datafiles_dir//"/"//"abs_mincenter.ascii")

    # Cabecera: lista de centros que minimizan rms():
    print("# Lista de centros (en pixeles) que minimizan la suma de RMS(I-I_180)", > datafiles_dir//"/"//"rms_mincenter.ascii")
    printf("#%31s %14s %14s %5s %5s\n", "ID", "RAmin", "DECmin", "Xmin", "Ymin", >> datafiles_dir//"/"//"rms_mincenter.ascii")

    for(k=1;k<=n_list;k+=1){

        # lectura de lista mincenter abs() en pixeles objeto-k:
        list = cache_dir//"/"//k//"_abs_skymincenter.ascii"
        while(fscan(list,line) != EOF){
            if(line != "" && substr(line,1,1) != "#"){
                print(line) | scan(tmp_id_obj, min_ra_abs, min_dec_abs)
            }
        }
        list = ""

        # lista de centros que minimizan abs():
        printf("%32s %14f %14f %5d %5d\n", id_obj[k], min_ra_abs, min_dec_abs, min_x0_abs[k], min_y0_abs[k], >> datafiles_dir//"/"//"abs_mincenter.ascii")

        # lectura de lista mincenter rms() en pixeles objeto-k:
        list = cache_dir//"/"//k//"_rms_skymincenter.ascii"
        while(fscan(list,line) != EOF){
            if(line != "" && substr(line,1,1) != "#"){
                print(line) | scan(tmp_id_obj, min_ra_rms, min_dec_rms)
            }
        }
        list = ""

        # lista de centros que minimizan rms():
        printf("%32s %14f %14f %5d %5d\n", id_obj[k], min_ra_rms, min_dec_rms, min_x0_rms[k], min_y0_rms[k], >> datafiles_dir//"/"//"rms_mincenter.ascii")

        # Liberar espacio:
        tmp_infile = cache_dir//"/"//k//"_abs_skymincenter.ascii"
        delete(tmp_infile, ver-, >& "dev$null")
        tmp_infile = cache_dir//"/"//k//"_abs_pixmincenter.ascii"
        delete(tmp_infile, ver-, >& "dev$null")
        tmp_infile = cache_dir//"/"//k//"_rms_pixmincenter.ascii"
        delete(tmp_infile, ver-, >& "dev$null")
        tmp_infile = cache_dir//"/"//k//"_rms_skymincenter.ascii"
        delete(tmp_infile, ver-, >& "dev$null")

    }

    exit_task:

    # print("Exit task.")
    print("\n END TASK: center_min")
    print("\n------------------------------------------")
    print("")
    beep

end
