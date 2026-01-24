procedure main_mytask(input_value)

int input_value {prompt="Input parameter"}

begin
    real result

    print("\n Los valores retornados son: ")

    # Llamar a mytask
    mytask(input_value)
    # Obtener el valor retornado
    result = mytask.output_value
    # imprimir
    print(result)

    # Llamar a mytask
    mytask(result)
    # Obtener el valor retornado
    result = mytask.output_value
    # imprimir
    print(result)

end

