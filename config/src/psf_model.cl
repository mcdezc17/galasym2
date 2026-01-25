procedure psf_model(image_sample, default_conv)

string image_sample = "objs_list"      {prompt = "Image to psf-sample"}
string key_sex      = "sex"            {prompt = "Keyword to run SExtractor"}
string key_psfex    = "psfex"          {prompt = "Keyword to run PSFEx"}
bool   default_conv = no               {prompt = "Have a sample?"}

begin

    # ************* Global variables *************
    # System variables
    string my_date, my_time
    bool re_run_bool
    # Temporal variables:
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

    config_prepsfex = prepsfex_dir//"/"//"prepsfex.sex"
    param_prepsfex = prepsfex_dir//"/"//"prepsfex.param"
    conv_prepsfex = prepsfex_dir//"/"//"default.conv"
    cat_prepsfex = outpsfex_dir//"/"//"prepsfex.cat"

    config_psfex = psfex_dir//"/"//"default.psfex"
    psf_fit = outpsfex_dir//"/"//"prepsfex.psf"

    # re_run_bool = no

    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    # printf("\n---- GALASYM2: %s at %s ----\n\n", my_date, my_time)
    print(" START TASK: psf_model")

    # Crear carpeta resultados psfex:
    if(!access(outpsfex_dir)){mkdir(outpsfex_dir)}

    # SI LA TAREA ES EJECUTADA EN MODO DEFAULT:
    if(default_conv == no){

        # re_run_task:

        # Access to psf model (prepsfex.psf) omit PrePSFEx (SEx-prior) and PSFEx, if not:
        if(!access(psf_fit)){

            #re_run_task:

            # Access to prepsfex catalog (prepsfex.cat [FITS_LDAC]) omit PrePSFEx, if not:
            if(!access(cat_prepsfex)){
                # Impossible to run PrePSFEx (SEx) prior to PSFEx if:
                if(!access(config_prepsfex) || !access(param_prepsfex) || !access(conv_prepsfex)){

                    print("\n ERR: impossible runing pre-PSFEx!")
                    print("        SExtractor. Exists?: ")
                    print("         - prepsfex.sex     (in ./config/psfex/prepsfex/)")
                    print("         - prepsfex.param   (in same dir)")
                    print("         - and default.conv (in same dir)")
                    print(" Verify and run again.")
                    print(" Abort task!")
                    goto exit_task
                }

                # Running PrePSFEx (pre-psfex) prior to PSFEx
                print("\n------------------------------------------")
                print(" RUNNING SExtractor PRIOR PSFEx:\n")
                printf("! %s %s -c %s\n", key_sex, image_sample, config_prepsfex) | cl
                sleep(2)
                print("\n------------------------------------------")

            }

            printf("\n Exists PrePSFEx catalog (FITS_LDAC). Reading: %s\n\n", cat_prepsfex)

            # Impossible to run PSFEx if:
           if(!access(config_psfex)){
               print("\n ERR: imposible run PSFEx! The-")
               print("        following files must exist: ")
               print("\n        - default.sex (in ./config/psfex/)")
               print(" Abort task!")
               goto exit_task
           }
           # Running PSFEx
           print("\n------------------------------------------")
           print(" RUNNING PSFEx:\n")
           printf("! %s %s -c %s\n", key_psfex, cat_prepsfex, config_psfex) | cl
           sleep(2)
           print("\n------------------------------------------")

           if(!access(psf_fit)){
               # Was PSFEx well executed?
               print(" ERR: PSF model wasn't created!")
               goto exit_task
           }

        }

        # if(re_run_bool == no){
        #     printf(" \n Exists PSF model: \n   - %s\n\n", psf_fit)
        #     print(" 'yes' for DELETE and re-run PSFEx?")
        #     printf(" Or 'no' for keeping this?: ")
        #     scan(tmp_bool)
        #
        #     if(tmp_bool == yes){
        #         delete(psf_fit, ver-, >& "dev$null")
        #         re_run_bool = yes
        #         goto re_run_task
        #     }
        #
        # }

    # DEFAULT PSF (default_conv == yes)-------------------------------
    }else{

        print("\n Use the default file from")
        print(" SExtractor repository. Expe-")
        print(" rimental stuff!")

        # Copiar el archivo por defecto:
        print("\n - copy"
        print("       'config/sextractor/default.psf'")
        print("   to ")
        print("     'data/results_psfex/prepsfex.psf'")
        copy(sex_dir//"/"//"default.psf", outpsfex_dir//"/"//"prepsfex.psf")

    }

    exit_task:

    # print("Exit task.")
    print("\n END TASK: psf_model")
    print("\n------------------------------------------")
    print("")
    beep
end
