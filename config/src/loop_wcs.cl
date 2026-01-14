procedure loop_wcs()
string infile
begin
    string outfile, tmp_image, line
    string img[2]
    int xc, yc

    xc = 249
    yc = 253

    img[1] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_J0434020_131747.fits"
    img[2] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_IC_0375.fits"

    print("# encabezado", > "/home/sloan/galasym2/test/A496/J_band/data/results_sex/dummy_list.ascii")
    print("linea_1_valida", >> "/home/sloan/galasym2/test/A496/J_band/data/results_sex/dummy_list.ascii")
    print("linea_2_valida", >> "/home/sloan/galasym2/test/A496/J_band/data/results_sex/dummy_list.ascii")

    # Simular lectura con fscan
    list = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/dummy_list.ascii"
    i = 0
    while(fscan(list, line) != EOF) {
        if(line != "" && substr(line,1,1) != "#" ){
            i = i + 1

            print((xc + i), " ", (yc + i), > "/home/sloan/galasym2/test/A496/J_band/data/results_sex/"//i//"_xycenter_images.ascii")

            tmp_image = img[i]
            infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/"//i//"_xycenter_images.ascii"
            outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/file_"//i//"_SKYcoord.ascii"

            wcsctran(infile, outfile, image=tmp_image, inwcs="logical", outwcs="world")

        }
    }
end


# FUNCIONA BIEN CON WHILE SIMPLE:
# procedure loop_wcs()
# string infile
# begin
#     string outfile, tmp_image, line
#     string img[2]
#
#     img[1] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_J0434020_131747.fits"
#     img[2] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_IC_0375.fits"
#
#     i = 1
#     while(i <= 2) {
#         tmp_image = img[i]
#         infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/"//i//"_xycenter_images.ascii"
#         outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/file_"//i//"_SKY.ascii"
#
#         wcsctran(infile, outfile, image=tmp_image, inwcs="logical", outwcs="world")
#
#         i = i + 1
#     }
# end

# FUNCIONA BIEN CON FOR:
# procedure loop_wcs()
# string infile
# begin
#     string outfile, tmp_image
#     string img[2]
#
#     img[1] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_J0434020_131747.fits"
#     img[2] = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_IC_0375.fits"
#
#     for(i=1; i<=2; i+=1) {
#         tmp_image = img[i]
#         infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/"//i//"_xycenter_images.ascii"
#         outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/file_"//i//"_SKY.ascii"
#
#         # Llama directamente pero con variable simple
#         wcsctran(infile, outfile, image=tmp_image, inwcs="logical", outwcs="world")
#         # Esto funciona porque current_img ya NO es array[index]
#     }
#
#
#     # for(i=1; i<=2; i+=1) {
#     #     infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/"//i//"_xycenter_images.ascii"
#     #     outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/file_"//i//"_sky.ascii"
#     #     tmp_image = img[i]
#     #
#     #     if (i == 1)
#     #         wcsctran(infile, outfile, image=tmp_image, inwcs="logical", outwcs="world")
#     #     else if (i == 2)
#     #         wcsctran(infile, outfile, image=tmp_image, inwcs="logical", outwcs="world")
#     # }
# end


# procedure loop_wcs()
#
# string infile
#
# begin
#
#     string outfile
#     string imagein
#
#     infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/1_xycenter_images.ascii"
#     outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/sky_1.ascii"
#     imagein = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_J0434020_131747.fits"
#     wcsctran(infile, outfile, image=imagein, inwcs="logical", outwcs="world")
#
#     infile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/2_xycenter_images.ascii"
#     outfile = "/home/sloan/galasym2/test/A496/J_band/data/results_sex/sky_2.ascii"
#     imagein = "/home/sloan/galasym2/test/A496/J_band/data/data_images/observed/ID_IC_0375.fits"
#     wcsctran(infile, outfile, image=imagein, inwcs="logical", outwcs="world")
#
# end
