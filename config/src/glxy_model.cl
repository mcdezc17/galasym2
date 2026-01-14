procedure glxy_model(inputlist, single_image)

string inputlist    = "objs_list"   {prompt = "list of objects"}
string key_sex      = "sex"         {prompt = "Keyword to run SExtractor"}
bool   single_image = yes           #{prompt = "one image?"}

begin
    # ************* Variables Definition *************
    # System variables
    int i, j, k
    struct line
    string my_date, my_time
    string expre
    bool re_run_bool
    # constants........
    real const_pi
    # Parameters:
    real scale_r_offset
    real scale_r[99]
    int r_measure
    int ri_ann[999], ro_ann[999]
    int lenght_nx, lenght_ny
    int xc[999], yc[999], xlen_min[999], ylen_min[999]
    real A_outer, B_outer
    string flag_size
    real pix_scale
    real tmp_ra[999], tmp_dec[999]
    # list of objects..
    int n_list, n_accepted
    string observed_img, measure_img
    string image_list[999], id_obj[999]
    int  seg_number[999]
    real ra_j00[999], dec_j00[999], ximg_pos[999], yimg_pos[999]
    real xwin_img[999], ywin_img[999], a_img[999], b_img[999]
    real ellip[999], theta_j00[999], theta_img[999], theta_rad[999]
    real petro_r[999], eff_r[999], kron_r[999]
    real iso_area[999], iso_areaf[999]
    # match list:
    real x0, y0

    # Temporal variables:
    int tmp_int
    string tmp_string, tmp_string2, tmp_string3, tmp_id_obj, tmp_image, tmp_infile, tmp_outfile, tmp_wait
    bool tmp_bool

    # ************* Main folders variables *************
    string config_dir
    string src_dir
    # -----------------------
    string data_dir
    string dataimg_dir
    string seg_dir, obs_dir, mod_dir, res_dir, bg_dir
    string datafiles_dir

    # ************* PRE-PSFEx variables *************
    string prepsfex_dir
    string config_prepsfex, param_prepsfex, conv_prepsfex, cat_prepsfex
    # PSFEx variables:
    string psfex_dir, config_psfex, outpsfex_dir, psf_fit
    # SExtractor variables:
    bool scndimg_bool
    string sex_dir, config_sex, param_sex, conv_sex
    string outsex_dir, cat_sex
    string segmen_img, smooth_img, bg_img, bgrms_img, model_img, residual_img, no_objs_img
    string list_cat_sex, list_models, list_bgrms_img, list_residual_img

    # ************* Cutout images variables *************
    int px1, px2, py1, py2, l_frame, side_frame[999]

    # ASIGNACIÓN DE DIRECTORIOS -------------------------
    # ./data: main output cut frames
    data_dir = "data"

    # ./data/images:
    dataimg_dir = data_dir//"/"//"data_images"
    # ./data/data_images/segmentation
    seg_dir = dataimg_dir//"/"//"segmentation"
    # ./data/data_images/observed
    obs_dir = dataimg_dir//"/"//"observed"
    # ./data/data_images/model
    mod_dir = dataimg_dir//"/"//"model"
    # ./data/data_images/residual
    res_dir = dataimg_dir//"/"//"residual"
    # ./data/data_images/background
    bg_dir = dataimg_dir//"/"//"background"
    # ./data/data_files:
    datafiles_dir = data_dir//"/"//"data_files"

    # ./config
    config_dir = "config"
    # ./config/src
    src_dir = config_dir//"/"//"src"

    # ./config/psfex
    psfex_dir = config_dir//"/"//"psfex"
    # ./config/psfex/prepsfex
    prepsfex_dir = psfex_dir//"/"//"prepsfex"
    # ./config/psfex/results_psfex
    outpsfex_dir = data_dir//"/"//"results_psfex"

    # ./config/sextractor
    sex_dir = config_dir//"/"//"sextractor"
    # ./config/sextractor/results_sex
    outsex_dir = data_dir//"/"//"results_sex"

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    # ro_ann[k] = 3.0
    scale_r_offset = 0.25
    pix_scale = 0.3

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (0.05 * (i-1))
    }

    config_sex = sex_dir//"/"//"default.sex"
    param_sex  = sex_dir//"/"//"default.param"
    conv_sex   = sex_dir//"/"//"filter.conv"

    segmen_img   = outsex_dir//"/"//"check_seg.fits"
    bg_img    = outsex_dir//"/"//"check_bg.fits"
    bgrms_img = outsex_dir//"/"//"check_bgrms.fits"
    smooth_img   = outsex_dir//"/"//"check_fil.fits"
    model_img   = outsex_dir//"/"//"check_mod.fits"
    residual_img   = outsex_dir//"/"//"check_res.fits"
    cat_sex   = outsex_dir//"/"//"test.cat"
    no_objs_img = outsex_dir//"/"//"check_no_objs.fits"

    tmp_bool = no

    print(" TASK: galaxy_model")

    if(single_image == yes){print(" image: list from single image")}
    else{print(" image: list from list of images")}

    # VERIFICAR QUE inputlist TIENE ACCESO:
    if(!access(inputlist)){
        print("\n ERR: not access to inputlist!")
        print("        call as:")
        printf("        - '%s' \n", inputlist)
    }

    # VERIFICAR SI EL inutlist ES DIFERENTE AL ESPERADO:
    tmp_string = datafiles_dir//"/"//"accepted_imgs.ascii"

    if(inputlist != tmp_string){
        print(" \n WRNNG: 'inputlist' is another")
        print("        that by default!")
    }
    # else{
    #    print("\n Using the 'inputlist' by default!")
    # }

    # LEER LOS OBJES DEL inputlist:
    delete(datafiles_dir//"/"//"not_imaccess_for_glxy_model.ascii", ver-, >& "dev$null")
    list = inputlist
    i = 0
    j = 0
    while(fscan(list, line) != EOF){
        if (line != "" && substr(line, 1, 1) != "#") {
            i = i + 1
            print(line) | scan(tmp_id_obj, tmp_string)

            if(!imaccess(tmp_string)){
                print(line, >> datafiles_dir//"/"//"not_imaccess_for_glxy_model.ascii")
            }else{
                j = j + 1
                id_obj[j] = tmp_id_obj
                image_list[j] = tmp_string
            }

        }
    }
    n_list = i
    n_accepted = j
    list = ""

    # AVISO SI NO SE ACCEDE A ALGUNAS IMAGENES
    if(n_accepted < n_list){
        print(" \n WRNNG: Can not access some images.")
        print("           Check the following file:  ")
        print("        - ", datafiles_dir//"/"//"not_imaccess_for_glxy_model.ascii")
        # si son pocos, imprimir:
        if(n_accepted > 0 && n_accepted < 6){
            for(k=1;k<=j;k+=1){
                printf(" - %s\n", image_list[k])
            }
        }else if(n_accepted > 0 && n_accepted > 6){
            for(k=1;k<=5;k+=1){
                printf(" - %s\n", image_list[k])
            }
            print(" - ... %d more", int(n_accepted - 5))
        }
    }
    printf("\n   - total lines: %d / accepted: %d \n", n_list, n_accepted)

    # VERIFICAR EXISTENCIA DE CARPETAS
    if(!access(data_dir)){mkdir(data_dir)}           # main output: ./data
    # ------------------------------------
    if(!access(dataimg_dir)){mkdir(dataimg_dir)}       # images folder:      ./data/images:
    if(!access(seg_dir)){mkdir(seg_dir)}
    if(!access(obs_dir)){mkdir(obs_dir)}               # observed images:    ./data/images/observed
    if(!access(mod_dir)){mkdir(mod_dir)}               # model images:       ./data/images/model
    if(!access(res_dir)){mkdir(res_dir)}               # residual images:    ./data/images/residual
    if(!access(bg_dir)){mkdir(bg_dir)}
    # ------------------------------------
    if(!access(datafiles_dir)){mkdir(datafiles_dir)}
    # ------------------------------------
    if(!access(outsex_dir)){mkdir(outsex_dir)}

    re_run_sex:

    list_cat_sex   = outsex_dir//"/"//"inlist.lis"
    list_models = data_dir//"/"//"sextracted.cat"
    # list_bgrms_img = datafiles_dir//"/"//"data_list_rms_img.ascii"
    # list_residual_img   = datafiles_dir//"/"//"data_list_residl_imgs.ascii"

    # Si no accede a los anteriores correr SExtractor
    if(!access(list_cat_sex)){

        # re_run_sex:

        # Impossible to run SEx if:
        if(!access(config_sex) || !access(param_sex) || !access(conv_sex)){
            print("\n WRNNG: incomplete configuration files")
            prnt("          for SExtractor run! Must exist:\n")
            print("         - 'default.sex' in 'config/sextractor/'")
            print("         - 'default.param'   (in same dir)")
            print("         - 'and filter.conv' (in same dir)")
            print(" Verify and run again.")
            goto exit_task
        }

        # EJECUTAR SEXTRACTOR PARA CADA IMAGEN VERIFICADA:
        # Si falla una imagen, colapsa para el resto!
        # print("! clear") | cl
        delete(segmen_img, ver-, >& "dev$null")
        delete(bg_img, ver-, >& "dev$null")
        delete(bgrms_img, ver-, >& "dev$null")
        delete(smooth_img, ver-, >& "dev$null")
        delete(model_img, ver-, >& "dev$null")
        delete(residual_img, ver-, >& "dev$null")
        delete(no_objs_img, ver-, >& "dev$null")
        delete(cat_sex, ver-, >& "dev$null")

        for(i=1; i<=n_accepted; i+=1){

            print("\n------------------------------------------")
            print("\n RUNNING SExtractor to model-fitting:\n")

            printf(" Process (sextracted image): %d/%d \n\n", i, n_accepted)

            measure_img = image_list[i]

            printf("! %s %s -c %s \n", key_sex, measure_img, config_sex) | cl

            sleep(1)

            rename(smooth_img,   obs_dir//"/"//id_obj[i]//"_smooth.fits")
            rename(segmen_img,   seg_dir//"/"//id_obj[i]//"_segmen.fits")
            rename(bg_img,       bg_dir//"/"//id_obj[i]//"_bg.fits")
            rename(no_objs_img,  bg_dir//"/"//id_obj[i]//"_no_objs.fits")
            rename(bgrms_img,    bg_dir//"/"//id_obj[i]//"_bgrms.fits")
            rename(model_img,    mod_dir//"/"//id_obj[i]//"_mod.fits")
            rename(residual_img, res_dir//"/"//id_obj[i]//"_res.fits")
            rename(cat_sex,      outsex_dir//"/"//id_obj[i]//"_test.cat")

        # END FOR RUNNING SExtractor
        }

    # SI EXISTE UN RESULTADO PREVIO:
    }else{

        tmp_bool = no
        print("\n  =>(Exists previuos results")
        print("     from SExtractor! 'yes' for")
        print("     DELETE and re-runing again,")
        printf("     or 'no' for keep it: ")
        scan(tmp_bool)

        if(tmp_bool == yes){

            delete(list_cat_sex, ver-, >& "dev$null")
            delete(list_models, ver-, >& "dev$null")

            goto re_run_sex

        }else{
            print("\n - No run SExtractor!\n")
        }
    # END ELSE
    }

    # ========================================================================
    # Ejecutar match y concatenacion de lista a pesar de no correr SExtractor:
    # ========================================================================
    print("\n------------------------------------------\n")
    re_run_match:

    list_models = data_dir//"/"//"sextracted.cat"

    if(!access(list_models)){

        # salida:
        delete(outsex_dir//"/"//"inlist.lis", ver-, >& "dev$null")

        for(i=1; i<=n_accepted; i+=1){

            # entrada:
            cat_sex = outsex_dir//"/"//id_obj[i]//"_test.cat"
            measure_img = image_list[i]

            # columna para identificador (# ID):
            printf("# ID\n %s\n", id_obj[i], > outsex_dir//"/"//"tmp_col_id.cat")

            # Calcula la mitad d ela imagen
            # captura el centro de la imagen:
            imgets(measure_img, "naxis1")
            x0 = (int(imgets.value) + 1) / 2
            imgets(measure_img, "naxis2")
            y0 = (int(imgets.value) + 1) / 2

            # STILTS > obj in center of image:
            expre = "! stilts tpipe ifmt=ascii ofmt=ascii cmd='addcol dist \"sqrt(($4-%.2f)*($4-%.2f) + ($5-%.2f)*($5-%.2f))\"; sorthead 1 dist' in=%s > %s/tmp_line.cat"
            printf(expre, x0, x0, y0, y0, cat_sex, outsex_dir, id_obj[i]) | cl

            # Agrega columna ID(col1_1):
            expre = "! stilts tjoin nin=2 ifmt1=ascii ifmt2=ascii in1=%s/tmp_col_id.cat in2=%s/tmp_line.cat ofmt=ascii out=%s/line_%s.cat"
            printf(expre, outsex_dir, outsex_dir, outsex_dir, id_obj[i]) | cl

            # imprime archivo que contiene la linea en una lista de (directorios) archivos
            printf("%s/line_%s.cat\n", outsex_dir, id_obj[i], >> outsex_dir//"/"//"inlist.lis")

            delete(outsex_dir//"/"//"tmp_col_id.cat", ver-, >& "dev$null")
            delete(outsex_dir//"/"//"tmp_line.cat", ver-, >& "dev$null")

            printf("\r - Process (center obj. match): %d%%", (i*100/n_accepted))

        # END FOR
        }

        # CONCATENACION
        delete(outsex_dir//"/"//"sextracted.cat", ver-, >& "dev$null")

        expre = "! awk 'FNR==1 && NR==1 {print; next} /^#/ {next} {print}' $(<%s/inlist.lis) > %s/sextracted.cat"
        printf(expre, outsex_dir, outsex_dir) | cl

        # Copiar para visualizar catalogo de modelos SEx:
        tmp_infile = outsex_dir//"/"//"sextracted.cat"
        tmp_outfile = data_dir//"/"//"sextracted.cat"
        delete(tmp_outfile, ver-, >& "dev$null")
        copy(tmp_infile, tmp_outfile)

        print("\n - Process (concat.): Ok.")

    # SI EXISTE UN RESULTADO PREVIO DE MATCH Y CONCATENACION:
    }else{

        tmp_bool = no
        print("\n  =>(Exists previuos results")
        print("     from MATCH! 'yes' for")
        print("     DELETE and re-runing again,")
        printf("     or 'no' for keep it: ")
        scan(tmp_bool)

        if(tmp_bool == yes){

            delete(list_models, ver-, >& "dev$null")
            print("")

            goto re_run_match

        }else{
            print("\n - No match & concat!")
            # goto exit_task
        }
    }

    # ========================================================================
    # Verificar tamaño de imagen (i.e. de las que ya vienen cortadas)
    # ========================================================================
    # input/output de wcsctran:
    # delete(outsex_dir//"/"//"list_wcstran.ascii", ver-, >& "dev$null")
    printf("#%31s %5d %5d\n", "ID", "Xc", "Yc", > outsex_dir//"/"//"xycenter_images.ascii")
    #delete(outsex_dir//"/"//"list_images.ascii", ver-, >& "dev$null")

    # cabecera regiones ds9:
    print("# Region file format: DS9 version 4.1", > datafiles_dir//"/"//"glxys_in_image.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> datafiles_dir//"/"//"glxys_in_image.reg")
    print("fk5", >> datafiles_dir//"/"//"glxys_in_image.reg")

    # leer resultados de SEx:
    list = outsex_dir//"/"//"sextracted.cat"
    k = 0
    while(fscan(list,line) != EOF){

        if(line != "" && substr(line,1,1) != "#" ){

            k = k + 1

            # Todas las imagenes derivan el tamaño de observacion:
            observed_img = image_list[k]

            # Tamaño de la imagen:
            imgets(observed_img, "naxis1")
            lenght_nx = int(imgets.value)
            imgets(observed_img, "naxis2")
            lenght_ny = int(imgets.value)

            # Los SEx-parametros de cada objeto [k]:
            # Se ajustara x/ywin_img -> x/yc ==> tmp_ra/dec[] -> ra/dec_j00[]
            print(line) | scan(id_obj[k], seg_number[k], tmp_ra[k], tmp_dec[k], xwin_img[k], ywin_img[k], a_img[k], b_img[k], ellip[k], theta_j00[k], theta_img[k], kron_r[k], petro_r[k], eff_r[k], iso_area[k], iso_areaf[k])

            # correcciones:
            petro_r[k] = petro_r[k] / 2
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[k] = theta_img[k] * const_pi / 180

            # el pixel mas cercano al SEx-centro:
            xc[k] = xwin_img[k]
            if((xwin_img[k] - xc[k]) >= 0.5){
                xc[k] = xc[k] + 1
            }
            # para y:
            yc[k] = ywin_img[k]
            if((ywin_img[k] - yc[k]) >= 0.5){
                yc[k] = yc[k] + 1
            }

            # Tamaño minimo aceptado para extraer cielo:
            A_outer = scale_r[46] * petro_r[k] * a_img[k] + 0.5
            B_outer = scale_r[46] * petro_r[k] * b_img[k] + 0.5
            # imagen que circunscribe la elipse rotada:
            xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
            ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
            # asegurar len_min entero impar:
            if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
            if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

            # Cumple tamaño minimo:
            if(lenght_nx >= xlen_min[k] && lenght_ny >= ylen_min[k]){

                # Puede cumplir el tamaño esperado:
                A_outer = scale_r[56] * petro_r[k] * a_img[k] + 0.5
                B_outer = scale_r[56] * petro_r[k] * b_img[k] + 0.5
                xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
                ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
                # asegurar len_min entero impar:
                if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
                if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

                # Asignar valores por defecto:
                if(lenght_nx >= xlen_min[k] && lenght_ny >= ylen_min[k]){
                    ri_ann[k] = 36
                    ro_ann[k] = 56
                }else{
                    # reduce el cielo
                    ri_ann[k] = 30
                    ro_ann[k] = 46
                }

            # Requere una imagen para extraer cielo
            }else{

                # Tamaño minimo para medida:
                A_outer = scale_r[26] * petro_r[k] * a_img[k] + 0.5
                B_outer = scale_r[26] * petro_r[k] * b_img[k] + 0.5
                xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
                ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
                # asegurar len_min entero impar:
                if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
                if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

                # Tamaño menor a medida:
                if(lenght_nx >= xlen_min[k] && lenght_ny >= ylen_min[k]){
                    # requiere imagen aparte del cielo:
                    ri_ann[k] = -1
                    ro_ann[k] = -1
                # No es posible medir
                }else{
                    ri_ann[k] = -1
                    ro_ann[k] = -1
                }
            #END condicional: verificacion de tamaño
            }

            # Tamaño minimo aceptado para extraer cielo:
            A_outer = scale_r[ro_ann[k]] * petro_r[k] * a_img[k] + 0.5
            B_outer = scale_r[ro_ann[k]] * petro_r[k] * b_img[k] + 0.5
            # imagen que circunscribe la elipse rotada:
            xlen_min[k] = 2 * sqrt((A_outer * cos(theta_rad[k]))**2 + (B_outer * sin(theta_rad[k]))**2)
            ylen_min[k] = 2 * sqrt((A_outer * sin(theta_rad[k]))**2 + (B_outer * cos(theta_rad[k]))**2)
            # asegurar len_min entero impar:
            if(xlen_min[k] % 2 == 0){xlen_min[k] = xlen_min[k] + 1}
            if(ylen_min[k] % 2 == 0){ylen_min[k] = ylen_min[k] + 1}

            # Centros de la imagen a transformar:
            # lista para wcstran:
            printf("%32s %5d %5d\n", id_obj[k], xc[k], yc[k], > outsex_dir//"/"//k//"_xycenter.ascii")
            # y para verificar (seguimiento):
            printf("%32s %5d %5d\n", id_obj[k], xc[k], yc[k], >> outsex_dir//"/"//"xycenter_images.ascii")

            # ============================================
            # WCSCTRAN: Transformar coordenadas X,Y -> RA,DEC
            # ============================================
            # CRÍTICO: Copiar imagen del array a variable simple ANTES de llamar wcsctran
            tmp_infile = outsex_dir//"/"//k//"_xycenter.ascii"
            tmp_outfile = outsex_dir//"/"//k//"_sky.ascii"

            # Escribir comando en script temporal
            printf("wcsctran(input='%s', output='%s', image='%s', inwcs='logical', outwcs='world', columns='2,3')\n", tmp_infile, tmp_outfile, observed_img) | cl

        # END if: lines no comentadas no vacias
        }
    #ENd WHILE: Lectura lista SEx
    }
    list = ""
    if(k != n_accepted){
        print(" WRNNG: the number of k-wcsctrans-")
        print("      formation is not as expected!")
        print("\n Pause process...")
        scan(tmp_wait)
    }

    # ============================================
    # Lectura de posiciones ajustadas:
    # ============================================
    # Cabecera de SKYcoord ajustadas
    printf("#%31s %12d %12d\n", "ID", "RA_c", "DEC_c", > outsex_dir//"/"//"skycenter_images.ascii")
    # Cabecera de parametros (ajustados) del modelo
    expre = "# ID SEG_ID RA DEC XCNTR_IMG YCNTR_IMG A_IMG B_IMG ELLIP PA THET_IMG KRON_R PETRO_R EFF_R ISO_A ISO_AF RI_ANN RO_ANN XMIN_LENG YMIN_LENG"
    print(expre, > outsex_dir//"/"//"params_to_index.ascii")

    for(i=1;i<=n_accepted;i+=1){

        list = outsex_dir//"/"//i//"_sky.ascii"

        while(fscan(list,line) != EOF){
            if(line != "" && substr(line,1,1) != "#"){

                print(line) | scan (id_obj[i], ra_j00[i], dec_j00[i])
                printf("%32s %12f %12f\n", id_obj[i], ra_j00[i], dec_j00[i], >> outsex_dir//"/"//"skycenter_images.ascii")

            # END IF: lineas validas
            }
        # END WHILE: lectura lista
        }
        list = ""

        # ----------------------------------------------
        # Imprimir catalogo de parametros del modelo (ajustados)
        # ----------------------------------------------
        print(id_obj[i], " ", seg_number[i], " ", ra_j00[i], " ", dec_j00[i], " ", xc[i], " ", yc[i], " ", a_img[i], " ", b_img[i], " ", ellip[i], " ", theta_j00[i], " ", theta_img[i], " ", kron_r[i], " ", petro_r[i], " ", eff_r[i], " ", iso_area[i], " ", iso_areaf[i], " ", ri_ann[i], " ", ro_ann[i], " ", xlen_min[i], " ", ylen_min[i], >> outsex_dir//"/"//"params_to_index.ascii")

        # ----------------------------------------------
        # Crear regiones DS9:
        # ----------------------------------------------
        # caja que inscribe la elipse rotada:
        expre = 'box('//ra_j00[i]//','//dec_j00[i]//','//(xlen_min[i] * pix_scale)//'",'//(ylen_min[i] * pix_scale)//'",360) # color=green  text={'//id_obj[i]//'}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
        # refrence (3A,3B) aperture: eliptical
        expre = 'ellipse('//ra_j00[i]//','//dec_j00[i]//','//str(3 * a_img[i] * pix_scale)//'",'//str(3 * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=green dash=1 text={SEx fit}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
        # elipse de un radio Petrosian (1 rp):
        expre = 'ellipse('//ra_j00[i]//','//dec_j00[i]//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={1}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
        # elipse de 1.5 rp:
        expre = 'ellipse('//ra_j00[i]//','//dec_j00[i]//','//str(1.5 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={1.5}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
        # elipse cielo int (ro_ann[k] = 2 rp):
        expre = 'ellipse('//ra_j00[i]//','//dec_j00[i]//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue text={2}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
        # elipse cielo ext (ro_ann[k] = 3 rp)
        expre = 'ellipse('//ra_j00[i]//','//dec_j00[i]//','//str(3 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(3 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue text={3rp}'
        print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")

        # Eliminar listas de transformacion WCSTRAN:
        delete(outsex_dir//"/"//i//"_xycenter.ascii", ver-, >& "dev$null")
        delete(outsex_dir//"/"//i//"_sky.ascii", ver-, >& "dev$null")

    # END FOR: recorrido de listas
    }

    # Copiar para visualizar por usuario
    tmp_infile = outsex_dir//"/"//"params_to_index.ascii"
    tmp_outfile = data_dir//"/"//"params_to_index.ascii"
    delete(tmp_outfile, ver-, >& "dev$null")
    copy(tmp_infile, tmp_outfile)

    # Copiar catalogo de regiones para visualizar:
    tmp_infile = datafiles_dir//"/"//"glxys_in_image.reg"
    tmp_outfile = data_dir//"/"//"glxys_in_image.reg"
    delete(tmp_outfile, ver-, >& "dev$null")
    copy(tmp_infile, tmp_outfile)

    exit_task:

    # print("Exit task.")
    print("\n END TASK: galaxy_model")
    print("\n------------------------------------------")
    print("")
    beep

end
