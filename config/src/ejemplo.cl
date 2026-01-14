# procedure ejemplo (lista_archivos)
#     string lista_archivos
#     struct *imglist
# begin
#     struct line
#     imglist = lista_archivos
#     while (fscan (imglist, line) != EOF) {
#         print (line)     # o lo que necesites hacer
#     }
#     imglist = ""
# end
procedure ejemplo (images)
    string images
    struct *lista
begin
    struct line
    lista = images
    while (fscan (lista, line) != EOF)
        print (line)
    lista = ""
end
