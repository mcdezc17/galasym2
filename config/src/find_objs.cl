procedure find_objs()

string initpos_alt = ""
struct *list

begin

    # ************* DEFINICIÓN DE VARIABLES *************
    # System variables
    int i
    struct line
    string key_word
    real const_pi
    real scale_r_offset, scale_r_step
    real scale_r[99]

    # parametros locales (globales)
    real scale_kp_arsec
    string expre
    real margen_offset
    # pset exp_pset
    string kw_python
    # temporals
    string tmp_file, tmp_infile, tmp_infile2, tmp_outfile
    bool tmp_bool
    string tmp_string, tmp_string2
    int tmp_int, tmp_int2

    # Parametros de lista de objtos a analizar:
    string id_obj[999]
    real ximg_pos[999], yimg_pos[999]
    real find_x[999], find_y[999]
    int n_list, n_accepted
    # effective image:
    real tmp_xc[10], tmp_yc[10], tmp_xside[10], tmp_yside[10]
    int x_limit[10], y_limit[10]
    # recorte de imagenes:
    int px1, px2, py1, py2, l_frame, side_frame[999]
    int xc, yc
    string trimsection

    # pset_datapar
    bool single_data
    string pathname_data, initpos_data
    real imagecut_data
    struct cosmopar_data
    string tformat_data, tcoord_data
    int xlenght_data, ylenght_data

    # pset photometry
    real pix_scal_phot

    # PSET psfex
    string key_run_psf
    bool defaultf_psf, same_img_psf
    string img_name_psf
    # local Params
    string extract_img

    # PSET sexpar
    string key_run_se
    real fit_xc, fit_yc
    # local params:
    string tmp_id_obj
    int seg_number
    real tmp_ra, tmp_dec, xwin_img, ywin_img
    real a_img, b_img, ellip, theta_j00
    real theta_img, theta_rad, petro_r
    int iso_areaf
    # ajuste de imagenes
    real A_outer, B_outer
    int xlen_min, ylen_min
    int ri_ann, ro_ann

    # otras carpetas:
    string datafiles_dir
    string outsex_dir

    # direcciones de imagenes:
    string observed_dir, bckgrnd_dir, segmen_dir
    string model_dir, residual_dir

    # ==================================================
    # TITULO DE BIENVENIDA:
    # ==================================================
    print(" ------------------------------------------")
    print(" START TASK: check_objs")

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    bckgrnd_dir  = "data/data_images/background"
    segmen_dir   = "data/data_images/segmentation"
    model_dir    = "data/data_images/model"
    residual_dir = "data/data_images/residual"

    # Declaracion de variables locales:
    const_pi = 3.1415926535897932385
    margen_offset = 0.03
    scale_r_offset = 0.25
    scale_r_step = 0.05

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (scale_r_step * (i-1))
    }

    # KEY_WORD requeridas para ejecutar programas
    list = "full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # DATAPAR PSET -----------------------------------------------------------

            if(key_word == "SINGLE_TYPE"){print(line) | scan(key_word, single_data)}

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            if(key_word == "INIT_POS"){print(line) | scan(key_word, initpos_data)}

            if(key_word == "CUT_IMG"){print(line) | scan(key_word, imagecut_data)}

            if(key_word == "T_FORMAT"){print(line) | scan(key_word, tformat_data)}

            if(key_word == "T_COORD"){print(line) | scan(key_word, tcoord_data)}

            if(key_word == "NAXIS1"){print(line) | scan(key_word, xlenght_data)}

            if(key_word == "NAXIS2"){print(line) | scan(key_word, ylenght_data)}

            if(key_word == "COSMOPAR"){print(line) | scan(key_word, cosmopar_data)}

            # PHOTOMERY PSET --------------------------------------------------------

            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pix_scal_phot)}

            # SEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_SE"){print(line) | scan(key_word, key_run_se)}

            # PSFEXPAR PSET --------------------------------------------------------

            if(key_word == "KW_PSFEX"){print(line) | scan(key_word, key_run_psf)}

            if(key_word == "DFLT_PSF"){print(line) | scan(key_word, defaultf_psf)}

            if(key_word == "SAME_IMG"){print(line) | scan(key_word, same_img_psf)}

            if(key_word == "IMG_NAME"){print(line) | scan(key_word, img_name_psf)}

            # EXPERIMENTAL PSET -----------------------------------------------------

            if(key_word == "KW_PYTHON"){print(line) | scan(key_word, kw_python)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    if(initpos_alt != ""){
        if(access(initpos_alt)){
            initpos_data = initpos_alt
        }
    }

    # DIRECTRIOS A USAR:
    if(!access("data")){mkdir("data")}
    # directorio de archivos:
    if(!access("data/data_files")){mkdir("data/data_files")}
    # Recortes de imagenes observadas:
    if(!access("data/data_images")){mkdir("data/data_images")}
    if(!access("data/data_images/observed")){mkdir("data/data_images/observed")}

    # IDENTIFICAR OBJETOS SI LA IMAGEN DE ENTRADA ES UNA SOLA:
    if(single_data == yes){
        # Calcular el valor de escala kp/arcsec:
        tmp_file = "config/src/"//"ned_calc.py"
        printf("! %s %s %s\n", kw_python, tmp_file, cosmopar_data) | cl | scan(scale_kp_arsec)

        # Transformar coordenadas SKY a IMG de posiciones iniciales:
        # Requiere transformar formato?
        # espacio para transformar formato: if(tcoord_data != "ascii"){TRANSFORMAR A 'SSV'}

        # SI NO TIENE IDENTIFICADOR: CREAR COLUMNA DE ID:
        # Espacio para crear columna.

        # Si la tabla de posiciones iniciales esa dada en grados
        if(tcoord_data == "deg"){
            tmp_infile = initpos_data
            tmp_outfile = "data/data_files/"//"xyimg_initpos.txt"
            wcsctran(tmp_infile, tmp_outfile, pathname_data, inwcs="world", outwcs="logical", columns="2,3")
        }else if(tcoord_data == "image"){
            tmp_infile = initpos_data
            tmp_outfile = "data/data_files/"//"xyimg_initpos.txt"
            copy(tmp_infile, tmp_outfile)
        }

        # REGION DE IMAGEN EFECTIVA:
        tmp_file = "data/data_files/"//"effective_image.reg"
        # Si no existe, correr como "primera vez"
        if(!access(tmp_file)){

            # cabecera de las siguientes regiones DS9 (version 4.1)
            print('global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', > tmp_file)
            print("image", >> tmp_file)

            # crear apertura de objetos PELIGROSOS (FUERA DE IMAGEN EFECTIVA)
            list = "data/data_files/"//"xyimg_initpos.txt"
            i = 0
            while(fscan(list,line) != EOF){
                if(line != "" && substr(line,1,1) != "#"){
                    i += 1
                    print(line) | scan(id_obj[i], find_x[i], find_y[i])
                    # Posiciones potencialmente peligrosos: fuera de imagen efectiva
                    if(find_x[i] <= (xlenght_data * margen_offset) || find_x[i] >= (xlenght_data - (xlenght_data * margen_offset)) || find_y[i] <= (ylenght_data * margen_offset) || find_y[i] >= (ylenght_data - (ylenght_data * margen_offset))){

                        # Objeto fuera de imagen:
                        expre = 'circle('//str(find_x[i])//','//str(find_y[i])//','//str(30 / (scale_kp_arsec * pix_scal_phot))//') # color=red width=2 text={'//str(id_obj[i])//'}'
                        print(expre, >> tmp_file)

                    }else{
                        # Objeto dentro de imagen:
                        expre = 'circle('//str(find_x[i])//','//str(find_y[i])//','//str(10 / (scale_kp_arsec * pix_scal_phot))//') # color=green width=2 text={'//str(id_obj[i])//'}'
                        print(expre, >> tmp_file)
                    }
                # END IF: lineas validas
                }
            # END WHILE: lectura de lista
            }
            list = ""

            # Regiones rectangulares de imagen efectiva:
            # Cuadro 1 (VERDE):
            expre = "box("//str((xlenght_data + 1) / 2.0)//","//str((ylenght_data + 1) / 2.0)//","//str(xlenght_data - (margen_offset * 2.0 * xlenght_data))//","//str(ylenght_data - (margen_offset * 2.0 * ylenght_data))//",360) # widht=2"
            print(expre, >> tmp_file)
            # Cuadro 2 (AGENTA):
            expre = "box("//str((xlenght_data + 1) / 2.0)//","//str((ylenght_data + 1) / 2.0)//","//str(xlenght_data - ((margen_offset + 0.01) * 2.0 * xlenght_data))//","//str(ylenght_data - ((margen_offset + 0.01) * 2.0 * ylenght_data))//",360) # color=magenta widht=2"
            print(expre, >> tmp_file)

            # Copiar a carptea local para visualizar:
            tmp_infile = tmp_file
            tmp_outfile = "to_edit_effective_image.reg"
            copy(tmp_infile, tmp_outfile)
        # ENF IF: like first time (effective image)
        }

        tmp_file = "data/data_files/"//"edited_effective_image.reg"
        if(!access(tmp_file)){

            print("\n +--------------------------------------------+")
            print(" | Pause to edit DS9 effective region image.  |")
            print(" | In your local directory see the file:      |")
            print(" |                                            |")
            print(" | - ./to_edit_effective_image.reg            |")
            print(" |                                            |")
            print(" | i) Edit the BOXES (green and magenta) that |")
            print(" | enclose your objects of interest.          |")
            print(" |                                            |")
            print(" | ii) Make sure to save AT LEAST the boxes,  |")
            print(" | OR BETTER YET, select 'region>all' and     |")
            print(" | 'region>save selection' in:                |")
            print(" |    - FORMAT: ds9                           |")
            print(" |    - COORDINATE SYSTEM: image              |")
            print(" +--------------------------------------------+")
            print("")
            tmp_bool = no
            while(tmp_bool == no){
                printf("\r Input 'y' to continue? (y/n): ")
                scan(tmp_bool)
            }

            tmp_infile = "to_edit_effective_image.reg"
            tmp_outfile = "data/data_files/"//"edited_effective_image.reg"
            copy(tmp_infile, tmp_outfile)

            # tmp_infile = "data/data_files/"//"effective_image.reg"
            # delete(tmp_infile, , ver-, >& "dev$null")
            tmp_infile = "to_edit_effective_image.reg"
            delete(tmp_infile, , ver-, >& "dev$null")
        # END IF: access to edited effective_image
        }
        print("")

        # Otener el centro y los lados de la region efectiva:
        expre = "! awk '/^box\\(/ {split($0,a,\"[(),]\"); print a[2],a[3],a[4],a[5]}' %s >> %s\n"
        tmp_infile = "data/data_files/"//"edited_effective_image.reg"
        tmp_outfile = "data/data_files/"//"boxes_effective_img.txt"
        print("# Two boxes to enclose effective region\n#XC     YC     XLEN     YLEN", > tmp_outfile)
        printf(expre, tmp_infile, tmp_outfile) | cl
        # Leer los parametros de las cajas efectivas:
        list = tmp_outfile
        i = 0
        while(fscan(list, line) != EOF){
            if (line != "" && substr(line, 1, 1) != "#") {
                i += 1
                print(line) | scan(tmp_xc[i], tmp_yc[i], tmp_xside[i], tmp_yside[i])
            }
        }
        list = ""

        # esquina inferior izquiera
        x_limit[1] = tmp_xc[1] - (tmp_xside[1] / 2.0)
        y_limit[1] = tmp_yc[1] - (tmp_yside[1] / 2.0)
        # esquina inferior derecha
        x_limit[2] = tmp_xc[1] + (tmp_xside[1] / 2.0)
        y_limit[2] = tmp_yc[1] + (tmp_yside[1] / 2.0)
        # esquina superior izquierda
        x_limit[3] = tmp_xc[2] - (tmp_xside[2] / 2.0)
        y_limit[3] = tmp_yc[2] - (tmp_yside[2] / 2.0)
        # esquina superior derecha
        x_limit[4] = tmp_xc[2] + (tmp_xside[2] / 2.0)
        y_limit[4] = tmp_yc[2] + (tmp_yside[2] / 2.0)

        # OBJETOS QUE ESTAN DENTRO DE IMAGEN EFECTIVA
        tmp_infile = "data/data_files/"//"xyimg_initpos.txt"
        tmp_outfile = "data/data_files/"//"objs_in_eff_img.txt"
        delete(tmp_outfile, ver-, >& "dev$null")
        expre = "\"(($2 > %g && $2 < %g) && ($3 > %g && $3 < %g)) || (($2 > %g && $2 < %g) && ($3 > %g && $3 < %g))\""
        printf("! stilts tpipe in=%s ifmt=ascii cmd='select "//expre//"' ofmt=ascii out=%s", tmp_infile, x_limit[1], x_limit[2], y_limit[1], y_limit[2], x_limit[3], x_limit[4], y_limit[3], y_limit[4], tmp_outfile) | cl

        # RECORTAR IMAGENES (en kiloparsecs):
        list = "data/data_files/"//"objs_in_eff_img.txt"
        i = 0
        while(fscan(list, line) != EOF){
            if (line != "" && substr(line, 1, 1) != "#") {
                i += 1
                print(line) | scan(id_obj[i], ximg_pos[i], yimg_pos[i])
            }
        }
        list = ""
        n_list = i

        # Encabezados de las salidas (imagenes recortadas):
        printf("#%31s %s\n", "ID", "PATH_IMAGE", > "data/data_files/accepted_imgs.txt")
        # Encabezados de las salidas (seccion de la imagen grande):
        printf("#%31s %s\n", "ID", "TRIMSECTION", > "data/data_files/trimsection_imgs.txt")

        for(i = 1; i <= n_list; i += 1){

            # Tamaño de la imagen ('imagecut_data' en kiloparsecs):
            side_frame[i] = imagecut_data / (scale_kp_arsec * pix_scal_phot)

            # Asgurar 'side_frame' entero positivo impar:
            if(side_frame[i] % 2 == 0){
                side_frame[i] = side_frame[i] + 1
            }

            # Centro entero más cercano al sub-pixel estimado
            xc = ximg_pos[i]
            if((ximg_pos[i] - xc) >= 0.5){
                xc += 1
            }
            # para y:
            yc = yimg_pos[i]
            if((yimg_pos[i] - yc) >= 0.5){
                yc += 1
            }

            # Vertices del recorte
            px1 = xc - int((side_frame[i] - 1) / 2)
            px2 = xc + int((side_frame[i] - 1) / 2)
            py1 = yc - int((side_frame[i] - 1) / 2)
            py2 = yc + int((side_frame[i] - 1) / 2)
            # Seccion a recortar:
            trimsection = "["//str(px1)//":"//str(px2)//","//str(py1)//":"//str(py2)//"]"

            tmp_file = "data/data_images/observed/"//id_obj[i]
            if(!imaccess(tmp_file)){
                imcopy(pathname_data//trimsection, tmp_file, verb-)
            }

            # Imprimir catalogos:
            tmp_infile = tmp_file//".fits"
            tmp_outfile = "data/data_files/accepted_imgs.txt"
            printf("%32s %s\n", id_obj[i], tmp_infile, >> tmp_outfile)
            # Imprimir catalogos:
            tmp_infile = trimsection
            tmp_outfile = "data/data_files/trimsection_imgs.txt"
            printf("%32s %s\n", id_obj[i], tmp_infile, >> tmp_outfile)

            # Progress bar proccess:
            printf("\r Process (cutting images): %d%%", (i*100/n_list))

        # END FOR: recorte de imagenes
        }
        print("")

    # END IF: single_image=yes
    }else{

        # SI LAS IMAGENES ESTAN SEPARADAS EN UNA CARPETA =========================

        # Archivo para enlistar imagenes separadas en 'folder=pathname_data':
        tmp_infile = "data/data_files/input_imgs.txt"
        delete(tmp_infile, ver-, >& "dev$null")
        # Encabezados de las salidas (imagenes validas):
        printf("#%31s %s\n", "ID", "PATH_IMAGE", > "data/data_files/accepted_imgs.txt")
        # Encabezados de las salidas (imagnes no validas):
        printf("#%31s %s\n", "ID", "PATH_IMAGE", > "data/data_files/not_imaccess.txt")

        # Enlistar los archivos:
        tmp_outfile = "data/data_files/input_imgs.txt"
        files(pathname_data//"/*.fits", sort+, >> tmp_outfile)

        # leer la lista anterior y verificar que imaccess tiene acceso (por ahora?):
        list = "data/data_files/input_imgs.txt"
        i = 0
        j = 0
        while(fscan(list, line) != EOF){
            if (line != "" && substr(line, 1, 1) != "#") {

                i += 1

                print(line) | scan(tmp_string2)

                # Extraer nombre del path. Carpeta contenedora:
                tmp_int = strldx("/", tmp_string2)
                if(tmp_int == 0){tmp_int = 1}
                # Elimina extension:
                tmp_int2 = stridx(".*", tmp_string2)
                if(tmp_int2 == 0 || tmp_int2 <= tmp_int){tmp_int2 = 0}
                # Nombre de imagen:
                tmp_string = substr(tmp_string2, (tmp_int + 1), (tmp_int2 - 1))
                # No existe ni '/' ni '.' ?
                if(tmp_int == 0 || tmp_int2 == 0){
                    tmp_string = "ERR_NAME?"
                }

                if(!imaccess(tmp_string2)){

                    tmp_outfile = "data/data_files/not_imaccess.txt"
                    printf("%32s %s\n", tmp_string, tmp_string2, >> tmp_outfile)

                }else{
                    # contador de imagenes aceptadas en la carpeta:
                    j += 1

                    tmp_outfile = "data/data_files/accepted_imgs.txt"
                    printf("%32s %s\n", tmp_string, tmp_string2, >> tmp_outfile)
                }

            # END IF: lineas validas
            }
        # END WHILE: lectura de lista
        }
        list = ""
        n_list = i
        n_accepted = j

        if(n_accepted < n_list){
            print(" \n WRNNG: Can not access some images.")
            print("           Check the following file:  ")
            print("\n  - data/data_files/not_imaccess.txt")
        }
        printf("\n - total images: %d / accepted: %d ", n_list, n_accepted)

    # END ELSE: lista de imagenes en una carpeta
    }

    # ==================================================
    # PSFExtractor SPACE
    # ==================================================
    print(" ------------------------------------------")
    print(" ============= PSF MODELING ===============")

    # Crear directorio de salida:
    # 'find_objs' ya verifica existencia de carpeta 'data':
    if(!access("data/results_psfex")){mkdir("data/results_psfex")}

    # Verificar si es la misma imagen usada para extraer estrellas:
    if(same_img_psf == yes){
        extract_img = pathname_data
    }else{
        extract_img = img_name_psf
    }

    # Si NO usa la PSF por defecto de PSFEx, Modela una:
    if(defaultf_psf == no){

        # Access to psf model (prepsfex.psf) omit PrePSFEx (SEx-prior) and PSFEx, if not:
        tmp_infile = "data/results_psfex/my_prepsfex.psf"
        if(!access(tmp_infile)){

            # Access to prepsfex catalog (prepsfex.cat [FITS_LDAC]) omit PrePSFEx, if not:
            tmp_infile = "data/results_psfex/my_prepsfex.cat"
            if(!access(tmp_infile)){

                # Impossible to run PrePSFEx (SEx) prior to PSFEx if:
                tmp_infile = "config/psfex/prepsfex/my_prepsfex.sex"
                if(!access(tmp_infile)){

                    print("\n ERR: impossible runing pre-PSFEx!")
                    print("        SExtractor. Exists?: ")
                    print("         - ./config/psfex/prepsfex/*.sex")
                    print(" Verify and run again.")
                    print(" Abort task!")
                    bye

                # Running PrePSFEx (pre-psfex) prior to PSFEx
                }else{

                    print(" ------------------------------------------")
                    print(" RUNNING SExtractor PRIOR PSFEx...")
                    printf("! %s %s -c %s\n", key_run_se, extract_img, tmp_infile) | cl
                }
            }

            # Impossible to run PSFEx if:
            tmp_infile = "config/psfex/my_default.psfex"
            if(!access(tmp_infile)){

                print("\n ERR: imposible run PSFEx! The-")
                print("        following files must exist: ")
                print("\n        - *.sex (in ./config/psfex/)")
                print(" Abort task!")
                bye

            # Running PSFEx
            }else{
                tmp_infile2 = "data/results_psfex/my_prepsfex.cat"
                print(" ------------------------------------------")
                print(" RUNNING PSFEx:\n")
                printf("! %s %s -c %s\n", key_run_psf, tmp_infile2, tmp_infile) | cl
                print(" ------------------------------------------")
            }

        # END IF: verificacion mypsf_model.psf
        }else{
            print("\n There is already a modeled PSF file.")
            print(" Delete it an run again to create a new one.")
        }

    # END IF: verificacion modo default.psf
    }

    # print(" END TASK: psf_model")

    # ==================================================
    # END OF PSFEx SPACE
    # ==================================================

    # ==================================================
    # SExtractor SPACE:
    # ==================================================
    print(" ------------------------------------------")
    print(" =========== GALAXY PHOTOMETRY ============")
    print(" =========== AND MODEL FITTING ============")

    # Crear directorios de salida:
    # 'find_objs' crea la carpeta results:
    if(!access(outsex_dir)){mkdir(outsex_dir)}
    # 'find_objs' crea la carpeta data/data_images[/observed]
    if(!access(bckgrnd_dir)){mkdir(bckgrnd_dir)}
    if(!access(segmen_dir)){mkdir(segmen_dir)}
    if(!access(model_dir)){mkdir(model_dir)}
    if(!access(residual_dir)){mkdir(residual_dir)}

    # limpieza de achivos residuales
    delete(outsex_dir//"/check_fil.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_seg.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_bg.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_no_objs.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_bgrms.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_mod.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/check_res.fits", ver-, >& "dev$null")
    delete(outsex_dir//"/test.cat", ver-, >& "dev$null")

    # Archivo de configuracion SExtractor '*.sex'
    tmp_infile = "config/sextractor/my_default.sex"
    # Verificar si se creo?

    # salida lista de lineas con parametros:
    #delete(outsex_dir//"/"//"inlist.lis", ver-, >& "dev$null")

    list = "data/data_files/accepted_imgs.txt"
    i = 0
    while(fscan(list, line) != EOF){
        if (line != "" && substr(line, 1, 1) != "#") {
            i += 1
            print(line) | scan(tmp_id_obj, extract_img)

            tmp_file = outsex_dir//"/"//tmp_id_obj//"_sextracted.cat"

            if(!access(tmp_file)){

                print(" ------------------------------------------")
                print(" RUNNING SExtractor to model-fitting:")
                printf(" - img: %4d | OBJ: %s \n", i, tmp_id_obj)

                printf("! %s %s -c %s \n", key_run_se, extract_img, tmp_infile) | cl

                tmp_outfile = observed_dir//"/"//tmp_id_obj//"_smooth.fits"
                rename(outsex_dir//"/check_fil.fits", tmp_outfile)

                tmp_outfile = segmen_dir//"/"//tmp_id_obj//"_segmen.fits"
                rename(outsex_dir//"/check_seg.fits", tmp_outfile)

                tmp_outfile = bckgrnd_dir//"/"//tmp_id_obj//"_bg.fits"
                rename(outsex_dir//"/check_bg.fits", tmp_outfile)

                tmp_outfile = bckgrnd_dir//"/"//tmp_id_obj//"_no_objs.fits"
                rename(outsex_dir//"/check_no_objs.fits", tmp_outfile)

                tmp_outfile = bckgrnd_dir//"/"//tmp_id_obj//"_bgrms.fits"
                rename(outsex_dir//"/check_bgrms.fits", tmp_outfile)

                tmp_outfile = model_dir//"/"//tmp_id_obj//"_mod.fits"
                rename(outsex_dir//"/check_mod.fits", tmp_outfile)

                tmp_outfile = residual_dir//"/"//tmp_id_obj//"_res.fits"
                rename(outsex_dir//"/check_res.fits", tmp_outfile)

                tmp_outfile = outsex_dir//"/"//tmp_id_obj//"_test.cat"
                rename(outsex_dir//"/test.cat", tmp_outfile)

                print(" - Identifying object...")

                # captura el centro de la imagen:
                imgets(extract_img, "naxis1")
                fit_xc = real(imgets.value) / 2
                imgets(extract_img, "naxis2")
                fit_yc = real(imgets.value) / 2

                # columna para identificador (# ID):
                printf("# ID\n %s\n", tmp_id_obj, > outsex_dir//"/"//"tmp_col_id.cat")

                # STILTS > obj in center of image:
                expre = "! stilts tpipe ifmt=ascii ofmt=ascii cmd='addcol dist \"sqrt(($4-%.2f)*($4-%.2f) + ($5-%.2f)*($5-%.2f))\"; sorthead 1 dist' in=%s > %s/tmp_line.cat"
                tmp_infile2 = outsex_dir//"/"//tmp_id_obj//"_test.cat"
                printf(expre, fit_xc, fit_xc, fit_yc, fit_yc, tmp_infile2, outsex_dir, tmp_id_obj) | cl

                # Agrega columna ID(col1_1):
                expre = "! stilts tjoin nin=2 ifmt1=ascii ifmt2=ascii in1=%s/tmp_col_id.cat in2=%s/tmp_line.cat ofmt=ascii out=%s/%s_sextracted.cat"
                printf(expre, outsex_dir, outsex_dir, outsex_dir, tmp_id_obj) | cl

                # imprime archivo que contiene la linea en una lista de (directorios) archivos
                printf("%s/%s_sextracted.cat\n", outsex_dir, tmp_id_obj, >> outsex_dir//"/"//"inlist.lis")

                delete(outsex_dir//"/"//"tmp_col_id.cat", ver-, >& "dev$null")
                delete(outsex_dir//"/"//"tmp_line.cat", ver-, >& "dev$null")

            # END IF: si ya existe la sextraccion
            }else{
                print(" ------------------------------------------")
                print(" This object has already been SExtracted!")
                printf(" - img: %4d | OBJ: %s \n", i, tmp_id_obj)
            }
        # END If: lineas validas
        }
    # END WHILE: lectura lista 'accepted_imgs.txt'
    }
    list = ""
    print(" ------------------------------------------")

    printf("\r - Concatenating SExtractions...")

    # CONCATENACION
    delete(outsex_dir//"/"//"sextracted.cat", ver-, >& "dev$null")
    expre = "! awk 'FNR==1 && NR==1 {print; next} /^#/ {next} {print}' $(<%s/inlist.lis) > %s/sextracted.cat"
    printf(expre, outsex_dir, outsex_dir) | cl

    printf("\r - Concatenating SExtractions... Ok.")

    # ==================================================
    # END OF SExtractor SPACE
    # ==================================================
    # DETERMINAR TAMAÑOS Y REGIONES OBTENIDAS POR SEx
    # ==================================================
    print("\n ------------------------------------------")
    printf("\r - solving parameters...")

    # Cabereca:
    printf("#%31s %5d %5d\n", "ID", "Xc", "Yc", > outsex_dir//"/"//"xycenter_images.txt")

    # leer resultados de SEx:
    list = outsex_dir//"/"//"sextracted.cat"
    i = 0
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#" ){

            i += 1

            # Se ajustara x/ywin_img -> x/yc ==> tmp_ra/dec[] -> ra/dec_j00[]
            print(line) | scan(tmp_id_obj, seg_number, tmp_ra, tmp_dec, xwin_img, ywin_img, a_img, b_img, ellip, theta_j00, theta_img, petro_r, iso_areaf)

            # correcciones (i). radio Petrosian:
            petro_r = (petro_r / 2)
            # (ii). theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad = theta_img * const_pi / 180

            # REALIZANDO MASKING A LAS IMAGENES -----------------------------------------
            # imagen de segmentacion para cada objeo:
            tmp_file = segmen_dir//"/"//tmp_id_obj//"_segmen.fits"

            # Realizar masking a la observacion:
            tmp_infile = observed_dir//"/"//tmp_id_obj//".fits"
            tmp_outfile = observed_dir//"/"//tmp_id_obj//"_obs_setmask.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("a == b || a == 0 ? c : 0", tmp_outfile, tmp_file, seg_number, tmp_infile, verb-)

            # Realizar masking a los modelos (de SEx):
            tmp_infile = model_dir//"/"//tmp_id_obj//"_mod.fits"
            tmp_outfile = model_dir//"/"//tmp_id_obj//"_mod_setmask.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("a == b || a == 0 ? c : 0", tmp_outfile, tmp_file, seg_number, tmp_infile, verb-)

            # Realizar masking a los residuos (de SEx):
            tmp_infile = residual_dir//"/"//tmp_id_obj//"_res.fits"
            tmp_outfile = residual_dir//"/"//tmp_id_obj//"_res_setmask.fits"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("a == b || a == 0 ? c : 0", tmp_outfile, tmp_file, seg_number, tmp_infile, verb-)

            # VERIFICACION DE TAMAÑO Y CENTRO --------------------------------------------
            # imagenes creadas por SEx tienen el tamaño de la original (tmp_file=segmentation):
            imgets(tmp_file, "naxis1")
            xlenght_data = int(imgets.value)
            imgets(tmp_file, "naxis2")
            ylenght_data = int(imgets.value)
            # se reusaron las varaiables x/ylenght_data

            # pixel mayor mas cercano al centro:
            xc = xwin_img
            if((xwin_img - xc) >= 0.5){xc += 1}
            # para y:
            yc = ywin_img
            if((ywin_img - yc) >= 0.5){yc += 1}

            # Tamaño minimo aceptado para extraer cielo:
            A_outer = scale_r[46] * petro_r * a_img + 0.5
            B_outer = scale_r[46] * petro_r * b_img + 0.5
            # imagen que circunscribe la elipse rotada:
            xlen_min = 2 * sqrt((A_outer * cos(theta_rad))**2 + (B_outer * sin(theta_rad))**2)
            ylen_min = 2 * sqrt((A_outer * sin(theta_rad))**2 + (B_outer * cos(theta_rad))**2)
            # asegurar len_min entero impar:
            if(xlen_min % 2 == 0){xlen_min += 1}
            if(ylen_min % 2 == 0){ylen_min += 1}

            # Cumple tamaño minimo:
            if(xlenght_data >= xlen_min && ylenght_data >= ylen_min){

                # Puede cumplir el tamaño esperado:
                A_outer = scale_r[56] * petro_r * a_img + 0.5
                B_outer = scale_r[56] * petro_r * b_img + 0.5
                xlen_min = 2 * sqrt((A_outer * cos(theta_rad))**2 + (B_outer * sin(theta_rad))**2)
                ylen_min = 2 * sqrt((A_outer * sin(theta_rad))**2 + (B_outer * cos(theta_rad))**2)
                # asegurar len_min entero impar:
                if(xlen_min % 2 == 0){xlen_min += 1}
                if(ylen_min % 2 == 0){ylen_min += 1}

                # Asignar valores por defecto:
                if(xlenght_data >= xlen_min && ylenght_data >= ylen_min){
                    ri_ann = 36
                    ro_ann = 56
                }else{
                    # reduce el cielo
                    ri_ann = 30
                    ro_ann = 46
                }

            # Requere una imagen para extraer cielo
            }else{

                # Tamaño minimo para medida:
                A_outer = scale_r[26] * petro_r * a_img + 0.5
                B_outer = scale_r[26] * petro_r * b_img + 0.5
                xlen_min = 2 * sqrt((A_outer * cos(theta_rad))**2 + (B_outer * sin(theta_rad))**2)
                ylen_min = 2 * sqrt((A_outer * sin(theta_rad))**2 + (B_outer * cos(theta_rad))**2)
                # asegurar len_min entero impar:
                if(xlen_min % 2 == 0){xlen_min += 1}
                if(ylen_min % 2 == 0){ylen_min += 1}

                # Tamaño menor a medida:
                if(xlenght_data >= xlen_min && ylenght_data >= ylen_min){
                    # requiere imagen aparte del cielo:
                    ri_ann = 26
                    ro_ann = -1
                # No es posible medir
                }else{
                    ri_ann = -1
                    ro_ann = -1
                }
            #END condicional: verificacion de tamaño
            }

            # Tamaño minimo aceptado para extraer cielo:
            A_outer = scale_r[ro_ann] * petro_r * a_img + 0.5
            B_outer = scale_r[ro_ann] * petro_r * b_img + 0.5
            # imagen que circunscribe la elipse rotada:
            xlen_min = 2 * sqrt((A_outer * cos(theta_rad))**2 + (B_outer * sin(theta_rad))**2)
            ylen_min = 2 * sqrt((A_outer * sin(theta_rad))**2 + (B_outer * cos(theta_rad))**2)
            # asegurar len_min entero impar:
            if(xlen_min % 2 == 0){xlen_min += 1}
            if(ylen_min % 2 == 0){ylen_min += 1}

            # Centros de la imagen a transformar:
            # lista para wcstran:
            printf("%32s %5d %5d\n", tmp_id_obj, xc, yc, > outsex_dir//"/"//i//"_xycenter.txt")
            # y para verificar (seguimiento):
            printf("%32s %5d %5d\n", tmp_id_obj, xc, yc, >> outsex_dir//"/"//"xycenter_images.txt")

            # ============================================
            # WCSCTRAN: Transformar coordenadas X,Y -> RA,DEC
            # ============================================
            tmp_infile = outsex_dir//"/"//i//"_xycenter.txt"
            tmp_outfile = outsex_dir//"/"//i//"_sky.txt"
            # la transformacion se basa en tmp_file=segmentation_img porque hereda cabecera FITS:
            printf("wcsctran(input='%s', output='%s', image='%s', inwcs='logical', outwcs='world', columns='2,3')\n", tmp_infile, tmp_outfile, tmp_file) | cl

            # Imprimir catalogo temporal para modificar en el siguiente loop:
            print(tmp_id_obj, " ", seg_number, " ", tmp_ra, " ", tmp_dec, " ", xc, " ", yc, " ", a_img, " ", b_img, " ", ellip, " ", theta_j00, " ", theta_img, " ", petro_r, " ", iso_areaf, " ", ri_ann, " ", ro_ann, " ", xlen_min, " ", ylen_min, >> outsex_dir//"/"//"tmp_params_to_index.txt")

        # END if: lines no comentadas no vacias
        }
    #ENd WHILE: Lectura lista SEx
    }
    list = ""
    n_list = i

    # ============================================
    # Lectura de posiciones ajustadas:
    # ============================================
    printf("\r - solving parameters... 50%%")

    # Cabecera de SKYcoord ajustadas
    printf("#%31s %14s %14s\n", "ID", "RA_c", "DEC_c", > outsex_dir//"/"//"skycenter_images.txt")

    for(i=1;i<=n_list;i+=1){

        list = outsex_dir//"/"//i//"_sky.txt"
        while(fscan(list,line) != EOF){
            if(line != "" && substr(line,1,1) != "#"){

                # ¡¡CUIDADO!! SE ESTAN RECICLANDO LAS VARIABLES
                # 'find_x' y 'find_y' para leer RA y DEC!
                print(line) | scan (id_obj[i], find_x[i], find_y[i])
                printf("%32s %14f %14f\n", id_obj[i], find_x[i], find_y[i], >> outsex_dir//"/"//"skycenter_images.txt")
            # END IF: lineas validas
            }
        # END WHILE: lectura lista
        }
        list = ""
    # END FOR: recuperar pos. del cielo ajustadas
    }

    # ============================================
    # Actualizar parametros:
    # ============================================

    # cabecera regiones ds9:
    print("# Region file format: DS9 version 4.1", > datafiles_dir//"/"//"glxys_in_image.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> datafiles_dir//"/"//"glxys_in_image.reg")
    print("fk5", >> datafiles_dir//"/"//"glxys_in_image.reg")

    # Cabecera de parametros (ajustados) del modelo
    expre = "# ID SEG_ID RA DEC XCNTR_IMG YCNTR_IMG A_IMG B_IMG ELLIP PA THET_IMG KRON_R PETRO_R EFF_R ISO_A ISO_AF RI_ANN RO_ANN XMIN_LENG YMIN_LENG"
    print(expre, > outsex_dir//"/"//"params_to_index.txt")

    # leer resultados de SEx:
    list = outsex_dir//"/"//"tmp_params_to_index.txt"
    i = 0
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#" ){

            i += 1

            # Se ajustara x/ywin_img -> x/yc ==> tmp_ra/dec[] -> ra/dec_j00[]
            print(line) | scan(tmp_id_obj, seg_number, tmp_ra, tmp_dec, xc, yc, a_img, b_img, ellip, theta_j00, theta_img, petro_r, iso_areaf, ri_ann, ro_ann, xlen_min, ylen_min)

            # Imprimir catalogo temporal para modificar en el siguiente loop:
            # (¡¡RECORDAR!! que 'find_x' y 'find_y' son RA y DEC actualizadas)
            print(tmp_id_obj, " ", seg_number, " ", find_x[i], " ", find_y[i], " ", xc, " ", yc, " ", a_img, " ", b_img, " ", ellip, " ", theta_j00, " ", theta_img, " ", petro_r, " ", iso_areaf, " ", ri_ann, " ", ro_ann, " ", xlen_min, " ", ylen_min, >> outsex_dir//"/"//"params_to_index.txt")
            # ¡ADEMAS! 'petro_r' ya esta corregida, i.e., petro_r = (petro_r/2)

            tmp_ra = find_x[i]
            tmp_dec = find_y[i]

            # ----------------------------------------------
            # Crear regiones DS9:
            # ----------------------------------------------
            # caja que inscribe la elipse rotada:
            expre = 'box('//tmp_ra//','//tmp_dec//','//(xlen_min * pix_scal_phot)//'",'//(ylen_min * pix_scal_phot)//'",360) # color=green  text={'//tmp_id_obj//'}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
            # refrence (3A,3B) aperture: eliptical
            expre = 'ellipse('//tmp_ra//','//tmp_dec//','//str(3 * a_img * pix_scal_phot)//'",'//str(3 * b_img * pix_scal_phot)//'",'//str(theta_img)//') # color=green dash=1 text={SEx fit}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
            # elipse de un radio Petrosian (1 rp):
            expre = 'ellipse('//tmp_ra//','//tmp_dec//','//str(petro_r * a_img * pix_scal_phot)//'",'//str(petro_r * b_img * pix_scal_phot)//'",'//str(theta_img)//') # color=red dash=1 text={1}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
            # elipse de 1.5 rp:
            expre = 'ellipse('//tmp_ra//','//tmp_dec//','//str(1.5 * petro_r * a_img * pix_scal_phot)//'",'//str(1.5 * petro_r * b_img * pix_scal_phot)//'",'//str(theta_img)//') # color=red dash=1 text={1.5}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
            # elipse cielo int (ro_ann[k] = 2 rp):
            expre = 'ellipse('//tmp_ra//','//tmp_dec//','//str(2 * petro_r * a_img * pix_scal_phot)//'",'//str(2 * petro_r * b_img * pix_scal_phot)//'",'//str(theta_img)//') # color=blue text={2}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")
            # elipse cielo ext (ro_ann[k] = 3 rp)
            expre = 'ellipse('//tmp_ra//','//tmp_dec//','//str(3 * petro_r * a_img * pix_scal_phot)//'",'//str(3 * petro_r * b_img * pix_scal_phot)//'",'//str(theta_img)//') # color=blue text={3rp}'
            print(expre, >> datafiles_dir//"/"//"glxys_in_image.reg")

            # Eliminar listas de transformacion WCSTRAN:
            delete(outsex_dir//"/"//i//"_xycenter.txt", ver-, >& "dev$null")
            delete(outsex_dir//"/"//i//"_sky.txt", ver-, >& "dev$null")

        # END if: lines no comentadas no vacias
        }
    #ENd WHILE: Lectura lista SEx
    }
    list = ""
    tmp_infile = outsex_dir//"/"//"tmp_params_to_index.txt"
    delete(tmp_infile, ver-, >& "dev$null")

    # Copiar catalogo de regiones para visualizar:
    tmp_infile = datafiles_dir//"/"//"glxys_in_image.reg"
    tmp_outfile = "glxys_in_image.reg"
    delete(tmp_outfile, ver-, >& "dev$null")
    copy(tmp_infile, tmp_outfile)

    printf("\r - solving parameters... Ok.")
    print("\n ------------------------------------------")
    print(" END TASK: check_objs")
    print(" ------------------------------------------")
    beep
    flpr
    flpr
end
