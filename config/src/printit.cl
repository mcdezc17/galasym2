procedure printfile (file_name)

  string filename
  struct *flist

begin

   struct line
   flist = filename
   while (fscan(flist, line) != EOF)
      print (line)
   flist = ""

end
