procedure config_files(imgname,pixel_scale,saturation,magzeropoint,default_psf,imgsingle)

string imgname
real   pixel_scale
real   saturation
real   magzeropoint
real   gain
bool   default_psf
bool   imgsingle

begin

    string tmp_outfile
    real aperture_ref


    if(default_psf == no){

        if(imgsingle == no){
            imgname = "images folder "//imgname
        }

        # ==============================================================================================
        # SEXTRACTOR PRE-PSFEX CONFIG FILE
        # ==============================================================================================

        tmp_outfile = "config/psfex/prepsfex/prepsfex.sex"

        print("# Simple configuration file for SExtractor prior to PSFEx use", > tmp_outfile)
        print("# only non-default parameters are present.", >> tmp_outfile)

        print("# FOR GALASYM2 ANALYSIS IMG: ", imgname, >> tmp_outfile)
        print("# DATE 190925", >> tmp_outfile)

        print("\n#-------------------------------- Catalog ------------------------------------", >> tmp_outfile)

        print("\nCATALOG_NAME     data/results_psfex/prepsfex.cat            # (BEST DEFAULT) Catalog filename", >> tmp_outfile)
        print("CATALOG_TYPE     FITS_LDAC                     # (MANDATORY FITS_LDAC) FITS_LDAC format", >> tmp_outfile)
        print("PARAMETERS_NAME  config/psfex/prepsfex/prepsfex.param # name of the file containing catalog contents", >> tmp_outfile)

        print("\n#------------------------------- Extraction ----------------------------------", >> tmp_outfile)

        print("\nDETECT_MINAREA 3    # (BEST DEFAULT) minimum number of pixels above threshold", >> tmp_outfile)
        print("DETECT_THRESH    4    # (BEST DEFAULT) a fairly conservative threshold", >> tmp_outfile)
        print("ANALYSIS_THRESH  4    # idem", >> tmp_outfile)

        print("\nFILTER         Y    # (MANDATORY YES) apply filter for detection (Y or N)?", >> tmp_outfile)
        print("FILTER_NAME      config/psfex/prepsfex/default.conv   # (MANATORY default.conv) name of the file containing the filter", >> tmp_outfile)

        print("\n#-------------------------------- WEIGHTing ----------------------------------", >> tmp_outfile)
        print("#-------------------------------- FLAGging -----------------------------------", >> tmp_outfile)
        print("#------------------------------ Photometry -----------------------------------", >> tmp_outfile)

        print("\nPHOT_FLUXFRAC   0.5", >> tmp_outfile)

        aperture_ref = (5 + 0.1) / pixel_scale

        printf("\nPHOT_APERTURES  %.2f        # put the referrence aperture diameter here: 5arsec diameter in pixels", aperture_ref, >> tmp_outfile)
        printf("SATUR_LEVEL       %.2f        # put the right saturation threshold here", saturation, >> tmp_outfile)
        printf("MAG_ZEROPOINT     %.2f        # magnitude zero-point", magzeropoint, >> tmp_outfile)
        printf("GAIN              %.2f        # put the right detector gain in e-/ADU here", gain, >> tmp_outfile)

        # ==============================================================================================
        # PSFEX CONFIG FILE
        # ==============================================================================================



    # END  IF (default_psf==no)
    }else{

        # SI USA ('default.psf') PSF POR DEFECTO, ESCRIBIR EN SEXTRACTOR CONFIG FILE:
        psf_name = "config/sextractor/default.psf"
    }


end
