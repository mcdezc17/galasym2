procedure cas_index()

# TO RUN FROM LOCAL DIRECTORY ./

    string input_list  = "no"        {prompt = "List of objects to analyze (ascii)"}
    real   pix_scale   = 0.2486      {prompt = "Pixel scale (arcsec/pixel)"}
    string key_ds9     = "ds9"       {prompt = "Keyword to run DS9 viewer"}
    string obj_center  = no          {prompt = "Index list center object (integer)"}
    real   clredshift  = 0.055       {prompt = "Cluster redshift (e.g. 0.033"}


begin

    # ---- Variables definition ----

    real const_pi

    string config_dir, sex_dir, outsex_dir
    string data_dir, dataimg_dir, obs_dir, mod_dir, res_dir

    string cas_dir
    string casimg_dir, absimg_dir, rmsimg_dir
    string file_dir, ds9_dir, cat_dir, rms_cat_dir, tmp_dir

    bool objcenter_bool

    real ri_ann, ro_ann, petro_factor
    real scale_r[100]

    string my_date, my_time

    struct line
    string line_info

    string id_obj[999]
    real ra_j00[999], dec_j00[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], kron_r[999], petro_r[999], eff_r[999], iso_area[999], iso_areaf[999]
    int n_list, n_edit

    string tmp_string, tmp_wait

    int i_center
    real kp_DA
    real ccdistance[999], ccdistance_pix[999], ccdistance_arsec[999], ccdistance_Mpc[999]

    int r_mask

    string expre, expre1, expre2

    # ---- Asignación de valores iniciales ----
    # (i). Directorios:

    # ./config
    config_dir = "config"

    # ./config/sextractor
    sex_dir = config_dir//"/"//"sextractor"
    # ./config/sextractor/results_sex
    outsex_dir = sex_dir//"/"//"results_sex"

    # ./data: main output cut frames
    data_dir = "data"

    # ./data/images:
    dataimg_dir = data_dir//"/"//"images"
    # ./data/images/observed
    obs_dir = dataimg_dir//"/"//"observed"
    # ./data/images/model
    mod_dir = dataimg_dir//"/"//"model"
    # ./data/images/residual
    res_dir = dataimg_dir//"/"//"residual"

    # ./cas_index: A_cas index output main folder
    cas_dir = "cas_index"                                # new variable
    # ./cas_index/images
    casimg_dir = cas_dir//"/"//"images"                  # new variable
    # ./cas_index/images/min_abs
    absimg_dir = casimg_dir//"/"//"min_abs"                 # new variable
    # ./cas_index/images/min_rms
    rmsimg_dir = casimg_dir//"/"//"min_rms"                 # new variable

    # ./cas_index/files(catalogs o plain text):
    file_dir = cas_dir//"/"//"files"
    # ./cas_index/files/ds9_files
    ds9_dir = file_dir//"/"//"ds9_files"
    # ./cas_index/files/catalogs
    cat_dir = file_dir//"/"//"catalogs"
    # ./cas_index/files/rotational_catalogs
    rms_cat_dir = cat_dir//"/"//"rms_catalog"            # new variable

    # ./cas_index/temporal:
    tmp_dir = cat_dir//"/"//"cache"

    # ---- Asignación de valores iniciales ----
    # (ii). :

    const_pi = 3.1415926535897932385

    objcenter_bool = no

    ri_ann = 3
    ro_ann = 4

    petro_factor = 2.0

    r_mask = 15

    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    # vector of scale r/rp
    scale_r[1]=0.25
    scale_r[2]=0.30; scale_r[3]=0.35; scale_r[4]=0.40; scale_r[5]=0.45; scale_r[6]=0.50; scale_r[7]=0.55; scale_r[8]=0.60; scale_r[9]=0.65; scale_r[10]=0.70; scale_r[11]=0.75; scale_r[12]=0.80; scale_r[13]=0.85; scale_r[14]=0.90; scale_r[15]=0.95; scale_r[16]=1.00; scale_r[17]=1.05; scale_r[18]=1.10; scale_r[19]=1.15; scale_r[20]=1.20; scale_r[21]=1.25; scale_r[22]=1.30; scale_r[23]=1.35; scale_r[24]=1.40; scale_r[25]=1.45; scale_r[26]=1.50; scale_r[27]=1.55; scale_r[28]=1.60; scale_r[29]=1.65; scale_r[30]=1.70; scale_r[31]=1.75; scale_r[32]=1.80; scale_r[33]=1.85; scale_r[34]=1.90; scale_r[35]=1.95; scale_r[36]=2.00; scale_r[37]=2.05; scale_r[38]=2.10; scale_r[39]=2.15; scale_r[40]=2.20; scale_r[41]=2.25; scale_r[42]=2.30; scale_r[43]=2.35; scale_r[44]=2.40; scale_r[45]=2.45; scale_r[46]=2.50; scale_r[47]=2.55; scale_r[48]=2.60; scale_r[49]=2.65; scale_r[50]=2.70; scale_r[51]=2.75; scale_r[52]=2.80; scale_r[53]=2.85; scale_r[54]=2.90; scale_r[55]=2.95; scale_r[56]=3.00; scale_r[57]=3.05; scale_r[58]=3.10; scale_r[59]=3.15; scale_r[60]=3.20; scale_r[61]=3.25; scale_r[62]=3.30; scale_r[63]=3.35; scale_r[64]=3.40; scale_r[65]=3.45; scale_r[66]=3.50; scale_r[67]=3.55; scale_r[68]=3.60; scale_r[69]=3.65; scale_r[70]=3.70; scale_r[71]=3.75; scale_r[72]=3.80; scale_r[73]=3.85; scale_r[74]=3.90; scale_r[75]=3.95; scale_r[76]=4.00; scale_r[77]=4.05; scale_r[78]=4.10; scale_r[79]=4.15; scale_r[80]=4.20; scale_r[81]=4.25; scale_r[82]=4.30; scale_r[83]=4.35; scale_r[84]=4.40; scale_r[85]=4.45; scale_r[86]=4.50; scale_r[87]=4.55; scale_r[88]=4.60; scale_r[89]=4.65; scale_r[90]=4.70; scale_r[91]=4.75; scale_r[92]=4.80; scale_r[93]=4.85; scale_r[94]=4.90; scale_r[95]=4.95; scale_r[96]=5.00

    # First terminal output
    print("")

    printf("|<------- GALASYM2 started on %s at %s ------>|\n", my_date, my_time)
    print("[ Computing: standard asymmetry indexes (A_cas, A_rms) ]\n")

    # INPUT PARAMETER VERIFICATION ------------------------------
    if (!access(input_list)){
        print("Warning: input list named <<", input_list, ">> not found!")
        print("Enter correct filename with extension *.txt, *.ascii, etc.")
        print("(list name):")
        scan(input_list)
        if(!access(input_list)){
            print("ERR: Second verification for ", input_list, " failed!")
            print("     Check the input list name and its existence in local directory.")
            print("")
            print("Analysis task aborted. Verify and try again!")
            goto exit_task
        }
    }
    # others verification here:

    # FOLDER VERIFICATION OR CREATION ----------------------------

    if(!access(data_dir)){
        print("folder <<data>> must exist! ")
        goto exit_task
    }                                            # main input: ./data

    if(!access(cas_dir)){mkdir(cas_dir)}         # main output: ./cas                            # new variable

    if(!access(casimg_dir)){mkdir(casimg_dir)}     # images folder:       ./cas_index/images:
    if(!access(absimg_dir)){mkdir(absimg_dir)}     # images abs folder:   ./cas_index/images/abs_min    # new variable
    if(!access(rmsimg_dir)){mkdir(rmsimg_dir)}     # images rms folder:   ./cas_index/images/rms_min    # new variable

    if(!access(file_dir)){mkdir(file_dir)}         # files folder:    ./cas_index/files:
    if(!access(ds9_dir)){mkdir(ds9_dir)}           # ds9_files:       ./cas_index/files/ds9_files
    if(!access(cat_dir)){mkdir(cat_dir)}           # catalogs_files:  ./cas_index/files/catalogs
    if(!access(rms_cat_dir)){mkdir(rms_cat_dir)}   # rotational_cataloogs: ./cas_index/files/rot_catalogs   # new variable

    if(!access(tmp_dir)){mkdir(tmp_dir)}           # temporal folder: ./cas_index/temp


    # READ INPUT LIST --------------------------------------------
    list = input_list
    i = 0
    while(fscan(list,line) != EOF){
        line_info = substr(line, 1, 1)
        if(line_info != "#"){

            i = i + 1

            # NOTE: The columns are readed in order to input.list
            #************************ USAR LAS SIGUIENTES VARIABLES ******************************
            # string id_obj[999]
            # real ra_j00[999], dec_j00[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], iso_area[999], iso_areaf[999]
            #****************************************************************************************

            print(line) | scan(id_obj[i], ra_j00[i], dec_j00[i], xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i])

            petro_r[i] = petro_r[i] / 2
        }
    }
    n_list = i


    #__________________________________________________________________________
    #___________ Distance of objects to galaxy center _________________________|
    if(strlwr(obj_center) != "no" && strlwr(obj_center) != "n"){

        i_center = int(obj_center)
        if(i_center < 1 || i_center > n_list){
            print(" ERR: <<obj_center>> must be an integer (within the inputlist)")
            goto exit_task
        }

        objcenter_bool = yes

        if(access(config_dir//"/"//"ned_calc.py")){

            print("! python3 "//config_dir//"/"//"ned_calc.py ", clredshift, " 70 0.3 0.7") | cl | scan(kp_DA)
        }

        for(i=1; i<=n_list; i+=1){

            ccdistance_pix[i] = sqrt((xwin_img[i_center] - xwin_img[i])**2 + (ywin_img[i_center] - ywin_img[i])**2)
            ccdistance[i] = ccdistance_pix[i]

            if(pix_scale != 0){

                ccdistance_arsec[i] = ccdistance_pix[i] * pix_scale
                ccdistance[i] = ccdistance_arsec[i]

                if(access(config_dir//"/"//"ned_calc.py")){

                    ccdistance_Mpc[i] = (ccdistance_arsec[i] * kp_DA) / 1000
                    ccdistance[i] = ccdistance_Mpc[i]
                }
            }
        }
    }

    # # If avoid cut frames and go to asymmetry compute
    # if(edit_mode == yes){
    #     goto edit_task
    # }
    # -----------------------------------------------------------

    #_______________________________________________________________________________
    #____________________ CREATE REGION DS9 FILES  _________________________________|
    # FK5 coordinates format / The shape of apertures depends on ellipticity (SEx)
    # and determines the measurement aperture (growing in this shape)

    # Header: measurement apertures
    delete(ds9_dir//"/"//"apertures.reg", ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"apertures.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"apertures.reg")
    print("fk5", >> ds9_dir//"/"//"apertures.reg")

    # Header: Kron and Petrosian apertures
    delete(ds9_dir//"/"//"kron_petro_aper.reg", ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> ds9_dir//"/"//"kron_petro_aper.reg")
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> ds9_dir//"/"//"kron_petro_aper.reg")
    print("fk5", >> ds9_dir//"/"//"kron_petro_aper.reg")


    for(i=1; i<=n_list; i+=1){
        # refrence (3A,3B) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(3 * a_img[i] * pix_scale)//'",'//str(3 * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=green text={SE fit}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # refrence (Rp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red text={Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # measurement (1.5xRp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(1.5 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={1.5Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # measurement (2xRp) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={2Rp}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # background aperture: eliptical annulus
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ri_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ri_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ro_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ro_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1 text={in:'//str(i)//', '//id_obj[i]//'}'
        print(expre, >> ds9_dir//"/"//"apertures.reg")

        # Elliptical petrosian aperture:
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=yellow'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
        # Elliptical total flux (2 x R_petro):
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=yellow dash=1 text={in:'//str(i)//', '//id_obj[i]//'}'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
        # Ell. kron aperture:
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(kron_r[i] * a_img[i] * pix_scale)//'",'//str(kron_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=white'
        print(expre, >> ds9_dir//"/"//"kron_petro_aper.reg")
    }
    #____________________ END CREATE REGION DS9 FILES  _____________________________|


# edit_task:

    #----------------------------------------------------------
    # SECTION: RESERVADA POR SI SE REQUIERE EDICION DE IMAGENES
    #          PARA RECALCULAR EL ÍNDICE.
    #__________________________________________________________


    #_______________________________________________________________________________
    #_________________________ STANDARD ASYMMETRY INDEX ____________________________|

    # FIRST (1) YOU DO HAVE CLEANING OF BACKGROUND OBJECTS: MASKING

    print("clear") | cl
    print("")
    print(" Preprocessing: Masking Process ")
    print("________________________________________________________________\n________________________________________________________________")
    print("")
    # ---- Abrir ds9 ----:
    print("!ds9 -tile -frame 1 -frame 2 A496J.fits -scale linear -scale mode 99.5 -regions load "//ds9_dir//"/apertures.reg -frame 3 &") | cl
    print("  Ds9-IRAF iterative mode (cursor mode)")
    print("")
    print("  You have to alternate clicking on one application and \n the other for this process:")
    print("  - First DS9 viewer (imedit task) and IRAF window-shell (Enter)")
    print("")
    print("  Press enter to continue...")
    scan(tmp_waiting)


    print(" Please wait while DS9 opens completely! Then, press Enter to continue...")
    scan(tmp_waiting)
    sleep(2)

    print("   Edit image with (look up help of) IMEDIT task of NOAO package.")
    print("   1. Clicking on DS9 window and:")
    print("   -Rectangular apperture: double cursor input with command 'a'")
    print("   -Circle aperture: one cursos input with command 'b'")
    print("")
    print("   Default diameter of circle is 15 pixels ")
    print("   (Press 'Enter' [15] or input a differen integer):")
    scan(r_mask)
    print("")
    if(r_mask < 4 && r_mask > 50){r_mask = 15}




    print("EXIT!")

exit_task:

    print("EXIT BY GOTO!")

end
