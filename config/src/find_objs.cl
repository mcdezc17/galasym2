procedure find_objs()

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
    # pset exp_pset
    string kw_python
    # temporals
    string tmp_file, tmp_infile

    # Parametros de lista de objtos a analizar:
    string id_obj[999]
    real find_x[999], find_y[999]

    # pset_datapar
    bool single_data
    string pathname_data, initpos_data
    struct cosmopar_data
    string tformat_data, tcoord_data

    # KEY_WORD requeridas para ejecutar programas
    list = "full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            if(key_word == "SINGLE_TYPE"){print(line) | scan(key_word, single_data)}

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            if(key_word == "INIT_POS"){print(line) | scan(key_word, initpos_data)}

            if(key_word == "T_FORMAT"){print(line) | scan(key_word, tformat_data)}

            if(key_word == "T_COORD"){print(line) | scan(key_word, tcoord_data)}

            if(key_word == "COSMOPAR"){print(line) | scan(key_word, cosmopar_data)}

            if(key_word == "KW_PYTHON"){print(line) | scan(key_word, kw_python)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    # IDENTIFICAR OBJETOS SI LA IMAGEN DE ENTRADA ES UNA SOLA:
    if(single_data == yes){
        # Calcular el valor de escala kp/arcsec:
        tmp_file = "config/src/" + "ned_calc.py"
        printf("! %s %s %s\n", kw_python, tmp_file, cosmopar_data) | cl | scan(scale_kp_arsec)

        # Transformar coordenadas SKY a IMG de posiciones iniciales:
        # Requiere transformar formato?
        # espacio para transformar formato: if(tcoord_data != "ascii"){TRANSFORMAR A 'SSV'}

        # SI NO TIENE IDENTIFICADOR: CREAR COLUMNA DE ID:
        # Espacio para crear columna.

        # Si la tabla de posiciones iniciales esa dada en grados
        if(tformat_data != "deg"){
            tmp_infile = initpos_data
            tmp_outfile = "data/data_files/" + "xyimg_initpos.ascii"
            wcsctran(tmp_infile, tmp_outfile, pathname_data, inwcs="world", outwcs="logical", columns="2,3")
        }

        # REGION DE IMAGEN EFECTIVA:
        tmp_file = "data/data_files/" + "effective_image.reg"
        # Si no existe, correr como "primera vez"
        if(!access(tmp_file)){

            # cabecera de las siguientes regiones DS9 (version 4.1)
            print('global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> tmp_file)
            print("image", >> tmp_file)

            # crear apertura de objetos PELIGROSOS (FUERA DE IMAGEN EFECTIVA)
            list = "data/data_files" + "xyimg_initpos.ascii"
            i = 0
            while(fscan(list,line) != EOF){
                if(line != "" && substr(line,1,1) != "#"){
                    i += 1
                    print(line) | scan(id_obj[i], find_x[i], find_y[i])
                    # Posiciones potencialmente peligrosos: fuera de imagen efectiva
                    if(find_x[i] <= (lenght_nx * margen_offset) || find_x[i] >= (lenght_nx - (lenght_nx * margen_offset)) || find_y[i] <= (lenght_ny * margen_offset) || find_y[i] >= (lenght_nx - (lenght_ny * margen_offset))){
                        expre =
                        print()
                    }else{
                        expre =
                        print()
                    }
                # END IF: lineas validas
                }
            # END WHILE: lectura de lista
            }

        }

    # END IF: single_image=yes
    }




end
