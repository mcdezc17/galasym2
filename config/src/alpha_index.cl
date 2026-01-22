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
    # constants........
    real const_pi
    # patrameters......
    string key_word
    real pixel_scale
    real hiblg_clip, hidsk_clip
    real scale_r_offset
    real scale_r[99]
    string ellip_expr
    # recorte de imagenes:
    real A_outer, B_outer
    int xlen_min[999], ylen_min[999]
    int px1, px2, py1, py2
    string trimsection

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
    string tmp_infile, tmp_outfile

    # nombre de imagenes:
    string observed_img[999], obs_setmask_img[999]
    string bgrms_img[999], model_img[999]
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

    clear

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (0.05 * (i-1))
    }

    if(strlwr(bulge_clip) == "off" && strlwr(disk_clip) != "off"){
        # Lee directorio como p.ej.: alpha_2.0_nn_10.0
        # NOTA: verificacion mas robusta del tipo de variable:
        hiblg_clip = 1.0e6                                           # Evita crear mas codigo abajo, pero no es lo mejor!
        hidsk_clip = real(disk_clip)
        # -
        if(hidsk_clip > 0 && hidsk_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_nn_%.1f\n", low_sigma, hidsk_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'disk_clip' out of range!")}

    }else if(strlwr(bulge_clip) != "off" && strlwr(disk_clip) == "off"){
        # Lee directorio como p.ej.: alpha_2.5_8.0_nn
        hiblg_clip = real(bulge_clip)
        hidsk_clip = 1.0e6                                            # Evita crear mas codigo abajo, pero no es lo mejor!
        # -
        if(hiblg_clip > 0 && hiblg_clip < 1.0e6){
            # lee directorio:
            printf("alpha_%.1f_%.1f_nn\n", low_sigma, hiblg_clip) | scan(alpha_dir)
        }else{print("\n ERR: 'bulge_clip' out of range!")}

    }else if(strlwr(bulge_clip) == "off" && strlwr(disk_clip) == "off"){
        # -
        hiblg_clip = 1.0e6
        hidsk_clip = 1.0e6
        # lee directorio:
        printf("alpha_%.1f_nn_nn\n", low_sigma) | scan(alpha_dir)
        # -
    }else{
        # -
        hiblg_clip = real(bulge_clip)
        hidsk_clip = real(disk_clip)
        #-
        # lee directorio:
        printf("alpha_%.1f_%.1f_%.1f\n", low_sigma, hiblg_clip, hidsk_clip) | scan(alpha_dir)
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

    print("\n START TASK: alpha_index")
    print("\n output folder: ", alpha_dir)

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
            bgrms_img[i]    = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
            #seguimiento:
            if(!imaccess(bgrms_img[i])){print("\n ERR: not access to bgrms img!"); goto exit_task}

            observed_img[i]    = observed_dir//"/"//id_obj[i]//".fits"
            #seguimiento:
            if(!imaccess(observed_img[i])){print("\n ERR: not access to observed img!"); goto exit_task}

            obs_setmask_img[i] = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"
            #seguimiento:
            if(!imaccess(obs_setmask_img[i])){print("\n ERR: not access to obs_setmask img!"); goto exit_task}

            model_img[i]       = model_dir//"/"//id_obj[i]//"_mod.fits"
            #seguimiento:
            if(!imaccess(model_img[i] )){print("\n ERR: not access to model img!"); goto exit_task}

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
                print("\n ", key_word, ": ", pixel_scale)
            }

        # END IF: lineas validas
        }
    # END WHILE: lectura lista
    }
    list = ""

    # ===============================================================
    # Recortar imagenes para realizar medida
    # ===============================================================

    if(!access(alpha_dir)){mkdir(alpha_dir)}
    if(!access(alphaimg_dir)){mkdir(alphaimg_dir)}
    if(!access(frames_dir)){mkdir(frames_dir)}
    if(!access(cache_dir)){mkdir(cache_dir)}

    # string areaglxy_img

    # Observed area for N total pixels:
    # printf(cache_dir//"/"//"area_%.1f_obs_"//"\n", low_clip) | scan(areaglxy_img)
    # Extended CENTER MASK for measure index (source + noise annulus):
    # centermodmask_img = cache_dir//"/"//"centermodelmask_"

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"

    for(i=1;i<=n_list;i+=1){

        # recortar las imagenes al cuadro minimo que encierre la elipse de medida (1.5rp)
        # De igual tamaño para todos los objetos:
        A_outer = scale_r[56] * petro_r[i] * a_img[i] + 0.5
        B_outer = scale_r[56] * petro_r[i] * b_img[i] + 0.5
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

        # Recortar imagenes a analizar (RESIDUAL):
        tmp_infile  = res_setmask_img[i]//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_residual.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)

        # Recorte de imagen BGRMS:
        tmp_infile  = bgrms_img[i]//trimsection
        tmp_outfile = frames_dir//"/"//id_obj[i]//"_bgrms.fits"
        imdelete(tmp_outfile, ver-, >& "dev$null")
        imcopy(tmp_infile, tmp_outfile, ver-)

        # Low area pixels (pixeles en el residuo >= low_sigma)
        imexpr("a*b >= c*e && a*b <= d*e", verb-)

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

    print("\n END TASK: alpha_index")
    print("\n------------------------------------------")
    print("")
    beep

end
