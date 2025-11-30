procedure check_edit()


string measure_img  = "A85J"    {prompt = "FITS observed data"}
real   thresh_index = 0.10      {prompt = "Check objects above this thresh index"}
real   low_clip     = 1.0       {prompt = "What folder to analyzis?"}
string keyw_ds9     = "ds9"     {prompt = "Key word to open terminal ds9"}
string   type_index = "rot"     {prompt = "list to edit: 'res' or 'rot'"}

begin

    string my_date, my_time

    string out_dir, dataimg_dir, obs_dir, asymm_dir, file_dir, cat_dir, ds9_dir, index_cat, tmp_dir, rot_cat_dir

    string tmp_string, tmp_bool

    struct line

    string line_info
    int n_list

    string id_obj[999]
    real ra_j00[999], dec_j00[999], cc_dist[999], index_col1[999], index_col2[999], index_col3[999]

    int poss_edit[999]

    real tmp_val

    string log_file

    string data_dir, alphaimg_dir

    # ./: main output folder
    out_dir = "alpha_"//str(low_clip)

    # ./data
    data_dir = "data"

    # ./alpha/files(catalogs o plain text):
    file_dir = out_dir//"/"//"files"
    # ./alpha/files/ds9_files
    ds9_dir = file_dir//"/"//"ds9_files"
    # ./alpha/files/catalogs
    cat_dir = file_dir//"/"//"catalogs"
    # ./alpha/files/catalogs/rot_alpha
    rot_cat_dir = cat_dir//"/"//"rotated_alpha"

    if (strlwr(type_index)=="res"){
        index_cat = cat_dir//"/"//"areaindex.cat"
    }else if(strlwr(type_index)=="rot"){
        index_cat = rot_cat_dir//"/"//"rot_areaindex.cat"
    }else{
        print("   WRNG: 'type_index' prompt input must be 'res' or 'rot' \n   Try again. Exit task!")
        goto exit_task
    }
    # ========================================

    # ./alpha: main output index alpha folder
    alphaimg_dir = out_dir//"/"//"images"
    # ./data/images:
    dataimg_dir = data_dir//"/"//"data_images"
    # ./alpha/images/observed
    obs_dir = dataimg_dir//"/"//"observed"
    # ./alpha/images/asymmpix
    asymm_dir = alphaimg_dir//"/"//"asymmpix"

    # ./data/temporal:
    tmp_dir = out_dir//"/"//"cache"

    log_file = tmp_dir//"/"//"imedit_logfile_"

    tmp_bool = "no"

    print("! date +\"%Y-%m-%d\"") | cl | scan(my_date)
    print("! date +\"%H:%M:%S\"") | cl | scan(my_time)

    print("clear") | cl
    printf("\n --------- Check Edit List for GALASYM2 started on %s at %s --------\n\n", my_date, my_time)


    # Go to local directory: out of config folder ----------------------------------
    # ======================================================================================================================
    # print("cd ..") | cl ==================================================================================================
    # ======================================================================================================================
    if(!access(index_cat)){
        print("   WRNG: Area asymmetry index catalog 'areaindex.cat' does not exist!")
        goto exit_task
    }
    # ------------------------------------------------------------------------------


    # Check that the input FITS observed image exists or is named correctly:
    if(!access(measure_img)){
        # print("Warning: FITS observed image: ", measure_img, " not found!")
        # print("         Forgot it? --> Adding extension *.fits: ")
        tmp_string = measure_img//".fits"
        # print("New name: ", tmp_string, " ...check:")
        if(access(tmp_string)){
            print(" Observed image name... correct")
            measure_img = tmp_string
        }else{
            print(" ERR: Check the full file name of the observed image and try again!")
            print("      e.g. 'cluster_a85.fits'")
            goto exit_task
        }
    }

    # READ INPUT LIST --------------------------------------------
    list = index_cat
    i = 0
    j = 0
    while(fscan(list,line) != EOF){
        line_info = substr(line, 1, 1)
        if(line_info != "#"){

            i = i + 1

            print(line) | scan(id_obj[i], ra_j00[i], dec_j00[i], cc_dist[i], index_col1[i], index_col2[i], index_col3[i])

            if(index_col2[i] >= thresh_index){

                j = j + 1
                poss_edit[j] = i
            }

        }
    }
    n_list = j
    j = 0

    # Show list of candidate objects
    printf(" Found %d objects to edit possibly.\n Asymmetry area index >= %.4f\n\n", n_list, thresh_index)
    printf(" -------------------------------------------------\n %12s %29s %6s\n -------------------------------------------------\n", "id_inputlist", "ID_OBJ", "Alpha")

    for(i =1;i <= n_list; i += 1){

        k = poss_edit[i]

        printf(" %12d %29s %6.4f\n", poss_edit[i], id_obj[k], index_col2[k])
    }
    k = 0
    print(" -------------------------------------------------\n")

    # Open DS9
    #print("! "//keyw_ds9//" -tile -frame 1 -frame 2 "//measure_img//" -scale linear -scale mode 99.5 -lock frame wcs -frame 2 -regions load "//ds9_dir//"/"//"apertures.reg &") | cl
    print("! "//keyw_ds9//" -tile -frame 1 -frame 2 -lock frame image &") | cl
    sleep(5)
    print(" Opening DS9 Wait...")
    sleep(7)
    print("\n MAKE SURE DS9 has completly opened")
    print(" Wait...\n")
    sleep(7)
    print(" Choose the objects to edit:")
    print("     - If you do not want to edit PRESS ENTER to skip object")
    print("     - BUT if you want to edit object MUST type input yes\n")

    print(" If you see two (2) frames in DS9 window then press Enter:")

    scan(tmp_bool)

    # Header: edit list catalog for galasym2
    delete(cat_dir//"/"//"edit_list.cat", ver-, >& "dev$null")
    printf("#%12s %29s %6s\n", "id_inputlist", "ID_OBJ", "Alpha", >> cat_dir//"/"//"edit_list.cat")

    # Display objects
    for(i =1;i <= n_list; i += 1){

        k = poss_edit[i]
        tmp_bool = "no"
        print("\n -------------------------------------------------------------")
        print(" Check object ("//str(i)//"/"//str(n_list)//"): "//id_obj[k]//" Alpha: "//str(index_col2[k])//"\n")

        display(image=asymm_dir//"/"//"asymmpix_"//id_obj[k], frame=1, erase=yes)
        display(image=obs_dir//"/"//"observed_"//id_obj[k], frame=2, erase=yes)
        print(" Press Enter to skip or yes if you want to edit: ")
        scan(tmp_bool)
        if(strlwr(tmp_bool) == "yes" || strlwr(tmp_bool) == "y"){
            imedit(asymm_dir//"/"//"asymmpix_"//id_obj[k], asymm_dir//"/"//"edit_asymmpix_"//id_obj[k], logfile=log_file//str(id_obj[k]), command = "display $image 1 erase=$erase fill=no zscale=no order=0 >& dev$null")
        }

        if(imaccess(asymm_dir//"/"//"edit_asymmpix_"//id_obj[k])){
            printf(" %13d %29s %6.4f\n", poss_edit[i], id_obj[k], index_col2[k], >> cat_dir//"/"//"edit_list.cat")
        }
    }
    k = 0
    print("\n -------------------------------------------------------------")

exit_task:

print("\n Exit check edit list task.")

print(" cd config") | cl
print("\n WRNG: you are in directory: ")
print("pwd") | cl
print("")

end
