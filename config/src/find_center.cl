procedure find_center()

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    # constants........
    real const_pi
    # Parameters:
    string key_word
    real pixel_scale, seeing_arc, seeing_pix
    int delta_pix
    int n_grid
    int i_grid[100], j_grid[100]
    int tmp_xc, tmp_yc
    int x0_min_abs, y0_min_abs
    int x0_min_rms, y0_min_rms
    real scale_r_offset
    real scale_r[99]
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    string expre
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
    string tmp_id_obj, tmp_infile, tmp_infile_2, tmp_outfile
    int x0[999], y0[999]
    string measure_img[999]

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

            # valor inicial del centro:
            x0[i] = xc[i]
            y0[i] = yc[i]

            # Correcciones:
            # petro_r[] ya fue corregido en 'glxy_model' task.
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[i] = theta_img[i] * const_pi / 180

            # La imagen de partida es la observada con MASKING!
            setmask_img[i] = observed_dir//"/"//id_obj[i]//"_setmask.fits"

            # expre = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"

        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""
    n_list = i

    #   # ==================================================
    #   # Leer la lista de imagenes (aceptadas-existentes?):
    #   # ==================================================
    #   list = images_list
    #   i = 0
    #   while(fscan(list, line) != EOF){
    #       if(line !="" && substr(line,1,1)!="#"){
    #           i = i + 1
    #
    #           print(line) | scan(tmp_id_obj, setmask_img[i])
    #
    #           # comprobacion (seguimiento):
    #           if(id_obj[i] != tmp_id_obj){
    #               print(" ERR: there  is no correlation")
    #               print("      in reading  images  list")
    #               print("      and SEx-parameters list!")
    #               print(" - ", images_list)
    #               print(" - ", params_list)
    #               print("\n Abort task!")
    #               list = ""
    #               goto exit_task
    #           }
    #       # END IF: lineas validas
    #       }
    #   # END WHILE: lectura de lista
    #   }
    #   list = ""
    #   # comprobacion de tamaños de listas:
    #   if(n_list != i){
    #       print(" ERR: the lists must be of equal")
    #       print("      size:")
    #       print(" - ", images_list)
    #       print(" - ", params_list)
    #       print("\n Abort task!")
    #       goto exit_task
    #   }


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

    # La busqueda de centro dentro de una caja del tamaño del SEEING_FWHM
    delta_pix = seeing_pix
    # Asegurar una caja cuadrada:
    if(delta_pix % 2 == 0){delta_pix += 1}

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

        # seguimiento:
        print("\n ", id_obj[k])
        print(" XY0: ", x0[k], y0[k])

        n_grid = 0

        # Para recorrer los i-pixeles en X:
        tmp_xc = x0[k] - int(delta_pix / 2)

        for(i=1;i<=delta_pix;i+=1){

            tmp_yc = y0[k] - int(delta_pix / 2)

            # Para recorrer los j-pixeles en Y:
            for(j=1;j<=delta_pix;j+=1){

                n_grid += 1

                i_grid[n_grid] = tmp_xc
                j_grid[n_grid] = tmp_yc

                # seguimiento:
                print(" ", tmp_xc, tmp_yc)

                # Recortar la imagen alrededor del centro temporal:
                # Vertices del frame
                px1 = tmp_xc - int((xlen_min[k] - 1) / 2)
                px2 = tmp_xc + int((xlen_min[k] - 1) / 2)
                py1 = tmp_yc - int((ylen_min[k] - 1) / 2)
                py2 = tmp_yc + int((ylen_min[k] - 1) / 2)
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

                # Aplicar mascara (imagen segmentada):


                # Una transposicion = rotar 90 grados:
                tmp_infile = measure_img[k]//"[*,-*]"
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imtranspose(tmp_infile, tmp_outfile)
                # Segunda transposicion = 180 grados:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"//"[*,-*]"
                tmp_outfile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_180.fits"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imtranspose(tmp_infile, tmp_outfile)
                # Borrar la imagen a 90 grados:
                tmp_infile = cache_dir//"/"//id_obj[k]//"_"//i//j//"_90.fits"
                imdelete(tmp_infile, ver-, >& "dev$null")





                # next j-pixel:
                tmp_yc += 1

            #END FOR: y-pixels
            }

            # next i-pixel:
            tmp_xc += 1
        # END FOR: x-pixels
        }

        x0_min_abs = i_grid[1]
        y0_min_abs = j_grid[1]

        x0_min_rms = i_grid[1]
        y0_min_rms = j_grid[1]

        # seguimiento:
        print(" ", n_grid)

    # END FOR: k-objects list
    }




    exit_task:

    # print("Exit task.")
    print("\n END TASK: center_min")
    print("\n------------------------------------------")
    print("")
    beep

end
