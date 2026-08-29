procedure snr_task()

string center_rot = "abs"   {prompt = "'abs' or 'rms' minimization"}
real   bulge_clip = 10.0    {prompt = "No sense if it's <=3"}
bool   force      = yes     {prompt = "force measure with ds9 regions"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    string key_word

    # constants........
    real const_pi
    # patrameters......
    real scale_r_offset, scale_r_step
    real scale_r[99]
    string expr, expre1, expre2, ellip_expr

    # PSET: datapar
    string pathname_data
    # PSET: photmetry
    real pixel_scale

    # list of objects:
    int n_list
    string id_obj[999]
    int  seg_number[999]
    real fit_xc, fit_yc
    real fit_ra_j00[999], fit_dec_j00[999]
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999]
    real iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # list of position to rotating images:
    real xc, yc
    #string center_rot_list
    #string tmp_id_obj
    #real ra_rot[999], dec_rot[999]
    #int x0_rot[999], y0_rot[999]

    # forzar medida:
    string force_obj
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force

    # carpeta principal:

    # otras carpetas:
    string cache_dir, datafiles_dir
    string outsex_dir
    # direcciones de imagenes:
    string observed_dir, segmen_dir, bckgrnd_dir, model_dir

    # DFEINIR SNR:
    real meanpix, ttlpix
    real sum_total, noise_total, snr_total, snr_ann_total
    real local_rms
    # average snr:
    real n_pixels_snr, average_snr_aper, average_snr_ann

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_infile3, tmp_infile4, tmp_outfile

    # other:
    cache_dir     = "data/cache"
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"
    segmen_dir   = "data/data_images/segmentation"
    bckgrnd_dir  = "data/data_images/background"
    model_dir    = "data/data_images/model"

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25
    scale_r_step = 0.05

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (scale_r_step * (i-1))
    }

    # KEY_WORD requeridas para ejecutar programas
    list = "data/data_files/full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # PHOTOMETRY PSET ---------------------------------------------------------

            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pixel_scale)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"
    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"


    print(" ------------------------------------------")
    print(" ================= SNR task ===============")
    print(" ==========================================")

    # listas heredadas exactamente de 'find_objs' task:
    tmp_infile = outsex_dir//"/"//"params_to_index.txt"
    # No existe archivo de entrada esperado:
    if(!access(tmp_infile)){
        print("\n ERR(fatal): mandatory that it exist:")
        print(" - ", tmp_infile)
        print("\n HINT: best run over again.")
        print("\n Abort task!")
        bye
    }

    list = outsex_dir//"/"//"params_to_index.txt"
    i = 0
    while(fscan(list, line) != EOF){
        if(line !="" && substr(line,1,1)!="#"){
            i = i + 1

            print(line) | scan(id_obj[i], seg_number[i], fit_ra_j00[i], fit_dec_j00[i], fit_xc, fit_yc, a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], petro_r[i], iso_areaf[i], ri_ann[i], ro_ann[i], xlen_min[i], ylen_min[i])

            # Correcciones:
            # petro_r[] ya fue corregido en 'glxy_model' task.
            # theta_img[] from SEx en grados (degrees, °) [-const_pi/2,+const_pi/2]
            theta_rad[i] = theta_img[i] * const_pi / 180
        # END IF: lineas validas
        }
    # END WHILE: leer lista
    }
    list = ""
    n_list = i

    # ===============================================================
    # FORCE APERTURES
    # ===============================================================

    for(i=1;i<=n_list;i+=1){
        force_obj = "force_"//id_obj[i]//".reg"
        if(access(force_obj) && force == yes){

            # extraer nuevos parametros de medida:
            expr = "! awk '/^ellipse\\(/ {split($0,a,\"[(),]\"); print a[4],a[5],a[6],a[7],a[8]}' %s\n"
            print("\n  - Object to force measure: ", id_obj[i])
            printf(expr, force_obj) | cl | scan(a_int, b_int, a_ext, b_ext, ell_angle)

            # Nuevos parametros:
            a_img[i] = a_int / (2.0 * petro_r[i])
            b_img[i] = b_int / (2.0 * petro_r[i])
            theta_img[i] = ell_angle
            theta_rad[i] = theta_img[i] * const_pi / 180
        }

        # Progress bar proccess:
        printf("\r - Process (cutting images): %d%%", (i*100/n_list))
    }

    #print("\n Catalogs!")

    # ===============================================================
    # CATALOGS HEADER:
    # ===============================================================

    for(i=1;i<=36;i+=1){

        if(i == 1){

            # V. NORMAL SNR CATALOG
            printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[i], > datafiles_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            print("# NOTE: SNR_set for annular if bulge_clip > 3sigma", > datafiles_dir//"/"//"SNR_ann_set.cat")
            printf("#%31s ⟨SNR⟩_%4.2frp", "ID_OBJ", scale_r[i], > datafiles_dir//"/"//"SNR_ann_set.cat")

        }else if(i == 36){

            # V. SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[i], "SNR_ttl_1rp", >> datafiles_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp %11s\n", scale_r[i], "SNR_ttl_1rp", >> datafiles_dir//"/"//"SNR_ann_set.cat")

        }else{

            # V. SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp", scale_r[i], >> datafiles_dir//"/"//"SNR_set.cat")

            # VI. ANULLAR SNR CATALOG
            printf(" ⟨SNR⟩_%4.2frp", scale_r[i], >> datafiles_dir//"/"//"SNR_ann_set.cat")

        }
    # END FOR: header catalogs
    }

    # ===============================================================
    # INDEX COMPUTATION
    # ===============================================================

    #print("\n SNR computation!")

    # Todas las imagenes a utilizar tienen el mismo tamaño:
    tmp_infile = observed_dir//"/"//id_obj[1]//"_obs_setmask.fits"
    imgets(tmp_infile, "naxis1")
    xc = real(imgets.value) / 2
    imgets(tmp_infile, "naxis2")
    yc = real(imgets.value) / 2


    # RECORRIDO DE OBJETOS:
    for(i=1;i<=n_list;i+=1){

        printf("\r - SNR process: %2d / %2d objects", i, n_list)

        # Local RMS FOR BULGE_CLIP
        tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"  # f-param
        # local RMS:
        imstat(tmp_infile, fields="midpt", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(local_rms)

        # AUMENTO DE APERTURAS:
        for(j=1;j<=36;j+=1){

            # ******************* TO DEFINE SNR TOTAL into 1.5Rp *****************************
            if(j == 16){

                # Valores OBS donde RMS>0 y r=1.5Rp:
                tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
                tmp_infile2 = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"
                tmp_outfile = cache_dir//"/"//"tmp_obs_to_SNRttl"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imexpr(expre1//" && (f > 0) ? g : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, tmp_infile2, ver-)
                # Estadistica de los valores anteriores:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                # Suma de valores
                sum_total = meanpix * ttlpix

                # Suma total del RMS:
                tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"
                tmp_outfile = cache_dir//"/"//"tmp_bgrms_to_SNRttl"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imexpr(expre1//" && (f > 0) ? (f**2) : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, ver-)
                # Estadistica de los valores anteriores:
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                # Suma de valores
                noise_total = sqrt(meanpix * ttlpix)

                snr_total = sum_total / noise_total
                #print("\n    SNR total = ", snr_total)

                # BORRAR IMAGENES SNR TTL PROCESO:
                imdelete(cache_dir//"/"//"tmp_obs_to_SNRttl", >& "dev$null")
                imdelete(cache_dir//"/"//"tmp_bgrms_to_SNRttl", >& "dev$null")

                # TOTAL SNR for annular aperture
                if(bulge_clip > 3){

                    # Valores OBS donde RMS>0 y r=1.5Rp BUT AVOID BULGE:
                    tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"  # f-param
                    # local RMS:
                    #imstat(tmp_infile, fields="midpt", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(local_rms)
                    tmp_infile2 = model_dir//"/"//id_obj[i]//"_mod.fits"     # g-param
                    tmp_infile3 = segmen_dir//"/"//id_obj[i]//"_segmen.fits"
                    tmp_infile4 = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"
                    tmp_outfile = cache_dir//"/"//"tmp_obs_to_SNRttl"
                    imdelete(tmp_outfile, ver-, >& "dev$null")
                    imexpr(expre1//" && (f > 0) && (g <= h*i) ? j : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, tmp_infile2, local_rms, bulge_clip, tmp_infile4, ver-)
                    # Estadística de los valores anteriores:
                    imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    # Suma de valores:
                    sum_total = meanpix * ttlpix

                    # Suma total del RMS:
                    tmp_outfile = cache_dir//"/"//"tmp_bgrms_to_SNRttl"
                    imdelete(tmp_outfile, ver-, >& "dev$null")
                    imexpr(expre1//" && (f > 0) && (g <= h*i) ? (f**2) : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, tmp_infile2, local_rms, bulge_clip, ver-)
                    # Estadistica de los valores anteriores:
                    imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    # Suma de valores:
                    noise_total = sqrt(meanpix * ttlpix)

                    snr_ann_total = sum_total / noise_total
                    #print("\n    SNR annulus total = ", snr_ann_total)

                    #imdelete(cache_dir//"/"//"tmp_obs_to_SNRttl", >& "dev$null")
                    #imdelete(cache_dir//"/"//"tmp_bgrms_to_SNRttl", >& "dev$null")

                }
                # END IF: BULGE_CLIP SNR TOTAL
            }
            # END FOR: SNR ANNULAR PROCESO

            # *************** TO DEFINE AVERAGE SNR or ⟨SNR⟩ *************************************************
            # Img apertura binaria
            tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"  # f-param
            tmp_outfile = cache_dir//"/"//"tmp_n_pixels"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr(expre1//" && (f > 0) ? 1 : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, ver-)
            # Suma de pixeles apertura
            imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            n_pixels_snr = (meanpix * ttlpix)

            # Imagen razon OBS / RMS
            tmp_infile  = cache_dir//"/"//"tmp_n_pixels"                     # a-param
            tmp_infile2 = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits"  # b-param
            tmp_infile3 = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"         # c-param
            tmp_outfile = cache_dir//"/"//"tmp_snr_per_pixel"
            imdelete(tmp_outfile, ver-, >& "dev$null")
            imexpr("(a > 0) ? (b/c) : 0", tmp_outfile, tmp_infile, tmp_infile2, tmp_infile3, ver-)
            imstat(cache_dir//"/"//"tmp_snr_per_pixel", fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
            sum_total = (meanpix * ttlpix)

            average_snr_aper = (sum_total / n_pixels_snr)

            #print("\n  average SNR = ", average_snr_aper)

            imdelete(cache_dir//"/"//"tmp_n_pixels", >& "dev$null")
            imdelete(cache_dir//"/"//"tmp_snr_per_pixel", >& "dev$null")

            # TOTAL SNR for annular aperture
            if(bulge_clip > 3){

                # Img apertura binaria
                tmp_infile  = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"  # f-param
                tmp_infile2 = model_dir//"/"//id_obj[i]//"_mod.fits"     # g-param
                tmp_outfile = cache_dir//"/"//"tmp_n_pixels"
                imdelete(tmp_outfile, ver-, >& "dev$null")
                imexpr(expre1//" && (f > 0) && (g <= h*i) ? 1 : 0", tmp_outfile, xc, yc, scale_r[j] * petro_r[i] * a_img[i], scale_r[j] * petro_r[i] * b_img[i], theta_rad[i], tmp_infile, tmp_infile2, local_rms, bulge_clip, ver-)
                # Estadistica de pixeles apertura
                imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                # Suma de valores
                n_pixels_snr = (meanpix * ttlpix)

                # Verificar inconsistencia (division por cero)
                if(n_pixels_snr > 0){

                    # Imagen razon OBS / RMS
                    tmp_infile  = cache_dir//"/"//"tmp_n_pixels"                     # a-param
                    tmp_infile2 = model_dir//"/"//id_obj[i]//"_mod.fits"            # b-param
                    tmp_infile3 = observed_dir//"/"//id_obj[i]//"_obs_setmask.fits" # e-param
                    tmp_infile4 = bckgrnd_dir//"/"//id_obj[i]//"_bgrms.fits"        # f-param
                    tmp_outfile = cache_dir//"/"//"tmp_snr_per_pixel"
                    imdelete(tmp_outfile, ver-, >& "dev$null")
                    imexpr("(a > 0) && (b <= c*d) ? (e/f) : 0", tmp_outfile, tmp_infile, tmp_infile2, local_rms, bulge_clip, tmp_infile3, tmp_infile4, ver-)
                    # Estadistica:
                    imstat(tmp_outfile, fields="mean, npix", lower=INDEF, upper=INDEF, nclip=0, format-) | scan(meanpix, ttlpix)
                    # Suma:
                    sum_total = (meanpix * ttlpix)


                    average_snr_ann = (sum_total / n_pixels_snr)
                    #imdelete(cache_dir//"/"//"tmp_snr_ann_per_pixel", >& "dev$null")

                }else{

                    average_snr_ann = 0
                }
                # END ZERO DIVISION

                #print("\n  average SNR annular = ", average_snr_ann)

                imdelete(cache_dir//"/"//"tmp_n_pixels", >& "dev$null")
                imdelete(cache_dir//"/"//"tmp_snr_per_pixel", >& "dev$null")

            }
            # END IF-ELSE BULGE_CLIP AVER. SNR.

            # ====================================================================================
            # PRINT CATALOGS
            # ====================================================================================

            if(j == 1){

                # V. NORMAL SNR CATALOG
                printf("%32s %11.4f", id_obj[i], average_snr_aper, >> datafiles_dir//"/"//"SNR_set.cat")

                if(bulge_clip > 3){
                    # VI. ANNULAR SNR CATALOG
                    printf("%32s %11.4f", id_obj[i], average_snr_ann, >> datafiles_dir//"/"//"SNR_ann_set.cat")
                }

            }else if(j == 36){

                # V. NORMAL SNR CATALOG
                printf(" %11.4f\n", snr_total, >> datafiles_dir//"/"//"SNR_set.cat")

                if(bulge_clip > 3){
                    # VI. ANNULAR SNR CATALOG
                    printf(" %11.4f\n", snr_ann_total, >> datafiles_dir//"/"//"SNR_ann_set.cat")
                }

            }else{

                # V. NORMAL SNR CATALOG
                printf(" %11.4f", average_snr_aper, >> datafiles_dir//"/"//"SNR_set.cat")

                if(bulge_clip > 3){
                    # VI. ANNULAR SNR CATALOG
                    printf(" %11.4f", average_snr_ann, >> datafiles_dir//"/"//"SNR_ann_set.cat")
                }

            }

        }
        # END FOR APERTURES
    }
    # END FOR INPUTLIST

    beep
    print("\n ------------------------------------------")
    printf(" OUTPUT FOLDER: ./%s\n", datafiles_dir)
    print(" END TASK: snr_task")
    print(" ------------------------------------------")
    print("")
end
