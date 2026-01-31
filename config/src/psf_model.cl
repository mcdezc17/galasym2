procedure psf_model()

# string image_sample = "objs_list"      {prompt = "Image to psf-sample"}
# string key_sex      = "sex"            {prompt = "Keyword to run SExtractor"}
# string key_psfex    = "psfex"          {prompt = "Keyword to run PSFEx"}
# bool   default_conv = no               {prompt = "Have a sample?"}
struct *list

begin

    # ************* Global variables *************
    # System variables
    string image_sample
    string key_word
    string my_date, my_time
    bool re_run_bool
    # Temporal variables:
    bool tmp_bool

    # PSET datapar
    string pathname_data
    # PSET sexpar
    string key_run_se
    # PSET psfex
    string key_run_psf
    bool defaultf_psf, same_img_psf
    string img_name_psf

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

    # temporal variables:
    string tmp_file, tmp_infile, tmp_outfile

    # KEY_WORD requeridas para ejecutar programas
    list = "full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # DATAPAR PSET -----------------------------------------------------------

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            # SEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_SE"){print(line) | scan(key_word, key_run_se)}

            # SEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_PSFEX"){print(line) | scan(key_word, key_run_psf)}

            if(key_word == "DFLT_PSF"){print(line) | scan(key_word, defaultf_psf)}

            if(key_word == "SAME_IMG"){print(line) | scan(key_word, same_img_psf)}

            if(key_word == "IMG_NAME"){print(line) | scan(key_word, img_name_psf)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    # Verificar si es la misma imagen usada para extraer estrellas:
    if(same_img_psf == yes){
        image_sample = pathname_data
    }else{
        image_sample = img_name_psf
    }

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

    config_prepsfex = prepsfex_dir//"/"//"my_prepsfex.sex"
    param_prepsfex = prepsfex_dir//"/"//"prepsfex.param"
    conv_prepsfex = prepsfex_dir//"/"//"default.conv"
    cat_prepsfex = outpsfex_dir//"/"//"prepsfex.cat"

    config_psfex = psfex_dir//"/"//"my_default.psfex"
    # psf_fit = outpsfex_dir//"/"//"prepsfex.psf"
    psf_fit = sex_dir//"/"//"my_prepsfex.psf"

    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    # printf("\n---- GALASYM2: %s at %s ----\n\n", my_date, my_time)
    print("\n------------------------------------------")
    print(" START TASK: psf_model")

    # Crear carpeta resultados psfex:
    if(!access(outpsfex_dir)){mkdir(outpsfex_dir)}

    # SI LA TAREA ES EJECUTADA EN MODO DEFAULT:
    # if(default_conv == no){

    # Access to psf model (prepsfex.psf) omit PrePSFEx (SEx-prior) and PSFEx, if not:
    if(!access(psf_fit)){

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
                bye
            }

            # Running PrePSFEx (pre-psfex) prior to PSFEx
            print("\n------------------------------------------")
            print(" RUNNING SExtractor PRIOR PSFEx:\n")
            printf("! %s %s -c %s\n", key_run_se, image_sample, config_prepsfex) | cl
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
           bye
       }
       # Running PSFEx
       print("\n------------------------------------------")
       print(" RUNNING PSFEx:\n")
       printf("! %s %s -c %s\n", key_run_psf, cat_prepsfex, config_psfex) | cl
       sleep(2)
       print("\n------------------------------------------")

       tmp_file = outpsfex_dir//"/"//"prepsfex.psf"

       if(!access(tmp_file)){

           # Was PSFEx well executed?
           print("\n ERR: PSF model wasn't created!")
           print(" WRNNG: force to use config/sextractor/default.psf")
           # Copiar resultado (prepsfex.psf) a carpeta de sextractor
           tmp_infile  = sex_dir//"/"//"default.psf"
           tmp_outfile = sex_dir//"/"//"my_prepsfex.psf"
           copy(tmp_infile, tmp_outfile)
           bye

       }else{

           # Copiar resultado (prepsfex.psf) a carpeta de sextractor
           tmp_infile  = outpsfex_dir//"/"//"prepsfex.psf"
           tmp_outfile = sex_dir//"/"//"my_prepsfex.psf"
           copy(tmp_infile, tmp_outfile)
       }

    }else{
        print("\n WRNNG: There is already a modeled PSF file.")
        print("         Delete it to create a new one.")
    }

    # print("Exit task.")
    print("\n END TASK: psf_model")
    print("\n------------------------------------------")
    print("")
    beep
end
