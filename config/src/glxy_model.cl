procedure glxy_model(inputlist, single_image)

string inputlist    = "objs_list"   {prompt = "list of objects"}
string key_sex      = "sex"         {prompt = "Keyword to run SExtractor"}
bool   single_image = yes           {prompt = "one image?"}

begin
    # ************* Global variables *************
    # Parameters:
    real ri_ann, ro_ann
    int lenght_nx, lenght_ny
    # System variables
    string my_date, my_time
    string expre
    bool re_run_bool
    struct line
    # list of objects..
    int n_list, n_accepted
    string observed_img, measure_img
    string image_list[999], id_obj[999]
    # match list:
    real x0, y0

    # Temporal variables:
    int tmp_int
    string tmp_string, tmp_id_obj
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

    # ./data/data_files
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
    ro_ann = 3.0

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
    if(!access(datafiles_dir)){mkdir(datafiles_dir)}
    if(!access(outsex_dir)){mkdir(outsex_dir)}

    re_run_sex:

    list_cat_sex   = outsex_dir//"/"//"inlist.lis"
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

        copy(outsex_dir//"/"//"sextracted.cat", data_dir//"/"//"sextracted.cat")

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

            goto re_run_match

        }else{
            print("\n - No match & concat!")
        }
    }

    # ========================================================================
    # :
    print("")

    # lectura de parametros ajustados por SEx:
    list = outsex_dir//"/"//"sextracted.cat"
    i = 0
    while(fscan(list, line) != EOF){
        if(line != "" && substr(line, 1, 1) != "#"){
            i = i + 1

            print(line) | scan(id_obj[i], seg_number[i], ra_j00[i], dec_j00[i], xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i])

            petro_r[i] = petro_r[i] / 2 # By default for SEx
        }
    }
    n_list = i

    # ciclo para verificar tamaños de imagenes:
    for(i=1; i<=n_list; i+=1){

        # directorio de check-images:
        observed_img = obs_dir//"/"//id_obj[i]//".fits"
        smooth_img   = obs_dir//"/"//id_obj[i]//"_smooth.fits"
        segmen_img   = seg_dir//"/"//id_obj[i]//"_segmen.fits"
        bg_img       = bg_dir//"/"//id_obj[i]//"_bg.fits"
        no_objs_img  = bg_dir//"/"//id_obj[i]//"_no_objs.fits"
        bgrms_img    = bg_dir//"/"//id_obj[i]//"_bgrms.fits"
        model_img    = mod_dir//"/"//id_obj[i]//"_mod.fits"
        residual_img = res_dir//"/"//id_obj[i]//"_res.fits"

        # Todas tienen el mismo tamaño que 'observed_img'.
        # - Vienen de una sola imagen: el mismo tamaño
        # - Viene de imagenes separadas, precaucion!
        imgets(observed_img, "naxis1")
        lenght_nx = int(imgets.value)
        imgets(observed_img, "naxis2")
        lenght_ny = int(imgets.value)

        # Lado del cuadrado a recortar (L = 2*4*1r/rp pix.)
        side_frame[i] = 2 * (ro_ann) * (petro_r[i] * a_img[i])

        if(lenght_nx < side_frame[i] && lenght_ny < side_frame[i]){



        }


        # Vertices del cuadrado:
        px1 = int(xwin_img[i] - (side_frame[i] / 2.0)) + 1
        px2 = int(xwin_img[i] + (side_frame[i] / 2.0))
        py1 = int(ywin_img[i] - (side_frame[i] / 2.0)) + 1
        py2 = int(ywin_img[i] + (side_frame[i] / 2.0))
        # Seccion a recortar:
        trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"
        #--------------------------------
    }





    exit_task:

    # print("Exit task.")
    print("\n END TASK: galaxy_model")
    print("\n------------------------------------------")
    print("")
    beep

end
#
# procedure glxy_model(inputlist, match_list, err_sky, pix_scale, single_image)
#    # ========================================================================
#    # Ejecutar match y concatenacion de lista a pesar de no correr SExtractor:
#    print("\n------------------------------------------\n")
#    re_run_match:
#
#    list_models = outsex_dir//"/"//"sextracted.cat"
#
#    if(!access(list_models)){
#
#        # verificar si exista la salida ya, para no rehacer!
#        # MATHC ENTRE OBJETOS DEL 'id_obj[i]_test.cat'
#        if(single_image == yes){
#
#            # salida:
#            delete(outsex_dir//"/"//"inlist.lis", ver-, >& "dev$null")
#
#            for(i=1; i<=n_accepted; i+=1){
#
#                cat_sex = outsex_dir//"/"//id_obj[i]//"_test.cat"
#
#                # STILTS > match RA/DEC inciales - SExtracted objs:
#                expre = "! stilts tskymatch2 in1=%s ifmt1=ascii in2=%s ifmt2=ascii ra1=RA dec1=DEC ra2=col2 dec2=col3 error=%.2f find=best ofmt=ascii out=%s/match_list.cat > /dev/null 2>&1\n"
#                printf(expre, match_list, cat_sex, err_sky, outsex_dir) | cl
#
#                # STILTS > se eliminan los RA/DEC iniciales - se asumen los SE-stimados:
#                expre ="! stilts tpipe cmd='delcols \"RA DEC\"' in=%s/match_list.cat ifmt=ascii ofmt=ascii out=%s/line_%s.cat"
#                printf(expre, outsex_dir, outsex_dir, id_obj[i]) | cl
#
#                # verificar que tenga una sola fila:
#                list = outsex_dir//"/"//"line_"//id_obj[i]//".cat"
#                j = 0
#                while(fscan(list, line)!= EOF){
#                    if (line != "" && substr(line, 1, 1) != "#"){
#                        j = j + 1
#                    }
#                }
#                if(j > 1){
#                    expre = "! stilts tpipe cmd='sorthead 1 Separation' ifmt=ascii ofmt=ascii in=%s > %s/tmp_one_line.ascii"
#                    printf(expre, list, outsex_dir)
#                    rename(outsex_dir//"/"//"tmp_one_line.ascii", list)
#                }
#
#                # imprime archivo que contiene la linea en una lista de (directorios) archivos
#                printf("%s/line_%s.cat\n", outsex_dir, id_obj[i], >> outsex_dir//"/"//"inlist.lis")
#
#                printf("\r - Process (skymatch stilts): %d%%", (i*100/n_accepted))
#
#            # END FOR
#            }
#
#        # single_image == NO:
#        }else{
#
#            # salida:
#            delete(outsex_dir//"/"//"inlist.lis", ver-, >& "dev$null")
#
#            for(i=1; i<=n_accepted; i+=1){
#
#                # entrada:
#                cat_sex = outsex_dir//"/"//id_obj[i]//"_test.cat"
#                measure_img = image_list[i]
#
#                # columna para identificador (# ID):
#                printf("# ID\n %s\n", id_obj[i], > outsex_dir//"/"//"tmp_col_id.cat")
#
#                # Radio de match entre objeto y modelo:
#                err_sky = err_sky / pix_scale
#
#                # Calcula la mitad d ela imagen
#                # captura el centro de la imagen:
#                imgets(measure_img, "naxis1")
#                x0 = (int(imgets.value) + 1) / 2
#                imgets(measure_img, "naxis2")
#                y0 = (int(imgets.value) + 1) / 2
#
#                # STILTS > obj in center of image:
#                expre = "! stilts tpipe ifmt=ascii ofmt=ascii cmd='addcol dist \"sqrt(($4-%.2f)*($4-%.2f) + ($5-%.2f)*($5-%.2f))\"; sorthead 1 dist' in=%s > %s/tmp_line.cat"
#                printf(expre, x0, x0, y0, y0, cat_sex, outsex_dir, id_obj[i]) | cl
#
#                # Agrega columna ID(col1_1):
#                expre = "! stilts tjoin nin=2 ifmt1=ascii ifmt2=ascii in1=%s/tmp_col_id.cat in2=%s/tmp_line.cat ofmt=ascii out=%s/line_%s.cat"
#                printf(expre, outsex_dir, outsex_dir, outsex_dir, id_obj[i]) | cl
#
#                # imprime archivo que contiene la linea en una lista de (directorios) archivos
#                printf("%s/line_%s.cat\n", outsex_dir, id_obj[i], >> outsex_dir//"/"//"inlist.lis")
#
#                delete(outsex_dir//"/"//"tmp_col_id.cat", ver-, >& "dev$null")
#                delete(outsex_dir//"/"//"tmp_line.cat", ver-, >& "dev$null")
#
#                printf("\r - Process (center obj. match): %d%%", (i*100/n_accepted))
#
#            # END FOR
#            }
#        }
