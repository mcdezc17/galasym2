procedure sexpar2reg()

string input_list  = "in_list"        {prompt = "List of SEx parameters"}
string output_reg  = "out_list"       {prompt = "Output name list"}
real   pix_scale   = 0.2486      {prompt = "Pixel scale (arcsec/pixel)"}

begin

    struct line

    string line_info

    string id_obj[999]
    real ra_j00[999], dec_j00[999], xwin_img[999], ywin_img[999], a_img[999], b_img[999], ellip[999], theta_j00[999], theta_img[999], kron_r[999], petro_r[999], eff_r[999], iso_area[999], iso_areaf[999], a_mod[999], b_mod[999]

    int n_list

    string expre

    real ri_ann, ro_ann

    ri_ann = 3
    ro_ann = 4
    # -----------------------------------------------------------

    # INPUT PARAMETER VERIFICATION ------------------------------
    if (!access(input_list)){
        print("Warning: input list named ", input_list, " not found!")
        print("Enter correct filename with extension *.txt, *.ascii (etc) e.g. input_list.txt or input_list.ascii: ")
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

    # READ INPUT LIST --------------------------------------------
    list = input_list
    i = 0
    while(fscan(list,line) != EOF){
        line_info = substr(line, 1, 1)
        if(line_info != "#"){

            i = i + 1

            # print(line) | scan(id_obj[i], ra_j00[i], dec_j00[i])
            print(line) | scan(ra_j00[i], dec_j00[i])

            id_obj[i] = "ID_GLXY_"//i

            #, xwin_img[i], ywin_img[i], a_img[i], b_img[i], ellip[i], theta_j00[i], theta_img[i], kron_r[i], petro_r[i], eff_r[i], iso_area[i], iso_areaf[i], a_mod[i], b_mod[i])

            # petro_r[i] = petro_r[i] / 2
        }
    }
    n_list = i

    #_______________________________________________________________________________
    #____________________ CREATE REGION DS9 FILES  _________________________________|
    # FK5 coordinates format / The shape of apertures depends on ellipticity (SEx)
    # and determines the measurement aperture (growing in this shape)

    # Header: footprint ellipse
    delete(output_reg, ver-, >& "dev$null")
    print("# Region file format: DS9 version 4.1", >> output_reg)
    print('global dashlist=8 3 width=1 font="helvetica 12 bold roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1', >> output_reg)
    print("fk5", >> output_reg)

    for(i=1; i<=n_list; i+=1){
        # refrence (3A,3B) aperture: eliptical
        expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(20)//'",'//str(20)//'",'//str(0)//') # color=green text={'//id_obj[i]//'}'
        print(expre, >> output_reg)

        #    # refrence (Rp) aperture: eliptical
        #    expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(petro_r[i] * a_img[i] * pix_scale)//'",'//str(petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red text={Rp}'
        #    print(expre, >> output_reg)
        #
        #    # measurement (1.5xRp) aperture: eliptical
        #    expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(1.5 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(1.5 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={1.5Rp}'
        #    print(expre, >> output_reg)
        #
        #    # measurement (2xRp) aperture: eliptical
        #    expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(2 * petro_r[i] * a_img[i] * pix_scale)//'",'//str(2 * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=red dash=1 text={2Rp}'
        #    print(expre, >> output_reg)
        #
        #    # Model (A_MOD, B_MOD) aperture: eliptical
        #    expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(3 * a_mod[i] * pix_scale)//'",'//str(3 * b_mod[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue text={Model}'
        #    print(expre, >> output_reg)

        # background aperture: eliptical annulus
        # expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ri_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ri_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1'
        # print(expre, >> output_reg)
        #
        # expre = 'ellipse('//str(ra_j00[i])//','//str(dec_j00[i])//','//str(ro_ann * petro_r[i] * a_img[i] * pix_scale)//'",'//str(ro_ann * petro_r[i] * b_img[i] * pix_scale)//'",'//str(theta_img[i])//') # color=blue dash=1 text={in:'//str(i)//', '//id_obj[i]//'}'
        # print(expre, >> output_reg)


    }
    #____________________ END CREATE REGION DS9 FILES  _____________________________|


    exit_task:

    # print("Exit task.")
    print("-------------------------------------------------------------")
    print("")

end
