procedure printit (file_name)
    string file_name
    #struct ∗flist
begin
    struct line
    flist = file_name
    while (fscan (flist, line) != EOF)
        print (line)
end
