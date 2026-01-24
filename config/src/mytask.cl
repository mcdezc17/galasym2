procedure mytask(input_value)

int input_value {prompt="Input parameter"}
real output_value = 0.0
#real output_value2 = 0.0

begin
    real temp
    # real temp2

    # Tu lógica aquí
    temp = input_value * 2
    # temp2 = temp * 2

    # Asignar al parámetro de salida
    mytask.output_value = temp
    # mytask.output_value2 = temp2
end
