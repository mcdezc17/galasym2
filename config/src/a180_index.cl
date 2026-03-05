procedure a180_index()

string   center_rot = "abs"   {prompt = "'abs' or 'rms' minimization"}
bool     force      = yes      {prompt = "force measure with ds9 regions"}

struct *list

begin

    # ************* Variables Definition *************
    # System variables:
    int i, j, k
    struct line
    string key_word
    real mean_val, n_pix
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
    real fit_ra_j00[999], fit_dec_j00[999]
    real fit_xc, fit_yc
    real a_img[999], b_img[999], ellip[999], theta_j00[999]
    real theta_img[999], theta_rad[999], petro_r[999]
    real iso_areaf[999]
    int ri_ann[999], ro_ann[999], xlen_min[999], ylen_min[999]
    # list of position to rotating images:
    string center_rot_list
    string tmp_id_obj
    real ra_rot[999], dec_rot[999]
    int x0_rot[999], y0_rot[999]

    # recorte de imagenes:
    real A_outer, B_outer
    int px1, px2, py1, py2
    string trimsection
    # forzar medida:
    string force_objs
    real a_int, b_int, a_ext, b_ext, ell_angle
    int ri_ann_force, ro_ann_force

    # carpeta principal:
    string abs_dir, absimg_dir, cache_dir
    string frames_dir, residualimg_dir
    string files_dir, abscat_dir, ds9_dir
    # otras carpetas:
    string datafiles_dir
    string outsex_dir
    # direcciones de imagenes:
    string observed_dir

    # calculo de indices:
    real cum_flux_ttl[999]
    int f_ri, f_ro
    real denominator_cumm, numerator_corr
    real area_sky, numerator_aper
    real area_aper, denominator_prfl
    real area_prfl, numerator_prfl
    real abs_prfl_index, abs_cumm_index

    # temporal variables:
    bool tmp_bool
    real tmp_real
    string tmp_wait
    string tmp_infile, tmp_infile2, tmp_outfile

    # ASIGNACIÓN DE  OTROS DIRECTORIOS ------------------------
    abs_dir = "a180_index"
    cache_dir = abs_dir//"/"//"cache"
    # images:
    absimg_dir = abs_dir//"/"//"images"
    frames_dir = absimg_dir//"/"//"small_frames"
    residualimg_dir = absimg_dir//"/"//"abs_residual"
    # catalogs:
    files_dir = abs_dir//"/"//"catalogs"
    ds9_dir = files_dir//"/"//"ds9"
    abscat_dir = files_dir//"/"//"abs_index"
    # other:
    datafiles_dir = "data/data_files"
    outsex_dir    = "data/results_sex"
    # directorio de imagenes:
    observed_dir = "data/data_images/observed"

    # KEY_WORD requeridas para ejecutar programas
    list = "data/data_files/full_params.txt"
    while(fscan(list,line) != EOF){
        if(line != "" && substr(line,1,1) != "#"){

            print(line) | scan(key_word)

            # DATAPAR PSET -----------------------------------------------------------

            if(key_word == "PATH_IMG"){print(line) | scan(key_word, pathname_data)}

            # PHOTOMETRY PSET ---------------------------------------------------------

            if(key_word == "PIXEL_SCALE"){print(line) | scan(key_word, pixel_scale)}

        # END IF: lineas validas
        }
    # END WHILE: lectura lista parametros full
    }
    list = ""

    # ==================================================
    find_objs
    # ==================================================
    find_center
    # ==================================================

    # ASIGNACIÓN DE VARIABLES -------------------------
    const_pi = 3.1415926535897932385
    scale_r_offset = 0.25
    scale_r_step = 0.05

    # VECTOR FOR ELLIPTICAL APERTURES in Petrosian radius
    for(i=1; i<=96; i+=1){
        scale_r[i] = scale_r_offset + (scale_r_step * (i-1))
    }

    # expresion de una elipse rotada y des-centrada:
    ellip_expr = "((((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)))"
    # Expression for annulus patch of bg estimation: outer
    expre1 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (c**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (d**2)) <= 1"
    # Inner annulus for noise extract
    expre2 = "(((I-a)*cos(e) + (J-b)*sin(e))**2 / (f**2)) + (((I-a)*sin(e) - (J-b)*cos(e))**2 / (g**2)) >= 1"

    print(" ----------------------------------------------")
    print(" ============== A_180 DIVISION ================")
    print(" ============= ASYMMETRY  INDEX ===============")

    print(" Asymmetry index (A_180) introduced by Plauchu-
    print(" Frayn  and  Coziol (2010). This index  is a no")
    print(" traditional way to measure residual rotational")
    print(" (180) asymmetry, like A_180 = I/I_180 form. We")
    print(" are c")
    print(" et. al. (2024).\n")






end<<
