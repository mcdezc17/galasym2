procedure find_objs()

string initpos_alt = ""
struct *list

begin

    # ************* DEFINICIÓN DE VARIABLES *************
    # System variables
    int i
    struct line
    string key_word

    # parametros locales (globales)
    real scale_kp_arsec
    string expre
    real margen_offset
    # pset exp_pset
    string kw_python
    # temporals
    string tmp_file, tmp_infile, tmp_outfile
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

    # Declaracion de variables locales:
    margen_offset = 0.03

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
        if(tformat_data != "deg"){
            tmp_infile = initpos_data
            tmp_outfile = "data/data_files/"//"xyimg_initpos.txt"
            wcsctran(tmp_infile, tmp_outfile, pathname_data, inwcs="world", outwcs="logical", columns="2,3")
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

            tmp_infile = "data/data_files/"//"effective_image.reg"
            delete(tmp_infile, , ver-, >& "dev$null")
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

    print("\n------------------------------------------")

end
