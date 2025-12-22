procedure find_xypos()

    #string out_list = "out_list"  {prompt = "Output name list"}
    string input_list  = "in_list"    {prompt = "List of SEx (NIR) parameters"}
    string measure_img = "A496r.fits"       {prompt = "FITS observed data"}
    real   pix_scale   = 0.186        {prompt = "Pixel scale (arcsec/pixel)"}
    real   clredshift  = 0.033        {prompt = "Cluster redshift"}
    bool   xy_cursor   = yes          {prompt = "Cursor xi, yi_limits (i=2)"}
    int    x1_limit    = 19729        {prompt = "Border x1 axis image"}
    int    y1_limit    = 21087        {prompt = "Border y1 axis image"}
    int    x2_limit    = 21460        {prompt = "Border x2 axis image"}
    int    y2_limit    = 20326        {prompt = "Border y2 axis image"}

begin

    # COPIA DE VARIABLES FROM GALASYM2 ---------------------------------------

    real const_pi

    string alpha_dir, data_dir, alphaimg_dir, dataimg_dir, obs_dir, mod_dir, res_dir, asymm_dir, file_dir, ds9_dir, cat_dir, tmp_dir


    # DEFINICIÓN DE VARIABLES "NUEVAS" ---------------------------------------

    struct line

    string limits_file

    string regions_xypos, regions_inimg
    string outlist_all, out_list

    int x_limit[10], y_limit[10]

    string line_info

    string id_obj[999]
    real find_x[999], find_y[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], kron_r[999], petro_r[999], eff_r[999], iso_area[999], iso_areaf[999], a_mod[999], b_mod[999]

    int n_list

    string expre

    real kp_DA

    real ri_ann, ro_ann

    # ASIGNACIÓN DE DIRECTORIOS --------------------------

    # ./data: main output cut frames
    data_dir = "data"
    # ./alpha/temporal:
    tmp_dir = data_dir//"/"//"cache"

    # ASIGNACIÓN DE VARIABLES ---------------------

    const_pi = 3.1415926535897932385

    regions_xypos = "regions_find_xypos.reg"
    regions_inimg = "regions_in_image.reg"

    limits_file = tmp_dir//"/"//"rectangles_find.reg"

    out_list = "inimg_objs.cat"
    outlist_all   = "all_objs.cat"

    ri_ann = 3
    ro_ann = 4

    # CONVERSIÓN DE COORDENADAS RA/DEC EN XY IMAGEN ACTUAL ------
    delete(outlist_all, ver-, >& "dev$null")
    wcsctran(input_list, outlist_all, image = measure_img, inwcs="world", outwcs="logical", columns="2,3")

    # INPUT PARAMETER VERIFICATION ------------------------------
    if (!access(outlist_all)){
        printf("The table %s wasn't created\n", outlist_all)
        goto exit_task
    }

    if(xy_cursor == yes){

        print("DS9 cursor input mode now")
        print("Remember! \n 1. two times position only -> press key 'x'")
        print(" 2. you must exit -> press 'q'")

        delete(limits_file, ver-, >& "dev$null")
        imexamine(logfile=limits_file, keeplog=yes)

        sleep(1)

        # READ INPUT LIST --------------------------------------------
        list = limits_file
        i = 0
        while (fscan(list, line) != EOF) {
            # Revisar que no sea comentario y que no esté vacía
            if (line != "" && substr(line, 1, 1) != "#") {
                i = i + 1
                print(line) | scan(x_limit[i], y_limit[i])
            }
        }

    }

    # DE LA CONVERSIÓN DE COORDENADAS, CUÁLES ESTÁN DENTRO DE LA IMAGEN:
    delete(out_list, ver-, >& "dev$null")
    expre = "\"(col2 > %d && col3 > %d) && ((col2 < %d && col3 < %d) || (col2 < %d && col3 < %d))\""

    printf("! stilts tpipe in=%s ifmt=ascii cmd='select "//expre//"' ofmt=ascii out=%s", outlist_all, x_limit[1], y_limit[1], x_limit[2], y_limit[2], x_limit[3], y_limit[3], out_list) | cl

    # Muchas opciones de hacer este filtrado manteniendo ascii (e.g., grep + awk)

    # if(access("./ned_calc.py")){
    #
    #     print("! python3 ned_calc.py ", clredshift, " 70 0.3 0.7") | cl | scan(kp_DA)
    #     print("")
    #     print('Scale Kpc/": ', kp_DA)
    #     print("Radius aperture: ", str(10/pix_scale), " pixels")
    # }

    #_______________________________________________________________________________
    #____________________ CREATE REGION DS9 FILES  _________________________________|
    # FK5 coordinates format / The shape of apertures depends on ellipticity (SEx)
    # and determines the measurement aperture (growing in this shape)

    # # Header: all objects image coordinates, but maube not in image!
    # delete(regions_xypos, ver-, >& "dev$null")
    # print("# Region file format: DS9 version 4.1", >> regions_xypos)
    # print('global color=red dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> regions_xypos)
    # print("image", >> regions_xypos)

    # Header: find objects in image
    delete(regions_inimg, ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> regions_inimg)
    print('global color=green dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> regions_inimg)
    print("image", >> regions_inimg)


    # # READ INPUT LIST --------------------------------------------
    # list = outlist_all
    # i = 0
    # while (fscan(list, line) != EOF) {
    #
    #     # Revisar que no sea comentario y que no esté vacía
    #     if (line != "" && substr(line, 1, 1) != "#") {
    #
    #         i = i + 1
    #
    #         print(line) | scan(id_obj[i], find_x[i], find_y[i])
    #         # , xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i], a_mod[i], b_mod[i])
    #         # petro_r[i] = petro_r[i] / 2
    #
    #         # refrence (3A,3B) aperture: eliptical
    #         expre = 'circle('//str(find_x[i])//','//str(find_y[i])//','//str(10 / pix_scale)//') # width=2 text={'//str(id_obj[i])//'}'
    #         print(expre, >> regions_xypos)
    #
    #     }
    #
    # }

    # READ INPUT LIST --------------------------------------------
    list = out_list
    i = 0
    while (fscan(list, line) != EOF) {

        # Revisar que no sea comentario y que no esté vacía
        if (line != "" && substr(line, 1, 1) != "#") {

            i = i + 1

            print(line) | scan(id_obj[i], find_x[i], find_y[i])
            # , xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i], a_mod[i], b_mod[i])

            # petro_r[i] = petro_r[i] / 2

            # refrence (3A,3B) aperture: eliptical
            expre = 'circle('//str(find_x[i])//','//str(find_y[i])//','//str(10 / pix_scale)//') # width=2 text={'//str(id_obj[i])//'}'
            print(expre, >> regions_inimg)
        }

    }

    # for(i=1; i<=n_list; i+=1){
    #     # refrence (3A,3B) aperture: eliptical
    #     expre = 'circle('//str(find_x[i])//','//str(find_y[i])//','//str(10 / pix_scale)//') # width=2 text={'//str(id_obj[i])//'}'
    #     print(expre, >> regions_xypos)
    # }
    #____________________ END CREATE REGION DS9 FILES  _____________________________|
    #
    #
    exit_task:
    #
    # # print("Exit task.")
    print("-------------------------------------------------------------")
    print("")

end
