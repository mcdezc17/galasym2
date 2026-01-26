import numpy as np
import matplotlib.pyplot as plt

plt.rcParams.update({'font.size': 15})

def leer_datos_txt_matriz(nombre_archivo):
    datos_filtrados = []
    with open(nombre_archivo, 'r') as archivo:
        for linea in archivo:
            if linea.strip().startswith('#') or not linea.strip():
                continue
            valores = linea.strip().split()[1:]  # Ignorar primera columna
            datos_filtrados.append([float(v) for v in valores])
    return np.array(datos_filtrados)

# Nombres de archivos
nombre_archivo_1 = "residual_area/cum_index_set.cat"
nombre_archivo_2 = "residual_rotation_area/rot_cum_index_set.cat"

# Leer matrices de datos (ignorando líneas con # y primera columna)
matriz1 = leer_datos_txt_matriz(nombre_archivo_1)
matriz2 = leer_datos_txt_matriz(nombre_archivo_2)

# Verificar consistencia
if matriz1.shape != matriz2.shape:
    raise ValueError("Los archivos no tienen la misma forma.")

# Mostrar cuántas filas hay y pedir al usuario cuál quiere usar
print(f"Se encontraron {matriz1.shape[0]} filas disponibles.")
fila = int(input("Ingrese el índice de la fila que desea graficar (comenzando desde 0): "))

# Validar índice
if fila < 0 or fila >= matriz1.shape[0]:
    raise IndexError("Índice de fila fuera de rango.")

# Extraer la fila deseada
data1 = matriz1[fila]
data2 = matriz2[fila]

# Obtener el tamaño mayor
n_max = max(len(data1), len(data2))
print(f"Tamaño de datos: {n_max}")

# Crear el eje x
x = np.arange(0.25, (0.25 + (0.05 * n_max)), 0.05)
print(f"Longitud del eje x: {len(x)}")

# Verificar tamaño
if len(data1) != len(x):
    raise ValueError(f"{nombre_archivo_1}: {len(data1)} datos no coinciden con {len(x)} valores de x.")
if len(data2) != len(x):
    raise ValueError(f"{nombre_archivo_2}: {len(data2)} datos no coinciden con {len(x)} valores de x.")

# Crear figura
plt.figure(figsize=(8, 6))

# Graficar curvas
plt.plot(x, data1, color='black', linewidth=1, label=r'index $\alpha$')
plt.plot(x, data2, color='blue', linewidth=1, label=r'index $\alpha_{ROT}$')

# Posiciones específicas de x para líneas verticales
x_valores = [1.5]

# Dibujar líneas verticales con f(x)=valor usando data1
for x_val in x_valores:
    idx = np.where(np.isclose(x, x_val))[0]
    if idx.size == 0:
        continue
    valor1 = data1[idx[0]]
    valor2 = data2[idx[0]]
    plt.axvline(x=x_val, color='red', linestyle='--', label=f'{valor1:.3f}')
    plt.axvline(x=x_val, color='red', linestyle='--', label=f'{valor2:.3f}')

# Etiquetas
plt.xlabel(r'$r/R_{P}$', fontsize=12)
plt.ylabel(r'$\alpha_{A2}$', fontsize=12)

# Mostrar todo
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
