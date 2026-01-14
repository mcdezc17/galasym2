procedure printfile (filename)

  string filename
  struct *rlist

begin

   struct line
   rlist = filename
   while (fscan(rlist, line) != EOF)
      print (line)
   rlist = ""

end
