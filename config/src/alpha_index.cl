procedure alpha_index(center_rot, sky_imgs)

string center_rot = "rms" {prompt = "'abs' or 'rms' minimization"}
# Experimental stuff:
bool   sky_imgs   = no    {prompt = "'yes' usefull to experimental"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    # constants........
    real const_pi
    # patrameters......
    real scale_r_offset
    real scale_r[99]

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

    # nombre de imagenes:
    string observed_img[999], obs_setmask_img[999], model_img[999]
    string residual_img[999], res_setmask_img[999]

    # folder variables:
    string datafiles_dir
    string folder_sky
    string outsex_dir

    # direcciones de imagenes:
    string observed_dir, model_dir, residual_dir

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (0.05 * (i-1))
    }

    # ASIGNACIÓN DE DIRECTORIOS -------------------------
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"

    print("\n START TASK: alpha_index")

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
            observed_img[i]    = observed_dir//"/"//id_obj[i]//".fits"
            #seguimiento:
            if(!imaccess(observed_img[i])){print("\n ERR: not access to observed img!"); goto exit_task}

            obs_setmask_img[i] = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"
            #seguimiento:
            if(!imaccess(obs_setmask_img[i])){print("\n ERR: not access to obs_setmask img!"); goto exit_task}

            model_img[i]       = model_dir//"/"//id_obj[i]//"_mod.fits"
            #seguimiento:
            if(!imaccess(model_img[i] )){print("\n ERR: not access to model img!"); goto exit_task}

            residual_img[i]    = residual_dir//"/"//id_obj[i]//"_res.fits"
            #seguimiento:
            if(!imaccess(residual_img[i])){print("\n ERR: not access to residual img!"); goto exit_task}

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

    print("\n END TASK: alpha_index")
    print("\n------------------------------------------")
    print("")
    beep

end
