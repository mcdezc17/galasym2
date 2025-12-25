procedure glxy_model(inputlist)

string inputlist = "objs_list"   {prompt = "list of objects"}
string key_sex   = "sex"          {prompt = "Keyword to run SExtractor"}

begin
    # ************* Global variables *************
    # System variables
    string my_date, my_time
    bool re_run_bool
    struct line
    # list of objects..
    int n_list, n_accepted
    string image_list[999], id_obj[999]

    # Temporal variables:
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
    string seg_img, mod_img, res_img, bg_img, bgrms_img
    string list_cat_sex, list_bgrms_img, list_res_img

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
    config_sex = sex_dir//"/"//"default.sex"
    param_sex = sex_dir//"/"//"default.param"
    conv_sex = sex_dir//"/"//"filter.conv"

    seg_img = outsex_dir//"/"//"check_seg.fits"
    bgrms_img = outsex_dir//"/"//"check_bgrms.fits"
    bg_img = outsex_dir//"/"//"check_bg.fits"
    mod_img = outsex_dir//"/"//"check_mod.fits"
    res_img = outsex_dir//"/"//"check_res.fits"
    cat_sex = outsex_dir//"/"//"test.cat"

    tmp_bool = no

    print(" task: galaxy_model")



    # VERIFICAR QUE inputlist TIENE ACCESO:
    if(!access(inputlist)){
        print("\n ERR: no access to inputlist!")
        print("        call as:")
        printf("        - '%s' \n", inputlist)
    }

    # VERIFICAR SI EL inutlist ES DIFERENTE AL ESPERADO:
    tmp_string = datafiles_dir//"/"//"list_of_imgs.ascii"

    if(inputlist != tmp_string){
        print(" \n WRNNG: 'inputlist' is another")
        print("        that by default!")
    }else{
        print("\n Using the 'inputlist' by default!")
    }

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
    printf("\n   - total lines: %d / accepted: %d ", n_list, n_accepted)

    # VERIFICAR EXISTENCIA DE CARPETAS
    if(!access(data_dir)){mkdir(data_dir)}           # main output: ./data
    if(!access(datafiles_dir)){mkdir(datafiles_dir)}
    if(!access(outsex_dir)){mkdir(outsex_dir)}

    re_run_task:

    list_cat_sex   = datafiles_dir//"/"//"data_sextracted_inputlist.cat"
    list_bgrms_img = datafiles_dir//"/"//"data_list_rms_img.ascii"
    list_res_img   = datafiles_dir//"/"//"data_list_residl_imgs.ascii"

    # Si no accede a los anteriores correr SExtractor
    if(!access(list_cat_sex) && !access(list_bgrms_img) && !access(list_res_img)){

        # re_run_task:

        # Impossible to run SEx if:
        if(!access(config_sex) || !access(param_sex) || !access(conv_sex)){
            print("\n WRNNG: incomplete configuration files")
            prnt("          for SExtractor run! Must exist:\n")
            print("         - 'default.sex' in './config/sextractor/'")
            print("         - 'default.param'   (in same dir)")
            print("         - 'and filter.conv' (in same dir)")
            print(" Verify and run again.")
            goto exit_task
        }

        # EJECUTAR SEXTRACTOR PARA CADA IMAGEN VERIFICADA:
        # Si falla una imagen, colapsa para el resto!
        print("! clear") | cl
        print(" RUNNING SExtractor to model-fitting:\n")
        print("\n------------------------------------------")


        for(i=1; i<=n_accepted; i+=1){

            printf(" Process (sextracted image): %d/%d \n\n", i, n_accepted)

            printf("! %s %s -c %s \n", key_sex, measure_img, config_sex) | cl

            sleep(1)

            rename(bgrms_img, outsex_dir//"/"//id_obj[i]//"_check_bgrms.fits")
            rename(fil_img, outsex_dir//"/"//id_obj[i]//"_check_fil.fits")
            rename(mod_img, outsex_dir//"/"//id_obj[i]//"_check_mod.fits")
            rename(res_img, outsex_dir//"/"//id_obj[i]//"_check_res.fits")
            rename(cat_sex, outsex_dir//"/"//id_obj[i]//"_test.cat")

        }



    }else{

        tmp_bool = no
        print("\n Exists previuos results")
        print(" from SExtractor!")
        print("\n 'yes' for DELETE and re-runing")
        printf(" again, or 'no' for keep it: ")
        scan(tmp_bool)

        if(tmp_bool){

            delete(cat_sex, ver-, >& "dev$null")
            delete(bgrms_img, ver-, >& "dev$null")
            delete(res_img, ver-, >& "dev$null")

            goto re_run_task

        }else{
            print("\n Not changes apply!")
        }

    }

    exit_task:

    # print("Exit task.")
    print("\n End task: galaxy_model")
    print("\n------------------------------------------")
    print("")
    beep

end
