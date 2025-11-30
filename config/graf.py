import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import sys

# CIERRA TODAS LAS FIGURAS PREVIAS
plt.close('all')
plt.rcParams.update({'font.size': 10})

def leer_columna_datos(nombre_archivo):
    """Lee una columna de datos ignorando líneas con #"""
    datos = []
    with open(nombre_archivo, 'r') as archivo:
        for linea in archivo:
            if linea.strip().startswith('#') or not linea.strip():
                continue
            valor = float(linea.strip())
            datos.append(valor)
    return np.array(datos)

# Verificar argumentos de línea de comandos
if len(sys.argv) != 3:
    print("Uso: python3 codigo.py <archivo1> <archivo2>")
    print("\nEjemplo:")
    print("  python3 codigo.py tmp_alpha tmp_rotalpha")
    sys.exit(1)

# Obtener nombres de archivos desde argumentos
nombre_archivo_1 = sys.argv[1]
nombre_archivo_2 = sys.argv[2]

#print(f"Leyendo archivos:")
#print(f"  Archivo 1: {nombre_archivo_1}")
#print(f"  Archivo 2: {nombre_archivo_2}")

# Leer datos (una columna cada archivo)
try:
    data1 = leer_columna_datos(nombre_archivo_1)
    data2 = leer_columna_datos(nombre_archivo_2)
except FileNotFoundError as e:
    print(f"\nError: No se pudo encontrar el archivo: {e.filename}")
    sys.exit(1)
except Exception as e:
    print(f"\nError al leer archivos: {e}")
    sys.exit(1)

# Verificar que tengan el mismo tamaño
if len(data1) != len(data2):
    raise ValueError(f"Los archivos tienen diferente número de datos: {len(data1)} vs {len(data2)}")

# Crear el eje x
x = np.arange(0.25, 3.1, 0.05)

# Verificar que coincidan
if len(data1) != len(x):
    # print(f"Advertencia: {len(data1)} datos pero {len(x)} valores de x.")
    # Ajustar si es necesario
    n_min = min(len(data1), len(x))
    data1 = data1[:n_min]
    data2 = data2[:n_min]
    x = x[:n_min]

# Calcular porcentaje en x=1.0
idx_x1 = np.where(np.isclose(x, 1.0, atol=0.05))[0]
if idx_x1.size > 0:
    valor1_en_x1 = data1[idx_x1[0]]
    valor2_en_x1 = data2[idx_x1[0]]
    porcentaje = (valor2_en_x1 / valor1_en_x1 * 100.0) if valor1_en_x1 != 0 else 0
    # print(f"\nEn x≈1.0 (índice {idx_x1[0]}):")
    # print(f"  Archivo 1 = {valor1_en_x1:.4f}")
    # print(f"  Archivo 2 = {valor2_en_x1:.4f}")
    # print(f"  Porcentaje = {porcentaje:.2f}%\n")
else:
    print("Advertencia: No se encontró x≈1.0 en los datos.")

# Crear figura pequeña
fig, ax = plt.subplots(figsize=(4.5, 3.5))

# Posicionar ventana en esquina superior derecha
fig.canvas.manager.window.wm_geometry("+1200+0")

# Gráfica: Datos originales
ax.plot(x, data1, color='green', linewidth=1.5, label=r'$Cumulative$')
ax.plot(x, data2, color='red', linewidth=1.5, label=r'$Profile$')

# Línea vertical en x=1.0
ax.axvline(x=1.5, color='black', linestyle='--', alpha=0.7)

ax.set_xlabel(r'$r/r_{P}$', fontsize=10)
ax.set_ylabel(r'$\alpha_{An}$', fontsize=10)
ax.set_title('Comparación de perfiles', fontsize=11)
ax.legend(fontsize=8)
ax.grid(True)

plt.show()
