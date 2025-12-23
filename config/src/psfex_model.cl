procedure psfex_model(image_sample, default_conv)

string image_sample = "objs_list"      {prompt = "Image to psf-sample"}
string key_sex     = "sex"             {prompt = "Keyword to run SExtractor"}
bool   default_conv = no               {prompt = "Have a sample?"}

begin
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

    config_prepsfex = prepsfex_dir//"/"//"prepsfex.sex"
    param_prepsfex = prepsfex_dir//"/"//"prepsfex.param"
    conv_prepsfex = prepsfex_dir//"/"//"default.conv"
    cat_prepsfex = outpsfex_dir//"/"//"prepsfex.cat"

    config_psfex = psfex_dir//"/"//"default.psfex"

    if(default_conv == no){
        # Access to psf model (prepsfex.psf) omit PrePSFEx (SEx-prior) and PSFEx, if not:
        if(!access(psf_fit)){
            # Access to prepsfex catalog (prepsfex.cat [FITS_LDAC]) omit PrePSFEx, if not:
            if(!access(cat_prepsfex)){
                # Impossible to run PrePSFEx (SEx) prior to PSFEx if:
                if(!access(config_prepsfex) || !access(param_prepsfex) || !access(conv_prepsfex)){

                    print("\n WARNING: config-files for running Pre-PSFEx are incomplete!")
                    print("         At least the following files must exist: ")
                    print("         - prepsfex.sex     (in ./config/psfex/prepsfex/)")
                    print("         - prepsfex.param   (in same dir)")
                    print("         - and default.conv (in same dir)")
                    print(" Verify and run again.")
                    print(" Abort task!")
                    goto exit_task
                }

                # Running PrePSFEx (pre-psfex) prior to PSFEx
                print("-------------------------------------------------------------")
                print(" RUNNING SExtractor PRIOR PSFEx:\n")
                printf("! %s %s -c %s\n", key_sex, image_sample, config_prepsfex) | cl
                sleep(2)
                print("-------------------------------------------------------------")
                print("\n Was PrePSFEx by SExtractor well execute (?)\n")

            }
        }
    # DEFAULT PSF -------------------------------
    }else{

        print("\n Use the default file from")
        print(" SExtractor repository. Expe-")
        print(" rimental stuff!")

        # Crear carpeta resultados psfex:
        if(!access(outpsfex_dir)){mkdir(outpsfex_dir)}

        # Copiar el archivo or defecto:
        print("\n - copy 'config/sextractor/default.psf'")
        print("   to 'data/results_psfex/prepsfex.psf'")
        copy(sex_dir//"/"//"default.psf", outpsfex_dir//"/"//"prepsfex.psf")

    }

    exit_task:
end
