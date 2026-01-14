procedure find_center()

begin

    # ************* Variables Definition *************
    # System variables:
    int i
    struct line
    # constants........
    real const_pi
    # Parameters:
    real scale_r_offset
    real scale_r[99]
    int xc[999], yc[999], xlen_min[999], ylen_min[999]
    real A_outer, B_outer
    # list of objects:
    string params_list, images_list
    int n_list
    string observed_img[999]
    string id_obj[999]
    int  seg_number[999]
    real ra_j00[999], dec_j00[999], xc[999], yc[999]
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999], eff_r[999]
    real kron_r[999], iso_area[999], iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # temporals:
    string tmp_id_obj

    # Folder variables:
    string outsex_dir
    string datafiles_dir

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

        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""
    n_list = i

    # ==================================================
    # Leer la lista de imagenes (aceptadas-existentes?):
    # ==================================================
    list = images_list
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(tmp_id_obj, observed_img[i])

            # comprobacion (seguimiento):
            if(id_obj[i] != tmp_id_obj){
                print(" ERR: there  is no correlation")
                print("      in reading  images  list")
                print("      and SEx-parameters list!")
                print(" - ", images_list)
                print(" - ", params_list)
                print("\n Abort task!")
                list = ""
                goto exit_task
            }
        # END IF: lineas validas
        }
    # END WHILE: lectura de lista
    }
    list = ""
    # comprobacion de tamaños de listas:
    if(n_list != i){
        print(" ERR: the lists must be of equal")
        print("      size:")
        print(" - ", images_list)
        print(" - ", params_list)
        print("\n Abort task!")
        goto exit_task
    }

    # ==================================================
    #
    # ==================================================

    # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
    # Tamaño minimo para medida:
    A_outer = scale_r[26] * petro_r[k] * a_img[k] + 0.5
    B_outer = scale_r[26] * petro_r[k] * b_img[k] + 0.5
    xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
    ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
    # asegurar len_min entero impar:
    if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
    if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

    exit_task:

    # print("Exit task.")
    print("\n END TASK: center_min")
    print("\n------------------------------------------")
    print("")
    beep

end
